"""
Lane A only — batch generation against Spekooh's own content (never
student-typed text, see apps/ai/prompts/summarise.py's own note on this).
Uses Gemini's raw REST endpoint rather than the google-genai SDK: one
fewer dependency, and this project's own convention (see
apps.papers.services.presign_paper_upload) already reaches for `requests`
directly over adding an SDK for a single HTTP call shape.

Phase 1 sends plain extracted text (PaperSubmission.ocr_text), not the raw
PDF — the OCR pipeline already exists and already runs at submission time
(apps.papers.services), so there's no need to re-fetch and re-send the
original file bytes just to summarize what's already been extracted.
Sending the PDF itself (for a scan OCR missed something in) is a real,
deferred Phase 2+ option — genuinely a cost/quality tradeoff to make
deliberately, not an oversight.
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

BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"


class GeminiProvider(BaseProvider):
    name = "gemini"

    def __init__(self, model: str | None = None):
        self.model = model or settings.AI_MODELS["gemini_primary"]
        self.key = settings.GEMINI_API_KEY

    def _post(self, body: dict, timeout: int) -> dict:
        if not self.key:
            # Same no-op-safely-when-unconfigured posture as SENTRY_DSN/
            # REDIS_URL/AWS_* elsewhere in this codebase — a fresh clone
            # with no GEMINI_API_KEY set shouldn't crash with a confusing
            # HTTP error, it should fail in an obviously-configuration
            # shaped way.
            raise AIUnavailable("GEMINI_API_KEY is not configured")
        url = f"{BASE_URL}/{self.model}:generateContent"
        try:
            response = requests.post(
                url,
                headers={"x-goog-api-key": self.key, "Content-Type": "application/json"},
                json=body,
                timeout=timeout,
            )
        except requests.RequestException as exc:
            raise AIUnavailable(str(exc)) from exc
        if response.status_code == 429:
            raise AIRateLimited("gemini 429")
        if response.status_code >= 500:
            raise AIUnavailable(f"gemini {response.status_code}")
        if response.status_code >= 400:
            raise AIError(f"gemini {response.status_code}: {response.text[:500]}")
        return response.json()

    @staticmethod
    def _extract(data: dict) -> AIResult:
        candidates = data.get("candidates") or []
        if not candidates:
            raise AIRefused("no candidates returned")
        candidate = candidates[0]
        if candidate.get("finishReason") == "SAFETY":
            raise AIRefused("safety block")
        parts = candidate.get("content", {}).get("parts", [])
        text = "".join(part.get("text", "") for part in parts).strip()
        if not text:
            raise AIRefused("empty response")
        usage = data.get("usageMetadata", {})
        return AIResult(
            text=text,
            model=data.get("modelVersion", ""),
            tokens_in=usage.get("promptTokenCount", 0),
            tokens_out=usage.get("candidatesTokenCount", 0),
        )

    def generate(self, *, system: str, user: str, max_tokens: int = 2048, temperature: float = 0.3) -> AIResult:
        body = {
            "systemInstruction": {"parts": [{"text": system}]},
            "contents": [{"role": "user", "parts": [{"text": user}]}],
            "generationConfig": {"temperature": temperature, "maxOutputTokens": max_tokens},
        }
        return self._extract(self._post(body, timeout=120))
