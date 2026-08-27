from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models

from apps.core.models import TimeStampedModel


class FlagCategory(models.TextChoices):
    # Spec §2.1: every event that needs Review Team action auto-creates a
    # ticket in this same queue rather than a separate ticketing system.
    PAPER_VERIFICATION = "PAPER_VERIFICATION", "New submission needs verification"
    PAPER_REPORTED = "PAPER_REPORTED", "Paper reported by a user"
    UNASSIGNED_PAPER = "UNASSIGNED_PAPER", "No instructor accepted"
    GUIDE_REVIEW = "GUIDE_REVIEW", "Marking guide returned, needs review/merge"
    PAMPHLET_DISPUTE = "PAMPHLET_DISPUTE", "Pamphlet handover dispute"
    PAMPHLET_EXPIRED = "PAMPHLET_EXPIRED", "Pamphlet ticket expired unredeemed"
    WITHDRAWAL_APPROVAL = "WITHDRAWAL_APPROVAL", "Instructor withdrawal needs KYC/payout approval"
    WEBHOOK_ANOMALY = "WEBHOOK_ANOMALY", "Instructor webhook contradicted local state"
    OTHER = "OTHER", "Other"


class FlagStatus(models.TextChoices):
    # Spec §2.1: "New -> In Progress -> Resolved."
    NEW = "NEW", "New"
    IN_PROGRESS = "IN_PROGRESS", "In Progress"
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
    status = models.CharField(max_length=12, choices=FlagStatus.choices, default=FlagStatus.NEW)

    # Who's actively working the ticket right now — distinct from
    # resolved_by, which only gets set once it's actually closed.
    assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="assigned_flags"
    )

    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="resolved_flags"
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["content_type", "object_id"])]

    def __str__(self):
        return f"[{self.category}] {self.subject!r}, {self.status}"

    @property
    def age_days(self) -> int:
        from django.utils import timezone

        end = self.resolved_at or timezone.now()
        return (end - self.created_at).days
