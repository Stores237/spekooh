"""
Owner decision: Master's Thesis and PhD Thesis reports run far more pages
than a standard exam paper or shorter report (Internship/Bachelor's/HND),
so they get a larger upload allowance — 50MB vs the 20MB default.
"""

from django.db import migrations

THESIS_REPORT_NAMES = [
    "Master’s Thesis (Mémoire)",
    "PhD Thesis (Thèse)",
]

THESIS_MAX_UPLOAD_MB = 50
DEFAULT_MAX_UPLOAD_MB = 20


def widen(apps, schema_editor):
    ExamType = apps.get_model("papers", "ExamType")
    ExamType.objects.filter(category__key="reports", name__in=THESIS_REPORT_NAMES).update(
        max_upload_mb=THESIS_MAX_UPLOAD_MB
    )


def narrow(apps, schema_editor):
    ExamType = apps.get_model("papers", "ExamType")
    ExamType.objects.filter(category__key="reports", name__in=THESIS_REPORT_NAMES).update(
        max_upload_mb=DEFAULT_MAX_UPLOAD_MB
    )


class Migration(migrations.Migration):
    dependencies = [("papers", "0012_examtype_max_upload_mb")]
    operations = [migrations.RunPython(widen, narrow)]
