from rest_framework import serializers

from .models import Note


class NoteSerializer(serializers.ModelSerializer):
    """The list row: title and level only, so the list stays light."""

    class Meta:
        model = Note
        fields = ["id", "title", "subtitle", "subject_title", "academic_level"]


class NoteDetailSerializer(NoteSerializer):
    """One note with its text. `assigned_to` is deliberately absent: which
    support-team member owns a note is an internal detail, not for the app."""

    class Meta(NoteSerializer.Meta):
        fields = NoteSerializer.Meta.fields + ["body"]
