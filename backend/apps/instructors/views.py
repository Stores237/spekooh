from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.papers.models import PaperSubmission
from apps.papers.serializers import PaperSubmissionDetailSerializer

from .models import InstructorRequest
from .serializers import (
    InstructorRequestSerializer,
    InstructorResponseWebhookSerializer,
    InstructorWebhookEnvelopeSerializer,
    MarkingGuideSubmissionWebhookSerializer,
)
from .services import (
    MergeError,
    RoutingError,
    handle_instructor_response,
    handle_marking_guide_submission,
    merge_and_publish,
    route_next_instructor,
)
from .webhook import WebhookError, verify_webhook_request


class InstructorRequestViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.IsAdminUser]
    queryset = InstructorRequest.objects.all()
    serializer_class = InstructorRequestSerializer


class RouteToInstructorView(APIView):
    """Ops-triggered: kick off (or advance) instructor routing for a paper ready for marking."""

    permission_classes = [permissions.IsAdminUser]

    @extend_schema(request=None, responses=InstructorRequestSerializer)
    def post(self, request, paper_id):
        try:
            paper = PaperSubmission.objects.get(id=paper_id)
        except PaperSubmission.DoesNotExist:
            return Response({"detail": "Paper not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            instructor_request = route_next_instructor(paper)
        except RoutingError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        if instructor_request is None:
            return Response({"detail": "No instructor available; flagged for admin review."}, status=status.HTTP_200_OK)
        return Response(InstructorRequestSerializer(instructor_request).data, status=status.HTTP_201_CREATED)


class MergeAndPublishView(APIView):
    permission_classes = [permissions.IsAdminUser]

    @extend_schema(request=None, responses=PaperSubmissionDetailSerializer)
    def post(self, request, paper_id):
        try:
            paper = PaperSubmission.objects.get(id=paper_id)
        except PaperSubmission.DoesNotExist:
            return Response({"detail": "Paper not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            merge_and_publish(paper)
        except MergeError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        paper.refresh_from_db()
        return Response(PaperSubmissionDetailSerializer(paper).data)


class InstructorWebhookView(APIView):
    """
    HMAC-signed, replay-protected — see apps.instructors.webhook. Not backed
    by JWT auth (the instructor platform is a genuine external third party,
    per spec's "golden rule"); AllowAny + signature verification instead.
    """

    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    @extend_schema(request=InstructorWebhookEnvelopeSerializer, responses=None)
    def post(self, request):
        try:
            verify_webhook_request(
                partner_id=request.headers.get("X-Spekooh-Partner-Id", ""),
                raw_body=request.body,
                signature_header=request.headers.get("X-Spekooh-Signature", ""),
                timestamp_header=request.headers.get("X-Spekooh-Timestamp", ""),
            )
        except WebhookError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)

        envelope = InstructorWebhookEnvelopeSerializer(data=request.data)
        envelope.is_valid(raise_exception=True)
        event_type = envelope.validated_data["event_type"]

        if event_type == "instructor_response":
            payload = InstructorResponseWebhookSerializer(data=request.data)
            payload.is_valid(raise_exception=True)
            result = handle_instructor_response(**payload.validated_data)
            return Response({"applied": result.applied, "detail": result.detail}, status=status.HTTP_200_OK)

        payload = MarkingGuideSubmissionWebhookSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        try:
            handle_marking_guide_submission(
                instructor_request_id=payload.validated_data["instructor_request_id"],
                content=payload.validated_data["content"],
            )
        except RoutingError as exc:
            return Response({"applied": False, "detail": str(exc)}, status=status.HTTP_200_OK)
        return Response({"applied": True}, status=status.HTTP_200_OK)
