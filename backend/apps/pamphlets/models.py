from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel
from apps.payments.models import PaymentTransaction


class PartnerBookshop(TimeStampedModel):
    name = models.CharField(max_length=150)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    commission_percent = models.PositiveSmallIntegerField(default=5)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Pamphlet(TimeStampedModel):
    partner = models.ForeignKey(PartnerBookshop, on_delete=models.CASCADE, related_name="pamphlets")
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price_fcfa = models.PositiveIntegerField()
    delivery_available = models.BooleanField(default=False)
    delivery_fee_fcfa = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)

    class Meta:
        ordering = ["-is_featured", "title"]

    def __str__(self):
        return f"{self.title} ({self.partner})"


class PamphletOrderStatus(models.TextChoices):
    PAID_HELD = "PAID_HELD", "Paid, held in escrow"
    QR_ISSUED = "QR_ISSUED", "QR issued"
    RELEASED = "RELEASED", "Released to partner"
    EXPIRED = "EXPIRED", "Expired, flagged for admin review"
    DISPUTED = "DISPUTED", "Disputed"


class PamphletOrder(TimeStampedModel):
    """Escrow ledger row: held → QR issued → released (minus commission), or expired/disputed."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="pamphlet_orders")
    pamphlet = models.ForeignKey(Pamphlet, on_delete=models.PROTECT, related_name="orders")
    is_delivery = models.BooleanField(default=False)
    amount_paid = models.PositiveIntegerField()
    status = models.CharField(max_length=12, choices=PamphletOrderStatus.choices, default=PamphletOrderStatus.PAID_HELD)
    payment_transaction = models.ForeignKey(
        PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True, related_name="pamphlet_orders"
    )

    qr_token = models.CharField(max_length=200, blank=True, unique=True, null=True)
    qr_issued_at = models.DateTimeField(null=True, blank=True)
    # Delivery-only fallback: user self-confirms receipt, auto-released after
    # COURIER_SELF_CONFIRM_DAYS by the cron command if undisputed.
    self_confirmed_at = models.DateTimeField(null=True, blank=True)

    payout_amount = models.PositiveIntegerField(null=True, blank=True)
    released_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.pamphlet}, {self.user} ({self.status})"
