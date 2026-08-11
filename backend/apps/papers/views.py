from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AdWatchEvent, ExamCategory, ExamType, PaperStatus, PaperSubmission, Subject
from .serializers import (
    AdWatchEventSerializer,
    ExamCategorySerializer,
    ExamTypeSerializer,
    PaperSubmissionCreateSerializer,
    PaperSubmissionDetailSerializer,
    PaperSubmissionListSerializer,
    PaperViewLogSerializer,
    SubjectSerializer,
)
from .services import PaywallError, process_ocr_and_duplicate_check, record_ad_watch, record_paper_view


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
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ["status", "category", "exam_type", "subject", "submitted_by"]
    ordering_fields = ["created_at", "year"]

    def get_queryset(self):
        return PaperSubmission.objects.select_related("category", "exam_type", "subject").all()

    def get_serializer_class(self):
        if self.action == "create":
            return PaperSubmissionCreateSerializer
        if self.action == "list":
            return PaperSubmissionListSerializer
        return PaperSubmissionDetailSerializer

    @action(detail=True, methods=["post"])
    def view(self, request, pk=None):
        paper = self.get_object()
        try:
            log = record_paper_view(user=request.user, paper_submission=paper)
        except PaywallError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(PaperViewLogSerializer(log).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def process_ocr(self, request, pk=None):
        paper = self.get_object()
        processed = process_ocr_and_duplicate_check(paper)
        return Response(PaperSubmissionDetailSerializer(processed).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def mark_published(self, request, pk=None):
        """
        Ops-triggered for now — the full instructor-accept -> marking-guide
        -> merge pipeline (stage 8) will call award_contributor_bonus from
        this same transition instead of duplicating the logic.
        """
        from apps.credits.services import award_contributor_bonus

        paper = self.get_object()
        paper.status = PaperStatus.PUBLISHED
        paper.save(update_fields=["status", "updated_at"])
        award_contributor_bonus(paper)
        return Response(PaperSubmissionDetailSerializer(paper).data)


class AdWatchView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(request=None, responses=AdWatchEventSerializer)
    def post(self, request):
        event = record_ad_watch(user=request.user)
        return Response(AdWatchEventSerializer(event).data, status=status.HTTP_201_CREATED)
