import datetime
import json

import pytest
import requests
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management import call_command
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.admin_queue.models import AdminFlagQueue, FlagCategory
from apps.credits.models import CreditLedgerEntry
from apps.papers.factories import (
    ExamCategoryFactory,
    ExamTypeFactory,
    PaperSubmissionFactory,
    SubjectFactory,
)
from apps.papers.models import MCQAnswerKey, PaperStatus

from .factories import InstructorSubjectQueueFactory, PartnerCredentialFactory
from .models import (
    InstructorCreditLedger,
    InstructorMarkingGuide,
    InstructorRequest,
    InstructorRequestStatus,
    WithdrawalRequest,
)
from .services import (
    GUIDE_REMINDER_DAYS,
    GuideFileError,
    MergeError,
    RoutingError,
    handle_instructor_response,
    handle_marking_guide_submission,
    merge_and_publish,
    request_withdrawal,
    route_next_instructor,
)
from .webhook import sign_payload, verify_webhook_request


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
    with pytest.raises(IntegrityError), transaction.atomic():
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
def test_marking_guide_submission_downloads_and_stores_an_uploaded_file(monkeypatch):
    # File mode: content is still required (a {question_type} tally, real
    # text/answer omitted) so PaperCreditCalculator has something to count
    # even though the real guide content lives in the file, not content.
    subject = SubjectFactory(key="guide_file_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    class _FakeResponse:
        content = b"%PDF-1.4 fake pdf bytes"

        def raise_for_status(self):
            pass

    monkeypatch.setattr("apps.instructors.services.requests.get", lambda url, timeout: _FakeResponse())

    guide = handle_marking_guide_submission(
        instructor_request_id=request.id,
        content=[{"question_type": "ESSAY"}, {"question_type": "ESSAY"}],
        guide_file_url="https://s-learn-beta.vercel.app/storage/guide.pdf",
    )

    assert guide.guide_file
    assert guide.guide_file.read() == b"%PDF-1.4 fake pdf bytes"
    assert InstructorCreditLedger.objects.filter(instructor_id="instructor-a", paper=paper).exists()


@pytest.mark.django_db
def test_marking_guide_submission_rejects_a_file_that_isnt_really_a_pdf(monkeypatch):
    subject = SubjectFactory(key="guide_file_subject_2")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    class _FakeResponse:
        content = b"not actually a pdf"

        def raise_for_status(self):
            pass

    monkeypatch.setattr("apps.instructors.services.requests.get", lambda url, timeout: _FakeResponse())

    with pytest.raises(GuideFileError):
        handle_marking_guide_submission(
            instructor_request_id=request.id,
            content=[{"question_type": "ESSAY"}],
            guide_file_url="https://s-learn-beta.vercel.app/storage/not-a-guide.exe",
        )
    assert not InstructorMarkingGuide.objects.filter(paper=paper).exists()


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
    assert published.content["guide_file_url"] is None
    paper.refresh_from_db()
    assert paper.status == PaperStatus.PUBLISHED
    assert CreditLedgerEntry.objects.filter(user=paper.submitted_by, paper_submission=paper).exists()

    # Owner request (2026-09-17): the merge-and-publish pipeline is the
    # other real place a paper gets accepted -- it must feed the same
    # spendable XP balance "Get more slots" reads from too, not just the
    # mark_published admin action.
    from apps.xp.services import XP_PER_CONTRIBUTION, xp_balance

    assert xp_balance(paper.submitted_by) == XP_PER_CONTRIBUTION


@pytest.mark.django_db
def test_merge_and_publish_uses_guide_file_url_and_omits_non_mcq_when_a_file_was_uploaded(monkeypatch):
    # A file-mode guide's content is only a credit-calculation tally (real
    # text/answer omitted) -- showing that to the paying customer would look
    # like a broken, empty guide, so the published content shows the file
    # instead and hides the tally.
    subject = SubjectFactory(key="merge_subject_file_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    class _FakeResponse:
        content = b"%PDF-1.4 fake pdf bytes"

        def raise_for_status(self):
            pass

    monkeypatch.setattr("apps.instructors.services.requests.get", lambda url, timeout: _FakeResponse())
    handle_marking_guide_submission(
        instructor_request_id=request.id,
        content=[{"question_type": "ESSAY"}],
        guide_file_url="https://s-learn-beta.vercel.app/storage/guide.pdf",
    )
    paper.refresh_from_db()

    published = merge_and_publish(paper)

    assert published.content["non_mcq"] is None
    assert published.content["guide_file_url"]


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


@pytest.mark.django_db
def test_webhook_marking_guide_submission_with_a_file_end_to_end(api_client, monkeypatch):
    credential = PartnerCredentialFactory()
    subject = SubjectFactory(key="webhook_subject_file_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)
    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    class _FakeResponse:
        content = b"%PDF-1.4 fake pdf bytes"

        def raise_for_status(self):
            pass

    monkeypatch.setattr("apps.instructors.services.requests.get", lambda url, timeout: _FakeResponse())

    response = _post_webhook(
        api_client,
        credential,
        {
            "event_type": "marking_guide_submission",
            "instructor_request_id": request.id,
            "content": [{"question_type": "CALCULATION"}],
            "guide_file_url": "https://s-learn-beta.vercel.app/storage/guide.pdf",
        },
    )

    assert response.status_code == 200
    assert response.data["applied"] is True
    guide = InstructorMarkingGuide.objects.get(paper=paper)
    assert guide.guide_file


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


# --- Outbound partner webhook (apps.instructors.outbound) ---


@pytest.mark.django_db
def test_outbound_webhook_is_a_no_op_without_a_configured_partner_url(settings, monkeypatch):
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = ""
    posted = []
    monkeypatch.setattr("apps.instructors.outbound.requests.post", lambda *a, **k: posted.append(1))

    from .outbound import send_partner_webhook

    assert send_partner_webhook(event_type="new_request", payload={}) is False
    assert posted == []


@pytest.mark.django_db
def test_outbound_webhook_sends_a_correctly_signed_request(settings, monkeypatch):
    credential = PartnerCredentialFactory(partner_id="s-learn")
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = "https://s-learn-beta.vercel.app/functions/v1/spekooh-webhook"
    settings.INSTRUCTOR_PARTNER_ID = "s-learn"

    captured = {}

    class _FakeResponse:
        def raise_for_status(self):
            pass

    def _fake_post(url, data, headers, timeout):
        captured["url"] = url
        captured["data"] = data
        captured["headers"] = headers
        captured["timeout"] = timeout
        return _FakeResponse()

    monkeypatch.setattr("apps.instructors.outbound.requests.post", _fake_post)

    from .outbound import send_partner_webhook

    assert send_partner_webhook(event_type="new_request", payload={"instructor_id": "instructor-a"}) is True

    assert captured["url"] == settings.INSTRUCTOR_PARTNER_WEBHOOK_URL
    assert captured["headers"]["X-Spekooh-Partner-Id"] == "s-learn"
    # Same verify_webhook_request the inbound endpoint uses — proves this is
    # a genuine round-trippable signature, not just "some header exists".
    verified = verify_webhook_request(
        partner_id="s-learn",
        raw_body=captured["data"],
        signature_header=captured["headers"]["X-Spekooh-Signature"],
        timestamp_header=captured["headers"]["X-Spekooh-Timestamp"],
    )
    assert verified == credential
    assert json.loads(captured["data"]) == {"event_type": "new_request", "instructor_id": "instructor-a"}


@pytest.mark.django_db
def test_outbound_webhook_failure_is_swallowed_not_raised(settings, monkeypatch):
    PartnerCredentialFactory(partner_id="s-learn")
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = "https://s-learn-beta.vercel.app/functions/v1/spekooh-webhook"
    settings.INSTRUCTOR_PARTNER_ID = "s-learn"

    def _raise(*args, **kwargs):
        raise requests.ConnectionError("simulated network failure")

    monkeypatch.setattr("apps.instructors.outbound.requests.post", _raise)

    from .outbound import send_partner_webhook

    assert send_partner_webhook(event_type="new_request", payload={}) is False


@pytest.mark.django_db
def test_notify_new_request_builds_a_real_payload_from_a_real_request(settings, monkeypatch):
    # Regression: every other outbound test here calls send_partner_webhook
    # directly or monkeypatches notify_new_request itself, so none of them
    # ever executed notify_new_request's own body -- which is exactly how a
    # real bug (Subject has no attribute "name"; the field is "title")
    # shipped and only surfaced live, routing a real paper against staging.
    PartnerCredentialFactory(partner_id="s-learn")
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = "https://s-learn-beta.vercel.app/functions/v1/spekooh-webhook"
    settings.INSTRUCTOR_PARTNER_ID = "s-learn"

    subject = SubjectFactory(key="notify_new_request_subject", title="Biology")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)

    captured = {}

    class _FakeResponse:
        def raise_for_status(self):
            pass

    def _fake_post(url, data, headers, timeout):
        captured["data"] = data
        return _FakeResponse()

    monkeypatch.setattr("apps.instructors.outbound.requests.post", _fake_post)

    request = route_next_instructor(paper)

    from .outbound import notify_new_request

    assert notify_new_request(request) is True
    assert json.loads(captured["data"])["subject"] == "Biology"
    assert json.loads(captured["data"])["paper_file_url"] is None


@pytest.mark.django_db
def test_notify_new_request_includes_the_real_question_paper_file_url(settings, monkeypatch):
    # Found live, 2026-09-16: the instructor had a subject name and nothing
    # else -- no way to actually see what they were being asked to mark.
    PartnerCredentialFactory(partner_id="s-learn")
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = "https://s-learn-beta.vercel.app/functions/v1/spekooh-webhook"
    settings.INSTRUCTOR_PARTNER_ID = "s-learn"

    subject = SubjectFactory(key="notify_new_request_file_subject")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    category = ExamCategoryFactory(key="notify_new_request_file_category")
    exam_type = ExamTypeFactory(category=category, name="O Level file test")
    paper = PaperSubmissionFactory(
        category=category,
        exam_type=exam_type,
        subject=subject,
        uploaded_file=SimpleUploadedFile("gce-bio-2024.pdf", b"%PDF-1.4 fake pdf bytes", content_type="application/pdf"),
    )

    captured = {}

    class _FakeResponse:
        def raise_for_status(self):
            pass

    def _fake_post(url, data, headers, timeout):
        captured["data"] = data
        return _FakeResponse()

    monkeypatch.setattr("apps.instructors.outbound.requests.post", _fake_post)

    request = route_next_instructor(paper)

    from .outbound import notify_new_request

    assert notify_new_request(request) is True
    assert json.loads(captured["data"])["paper_file_url"]


@pytest.mark.django_db(transaction=True)
def test_route_next_instructor_pushes_a_new_request_notification_on_commit(settings, monkeypatch):
    # transaction=True: on_commit callbacks are only ever fired on a real
    # commit of the OUTERMOST atomic block, which pytest-django's default
    # (test-wrapping, never-committed) transaction handling would silently
    # discard -- this is the one test in the file that needs the real thing.
    PartnerCredentialFactory(partner_id="s-learn")
    settings.INSTRUCTOR_PARTNER_WEBHOOK_URL = "https://s-learn-beta.vercel.app/functions/v1/spekooh-webhook"
    settings.INSTRUCTOR_PARTNER_ID = "s-learn"

    calls = []
    monkeypatch.setattr("apps.instructors.services.notify_new_request", lambda request: calls.append(request.id))

    subject = SubjectFactory(key="outbound_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-a", priority_order=1)
    paper = _routable_paper(subject=subject)

    request = route_next_instructor(paper)

    assert calls == [request.id]


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


# --- Partner pull API: fresh paper link + earnings ---


def _post_signed(api_client, credential, path: str, payload: dict):
    body = json.dumps(payload).encode()
    timestamp = str(int(timezone.now().timestamp()))
    signature = sign_payload(secret=credential.hmac_secret, timestamp=timestamp, raw_body=body)
    return api_client.post(
        path,
        data=body,
        content_type="application/json",
        HTTP_X_SPEKOOH_PARTNER_ID=credential.partner_id,
        HTTP_X_SPEKOOH_SIGNATURE=signature,
        HTTP_X_SPEKOOH_TIMESTAMP=timestamp,
    )


def _routed_request(key: str, *, instructor_id: str = "instructor-a", with_file: bool = True):
    subject = SubjectFactory(key=key)
    InstructorSubjectQueueFactory(subject=subject, instructor_id=instructor_id, priority_order=1)
    paper = _routable_paper(subject=subject)
    if with_file:
        paper.uploaded_file = "paper_submissions/2026/09/exam.pdf"
        paper.save(update_fields=["uploaded_file"])
    return route_next_instructor(paper)


PAPER_LINK_PATH = "/api/instructors/partner/paper-link/"
EARNINGS_PATH = "/api/instructors/partner/earnings/"


@pytest.mark.django_db
@pytest.mark.parametrize("path", [PAPER_LINK_PATH, EARNINGS_PATH])
def test_partner_pull_endpoints_reject_an_unsigned_call(api_client, path):
    PartnerCredentialFactory()
    response = api_client.post(path, data=json.dumps({"instructor_id": "x"}), content_type="application/json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_partner_pull_endpoint_rejects_a_body_tampered_after_signing(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_tamper")
    signed_body = json.dumps({"instructor_request_id": request.id, "instructor_id": "instructor-a"}).encode()
    timestamp = str(int(timezone.now().timestamp()))
    signature = sign_payload(secret=credential.hmac_secret, timestamp=timestamp, raw_body=signed_body)
    # Signature covers instructor-a's body; the caller swaps in someone else's id.
    forged_body = json.dumps({"instructor_request_id": request.id, "instructor_id": "instructor-b"}).encode()

    response = api_client.post(
        PAPER_LINK_PATH,
        data=forged_body,
        content_type="application/json",
        HTTP_X_SPEKOOH_PARTNER_ID=credential.partner_id,
        HTTP_X_SPEKOOH_SIGNATURE=signature,
        HTTP_X_SPEKOOH_TIMESTAMP=timestamp,
    )

    assert response.status_code == 401


@pytest.mark.django_db
def test_paper_link_returns_a_fresh_link_for_a_pending_request(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_pending")

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-a"}
    )

    assert response.status_code == 200
    assert response.data["url"].endswith("exam.pdf")
    assert response.data["file_name"] == "exam.pdf"
    assert response.data["content_type"] == "application/pdf"
    assert response.data["request_status"] == "PENDING"
    assert response.data["expires_in"] > 0


@pytest.mark.django_db
def test_paper_link_is_still_served_once_the_request_is_accepted(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_accepted")
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-a"}
    )

    assert response.status_code == 200
    assert response.data["request_status"] == "ACCEPTED"


@pytest.mark.django_db
def test_paper_link_refuses_another_instructors_request(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_other")

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-b"}
    )

    # Same answer as for an id that does not exist, so ids cannot be probed.
    assert response.status_code == 404
    missing = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": 999999, "instructor_id": "instructor-a"}
    )
    assert missing.status_code == 404
    assert missing.data == response.data


@pytest.mark.django_db
@pytest.mark.parametrize("decision", ["REJECTED"])
def test_paper_link_is_gone_once_the_request_is_closed(api_client, decision):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_closed")
    handle_instructor_response(instructor_request_id=request.id, decision=decision)

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-a"}
    )

    assert response.status_code == 410


