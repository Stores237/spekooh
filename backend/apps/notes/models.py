from django.db import models

from apps.core.models import TimeStampedModel


class Note(TimeStampedModel):
    """
    Admin-managed study notes. Deliberately minimal — matches the existing
    Flutter NotesRepository.getNotes() interface exactly (no detail view,
    no per-user content, no search endpoint). Not part of the confirmed
    product spec; ops add notes via Django admin.

    subject_title/academic_level are free text (not FKs into
    apps.papers.Subject/ExamType) — notes are admin-authored one at a time,
    not picked from the same contributor-facing taxonomy, so a lighter,
    independent field fits better than forcing a shared dependency. They
    back the app's Subject/Academic level filter chips; subtitle stays the
    single rendered "Subject · Level" display string.
    """

    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    subject_title = models.CharField(max_length=100, blank=True)
    academic_level = models.CharField(max_length=100, blank=True)
    sort_order = models.PositiveIntegerField(default=0)
    # Owner request, 2026-09-17: the actual note content Integration Ops
    # uploads -- optional so existing/placeholder rows (and this session's
    # own admin tests) still save without one; the app has no detail view
    # to open it from yet (see the class docstring), just the file itself
    # once a real download/open flow exists.
    pdf_file = models.FileField(upload_to="notes/%Y/%m/", null=True, blank=True)

    class Meta:
        ordering = ["sort_order", "title"]

    def __str__(self):
        return self.title
