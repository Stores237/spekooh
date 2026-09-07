"""
Cron-driven (see scripts/crontab.example / apps.core.views
.TRIGGERABLE_COMMANDS) — this project's usual replacement for a Celery
task queue, which it deliberately doesn't run (Render's free web-service
tier has no worker-service concept at all; see apps.accounts.management
.commands.prune_stale_guest_accounts's own docstring for the same reasoning).

Owner decision (2026-09-06): OCR used to run only via a manual, admin-only
API action that neither publish path ever called — meaning a normally-
published submission (exam paper or report, no distinction) had
permanently empty ocr_text, and apps.ai's summary/chat silently never
worked for it. This makes OCR automatic: every new submission starts
ocr_status=PENDING (PaperSubmission's own default) and this command picks
it up within a few minutes, well before anyone gets around to publishing
it.

Not run synchronously at submission time, on purpose — a past, deliberate
latency fix (the presigned direct-to-storage upload in
apps.papers.views.PaperSubmissionViewSet.upload_url) kept that request
fast; synchronous, page-by-page Tesseract OCR over a 50MB thesis PDF in
the same request would undo it.

BATCH_SIZE (2026-09-07, real live failure): this whole run still executes
inside ONE HTTP request/response (apps.core.views.run_task calls
call_command() and blocks until it returns) — unlike the lightweight
housekeeping commands sharing this same trigger mechanism
(process_instructor_timeouts, process_pamphlet_expiry), OCR is genuinely
slow per item (pdf2image page rasterization + Tesseract, per page, on
Render's free-tier CPU). A batch of 20 real submissions timed out the
triggering cron-job.org request outright. Kept small so a single run
comfortably finishes inside a typical external timeout regardless of how
many submissions are actually waiting — it still clears any real backlog
fine since this runs every few minutes anyway.
"""

from django.core.management.base import BaseCommand
from django.db.models import Q

from apps.papers.models import OcrStatus, PaperSubmission
from apps.papers.services import MAX_OCR_ATTEMPTS, run_pending_ocr

BATCH_SIZE = 3


class Command(BaseCommand):
    help = "Runs OCR (+ duplicate detection) over newly-submitted papers/reports. Cron-driven, see this module's own docstring."

    def handle(self, *args, **options):
        queryset = PaperSubmission.objects.filter(
            Q(ocr_status=OcrStatus.PENDING) | Q(ocr_status=OcrStatus.FAILED, ocr_attempts__lt=MAX_OCR_ATTEMPTS)
        )[:BATCH_SIZE]

        processed = failed = 0
        for submission in queryset:
            try:
                run_pending_ocr(submission)
                processed += 1
            except Exception as exc:  # noqa: BLE001 — deliberately blind: one submission's
                # unpredictable OCR failure (Tesseract/PIL/pdf2image raise a variety of
                # unrelated exception types, no shared base) must never abort the rest of
                # the batch; run_pending_ocr already recorded the real failure on the row.
                failed += 1
                self.stdout.write(self.style.WARNING(f"Submission {submission.pk} OCR failed: {exc}"))

        self.stdout.write(f"Processed {processed}, failed {failed}, of {len(queryset)} considered.")