@pytest.mark.django_db
def test_paper_link_is_gone_once_the_guide_is_submitted(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_submitted")
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")
    handle_marking_guide_submission(instructor_request_id=request.id, content=[{"question_type": "ESSAY"}])

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-a"}
    )

    assert response.status_code == 410


@pytest.mark.django_db
def test_paper_link_is_gone_when_the_paper_has_no_file(api_client):
    credential = PartnerCredentialFactory()
    request = _routed_request("pull_subject_nofile", with_file=False)

    response = _post_signed(
        api_client, credential, PAPER_LINK_PATH, {"instructor_request_id": request.id, "instructor_id": "instructor-a"}
    )

    assert response.status_code == 410


def test_signed_url_asks_the_storage_for_a_short_lived_link():
    from .partner_api import _signed_url

    class _SigningStorage:
        def url(self, name, expire=None):
            return f"https://storage.example/{name}?expires={expire}"

    class _File:
        name = "papers/a.pdf"
        storage = _SigningStorage()

    assert _signed_url(_File(), 900) == "https://storage.example/papers/a.pdf?expires=900"


def test_signed_url_falls_back_for_storage_that_cannot_expire_links():
    from .partner_api import _signed_url

    class _PlainStorage:
        def url(self, name):
            return f"/media/{name}"

    class _File:
        name = "papers/a.pdf"
        storage = _PlainStorage()

    assert _signed_url(_File(), 900) == "/media/papers/a.pdf"


