from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from apps.payments.services import first_unlock_free_eligible, trial_days_remaining

from .models import AccountType, User


class UserSerializer(serializers.ModelSerializer):
    trial_days_remaining = serializers.SerializerMethodField()
    first_unlock_free_eligible = serializers.SerializerMethodField()

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
        ]
        read_only_fields = [
            "id",
            "account_type",
            "created_at",
            "trial_days_remaining",
            "first_unlock_free_eligible",
            "referral_code",
        ]

    def get_trial_days_remaining(self, obj) -> int:
        return trial_days_remaining(obj)

    def get_first_unlock_free_eligible(self, obj) -> bool:
        return first_unlock_free_eligible(obj)


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
        data["user"] = UserSerializer(self.user).data
        return data


def tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}
