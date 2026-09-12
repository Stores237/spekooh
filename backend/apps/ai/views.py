import json
import logging

from django.conf import settings
from django.db.models import Q
from django.http import StreamingHttpResponse
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.renderers import BaseRenderer
from rest_framework.response import Response
from rest_framework.settings import api_settings
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest
from apps.papers.models import PaperStatus, PaperSubmission
from apps.papers.services import user_can_view_file
from apps.payments.models import Subscription

from .models import ArtifactKind
from .providers.base import AIError, AIRateLimited, AIRefused
from .quota import consume_chat_quota, consume_provider_budget
from .services import (
    get_or_queue_artifact,
    send_chat_message,
    stream_chat_message,
    validate_chat_messages,
)

# Shared between PaperChatView's non-streaming and streaming paths so a
# safety-filter refusal reads identically either way.
CHAT_REFUSAL_MESSAGE = "I can't help with that. Let's stick to this paper."

# Real gap found 2026-09-12 while diagnosing a live "AI chat is currently
# unavailable" report on staging: every AIError branch below (and in
# PaperSummaryView) only ever turned into a clean client-facing Response —
# nothing was ever logged server-side, so a real provider failure (wrong/
# missing key, a genuine Groq/Gemini outage, a bad model name) was
# indistinguishable from any other cause without direct DB/shell access,
# which the free Render tier doesn't even have. logger.warning here still
# reaches Render's log stream with zero LOGGING config needed — Python's
# root logger prints WARNING+ via its own last-resort handler when nothing
# else is configured.
logger = logging.getLogger(__name__)


class ServerSentEventRenderer(BaseRenderer):
    """Exists purely so DRF's own content negotiation (APIView.initial()
    calls this before post() ever runs) accepts `Accept: text/event-stream`
    instead of rejecting it with a 406 — found live while writing this
    view's own tests, not something the docs warn you about. render() is
    never actually called: PaperChatView's streaming branch returns a raw
    StreamingHttpResponse, which bypasses DRF's render step entirely
    (APIView.finalize_response only renders real rest_framework.Response
    instances). Registered as an extra renderer_class below, alongside the
    project's normal defaults, so the non-streaming JSON path is untouched."""

    media_type = "text/event-stream"
    format = "sse"

    def render(self, data, accepted_media_type=None, renderer_context=None):
        return data


def _sse_chat_stream(deltas, quota_remaining):
    """Wraps a GroqProvider.iter_stream_deltas() generator as Server-Sent
    Events. Real edge case this exists for (2026-09-08, see the streaming
    architecture decision): once PaperChatView has returned this generator
    inside a StreamingHttpResponse, the HTTP status code is already
    committed at 200 — a failure from here on (Groq's content filter
    tripping mid-reply, a dropped connection, a rare post-handshake error)
    can no longer become an HTTP error response, so it has to become an
    in-band frame the client checks for instead. Each event is one JSON
    object: {"delta": str} while text is arriving, then exactly one final
    {"done": true, "quota_remaining": int|null} on success, or
    {"error": true, "code": str, "detail": str} in place of that final
    frame on failure."""
    try:
        for delta in deltas:
            yield f"data: {json.dumps({'delta': delta})}\n\n"
    except AIRefused:
        yield f"data: {json.dumps({'delta': CHAT_REFUSAL_MESSAGE})}\n\n"
    except AIRateLimited as exc:
        logger.warning("_sse_chat_stream: rate limited mid-stream: %s", exc)
        yield f"data: {json.dumps({'error': True, 'code': 'rate_limited', 'detail': 'AI chat is busy right now. Try again in a moment.'})}\n\n"
        return
    except AIError as exc:
        logger.warning("_sse_chat_stream: %s", exc)
        yield f"data: {json.dumps({'error': True, 'code': 'unavailable', 'detail': 'AI chat is currently unavailable.'})}\n\n"
        return
    yield f"data: {json.dumps({'done': True, 'quota_remaining': quota_remaining})}\n\n"


class PaperSummaryView(APIView):
    """
    IsAuthenticatedNotGuest at the permission-class level (2026-09-06,
    supersedes this class's own earlier AllowAny) — mirrors
    PaperSubmissionViewSet's own retrieve/list/view actions on the backend,
    which now require the same real, non-guest account to even view a
    paper at all; an AI summary of a paper you can't view otherwise would
    be an inconsistent loophole. The actual content gate underneath that
    is the same two real checks that endpoint already applies: is this
    paper even visible to this caller (published, or their own), and does
    viewing its file require a payment this caller hasn't made
    (apps.papers.services.user_can_view_file) — an AI summary of a
    paid/private paper would otherwise be a free way around the paywall
    that generates the file itself.
    """

    permission_classes = [IsAuthenticatedNotGuest]

    def get(self, request, pk):
        if not settings.AI_ENABLED:
            return Response({"detail": "AI features are currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        user = request.user
        visible = Q(status=PaperStatus.PUBLISHED) | Q(submitted_by=user)
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
    (IsAuthenticatedNotGuest — fixed 2026-09-06; this used to say
    "IsAuthenticated" here and mean it, but was actually still built with
    plain IsAuthenticated, which a guest JWT satisfies too): this endpoint
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

    permission_classes = [IsAuthenticatedNotGuest]
    renderer_classes = [*api_settings.DEFAULT_RENDERER_CLASSES, ServerSentEventRenderer]

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
            return Response({"detail": "AI chat is temporarily unavailable. Try again shortly."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        # Content negotiation, not a separate endpoint (2026-09-08, real
        # streaming for Lane B) — reuses every gate above (permissions,
        # paywall, OCR-readiness, quota, provider budget) instead of
        # duplicating them behind a second URL. `Accept: text/event-stream`
        # opts into progressive delta frames (see _sse_chat_stream's own
        # docstring); anything else keeps today's exact buffered response,
        # unchanged, for callers that haven't adopted streaming yet.
        if request.META.get("HTTP_ACCEPT") == "text/event-stream":
            # AIRefused deliberately isn't caught here — GroqProvider
            # .iter_stream_deltas() only ever raises it lazily, once
            # something actually iterates the generator this returns
            # (content-filter detection happens per-chunk, not on the
            # initial handshake) — so it always surfaces inside
            # _sse_chat_stream's own try/except below, never here.
            try:
                deltas = stream_chat_message(paper=paper, messages=request.data["messages"])
            except AIRateLimited as exc:
                logger.warning("PaperChatView (paper %s, streaming): rate limited: %s", pk, exc)
                return Response({"detail": "AI chat is busy right now. Try again in a moment."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            except AIError as exc:
                logger.warning("PaperChatView (paper %s, streaming): %s", pk, exc)
                return Response({"detail": "AI chat is currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

            return StreamingHttpResponse(_sse_chat_stream(deltas, quota_remaining), content_type="text/event-stream")

        try:
            result = send_chat_message(paper=paper, messages=request.data["messages"])
        except AIRefused:
            return Response({"role": "assistant", "content": CHAT_REFUSAL_MESSAGE, "quota_remaining": quota_remaining})
        except AIRateLimited as exc:
            logger.warning("PaperChatView (paper %s): rate limited: %s", pk, exc)
            return Response({"detail": "AI chat is busy right now. Try again in a moment."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except AIError as exc:
            logger.warning("PaperChatView (paper %s): %s", pk, exc)
            return Response({"detail": "AI chat is currently unavailable."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        return Response({"role": "assistant", "content": result.text, "quota_remaining": quota_remaining})
