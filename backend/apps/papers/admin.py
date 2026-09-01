from django.contrib import admin, messages
from django.utils.html import format_html
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import (
    AcademicReportSubmission,
    AdWatchEvent,
    ExamCategory,
    ExamType,
    MCQAnswerKey,
    PaperFlag,
    PaperStatus,
    PaperSubmission,
    PaperViewLog,
    PublishedGuide,
    Subject,
)
from .services import mark_published, reject_submission


def _uploaded_file_link(uploaded_file):
    """A direct view/download link for an admin list column — .url works for
    both local disk and remote (Supabase S3) storage, unlike .path() which
    only local disk supports (see PaperSubmission.save)."""
    if not uploaded_file:
        return "-"
    try:
        url = uploaded_file.url
    except ValueError:
        return "-"
    return format_html('<a href="{}" target="_blank" rel="noopener noreferrer">View / download</a>', url)

STATUS_LABELS = {
    PaperStatus.PENDING_REVIEW: "warning",
    PaperStatus.INSTRUCTOR_REQUEST_SENT: "info",
    PaperStatus.INSTRUCTOR_ACCEPTED: "info",
    PaperStatus.INSTRUCTOR_REJECTED: "danger",
    PaperStatus.AWAITING_MARKING_GUIDE: "warning",
    PaperStatus.GUIDE_SUBMITTED: "primary",
    PaperStatus.MERGED: "primary",
    PaperStatus.PUBLISHED: "success",
    PaperStatus.UNASSIGNED_ADMIN_QUEUE: "danger",
    PaperStatus.REJECTED: "danger",
}


@admin.register(ExamCategory)
class ExamCategoryAdmin(ModelAdmin):
    list_display = ("title", "key", "requires_system", "sort_order")
    ordering = ("sort_order",)


@admin.register(ExamType)
class ExamTypeAdmin(ModelAdmin):
    list_display = ("name", "category", "system", "sort_order")
    list_filter = ("category", "system")


@admin.register(Subject)
class SubjectAdmin(ModelAdmin):
    list_display = ("title", "key", "code", "language")
    list_filter = ("language",)


@admin.register(PaperSubmission)
class PaperSubmissionAdmin(ModelAdmin):
    list_display = ("id", "exam_type", "subject", "year", "status_badge", "submitted_by", "created_at", "file_link")
    list_filter = ("status", "category", "exam_type")
    search_fields = ("id", "submitted_by__name", "duplicate_hash")
    readonly_fields = ("created_at", "updated_at")
    actions = ["publish_selected", "reject_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="File")
    def file_link(self, obj):
        return _uploaded_file_link(obj.uploaded_file)

    @admin.action(description="Publish selected (any reviewed status; awards contributor bonus)")
    def publish_selected(self, request, queryset):
        # Owner decision (2026-08-28): an exam paper no longer has to wait
        # on the instructor-guide pipeline to be published — a contributor's
        # scan is useful to other students well before a marking guide
        # exists, and instructors can take a long time to produce a decent
        # one. Publishing here never fabricates a guide: has_marking_guide
        # (PaperAccessFieldsMixin.get_has_marking_guide) reflects whether a
        # real PublishedGuide exists independent of publish status, and the
        # app shows an honest "marking guide not available yet" instead of
        # a fake unlock button when it doesn't. The real instructor pipeline
        # (merge_and_publish) still works exactly as before for a paper
        # that does go through it — this action doesn't replace that, it's
        # just no longer the only way to get a paper in front of students.
        # Only guard left: can't re-publish something already published,
        # so re-selecting one doesn't double-award the contributor bonus
        # (award_contributor_bonus is not itself idempotent).
        eligible = queryset.exclude(status=PaperStatus.PUBLISHED)
        for paper in eligible:
            mark_published(paper)
        skipped = queryset.count() - eligible.count()
        self.message_user(
            request,
            f"Published {eligible.count()} paper(s)."
            + (f" Skipped {skipped}: already Published." if skipped else ""),
            level=messages.SUCCESS if eligible.count() else messages.WARNING,
        )

    @admin.action(description="Reject selected (requires Rejection reason to already be filled in)")
    def reject_selected(self, request, queryset):
        # Bulk admin actions can't collect free-text input per row — the
        # workflow is: open the submission, type the real reason into
        # Rejection reason, save, then select it and run this action. A row
        # with that field still blank is skipped rather than rejected with
        # no explanation, since the contributor-facing notification quotes
        # this field directly (apps.papers.services.reject_submission) —
        # an unexplained rejection is worse than no action at all.
        eligible = queryset.exclude(status=PaperStatus.REJECTED).exclude(rejection_reason="")
        for paper in eligible:
            reject_submission(paper, reason=paper.rejection_reason)
        skipped = queryset.count() - eligible.count()
        self.message_user(
            request,
            f"Rejected {eligible.count()} paper(s)."
            + (f" Skipped {skipped}: already Rejected, or Rejection reason is blank." if skipped else ""),
            level=messages.SUCCESS if eligible.count() else messages.WARNING,
        )


@admin.register(AcademicReportSubmission)
class AcademicReportSubmissionAdmin(PaperSubmissionAdmin):
    """Reports' own admin section — the general PaperSubmissionAdmin list
    shows `subject`, which is always blank for reports (no subject
    taxonomy), so reviewing them there is nearly blind to what they
    actually are. This shows the fields that matter for a report instead,
    plus the same direct file link."""

    list_display = (
        "id",
        "exam_type",
        "institution",
        "discipline",
        "supervisor_name",
        "year",
        "status_badge",
        "submitted_by",
        "created_at",
        "file_link",
    )
    list_filter = ("status", "exam_type")
    search_fields = ("id", "submitted_by__name", "institution", "discipline", "supervisor_name")

    def get_queryset(self, request):
        return super().get_queryset(request).filter(category__key="reports")


@admin.register(PaperFlag)
class PaperFlagAdmin(ModelAdmin):
    list_display = ("paper_submission", "reason", "flagged_by", "created_at")
    list_filter = ("reason",)
    search_fields = ("paper_submission__id", "flagged_by__name")
    readonly_fields = ("created_at", "updated_at")


@admin.register(PaperViewLog)
class PaperViewLogAdmin(ModelAdmin):
    # paper_submission's own __str__ always says "no subject" for a report
    # (reports have no Subject taxonomy — see PaperSubmission.subject), so a
    # plain str column here told an admin nothing about which report was
    # actually viewed. paper_label swaps in the fields that do, and
    # file_link gets straight to the document without hunting for it.
    list_display = ("user", "paper_label", "created_at", "file_link")
    list_filter = ("paper_submission__category",)
    search_fields = ("user__name", "paper_submission__institution", "paper_submission__discipline")

    @display(description="Paper / report")
    def paper_label(self, obj):
        paper = obj.paper_submission
        if paper.category.key == "reports":
            return f"{paper.exam_type}, {paper.institution or paper.discipline or 'report'} ({paper.year})"
        return str(paper)

    @display(description="File")
    def file_link(self, obj):
        return _uploaded_file_link(obj.paper_submission.uploaded_file)


@admin.register(AdWatchEvent)
class AdWatchEventAdmin(ModelAdmin):
    list_display = ("user", "consumed_by_view_log", "created_at")
    search_fields = ("user__name",)


@admin.register(MCQAnswerKey)
class MCQAnswerKeyAdmin(ModelAdmin):
    list_display = ("paper_submission", "authored_by", "created_at")


@admin.register(PublishedGuide)
class PublishedGuideAdmin(ModelAdmin):
    list_display = ("paper_submission", "published_at")
