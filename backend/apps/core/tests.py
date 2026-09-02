import pytest
from django.contrib.auth.models import Group
from django.test import Client, RequestFactory

from apps.accounts.factories import UserFactory

from .admin_dashboard import dashboard_callback
from .exceptions import SafeMessageError
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


def test_email_backend_defaults_to_real_smtp_when_unconfigured():
    """Regression test for a real bug found live (2026-08-31): prod.py never
    overrode EMAIL_BACKEND, so with no EMAIL_HOST configured, Django's real
    default (SMTP against localhost:25) crashed every single registration
    on the actual deployed staging site with an unhandled
    ConnectionRefusedError — reproduced locally against config.settings.prod
    before this fix existed. base.py now makes EMAIL_BACKEND
    env-configurable (RENDER_STAGING.md sets it to the console backend for
    staging specifically) but keeps the real SMTP default, so real
    production still fails loudly instead of silently discarding mail.

    Run in a fresh subprocess rather than asserting on this test process's
    own settings — pytest-django unconditionally overrides EMAIL_BACKEND to
    the locmem backend for every test regardless of what settings.py says,
    which is exactly why this bug shipped without any test catching it."""
    import os
    import subprocess
    import sys
    from pathlib import Path

    env = {**os.environ}
    env.pop("EMAIL_BACKEND", None)
    env["DJANGO_SETTINGS_MODULE"] = "config.settings.base"
    result = subprocess.run(
        [sys.executable, "-c", "import django; django.setup(); from django.conf import settings; print(settings.EMAIL_BACKEND)"],
        env=env,
        cwd=Path(__file__).resolve().parents[2],  # backend/ — where manage.py/config/ live
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    assert result.stdout.strip() == "django.core.mail.backends.smtp.EmailBackend", result.stderr


def test_email_backend_is_actually_overridable_via_env_var():
    """The actual fix: before this, nothing in settings.py read an
    EMAIL_BACKEND env var at all, so setting one in Render's dashboard
    would have silently done nothing — Django's own SMTP default (equal to
    the un-overridden case above) would apply regardless. This is what
    RENDER_STAGING.md's EMAIL_BACKEND=...console.EmailBackend env var
    actually relies on working."""
    import os
    import subprocess
    import sys
    from pathlib import Path

    env = {**os.environ, "DJANGO_SETTINGS_MODULE": "config.settings.base"}
    env["EMAIL_BACKEND"] = "django.core.mail.backends.console.EmailBackend"
    result = subprocess.run(
        [sys.executable, "-c", "import django; django.setup(); from django.conf import settings; print(settings.EMAIL_BACKEND)"],
        env=env,
        cwd=Path(__file__).resolve().parents[2],  # backend/ — where manage.py/config/ live
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    assert result.stdout.strip() == "django.core.mail.backends.console.EmailBackend", result.stderr


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


class TestSafeMessageError:
    """Fixes 15 open "information exposure through an exception" CodeQL
    findings (backend/.../views.py, 2026-09-02): every one was a
    `str(exc)` on one of this codebase's own domain exceptions
    (PaperUnlockError, RedeemCodeError, EscrowError, etc.) — human-verified
    safe (a curated, hardcoded message, never a raw system exception), but
    `str(exc)` is exactly the pattern CodeQL's py/stack-trace-exposure
    query watches for on any exception. `.detail` is a plain attribute
    outside that model, so views reading it don't re-trigger the same
    finding on the next scan — see every subclass across apps/*/services.py,
    apps/*/escrow.py, and apps/instructors/webhook.py, all now inheriting
    this base instead of bare Exception."""

    def test_detail_attribute_holds_the_exact_message_passed_in(self):
        error = SafeMessageError("Already unlocked.")
        assert error.detail == "Already unlocked."

    def test_str_still_matches_detail_for_any_existing_code_still_using_it(self):
        # Exception's default __str__ already returns this for a single-arg
        # exception — asserted explicitly so a future refactor of __init__
        # can't silently break that equivalence.
        error = SafeMessageError("Redeem code has expired.")
        assert str(error) == error.detail

    def test_every_real_domain_exception_actually_inherits_it(self):
        from apps.credits.services import CreditEngineError, RedeemCodeError
        from apps.instructors.services import MergeError, RoutingError
        from apps.instructors.webhook import WebhookError
        from apps.pamphlets.escrow import AlreadyRedeemedError, EscrowError
        from apps.pamphlets.services import PamphletOrderError
        from apps.papers.services import AlreadyFlaggedError, PaywallError
        from apps.payments.services import (
            PaperDownloadUnlockError,
            PaperUnlockError,
            SubscriptionError,
        )
        from apps.quizzes.services import QuizError

        for cls in [
            RedeemCodeError,
            CreditEngineError,
            RoutingError,
            MergeError,
            WebhookError,
            EscrowError,
            AlreadyRedeemedError,
            PamphletOrderError,
            AlreadyFlaggedError,
            PaywallError,
            PaperDownloadUnlockError,
            PaperUnlockError,
            SubscriptionError,
            QuizError,
        ]:
            assert issubclass(cls, SafeMessageError), f"{cls.__name__} still inherits bare Exception"
