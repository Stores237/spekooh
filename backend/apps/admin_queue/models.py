from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models

from apps.core.models import TimeStampedModel


class FlagCategory(models.TextChoices):
    UNASSIGNED_PAPER = "UNASSIGNED_PAPER", "No instructor accepted"
    PAMPHLET_DISPUTE = "PAMPHLET_DISPUTE", "Pamphlet handover dispute"
    PAMPHLET_EXPIRED = "PAMPHLET_EXPIRED", "Pamphlet ticket expired unredeemed"
    WEBHOOK_ANOMALY = "WEBHOOK_ANOMALY", "Instructor webhook contradicted local state"
    OTHER = "OTHER", "Other"


class FlagStatus(models.TextChoices):
    OPEN = "OPEN", "Open"
    RESOLVED = "RESOLVED", "Resolved"


class AdminFlagQueue(TimeStampedModel):
    """
    Generic sink other apps write to when something needs human review —
    keeps papers/pamphlets/instructors from depending on each other just to
    share one admin-facing queue. Uses a GenericForeignKey rather than a
    per-source FK for exactly that reason.
    """

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.CharField(max_length=64)
    subject = GenericForeignKey("content_type", "object_id")

    category = models.CharField(max_length=20, choices=FlagCategory.choices)
    reason = models.TextField()
    status = models.CharField(max_length=10, choices=FlagStatus.choices, default=FlagStatus.OPEN)

    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="resolved_flags"
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["content_type", "object_id"])]

    def __str__(self):
        return f"[{self.category}] {self.subject!r} — {self.status}"
