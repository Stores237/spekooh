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
    RedeemCode,
    RedeemCodeContribution,
    RedeemCodeStatus,
    RedeemCodeTierConfig,
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
    award_contributor_bonus,
    award_referral_bonus,
    grant_redeem_code,
    redeem_code,
    redeem_tier_for,
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
def test_redeem_tier_picks_the_right_band():
    """The seeded table: 1-4 papers 5%/7d, 5-14 10%/14d, 15-23 15%/21d, 24+ 20%/30d."""
    expected = {1: 5, 4: 5, 5: 10, 14: 10, 15: 15, 23: 15, 24: 20, 100: 20}
    for accepted, percent in expected.items():
        assert redeem_tier_for(accepted).value_percent == percent, accepted
    assert redeem_tier_for(1).expiry_days == 7
    assert redeem_tier_for(24).expiry_days == 30


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
    from apps.xp.services import xp_balance

    assert xp_balance(submitter) == ContributorBonusConfig.objects.first().amount


@pytest.mark.django_db
def test_mark_published_pays_one_balance_once_and_nothing_into_the_retired_credit_ledger(api_client):
    """Owner decision (2026-09-28): credits and XP are one "Points" balance.
    A published paper used to pay 50 credits AND 15 XP into two ledgers; it
    now pays the configured amount, once, into the single one."""
    from apps.xp.models import XPLedgerEntry
    from apps.xp.services import xp_balance

    admin_user = UserFactory(is_staff=True)
    submitter = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=submitter, is_duplicate=False)
    api_client.force_authenticate(user=admin_user)
    response = api_client.post(f"/api/papers/submissions/{paper.id}/mark_published/")
    assert response.status_code == 200
    assert xp_balance(submitter) == 50  # ContributorBonusConfig's default, not 50 + 15
    assert XPLedgerEntry.objects.filter(user=submitter).count() == 1
    assert not CreditLedgerEntry.objects.filter(user=submitter).exists()


@pytest.mark.django_db
def test_there_is_no_way_to_request_a_discount_code(api_client):
    """The old open endpoint let any signed-in user mint unlimited codes, even
    with no accepted paper. Codes are only ever earned now."""
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post("/api/credits/redeem-codes/issue/")
    assert response.status_code in (404, 405)
    assert not RedeemCode.objects.filter(owner=user).exists()


@pytest.mark.django_db
def test_the_owner_sees_the_code_they_earned_in_their_list(api_client):
    user = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PUBLISHED)
    grant = grant_redeem_code(paper)
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/credits/redeem-codes/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert [row["code"] for row in rows] == [grant.code.code]
    assert rows[0]["value_percent"] == 5


# --- automatic, accumulating discount codes (2026-09-28) -------------------


def _accepted_paper(user, **kwargs):
    return PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PUBLISHED, is_duplicate=False, **kwargs)


@pytest.mark.django_db
def test_the_first_accepted_paper_grants_a_code_at_the_first_tier():
    owner = UserFactory()
    grant = grant_redeem_code(_accepted_paper(owner))

    assert grant.created is True
    assert grant.code.owner == owner
    assert grant.code.value_percent == 5
    assert grant.code.tier_at_issuance == 1
    assert grant.code.status == RedeemCodeStatus.ACTIVE
    assert abs(grant.code.expires_at - (timezone.now() + datetime.timedelta(days=7))) < datetime.timedelta(minutes=1)


@pytest.mark.django_db
def test_a_second_accepted_paper_upgrades_the_same_code_instead_of_minting_another():
    owner = UserFactory()
    first = grant_redeem_code(_accepted_paper(owner))
    # "the next day": the code has 1 day left when the second paper is accepted.
    RedeemCode.objects.filter(pk=first.code.pk).update(expires_at=timezone.now() + datetime.timedelta(days=1))

    second = grant_redeem_code(_accepted_paper(owner))

    assert second.created is False
    assert second.code.pk == first.code.pk
    assert RedeemCode.objects.filter(owner=owner).count() == 1
    second.code.refresh_from_db()
    assert second.code.value_percent == 5  # still the first tier
    assert second.code.tier_at_issuance == 2
    assert second.code.expires_at > timezone.now() + datetime.timedelta(days=6, hours=23)  # the clock was refreshed


@pytest.mark.django_db
def test_reaching_the_next_tier_raises_the_discount_on_the_same_code():
    owner = UserFactory()
    grants = [grant_redeem_code(_accepted_paper(owner)) for _ in range(5)]

    assert {g.code.pk for g in grants} == {grants[0].code.pk}
    assert RedeemCode.objects.filter(owner=owner).count() == 1
    code = RedeemCode.objects.get(owner=owner)
    assert code.value_percent == 10  # the 5th accepted paper crosses into the 5-14 band
    assert code.expires_at > timezone.now() + datetime.timedelta(days=13)


@pytest.mark.django_db
def test_a_used_code_is_left_alone_and_the_next_paper_earns_a_fresh_one():
    owner = UserFactory()
    first = grant_redeem_code(_accepted_paper(owner))
    RedeemCode.objects.filter(pk=first.code.pk).update(status=RedeemCodeStatus.REDEEMED)

    second = grant_redeem_code(_accepted_paper(owner))

    assert second.created is True
    assert second.code.pk != first.code.pk
    first.code.refresh_from_db()
    assert first.code.status == RedeemCodeStatus.REDEEMED


@pytest.mark.django_db
def test_an_expired_code_is_replaced_not_revived():
    owner = UserFactory()
    first = grant_redeem_code(_accepted_paper(owner))
    RedeemCode.objects.filter(pk=first.code.pk).update(expires_at=timezone.now() - datetime.timedelta(days=1))

    second = grant_redeem_code(_accepted_paper(owner))

    assert second.created is True
    assert second.code.pk != first.code.pk


