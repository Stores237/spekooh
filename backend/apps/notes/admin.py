from django.contrib import admin

from .models import Note


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ("title", "subtitle", "subject_title", "academic_level", "sort_order")
    list_filter = ("subject_title", "academic_level")
    ordering = ("sort_order",)
