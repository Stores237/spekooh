from unittest import mock

import pytest
from django.test import override_settings
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.instructors.factories import InstructorSubjectQueueFactory
from apps.instructors.services import (
    handle_instructor_response,
    handle_marking_guide_submission,
    merge_and_publish,
    route_next_instructor,
)
from apps.papers.factories import (
    ExamCategoryFactory,
    ExamTypeFactory,
    PaperSubmissionFactory,
    SubjectFactory,
)
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
        {"email": "new@example.com", "name": "New User", "password": "S0mePass!23", "terms_accepted": True},
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
def test_list_endpoint_includes_the_link(api_client):
    # QR Vault (2026-09-16): the app needs this to navigate a tapped
    # notification straight to the right order's pickup card.
    me = UserFactory()
    NotificationFactory(user=me, link="qr-vault/7")
    api_client.force_authenticate(user=me)
    response = api_client.get("/api/notifications/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert rows[0]["link"] == "qr-vault/7"


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


# --- SMS opt-in (Twilio, 2026-09-14) -----------------------------------------


@pytest.mark.django_db
def test_notify_sms_true_sends_sms_to_a_verified_phone():
    from django.utils import timezone

    from .services import notify

    user = UserFactory(phone_number="+237600000010")
    user.phone_verified_at = timezone.now()
    user.save(update_fields=["phone_verified_at"])

    with (
        override_settings(
            TWILIO_ACCOUNT_SID="ACtest",
            TWILIO_API_KEY_SID="SKtest",
            TWILIO_API_KEY_SECRET="secret",
            TWILIO_MESSAGING_FROM_NUMBER="+15005550006",
        ),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        mocked_post.return_value = mock.Mock(status_code=201)
        notify(user=user, title="Paper approved", body="Your submission is live.", sms=True)

    mocked_post.assert_called_once()
    assert mocked_post.call_args.kwargs["data"]["To"] == "+237600000010"


@pytest.mark.django_db
def test_notify_sms_true_is_a_noop_for_an_unverified_phone():
    from .services import notify

    user = UserFactory(phone_number="+237600000011")  # never verified

    with (
        override_settings(
            TWILIO_ACCOUNT_SID="ACtest",
            TWILIO_API_KEY_SID="SKtest",
            TWILIO_API_KEY_SECRET="secret",
            TWILIO_MESSAGING_FROM_NUMBER="+15005550006",
        ),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        notify(user=user, title="Paper approved", body="Your submission is live.", sms=True)

    mocked_post.assert_not_called()


@pytest.mark.django_db
def test_notify_sms_false_never_touches_twilio():
    """The default — sms defaults to False, so every existing notify() call
    site is unaffected by this feature existing at all."""
    from django.utils import timezone

    from .services import notify

    user = UserFactory(phone_number="+237600000012")
    user.phone_verified_at = timezone.now()
    user.save(update_fields=["phone_verified_at"])

    with mock.patch("apps.core.sms.requests.post") as mocked_post:
        notify(user=user, title="Paper approved", body="Your submission is live.")

    mocked_post.assert_not_called()


@pytest.mark.django_db
def test_notify_link_defaults_to_blank_and_is_stored_when_given():
    from .services import notify

    user = UserFactory()
    blank = notify(user=user, title="Generic", body="No link here.")
    assert blank.link == ""

    linked = notify(user=user, title="Ticket ready", body="Pick it up.", link="qr-vault/7")
    assert linked.link == "qr-vault/7"


@pytest.mark.django_db
def test_notify_sms_true_still_creates_the_in_app_notification_even_when_twilio_fails():
    from django.utils import timezone

    from .models import Notification
    from .services import notify

    user = UserFactory(phone_number="+237600000013")
    user.phone_verified_at = timezone.now()
    user.save(update_fields=["phone_verified_at"])

    with (
        override_settings(
            TWILIO_ACCOUNT_SID="ACtest",
            TWILIO_API_KEY_SID="SKtest",
            TWILIO_API_KEY_SECRET="secret",
            TWILIO_MESSAGING_FROM_NUMBER="+15005550006",
        ),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        mocked_post.return_value = mock.Mock(status_code=500, text="Twilio is down")
        notification = notify(user=user, title="Paper approved", body="Your submission is live.", sms=True)

    assert Notification.objects.filter(pk=notification.pk).exists()
