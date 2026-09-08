"""
Two of the six ExamCategory subtitles seeded by 0002_seed_taxonomy.py used an
em dash ("—") as a sentence connector — the exact pattern already flagged and
swept from every other user-facing string (owner feedback, see the "Em dash
removed from user-facing text" entry in TODOS.md's own shipped history) but
missed here, because 0002's own seed data had drifted from the Flutter mock
taxonomy (app/lib/data/mock/mock_taxonomy.dart) it was supposed to mirror
1:1 — that mock already uses parentheses for this exact same content
("(State & Private)", "(no marking guide)"). This migration brings the two
live rows back in line with the mock's own already-decided convention,
rather than inventing a third one.

0002 itself is left untouched — it's a historical record of what was
originally seeded, not the place to retroactively edit already-applied
migration content.
"""

from django.db import migrations

FIXES = {
    "university": ("Semester exams · Resits — State & Private", "Semester exams · Resits (State & Private)"),
    "reports": ("Internship · Mémoire · Thèse — no marking guide", "Internship · Mémoire · Thèse (no marking guide)"),
}


def fix_subtitles(apps, schema_editor):
    ExamCategory = apps.get_model("papers", "ExamCategory")
    for key, (old, new) in FIXES.items():
        ExamCategory.objects.filter(key=key, subtitle=old).update(subtitle=new)


def revert_subtitles(apps, schema_editor):
    ExamCategory = apps.get_model("papers", "ExamCategory")
    for key, (old, new) in FIXES.items():
        ExamCategory.objects.filter(key=key, subtitle=new).update(subtitle=old)


class Migration(migrations.Migration):
    dependencies = [
        ("papers", "0019_papersubmission_title"),
    ]

    operations = [
        migrations.RunPython(fix_subtitles, revert_subtitles),
    ]
