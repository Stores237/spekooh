import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.credits.factories import RedeemCodeFactory
from apps.papers.factories import PaperSubmissionFactory

from .factories import SubscriptionFactory
from .models import PaperUnlock, PaymentTransactionStatus, Subscription, SubscriptionStatus
from .services import PAPER_UNLOCK_PRICE_FCFA, PaperUnlockError, unlock_paper


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
    user = UserFactory()
    paper = PaperSubmissionFactory()
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    assert unlock.amount_paid == PAPER_UNLOCK_PRICE_FCFA
    assert PaperUnlock.objects.has_unlocked(user, paper) is True


@pytest.mark.django_db
def test_unlock_paper_applies_redeem_code_discount():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    code = RedeemCodeFactory(value_percent=20)
    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000", redeem_code_str=code.code)
    assert unlock.amount_paid == round(PAPER_UNLOCK_PRICE_FCFA * 0.8)
    assert unlock.redeem_code_applied_id == code.id


@pytest.mark.django_db
def test_unlock_paper_rejects_double_unlock():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    with pytest.raises(PaperUnlockError):
        unlock_paper(user=user, paper_submission=paper, phone_number="670000000")


@pytest.mark.django_db
def test_unlock_endpoint_end_to_end(api_client):
    user = UserFactory()
    paper = PaperSubmissionFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post(
        "/api/payments/unlock/",
        {"paper_submission": paper.id, "phone_number": "670000000"},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["amount_paid"] == PAPER_UNLOCK_PRICE_FCFA
