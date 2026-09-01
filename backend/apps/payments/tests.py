import datetime

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.accounts.models import User
from apps.credits.factories import RedeemCodeFactory
from apps.papers.factories import (
    ExamCategoryFactory,
    ExamTypeFactory,
    PaperSubmissionFactory,
)

from .factories import SubscriptionFactory
from .models import (
    PaperDownloadUnlock,
    PaperUnlock,
    PaymentTransactionStatus,
    Subscription,
    SubscriptionStatus,
)
from .services import (
    PAPER_UNLOCK_PRICE_FCFA,
    TRIAL_DAYS,
    PaperDownloadUnlockError,
    PaperUnlockError,
    first_unlock_free_eligible,
    trial_days_remaining,
    unlock_paper,
    unlock_paper_download,
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
def test_unlock_paper_rejects_a_free_tier_report():
    """Internship/Bachelor's/HND reports are free to download outright —
    calling unlock directly must not charge for something already free."""
    user = UserFactory()
    _expire_trial(user)
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    internship = ExamTypeFactory(category=reports_category, system=None, name="Internship Report")
    paper = PaperSubmissionFactory(category=reports_category, exam_type=internship, subject=None)

    with pytest.raises(PaperUnlockError):
        unlock_paper(user=user, paper_submission=paper, phone_number="670000000")
    assert PaperUnlock.objects.has_unlocked(user, paper) is False


@pytest.mark.django_db
def test_unlock_paper_still_charges_for_a_masters_tier_report():
    user = UserFactory()
    _expire_trial(user)
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    masters = ExamTypeFactory(
        category=reports_category, system=None, name="Master’s Thesis (Mémoire)", requires_payment_to_view=True
    )
    paper = PaperSubmissionFactory(category=reports_category, exam_type=masters, subject=None)

    unlock = unlock_paper(user=user, paper_submission=paper, phone_number="670000000")

    assert unlock.amount_paid == PAPER_UNLOCK_PRICE_FCFA


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


@pytest.mark.django_db
def test_unlock_paper_credits_the_referrer_on_first_unlock():
    from apps.credits.models import CreditLedgerEntry

    referrer = UserFactory()
    referred = UserFactory(referred_by=referrer)
    paper = PaperSubmissionFactory()
    unlock_paper(user=referred, paper_submission=paper, phone_number="670000000")
    assert CreditLedgerEntry.objects.filter(user=referrer).exists()
    referred.refresh_from_db()
    assert referred.referral_bonus_awarded_at is not None


@pytest.mark.django_db
def test_unlock_paper_does_not_credit_referrer_again_on_a_second_unlock():
    from apps.credits.models import CreditLedgerEntry

    referrer = UserFactory()
    referred = UserFactory(referred_by=referrer)
    first_paper = PaperSubmissionFactory()
    second_paper = PaperSubmissionFactory()
    unlock_paper(user=referred, paper_submission=first_paper, phone_number="670000000")
    unlock_paper(user=referred, paper_submission=second_paper, phone_number="670000000")
    assert CreditLedgerEntry.objects.filter(user=referrer).count() == 1


@pytest.mark.django_db
def test_unlock_paper_download_charges_the_category_price_and_creates_a_real_unlock():
    user = UserFactory()
    # ExamCategoryFactory's default key is "secondary" -> 75 FCFA.
    paper = PaperSubmissionFactory()

    unlock = unlock_paper_download(user=user, paper_submission=paper, phone_number="670000000")

    assert unlock.amount_paid == 75
    assert unlock.payment_transaction.status == PaymentTransactionStatus.SUCCESS
    assert PaperDownloadUnlock.objects.has_unlocked(user, paper) is True


@pytest.mark.django_db
def test_unlock_paper_download_prices_by_exam_level():
    user = UserFactory()
    primary = ExamCategoryFactory(key="primary", requires_system=False)
    primary_type = ExamTypeFactory(category=primary, system=None)
    primary_paper = PaperSubmissionFactory(category=primary, exam_type=primary_type)

    university = ExamCategoryFactory(key="university", requires_system=True)
    university_type = ExamTypeFactory(category=university)
    university_paper = PaperSubmissionFactory(category=university, exam_type=university_type)

    primary_unlock = unlock_paper_download(user=user, paper_submission=primary_paper, phone_number="670000000")
    university_unlock = unlock_paper_download(user=user, paper_submission=university_paper, phone_number="670000000")

    assert primary_unlock.amount_paid == 50
    assert university_unlock.amount_paid == 100


@pytest.mark.django_db
def test_unlock_paper_download_rejects_double_unlock():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    unlock_paper_download(user=user, paper_submission=paper, phone_number="670000000")
    with pytest.raises(PaperDownloadUnlockError):
        unlock_paper_download(user=user, paper_submission=paper, phone_number="670000000")


@pytest.mark.django_db
def test_unlock_paper_download_rejects_a_report():
    """Reports use the existing unlock_paper-based download gate — this is
    exam-paper only."""
    user = UserFactory()
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    report_type = ExamTypeFactory(category=reports_category, system=None, name="Internship Report")
    report = PaperSubmissionFactory(category=reports_category, exam_type=report_type, subject=None)

    with pytest.raises(PaperDownloadUnlockError):
        unlock_paper_download(user=user, paper_submission=report, phone_number="670000000")
    assert PaperDownloadUnlock.objects.has_unlocked(user, report) is False


@pytest.mark.django_db
def test_unlock_paper_download_view_creates_a_real_unlock(api_client):
    user = UserFactory()
    paper = PaperSubmissionFactory()
    api_client.force_authenticate(user=user)

    response = api_client.post(
        "/api/payments/unlock-download/",
        {"paper_submission": paper.id, "phone_number": "670000000"},
        format="json",
    )

    assert response.status_code == 201
    assert response.data["amount_paid"] == 75
    assert PaperDownloadUnlock.objects.has_unlocked(user, paper) is True


@pytest.mark.django_db
def test_unlock_paper_download_view_rejects_a_report(api_client):
    user = UserFactory()
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    report_type = ExamTypeFactory(category=reports_category, system=None, name="Internship Report")
    report = PaperSubmissionFactory(category=reports_category, exam_type=report_type, subject=None)
    api_client.force_authenticate(user=user)

    response = api_client.post(
        "/api/payments/unlock-download/",
        {"paper_submission": report.id, "phone_number": "670000000"},
        format="json",
    )

    assert response.status_code == 402


@pytest.mark.django_db
def test_submitter_and_staff_can_download_their_own_exam_paper_without_unlocking():
    from apps.papers.services import user_can_download_paper_file

    submitter = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=submitter)
    staff = UserFactory(is_staff=True)
    stranger = UserFactory()

    assert user_can_download_paper_file(submitter, paper) is True
    assert user_can_download_paper_file(staff, paper) is True
    assert user_can_download_paper_file(stranger, paper) is False


@pytest.mark.django_db
def test_paper_serializer_exposes_download_unlock_state_and_price(api_client):
    from apps.papers.serializers import PaperSubmissionDetailSerializer

    user = UserFactory()
    paper = PaperSubmissionFactory()

    unlocked_data = PaperSubmissionDetailSerializer(paper, context={"request": _fake_authed_request(user)}).data
    assert unlocked_data["paper_download_unlocked"] is False
    assert unlocked_data["paper_download_price_fcfa"] == 75

    unlock_paper_download(user=user, paper_submission=paper, phone_number="670000000")
    now_unlocked_data = PaperSubmissionDetailSerializer(paper, context={"request": _fake_authed_request(user)}).data
    assert now_unlocked_data["paper_download_unlocked"] is True


def _fake_authed_request(user):
    class _Req:
        pass

    req = _Req()
    req.user = user
    return req
