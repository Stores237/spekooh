"""Backfills subject_title/academic_level from the existing "Subject · Level"
subtitle string for the notes seeded in 0002. Also fixes a title that still
had an em dash baked into the seed data ("Mechanics — Newton's Laws") — the
same cleanup already applied everywhere else user-facing text lives."""

from django.db import migrations

# (old title, new title, subject_title, academic_level)
FIXUPS = [
    ("Mechanics — Newton’s Laws", "Mechanics: Newton’s Laws", "Physics", "A Level"),
    ("Cell Structure & Function", "Cell Structure & Function", "Biology", "O Level"),
    ("La Dissertation Philosophique", "La Dissertation Philosophique", "Philosophie", "Baccalauréat"),
    ("Acids, Bases & Salts", "Acids, Bases & Salts", "Chemistry", "O Level"),
    ("Les Nombres Complexes", "Les Nombres Complexes", "Mathématiques", "Terminale"),
]


def backfill(apps, schema_editor):
    Note = apps.get_model("notes", "Note")
    for old_title, new_title, subject_title, academic_level in FIXUPS:
        Note.objects.filter(title=old_title).update(
            title=new_title, subject_title=subject_title, academic_level=academic_level
        )


def unbackfill(apps, schema_editor):
    Note = apps.get_model("notes", "Note")
    for old_title, new_title, _, _ in FIXUPS:
        Note.objects.filter(title=new_title).update(title=old_title, subject_title="", academic_level="")


class Migration(migrations.Migration):
    dependencies = [("notes", "0003_note_academic_level_note_subject_title")]
    operations = [migrations.RunPython(backfill, unbackfill)]
