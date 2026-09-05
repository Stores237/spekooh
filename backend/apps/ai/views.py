from django.conf import settings
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.papers.models import PaperStatus, PaperSubmission
from apps.papers.services import user_can_view_file
from apps.payments.models import Subscription

from .models import ArtifactKind
from .providers.base import AIError, AIRateLimited, AIRefused
from .quota import consume_chat_quota, consume_provider_budget
from .services import get_or_queue_artifact, send_chat_message, validate_chat_messages


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


class PaperChatView(APIView):
    """
    Lane B — the real-time Groq student chatbot. Real accounts only
    (IsAuthenticated, unlike PaperSummaryView's AllowAny): this endpoint
    costs real money per message and needs a stable identity to enforce a
    meaningful daily quota against (apps.ai.quota.consume_chat_quota) — a
    guest's token is minted fresh essentially per session elsewhere in this
    codebase, which would make a "daily" cap meaningless. Requiring an
    account also lines up naturally with the upgrade-to-Pro path once the
    free quota's used up.

    Stateless: the client resends its own running conversation (`messages`)
    on every call — see services.validate_chat_messages/send_chat_message's
    own docstrings for why nothing is persisted server-side.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        if not settings.AI_ENABLED or not settings.AI_CHAT_ENABLED:
            return Response({"detail": "AI chat is currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        user = request.user
        visible = Q(status=PaperStatus.PUBLISHED) | Q(submitted_by=user)
        paper = get_object_or_404(PaperSubmission.objects.filter(visible), pk=pk)

        if not user_can_view_file(user, paper):
            return Response({"detail": "Payment required to view this paper."}, status=status.HTTP_402_PAYMENT_REQUIRED)

        if not paper.ocr_text:
            return Response({"detail": "This paper has no extracted text to chat about yet."}, status=status.HTTP_409_CONFLICT)

        error = validate_chat_messages(request.data.get("messages"))
        if error:
            return Response({"detail": error}, status=status.HTTP_400_BAD_REQUEST)

        # Owner decision (resolved via AskUserQuestion): free for everyone
        # with a daily per-user quota, then an upgrade prompt — a Pro
        # subscriber skips this cap entirely, same "give Pro real value"
        # reasoning already covering ad-free + unlimited paper views.
        is_pro = Subscription.objects.has_active(user)
        quota_remaining = None
        if not is_pro:
            allowed, remaining = consume_chat_quota(str(user.pk), settings.AI_CHAT_DAILY_LIMIT)
            if not allowed:
                return Response(
                    {"detail": "You've used today's free chat messages. Upgrade to Kawlo Plus for unlimited chat.", "upgrade_required": True},
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )
            quota_remaining = remaining

        # A hard, provider-wide ceiling even a Pro subscriber's
        # unlimited-seeming chat is still subject to — defense in depth
        # against a runaway bug or abuse, same reasoning as
        # GEMINI_DAILY_BUDGET for Lane A.
        if not consume_provider_budget("groq", settings.GROQ_DAILY_BUDGET):
            return Response({"detail": "AI chat is temporarily unavailable — try again shortly."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            result = send_chat_message(paper=paper, messages=request.data["messages"])
        except AIRefused:
            return Response({"role": "assistant", "content": "I can't help with that — let's stick to this paper.", "quota_remaining": quota_remaining})
        except AIRateLimited:
            return Response({"detail": "AI chat is busy right now — try again in a moment."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except AIError:
            return Response({"detail": "AI chat is currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        return Response({"role": "assistant", "content": result.text, "quota_remaining": quota_remaining})
