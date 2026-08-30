import pytest
from django.contrib.auth.models import Group
from django.test import Client, RequestFactory

from apps.accounts.factories import UserFactory

from .admin_dashboard import dashboard_callback
from .views import TRIGGERABLE_COMMANDS


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


# --- Render staging deployment (2026-08-30) ---
# See RENDER_STAGING.md. /healthz/ is what Render's own health check polls
# to decide whether a deploy is live; /internal/tasks/<name>/ stands in for
# a real crontab on the free plan, which can't run one at all.


def test_healthz_reports_ok():
    response = Client().get("/healthz/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_run_task_requires_the_token_header(monkeypatch):
    monkeypatch.delenv("TASK_TRIGGER_TOKEN", raising=False)
    response = Client().post("/internal/tasks/prune-stale-guest-accounts/")
    assert response.status_code == 403


def test_run_task_rejects_a_wrong_token(monkeypatch):
    monkeypatch.setenv("TASK_TRIGGER_TOKEN", "the-real-token")
    response = Client().post(
        "/internal/tasks/prune-stale-guest-accounts/", HTTP_X_TASK_TOKEN="not-the-real-token"
    )
    assert response.status_code == 403


def test_run_task_rejects_get(monkeypatch):
    """State-mutating — never triggerable by a plain GET (e.g. a crawler,
    or someone pasting the URL into a browser)."""
    monkeypatch.setenv("TASK_TRIGGER_TOKEN", "the-real-token")
    response = Client().get(
        "/internal/tasks/prune-stale-guest-accounts/", HTTP_X_TASK_TOKEN="the-real-token"
    )
    assert response.status_code == 405


def test_run_task_rejects_an_unknown_task_name(monkeypatch):
    monkeypatch.setenv("TASK_TRIGGER_TOKEN", "the-real-token")
    response = Client().post("/internal/tasks/not-a-real-task/", HTTP_X_TASK_TOKEN="the-real-token")
    assert response.status_code == 404


@pytest.mark.django_db
@pytest.mark.parametrize("name", list(TRIGGERABLE_COMMANDS))
def test_run_task_actually_runs_the_real_management_command(monkeypatch, name):
    """Each triggerable name really does invoke the same real, cron-driven
    command scripts/crontab.example runs on a machine with a real crontab —
    not a stand-in Celery task that doesn't exist in this codebase."""
    monkeypatch.setenv("TASK_TRIGGER_TOKEN", "the-real-token")
    calls = []
    monkeypatch.setattr("apps.core.views.call_command", lambda cmd: calls.append(cmd))

    response = Client().post(f"/internal/tasks/{name}/", HTTP_X_TASK_TOKEN="the-real-token")

    assert response.status_code == 200
    assert response.json() == {"ran": TRIGGERABLE_COMMANDS[name]}
    assert calls == [TRIGGERABLE_COMMANDS[name]]
