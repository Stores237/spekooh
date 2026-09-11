from django.contrib import admin
from unfold.admin import ModelAdmin

from .models import Promotion


@admin.register(Promotion)
class PromotionAdmin(ModelAdmin):
    list_display = ("title", "sponsor_name", "is_active", "sort_order", "created_at")
    list_filter = ("is_active",)
    search_fields = ("title", "sponsor_name")
