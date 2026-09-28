from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class XPLedgerEntry(TimeStampedModel):
    """
    The single, auditable Points balance (users see "points"; internal names
    keep "xp"). Quiz play, accepted papers and referrals all pay in here, and
    redemptions (apps.xp.services.redeem_slot_bonus) spend from it. Until
    2026-09-28 contributor "credits" were a second, separate ledger with
    nothing to spend them on (apps.credits.CreditLedgerEntry, now retired);
    they were merged into this one so there is one simple balance.
    amount is negative for a redemption, so the balance is always just a real
    sum, never a separately-tracked counter that could drift from its history.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="xp_ledger_entries")
    amount = models.IntegerField()
    reason = models.CharField(max_length=200)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "points ledger entry"
        verbose_name_plural = "points ledger entries"

    def __str__(self):
        return f"{self.user} {self.amount:+d} ({self.reason})"
