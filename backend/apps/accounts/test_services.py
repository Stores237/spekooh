"""apps.accounts.services — the Supabase Edge Function integration.

Mocks requests.post throughout: this must never make a real network call in
CI, and the real deployed function (supabase/functions/verify-email-domain)
was already verified live and separately during development (curl against
the actual deployed URL — real gmail.com -> valid, a typo'd domain and a
malformed address -> invalid, missing shared secret -> 401).
"""

import requests

from .services import email_domain_is_verifiable


def test_returns_true_when_edge_function_not_configured(settings):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = None
    assert email_domain_is_verifiable("anyone@example.com") is True


def test_returns_true_when_edge_function_says_valid(settings, monkeypatch):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"valid": True}

    monkeypatch.setattr(requests, "post", lambda *a, **k: FakeResponse())
    assert email_domain_is_verifiable("real@gmail.com") is True


def test_returns_false_when_edge_function_says_invalid(settings, monkeypatch):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"valid": False, "reason": "domain_not_found"}

    monkeypatch.setattr(requests, "post", lambda *a, **k: FakeResponse())
    assert email_domain_is_verifiable("typo@gmial.com") is False


def test_fails_open_on_network_error(settings, monkeypatch):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"

    def boom(*args, **kwargs):
        raise requests.ConnectionError("simulated outage")

    monkeypatch.setattr(requests, "post", boom)
    # A third-party outage must not block every registration.
    assert email_domain_is_verifiable("anyone@example.com") is True


def test_fails_open_on_timeout(settings, monkeypatch):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"

    def boom(*args, **kwargs):
        raise requests.Timeout("simulated timeout")

    monkeypatch.setattr(requests, "post", boom)
    assert email_domain_is_verifiable("anyone@example.com") is True


def test_sends_the_shared_secret_header(settings, monkeypatch):
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"
    settings.EMAIL_VERIFY_SHARED_SECRET = "top-secret"
    captured = {}

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"valid": True}

    def fake_post(url, json, headers, timeout):
        captured["url"] = url
        captured["headers"] = headers
        return FakeResponse()

    monkeypatch.setattr(requests, "post", fake_post)
    email_domain_is_verifiable("someone@gmail.com")

    assert captured["url"] == "https://example.supabase.co/functions/v1/verify-email-domain"
    assert captured["headers"]["X-Verification-Secret"] == "top-secret"
