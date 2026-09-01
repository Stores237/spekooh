from django.utils.text import slugify
from rest_framework import serializers

from apps.payments.models import PaperUnlock

from .models import (
    AdWatchEvent,
    ExamCategory,
    ExamType,
    PaperFlag,
    PaperSubmission,
    PaperViewLog,
    Subject,
    SubjectLanguage,
)
from .services import (
    STORAGE_KEY_RE,
    paper_download_price_fcfa,
    report_download_is_free,
    user_can_download_paper_file,
    user_can_view_file,
)


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
    """key/code/icon_name/tint stay read-only even on create: a
    contributor-typed subject only supplies a title, everything else is
    either derived (key, via slugify) or cosmetic curation the owner adds
    later (code/icon_name/tint default blank, same as any seeded row)."""

    class Meta:
        model = Subject
        fields = ["id", "key", "title", "code", "icon_name", "tint", "language"]
        read_only_fields = ["key", "code", "icon_name", "tint"]

    def create(self, validated_data):
        # get_or_create by key (not title) so "physics" and "Physics" don't
        # create two rows, and a contributor's typed subject that matches an
        # existing curated one (icon/tint already set) reuses it instead of
        # shadowing it with a bare duplicate.
        title = validated_data["title"].strip()
        key = slugify(title)[:60]
        subject, _ = Subject.objects.get_or_create(
            key=key,
            defaults={"title": title, "language": validated_data.get("language", SubjectLanguage.EN)},
        )
        return subject


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
    (already paid to view) require a real unlock to download; exam papers'
    PaperUnlock is a *different* purchase (it gates the marking guide, not
    the file — see paper_download_unlocked below for the file). Lower-tier
    reports (Internship/Bachelor's/HND) are free to both view and download
    (owner decision) — see report_download_is_free.

    paper_download_unlocked / paper_download_price_fcfa: exam papers only
    (owner decision, 2026-08-28) — free to view in-app (ReportViewerScreen,
    the same in-app-only renderer reports use), but downloading/saving the
    file is a separate, small, exam-level-priced purchase (PaperDownloadUnlock
    — see apps.papers.services.user_can_download_paper_file /
    apps.payments.services.unlock_paper_download). Always True for a report
    here — they keep the is_unlocked-based gate above instead.
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

    def get_paper_download_unlocked(self, obj) -> bool:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None:
            return obj.category.key == "reports"
        return user_can_download_paper_file(user, obj)

    def get_paper_download_price_fcfa(self, obj) -> int:
        return paper_download_price_fcfa(obj)

    def get_category_key(self, obj) -> str:
        return obj.category.key

    def get_has_marking_guide(self, obj) -> bool:
        # Real state, not "is this published" — a paper can be published
        # (see PaperSubmissionAdmin.publish_selected, which no longer
        # requires a guide to exist first) before its marking guide is
        # ready. Reports have no marking-guide concept at all, so this is
        # always False for them (PublishedGuide is never created for one).
        return getattr(obj, "published_guide", None) is not None

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
    has_marking_guide = serializers.SerializerMethodField()
    paper_download_unlocked = serializers.SerializerMethodField()
    paper_download_price_fcfa = serializers.SerializerMethodField()

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
            "has_marking_guide",
            "paper_download_unlocked",
            "paper_download_price_fcfa",
            "status",
            "rejection_reason",
            "dismissed_by_contributor",
            "created_at",
        ]
        read_only_fields = ["rejection_reason", "dismissed_by_contributor"]


class PaperSubmissionDetailSerializer(PaperAccessFieldsMixin, serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    category_key = serializers.SerializerMethodField()
    requires_unlock = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()
    has_marking_guide = serializers.SerializerMethodField()
    paper_download_unlocked = serializers.SerializerMethodField()
    paper_download_price_fcfa = serializers.SerializerMethodField()

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
            "has_marking_guide",
            "paper_download_unlocked",
            "paper_download_price_fcfa",
            "ocr_text",
            "duplicate_hash",
            "is_duplicate",
            "duplicate_of",
            "mcq_section",
            "non_mcq_section",
            "status",
            "rejection_reason",
            "dismissed_by_contributor",
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
            "rejection_reason",
            "dismissed_by_contributor",
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
    paper_download_unlocked = serializers.SerializerMethodField()
    paper_download_price_fcfa = serializers.SerializerMethodField()
    # Alternative to uploaded_file (2026-08-30 direct-to-storage upload fix,
    # see apps.papers.services.presign_paper_upload): the app PUTs the file
    # straight to storage first, then submits just this key instead of the
    # bytes themselves. Exactly one of uploaded_file/storage_key is required
    # — see validate() below. Never client-chosen freely: validate_storage_key
    # only accepts a key shaped like one presign_upload actually issued.
    storage_key = serializers.CharField(required=False, write_only=True, allow_blank=False)

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
            "storage_key",
            "file_url",
            "requires_unlock",
            "is_unlocked",
            "paper_download_unlocked",
            "paper_download_price_fcfa",
            "status",
            "created_at",
            "mcq_section",
            "non_mcq_section",
        ]
        read_only_fields = ["id", "file_url", "status", "created_at"]
        extra_kwargs = {"uploaded_file": {"required": False, "write_only": True}}

    def validate_storage_key(self, value):
        if not STORAGE_KEY_RE.match(value):
            raise serializers.ValidationError("Not a key this server issued via the upload-url endpoint.")
        return value

    def validate(self, attrs):
        uploaded_file = attrs.get("uploaded_file")
        storage_key = attrs.get("storage_key")
        if bool(uploaded_file) == bool(storage_key):
            raise serializers.ValidationError({"uploaded_file": "Provide exactly one of uploaded_file or storage_key."})
        exam_type = attrs.get("exam_type")
        if exam_type is not None and uploaded_file is not None:
            max_bytes = exam_type.max_upload_mb * 1024 * 1024
            if uploaded_file.size > max_bytes:
                raise serializers.ValidationError(
                    {"uploaded_file": f"File is too large. {exam_type.name} allows up to {exam_type.max_upload_mb}MB."}
                )
            # storage_key path can't be size-checked server-side (Django
            # never receives the bytes) — relies on the app's own
            # client-side pre-check before it ever requests a presigned URL.
        return attrs

    def create(self, validated_data):
        validated_data["submitted_by"] = self.context["request"].user
        storage_key = validated_data.pop("storage_key", None)
        if storage_key:
            instance = PaperSubmission(**validated_data)
            # Assigning a plain string (not a File/UploadedFile) to a
            # FileField sets .name directly without triggering any storage
            # write — the bytes are already at that key, PUT there straight
            # by the client. This is the entire point of this path.
            instance.uploaded_file.name = storage_key
            instance.save()
            return instance
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