@pytest.mark.django_db
def test_a_discount_never_goes_down():
    owner = UserFactory()
    existing = RedeemCodeFactory(owner=owner, value_percent=15)

    grant = grant_redeem_code(_accepted_paper(owner))  # the tier for 1 paper is only 5%

    assert grant.created is False
    existing.refresh_from_db()
    assert existing.value_percent == 15


@pytest.mark.django_db
def test_a_duplicate_paper_earns_no_code():
    owner = UserFactory()
    duplicate = PaperSubmissionFactory(submitted_by=owner, status=PaperStatus.PUBLISHED, is_duplicate=True)

    assert grant_redeem_code(duplicate) is None
    assert not RedeemCode.objects.filter(owner=owner).exists()


@pytest.mark.django_db
def test_a_paper_counts_only_once_however_often_publishing_runs():
    owner = UserFactory()
    paper = _accepted_paper(owner)

    assert grant_redeem_code(paper) is not None
    assert grant_redeem_code(paper) is None
    assert RedeemCodeContribution.objects.filter(paper_submission=paper).count() == 1
    assert RedeemCode.objects.filter(owner=owner).count() == 1


@pytest.mark.django_db
def test_papers_that_are_not_accepted_do_not_count_towards_the_tier():
    owner = UserFactory()
    for status in (PaperStatus.PENDING_REVIEW, PaperStatus.REJECTED):
        PaperSubmissionFactory(submitted_by=owner, status=status)
    grant_redeem_code(_accepted_paper(owner))
    grant = grant_redeem_code(_accepted_paper(owner))

    assert grant.code.tier_at_issuance == 2  # only the two accepted ones


@pytest.mark.django_db
def test_no_configured_tier_grants_nothing_and_does_not_break_publishing():
    RedeemCodeTierConfig.objects.all().delete()
    owner = UserFactory()

    assert grant_redeem_code(_accepted_paper(owner)) is None
    assert not RedeemCode.objects.filter(owner=owner).exists()


@pytest.mark.django_db
def test_mark_published_grants_points_and_a_discount_code(api_client):
    admin_user = UserFactory(is_staff=True)
    submitter = UserFactory()
    paper = PaperSubmissionFactory(submitted_by=submitter, is_duplicate=False)
    api_client.force_authenticate(user=admin_user)

    response = api_client.post(f"/api/papers/submissions/{paper.id}/mark_published/")

    assert response.status_code == 200
    code = RedeemCode.objects.get(owner=submitter)
    assert code.value_percent == 5
    assert RedeemCodeContribution.objects.filter(code=code, paper_submission=paper).exists()


@pytest.mark.django_db
def test_admin_tier_table_shows_readable_paper_ranges():
    from django.contrib.admin.sites import AdminSite

    from .admin import RedeemCodeTierConfigAdmin

    tier_admin = RedeemCodeTierConfigAdmin(RedeemCodeTierConfig, AdminSite())
    labels = [tier_admin.papers_range(tier) for tier in RedeemCodeTierConfig.objects.order_by("min_submissions")]

    assert labels == ["1–4", "5–14", "15–23", "24 or more"]


# --- backfill for contributors who already had accepted papers (0008) ------


def _backfill():
    import importlib

    return importlib.import_module("apps.credits.migrations.0008_backfill_redeem_codes_for_existing_contributors")


@pytest.mark.django_db
def test_backfill_gives_each_existing_contributor_one_code_at_their_current_tier():
    from django.apps import apps

    veteran = UserFactory()
    for _ in range(6):
        _accepted_paper(veteran)
    beginner = UserFactory()
    _accepted_paper(beginner)
    PaperSubmissionFactory(submitted_by=beginner, status=PaperStatus.PENDING_REVIEW)  # not accepted: ignored
    PaperSubmissionFactory(submitted_by=beginner, status=PaperStatus.PUBLISHED, is_duplicate=True)  # duplicate: ignored

    _backfill().backfill(apps, None)

    veteran_code = RedeemCode.objects.get(owner=veteran)  # one code, not six
    assert veteran_code.value_percent == 10
    assert RedeemCodeContribution.objects.filter(code=veteran_code).count() == 6
    beginner_code = RedeemCode.objects.get(owner=beginner)
    assert beginner_code.value_percent == 5
    assert RedeemCodeContribution.objects.filter(code=beginner_code).count() == 1


@pytest.mark.django_db
def test_backfill_upgrades_an_existing_active_code_instead_of_adding_one():
    from django.apps import apps

    owner = UserFactory()
    existing = RedeemCodeFactory(owner=owner, value_percent=5)
    for _ in range(5):
        _accepted_paper(owner)

    _backfill().backfill(apps, None)

    assert RedeemCode.objects.filter(owner=owner).count() == 1
    existing.refresh_from_db()
    assert existing.value_percent == 10


@pytest.mark.django_db
def test_backfill_is_idempotent_and_papers_already_counted_cannot_earn_again():
    from django.apps import apps

    owner = UserFactory()
    for _ in range(3):
        _accepted_paper(owner)

    _backfill().backfill(apps, None)
    _backfill().backfill(apps, None)

    assert RedeemCode.objects.filter(owner=owner).count() == 1
    assert RedeemCodeContribution.objects.filter(code__owner=owner).count() == 3
    old_paper = owner.paper_submissions.first()
    assert grant_redeem_code(old_paper) is None  # already counted by the backfill


@pytest.mark.django_db
def test_award_referral_bonus_pays_the_referrer_points():
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
    from apps.xp.models import XPLedgerEntry

    assert XPLedgerEntry.objects.filter(user=referrer).count() == 1
    assert not CreditLedgerEntry.objects.filter(user=referrer).exists()
