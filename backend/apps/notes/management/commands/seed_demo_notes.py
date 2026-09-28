"""
Seeds demo summary notes (apps.notes.demo_notes) across every level, each with
real text, so beta testers see a populated Notes page they can actually open.

Safe to re-run, and it never overwrites anything staff have written:
- a note is matched by title and only *created* when missing;
- an existing note gets the demo text only if its text is still blank (the
  first five exist on every database from migrations 0002/0004 with no text);
- anything else about an existing note (subtitle, level, assignment, edited
  text) is left alone.

    python manage.py seed_demo_notes            # create/fill whatever is missing
    python manage.py seed_demo_notes --remove   # delete demo notes that are still untouched
"""

from django.core.management.base import BaseCommand

from apps.notes.demo_notes import DEMO_NOTES, TITLES_FROM_MIGRATIONS
from apps.notes.models import Note


class Command(BaseCommand):
    help = "Create the demo summary notes, or fill in their text (idempotent; never overwrites staff edits)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--remove",
            action="store_true",
            help="Delete the demo notes this command added, but only those whose text is still the demo text. "
            "Never touches the five from the migrations or any note staff wrote or edited.",
        )

    def handle(self, *args, **options):
        if options["remove"]:
            self._remove()
            return

        created = filled = 0
        for index, (title, subject_title, academic_level, body) in enumerate(DEMO_NOTES):
            note, was_created = Note.objects.get_or_create(
                title=title,
                defaults={
                    "subtitle": f"{subject_title} · {academic_level}",
                    "subject_title": subject_title,
                    "academic_level": academic_level,
                    "body": body,
                    "sort_order": index,
                },
            )
            if was_created:
                created += 1
            elif not note.body.strip():
                note.body = body
                note.save(update_fields=["body", "updated_at"])
                filled += 1
        untouched = len(DEMO_NOTES) - created - filled
        self.stdout.write(
            self.style.SUCCESS(f"{created} created, {filled} given their text, {untouched} already complete.")
        )

    def _remove(self):
        removed = kept = 0
        for title, _subject, _level, body in DEMO_NOTES:
            if title in TITLES_FROM_MIGRATIONS:
                continue
            note = Note.objects.filter(title=title).first()
            if note is None:
                continue
            if note.body == body:
                note.delete()
                removed += 1
            else:
                kept += 1
        self.stdout.write(self.style.SUCCESS(f"Removed {removed} demo note(s); kept {kept} that staff had edited."))
