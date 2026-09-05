from django.conf import settings
from django.contrib.contenttypes.models import ContentType

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag

from .models import ArtifactKind, ArtifactStatus, GeneratedArtifact
from .prompts import chat as chat_prompts
from .prompts import summarise
from .providers.base import AIError, AIResult, AIUnavailable
from .providers.gemini import GeminiProvider
from .providers.groq import GroqProvider


def get_or_queue_artifact(source, kind: str, language: str = "en") -> tuple[GeneratedArtifact, bool]:
    """
    Returns (artifact, is_ready). Never blocks, and never calls a provider
    itself — generation happens out of band, the next time
    generate_pending_artifacts runs (cron-driven, see that command's own
    docstring for why this isn't a Celery .delay() call). A student's very
    first request for a not-yet-generated artifact gets a PENDING row and
    should poll; once pre-warming (a real, deliberately deferred Phase 2+
    piece — see apps/ai/models.py) exists, this will almost always find a
    READY row already waiting instead.
    """
    content_type = ContentType.objects.get_for_model(source)
    artifact, _ = GeneratedArtifact.objects.get_or_create(
        content_type=content_type,
        object_id=str(source.pk),
        kind=kind,
        language=language,
        prompt_version=settings.AI_PROMPT_VERSION,
    )
    return artifact, artifact.status == ArtifactStatus.READY


def generate_paper_summary(artifact: GeneratedArtifact) -> None:
    """
    Mutates and saves `artifact` in place. Raises an AIError subclass on
    failure — generate_pending_artifacts is what actually catches those
    and marks the row FAILED; this function's only job is the real work.
    """
    paper = artifact.source
    if not paper.ocr_text:
        # A brand-new submission whose OCR step hasn't landed yet, or a
        # genuinely un-OCR'able file (see apps.papers.ocr) — not the
        # provider's fault, so this doesn't count against the daily
        # Gemini budget the way a real API failure would.
        raise AIUnavailable("no OCR text yet for this submission")

    text = paper.ocr_text[:60_000]  # a real, generous cap — Gemini's own context window is 1M tokens, this just guards against a pathological OCR dump
    artifact.source_hash = GeneratedArtifact.hash_source(text)
    result = GeminiProvider().generate(
        system=summarise.SYSTEM[artifact.language],
        user=summarise.PAPER_SUMMARY[artifact.language].format(ocr_text=text),
    )
    artifact.body = result.text
    artifact.model_used = result.model
    artifact.tokens_in = result.tokens_in
    artifact.tokens_out = result.tokens_out


# One entry per real ArtifactKind — generate_pending_artifacts dispatches
# through this rather than an if/elif chain, so adding a new kind (quiz,
# translation) is a one-line addition here plus a new prompt module.
GENERATORS = {
    ArtifactKind.SUMMARY: generate_paper_summary,
}


def run_pending_generation(artifact: GeneratedArtifact) -> None:
    """
    The one place that turns a PENDING/FAILED row into READY/FAILED —
    shared by the real management command and its own tests, so a test
    exercises the exact code path a real cron trigger does.
    """
    artifact.status = ArtifactStatus.RUNNING
    artifact.attempts += 1
    artifact.save(update_fields=["status", "attempts"])
    try:
        GENERATORS[artifact.kind](artifact)
    except AIError as exc:
        artifact.status = ArtifactStatus.FAILED
        artifact.error = str(exc)[:2000]
        artifact.save(update_fields=["status", "error"])
        if artifact.attempts >= 3:
            flag(
                subject=artifact.source,
                category=FlagCategory.OTHER,
                reason=f"AI {artifact.get_kind_display()} generation failed after {artifact.attempts} attempts: {artifact.error}",
            )
        raise
    else:
        artifact.status = ArtifactStatus.READY
        artifact.error = ""
        artifact.save()


# --- Lane B: the real-time student chatbot (apps.ai.views.PaperChatView) ---
# Stateless by design (a deliberate, deferred simplification — see the
# resolved AskUserQuestion on chat scope): the client resends its own
# running conversation on every call, so there is no ChatMessage model, no
# migration, and nothing about a student's conversation is ever persisted
# server-side.

CHAT_MAX_MESSAGES = 12
CHAT_MAX_CHARS = 4000


def validate_chat_messages(messages) -> str | None:
    """Returns a human-readable error, or None if `messages` (the client's
    own running conversation, oldest first) is well-formed and safe to
    forward to Groq. Deliberately hand-rolled rather than a DRF serializer
    — this is a list of free-form dicts, not a model-backed shape."""
    if not isinstance(messages, list) or not messages:
        return "messages must be a non-empty list."
    if len(messages) > CHAT_MAX_MESSAGES:
        return f"Send at most {CHAT_MAX_MESSAGES} messages of conversation history."
    total_chars = 0
    for message in messages:
        if not isinstance(message, dict) or message.get("role") not in ("user", "assistant"):
            return "Each message needs a role of 'user' or 'assistant'."
        content = message.get("content")
        if not isinstance(content, str) or not content.strip():
            return "Each message needs non-empty string content."
        total_chars += len(content)
    if total_chars > CHAT_MAX_CHARS:
        return "That's too much text for one request."
    if messages[-1]["role"] != "user":
        return "The last message must be from the student."
    return None


def send_chat_message(*, paper, messages: list[dict]) -> AIResult:
    """The one Groq call. Raises an AIError subclass on failure — the view
    is what turns that into a real HTTP response, same split as Lane A's
    generate_paper_summary/run_pending_generation."""
    text = paper.ocr_text[:60_000]  # same generous, pathological-OCR-dump guard as generate_paper_summary
    system = chat_prompts.SYSTEM_CHAT["en"].format(ocr_text=text)
    return GroqProvider().chat(system=system, messages=messages)
