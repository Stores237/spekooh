"""
Cron-driven (see scripts/crontab.example / apps.core.views
.TRIGGERABLE_COMMANDS) — no Celery/Redis-as-broker, matching every other
background job in this codebase (apps.accounts
.prune_stale_guest_accounts, apps.instructors
.process_instructor_timeouts, apps.pamphlets.process_pamphlet_expiry all
say the same thing in their own docstrings). Render's free web-service
tier has no worker-service concept at all — this command being triggered
every few minutes via cron-job.org's free scheduler hitting
/internal/tasks/generate-ai-artifacts/ is the whole "queue."

A capped batch per run (not "every PENDING row") for the same reason
Celery's own rate_limit="20/m" existed in the original design: staying
comfortably under Gemini's free-tier per-minute ceiling without needing a
real task-queue rate limiter to do it.
"""

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db.models import Q

from apps.ai.models import ArtifactStatus, GeneratedArtifact
from apps.ai.providers.base import AIError
from apps.ai.quota import consume_provider_budget
from apps.ai.services import run_pending_generation

BATCH_SIZE = 20
MAX_ATTEMPTS = 3


class Command(BaseCommand):
    help = "Generates pending AI artifacts (summaries, etc.) via Gemini. Cron-driven, see this module's own docstring."

    def handle(self, *args, **options):
        if not settings.AI_ENABLED:
            self.stdout.write("AI_ENABLED is False — skipping.")
            return

        queryset = GeneratedArtifact.objects.filter(
            Q(status=ArtifactStatus.PENDING) | Q(status=ArtifactStatus.FAILED, attempts__lt=MAX_ATTEMPTS)
        ).select_related("content_type")[:BATCH_SIZE]

        generated = failed = 0
        for artifact in queryset:
            if not consume_provider_budget("gemini", settings.GEMINI_DAILY_BUDGET):
                self.stdout.write(self.style.WARNING("Daily Gemini budget exhausted — stopping for this run."))
                break
            try:
                run_pending_generation(artifact)
                generated += 1
            except AIError as exc:
                failed += 1
                self.stdout.write(self.style.WARNING(f"Artifact {artifact.pk} failed: {exc}"))

        self.stdout.write(f"Generated {generated}, failed {failed}, of {len(queryset)} considered.")
