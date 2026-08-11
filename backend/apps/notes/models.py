from django.db import models

from apps.core.models import TimeStampedModel


class Note(TimeStampedModel):
    """
    Admin-managed study notes. Deliberately minimal — matches the existing
    Flutter NotesRepository.getNotes() interface exactly (no detail view,
    no per-user content, no search endpoint). Not part of the confirmed
    product spec; ops add notes via Django admin.
    """

    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "title"]

    def __str__(self):
        return self.title
