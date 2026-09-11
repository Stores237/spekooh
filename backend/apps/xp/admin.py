from django.contrib import admin
from unfold.admin import ModelAdmin

from .models import XPLedgerEntry


@admin.register(XPLedgerEntry)
class XPLedgerEntryAdmin(ModelAdmin):
    list_display = ("user", "amount", "reason", "created_at")
    list_filter = ("created_at",)
    search_fields = ("user__name", "user__email", "reason")
