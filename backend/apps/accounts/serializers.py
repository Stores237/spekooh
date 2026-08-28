from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.db.models import F
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from apps.payments.services import first_unlock_free_eligible, trial_days_remaining

from . import services
from .models import AccountType, EmailVerificationCode, PasswordResetCode, User


class UserSerializer(serializers.ModelSerializer):
    trial_days_remaining = serializers.SerializerMethodField()
    first_unlock_free_eligible = serializers.SerializerMethodField()
    email_verified = serializers.SerializerMethodField()
    avatar_url = serializers.SerializerMethodField()
    # Write-only upload target — PATCH /me/ with multipart form data,
    # field name "avatar", to set/replace it. Not access-gated like paper
    # files (see the model field's own comment): avatar_url just returns
    # the URL directly.
    avatar = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone_number",
            "name",
            "account_type",
            "education_level",
            "region",
            "language_pref",
            "created_at",
            "trial_days_remaining",
            "first_unlock_free_eligible",
            "referral_code",
            "email_verified",
            "avatar",
            "avatar_url",
        ]
        read_only_fields = [
            "id",
            "account_type",
            "created_at",
            "trial_days_remaining",
            "first_unlock_free_eligible",
            "referral_code",
            "email_verified",
            "avatar_url",
        ]

    def get_trial_days_remaining(self, obj) -> int:
        return trial_days_remaining(obj)

    def get_first_unlock_free_eligible(self, obj) -> bool:
        return first_unlock_free_eligible(obj)

    def get_email_verified(self, obj) -> bool:
        return obj.email_verified_at is not None

    def get_avatar_url(self, obj) -> str | None:
        if not obj.avatar:
            return None
        request = self.context.get("request")
        url = obj.avatar.url
        return request.build_absolute_uri(url) if request else url

    def update(self, instance, validated_data):
        # Edit-profile (PATCH /accounts/me/) lets a user change their email
        # freely — but email_verified_at was only ever set for the *old*
        # address. Without this, changing your email to one you don't
        # control would silently keep showing "verified", which is exactly
        # what email verification exists to prevent (see PR #41). Reset and
        # re-send, same real flow as at signup — not a new mechanism.
        email_changed = "email" in validated_data and (validated_data["email"] or None) != instance.email
        user = super().update(instance, validated_data)
        if email_changed:
            user.email_verified_at = None
            user.save(update_fields=["email_verified_at"])
            if user.email:
                services.send_verification_email(user)
        return user


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    referral_code = serializers.CharField(write_only=True, required=False, allow_blank=True)
    # Regulatory: a registration without real, affirmative Terms/Privacy
    # consent is rejected outright — this isn't just a client-side nudge,
    # the server enforces it too. Recorded as `terms_accepted_at`, not
    # just accepted-or-not, so there's a real audit trail of when.
    terms_accepted = serializers.BooleanField(write_only=True)

    class Meta:
        model = User
        fields = [
            "email",
            "phone_number",
            "name",
            "password",
            "education_level",
            "region",
            "language_pref",
            "referral_code",
            "terms_accepted",
        ]

    def validate_email(self, value):
        if not services.email_domain_is_verifiable(value):
            raise serializers.ValidationError("That email domain doesn't appear to accept mail. Check for a typo.")
        return value

    def validate_referral_code(self, value):
        if not value:
            return value
        code = value.strip().upper()
        if not User.objects.filter(referral_code=code).exists():
            raise serializers.ValidationError("Referral code not found.")
        return code

    def validate_terms_accepted(self, value):
        if not value:
            raise serializers.ValidationError("You must accept the Terms of Service and Privacy Policy to register.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        referral_code = validated_data.pop("referral_code", "")
        validated_data.pop("terms_accepted")
        referred_by = User.objects.filter(referral_code=referral_code).first() if referral_code else None
        user = User.objects.create_user(
            account_type=AccountType.REGISTERED,
            referred_by=referred_by,
            terms_accepted_at=timezone.now(),
            **validated_data,
        )
        user.set_password(password)
        user.save(update_fields=["password"])
        return user


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds the serialized user alongside the token pair on login."""

    def validate(self, attrs):
        data = super().validate(attrs)
        # settings.REQUIRE_EMAIL_VERIFICATION's own docstring covers why
        # this is a login-time gate, not a registration-time one: a brand
        # new account already got tokens at signup (so it can confirm in
        # that same session) — this only blocks a *later* login once that
        # session is gone and the code has expired.
        if (
            settings.REQUIRE_EMAIL_VERIFICATION
            and self.user.account_type == AccountType.REGISTERED
            and self.user.email_verified_at is None
        ):
            # A stable machine-readable key (not just a human sentence) so
            # the app can distinguish this from a plain wrong-password
            # rejection and offer a real "resend code" recovery instead of
            # a dead-end generic error.
            raise serializers.ValidationError({"code": ["email_not_verified"]})
        data["user"] = UserSerializer(self.user).data
        return data


def tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


class PasswordResetRequestSerializer(serializers.Serializer):
    """Always succeeds from the caller's point of view regardless of
    whether the email matches a real, registered account — the view (not
    this serializer) is what decides whether to actually issue+email a
    code, so a script probing emails can't tell which ones exist."""

    email = serializers.EmailField()

    def issue_code_if_real_account(self):
        email = self.validated_data["email"].strip().lower()
        user = User.objects.filter(email__iexact=email, account_type=AccountType.REGISTERED).first()
        if user is None:
            return
        reset = PasswordResetCode.issue(user)
        send_mail(
            subject="Your Spekooh password reset code",
            message=(
                f"Your Spekooh password reset code is {reset.code}. "
                "It expires in 15 minutes. If you didn't request this, ignore this email."
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
        )


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6, min_length=6)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        user = User.objects.filter(email__iexact=email, account_type=AccountType.REGISTERED).first()
        # Deliberately the same error for "no such account" and "wrong
        # code" — distinguishing them would leak which emails are registered.
        generic_error = "That code is invalid or has expired."
        if user is None:
            raise serializers.ValidationError(generic_error)
        reset = (
            PasswordResetCode.objects.filter(user=user, used_at__isnull=True)
            .order_by("-created_at")
            .first()
        )
        if reset is None or not reset.is_usable:
            raise serializers.ValidationError(generic_error)
        if reset.code != attrs["code"]:
            PasswordResetCode.objects.filter(pk=reset.pk).update(attempts=F("attempts") + 1)
            raise serializers.ValidationError(generic_error)
        attrs["_user"] = user
        attrs["_reset"] = reset
        return attrs

    def save(self, **kwargs):
        user = self.validated_data["_user"]
        reset = self.validated_data["_reset"]
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])
        reset.used_at = timezone.now()
        reset.save(update_fields=["used_at"])
        return user


