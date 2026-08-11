from django.contrib import admin

from .models import Note


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ("title", "subtitle", "sort_order")
    ordering = ("sort_order",)
