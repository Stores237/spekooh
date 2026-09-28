from django.contrib import admin

from .models import Note


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ("title", "subtitle", "subject_title", "academic_level", "sort_order")
    list_filter = ("subject_title", "academic_level")
    search_fields = ("title", "subject_title", "subtitle")
    ordering = ("sort_order",)

    def save_model(self, request, obj, form, change):
        # subtitle is the one "Subject · Level" string the app renders on the
        # note's row; without this a staff member who fills in Subject and
        # Academic level (the fields that drive the filters) and skips
        # Subtitle would publish a note with a blank second line.
        if not obj.subtitle and obj.subject_title and obj.academic_level:
            obj.subtitle = f"{obj.subject_title} · {obj.academic_level}"
        super().save_model(request, obj, form, change)
