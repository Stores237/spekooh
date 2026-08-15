import datetime

from django.db import transaction
from django.utils import timezone

from .models import (
    ContributorBonusConfig,
    CreditLedgerEntry,
    RedeemCode,
    RedeemCodeStatus,
    RedeemCodeTierConfig,
    ReferralBonusConfig,
)


class RedeemCodeError(Exception):
    pass


class CreditEngineError(Exception):
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


def award_contributor_bonus(paper_submission) -> CreditLedgerEntry | None:
    """Bonus credit per accepted, non-duplicate submission (spec §5.1). No credit for duplicates."""
    if paper_submission.is_duplicate:
        return None
    config = ContributorBonusConfig.objects.first() or ContributorBonusConfig.objects.create()
    return CreditLedgerEntry.objects.create(
        user=paper_submission.submitted_by,
        paper_submission=paper_submission,
        amount=config.amount,
        reason="Paper accepted and published",
    )


def award_referral_bonus(referred_user) -> CreditLedgerEntry | None:
    """Credits the referrer once, the first time their referred user
    completes a real first action (currently: their first paper unlock —
    see apps.payments.services.unlock_paper). referral_bonus_awarded_at is
    the idempotency guard: a no-op on every unlock after the first, and a
    no-op entirely if this user wasn't referred by anyone."""
    referrer = referred_user.referred_by
    if referrer is None or referred_user.referral_bonus_awarded_at is not None:
        return None
    config = ReferralBonusConfig.objects.first() or ReferralBonusConfig.objects.create()
    entry = CreditLedgerEntry.objects.create(
        user=referrer,
        amount=config.amount,
        reason=f"Referral bonus — {referred_user.name or referred_user.email} unlocked their first paper",
    )
    referred_user.referral_bonus_awarded_at = timezone.now()
    referred_user.save(update_fields=["referral_bonus_awarded_at", "updated_at"])
    return entry


class RedeemCodeIssuer:
    """Issues a redeem code sized to the owner's contribution tier (spec §5.1)."""

    def issue_for(self, *, owner, accepted_submission_count: int) -> RedeemCode:
        tier = (
            RedeemCodeTierConfig.objects.filter(min_submissions__lte=accepted_submission_count)
            .order_by("-min_submissions")
            .first()
        )
        if tier is None:
            raise CreditEngineError("No redeem code tier is configured.")

        return RedeemCode.objects.create(
            owner=owner,
            value_percent=tier.value_percent,
            tier_at_issuance=accepted_submission_count,
            expires_at=timezone.now() + datetime.timedelta(days=tier.expiry_days),
        )
