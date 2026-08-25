import pytest
from django.contrib.auth.models import Group
from django.test import Client, RequestFactory

from apps.accounts.factories import UserFactory

from .admin_dashboard import dashboard_callback


def _dashboard_for(user):
    request = RequestFactory().get("/admin/")
    request.user = user
    return dashboard_callback(request, {})["spekooh_dashboard"]


@pytest.mark.django_db
def test_dashboard_shows_everything_to_a_superuser():
    owner = UserFactory(is_staff=True, is_superuser=True)
    dashboard = _dashboard_for(owner)
    assert dashboard["can_view_papers"] is True
    assert dashboard["can_view_admin_queue"] is True
    assert dashboard["can_view_instructor_requests"] is True
    assert dashboard["can_view_withdrawals"] is True
    assert dashboard["can_view_credits"] is True
    assert dashboard["can_view_transactions"] is True
    assert dashboard["can_view_subscriptions"] is True
    assert "papers_funnel" in dashboard


@pytest.mark.django_db
def test_dashboard_scopes_to_reviewer_permissions():
    """Reviewer has instructor *requests* access but not withdrawals — a
    financial approval, not part of their Review Team scope."""
    reviewer = UserFactory(is_staff=True)
    reviewer.groups.add(Group.objects.get(name="Reviewer"))
    dashboard = _dashboard_for(reviewer)
    assert dashboard["can_view_papers"] is True
    assert dashboard["can_view_admin_queue"] is True
    assert dashboard["can_view_instructor_requests"] is True
    assert dashboard["can_view_withdrawals"] is False
    assert dashboard["can_view_credits"] is False
    assert dashboard["can_view_transactions"] is False
    assert dashboard["can_view_subscriptions"] is False
    # Not just hidden in the template — never queried at all for this role.
    assert "withdrawals_url" not in dashboard
    assert "revenue_by_purpose" not in dashboard


@pytest.mark.django_db
def test_dashboard_scopes_to_support_permissions():
    support = UserFactory(is_staff=True)
    support.groups.add(Group.objects.get(name="Support"))
    dashboard = _dashboard_for(support)
    assert dashboard["can_view_papers"] is True
    assert dashboard["can_view_admin_queue"] is False
    assert dashboard["can_view_instructor_requests"] is False
    assert dashboard["can_view_credits"] is False
    assert dashboard["can_view_transactions"] is True
    assert dashboard["can_view_subscriptions"] is True
    assert "flags_by_category" not in dashboard
    assert "pending_instructor_requests" not in dashboard


@pytest.mark.django_db
def test_dashboard_page_hides_sections_a_support_agent_cant_open():
    support = UserFactory(is_staff=True)
    support.groups.add(Group.objects.get(name="Support"))
    client = Client()
    client.force_login(support)

    response = client.get("/admin/")

    content = response.content.decode()
    assert "Papers pipeline" in content
    assert "Payments" in content
    assert "Admin queue" not in content
    assert "Instructors" not in content
    assert "Credits" not in content


@pytest.mark.django_db
def test_dashboard_page_hides_sections_a_reviewer_cant_open():
    reviewer = UserFactory(is_staff=True)
    reviewer.groups.add(Group.objects.get(name="Reviewer"))
    client = Client()
    client.force_login(reviewer)

    response = client.get("/admin/")

    content = response.content.decode()
    assert "Papers pipeline" in content
    assert "Admin queue" in content
    assert "Instructors" in content
    assert "Credits" not in content
    assert "Payments" not in content
