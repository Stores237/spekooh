import datetime

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.papers.factories import (
    ExamCategoryFactory,
    ExamTypeFactory,
    PaperSubmissionFactory,
    SubjectFactory,
)
from apps.papers.models import PaperStatus

from .factories import CreditLedgerEntryFactory, RedeemCodeFactory
from .models import (
    ContributorBonusConfig,
    CreditLedgerEntry,
    RedeemCodeStatus,
    ReferralBonusConfig,
    SubjectDemandFactor,
)
from .rules_engine import (
    ComplexityLevel,
    CreditRulesError,
    MarkingQuestion,
    PaperCreditCalculator,
    QuestionType,
)
from .services import (
    RedeemCodeError,
    RedeemCodeIssuer,
    award_contributor_bonus,
    award_referral_bonus,
    redeem_code,
)


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_ledger_lists_only_own_entries(api_client):
    me = UserFactory()
    other = UserFactory()
    CreditLedgerEntryFactory(user=me, amount=200)
    CreditLedgerEntryFactory(user=other, amount=500)
    api_client.force_authenticate(user=me)
    response = api_client.get("/api/credits/ledger/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert response.status_code == 200
    assert len(rows) == 1
    assert rows[0]["amount"] == 200


@pytest.mark.django_db
def test_redeem_code_service_marks_used_and_records_redeemer():
    owner = UserFactory()
    redeemer = UserFactory()
    code = RedeemCodeFactory(owner=owner)
    result = redeem_code(code.code, redeemed_by=redeemer)
    assert result.status == RedeemCodeStatus.REDEEMED
    assert result.redeemed_by == redeemer
    assert result.redeemed_at is not None


@pytest.mark.django_db
def test_redeem_code_service_rejects_double_use():
    code = RedeemCodeFactory()
    first = UserFactory()
    second = UserFactory()
    redeem_code(code.code, redeemed_by=first)
    with pytest.raises(RedeemCodeError):
        redeem_code(code.code, redeemed_by=second)


@pytest.mark.django_db
def test_redeem_code_service_rejects_expired_code():
    code = RedeemCodeFactory(expires_at=timezone.now() - datetime.timedelta(days=1))
    with pytest.raises(RedeemCodeError):
        redeem_code(code.code, redeemed_by=UserFactory())


@pytest.mark.django_db
def test_redeem_code_by_different_user_than_owner_is_allowed_end_to_end(api_client):
    owner = UserFactory()
    redeemer = UserFactory()
    code = RedeemCodeFactory(owner=owner)
    api_client.force_authenticate(user=redeemer)
    response = api_client.post("/api/credits/redeem-codes/apply/", {"code": code.code}, format="json")
    assert response.status_code == 200
    assert response.data["status"] == RedeemCodeStatus.REDEEMED
    assert response.data["redeemed_by"] == redeemer.id


@pytest.mark.django_db
def test_apply_unknown_code_returns_400(api_client):
    api_client.force_authenticate(user=UserFactory())
    response = api_client.post("/api/credits/redeem-codes/apply/", {"code": "NOPE12345"}, format="json")
    assert response.status_code == 400


# --- Credit rules engine (Stage 7) ---


@pytest.mark.django_db
def test_worked_example_from_spec_o_level_physics_four_essay_questions():
    subject = SubjectFactory(key="physics_worked", title="Physics")
    SubjectDemandFactor.objects.create(subject=subject, factor="1.3")

    calculator = PaperCreditCalculator()
    questions = [MarkingQuestion(question_type=QuestionType.ESSAY) for _ in range(4)]
    total = calculator.calculate(questions=questions, level=ComplexityLevel.O_LEVEL, subject=subject)

    assert total == 2496


@pytest.mark.django_db
def test_calculator_defaults_to_1x_demand_when_no_factor_configured():
    subject = SubjectFactory(key="no_demand_factor", title="Undemanded Subject")
    calculator = PaperCreditCalculator()
    questions = [MarkingQuestion(question_type=QuestionType.SHORT_ANSWER)]
    total = calculator.calculate(questions=questions, level=ComplexityLevel.BASIC, subject=subject)
    assert total == 200  # 200 base * 1.0 multiplier * 1.0 default demand


@pytest.mark.django_db
def test_calculator_rejects_mcq_questions():
    subject = SubjectFactory(key="mcq_reject_subject")
    calculator = PaperCreditCalculator()
    with pytest.raises(CreditRulesError, match="MCQ"):
        calculator.calculate(
            questions=[MarkingQuestion(question_type=QuestionType.MCQ)],
            level=ComplexityLevel.O_LEVEL,
            subject=subject,
        )


@pytest.mark.django_db
def test_calculator_requires_at_least_one_question():
    subject = SubjectFactory(key="empty_questions_subject")
    calculator = PaperCreditCalculator()
    with pytest.raises(CreditRulesError):
        calculator.calculate(questions=[], level=ComplexityLevel.O_LEVEL, subject=subject)


@pytest.mark.django_db
def test_redeem_code_issuer_picks_correct_tier_band():
    owner = UserFactory()
    low_tier = RedeemCodeIssuer().issue_for(owner=owner, accepted_submission_count=2)
    assert low_tier.value_percent == 5

    mid_tier = RedeemCodeIssuer().issue_for(owner=owner, accepted_submission_count=10)
    assert mid_tier.value_percent == 10

    high_tier = RedeemCodeIssuer().issue_for(owner=owner, accepted_submission_count=24)
    assert high_tier.value_percent == 20
    assert high_tier.tier_at_issuance == 24


@pytest.mark.django_db
def test_award_contributor_bonus_skips_duplicates():
    submitter = UserFactory()
    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    paper = PaperSubmissionFactory(submitted_by=submitter, category=category, exam_type=exam_type, is_duplicate=True)
    entry = award_contributor_bonus(paper)
    assert entry is None


@pytest.mark.django_db
def test_award_contributor_bonus_credits_non_duplicate():
    submitter = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=submitter, is_duplicate=False)
    entry = award_contributor_bonus(paper)
    assert entry is not None
    assert entry.amount == ContributorBonusConfig.objects.first().amount
    assert entry.user == submitter


