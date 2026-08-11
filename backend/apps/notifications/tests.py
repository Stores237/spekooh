import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.credits.services import award_contributor_bonus
from apps.instructors.factories import InstructorSubjectQueueFactory
from apps.instructors.services import (
    handle_instructor_response,
    handle_marking_guide_submission,
    merge_and_publish,
    route_next_instructor,
)
from apps.papers.factories import ExamCategoryFactory, ExamTypeFactory, PaperSubmissionFactory, SubjectFactory
from apps.papers.models import MCQAnswerKey

from .factories import NotificationFactory
from .models import Notification, NotificationKind


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_register_endpoint_sends_onboarding_notification(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "new@example.com", "name": "New User", "password": "S0mePass!23"},
        format="json",
    )
    assert response.status_code == 201
    user_id = response.data["user"]["id"]
    notification = Notification.objects.get(user_id=user_id)
    assert notification.kind == NotificationKind.ONBOARDING
    assert "Welcome" in notification.title


@pytest.mark.django_db
def test_merge_and_publish_sends_submission_status_notification():
    subject = SubjectFactory(key="notif_subject_1")
    InstructorSubjectQueueFactory(subject=subject, instructor_id="instructor-notif", priority_order=1)
    category = ExamCategoryFactory(key="secondary")
    exam_type = ExamTypeFactory(category=category, name="O Level")
    paper = PaperSubmissionFactory(category=category, exam_type=exam_type, subject=subject)
    MCQAnswerKey.objects.create(paper_submission=paper, content={"q1": "A"})

    request = route_next_instructor(paper)
    handle_instructor_response(instructor_request_id=request.id, decision="ACCEPTED")
    handle_marking_guide_submission(instructor_request_id=request.id, content=[{"question_type": "ESSAY"}])
    paper.refresh_from_db()

    merge_and_publish(paper)

    notification = Notification.objects.get(user=paper.submitted_by, kind=NotificationKind.SUBMISSION_STATUS)
    assert "published" in notification.title.lower()
    assert "credits" in notification.body.lower()


@pytest.mark.django_db
def test_list_endpoint_shows_only_own_notifications(api_client):
    me = UserFactory()
    other = UserFactory()
    NotificationFactory(user=me)
    NotificationFactory(user=other)
    api_client.force_authenticate(user=me)
    response = api_client.get("/api/notifications/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) == 1


@pytest.mark.django_db
def test_mark_read_action(api_client):
    user = UserFactory()
    notification = NotificationFactory(user=user, is_read=False)
    api_client.force_authenticate(user=user)
    response = api_client.post(f"/api/notifications/{notification.id}/mark_read/")
    assert response.status_code == 200
    notification.refresh_from_db()
    assert notification.is_read is True


@pytest.mark.django_db
def test_mark_all_read_endpoint(api_client):
    user = UserFactory()
    NotificationFactory(user=user, is_read=False)
    NotificationFactory(user=user, is_read=False)
    api_client.force_authenticate(user=user)
    response = api_client.post("/api/notifications/mark-all-read/")
    assert response.status_code == 204
    assert Notification.objects.filter(user=user, is_read=False).count() == 0
