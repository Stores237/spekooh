"""
Lane B only — the real-time student chatbot (see apps.ai.views.PaperChatView).
Unlike
GeminiProvider's batch summaries (cron-driven, a queued row is fine to
retry later), a chat reply has to come back inside the same HTTP request
the student is waiting on — there's no queue to just stop draining if
something's wrong, hence the separate AI_CHAT_ENABLED kill switch and
GROQ_DAILY_BUDGET cap in settings.

Groq's own OpenAI-compatible REST endpoint, same raw-`requests` convention
as GeminiProvider (see that module's own docstring for why).
"""

import json

import requests
from django.conf import settings

from .base import (
    AIError,
    AIRateLimited,
    AIRefused,
    AIResult,
    AIUnavailable,
    BaseProvider,
)

BASE_URL = "https://api.groq.com/openai/v1/chat/completions"


class GroqProvider(BaseProvider):
    name = "groq"

    def __init__(self, model: str | None = None):
        self.model = model or settings.AI_MODELS["groq_chat"]
        self.key = settings.GROQ_API_KEY

    def chat(self, *, system: str, messages: list[dict], max_tokens: int = 600, temperature: float = 0.4) -> AIResult:
        if not self.key:
            # Same no-op-safely-when-unconfigured posture as
            # GeminiProvider's own GEMINI_API_KEY check.
            raise AIUnavailable("GROQ_API_KEY is not configured")
        body = {
            "model": self.model,
            "messages": [{"role": "system", "content": system}, *messages],
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        try:
            response = requests.post(
                BASE_URL,
                headers={"Authorization": f"Bearer {self.key}", "Content-Type": "application/json"},
                json=body,
                # Short, deliberately — a live request a student is
                # waiting on, not a cron job with all day to retry.
                # Groq's own inference is fast enough that this is
                # generous, not tight.
                timeout=30,
            )
        except requests.RequestException as exc:
            raise AIUnavailable(str(exc)) from exc
        if response.status_code == 429:
            raise AIRateLimited("groq 429")
        if response.status_code >= 500:
            raise AIUnavailable(f"groq {response.status_code}")
        if response.status_code >= 400:
            raise AIError(f"groq {response.status_code}: {response.text[:500]}")
        return self._extract(response.json())

    def chat_stream(self, *, system: str, messages: list[dict], max_tokens: int = 600, temperature: float = 0.4) -> requests.Response:
        """Streaming counterpart to chat() (2026-09-08 — real streaming for
        Lane B, see apps.ai.views.PaperChatView's own note on why). Deliberately
        split from iter_stream_deltas() below: this method does the actual
        POST with stream=True and validates the initial response synchronously
        — same status-code checks as chat(), raising the same exceptions —
        so a 429/5xx/network failure surfaces to the caller (services
        .stream_chat_message) BEFORE the view has written a single byte to
        its own client and can still just return a normal HTTP error
        response, exactly like the non-streaming path does. Only a failure
        that happens once Groq's stream is already flowing (rare — the
        handshake already succeeded) is the view's problem to fold into an
        in-band SSE frame instead, via iter_stream_deltas() raising mid-loop.
        """
        if not self.key:
            raise AIUnavailable("GROQ_API_KEY is not configured")
        body = {
            "model": self.model,
            "messages": [{"role": "system", "content": system}, *messages],
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": True,
        }
        try:
            response = requests.post(
                BASE_URL,
                headers={"Authorization": f"Bearer {self.key}", "Content-Type": "application/json"},
                json=body,
                stream=True,
                timeout=30,
            )
        except requests.RequestException as exc:
            raise AIUnavailable(str(exc)) from exc
        if response.status_code == 429:
            response.close()
            raise AIRateLimited("groq 429")
        if response.status_code >= 500:
            response.close()
            raise AIUnavailable(f"groq {response.status_code}")
        if response.status_code >= 400:
            detail = response.text[:500]
            response.close()
            raise AIError(f"groq {response.status_code}: {detail}")
        return response

    @staticmethod
    def iter_stream_deltas(response: requests.Response):
        """Yields text deltas parsed from an already-validated streaming
        Groq response (see chat_stream() above) — Groq's own
        OpenAI-compatible SSE framing (`data: {...}\\n\\n`, terminated by a
        literal `data: [DONE]`). Raises AIRefused if Groq's own
        finish_reason says its content filter tripped mid-stream (chat()'s
        non-streaming twin only ever sees this in the one final message, so
        it can check it once; here it can show up on any chunk). Any
        exception raised here happens DURING iteration, after the view has
        already started writing SSE bytes to its own client — the caller
        (apps.ai.views.PaperChatView) is responsible for folding it into an
        in-band error frame rather than an HTTP status code."""
        try:
            for line in response.iter_lines(decode_unicode=True):
                if not line or not line.startswith("data: "):
                    continue
                payload = line[len("data: "):]
                if payload == "[DONE]":
                    return
                chunk = json.loads(payload)
                choices = chunk.get("choices") or []
                if not choices:
                    continue
                choice = choices[0]
                if choice.get("finish_reason") == "content_filter":
                    raise AIRefused("content filter")
                delta = (choice.get("delta") or {}).get("content")
                if delta:
                    yield delta
        except requests.RequestException as exc:
            raise AIUnavailable(str(exc)) from exc
        finally:
            response.close()

    @staticmethod
    def _extract(data: dict) -> AIResult:
        choices = data.get("choices") or []
        if not choices:
            raise AIRefused("no choices returned")
        choice = choices[0]
        if choice.get("finish_reason") == "content_filter":
            raise AIRefused("content filter")
        content = (choice.get("message") or {}).get("content", "").strip()
        if not content:
            raise AIRefused("empty response")
        usage = data.get("usage", {})
        return AIResult(
            text=content,
            model=data.get("model", ""),
            tokens_in=usage.get("prompt_tokens", 0),
            tokens_out=usage.get("completion_tokens", 0),
        )
