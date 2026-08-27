from rest_framework import serializers

from apps.payments.models import PaperUnlock

from .models import AdWatchEvent, ExamCategory, ExamType, PaperFlag, PaperSubmission, PaperViewLog, Subject
from .services import report_download_is_free, user_can_view_file


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
            "requires_payment_to_view",
            "max_upload_mb",
        ]


class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ["id", "key", "title", "code", "icon_name", "tint", "language"]


class PaperAccessFieldsMixin:
    """Shared by every PaperSubmission serializer that exposes the file —
    keeps the view-gate (requires_unlock/file_url) and the separate
    download-gate (is_unlocked) consistent in one place instead of
    triplicated per serializer.

    requires_unlock: can this request's user see the file at all (server-
    side withheld file_url for PhD/Master's-tier reports until paid — see
    apps.papers.services.user_can_view_file).

    is_unlocked: has this user actually completed a real PaperUnlock for
    this paper — independent of requires_unlock. Master's/PhD-tier reports
    (already paid to view) and exam papers (whose PaperUnlock also gates
    the marking guide) still require a real unlock to download. Lower-tier
    reports (Internship/Bachelor's/HND) are free to both view and download
    (owner decision) — see report_download_is_free.
    """

    def get_requires_unlock(self, obj) -> bool:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        return user is None or not user_can_view_file(user, obj)

    def get_is_unlocked(self, obj) -> bool:
        if report_download_is_free(obj):
            return True
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False
        return PaperUnlock.objects.has_unlocked(user, obj)

    def get_category_key(self, obj) -> str:
        return obj.category.key

    def get_file_url(self, obj) -> str | None:
        if not obj.uploaded_file:
            return None
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or not user_can_view_file(user, obj):
            return None
        url = obj.uploaded_file.url
        return request.build_absolute_uri(url) if request else url


class PaperSubmissionListSerializer(PaperAccessFieldsMixin, serializers.ModelSerializer):
    subject_title = serializers.CharField(source="subject.title", default=None, read_only=True)
    exam_type_name = serializers.CharField(source="exam_type.name", read_only=True)
    category_key = serializers.SerializerMethodField()
    requires_unlock = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()

    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "category",
            "category_key",
            "exam_type",
            "exam_type_name",
            "subject",
            "subject_title",
            "system",
            "track",
            "year",
            "institution",
            "discipline",
            "supervisor_name",
            "requires_unlock",
            "is_unlocked",
            "status",
            "created_at",
        ]


class PaperSubmissionDetailSerializer(PaperAccessFieldsMixin, serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    category_key = serializers.SerializerMethodField()
    requires_unlock = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()

    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "submitted_by",
            "category",
            "category_key",
            "exam_type",
            "system",
            "track",
            "subject",
            "exam_board",
            "year",
            "institution",
            "discipline",
            "supervisor_name",
            "file_url",
            "requires_unlock",
            "is_unlocked",
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


class PaperSubmissionCreateSerializer(PaperAccessFieldsMixin, serializers.ModelSerializer):
    # Included so the create response is a real, complete PaperEntry (status,
    # file_url, created_at) instead of an echo of just the input fields —
    # the app shows the freshly-submitted paper immediately, it doesn't
    # re-fetch. requires_unlock is always false here — you never need to
    # pay to see the file you just submitted yourself (is_unlocked stays
    # real: submitting isn't the same as paying, so a report still needs a
    # real unlock before it can be downloaded, same as anyone else's).
    file_url = serializers.SerializerMethodField()
    category_key = serializers.SerializerMethodField()
    requires_unlock = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()

    class Meta:
        model = PaperSubmission
        fields = [
            "id",
            "category",
            "category_key",
            "exam_type",
            "system",
            "track",
            "subject",
            "exam_board",
            "year",
            "institution",
            "discipline",
            "supervisor_name",
            "uploaded_file",
            "file_url",
            "requires_unlock",
            "is_unlocked",
            "status",
            "created_at",
            "mcq_section",
            "non_mcq_section",
        ]
        read_only_fields = ["id", "file_url", "status", "created_at"]
        extra_kwargs = {"uploaded_file": {"required": True, "write_only": True}}

    def validate(self, attrs):
        exam_type = attrs.get("exam_type")
        uploaded_file = attrs.get("uploaded_file")
        if exam_type is not None and uploaded_file is not None:
            max_bytes = exam_type.max_upload_mb * 1024 * 1024
            if uploaded_file.size > max_bytes:
                raise serializers.ValidationError(
                    {"uploaded_file": f"File is too large. {exam_type.name} allows up to {exam_type.max_upload_mb}MB."}
                )
        return attrs

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
