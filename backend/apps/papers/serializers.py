from rest_framework import serializers

from .models import AdWatchEvent, ExamCategory, ExamType, PaperSubmission, PaperViewLog, Subject


class ExamCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ExamCategory
        fields = ["id", "key", "title", "subtitle", "icon_name", "tint", "requires_system", "sort_order"]


class ExamTypeSerializer(serializers.ModelSerializer):
    requires_track = serializers.BooleanField(read_only=True)

    class Meta:
        model = ExamType
        fields = [
            "id",
            "category",
            "system",
            "name",
            "subtitle",
            "mock_variant_label",
            "tracks",
            "requires_track",
            "subject_language",
            "badge_tone",
            "sort_order",
        ]


class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ["id", "key", "title", "code", "icon_name", "tint", "language"]


class PaperSubmissionListSerializer(serializers.ModelSerializer):
    subject_title = serializers.CharField(source="subject.title", default=None, read_only=True)
    exam_type_name = serializers.CharField(source="exam_type.name", read_only=True)

    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "category",
            "exam_type",
            "exam_type_name",
            "subject",
            "subject_title",
            "system",
            "track",
            "year",
            "status",
            "created_at",
        ]


class PaperSubmissionDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "submitted_by",
            "category",
            "exam_type",
            "system",
            "track",
            "subject",
            "exam_board",
            "year",
            "file_ref",
            "ocr_text",
            "duplicate_hash",
            "is_duplicate",
            "duplicate_of",
            "mcq_section",
            "non_mcq_section",
            "status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "submitted_by",
            "ocr_text",
            "duplicate_hash",
            "is_duplicate",
            "duplicate_of",
            "status",
            "created_at",
            "updated_at",
        ]


class PaperSubmissionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "category",
            "exam_type",
            "system",
            "track",
            "subject",
            "exam_board",
            "year",
            "file_ref",
            "mcq_section",
            "non_mcq_section",
        ]
        read_only_fields = ["id"]

    def create(self, validated_data):
        validated_data["submitted_by"] = self.context["request"].user
        return super().create(validated_data)


class PaperViewLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperViewLog
        fields = ["id", "paper_submission", "created_at"]
        read_only_fields = fields


class AdWatchEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdWatchEvent
        fields = ["id", "created_at"]
        read_only_fields = fields
