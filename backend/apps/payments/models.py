from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class PaymentPurpose(models.TextChoices):
    SUBSCRIPTION = "SUBSCRIPTION", "Pro subscription"
    PAPER_UNLOCK = "PAPER_UNLOCK", "Marking guide unlock"
    PAPER_DOWNLOAD = "PAPER_DOWNLOAD", "Exam paper download unlock"
    PAMPHLET_ORDER = "PAMPHLET_ORDER", "Pamphlet order"


class PaymentTransactionStatus(models.TextChoices):
    SUCCESS = "SUCCESS", "Success"
    FAILED = "FAILED", "Failed"


class PaymentTransaction(TimeStampedModel):
    """
    Audit trail of every call made through the PaymentProvider seam
    (apps.core.payment_provider). Real today only because the provider
    behind it is a MockPaymentProvider — the data model doesn't change
    when a real Flutterwave provider is swapped in.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="payment_transactions")
    purpose = models.CharField(max_length=20, choices=PaymentPurpose.choices)
    amount_fcfa = models.PositiveIntegerField()
    phone_number = models.CharField(max_length=20)
    status = models.CharField(max_length=10, choices=PaymentTransactionStatus.choices)
    provider_reference = models.CharField(max_length=100, blank=True)
    failure_reason = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.purpose} {self.amount_fcfa}FCFA, {self.status}"


class SubscriptionStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    EXPIRED = "EXPIRED", "Expired"


class SubscriptionManager(models.Manager):
    def has_active(self, user) -> bool:
        from django.utils import timezone

        return self.filter(user=user, status=SubscriptionStatus.ACTIVE, renews_at__gt=timezone.now()).exists()


class Subscription(TimeStampedModel):
    """Kawlo Plus: ad-free + unlimited paper views. Does NOT grant marking-guide access."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions")
    status = models.CharField(max_length=10, choices=SubscriptionStatus.choices, default=SubscriptionStatus.ACTIVE)
    renews_at = models.DateTimeField()
    payment_transaction = models.ForeignKey(
        PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True, related_name="subscriptions"
    )

    objects = SubscriptionManager()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user}, {self.status} (renews {self.renews_at:%Y-%m-%d})"


class PaperUnlockManager(models.Manager):
    def has_unlocked(self, user, paper_submission) -> bool:
        return self.filter(user=user, paper_submission=paper_submission).exists()


class PaperUnlock(TimeStampedModel):
    """Pay-per-unlock — marking guides only. Always required, even for Pro subscribers."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="paper_unlocks")
    paper_submission = models.ForeignKey(
        "papers.PaperSubmission", on_delete=models.CASCADE, related_name="unlocks"
    )
    amount_paid = models.PositiveIntegerField()
    redeem_code_applied = models.ForeignKey(
        "credits.RedeemCode", on_delete=models.SET_NULL, null=True, blank=True, related_name="paper_unlocks"
    )
    payment_transaction = models.ForeignKey(
        PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True, related_name="paper_unlocks"
    )

    objects = PaperUnlockManager()

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "paper_submission"], name="unique_unlock_per_user_per_paper"),
        ]

    def __str__(self):
        return f"{self.user} unlocked {self.paper_submission_id}"


class PaperDownloadUnlockManager(models.Manager):
    def has_unlocked(self, user, paper_submission) -> bool:
        return self.filter(user=user, paper_submission=paper_submission).exists()


class PaperDownloadUnlock(TimeStampedModel):
    """Pay-per-unlock for downloading an exam paper's actual scanned file —
    deliberately separate from PaperUnlock above, which gates the marking
    guide, not the file. Owner decision (2026-08-28): an exam paper is free
    to view in-app (ReportViewerScreen — the same in-app-only renderer
    reports already use, so viewing here never exposes a save-able file the
    OS's own viewer would), but downloading/saving it is a small,
    exam-level-priced purchase (see
    apps.papers.services.paper_download_price_fcfa). Reports keep their own
    existing download gate (PaperUnlock + report_download_is_free)
    untouched — this model is exam-paper only, never used for a report."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="paper_download_unlocks")
    paper_submission = models.ForeignKey(
        "papers.PaperSubmission", on_delete=models.CASCADE, related_name="download_unlocks"
    )
    amount_paid = models.PositiveIntegerField()
    payment_transaction = models.ForeignKey(
        PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True, related_name="paper_download_unlocks"
    )

    objects = PaperDownloadUnlockManager()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "paper_submission"], name="unique_download_unlock_per_user_per_paper"
            ),
        ]

    def __str__(self):
        return f"{self.user} unlocked download of {self.paper_submission_id}"
