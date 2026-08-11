from django.contrib import admin, messages
from django.urls import NoReverseMatch, reverse
from django.utils.html import format_html
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import AdminFlagQueue, FlagStatus
from .services import resolve

STATUS_LABELS = {
    FlagStatus.OPEN: "danger",
    FlagStatus.RESOLVED: "success",
}


@admin.register(AdminFlagQueue)
class AdminFlagQueueAdmin(ModelAdmin):
    list_display = ("category", "subject_link", "status_badge", "created_at", "resolved_by")
    list_filter = ("category", "status")
    readonly_fields = ("content_type", "object_id", "category", "reason", "created_at")
    actions = ["resolve_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="Source object")
    def subject_link(self, obj):
        target = obj.subject
        if target is None:
            return f"{obj.content_type} #{obj.object_id} (deleted)"
        try:
            url = reverse(
                f"admin:{obj.content_type.app_label}_{obj.content_type.model}_change",
                args=[obj.object_id],
            )
            return format_html('<a href="{}">{}</a>', url, str(target))
        except NoReverseMatch:
            return str(target)

    @admin.action(description="Resolve selected flags")
    def resolve_selected(self, request, queryset):
        open_flags = queryset.filter(status=FlagStatus.OPEN)
        for flag_entry in open_flags:
            resolve(flag_entry, resolved_by=request.user, notes="Resolved via admin bulk action.")
        skipped = queryset.count() - open_flags.count()
        self.message_user(
            request,
            f"Resolved {open_flags.count()} flag(s)." + (f" Skipped {skipped} already resolved." if skipped else ""),
            level=messages.SUCCESS if open_flags.count() else messages.WARNING,
        )
