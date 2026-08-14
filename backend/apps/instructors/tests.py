import datetime
import json

import pytest
from django.core.management import call_command
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.admin_queue.models import AdminFlagQueue, FlagCategory
from apps.credits.models import CreditLedgerEntry
from apps.papers.factories import ExamCategoryFactory, ExamTypeFactory, PaperSubmissionFactory, SubjectFactory
from apps.papers.models import MCQAnswerKey, PaperStatus, PaperSubmission, PublishedGuide

from .factories import InstructorSubjectQueueFactory, PartnerCredentialFactory
from .models import (
    ACTIVE_INSTRUCTOR_REQUEST_STATUSES,
    InstructorCreditLedger,
    InstructorMarkingGuide,
    InstructorRequest,
    InstructorRequestStatus,
    WithdrawalRequest,
)
from .services import (
    GUIDE_REMINDER_DAYS,
    MergeError,
    RoutingError,
    handle_instructor_response,
    handle_marking_guide_submission,
    merge_and_publish,
    request_withdrawal,
    route_next_instructor,
)
from .webhook import sign_payload


@pytest.fixture
def api_client():
    return APIClient()


def _routable_paper(subject=None):
    category = ExamCategoryFactory(key="secondary")
    exam_type = ExamTypeFactory(category=category, name="O Level")
    subject = subject or SubjectFactory()
    return PaperSubmissionFactory(category=category, exam_type=exam_type, subject=subject)


# --- Routing ---


@pytest.mark.django_db
def test_route_next_instructor_picks_first_in_queue():
    subject = SubjectFactory(key="routing_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-b", priority_order=2)
    paper = _routable_paper(subject=subject)

    request = route_next_instructor(paper)

    assert request.instructor_id == "instructor-a"
    assert request.status == InstructorRequestStatus.PENDING
    paper.refresh_from_db()
    assert paper.status == PaperStatus.INSTRUCTOR_REQUEST_SENT


@pytest.mark.django_db
def test_route_next_instructor_skips_already_tried_instructors():
    subject = SubjectFactory(key="routing_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-b", priority_order=2)
    paper = _routable_paper(subject=subject)

    first = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=first.id, decision="REJECTED")

    second = InstructorRequest.objects.filter(paper=paper).exclude(id=first.id).get()
    assert second.instructor_id == "instructor-b"


@pytest.mark.django_db
def test_route_next_instructor_flags_admin_when_queue_exhausted():
    subject = SubjectFactory(key="routing_subject_3")
    paper = _routable_paper(subject=subject)

    result = route_next_instructor(paper)

    assert result is None
    paper.refresh_from_db()
    assert paper.status == PaperStatus.UNASSIGNED_ADMIN_QUEUE
    assert AdminFlagQueue.objects.filter(category=FlagCategory.UNASSIGNED_PAPER).count() == 1


@pytest.mark.django_db
def test_one_active_instructor_request_per_paper_enforced_at_db_level():
    subject = SubjectFactory(key="routing_subject_4")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    now = timezone.now()

    InstructorRequest.objects.create(
        paper=paper, instructor_id="instructor-a", sent_at=now, responds_by=now + datetime.timedelta(hours=48)
    )
    with pytest.raises(IntegrityError):
        with transaction.atomic():
            InstructorRequest.objects.create(
                paper=paper, instructor_id="instructor-b", sent_at=now, responds_by=now + datetime.timedelta(hours=48)
            )


# --- Instructor response handling ---


@pytest.mark.django_db
def test_handle_instructor_response_accepted_sets_guide_deadline():
    subject = SubjectFactory(key="response_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)

    result = handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    assert result.applied is True
    request.refresh_from_db()
    assert request.status == InstructorRequestStatus.ACCEPTED
    assert request.guide_deadline is not None
    paper.refresh_from_db()
    assert paper.status == PaperStatus.AWAITING_MARKING_GUIDE


@pytest.mark.django_db
def test_handle_instructor_response_rejected_auto_advances():
    subject = SubjectFactory(key="response_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-b", priority_order=2)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)

    handle_instructor_response(instructor_request_id=request.id, decision="REJECTED")

    assert InstructorRequest.objects.filter(paper=paper, status=InstructorRequestStatus.PENDING).get().instructor_id == "instructor-b"


@pytest.mark.django_db
def test_handle_instructor_response_ignores_and_flags_stale_state():
    subject = SubjectFactory(key="response_subject_3")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="REJECTED")

    # A second, contradictory decision arrives for the same (already-resolved) request.
    result = handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    assert result.applied is False
    assert AdminFlagQueue.objects.filter(category=FlagCategory.WEBHOOK_ANOMALY).count() == 1


# --- Marking guide submission + merge ---


