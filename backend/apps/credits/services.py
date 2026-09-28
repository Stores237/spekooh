import datetime
import logging
from typing import NamedTuple

from django.db import transaction
from django.utils import timezone

from apps.core.exceptions import SafeMessageError
from apps.xp.models import XPLedgerEntry

from .models import (
    ContributorBonusConfig,
    RedeemCode,
    RedeemCodeContribution,
    RedeemCodeStatus,
    RedeemCodeTierConfig,
    ReferralBonusConfig,
)

logger = logging.getLogger(__name__)


class RedeemCodeError(SafeMessageError):
    pass


class CreditEngineError(SafeMessageError):
    pass


@transaction.atomic
def redeem_code(code: str, redeemed_by) -> RedeemCode:
    """Applies a redeem code, locking the row so concurrent redemption attempts can't double-spend it."""
    try:
        redeem = RedeemCode.objects.select_for_update().get(code=code)
    except RedeemCode.DoesNotExist:
        raise RedeemCodeError("Redeem code not found.")

    if redeem.status == RedeemCodeStatus.REDEEMED:
        raise RedeemCodeError("Redeem code has already been used.")

    if redeem.status == RedeemCodeStatus.EXPIRED or redeem.expires_at <= timezone.now():
        redeem.status = RedeemCodeStatus.EXPIRED
        redeem.save(update_fields=["status", "updated_at"])
        raise RedeemCodeError("Redeem code has expired.")

    redeem.status = RedeemCodeStatus.REDEEMED
    redeem.redeemed_by = redeemed_by
    redeem.redeemed_at = timezone.now()
    redeem.save(update_fields=["status", "redeemed_by", "redeemed_at", "updated_at"])
    return redeem


def award_contributor_bonus(paper_submission) -> XPLedgerEntry | None:
    """Points per accepted, non-duplicate submission (spec §5.1). No points for duplicates.

    Paid into the single Points balance (apps.xp.XPLedgerEntry) -- credits and
    XP were merged on 2026-09-28 (owner decision: one simple reward balance).
    The amount is still ops-editable via ContributorBonusConfig."""
    if paper_submission.is_duplicate:
        return None
    config = ContributorBonusConfig.objects.first() or ContributorBonusConfig.objects.create()
    return XPLedgerEntry.objects.create(
        user=paper_submission.submitted_by,
        amount=config.amount,
        reason="Paper accepted and published",
    )


def award_referral_bonus(referred_user) -> XPLedgerEntry | None:
    """Pays the referrer points once, the first time their referred user
    completes a real first action (currently: their first paper unlock —
    see apps.payments.services.unlock_paper). referral_bonus_awarded_at is
    the idempotency guard, claimed via a conditional UPDATE (not a Python
    read-then-write) so two concurrent unlock requests for the same brand
    -new user can't both pass the check and double-credit the referrer."""
    referrer = referred_user.referred_by
    if referrer is None or referred_user.referral_bonus_awarded_at is not None:
        return None
    now = timezone.now()
    claimed = type(referred_user).objects.filter(
        pk=referred_user.pk, referral_bonus_awarded_at__isnull=True
    ).update(referral_bonus_awarded_at=now)
    if not claimed:
        return None
    referred_user.referral_bonus_awarded_at = now
    config = ReferralBonusConfig.objects.first() or ReferralBonusConfig.objects.create()
    return XPLedgerEntry.objects.create(
        user=referrer,
        amount=config.amount,
        reason=f"Referral bonus: {referred_user.name or referred_user.email} unlocked their first paper",
    )


class CodeGrant(NamedTuple):
    code: RedeemCode
    created: bool  # True: a new code; False: the contributor's existing code was upgraded


def redeem_tier_for(accepted_count: int) -> RedeemCodeTierConfig | None:
    """The tier for a contributor's total of accepted papers (spec §5.1: more
    contribution, more valuable and longer-lived codes). Ops edit the bands
    in the admin."""
    return (
        RedeemCodeTierConfig.objects.filter(min_submissions__lte=accepted_count)
        .order_by("-min_submissions")
        .first()
    )


def accepted_paper_count(user) -> int:
    """Papers that count towards a contributor's tier: published and not a
    duplicate (a duplicate earns nothing)."""
    from apps.papers.models import PaperStatus, PaperSubmission

    return PaperSubmission.objects.filter(
        submitted_by=user, status=PaperStatus.PUBLISHED, is_duplicate=False
    ).count()


@transaction.atomic
def grant_redeem_code(paper_submission) -> CodeGrant | None:
    """Called when a paper is accepted and published. Gives its contributor a
    discount code, or improves the one they already hold -- never a second.

    - No active code (never had one, or the last was used or expired): a new
      code at the tier for their total of accepted papers.
    - An active code exists: that same code is upgraded in place. Its discount
      becomes the higher of its current value and the new tier's, and its
      expiry the later of its current one and today plus the tier's validity,
      so it never gets worse and each accepted paper keeps it alive longer.

    Each paper counts once (RedeemCodeContribution.paper_submission is unique),
    and a duplicate counts never. Returns None when nothing was granted,
    including when no tier is configured, which must not block publishing.
    """
    if paper_submission.is_duplicate:
        return None
    if RedeemCodeContribution.objects.filter(paper_submission=paper_submission).exists():
        return None

    owner = paper_submission.submitted_by
    count = accepted_paper_count(owner)
    tier = redeem_tier_for(count) if count else None
    if tier is None:
        logger.warning("No redeem code tier applies to %s accepted papers; no code granted for paper %s.", count, paper_submission.pk)
        return None

    now = timezone.now()
    new_expiry = now + datetime.timedelta(days=tier.expiry_days)
    code = (
        RedeemCode.objects.select_for_update()
        .filter(owner=owner, status=RedeemCodeStatus.ACTIVE, expires_at__gt=now)
        .order_by("-value_percent", "-expires_at")
        .first()
    )
    if code is None:
        code = RedeemCode.objects.create(
            owner=owner, value_percent=tier.value_percent, tier_at_issuance=count, expires_at=new_expiry
        )
        created = True
    else:
        code.value_percent = max(code.value_percent, tier.value_percent)
        code.expires_at = max(code.expires_at, new_expiry)
        code.tier_at_issuance = count
        code.save(update_fields=["value_percent", "expires_at", "tier_at_issuance", "updated_at"])
        created = False

    RedeemCodeContribution.objects.create(code=code, paper_submission=paper_submission)
    return CodeGrant(code=code, created=created)


def award_contribution_rewards(paper_submission) -> tuple[XPLedgerEntry | None, CodeGrant | None]:
    """Everything a contributor earns when a paper is accepted: points, and a
    discount code (new or upgraded). The one call both publish paths make."""
    return award_contributor_bonus(paper_submission), grant_redeem_code(paper_submission)
