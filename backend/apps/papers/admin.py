from django.contrib import admin

from .models import (
    AdWatchEvent,
    ExamCategory,
    ExamType,
    MCQAnswerKey,
    PaperSubmission,
    PaperViewLog,
    PublishedGuide,
    Subject,
)


@admin.register(ExamCategory)
class ExamCategoryAdmin(admin.ModelAdmin):
    list_display = ("title", "key", "requires_system", "sort_order")
    ordering = ("sort_order",)


@admin.register(ExamType)
class ExamTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "system", "sort_order")
    list_filter = ("category", "system")


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ("title", "key", "code", "language")
    list_filter = ("language",)


@admin.register(PaperSubmission)
class PaperSubmissionAdmin(admin.ModelAdmin):
    list_display = ("id", "exam_type", "subject", "year", "status", "submitted_by", "created_at")
    list_filter = ("status", "category", "exam_type")
    search_fields = ("id", "submitted_by__email", "duplicate_hash")
    readonly_fields = ("created_at", "updated_at")


@admin.register(PaperViewLog)
class PaperViewLogAdmin(admin.ModelAdmin):
    list_display = ("user", "paper_submission", "created_at")
    search_fields = ("user__email",)


@admin.register(AdWatchEvent)
class AdWatchEventAdmin(admin.ModelAdmin):
    list_display = ("user", "consumed_by_view_log", "created_at")
    search_fields = ("user__email",)


@admin.register(MCQAnswerKey)
class MCQAnswerKeyAdmin(admin.ModelAdmin):
    list_display = ("paper_submission", "authored_by", "created_at")


@admin.register(PublishedGuide)
class PublishedGuideAdmin(admin.ModelAdmin):
    list_display = ("paper_submission", "published_at")
