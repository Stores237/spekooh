"""
The "reports" ExamCategory has existed since the initial taxonomy seed
(0002_seed_taxonomy) with zero ExamType rows under it — Submit's
"Academic report" tab showed an honest "coming soon" state rather than
faking a submission flow with no real taxonomy to submit against.

These 5 report types are ported 1:1 from the Flutter mock at
app/lib/data/mock/mock_taxonomy.dart (MockTaxonomy.reportTypes), which
already anticipated this real feature — same names, same order.
"""

from django.db import migrations

REPORT_TYPES = [
    # (name, subtitle)
    ("Internship Report", "HND / Bachelor / Master"),
    ("Bachelor’s Report (Mémoire de Licence)", "Bachelor / Licence"),
    ("HND Report", "Rapport de fin d’études"),
    ("Master’s Thesis (Mémoire)", "Master"),
    ("PhD Thesis (Thèse)", "Doctorat"),
]


def seed(apps, schema_editor):
    ExamCategory = apps.get_model("papers", "ExamCategory")
    ExamType = apps.get_model("papers", "ExamType")
    reports = ExamCategory.objects.get(key="reports")
    for i, (name, subtitle) in enumerate(REPORT_TYPES):
        ExamType.objects.create(
            category=reports,
            system=None,
            name=name,
            subtitle=subtitle,
            subject_language="en",
            badge_tone="neutral",
            sort_order=i,
        )


def unseed(apps, schema_editor):
    ExamCategory = apps.get_model("papers", "ExamCategory")
    ExamType = apps.get_model("papers", "ExamType")
    ExamType.objects.filter(category__key="reports").delete()


class Migration(migrations.Migration):
    dependencies = [("papers", "0008_papersubmission_discipline_and_more")]
    operations = [migrations.RunPython(seed, unseed)]
