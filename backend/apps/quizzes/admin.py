from django.contrib import admin

from .models import Quiz, QuizAttempt, QuizQuestion


class QuizQuestionInline(admin.TabularInline):
    model = QuizQuestion
    extra = 1


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ("title", "subject", "is_daily_challenge", "played_count")
    list_filter = ("is_daily_challenge", "subject")
    inlines = [QuizQuestionInline]


@admin.register(QuizAttempt)
class QuizAttemptAdmin(admin.ModelAdmin):
    list_display = ("user", "quiz", "score", "completed_at")
    search_fields = ("user__email",)
