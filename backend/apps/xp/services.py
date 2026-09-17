import datetime

from django.db.models import Sum
from django.utils import timezone

from apps.core.exceptions import SafeMessageError

from .models import XPLedgerEntry

# Flat per-attempt amounts (owner request, 2026-09-11) — the daily challenge
# earns more than an ordinary quiz since it's the app's own centerpiece
# gamification loop already (streaks, leaderboard); nothing more elaborate
# (score-scaled bonuses, difficulty tiers) was asked for or exists to base
# one on.
XP_PER_QUIZ_ATTEMPT = 10
XP_PER_DAILY_CHALLENGE_ATTEMPT = 25

# Owner request (2026-09-17): a real paper/report contribution or a
# successful referral should feed this same spendable balance too, not
# just quiz play -- awarded alongside (not instead of) the separate
# credits-based discount-code reward (apps.credits.services
# .award_contributor_bonus / .award_referral_bonus), which is unchanged.
XP_PER_CONTRIBUTION = 15
XP_PER_REFERRAL = 10

# Matches the real "+1 slot for 3 days" copy already shown on My
# Downloads — this is what makes that card real instead of a coming-soon
# placeholder. Raised from 250 (owner request, 2026-09-17) now that real
# contributions feed this balance too, not just quiz play.
SLOT_BONUS_COST_XP = 500
SLOT_BONUS_DURATION_DAYS = 3


class InsufficientXPError(SafeMessageError):
    pass


def xp_balance(user) -> int:
    return XPLedgerEntry.objects.filter(user=user).aggregate(total=Sum("amount"))["total"] or 0


def award_quiz_attempt_xp(*, user, quiz) -> int:
    """Called once per real QuizAttempt (see apps.quizzes.services
    .submit_attempt) — never for a guest, since quiz submission itself is
    already IsAuthenticatedNotGuest-gated. Returns the amount awarded so
    the caller can surface it (e.g. "+10 XP") without a second query."""
    amount = XP_PER_DAILY_CHALLENGE_ATTEMPT if quiz.is_daily_challenge else XP_PER_QUIZ_ATTEMPT
    XPLedgerEntry.objects.create(user=user, amount=amount, reason=f"Completed quiz: {quiz.title}")
    return amount


def award_contribution_xp(user) -> int:
    """Called by the caller only once a real contributor-credit bonus has
    actually been awarded (apps.credits.services.award_contributor_bonus
    returned a real entry, not None) -- piggybacks on that function's own
    is_duplicate check rather than duplicating it here."""
    XPLedgerEntry.objects.create(user=user, amount=XP_PER_CONTRIBUTION, reason="Paper/report contribution accepted")
    return XP_PER_CONTRIBUTION


def award_referral_xp(user) -> int:
    """Same pattern as award_contribution_xp -- called only once
    apps.credits.services.award_referral_bonus has actually awarded a real
    credit entry, piggybacking on its own once-only idempotency guard."""
    XPLedgerEntry.objects.create(user=user, amount=XP_PER_REFERRAL, reason="Referral bonus")
    return XP_PER_REFERRAL


def redeem_slot_bonus(user):
    """
    Spends SLOT_BONUS_COST_XP for +1 offline download slot, active for
    SLOT_BONUS_DURATION_DAYS from now (always a fresh window from the
    moment of redemption — same "renew fresh, don't stack" shape as
    apps.payments.services.subscribe, not a more elaborate
    extend-from-existing-expiry scheme nothing else in this app uses).
    Returns the new bonus_offline_slot_until.
    """
    balance = xp_balance(user)
    if balance < SLOT_BONUS_COST_XP:
        raise InsufficientXPError(f"You need {SLOT_BONUS_COST_XP} XP to redeem this. You have {balance}.")
    XPLedgerEntry.objects.create(user=user, amount=-SLOT_BONUS_COST_XP, reason="Redeemed: +1 offline slot for 3 days")
    user.bonus_offline_slot_until = timezone.now() + datetime.timedelta(days=SLOT_BONUS_DURATION_DAYS)
    user.save(update_fields=["bonus_offline_slot_until"])
    return user.bonus_offline_slot_until
