from django.contrib import admin
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import ArtifactStatus, GeneratedArtifact

STATUS_LABELS = {
    ArtifactStatus.PENDING: "info",
    ArtifactStatus.RUNNING: "warning",
    ArtifactStatus.READY: "success",
    ArtifactStatus.FAILED: "danger",
}


@admin.register(GeneratedArtifact)
class GeneratedArtifactAdmin(ModelAdmin):
    list_display = ("kind", "language", "source", "status_badge", "attempts", "model_used", "updated_at")
    list_filter = ("kind", "language", "status")
    readonly_fields = ("content_type", "object_id", "kind", "language", "prompt_version", "source_hash", "model_used", "tokens_in", "tokens_out", "created_at", "updated_at")
    actions = ["retry_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @admin.action(description="Retry generation (resets to pending, next cron run picks it up)")
    def retry_selected(self, request, queryset):
        # Doesn't call the provider inline from the admin request — the
        # real generation still only ever happens from
        # generate_pending_artifacts (cron-driven), same as every other
        # background job in this codebase. This just clears a FAILED row
        # back to PENDING so the next scheduled run retries it, rather
        # than waiting out attempts < 3 or manually deleting the row.
        updated = queryset.exclude(status=ArtifactStatus.READY).update(status=ArtifactStatus.PENDING, attempts=0, error="")
        self.message_user(request, f"{updated} artifact(s) reset to pending.")
