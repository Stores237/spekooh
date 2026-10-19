from rest_framework import serializers

from .models import Note


class NoteSerializer(serializers.ModelSerializer):
    """The list row: title and level only, so the list stays light.

    subject_title/academic_level keep their original flat-string field names
    on the wire (the app reads them as plain strings) even though the model
    now holds real Subject/ExamCategory FKs underneath.
    """

    subject_title = serializers.CharField(source="subject.title", read_only=True)
    academic_level = serializers.CharField(source="level.title", read_only=True)

    class Meta:
        model = Note
        fields = ["id", "title", "subtitle", "subject_title", "academic_level"]


class NoteDetailSerializer(NoteSerializer):
    """One note with its text. `assigned_to` is deliberately absent: which
    support-team member owns a note is an internal detail, not for the app."""

    class Meta(NoteSerializer.Meta):
        fields = NoteSerializer.Meta.fields + ["body"]
