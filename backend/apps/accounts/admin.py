from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    """Owner decision (regulatory data minimization): nobody browsing this
    admin — including superusers — sees a user's raw email or phone number.
    `name` is the only identifying field shown or searchable here. Email
    stays settable only on account *creation* (add_fieldsets), since
    that's the Owner typing in credentials they already know, not browsing
    an existing user's PII. Anyone who genuinely needs an existing user's
    email/phone for a real operational reason goes through `manage.py
    shell`, not this UI."""

    ordering = ("-created_at",)
    list_display = ("name", "account_type", "is_staff", "is_active", "created_at")
    list_filter = ("account_type", "is_staff", "is_active")
    search_fields = ("name", "guest_ref", "referral_code")
    fieldsets = (
        (None, {"fields": ("password",)}),
        ("Profile", {"fields": ("name", "education_level", "region", "language_pref")}),
        ("Account", {"fields": ("account_type", "guest_ref")}),
        ("Referrals", {"fields": ("referral_code", "referred_by", "referral_bonus_awarded_at")}),
        ("Compliance", {"fields": ("terms_accepted_at",)}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "name", "password1", "password2")}),
    )
    readonly_fields = (
        "created_at",
        "updated_at",
        "last_login",
        "referral_code",
        "referral_bonus_awarded_at",
        "terms_accepted_at",
    )
