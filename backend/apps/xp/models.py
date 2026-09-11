from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class XPLedgerEntry(TimeStampedModel):
    """
    Real, auditable XP ledger (owner request, 2026-09-11 — the first real
    definition of XP anywhere in this app) — same append-only-ledger shape
    as apps.credits.CreditLedgerEntry, but a genuinely distinct economy:
    student-engagement gamification (quiz play), not contributor rewards.
    amount is negative for a redemption (see apps.xp.services
    .redeem_slot_bonus) so the balance is always just a real sum, never a
    separately-tracked counter that could drift from its own history.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="xp_ledger_entries")
    amount = models.IntegerField()
    reason = models.CharField(max_length=200)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} {self.amount:+d} ({self.reason})"
