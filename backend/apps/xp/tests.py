import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory

from .factories import XPLedgerEntryFactory
from .models import XPLedgerEntry
from .services import (
    SLOT_BONUS_COST_XP,
    InsufficientXPError,
    award_quiz_attempt_xp,
    redeem_slot_bonus,
    xp_balance,
)


@pytest.mark.django_db
def test_xp_balance_is_zero_for_an_account_that_has_never_earned_any():
    user = UserFactory()
    assert xp_balance(user) == 0


@pytest.mark.django_db
def test_xp_balance_is_a_real_sum_of_the_ledger_not_a_separate_counter():
    user = UserFactory()
    XPLedgerEntryFactory(user=user, amount=10)
    XPLedgerEntryFactory(user=user, amount=25)
    XPLedgerEntryFactory(user=user, amount=-5)
    assert xp_balance(user) == 30


@pytest.mark.django_db
def test_award_quiz_attempt_xp_gives_more_for_the_daily_challenge():
    from apps.quizzes.factories import QuizFactory

    user = UserFactory()
    ordinary = QuizFactory(is_daily_challenge=False)
    daily = QuizFactory(is_daily_challenge=True)

    ordinary_amount = award_quiz_attempt_xp(user=user, quiz=ordinary)
    daily_amount = award_quiz_attempt_xp(user=user, quiz=daily)

    assert ordinary_amount == 10
    assert daily_amount == 25
    assert xp_balance(user) == 35
    assert XPLedgerEntry.objects.filter(user=user).count() == 2


@pytest.mark.django_db
def test_redeem_slot_bonus_fails_honestly_below_the_real_cost():
    user = UserFactory()
    XPLedgerEntryFactory(user=user, amount=SLOT_BONUS_COST_XP - 1)

    with pytest.raises(InsufficientXPError):
        redeem_slot_bonus(user)

    user.refresh_from_db()
    assert user.bonus_offline_slot_until is None


@pytest.mark.django_db
def test_redeem_slot_bonus_spends_real_xp_and_grants_a_real_bonus_window():
    user = UserFactory()
    XPLedgerEntryFactory(user=user, amount=SLOT_BONUS_COST_XP)

    expires_at = redeem_slot_bonus(user)

    assert xp_balance(user) == 0
    user.refresh_from_db()
    assert user.bonus_offline_slot_until == expires_at


@pytest.mark.django_db
def test_redeem_slot_bonus_endpoint_requires_a_real_non_guest_account():
    client = APIClient()
    response = client.post("/api/xp/redeem-slot-bonus/")
    assert response.status_code == 401


@pytest.mark.django_db
def test_redeem_slot_bonus_endpoint_charges_402_when_insufficient():
    user = UserFactory()
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post("/api/xp/redeem-slot-bonus/")

    assert response.status_code == 402
    assert "250 XP" in response.data["detail"]


@pytest.mark.django_db
def test_redeem_slot_bonus_endpoint_succeeds_with_enough_real_xp():
    user = UserFactory()
    XPLedgerEntryFactory(user=user, amount=SLOT_BONUS_COST_XP)
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post("/api/xp/redeem-slot-bonus/")

    assert response.status_code == 200
    assert response.data["bonus_offline_slot_until"] is not None
