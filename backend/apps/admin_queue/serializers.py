from rest_framework import serializers

from .models import AdminFlagQueue


class AdminFlagQueueSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminFlagQueue
        fields = [
            "id",
            "content_type",
            "object_id",
            "category",
            "reason",
            "status",
            "resolved_by",
            "resolved_at",
            "resolution_notes",
            "created_at",
        ]
        read_only_fields = [f for f in fields if f != "resolution_notes"]


class ResolveFlagSerializer(serializers.Serializer):
    notes = serializers.CharField(required=False, allow_blank=True, default="")
