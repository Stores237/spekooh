"""
A daily provider-side spend cap, backed by CACHES["default"] — the same
Redis this project already runs for DRF's ScopedRateThrottle (see
config/settings/base.py's own comment on that). Deliberately separate
from Django's / DRF's own per-minute throttling: a free-tier daily request
cap (Gemini) needs a day-scoped counter, which DRF's throttle classes
don't provide on their own.
"""

from datetime import datetime
from zoneinfo import ZoneInfo

from django.core.cache import cache

CAMEROON_TZ = ZoneInfo("Africa/Douala")


def _day_key(prefix: str) -> str:
    today = datetime.now(CAMEROON_TZ).strftime("%Y%m%d")
    return f"{prefix}:{today}"


def _consume(key: str, limit: int) -> tuple[bool, int]:
    """Shared by consume_provider_budget and consume_chat_quota below.
    Returns (allowed, remaining-after-this-call)."""
    # One day plus a small margin, so a key created right at midnight
    # doesn't expire a few seconds early and silently reset the count.
    used = cache.get_or_set(key, 0, timeout=90_000)
    if used >= limit:
        return False, 0
    try:
        cache.incr(key)
    except ValueError:
        # incr() on an already-expired key raises rather than treating it
        # as zero — reseed it explicitly instead of failing the request.
        cache.set(key, 1, timeout=90_000)
    return True, limit - used - 1


def consume_provider_budget(provider: str, limit: int) -> bool:
    """Returns False once today's budget for `provider` is used up. A
    real day boundary (Africa/Douala, not UTC) — the daily reset should
    line up with when Cameroonian students are actually asleep, not an
    arbitrary UTC midnight."""
    allowed, _ = _consume(_day_key(f"aibudget:{provider}"), limit)
    return allowed


def consume_chat_quota(identity: str, limit: int) -> tuple[bool, int]:
    """Per-user daily Lane B chat message cap (apps.ai.chat) — [identity]
    is a real User's str(pk); chat requires a real account, see
    apps.ai.chat.views's own doc comment for why. Returns
    (allowed, remaining-after-this-message) so the response can tell the
    student how many free messages are left today."""
    return _consume(_day_key(f"aichat:{identity}"), limit)
