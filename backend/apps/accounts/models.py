import uuid

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models

from apps.core.models import TimeStampedModel


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

    def create_guest(self):
        """A guest is a real User row (account_type=guest), not a session-only concept."""
        guest_ref = uuid.uuid4().hex[:12]
        user = self.model(
            email=None,
            name=f"Guest {guest_ref[:6]}",
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

    account_type = models.CharField(max_length=12, choices=AccountType.choices, default=AccountType.REGISTERED)
    # Opaque local identifier for guest accounts, stable across the guest's session lifetime.
    guest_ref = models.CharField(max_length=32, unique=True, null=True, blank=True)

    education_level = models.CharField(max_length=80, blank=True)
    region = models.CharField(max_length=80, blank=True)
    language_pref = models.CharField(max_length=2, choices=LanguagePreference.choices, default=LanguagePreference.ENGLISH)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

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
