"""
Owner decision (2026-09-28): discount codes are now earned automatically, one
per contributor that accumulates with each accepted paper (see
apps.credits.services.grant_redeem_code), instead of being requested through
an open endpoint.

This gives every contributor who already has accepted papers their single
code, at the tier for their current total, and marks those papers as counted
so they cannot earn a code again. One code per contributor -- not one per old
paper: someone with 24 accepted papers gets one 20% code, not 24 of them.

If a contributor already holds an active code, it is upgraded the same way a
new accepted paper would upgrade it (higher of the two discounts, later of the
two expiries) instead of adding another.

Idempotent: only papers not yet counted are considered, so re-running it does
nothing. Reversing removes the counted-paper records only; codes that were
created stay (they are ordinary, expiring codes).
"""

import datetime

from django.db import migrations
from django.utils import timezone


def backfill(apps, schema_editor):
    PaperSubmission = apps.get_model("papers", "PaperSubmission")
    RedeemCode = apps.get_model("credits", "RedeemCode")
    RedeemCodeContribution = apps.get_model("credits", "RedeemCodeContribution")
    RedeemCodeTierConfig = apps.get_model("credits", "RedeemCodeTierConfig")

    accepted = PaperSubmission.objects.filter(status="PUBLISHED", is_duplicate=False)
    uncounted = (
        accepted.filter(redeem_code_contribution__isnull=True)
        .order_by("submitted_by_id", "id")
        .values_list("submitted_by_id", "id")
    )
    paper_ids_by_owner = {}
    for owner_id, paper_id in uncounted:
        paper_ids_by_owner.setdefault(owner_id, []).append(paper_id)

    now = timezone.now()
    for owner_id, paper_ids in paper_ids_by_owner.items():
        total = accepted.filter(submitted_by_id=owner_id).count()
        tier = RedeemCodeTierConfig.objects.filter(min_submissions__lte=total).order_by("-min_submissions").first()
        if tier is None:
            continue
        new_expiry = now + datetime.timedelta(days=tier.expiry_days)
        code = (
            RedeemCode.objects.filter(owner_id=owner_id, status="ACTIVE", expires_at__gt=now)
            .order_by("-value_percent", "-expires_at")
            .first()
        )
        if code is None:
            code = RedeemCode.objects.create(
                owner_id=owner_id, value_percent=tier.value_percent, tier_at_issuance=total, expires_at=new_expiry
            )
        else:
            code.value_percent = max(code.value_percent, tier.value_percent)
            code.expires_at = max(code.expires_at, new_expiry)
            code.tier_at_issuance = total
            code.save(update_fields=["value_percent", "expires_at", "tier_at_issuance", "updated_at"])
        RedeemCodeContribution.objects.bulk_create(
            [RedeemCodeContribution(code=code, paper_submission_id=paper_id) for paper_id in paper_ids]
        )


def undo_backfill(apps, schema_editor):
    apps.get_model("credits", "RedeemCodeContribution").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ("credits", "0007_redeemcodecontribution"),
    ]

    operations = [
        migrations.RunPython(backfill, undo_backfill),
    ]
