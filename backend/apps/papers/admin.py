from django.contrib import admin, messages
from django.db.models import Q
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import (
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
    list_display = ("id", "exam_type", "subject", "year", "status_badge", "submitted_by", "created_at")
    list_filter = ("status", "category", "exam_type")
    search_fields = ("id", "submitted_by__email", "duplicate_hash")
    readonly_fields = ("created_at", "updated_at")
    actions = ["publish_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @admin.action(description="Publish selected (exam papers: guide submitted/merged; reports: any reviewed status — awards contributor bonus)")
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
                f" Skipped {skipped} — exam papers need Guide submitted/Merged status; reports just can't already be Published."
                if skipped
                else ""
            ),
            level=messages.SUCCESS if eligible.count() else messages.WARNING,
        )


@admin.register(PaperFlag)
class PaperFlagAdmin(ModelAdmin):
    list_display = ("paper_submission", "reason", "flagged_by", "created_at")
    list_filter = ("reason",)
    search_fields = ("paper_submission__id", "flagged_by__email")
    readonly_fields = ("created_at", "updated_at")


@admin.register(PaperViewLog)
class PaperViewLogAdmin(ModelAdmin):
    list_display = ("user", "paper_submission", "created_at")
    search_fields = ("user__email",)


@admin.register(AdWatchEvent)
class AdWatchEventAdmin(ModelAdmin):
    list_display = ("user", "consumed_by_view_log", "created_at")
    search_fields = ("user__email",)


@admin.register(MCQAnswerKey)
class MCQAnswerKeyAdmin(ModelAdmin):
    list_display = ("paper_submission", "authored_by", "created_at")


@admin.register(PublishedGuide)
class PublishedGuideAdmin(ModelAdmin):
    list_display = ("paper_submission", "published_at")
