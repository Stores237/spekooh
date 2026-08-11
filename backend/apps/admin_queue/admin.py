from django.contrib import admin

from .models import AdminFlagQueue


@admin.register(AdminFlagQueue)
class AdminFlagQueueAdmin(admin.ModelAdmin):
    list_display = ("category", "subject", "status", "created_at", "resolved_by")
    list_filter = ("category", "status")
    readonly_fields = ("content_type", "object_id", "category", "reason", "created_at")
