from rest_framework import serializers

from .models import AdWatchEvent, ExamCategory, ExamType, PaperFlag, PaperSubmission, PaperViewLog, Subject


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
    file_url = serializers.SerializerMethodField()

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
            "file_url",
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

    def get_file_url(self, obj) -> str | None:
        if not obj.uploaded_file:
            return None
        request = self.context.get("request")
        url = obj.uploaded_file.url
        return request.build_absolute_uri(url) if request else url


class PaperSubmissionCreateSerializer(serializers.ModelSerializer):
    # Included so the create response is a real, complete PaperEntry (status,
    # file_url, created_at) instead of an echo of just the input fields —
    # the app shows the freshly-submitted paper immediately, it doesn't
    # re-fetch.
    file_url = serializers.SerializerMethodField()

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
            "uploaded_file",
            "file_url",
            "status",
            "created_at",
            "mcq_section",
            "non_mcq_section",
        ]
        read_only_fields = ["id", "file_url", "status", "created_at"]
        extra_kwargs = {"uploaded_file": {"required": True, "write_only": True}}

    def get_file_url(self, obj) -> str | None:
        if not obj.uploaded_file:
            return None
        request = self.context.get("request")
        url = obj.uploaded_file.url
        return request.build_absolute_uri(url) if request else url

    def create(self, validated_data):
        validated_data["submitted_by"] = self.context["request"].user
        return super().create(validated_data)


class PaperFlagSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperFlag
        fields = ["id", "paper_submission", "reason", "details", "created_at"]
        read_only_fields = ["id", "paper_submission", "created_at"]


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
