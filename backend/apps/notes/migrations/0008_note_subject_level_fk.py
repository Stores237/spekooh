"""
Replaces free-text subject_title/academic_level with real FKs into the
already-existing apps.papers taxonomy (Subject, ExamCategory) — an admin now
picks from a proposed list instead of retyping a subject/level by hand. Also
makes body required: a note with no summary text is a placeholder, not
something a student should be able to open.

Four subjects used by the existing demo notes (Mathematics, Science,
Français, Geography) have no exact match in the curated Subject list seeded
by papers/0002 — real, ordinary school subjects missing from that list, not
anything specific to notes, so they're added here rather than force-fitting
notes onto the wrong existing subject. "Physique" (no standalone entry,
only the combined "Physique-Chimie") is aliased to the existing subject
instead, since a near-duplicate would be redundant.

Academic-level free text mixes exam-type-level labels ("O Level", "BEPC",
"Baccalauréat") and lycée grade-year names ("Terminale", "Seconde") that
don't literally match any ExamCategory title — LEVEL_ALIASES maps each to
the ExamCategory it actually belongs to. "Primary" and "University" already
match an ExamCategory title directly.

If a future deploy has a note with a subject_title/academic_level this
migration doesn't recognise, it fails loudly (RuntimeError naming the note
and the unmatched text) rather than silently leaving a required FK unset.
"""

from django.db import migrations, models
import django.db.models.deletion


NEW_SUBJECTS = [
    # (key, title, tint, icon_name, language)
    ("mathematics", "Mathematics", "blue", "functions", "en"),
    ("science", "Science", "green", "science_outlined", "en"),
    ("francais", "Français", "amber", "menu_book_outlined", "fr"),
    ("geography", "Geography", "amber", "public_outlined", "en"),
]

SUBJECT_ALIASES = {
    "physique": "physique-chimie",
}

LEVEL_ALIASES = {
    "a level": "secondary",
    "o level": "secondary",
    "baccalauréat": "secondary",
    "bepc": "secondary",
    "probatoire": "secondary",
    "terminale": "secondary",
    "seconde": "secondary",
    "première": "secondary",
    "hnd": "tertiary",
    "bts": "tertiary",
}


def resolve_subject(text, subjects_by_title):
    normalized = text.strip().lower()
    if not normalized:
        return None
    normalized = SUBJECT_ALIASES.get(normalized, normalized)
    return subjects_by_title.get(normalized)


def resolve_level(text, categories_by_key, categories_by_title):
    normalized = text.strip().lower()
    if not normalized:
        return None
    alias_key = LEVEL_ALIASES.get(normalized)
    if alias_key:
        return categories_by_key.get(alias_key)
    return categories_by_title.get(normalized)


def backfill(apps, schema_editor):
    Note = apps.get_model("notes", "Note")
    Subject = apps.get_model("papers", "Subject")
    ExamCategory = apps.get_model("papers", "ExamCategory")

    for key, title, tint, icon_name, language in NEW_SUBJECTS:
        Subject.objects.get_or_create(
            key=key, defaults={"title": title, "tint": tint, "icon_name": icon_name, "language": language}
        )

    subjects_by_title = {s.title.lower(): s for s in Subject.objects.all()}
    categories_by_key = {c.key: c for c in ExamCategory.objects.all()}
    categories_by_title = {c.title.lower(): c for c in ExamCategory.objects.all()}

    notes = list(Note.objects.all())
    resolved = {}
    problems = []
    for note in notes:
        subject = resolve_subject(note.subject_title or "", subjects_by_title)
        level = resolve_level(note.academic_level or "", categories_by_key, categories_by_title)
        if subject is None:
            problems.append(f'"{note.title}": no Subject matches subject_title={note.subject_title!r}')
        if level is None:
            problems.append(f'"{note.title}": no ExamCategory matches academic_level={note.academic_level!r}')
        resolved[note.pk] = (subject, level)

    if problems:
        raise RuntimeError(
            "notes 0008 backfill: some notes could not be matched to a real Subject/ExamCategory:\n  "
            + "\n  ".join(problems)
            + "\nAdd an alias in this migration (or fix the note in the admin) before deploying."
        )

    for note in notes:
        subject, level = resolved[note.pk]
        note.subject = subject
        note.level = level
        note.save(update_fields=["subject", "level"])


def reverse_backfill(apps, schema_editor):
    Note = apps.get_model("notes", "Note")
    for note in Note.objects.all():
        Note.objects.filter(pk=note.pk).update(
            subject_title=note.subject.title if note.subject_id else "",
            academic_level=note.level.title if note.level_id else "",
        )


class Migration(migrations.Migration):
    dependencies = [
        ("notes", "0007_note_body_assigned_to"),
        ("papers", "0020_fix_em_dash_in_category_subtitles"),
    ]

    operations = [
        migrations.AddField(
            model_name="note",
            name="subject",
            field=models.ForeignKey(
                null=True, on_delete=django.db.models.deletion.PROTECT, related_name="notes", to="papers.subject"
            ),
        ),
        migrations.AddField(
            model_name="note",
            name="level",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="notes",
                to="papers.examcategory",
                verbose_name="academic level",
            ),
        ),
        migrations.RunPython(backfill, reverse_backfill),
        migrations.AlterField(
            model_name="note",
            name="subject",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT, related_name="notes", to="papers.subject"
            ),
        ),
        migrations.AlterField(
            model_name="note",
            name="level",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT,
                related_name="notes",
                to="papers.examcategory",
                verbose_name="academic level",
            ),
        ),
        migrations.RemoveField(model_name="note", name="subject_title"),
        migrations.RemoveField(model_name="note", name="academic_level"),
        migrations.AlterField(model_name="note", name="body", field=models.TextField()),
    ]
