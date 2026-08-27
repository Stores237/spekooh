import secrets
import uuid

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel

# Owner-tunable: how long a reset code stays valid, and how many wrong
# guesses before it's dead regardless of time left (a 6-digit code has only
# 1e6 possibilities — capping attempts matters more than the format looks).
PASSWORD_RESET_CODE_TTL_MINUTES = 15
PASSWORD_RESET_MAX_ATTEMPTS = 5


class AccountType(models.TextChoices):
    GUEST = "guest", "Guest"
    REGISTERED = "registered", "Registered"


class LanguagePreference(models.TextChoices):
    ENGLISH = "en", "English"
    FRENCH = "fr", "French"


def generate_referral_code():
    return uuid.uuid4().hex[:8].upper()


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        extra_fields.setdefault("account_type", AccountType.REGISTERED)
        user = self.model(email=self.normalize_email(email) if email else None, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email=None, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email=None, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("account_type", AccountType.REGISTERED)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self._create_user(email, password, **extra_fields)

    def create_guest(self, name=None):
        """A guest is a real User row (account_type=guest), not a session-only concept.

        Owner decision: a contributor without an account still has to be
        identified by a real name they typed (see Submit's contributor-name
        field) — an auto-generated "Guest xxxxxx" label is only a fallback
        for guest flows that don't collect one.
        """
        guest_ref = uuid.uuid4().hex[:12]
        clean_name = name.strip()[:150] if name and name.strip() else f"Guest {guest_ref[:6]}"
        user = self.model(
            email=None,
            name=clean_name,
            account_type=AccountType.GUEST,
            guest_ref=guest_ref,
        )
        user.set_unusable_password()
        user.save(using=self._db)
        return user


class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    """
    Custom User model, wired via AUTH_USER_MODEL before the first migration.
    Guests are real rows here (account_type=guest) so every other model FKs
    to User uniformly regardless of guest/registered status.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, null=True, blank=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    name = models.CharField(max_length=150, blank=True)
    # Same storage backend as paper scans (django-storages -> real Supabase
    # Storage when AWS_* env vars are set, local disk otherwise — see
    # STORAGES in config/settings/base.py). Unlike paper files this isn't
    # access-gated: any authenticated caller who can see this profile at
    # all can see its avatar, so UserSerializer.get_avatar_url just returns
    # the URL directly, no user_can_view_file-style check needed.
    avatar = models.ImageField(upload_to="avatars/%Y/%m/", null=True, blank=True)

    account_type = models.CharField(max_length=12, choices=AccountType.choices, default=AccountType.REGISTERED)
    # Opaque local identifier for guest accounts, stable across the guest's session lifetime.
    guest_ref = models.CharField(max_length=32, unique=True, null=True, blank=True)

    education_level = models.CharField(max_length=80, blank=True)
    region = models.CharField(max_length=80, blank=True)
    language_pref = models.CharField(max_length=2, choices=LanguagePreference.choices, default=LanguagePreference.ENGLISH)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    # Set once EmailVerificationCode confirms the address is real (see
    # RegisterView, which issues+sends the first code right at signup).
    # Deliberately does NOT gate login/access — unverified accounts work
    # normally; this is a signal surfaced in the app (a nag to verify), not
    # an access-control mechanism. Null for guests, who have no email.
    email_verified_at = models.DateTimeField(null=True, blank=True)

    # Regulatory: proof of Terms/Privacy consent at signup — required by
    # RegisterSerializer (a registration without it is rejected outright,
    # not just nudged client-side). Null for guests, who never go through
    # RegisterSerializer at all.
    terms_accepted_at = models.DateTimeField(null=True, blank=True)

    # Referral bonuses (spec: "referral bonuses", mechanics scoped by product
    # this session — fires on the referred user's first real action, not
    # bare signup, to resist fake-account abuse; see
    # apps.credits.services.award_referral_bonus).
    referral_code = models.CharField(max_length=10, unique=True, default=generate_referral_code)
    referred_by = models.ForeignKey(
        "self", on_delete=models.SET_NULL, null=True, blank=True, related_name="referrals_made"
    )
    # Set once this user's first paper unlock has credited their referrer —
    # the idempotency guard so the bonus can't fire twice.
    referral_bonus_awarded_at = models.DateTimeField(null=True, blank=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=models.Q(account_type="guest") | models.Q(email__isnull=False),
                name="registered_users_require_email",
            ),
        ]

    def __str__(self):
        return self.name or self.email or self.guest_ref or str(self.id)

    @property
    def is_guest(self):
        return self.account_type == AccountType.GUEST


class PasswordResetCode(TimeStampedModel):
    """A short-lived, single-use OTP for the app-native reset flow (no
    website to click an emailed link on, so a code the user retypes into
    the app fits the actual product better than Django's default
    token+uidb64 web flow).

    Request-side deliberately never reveals whether the email matched a
    real account (see PasswordResetRequestSerializer) — this table is the
    only place that distinction lives.
    """

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="password_reset_codes")
    code = models.CharField(max_length=6)
    attempts = models.PositiveSmallIntegerField(default=0)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["user", "used_at"])]

    @classmethod
    def issue(cls, user: "User") -> "PasswordResetCode":
        # secrets.randbelow (not `random`) — this gates a real password
        # change, so it needs to be cryptographically unguessable.
        code = f"{secrets.randbelow(1_000_000):06d}"
        return cls.objects.create(user=user, code=code)

    @property
    def is_expired(self) -> bool:
        age = timezone.now() - self.created_at
        return age.total_seconds() > PASSWORD_RESET_CODE_TTL_MINUTES * 60

    @property
    def is_usable(self) -> bool:
        return self.used_at is None and not self.is_expired and self.attempts < PASSWORD_RESET_MAX_ATTEMPTS


class EmailVerificationCode(TimeStampedModel):
    """Same OTP shape as PasswordResetCode (deliberately a separate model,
    not a shared one — the two are logically unrelated and mixing them up
    would be a real security bug, not just a style choice).

    RegisterView issues+emails the first one automatically right at signup
    — this is what actually answers "no verification was required": there
    now is a real code, sent for real (console backend today, see
    TODOS.md), that the app asks the new user to confirm. See User.
    email_verified_at's docstring for why confirming it doesn't gate access.
    """

    EMAIL_VERIFICATION_CODE_TTL_MINUTES = 30
    EMAIL_VERIFICATION_MAX_ATTEMPTS = 5

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="email_verification_codes")
    code = models.CharField(max_length=6)
    attempts = models.PositiveSmallIntegerField(default=0)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["user", "used_at"])]

    @classmethod
    def issue(cls, user: "User") -> "EmailVerificationCode":
        code = f"{secrets.randbelow(1_000_000):06d}"
        return cls.objects.create(user=user, code=code)

    @property
    def is_expired(self) -> bool:
        age = timezone.now() - self.created_at
        return age.total_seconds() > self.EMAIL_VERIFICATION_CODE_TTL_MINUTES * 60

    @property
    def is_usable(self) -> bool:
        return self.used_at is None and not self.is_expired and self.attempts < self.EMAIL_VERIFICATION_MAX_ATTEMPTS