@pytest.mark.django_db
def test_mark_published_endpoint_awards_bonus(api_client):
    admin_user = UserFactory(is_staff=True)
    submitter = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=submitter, is_duplicate=False)
    api_client.force_authenticate(user=admin_user)
    response = api_client.post(f"/api/papers/submissions/{paper.id}/mark_published/")
    assert response.status_code == 200
    assert response.data["status"] == PaperStatus.PUBLISHED
    assert CreditLedgerEntry.objects.filter(user=submitter).exists()


@pytest.mark.django_db
def test_issue_redeem_code_endpoint_counts_published_submissions(api_client):
    user = UserFactory()
    for _ in range(6):
        PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PUBLISHED)
    api_client.force_authenticate(user=user)
    response = api_client.post("/api/credits/redeem-codes/issue/")
    assert response.status_code == 201
    assert response.data["value_percent"] == 10  # 6 accepted -> the 5+ tier


@pytest.mark.django_db
def test_award_referral_bonus_credits_the_referrer():
    referrer = UserFactory()
    referred = UserFactory(referred_by=referrer)
    entry = award_referral_bonus(referred)
    config = ReferralBonusConfig.objects.first()
    assert entry.user == referrer
    assert entry.amount == config.amount
    referred.refresh_from_db()
    assert referred.referral_bonus_awarded_at is not None


@pytest.mark.django_db
def test_award_referral_bonus_is_a_noop_without_a_referrer():
    user = UserFactory()
    assert award_referral_bonus(user) is None


@pytest.mark.django_db
def test_award_referral_bonus_fires_only_once():
    referrer = UserFactory()
    referred = UserFactory(referred_by=referrer)
    first = award_referral_bonus(referred)
    referred.refresh_from_db()
    second = award_referral_bonus(referred)
    assert first is not None
    assert second is None
    assert CreditLedgerEntry.objects.filter(user=referrer).count() == 1
