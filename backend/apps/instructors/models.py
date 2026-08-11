from django.db import models

from apps.core.models import TimeStampedModel

# Spekooh never owns instructor accounts — they live on a separate partner
# platform (spec §2 "golden rule"). instructor_id is always a plain,
# indexed CharField opaque reference, never a local FK.


class InstructorProfileCache(TimeStampedModel):
    """Denormalized, non-authoritative — refreshed from webhook payloads, for admin-UI readability only."""

    instructor_id = models.CharField(max_length=100, unique=True, db_index=True)
    display_name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True)
    subjects = models.JSONField(default=list, blank=True)

    def __str__(self):
        return self.display_name or self.instructor_id


class InstructorSubjectQueue(TimeStampedModel):
    """Ops-editable subject -> instructor routing order (spec §4.3: strictly sequential, not parallel)."""

    subject = models.ForeignKey("papers.Subject", on_delete=models.CASCADE, related_name="instructor_queue")
    instructor_id = models.CharField(max_length=100, db_index=True)
    priority_order = models.PositiveIntegerField()
    active = models.BooleanField(default=True)

    class Meta:
        ordering = ["subject", "priority_order"]
        constraints = [
            models.UniqueConstraint(fields=["subject", "instructor_id"], name="unique_instructor_per_subject_queue"),
        ]

    def __str__(self):
        return f"{self.subject} -> {self.instructor_id} (#{self.priority_order})"


class InstructorRequestStatus(models.TextChoices):
    PENDING = "PENDING", "Pending response"
    ACCEPTED = "ACCEPTED", "Accepted"
    REJECTED = "REJECTED", "Rejected"
    TIMED_OUT = "TIMED_OUT", "Timed out"


# "Active" = still occupying the one-active-request-per-paper slot.
ACTIVE_INSTRUCTOR_REQUEST_STATUSES = [InstructorRequestStatus.PENDING, InstructorRequestStatus.ACCEPTED]


class InstructorRequest(TimeStampedModel):
    """Tracks the request-BEFORE-transfer step (spec §4.1) — a request, not the paper transfer itself."""

    paper = models.ForeignKey("papers.PaperSubmission", on_delete=models.CASCADE, related_name="instructor_requests")
    instructor_id = models.CharField(max_length=100, db_index=True)
    sent_at = models.DateTimeField()
    responds_by = models.DateTimeField()
    status = models.CharField(
        max_length=10, choices=InstructorRequestStatus.choices, default=InstructorRequestStatus.PENDING
    )
    responded_at = models.DateTimeField(null=True, blank=True)

    # Set on ACCEPTED: sent_at + 7 days (spec §4.1).
    guide_deadline = models.DateTimeField(null=True, blank=True)
    day4_reminder_sent_at = models.DateTimeField(null=True, blank=True)
    day6_reminder_sent_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            # DB-enforced: impossible to have two open requests for one
            # paper even if application code has a bug (spec §4.3).
            models.UniqueConstraint(
                fields=["paper"],
                condition=models.Q(status__in=[s.value for s in ACTIVE_INSTRUCTOR_REQUEST_STATUSES]),
                name="one_active_instructor_request_per_paper",
            ),
        ]

    def __str__(self):
        return f"{self.paper_id} -> {self.instructor_id} ({self.status})"


class InstructorMarkingGuide(TimeStampedModel):
    paper = models.OneToOneField(
        "papers.PaperSubmission", on_delete=models.CASCADE, related_name="instructor_marking_guide"
    )
    instructor_id = models.CharField(max_length=100, db_index=True)
    content = models.JSONField()
    submitted_at = models.DateTimeField()

    def __str__(self):
        return f"Guide for {self.paper_id} by {self.instructor_id}"


class InstructorCreditLedger(TimeStampedModel):
    """Instructor credits — convertible to cash, unlike the student contributor bonus."""

    instructor_id = models.CharField(max_length=100, db_index=True)
    paper = models.ForeignKey("papers.PaperSubmission", on_delete=models.SET_NULL, null=True, related_name="+")
    amount = models.PositiveIntegerField()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.instructor_id} +{self.amount} XAF"


class WithdrawalStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    APPROVED = "APPROVED", "Approved"
    PAID = "PAID", "Paid"


class WithdrawalRequest(TimeStampedModel):
    """Instructor cash-out — distinct from the student redeem-code flow (spec §5.4)."""

    instructor_id = models.CharField(max_length=100, db_index=True)
    amount = models.PositiveIntegerField()
    kyc_status = models.CharField(max_length=30, default="PENDING")
    payout_method = models.CharField(max_length=30)
    status = models.CharField(max_length=10, choices=WithdrawalStatus.choices, default=WithdrawalStatus.PENDING)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.instructor_id} withdraw {self.amount} ({self.status})"


class PartnerCredential(TimeStampedModel):
    """HMAC shared secret for the instructor-platform webhook — per-partner, so rotation needs no redeploy."""

    partner_id = models.CharField(max_length=100, unique=True)
    hmac_secret = models.CharField(max_length=200)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.partner_id
