from django.db.models import Q
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest
from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag

from .models import ExamCategory, ExamType, PaperStatus, PaperSubmission, Subject
from .serializers import (
    AdWatchEventSerializer,
    ExamCategorySerializer,
    ExamTypeSerializer,
    PaperFlagSerializer,
    PaperSubmissionCreateSerializer,
    PaperSubmissionDetailSerializer,
    PaperSubmissionListSerializer,
    PaperViewLogSerializer,
    PublishedGuideSerializer,
    SubjectSerializer,
)
from .services import (
    AlreadyFlaggedError,
    PaywallError,
    mark_published,
    presign_paper_upload,
    process_ocr_and_duplicate_check,
    record_ad_watch,
    record_paper_view,
    report_paper,
    user_can_view_guide,
    watermark_report_submission,
)


class ExamCategoryViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = ExamCategory.objects.all()
    serializer_class = ExamCategorySerializer


class ExamTypeViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = ExamType.objects.all()
    serializer_class = ExamTypeSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["category", "system"]


class SubjectViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.CreateModelMixin, viewsets.GenericViewSet):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["language"]

    def get_permissions(self):
        if self.action == "create":
            # Same bar as submitting a paper itself (see PaperSubmissionViewSet
            # .get_permissions) — a guest account can propose a subject the
            # curated list is missing, real accounts aren't required.
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]


