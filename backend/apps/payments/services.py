import datetime

from django.utils import timezone

from apps.core.payment_provider import MockPaymentProvider, PaymentProvider
from apps.credits.services import RedeemCodeError, award_referral_bonus, redeem_code
from apps.papers.services import report_download_is_free

from .models import (
    PaperUnlock,
    PaymentPurpose,
    PaymentTransaction,
    PaymentTransactionStatus,
    Subscription,
    SubscriptionStatus,
)

# The one place a concrete PaymentProvider is chosen. Swapping to real
# Flutterwave later means changing this line, not any call site.
_provider: PaymentProvider = MockPaymentProvider()


def charge(*, user, purpose: str, amount_fcfa: int, phone_number: str, description: str) -> PaymentTransaction:
    result = _provider.charge(amount_fcfa=amount_fcfa, phone_number=phone_number, description=description)
    return PaymentTransaction.objects.create(
        user=user,
        purpose=purpose,
        amount_fcfa=amount_fcfa,
        phone_number=phone_number,
        status=PaymentTransactionStatus.SUCCESS if result.success else PaymentTransactionStatus.FAILED,
        provider_reference=result.provider_reference,
        failure_reason=result.failure_reason,
    )


class SubscriptionError(Exception):
    pass


PRO_MONTHLY_FCFA = 500


def subscribe(*, user, phone_number: str) -> Subscription:
    transaction = charge(
        user=user,
        purpose=PaymentPurpose.SUBSCRIPTION,
        amount_fcfa=PRO_MONTHLY_FCFA,
        phone_number=phone_number,
        description="Kawlo Plus: monthly subscription",
    )
    if transaction.status != PaymentTransactionStatus.SUCCESS:
        raise SubscriptionError(transaction.failure_reason or "Payment failed.")

    return Subscription.objects.create(
        user=user,
        status=SubscriptionStatus.ACTIVE,
        renews_at=timezone.now() + datetime.timedelta(days=30),
        payment_transaction=transaction,
    )


class PaperUnlockError(Exception):
    pass


# Illustrative default per the spec's example range (§5.3: "say, 300-500 XAF");
# no confirmed fixed price yet. Kept as a single constant so it's easy to retune.
PAPER_UNLOCK_PRICE_FCFA = 500

# Speculative — not in the confirmed spec, but a small, real onboarding perk:
# a brand-new account's very first marking-guide unlock is free for a week.
TRIAL_DAYS = 7


def trial_days_remaining(user) -> int:
    elapsed = (timezone.now() - user.created_at).days
    return max(0, TRIAL_DAYS - elapsed)


def first_unlock_free_eligible(user) -> bool:
    return trial_days_remaining(user) > 0 and not PaperUnlock.objects.filter(user=user).exists()


def unlock_paper(*, user, paper_submission, phone_number: str, redeem_code_str: str | None = None) -> PaperUnlock:
    if report_download_is_free(paper_submission):
        raise PaperUnlockError("This report is already free to download.")
    if PaperUnlock.objects.has_unlocked(user, paper_submission):
        raise PaperUnlockError("Already unlocked.")

    applied_code = None
    if redeem_code_str:
        try:
            applied_code = redeem_code(redeem_code_str, redeemed_by=user)
        except RedeemCodeError as exc:
            raise PaperUnlockError(str(exc)) from exc

    # The trial perk only applies to a plain first unlock — a redeem code
    # already grants a real discount, stacking both would be a fabricated
    # freebie disguised as two independently-real ones.
    if applied_code is None and first_unlock_free_eligible(user):
        unlock = PaperUnlock.objects.create(
            user=user, paper_submission=paper_submission, amount_paid=0, payment_transaction=None
        )
        award_referral_bonus(user)
        return unlock

    amount = PAPER_UNLOCK_PRICE_FCFA
    if applied_code is not None:
        amount = round(amount * (1 - applied_code.value_percent / 100))

    transaction = charge(
        user=user,
        purpose=PaymentPurpose.PAPER_UNLOCK,
        amount_fcfa=amount,
        phone_number=phone_number,
        description=f"Marking guide unlock: paper {paper_submission.id}",
    )
    if transaction.status != PaymentTransactionStatus.SUCCESS:
        raise PaperUnlockError(transaction.failure_reason or "Payment failed.")

    unlock = PaperUnlock.objects.create(
        user=user,
        paper_submission=paper_submission,
        amount_paid=amount,
        redeem_code_applied=applied_code,
        payment_transaction=transaction,
    )
    award_referral_bonus(user)
    return unlock
