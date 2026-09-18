import hmac
import os

from django.core.management import call_command
from django.http import HttpResponseForbidden, JsonResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from . import legal_content


def healthz(request):
    """Render's own healthCheckPath (see /render.yaml) — deploys are marked
    unhealthy and rolled back without this."""
    return JsonResponse({"status": "ok"})


def marketing_home(request):
    """Public marketing site (2026-09-18, owner request) — replaces the
    old bare redirect to /api/docs/ at '/'. Announcements reuse the real
    Promotion model (apps.promotions) that already backs the in-app Home
    sponsor section, rather than a second content source to keep in sync."""
    from apps.promotions.models import Promotion

    announcements = Promotion.objects.filter(is_active=True).order_by("sort_order", "-created_at")
    return render(request, "core/site/home.html", {"announcements": announcements})


def privacy_policy_page(request):
    """A real, public URL for the Privacy Policy — 2026-09-14, owner
    request: Play Console's Store Listing requires one (a validated field,
    not optional), and this document previously only existed as an in-app
    Flutter screen with no URL at all. See apps.core.legal_content's own
    docstring for why this is a content duplicate, not a shared source of
    truth, with the Flutter version."""
    return render(
        request,
        "core/legal_document.html",
        {
            "title": "Privacy Policy",
            "last_updated": legal_content.PRIVACY_POLICY_LAST_UPDATED,
            "intro": legal_content.PRIVACY_POLICY_INTRO,
            "sections": legal_content.PRIVACY_POLICY_SECTIONS,
        },
    )


def terms_of_service_page(request):
    """Same reasoning as privacy_policy_page above — App Store Connect
    also asks for this as a URL, not just an in-app screen."""
    return render(
        request,
        "core/legal_document.html",
        {
            "title": "Terms of Service",
            "last_updated": legal_content.TERMS_OF_SERVICE_LAST_UPDATED,
            "intro": legal_content.TERMS_OF_SERVICE_INTRO,
            "sections": legal_content.TERMS_OF_SERVICE_SECTIONS,
        },
    )


# Render's free web-service plan has no background-worker or cron concept
# at all (see RENDER_STAGING.md §6) — this repo's real scheduled work is
# already three plain, race-safe Django management commands
# (scripts/crontab.example runs them via a real crontab on any machine that
# has one). This just makes the same three commands reachable over HTTP,
# gated by a long random shared-secret header, so a free external cron
# service (e.g. cron-job.org) can trigger them on staging instead of a real
# crontab, which the free plan can't run.
#
# Staging only. Production gets the real crontab — an HTTP endpoint that
# mutates instructor/pamphlet/account state on any correctly-tokened
# request is an availability and security liability under real load.
TRIGGERABLE_COMMANDS = {
    "process-instructor-timeouts": "process_instructor_timeouts",
    "process-pamphlet-expiry": "process_pamphlet_expiry",
    "prune-stale-guest-accounts": "prune_stale_guest_accounts",
    # Not a cron job — an on-demand cleanup for the real @example.com rows
    # that live-testing a real deployment leaves behind (there's no Shell
    # tab on the free plan to delete them by hand — see "Create an admin
    # user" in RENDER_STAGING.md).
    "delete-test-accounts": "delete_test_accounts",
    # AI generation (2026-09-05) — this project's real replacement for a
    # Celery task queue, which it deliberately doesn't run (see
    # apps.ai.management.commands.generate_pending_artifacts's own
    # docstring). Point a cron-job.org schedule at this every few minutes.
    "generate-ai-artifacts": "generate_pending_artifacts",
    # OCR (2026-09-06) — every new paper/report submission now needs this
    # to run before its AI summary/chat can ever work; see
    # apps.papers.management.commands.process_pending_ocr's own docstring
    # for why this replaced the old manual, admin-only process_ocr action.
    "process-pending-ocr": "process_pending_ocr",
}


@csrf_exempt
@require_POST
def run_task(request, name):
    expected = os.environ.get("TASK_TRIGGER_TOKEN")
    received = request.headers.get("X-Task-Token")
    if not expected or not received or not hmac.compare_digest(received, expected):
        return HttpResponseForbidden()
    command = TRIGGERABLE_COMMANDS.get(name)
    if command is None:
        return JsonResponse({"error": "unknown task"}, status=404)
    call_command(command)
    return JsonResponse({"ran": command})
