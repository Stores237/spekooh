import uuid

from django import forms
from django.contrib import admin, messages
from unfold.admin import ModelAdmin

from apps.accounts.models import User

from .models import Note

SUPPORT_GROUP = "Support"


def staff_label(user) -> str:
    """Name only, never the email: nobody browsing this admin sees a user's
    raw email (see apps.accounts.admin.UserAdmin), and a staff member with no
    name set must not fall back to it here either."""
    return user.name or f"Staff member {user.pk}"


class AssignedToFilter(admin.SimpleListFilter):
    """Who owns a note: everyone with notes assigned, plus Unassigned and
    "Assigned to me". Built by hand so the labels are names, not emails."""

    title = "assigned to"
    parameter_name = "assigned"

    def lookups(self, request, model_admin):
        entries = [("me", "Assigned to me"), ("none", "Unassigned")]
        owners = User.objects.filter(assigned_notes__isnull=False).distinct().order_by("name")
        return entries + [(str(owner.pk), staff_label(owner)) for owner in owners]

    def queryset(self, request, queryset):
        value = self.value()
        if value == "me":
            return queryset.filter(assigned_to=request.user)
        if value == "none":
            return queryset.filter(assigned_to__isnull=True)
        if value:
            # A specific person: user ids are UUIDs. A malformed value shows
            # nothing rather than silently showing every note.
            try:
                return queryset.filter(assigned_to_id=uuid.UUID(value))
            except ValueError:
                return queryset.none()
        return queryset


class HasTextFilter(admin.SimpleListFilter):
    """Notes that still need their summary written, or already have one."""

    title = "summary text"
    parameter_name = "text"

    def lookups(self, request, model_admin):
        return [("missing", "Still to write"), ("written", "Written")]

    def queryset(self, request, queryset):
        if self.value() == "missing":
            return queryset.filter(body="")
        if self.value() == "written":
            return queryset.exclude(body="")
        return queryset


@admin.register(Note)
class NoteAdmin(ModelAdmin):
    """Summary notes: the study summaries students browse under Notes.

    Anyone with the notes permissions can add and edit; delete is separate
    (Owner, Reviewer and Integration Ops have it, Support deliberately does
    not). Each note can be assigned to a support-team member, who then owns
    writing and maintaining it. The assignment is internal and never sent to
    the app."""

    list_display = ("title", "subject_title", "academic_level", "assigned_to", "has_text", "sort_order")
    list_display_links = ("title",)
    list_editable = ("assigned_to",)
    list_filter = ("academic_level", "subject_title", AssignedToFilter, HasTextFilter)
    search_fields = ("title", "subject_title", "subtitle", "body")
    ordering = ("sort_order", "title")
    actions = ["assign_to_me", "clear_assignment"]
    fieldsets = (
        ("Note", {"fields": ("title", "subject_title", "academic_level", "subtitle", "sort_order")}),
        (
            "Summary text",
            {
                "fields": ("body",),
                "description": "What students read. A blank line starts a new paragraph, a line starting "
                "with '## ' is a heading, and a line starting with '- ' is a bullet point.",
            },
        ),
        ("Assignment", {"fields": ("assigned_to",), "description": "The support-team member who owns this note."}),
        ("Optional PDF", {"fields": ("pdf_file",)}),
    )

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        field = super().formfield_for_foreignkey(db_field, request, **kwargs)
        if db_field.name == "assigned_to" and isinstance(field, forms.ModelChoiceField):
            field.label_from_instance = staff_label
        return field

    @admin.display(boolean=True, description="Has text")
    def has_text(self, obj):
        return bool(obj.body.strip())

    def save_model(self, request, obj, form, change):
        # subtitle is the one "Subject · Level" string the app renders on the
        # note's row; without this a staff member who fills in Subject and
        # Academic level (the fields that drive the filters) and skips
        # Subtitle would publish a note with a blank second line.
        if not obj.subtitle and obj.subject_title and obj.academic_level:
            obj.subtitle = f"{obj.subject_title} · {obj.academic_level}"
        super().save_model(request, obj, form, change)

    @admin.action(description="Assign selected notes to me")
    def assign_to_me(self, request, queryset):
        if not request.user.groups.filter(name=SUPPORT_GROUP).exists():
            self.message_user(request, "Only support-team members can be assigned notes.", level=messages.ERROR)
            return
        updated = queryset.update(assigned_to=request.user)
        self.message_user(request, f"Assigned {updated} note(s) to you.", level=messages.SUCCESS)

    @admin.action(description="Remove the assignment from selected notes")
    def clear_assignment(self, request, queryset):
        updated = queryset.update(assigned_to=None)
        self.message_user(request, f"Cleared the assignment on {updated} note(s).", level=messages.SUCCESS)
