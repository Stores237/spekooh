"""
The new ocr_status field (previous migration) defaults every row to
PENDING, including submissions that were already OCR'd via the old
manual, admin-only process_ocr action before this migration existed —
without this backfill, process_pending_ocr would needlessly re-run OCR
over every one of them on its first pass.
"""

from django.db import migrations


def backfill(apps, schema_editor):
    PaperSubmission = apps.get_model("papers", "PaperSubmission")
    PaperSubmission.objects.exclude(ocr_text="").update(ocr_status="DONE")


def unbackfill(apps, schema_editor):
    # Not meaningfully reversible (we can't tell which PENDING rows were
    # flipped from which) — a no-op reverse is safe here since ocr_status
    # is a derived convenience field, not a source of truth (ocr_text is).
    pass


class Migration(migrations.Migration):
    dependencies = [("papers", "0017_papersubmission_ocr_attempts_and_more")]
    operations = [migrations.RunPython(backfill, unbackfill)]
