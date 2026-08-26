import pytest
from django.core.cache import cache


@pytest.fixture(autouse=True)
def _clear_cache():
    """CACHES now points at real Redis (see config/settings/base.py), not
    an in-memory per-process cache — its state survives across test runs,
    unlike the DB (which pytest-django rolls back per test). Without this,
    DRF's guest-mint throttle (backed by this same cache) would accumulate
    hits across repeated local test runs and eventually 429 a test that
    has nothing to do with rate limiting."""
    cache.clear()
    yield
