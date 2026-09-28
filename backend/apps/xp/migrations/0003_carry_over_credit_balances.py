"""
Owner decision (2026-09-28): contributor credits and XP become one "Points"
balance. Credits could never be spent, so nobody loses anything by this; it
just makes the number a user already saw as credits part of the one balance
they can now spend.

Adds each user's total credit balance to the points ledger as a single entry.
Idempotent (a user who already has a carry-over entry is skipped) and
non-destructive: the credit ledger rows stay untouched as the audit trail, and
reversing this removes only the carry-over entries.
"""

from django.db import migrations
from django.db.models import Sum

CARRY_OVER_REASON = "Carried over from bonus credits"


def carry_over(apps, schema_editor):
    CreditLedgerEntry = apps.get_model("credits", "CreditLedgerEntry")
    XPLedgerEntry = apps.get_model("xp", "XPLedgerEntry")

    already = set(XPLedgerEntry.objects.filter(reason=CARRY_OVER_REASON).values_list("user_id", flat=True))
    totals = CreditLedgerEntry.objects.values("user_id").annotate(total=Sum("amount"))
    XPLedgerEntry.objects.bulk_create(
        [
            XPLedgerEntry(user_id=row["user_id"], amount=row["total"], reason=CARRY_OVER_REASON)
            for row in totals
            if row["total"] and row["total"] > 0 and row["user_id"] not in already
        ]
    )


def undo_carry_over(apps, schema_editor):
    XPLedgerEntry = apps.get_model("xp", "XPLedgerEntry")
    XPLedgerEntry.objects.filter(reason=CARRY_OVER_REASON).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("xp", "0002_alter_xpledgerentry_options"),
        ("credits", "0006_alter_creditledgerentry_options"),
    ]

    operations = [
        migrations.RunPython(carry_over, undo_carry_over),
    ]
