from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import AdminFlagQueue


class AdminFlagQueueSerializer(serializers.ModelSerializer):
    age_days = serializers.ReadOnlyField()

    class Meta:
        model = AdminFlagQueue
        fields = [
            "id",
            "content_type",
            "object_id",
            "category",
            "reason",
            "status",
            "assignee",
            "age_days",
            "resolved_by",
            "resolved_at",
            "resolution_notes",
            "created_at",
        ]
        read_only_fields = [f for f in fields if f != "resolution_notes"]


class ResolveFlagSerializer(serializers.Serializer):
    notes = serializers.CharField(required=False, allow_blank=True, default="")


class AssignFlagSerializer(serializers.Serializer):
    assignee_id = serializers.PrimaryKeyRelatedField(source="assignee", queryset=get_user_model().objects.all())
