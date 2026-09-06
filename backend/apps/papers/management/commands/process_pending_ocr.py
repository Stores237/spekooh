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
"""

from django.core.management.base import BaseCommand
from django.db.models import Q

from apps.papers.models import OcrStatus, PaperSubmission
from apps.papers.services import MAX_OCR_ATTEMPTS, run_pending_ocr

BATCH_SIZE = 20


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
