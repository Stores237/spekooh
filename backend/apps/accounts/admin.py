from django import forms
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.contrib.auth.models import Group
from unfold.admin import ModelAdmin
from unfold.decorators import display

from . import services
from .models import StaffAccount, User


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

    def has_delete_permission(self, request, obj=None):
        # Owner decision (2026-09-25): nobody deletes an account from the
        # admin, the Owner included -- deactivate (is_active) instead. A
        # delete cascades to the person's paper submissions and pamphlet
        # orders and takes their payment history with it, and a staff
        # account carries audit history (what they reviewed, what they
        # resolved). Returning False also removes the bulk "delete
        # selected" action. Scheduled clean-ups of stale guest accounts
        # and staging test accounts are management commands, not this
        # screen, and are unaffected.
        return False


# The one group IT Helpdesk itself belongs to is included here too, on
# purpose: onboarding a peer (e.g. covering for someone on leave) isn't a
# privilege escalation the way granting Owner would be, since this whole
# screen's own permissions never go beyond what StaffAccountAdmin allows.
# "Owner" isn't in this list because it isn't a Group at all — it's
# is_superuser, which nothing here ever exposes a way to set.
IT_HELPDESK_GROUP_NAME = "IT Helpdesk"
ASSIGNABLE_ROLE_NAMES = ["Reviewer", "Support", "Integration Ops", IT_HELPDESK_GROUP_NAME]


def _assignable_roles():
    return Group.objects.filter(name__in=ASSIGNABLE_ROLE_NAMES)


class StaffAccountAddForm(forms.ModelForm):
    role = forms.ModelChoiceField(
        queryset=_assignable_roles(),
        help_text="What this person will be able to do — see Staff Roles for what each one covers.",
    )

    class Meta:
        model = StaffAccount
        fields = ("email", "name")

    def save(self, commit=True):
        user = super().save(commit=False)
        user.is_staff = True
        user.is_active = True
        # Nobody, including whoever fills in this form, ever knows a
        # password for this account — see services.send_staff_set_password_email.
        user.set_unusable_password()
        if commit:
            user.save()
            self.sync_role(user)
        return user

    def sync_role(self, user):
        user.groups.set([self.cleaned_data["role"]])


class StaffAccountChangeForm(forms.ModelForm):
    role = forms.ModelChoiceField(queryset=_assignable_roles(), required=False)

    class Meta:
        model = StaffAccount
        fields = ("name", "is_active")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            self.fields["role"].initial = self.instance.groups.filter(name__in=ASSIGNABLE_ROLE_NAMES).first()

    def save(self, commit=True):
        user = super().save(commit=commit)
        if commit:
            self.sync_role(user)
        return user

    def sync_role(self, user):
        role = self.cleaned_data.get("role")
        user.groups.set([role] if role else [])


@admin.register(StaffAccount)
class StaffAccountAdmin(ModelAdmin):
    """Owner request (2026-09-22): IT Helpdesk had nowhere to actually
    create a staff login against an already-provided work email, and had
    to be routed through the Owner's own User admin (which exposes
    is_superuser and every other role's permissions). This is that
    narrower screen: create a staff login, assign one role, done.

    Every permission check below is a hardcoded superuser-or-IT-Helpdesk
    group test, not Django's generic permission system — same
    defense-in-depth as apps.pamphlets.admin's support-override action.
    This screen can create a working admin login, so it never trusts
    anything softer than an explicit check.
    """

    list_display = ("name", "email", "role_display", "is_active", "last_login")
    search_fields = ("name", "email")
    ordering = ("-created_at",)
    actions = ["resend_set_password_link"]

    def get_queryset(self, request):
        return super().get_queryset(request).filter(is_staff=True)

    def _is_authorized(self, request, obj=None):
        if not (request.user.is_superuser or request.user.groups.filter(name=IT_HELPDESK_GROUP_NAME).exists()):
            return False
        # A second, independent guard beyond the form itself never exposing
        # is_superuser/is_staff: IT Helpdesk can't open a superuser's own
        # row here at all, even read-only — Django's change_view falls back
        # to a read-only render off has_view_permission alone, so this has
        # to be enforced there too, not only in has_change_permission.
        return obj is None or not obj.is_superuser or request.user.is_superuser

    def has_module_permission(self, request):
        return self._is_authorized(request)

    def has_view_permission(self, request, obj=None):
        return self._is_authorized(request, obj)

    def has_add_permission(self, request):
        return self._is_authorized(request)

    def has_change_permission(self, request, obj=None):
        return self._is_authorized(request, obj)

    def has_delete_permission(self, request, obj=None):
        # Deactivate (is_active) instead of deleting — same rule as
        # partner bookshops: a staff account may have real audit history
        # (who reviewed what, who resolved which ticket) attached to it.
        return False

    @admin.action(description="Resend set-password link", permissions=["change"])
    def resend_set_password_link(self, request, queryset):
        """A set-password link expires after a few days. With delete blocked,
        this is how someone whose link lapsed gets a fresh one. Only ever
        sent to an active account that still has no password -- one that
        already set theirs has nothing to resend."""
        sent = 0
        for user in queryset.filter(is_active=True):
            if user.has_usable_password():
                continue
            services.send_staff_set_password_email(user, request=request)
            sent += 1
        skipped = queryset.count() - sent
        message = f"Sent a new set-password link to {sent} account(s)."
        if skipped:
            message += f" Skipped {skipped}: already set a password, or deactivated."
        self.message_user(request, message)

    def get_form(self, request, obj=None, **kwargs):
        kwargs["form"] = StaffAccountChangeForm if obj else StaffAccountAddForm
        return super().get_form(request, obj, **kwargs)

    def get_fields(self, request, obj=None):
        return ("email", "name", "role") if obj is None else ("name", "is_active", "role")

    @display(description="Role")
    def role_display(self, obj):
        names = obj.groups.filter(name__in=ASSIGNABLE_ROLE_NAMES).values_list("name", flat=True)
        return ", ".join(names) or "No role assigned"

    def save_related(self, request, form, formsets, change):
        super().save_related(request, form, formsets, change)
        form.sync_role(form.instance)

    def response_add(self, request, obj, post_url_continue=None):
        services.send_staff_set_password_email(obj, request=request)
        self.message_user(request, f"Staff account created. A set-password link was emailed to {obj.email}.")
        return super().response_add(request, obj, post_url_continue)