class EmailVerificationConfirmSerializer(serializers.Serializer):
    """Operates on request.user (passed in via context), not an email —
    unlike password reset, this always runs from an authenticated session
    (RegisterView already grants tokens at signup), so there's no
    account-enumeration concern to design around here."""

    code = serializers.CharField(max_length=6, min_length=6)

    def validate(self, attrs):
        user = self.context["request"].user
        generic_error = "That code is invalid or has expired."
        verification = (
            EmailVerificationCode.objects.filter(user=user, used_at__isnull=True).order_by("-created_at").first()
        )
        if verification is None or not verification.is_usable:
            raise serializers.ValidationError(generic_error)
        if verification.code != attrs["code"]:
            EmailVerificationCode.objects.filter(pk=verification.pk).update(attempts=F("attempts") + 1)
            raise serializers.ValidationError(generic_error)
        attrs["_user"] = user
        attrs["_verification"] = verification
        return attrs

    def save(self, **kwargs):
        user = self.validated_data["_user"]
        verification = self.validated_data["_verification"]
        user.email_verified_at = timezone.now()
        user.save(update_fields=["email_verified_at"])
        verification.used_at = timezone.now()
        verification.save(update_fields=["used_at"])
        return user


class EmailVerificationRequestByEmailSerializer(serializers.Serializer):
    """The recovery path for REQUIRE_EMAIL_VERIFICATION: a registered user
    who never verified, then lost the session that let them use the
    authenticated confirm/resend above (closed the app, came back a day
    later, code long expired) is now refused at login with nothing else to
    do — this is how they get a fresh code without being logged in.
    Same non-revealing shape as PasswordResetRequestSerializer, and for the
    same reason: a script probing emails shouldn't learn which are real."""

    email = serializers.EmailField()

    def issue_code_if_unverified_real_account(self):
        email = self.validated_data["email"].strip().lower()
        user = User.objects.filter(
            email__iexact=email, account_type=AccountType.REGISTERED, email_verified_at__isnull=True
        ).first()
        if user is None:
            return
        services.send_verification_email(user)


class EmailVerificationConfirmByEmailSerializer(serializers.Serializer):
    """Same idea as EmailVerificationConfirmSerializer but keyed by email
    instead of request.user, for the same not-logged-in recovery case as
    EmailVerificationRequestByEmailSerializer above. Confirming here does
    NOT log the caller in — it only flips email_verified_at so their next
    real login (with their password) succeeds."""

    email = serializers.EmailField()
    code = serializers.CharField(max_length=6, min_length=6)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        generic_error = "That code is invalid or has expired."
        user = User.objects.filter(email__iexact=email, account_type=AccountType.REGISTERED).first()
        if user is None:
            raise serializers.ValidationError(generic_error)
        verification = (
            EmailVerificationCode.objects.filter(user=user, used_at__isnull=True).order_by("-created_at").first()
        )
        if verification is None or not verification.is_usable:
            raise serializers.ValidationError(generic_error)
        if verification.code != attrs["code"]:
            EmailVerificationCode.objects.filter(pk=verification.pk).update(attempts=F("attempts") + 1)
            raise serializers.ValidationError(generic_error)
        attrs["_user"] = user
        attrs["_verification"] = verification
        return attrs

    def save(self, **kwargs):
        user = self.validated_data["_user"]
        verification = self.validated_data["_verification"]
        user.email_verified_at = timezone.now()
        user.save(update_fields=["email_verified_at"])
        verification.used_at = timezone.now()
        verification.save(update_fields=["used_at"])
        return user
