from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class ExamSystem(models.TextChoices):
    FRANCOPHONE = "francophone", "Francophone"
    ANGLOPHONE = "anglophone", "Anglophone"


class SubjectLanguage(models.TextChoices):
    EN = "en", "English"
    FR = "fr", "French"


class ExamCategory(TimeStampedModel):
    """Top-level browse category. Mirrors app/lib/models/exam_taxonomy.dart ExamCategoryKey."""

    key = models.SlugField(max_length=40, unique=True)
    title = models.CharField(max_length=100)
    subtitle = models.CharField(max_length=200, blank=True)
    icon_name = models.CharField(max_length=60, blank=True)
    tint = models.CharField(max_length=20, blank=True)
    requires_system = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name_plural = "exam categories"
        ordering = ["sort_order", "title"]

    def __str__(self):
        return self.title


class ExamType(TimeStampedModel):
    """e.g. BEPC, O Level, HND. tracks holds an ordered list of track names, empty if none."""

    category = models.ForeignKey(ExamCategory, on_delete=models.CASCADE, related_name="exam_types")
    system = models.CharField(max_length=20, choices=ExamSystem.choices, null=True, blank=True)
    name = models.CharField(max_length=100)
    subtitle = models.CharField(max_length=200, blank=True)
    mock_variant_label = models.CharField(max_length=100, blank=True)
    tracks = models.JSONField(default=list, blank=True)
    subject_language = models.CharField(max_length=2, choices=SubjectLanguage.choices, default=SubjectLanguage.EN)
    badge_tone = models.CharField(max_length=20, blank=True, default="neutral")
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "name"]
        constraints = [
            models.UniqueConstraint(fields=["category", "system", "name"], name="unique_exam_type_per_category_system"),
        ]

    def __str__(self):
        return self.name

    @property
    def requires_track(self):
        return bool(self.tracks)


class Subject(TimeStampedModel):
    key = models.SlugField(max_length=60, unique=True)
    title = models.CharField(max_length=100)
    code = models.CharField(max_length=20, blank=True)
    icon_name = models.CharField(max_length=60, blank=True)
    tint = models.CharField(max_length=20, blank=True)
    language = models.CharField(max_length=2, choices=SubjectLanguage.choices, default=SubjectLanguage.EN)

    class Meta:
        ordering = ["title"]

    def __str__(self):
        return self.title


class PaperStatus(models.TextChoices):
    PENDING_REVIEW = "PENDING_REVIEW", "Pending review"
    INSTRUCTOR_REQUEST_SENT = "INSTRUCTOR_REQUEST_SENT", "Instructor request sent"
    INSTRUCTOR_ACCEPTED = "INSTRUCTOR_ACCEPTED", "Instructor accepted"
    INSTRUCTOR_REJECTED = "INSTRUCTOR_REJECTED", "Instructor rejected"
    AWAITING_MARKING_GUIDE = "AWAITING_MARKING_GUIDE", "Awaiting marking guide"
    GUIDE_SUBMITTED = "GUIDE_SUBMITTED", "Guide submitted"
    MERGED = "MERGED", "Merged"
    PUBLISHED = "PUBLISHED", "Published"
    UNASSIGNED_ADMIN_QUEUE = "UNASSIGNED_ADMIN_QUEUE", "Unassigned — admin queue"


class PaperSubmission(TimeStampedModel):
    submitted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="paper_submissions"
    )
    category = models.ForeignKey(ExamCategory, on_delete=models.PROTECT, related_name="submissions")
    exam_type = models.ForeignKey(ExamType, on_delete=models.PROTECT, related_name="submissions")
    system = models.CharField(max_length=20, choices=ExamSystem.choices, null=True, blank=True)
    track = models.CharField(max_length=60, blank=True)
    # Null for the "reports" category, which has no subject taxonomy.
    subject = models.ForeignKey(Subject, on_delete=models.PROTECT, related_name="submissions", null=True, blank=True)
    exam_board = models.CharField(max_length=120, blank=True)
    year = models.PositiveIntegerField()

    file_ref = models.CharField(max_length=500)
    ocr_text = models.TextField(blank=True)
    duplicate_hash = models.CharField(max_length=64, blank=True, db_index=True)

    # non_mcq_section is the only part ever sent to the external instructor.
    mcq_section = models.JSONField(null=True, blank=True)
    non_mcq_section = models.JSONField(null=True, blank=True)

    is_duplicate = models.BooleanField(default=False)
    duplicate_of = models.ForeignKey(
        "self", on_delete=models.SET_NULL, null=True, blank=True, related_name="duplicates"
    )

    status = models.CharField(max_length=32, choices=PaperStatus.choices, default=PaperStatus.PENDING_REVIEW)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.exam_type} {self.year} — {self.subject or 'no subject'}"


class MCQAnswerKey(TimeStampedModel):
    """Marked and finalized in-house by the Review Team — never sent to an external instructor."""

    paper_submission = models.OneToOneField(PaperSubmission, on_delete=models.CASCADE, related_name="mcq_answer_key")
    authored_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="authored_mcq_keys"
    )
    content = models.JSONField()

    def __str__(self):
        return f"MCQ key for {self.paper_submission_id}"


class PublishedGuide(TimeStampedModel):
    """The merge of the in-house MCQ answer key + the instructor-authored non-MCQ guide."""

    paper_submission = models.OneToOneField(PaperSubmission, on_delete=models.CASCADE, related_name="published_guide")
    content = models.JSONField()
    published_at = models.DateTimeField()

    def __str__(self):
        return f"Published guide for {self.paper_submission_id}"


class PaperViewLog(TimeStampedModel):
    """One row per question-paper view. Drives the 3-free-views/day paywall."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="paper_view_logs")
    paper_submission = models.ForeignKey(PaperSubmission, on_delete=models.CASCADE, related_name="view_logs")

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} viewed {self.paper_submission_id} at {self.created_at:%Y-%m-%d %H:%M}"


class AdWatchEvent(TimeStampedModel):
    """A completed rewarded-ad watch, granting exactly one additional paper view."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="ad_watch_events")
    # Consumed by the paper view it unlocked, null until spent.
    consumed_by_view_log = models.OneToOneField(
        PaperViewLog, on_delete=models.SET_NULL, null=True, blank=True, related_name="ad_watch_event"
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} watched ad at {self.created_at:%Y-%m-%d %H:%M}"
