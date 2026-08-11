import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.papers.factories import PaperSubmissionFactory

from .factories import AdminFlagQueueFactory
from .models import FlagCategory, FlagStatus
from .services import flag, resolve


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_flag_service_links_generic_subject():
    paper = PaperSubmissionFactory()
    entry = flag(subject=paper, category=FlagCategory.UNASSIGNED_PAPER, reason="No instructor accepted.")
    assert entry.subject == paper
    assert entry.status == FlagStatus.OPEN


@pytest.mark.django_db
def test_resolve_service_records_who_and_when():
    entry = AdminFlagQueueFactory()
    admin_user = UserFactory(is_staff=True)
    resolved = resolve(entry, resolved_by=admin_user, notes="Reassigned manually.")
    assert resolved.status == FlagStatus.RESOLVED
    assert resolved.resolved_by == admin_user
    assert resolved.resolved_at is not None


@pytest.mark.django_db
def test_non_staff_user_cannot_list_flags(api_client):
    AdminFlagQueueFactory()
    api_client.force_authenticate(user=UserFactory(is_staff=False))
    response = api_client.get("/api/admin-queue/flags/")
    assert response.status_code == 403


@pytest.mark.django_db
def test_staff_user_can_list_and_resolve_flags(api_client):
    entry = AdminFlagQueueFactory()
    admin_user = UserFactory(is_staff=True)
    api_client.force_authenticate(user=admin_user)

    list_response = api_client.get("/api/admin-queue/flags/")
    rows = list_response.data["results"] if isinstance(list_response.data, dict) else list_response.data
    assert list_response.status_code == 200
    assert len(rows) == 1

    resolve_response = api_client.post(f"/api/admin-queue/flags/{entry.id}/resolve/", {"notes": "done"}, format="json")
    assert resolve_response.status_code == 200
    assert resolve_response.data["status"] == FlagStatus.RESOLVED
