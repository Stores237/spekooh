from django.conf import settings
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.papers.models import PaperStatus, PaperSubmission
from apps.papers.services import user_can_view_file

from .models import ArtifactKind
from .services import get_or_queue_artifact


class PaperSummaryView(APIView):
    """
    AllowAny at the permission-class level, same as PaperSubmissionViewSet's
    own retrieve/list/view actions (apps.papers.views) — guest browsing is
    real, spec'd behavior, not an oversight. The actual gate is the same
    two real checks that endpoint already applies: is this paper even
    visible to this caller (published, or their own), and does viewing its
    file require a payment this caller hasn't made
    (apps.papers.services.user_can_view_file) — an AI summary of a
    paid/private paper would otherwise be a free way around the paywall
    that generates the file itself.
    """

    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        if not settings.AI_ENABLED:
            return Response({"detail": "AI features are currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        user = request.user
        visible = Q(status=PaperStatus.PUBLISHED)
        if user.is_authenticated:
            visible |= Q(submitted_by=user)
        paper = get_object_or_404(PaperSubmission.objects.filter(visible), pk=pk)

        if not user_can_view_file(user, paper):
            return Response({"detail": "Payment required to view this paper."}, status=status.HTTP_402_PAYMENT_REQUIRED)

        artifact, is_ready = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        if not is_ready:
            return Response({"status": artifact.status, "retry_after": 15}, status=status.HTTP_202_ACCEPTED)

        return Response({"status": "ready", "body": artifact.body})
