from django.contrib import admin, messages
from django.db.models import Q
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
from .services import mark_published


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
    actions = ["publish_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="File")
    def file_link(self, obj):
        return _uploaded_file_link(obj.uploaded_file)

    @admin.action(description="Publish selected (exam papers: guide submitted/merged; reports: any reviewed status; awards contributor bonus)")
    def publish_selected(self, request, queryset):
        # Reports have no marking-guide/instructor pipeline at all (see the
        # "no marking guide" copy on the Academic Reports category) — they
        # default to PENDING_REVIEW and can never reach GUIDE_SUBMITTED/
        # MERGED, so gating them on that status meant a report could never
        # be published through this action. Exam papers keep the real
        # pipeline gate; reports just need a real review (any status short
        # of already-PUBLISHED, so re-selecting one doesn't double-award
        # the contributor bonus — see award_contributor_bonus, not itself
        # idempotent).
        is_report = Q(category__key="reports")
        eligible = queryset.filter(
            (~is_report & Q(status__in=[PaperStatus.GUIDE_SUBMITTED, PaperStatus.MERGED]))
            | (is_report & ~Q(status=PaperStatus.PUBLISHED))
        )
        for paper in eligible:
            mark_published(paper)
        skipped = queryset.count() - eligible.count()
        self.message_user(
            request,
            f"Published {eligible.count()} paper(s)."
            + (
                f" Skipped {skipped}: exam papers need Guide submitted/Merged status; reports just can't already be Published."
                if skipped
                else ""
            ),
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
