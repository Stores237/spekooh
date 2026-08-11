import datetime

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.accounts.models import User
from apps.credits.factories import RedeemCodeFactory
from apps.papers.factories import PaperSubmissionFactory

from .factories import SubscriptionFactory
from .models import PaperUnlock, PaymentTransactionStatus, Subscription, SubscriptionStatus
from .services import (
    PAPER_UNLOCK_PRICE_FCFA,
    TRIAL_DAYS,
    PaperUnlockError,
    first_unlock_free_eligible,
    trial_days_remaining,
    unlock_paper,
)


def _expire_trial(user):
    """created_at is auto_now_add — bypass it with a bulk update to
    simulate an account old enough that its trial window has closed."""
    User.objects.filter(id=user.id).update(created_at=timezone.now() - datetime.timedelta(days=TRIAL_DAYS + 1))
    user.refresh_from_db()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_subscribe_endpoint_creates_active_subscription_via_mock_provider(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post("/api/payments/subscribe/", {"phone_number": "670123456"}, format="json")
    assert response.status_code == 201
    assert response.data["status"] == SubscriptionStatus.ACTIVE
    sub = Subscription.objects.get(user=user)
    assert sub.payment_transaction.status == PaymentTransactionStatus.SUCCESS
    assert sub.payment_transaction.provider_reference.startswith("mock-")


@pytest.mark.django_db
def test_has_active_subscription_manager_helper():
    user = UserFactory()
    assert Subscription.objects.has_active(user) is False
    SubscriptionFactory(user=user)
    assert Subscription.objects.has_active(user) is True


@pytest.mark.django_db
def test_unlock_paper_creates_unlock_and_charges_full_price():
    # Outside the trial window — a plain, non-first-unlock price check.
    user = UserFactory()
    _expire_trial(user)
    paper = PaperSubmissionFactory()
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    assert unlock.amount_paid == PAPER_UNLOCK_PRICE_FCFA
    assert PaperUnlock.objects.has_unlocked(user, paper) is True


@pytest.mark.django_db
def test_unlock_paper_applies_redeem_code_discount():
    user = UserFactory()
    _expire_trial(user)
    paper = PaperSubmissionFactory()
    code = RedeemCodeFactory(value_percent=20)
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000", redeem_code_str=code.code)
    assert unlock.amount_paid == round(PAPER_UNLOCK_PRICE_FCFA * 0.8)
    assert unlock.redeem_code_applied_id == code.id


@pytest.mark.django_db
def test_unlock_paper_rejects_double_unlock():
    user = UserFactory()
    _expire_trial(user)
    paper = PaperSubmissionFactory()
    unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    with pytest.raises(PaperUnlockError):
        unlock_paper(user=user, paper_submission=paper, phone_number="670000000")


@pytest.mark.django_db
def test_unlock_endpoint_end_to_end(api_client):
    user = UserFactory()
    _expire_trial(user)
    paper = PaperSubmissionFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post(
        "/api/payments/unlock/",
        {"paper_submission": paper.id, "phone_number": "670000000"},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["amount_paid"] == PAPER_UNLOCK_PRICE_FCFA


@pytest.mark.django_db
def test_trial_days_remaining_counts_down_from_a_fresh_account():
    user = UserFactory()
    assert trial_days_remaining(user) == TRIAL_DAYS


@pytest.mark.django_db
def test_trial_days_remaining_is_zero_once_expired():
    user = UserFactory()
    _expire_trial(user)
    assert trial_days_remaining(user) == 0


@pytest.mark.django_db
def test_first_unlock_free_eligible_for_a_fresh_account_with_no_prior_unlocks():
    user = UserFactory()
    assert first_unlock_free_eligible(user) is True


@pytest.mark.django_db
def test_first_unlock_free_eligible_false_once_trial_expired():
    user = UserFactory()
    _expire_trial(user)
    assert first_unlock_free_eligible(user) is False


@pytest.mark.django_db
def test_unlock_paper_waives_charge_for_first_unlock_within_trial():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    assert unlock.amount_paid == 0
    assert unlock.payment_transaction is None


@pytest.mark.django_db
def test_unlock_paper_charges_normally_for_a_second_unlock_even_within_trial():
    user = UserFactory()
    first_paper = PaperSubmissionFactory()
    second_paper = PaperSubmissionFactory()
    unlock_paper(user=user, paper_submission=first_paper, phone_number="670000000")
    second_unlock = unlock_paper(user=user, paper_submission=second_paper, phone_number="670000000")
    assert second_unlock.amount_paid == PAPER_UNLOCK_PRICE_FCFA


@pytest.mark.django_db
def test_unlock_paper_does_not_stack_trial_waiver_with_a_redeem_code():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    code = RedeemCodeFactory(value_percent=20)
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000", redeem_code_str=code.code)
    assert unlock.amount_paid == round(PAPER_UNLOCK_PRICE_FCFA * 0.8)