@pytest.mark.django_db
def test_new_request_payload_carries_the_paper_context_and_keeps_the_old_keys(settings, monkeypatch):
    from .outbound import notify_new_request

    request = _routed_request("pull_subject_payload")
    paper = request.paper
    paper.year = 2022
    paper.track = "Science"
    paper.exam_board = "GCE Board"
    paper.save(update_fields=["year", "track", "exam_board"])

    sent = {}
    monkeypatch.setattr(
        "apps.instructors.outbound.send_partner_webhook",
        lambda *, event_type, payload: sent.update(event_type=event_type, payload=payload) or True,
    )

    notify_new_request(request)

    payload = sent["payload"]
    # Original contract, unchanged.
    assert payload["instructor_request_id"] == request.id
    assert payload["subject"] == paper.subject.title
    assert payload["paper_file_url"]
    # New context an instructor needs before agreeing to mark it.
    assert payload["exam_type"] == "O Level"
    assert payload["category"] == "secondary"
    assert payload["year"] == 2022
    assert payload["track"] == "Science"
    assert payload["exam_board"] == "GCE Board"
    assert payload["language"] == "en"
    assert payload["report_title"] is None


@pytest.mark.django_db
def test_earnings_sums_credits_and_reserves_withdrawals(api_client):
    credential = PartnerCredentialFactory()
    paper = _routable_paper(subject=SubjectFactory(key="pull_subject_earn"))
    InstructorCreditLedger.objects.create(instructor_id="instructor-a", paper=paper, amount=3000)
    InstructorCreditLedger.objects.create(instructor_id="instructor-a", paper=paper, amount=2000)
    # Someone else's earnings never leak into this instructor's totals.
    InstructorCreditLedger.objects.create(instructor_id="instructor-b", paper=paper, amount=9999)
    WithdrawalRequest.objects.create(instructor_id="instructor-a", amount=1000, payout_method="mtn", status="PAID")
    WithdrawalRequest.objects.create(instructor_id="instructor-a", amount=500, payout_method="mtn", status="PENDING")
    WithdrawalRequest.objects.create(instructor_id="instructor-a", amount=700, payout_method="mtn", status="APPROVED")

    response = _post_signed(api_client, credential, EARNINGS_PATH, {"instructor_id": "instructor-a"})

    assert response.status_code == 200
    assert response.data["currency"] == "XAF"
    assert response.data["total_earned"] == 5000
    assert response.data["paid_out"] == 1000
    assert response.data["in_review"] == 1200
    assert response.data["available"] == 2800
    assert len(response.data["ledger"]) == 2
    assert {row["status"] for row in response.data["withdrawals"]} == {"PAID", "PENDING", "APPROVED"}
    assert all(row["subject"] == paper.subject.title for row in response.data["ledger"])


@pytest.mark.django_db
def test_earnings_for_an_instructor_with_no_activity_is_all_zero(api_client):
    credential = PartnerCredentialFactory()

    response = _post_signed(api_client, credential, EARNINGS_PATH, {"instructor_id": "brand-new"})

    assert response.status_code == 200
    assert response.data["total_earned"] == 0
    assert response.data["available"] == 0
    assert response.data["ledger"] == []
    assert response.data["withdrawals"] == []
