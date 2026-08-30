import hmac
import os

from django.core.management import call_command
from django.http import HttpResponseForbidden, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST


def healthz(request):
    """Render's own healthCheckPath (see /render.yaml) — deploys are marked
    unhealthy and rolled back without this."""
    return JsonResponse({"status": "ok"})


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
