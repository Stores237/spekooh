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
    SubjectSerializer,
)
from .services import (
    AlreadyFlaggedError,
    PaywallError,
    mark_published,
    process_ocr_and_duplicate_check,
    record_ad_watch,
    record_paper_view,
    report_paper,
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


class SubjectViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["language"]


class PaperSubmissionViewSet(
    mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet
):
    # Reading (browsing published papers) stays open to guests, per spec
    # ("guest browsing allowed... account required only for streaks/XP,
    # forum posting, ... not for reading"). Only creating/viewing/unlocking
    # requires auth. process_ocr/mark_published set their own IsAdminUser
    # via @action(permission_classes=...) — defer to super() there instead
    # of hardcoding, or those per-action overrides get silently clobbered.
    # `create` is the one exception where a guest account is welcome
    # (see get_permissions) — everything else, including `report`, falls
    # through to this class-level IsAuthenticatedNotGuest.
    permission_classes = [IsAuthenticatedNotGuest]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ["status", "category", "exam_type", "subject", "system", "track", "submitted_by"]
    ordering_fields = ["created_at", "year"]

    def get_permissions(self):
        if self.action in ("list", "retrieve", "view"):
            return [permissions.AllowAny()]
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
        # Guests (per spec: reading stays open to guests) see published only.
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

    @action(detail=True, methods=["post"])
    def view(self, request, pk=None):
        paper = self.get_object()
        if not request.user.is_authenticated:
            # Reading stays open to guests (spec) — there's no identity to
            # rate-limit an anonymous viewer against, so guests are simply
            # never subject to the daily-view paywall; only signed-in
            # accounts are. Previously this fell through to the class's
            # default IsAuthenticated and 401'd on every guest view (the
            # client silently swallows the failure, so guests already got
            # unlimited views in practice — this makes that real instead of
            # accidental, and drops the bogus error from the console).
            return Response(status=status.HTTP_204_NO_CONTENT)
        try:
            log = record_paper_view(user=request.user, paper_submission=paper)
        except PaywallError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(PaperViewLogSerializer(log).data, status=status.HTTP_201_CREATED)

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
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)
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


class AdWatchView(APIView):
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=None, responses=AdWatchEventSerializer)
    def post(self, request):
        event = record_ad_watch(user=request.user)
        return Response(AdWatchEventSerializer(event).data, status=status.HTTP_201_CREATED)
