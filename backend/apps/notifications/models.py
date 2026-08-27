from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class NotificationKind(models.TextChoices):
    ONBOARDING = "ONBOARDING", "Onboarding"
    SUBMISSION_STATUS = "SUBMISSION_STATUS", "Submission status changed"
    CREDIT_AWARDED = "CREDIT_AWARDED", "Credit awarded"
    GENERIC = "GENERIC", "Generic"


class Notification(TimeStampedModel):
    """
    Spec §3.1 P0: "Notifications (push/in-app) when a submission status
    changes." Driven by real domain events (see apps.notifications.services
    .notify(), called from papers/instructors/credits services) rather than
    a freeform admin-composable inbox.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    kind = models.CharField(max_length=20, choices=NotificationKind.choices, default=NotificationKind.GENERIC)
    title = models.CharField(max_length=200)
    body = models.CharField(max_length=500)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["is_read", "-created_at"]

    def __str__(self):
        return f"{self.user}: {self.title}"