class PaperSubmissionViewSet(
    mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet
):
    # Owner decision (2026-09-06, supersedes the original spec quoted
    # below): a guest account may now ONLY contribute a paper/report —
    # viewing one (list/retrieve/view) requires a real, non-guest account
    # too, same as everything else on this class. The original spec's own
    # words: "guest browsing allowed... account required only for
    # streaks/XP, forum posting, ... not for reading" — reading is no
    # longer the exception; `create` (see get_permissions) now is.
    # process_ocr/mark_published set their own IsAdminUser via
    # @action(permission_classes=...) — defer to super() there instead of
    # hardcoding, or those per-action overrides get silently clobbered.
    permission_classes = [IsAuthenticatedNotGuest]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ["status", "category", "exam_type", "subject", "system", "track", "submitted_by"]
    ordering_fields = ["created_at", "year"]

    def get_permissions(self):
        if self.action == "create":
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    def get_queryset(self):
        qs = PaperSubmission.objects.select_related("category", "exam_type", "subject")
        user = self.request.user
        if user.is_authenticated and user.is_staff:
            return qs
        if user.is_authenticated:
            # Published papers from anyone, plus your own at any status
            # (so "My submissions" on the Profile screen just works).
            return qs.filter(Q(status=PaperStatus.PUBLISHED) | Q(submitted_by=user))
        # An anonymous/guest request never reaches here at all in practice
        # now — the class-level IsAuthenticatedNotGuest above rejects it
        # before get_queryset ever runs for list/retrieve/view — but this
        # stays a defensive fallback rather than assuming that always holds.
        return qs.filter(status=PaperStatus.PUBLISHED)

    def get_serializer_class(self):
        if self.action == "create":
            return PaperSubmissionCreateSerializer
        if self.action == "list":
            return PaperSubmissionListSerializer
        return PaperSubmissionDetailSerializer

    def perform_create(self, serializer):
        # Spec §2.1: every new submission auto-creates a Review Team
        # verification ticket rather than sitting silently in PENDING_REVIEW
        # until someone happens to look.
        paper = serializer.save()
        watermark_report_submission(paper)
        flag(
            subject=paper,
            category=FlagCategory.PAPER_VERIFICATION,
            reason="New paper submission awaiting review team verification.",
        )

    @action(detail=False, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def upload_url(self, request):
        # Real fix (2026-08-30) for the slow submit->submitted round trip:
        # hands back a presigned URL the app PUTs the file straight to
        # (Supabase Storage), bypassing Django entirely for the bytes
        # themselves — see apps.papers.services.presign_paper_upload. Same
        # permission bar as `create` (a guest account may submit a paper).
        filename = request.data.get("filename")
        content_type = request.data.get("content_type")
        if not filename or not content_type:
            return Response(
                {"detail": "filename and content_type are required."}, status=status.HTTP_400_BAD_REQUEST
            )
        presigned = presign_paper_upload(filename=filename, content_type=content_type)
        if presigned is None:
            # Local-disk dev fallback has no presigning concept — the app
            # falls back to the old multipart-upload path when it sees this.
            return Response(
                {"detail": "Direct upload isn't available on this server."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response(presigned, status=status.HTTP_200_OK)

    @action(detail=True, methods=["post"])
    def view(self, request, pk=None):
        # No guest exemption here any more (2026-09-06) — this action falls
        # through to the class-level IsAuthenticatedNotGuest, so
        # request.user is guaranteed a real, non-guest account by the time
        # this runs. The old exemption existed only because reading used to
        # be guest-open; that's no longer true (see this class's own
        # top-of-file comment).
        paper = self.get_object()
        try:
            log = record_paper_view(user=request.user, paper_submission=paper)
        except PaywallError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(PaperViewLogSerializer(log).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get"])
    def guide(self, request, pk=None):
        """The actual guide content — has_marking_guide (on the list/detail
        serializers) only ever told the client whether one exists at all.
        Same "no such thing yet" vs "you haven't paid for it" distinction
        user_can_download_paper_file's callers already make elsewhere."""
        paper = self.get_object()
        published_guide = getattr(paper, "published_guide", None)
        if published_guide is None:
            return Response(
                {"detail": "No marking guide has been published for this paper yet."},
                status=status.HTTP_404_NOT_FOUND,
            )
        if not user_can_view_guide(request.user, paper):
            return Response(
                {"detail": "Unlock this paper's marking guide to view it."}, status=status.HTTP_402_PAYMENT_REQUIRED
            )
        return Response(PublishedGuideSerializer(published_guide).data)

    @action(detail=True, methods=["post"])
    def report(self, request, pk=None):
        paper = self.get_object()
        serializer = PaperFlagSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            paper_flag = report_paper(
                user=request.user,
                paper_submission=paper,
                reason=serializer.validated_data["reason"],
                details=serializer.validated_data.get("details", ""),
            )
        except AlreadyFlaggedError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_409_CONFLICT)
        return Response(PaperFlagSerializer(paper_flag).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def process_ocr(self, request, pk=None):
        paper = self.get_object()
        processed = process_ocr_and_duplicate_check(paper)
        return Response(PaperSubmissionDetailSerializer(processed).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def mark_published(self, request, pk=None):
        paper = mark_published(self.get_object())
        return Response(PaperSubmissionDetailSerializer(paper).data)

    @action(detail=True, methods=["post"])
    def dismiss(self, request, pk=None):
        # Same auth bar as `report` — a real account, guests excluded (class
        # default IsAuthenticatedNotGuest, no override needed here). The
        # explicit ownership check matters specifically for staff: their
        # get_queryset is unfiltered (every submission, any status), so
        # without this a staff member could clear a rejection out of a
        # *contributor's own* list on their behalf — this is deliberately
        # something only the contributor themselves does.
        paper = self.get_object()
        if paper.submitted_by_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        if paper.status != PaperStatus.REJECTED:
            return Response(
                {"detail": "Only a rejected submission can be dismissed."}, status=status.HTTP_400_BAD_REQUEST
            )
        paper.dismissed_by_contributor = True
        paper.save(update_fields=["dismissed_by_contributor", "updated_at"])
        return Response(PaperSubmissionDetailSerializer(paper, context={"request": request}).data)


class AdWatchView(APIView):
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=None, responses=AdWatchEventSerializer)
    def post(self, request):
        event = record_ad_watch(user=request.user)
        return Response(AdWatchEventSerializer(event).data, status=status.HTTP_201_CREATED)
