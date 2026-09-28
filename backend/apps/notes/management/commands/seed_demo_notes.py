"""
Seeds the demo study notes the Flutter app's mock data shows (app/lib/data/
mock/mock_notes.dart), so beta testers see a populated Notes page on a fresh
or staging database.

Safe to re-run: notes are matched by title and only *created* when missing,
never updated -- a subtitle or level an admin has since edited is left alone.
The first five already exist on every database (seeded by migration 0002 and
fixed up by 0004), so this really adds the four newer ones (Primary, O Level,
Seconde, University) and is a no-op for the rest.

    python manage.py seed_demo_notes            # create any that are missing
    python manage.py seed_demo_notes --remove   # delete only the four this command adds
"""

from django.core.management.base import BaseCommand

from apps.notes.models import Note

# (title, subject_title, academic_level) -- subtitle is always "Subject · Level".
ALREADY_SEEDED_BY_MIGRATIONS = [
    ("Mechanics: Newton’s Laws", "Physics", "A Level"),
    ("Cell Structure & Function", "Biology", "O Level"),
    ("La Dissertation Philosophique", "Philosophie", "Baccalauréat"),
    ("Acids, Bases & Salts", "Chemistry", "O Level"),
    ("Les Nombres Complexes", "Mathématiques", "Terminale"),
]
ADDED_BY_THIS_COMMAND = [
    ("Fractions & Decimals Made Simple", "Mathematics", "Primary"),
    ("Rivers, Relief & Climate of Cameroon", "Geography", "O Level"),
    ("La Photosynthèse en Bref", "SVT", "Seconde"),
    ("Introduction to Algorithms & Complexity", "Computer Science", "University"),
]


class Command(BaseCommand):
    help = "Create the demo study notes shown in the app's mock data (idempotent; never overwrites edits)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--remove",
            action="store_true",
            help="Delete only the demo notes this command adds (never the five from the migrations, never admin-authored notes).",
        )

    def handle(self, *args, **options):
        if options["remove"]:
            deleted, _ = Note.objects.filter(title__in=[title for title, _, _ in ADDED_BY_THIS_COMMAND]).delete()
            self.stdout.write(self.style.SUCCESS(f"Removed {deleted} demo note(s)."))
            return

        created = 0
        for index, (title, subject_title, academic_level) in enumerate(ALREADY_SEEDED_BY_MIGRATIONS + ADDED_BY_THIS_COMMAND):
            _, was_created = Note.objects.get_or_create(
                title=title,
                defaults={
                    "subtitle": f"{subject_title} · {academic_level}",
                    "subject_title": subject_title,
                    "academic_level": academic_level,
                    "sort_order": index,
                },
            )
            created += was_created
        total = len(ALREADY_SEEDED_BY_MIGRATIONS) + len(ADDED_BY_THIS_COMMAND)
        self.stdout.write(self.style.SUCCESS(f"{created} created, {total - created} already present."))
