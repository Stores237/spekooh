from django.contrib import admin, messages
from django.urls import NoReverseMatch, reverse
from django.utils.html import format_html
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import AdminFlagQueue, FlagStatus
from .services import assign, resolve

STATUS_LABELS = {
    FlagStatus.NEW: "danger",
    FlagStatus.IN_PROGRESS: "warning",
    FlagStatus.RESOLVED: "success",
}


@admin.register(AdminFlagQueue)
class AdminFlagQueueAdmin(ModelAdmin):
    list_display = ("category", "subject_link", "status_badge", "age_badge", "assignee", "created_at")
    list_filter = ("category", "status", "assignee")
    readonly_fields = ("content_type", "object_id", "category", "reason", "created_at")
    actions = ["claim_selected", "resolve_selected"]

    @display(description="Status", label=STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="Age")
    def age_badge(self, obj):
        days = obj.age_days
        return "today" if days == 0 else f"{days}d"

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

    @admin.action(description="Claim selected (assign to me, -> In Progress)")
    def claim_selected(self, request, queryset):
        claimable = queryset.exclude(status=FlagStatus.RESOLVED)
        for flag_entry in claimable:
            assign(flag_entry, assignee=request.user)
        skipped = queryset.count() - claimable.count()
        self.message_user(
            request,
            f"Claimed {claimable.count()} ticket(s)." + (f" Skipped {skipped} already resolved." if skipped else ""),
            level=messages.SUCCESS if claimable.count() else messages.WARNING,
        )

    @admin.action(description="Resolve selected")
    def resolve_selected(self, request, queryset):
        open_flags = queryset.exclude(status=FlagStatus.RESOLVED)
        for flag_entry in open_flags:
            resolve(flag_entry, resolved_by=request.user, notes="Resolved via admin bulk action.")
        skipped = queryset.count() - open_flags.count()
        self.message_user(
            request,
            f"Resolved {open_flags.count()} flag(s)." + (f" Skipped {skipped} already resolved." if skipped else ""),
            level=messages.SUCCESS if open_flags.count() else messages.WARNING,
        )
