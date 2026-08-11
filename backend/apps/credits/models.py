import uuid

from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


def generate_redeem_code():
    return uuid.uuid4().hex[:10].upper()


class CreditLedgerEntry(TimeStampedModel):
    """Contributor bonus credits — redeemable as discount codes, NOT cash."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="credit_ledger_entries")
    paper_submission = models.ForeignKey(
        "papers.PaperSubmission", on_delete=models.SET_NULL, null=True, blank=True, related_name="credit_entries"
    )
    amount = models.PositiveIntegerField()
    reason = models.CharField(max_length=200)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} +{self.amount} ({self.reason})"


class RedeemCodeStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    REDEEMED = "REDEEMED", "Redeemed"
    EXPIRED = "EXPIRED", "Expired"


class RedeemCode(TimeStampedModel):
    """
    Issued to a contributor (owner) based on their accepted-submission tier,
    but shareable: whoever applies the code at checkout consumes it, not
    necessarily the owner.
    """

    code = models.CharField(max_length=20, unique=True, default=generate_redeem_code)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="redeem_codes_owned")
    value_percent = models.PositiveSmallIntegerField()
    tier_at_issuance = models.PositiveIntegerField(help_text="Owner's total accepted submission count at issuance.")
    status = models.CharField(max_length=10, choices=RedeemCodeStatus.choices, default=RedeemCodeStatus.ACTIVE)
    expires_at = models.DateTimeField()

    redeemed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="redeem_codes_used",
    )
    redeemed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.code} ({self.status})"


# --- Instructor credit rules engine config (spec §5.2) ---
# Data-driven so ops can retune rates per subject/region with zero deploys.


class QuestionType(models.TextChoices):
    # MCQ deliberately has no rate row: it's marked in-house by the Review
    # Team (§4.1) and never carries instructor credit cost.
    SHORT_ANSWER = "SHORT_ANSWER", "Short-answer / structured"
    CALCULATION = "CALCULATION", "Calculation / derivation"
    ESSAY = "ESSAY", "Essay / long-form"
    MCQ = "MCQ", "Multiple choice (never instructor-priced)"


class QuestionTypeRate(TimeStampedModel):
    question_type = models.CharField(max_length=20, choices=QuestionType.choices, unique=True)
    base_rate_xaf = models.PositiveIntegerField()

    def __str__(self):
        return f"{self.get_question_type_display()}: {self.base_rate_xaf} XAF"


class ComplexityLevel(models.TextChoices):
    BASIC = "BASIC", "Primary / basic secondary"
    O_LEVEL = "O_LEVEL", "O-Level / BEPC / Probatoire"
    A_LEVEL = "A_LEVEL", "A-Level / Baccalauréat"
    UNIVERSITY = "UNIVERSITY", "University"


class LevelComplexityMultiplier(TimeStampedModel):
    level = models.CharField(max_length=20, choices=ComplexityLevel.choices, unique=True)
    multiplier = models.DecimalField(max_digits=4, decimal_places=2)

    def __str__(self):
        return f"{self.get_level_display()}: {self.multiplier}x"


class SubjectDemandFactor(TimeStampedModel):
    """Starts every subject at 1.0x; ops adjust as real instructor-availability data comes in."""

    subject = models.OneToOneField("papers.Subject", on_delete=models.CASCADE, related_name="demand_factor")
    factor = models.DecimalField(max_digits=4, decimal_places=2, default=1)

    def __str__(self):
        return f"{self.subject}: {self.factor}x"


class RedeemCodeTierConfig(TimeStampedModel):
    """
    Submission-count band -> redeem code value% and expiry window (spec
    §5.1: "more contribution -> more valuable, longer-lived redeem codes").
    Illustrative starting bands, ops-editable via admin.
    """

    min_submissions = models.PositiveIntegerField(unique=True)
    value_percent = models.PositiveSmallIntegerField()
    expiry_days = models.PositiveIntegerField()

    class Meta:
        ordering = ["min_submissions"]

    def __str__(self):
        return f"{self.min_submissions}+ submissions -> {self.value_percent}% / {self.expiry_days}d"


class ContributorBonusConfig(TimeStampedModel):
    """Singleton: the flat bonus-credit amount awarded per accepted, non-duplicate submission."""

    amount = models.PositiveIntegerField(default=50)

    def __str__(self):
        return f"{self.amount} credits per accepted submission"
