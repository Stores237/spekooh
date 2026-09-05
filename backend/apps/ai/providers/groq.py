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
