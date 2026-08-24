"""
Owner decision: viewing is free for Internship/Bachelor's/HND reports, but
Master's Thesis and PhD Thesis require payment even to view (not just
download) — matches how these are actually treated academically (advanced-
degree theses are more commonly restricted/gated than undergraduate or
internship reports).
"""

from django.db import migrations

GATED_REPORT_NAMES = [
    "Master’s Thesis (Mémoire)",
    "PhD Thesis (Thèse)",
]


def gate(apps, schema_editor):
    ExamType = apps.get_model("papers", "ExamType")
    ExamType.objects.filter(category__key="reports", name__in=GATED_REPORT_NAMES).update(
        requires_payment_to_view=True
    )


def ungate(apps, schema_editor):
    ExamType = apps.get_model("papers", "ExamType")
    ExamType.objects.filter(category__key="reports", name__in=GATED_REPORT_NAMES).update(
        requires_payment_to_view=False
    )


class Migration(migrations.Migration):
    dependencies = [("papers", "0010_examtype_requires_payment_to_view")]
    operations = [migrations.RunPython(gate, ungate)]
