from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ("-created_at",)
    list_display = ("email", "name", "account_type", "is_staff", "is_active", "created_at")
    list_filter = ("account_type", "is_staff", "is_active")
    search_fields = ("email", "name", "phone_number", "guest_ref", "referral_code")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Profile", {"fields": ("name", "phone_number", "education_level", "region", "language_pref")}),
        ("Account", {"fields": ("account_type", "guest_ref")}),
        ("Referrals", {"fields": ("referral_code", "referred_by", "referral_bonus_awarded_at")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "name", "password1", "password2")}),
    )
    readonly_fields = ("created_at", "updated_at", "last_login", "referral_code", "referral_bonus_awarded_at")
