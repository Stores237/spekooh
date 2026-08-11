"""Seeds the same notes already shown by the Flutter mock data, ported 1:1."""

from django.db import migrations

NOTES = [
    ("Mechanics — Newton’s Laws", "Physics · A Level"),
    ("Cell Structure & Function", "Biology · O Level"),
    ("La Dissertation Philosophique", "Philosophie · Baccalauréat"),
    ("Acids, Bases & Salts", "Chemistry · O Level"),
    ("Les Nombres Complexes", "Mathématiques · Terminale"),
]


def seed(apps, schema_editor):
    Note = apps.get_model("notes", "Note")
    for i, (title, subtitle) in enumerate(NOTES):
        Note.objects.create(title=title, subtitle=subtitle, sort_order=i)


def unseed(apps, schema_editor):
    apps.get_model("notes", "Note").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("notes", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