@pytest.mark.django_db
def test_marking_guide_submission_creates_guide_and_credit_ledger():
    subject = SubjectFactory(key="guide_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    content = [{"question_type": "ESSAY"}, {"question_type": "ESSAY"}]
    guide = handle_marking_guide_submission(instructor_request_id=request.id, content=content)

    assert guide.instructor_id == "instructor-a"
    paper.refresh_from_db()
    assert paper.status == PaperStatus.GUIDE_SUBMITTED
    ledger_entry = InstructorCreditLedger.objects.get(paper=paper)
    assert ledger_entry.instructor_id == "instructor-a"
    assert ledger_entry.amount == 2 * 400 * 1.2  # ESSAY x O_LEVEL multiplier, demand defaults to 1.0x

    review_ticket = AdminFlagQueue.objects.get(category=FlagCategory.GUIDE_REVIEW)
    assert review_ticket.subject == guide
    assert "credit ceiling" not in review_ticket.reason.lower()  # under the default ceiling — no clamp note


@pytest.mark.django_db
def test_marking_guide_submission_clamps_credit_at_ceiling_and_flags_it():
    """Spec §5.2's "profit-deficit guardrail" — never pay out more than the configured ceiling per paper."""
    from apps.credits.models import CreditCeilingConfig

    CreditCeilingConfig.objects.create(max_credit_per_paper_xaf=500)

    subject = SubjectFactory(key="guide_subject_ceiling")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    # 2 essays * 400 * 1.2 = 960 XAF raw — above the 500 XAF ceiling just configured.
    content = [{"question_type": "ESSAY"}, {"question_type": "ESSAY"}]
    guide = handle_marking_guide_submission(instructor_request_id=request.id, content=content)

    ledger_entry = InstructorCreditLedger.objects.get(paper=paper)
    assert ledger_entry.amount == 500  # clamped, not the raw 960

    review_ticket = AdminFlagQueue.objects.get(category=FlagCategory.GUIDE_REVIEW)
    assert review_ticket.subject == guide
    assert "960" in review_ticket.reason and "500" in review_ticket.reason


@pytest.mark.django_db
def test_marking_guide_submission_rejects_non_accepted_request():
    subject = SubjectFactory(key="guide_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)  # still PENDING, never accepted

    with pytest.raises(RoutingError):
        handle_marking_guide_submission(instructor_request_id=request.id, content=[{"question_type": "ESSAY"}])
    assert AdminFlagQueue.objects.filter(category=FlagCategory.WEBHOOK_ANOMALY).count() == 1


@pytest.mark.django_db
def test_merge_and_publish_combines_mcq_and_instructor_guide_then_pays_bonus():
    subject = SubjectFactory(key="merge_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    MCQAnswerKey.objects.create(paper_submission=paper, content={"q1": "A"})
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")
    handle_marking_guide_submission(instructor_request_id=request.id, content=[{"question_type": "ESSAY"}])
    paper.refresh_from_db()

    published = merge_and_publish(paper)

    assert published.content["mcq"] == {"q1": "A"}
    assert published.content["non_mcq"] == [{"question_type": "ESSAY"}]
    paper.refresh_from_db()
    assert paper.status == PaperStatus.PUBLISHED
    assert CreditLedgerEntry.objects.filter(user=paper.submitted_by, paper_submission=paper).exists()


@pytest.mark.django_db
def test_merge_and_publish_requires_guide_submitted_status():
    paper = _routable_paper()
    with pytest.raises(MergeError):
        merge_and_publish(paper)


# --- Webhook signature verification + full dispatch ---


@pytest.mark.django_db
def test_webhook_rejects_missing_signature(api_client):
    PartnerCredentialFactory()
    response = api_client.post(
        "/api/instructors/webhook/",
        data=json.dumps({"event_type": "instructor_response"}),
        content_type="application/json",
    )
    assert response.status_code == 401


@pytest.mark.django_db
def test_webhook_rejects_invalid_signature(api_client):
    PartnerCredentialFactory()
    body = json.dumps({"event_type": "instructor_response", "instructor_request_id": 1, "decision": "ACCEPTED"}).encode()
    response = api_client.post(
        "/api/instructors/webhook/",
        data=body,
        content_type="application/json",
        HTTP_X_SPEKOOH_PARTNER_ID="partner-platform-1",
        HTTP_X_SPEKOOH_SIGNATURE="sha256=deadbeef",
        HTTP_X_SPEKOOH_TIMESTAMP=str(int(timezone.now().timestamp())),
    )
    assert response.status_code == 401


@pytest.mark.django_db
def test_webhook_rejects_stale_timestamp(api_client):
    credential = PartnerCredentialFactory()
    body = json.dumps({"event_type": "instructor_response", "instructor_request_id": 1, "decision": "ACCEPTED"}).encode()
    old_timestamp = str(int(timezone.now().timestamp()) - 3600)
    signature = sign_payload(secret=credential.hmac_secret, timestamp=old_timestamp, raw_body=body)
    response = api_client.post(
        "/api/instructors/webhook/",
        data=body,
        content_type="application/json",
        HTTP_X_SPEKOOH_PARTNER_ID=credential.partner_id,
        HTTP_X_SPEKOOH_SIGNATURE=signature,
        HTTP_X_SPEKOOH_TIMESTAMP=old_timestamp,
    )
    assert response.status_code == 401


def _post_webhook(api_client, credential, payload: dict):
    body = json.dumps(payload).encode()
    timestamp = str(int(timezone.now().timestamp()))
    signature = sign_payload(secret=credential.hmac_secret, timestamp=timestamp, raw_body=body)
    return api_client.post(
        "/api/instructors/webhook/",
        data=body,
        content_type="application/json",
        HTTP_X_SPEKOOH_PARTNER_ID=credential.partner_id,
        HTTP_X_SPEKOOH_SIGNATURE=signature,
        HTTP_X_SPEKOOH_TIMESTAMP=timestamp,
    )


@pytest.mark.django_db
def test_webhook_instructor_response_end_to_end(api_client):
    credential = PartnerCredentialFactory()
    subject = SubjectFactory(key="webhook_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)

    response = _post_webhook(
        api_client,
        credential,
        {"event_type": "instructor_response", "instructor_request_id": request.id, "decision": "ACCEPTED"},
    )

    assert response.status_code == 200
    assert response.data["applied"] is True
    request.refresh_from_db()
    assert request.status == InstructorRequestStatus.ACCEPTED


@pytest.mark.django_db
def test_webhook_marking_guide_submission_end_to_end(api_client):
    credential = PartnerCredentialFactory()
    subject = SubjectFactory(key="webhook_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    response = _post_webhook(
        api_client,
        credential,
        {
            "event_type": "marking_guide_submission",
            "instructor_request_id": request.id,
            "content": [{"question_type": "CALCULATION"}],
        },
    )

    assert response.status_code == 200
    assert response.data["applied"] is True
    assert InstructorMarkingGuide.objects.filter(paper=paper).exists()


# --- Timeout + reminder cron ---


@pytest.mark.django_db
def test_cron_times_out_stale_pending_requests_and_advances():
    subject = SubjectFactory(key="cron_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-b", priority_order=2)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    InstructorRequest.objects.filter(id=request.id).update(responds_by=timezone.now() - datetime.timedelta(hours=1))

    call_command("process_instructor_timeouts")

    request.refresh_from_db()
    assert request.status == InstructorRequestStatus.TIMED_OUT
    new_request = InstructorRequest.objects.filter(paper=paper, status=InstructorRequestStatus.PENDING).get()
    assert new_request.instructor_id == "instructor-b"


@pytest.mark.django_db
def test_cron_sends_day4_reminder_once():
    subject = SubjectFactory(key="cron_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")
    InstructorRequest.objects.filter(id=request.id).update(
        responded_at=timezone.now() - datetime.timedelta(days=GUIDE_REMINDER_DAYS[0])
    )

    call_command("process_instructor_timeouts")
    request.refresh_from_db()
    assert request.day4_reminder_sent_at is not None
    first_sent_at = request.day4_reminder_sent_at

    call_command("process_instructor_timeouts")
    request.refresh_from_db()
    assert request.day4_reminder_sent_at == first_sent_at  # not sent twice


# --- Admin-facing routing/merge endpoints ---


@pytest.mark.django_db
def test_route_endpoint_requires_staff(api_client):
    paper = _routable_paper()
    api_client.force_authenticate(user=UserFactory())
    response = api_client.post(f"/api/instructors/papers/{paper.id}/route/")
    assert response.status_code == 403


@pytest.mark.django_db
def test_route_endpoint_works_for_staff(api_client):
    subject = SubjectFactory(key="endpoint_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    api_client.force_authenticate(user=UserFactory(is_staff=True))
    response = api_client.post(f"/api/instructors/papers/{paper.id}/route/")
    assert response.status_code == 201
    assert response.data["instructor_id"] == "instructor-a"


# --- Withdrawal requests (spec §5.4 + §2.1 KYC/payout ticket) ---


@pytest.mark.django_db
def test_request_withdrawal_creates_request_and_approval_ticket():
    withdrawal = request_withdrawal(instructor_id="instructor-a", amount=15000, payout_method="MTN_MOMO")

    assert withdrawal.instructor_id == "instructor-a"
    assert withdrawal.amount == 15000
    assert WithdrawalRequest.objects.count() == 1

    ticket = AdminFlagQueue.objects.get(category=FlagCategory.WITHDRAWAL_APPROVAL)
    assert ticket.subject == withdrawal
    assert "instructor-a" in ticket.reason and "15000" in ticket.reason
