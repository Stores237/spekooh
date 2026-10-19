from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel
from apps.papers.models import ExamCategory, Subject
from apps.papers.validation import validate_pdf_file_content


class Note(TimeStampedModel):
    """
    Admin-managed study notes. Deliberately minimal — matches the existing
    Flutter NotesRepository.getNotes() interface exactly (no detail view,
    no per-user content, no search endpoint). Not part of the confirmed
    product spec; ops add notes via Django admin.

    subject/level are real FKs into the same apps.papers taxonomy every
    other part of the app already uses (2026-09-29, replacing free-text
    subject_title/academic_level) — an admin picks from the already-defined
    subjects and academic levels instead of retyping them, so two notes
    about the same subject can't end up spelled two different ways. Subject
    stays open-ended (an admin can add a missing one inline, same as a
    contributor can when submitting a paper); level does not — the six
    academic levels are a fixed, already-complete set.
    """

    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    subject = models.ForeignKey(Subject, on_delete=models.PROTECT, related_name="notes")
    level = models.ForeignKey(
        ExamCategory, on_delete=models.PROTECT, related_name="notes", verbose_name="academic level"
    )
    sort_order = models.PositiveIntegerField(default=0)
    # The summary itself (2026-09-28). Until now a note was only a title and
    # a "Subject · Level" line: the app could list it but there was nothing to
    # open and read. Plain text: blank lines separate paragraphs, a line
    # starting "## " is a heading and a line starting "- " is a bullet.
    # Required (2026-09-29): a note with no summary text is a placeholder,
    # not something a student should be able to open.
    body = models.TextField()
    # Which support-team member owns writing and maintaining this note. Only
    # people in the Support group can be picked. Never shown in the app.
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_notes",
        limit_choices_to={"groups__name": "Support"},
    )
    # Owner request, 2026-09-17: the actual note content Integration Ops
    # uploads -- optional so existing/placeholder rows (and this session's
    # own admin tests) still save without one; the app has no detail view
    # to open it from yet (see the class docstring), just the file itself
    # once a real download/open flow exists.
    # Security hardening (2026-09-18): a real magic-byte check, not just
    # the ".pdf" extension -- same gap this app already closed for
    # papers/avatars (see apps.papers.validation's own docstring).
    pdf_file = models.FileField(
        upload_to="notes/%Y/%m/", null=True, blank=True, validators=[validate_pdf_file_content]
    )

    class Meta:
        ordering = ["sort_order", "title"]
        verbose_name = "summary note"
        verbose_name_plural = "summary notes"

    def __str__(self):
        return self.title
