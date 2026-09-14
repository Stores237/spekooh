"""
Thin wrapper around Twilio's REST API (Verify + plain Messaging) — raw
requests calls, same convention this codebase already uses for external
provider APIs (see apps.ai.providers.gemini/groq), not the official
`twilio` SDK, so no new heavy dependency for four HTTP calls.

Two independent capabilities, with independent real-world requirements:

- Phone verification (send_verification_code/check_verification_code) uses
  a Twilio Verify Service, which generates/expires/attempt-limits the code
  itself — no local OTP-storage model needed here, unlike
  apps.accounts.models.EmailVerificationCode. Confirmed live (2026-09-14):
  creating a Verify Service and using it needs no purchased phone number,
  even on a $0-balance Trial account.
- Plain SMS (send_sms) is Twilio's ordinary Messaging API and DOES need a
  real "From" number or Messaging Service — confirmed live (2026-09-14):
  this account has neither yet (Trial, no funds to buy one). Safe to call
  regardless; it just raises SMSUnavailable until one exists.

Every function raises rather than returning a boolean/None on failure —
callers decide whether that's a 503-style "feature not configured" or a
swallowed-and-logged best-effort failure (see apps.notifications.services
.notify's own sms= handling).
"""

import requests
from django.conf import settings

TWILIO_API_TIMEOUT_SECONDS = 10


class SMSError(Exception):
    """A real Twilio API call was attempted and failed."""


class SMSUnavailable(SMSError):
    """Not configured — same "feature is off, not broken" posture as
    apps.ai.providers.base.AIUnavailable."""


def _require(*values) -> None:
    if not all(values):
        raise SMSUnavailable("Twilio is not configured.")


def _auth() -> tuple[str, str]:
    return settings.TWILIO_API_KEY_SID, settings.TWILIO_API_KEY_SECRET


def send_verification_code(phone_number: str) -> None:
    """Starts a Twilio Verify check — the SMS itself, and its code, are
    entirely Twilio's responsibility from here; see check_verification_code."""
    _require(settings.TWILIO_API_KEY_SID, settings.TWILIO_API_KEY_SECRET, settings.TWILIO_VERIFY_SERVICE_SID)
    response = requests.post(
        f"https://verify.twilio.com/v2/Services/{settings.TWILIO_VERIFY_SERVICE_SID}/Verifications",
        auth=_auth(),
        data={"To": phone_number, "Channel": "sms"},
        timeout=TWILIO_API_TIMEOUT_SECONDS,
    )
    if response.status_code >= 400:
        raise SMSError(f"Twilio Verify send failed ({response.status_code}): {response.text}")


def check_verification_code(phone_number: str, code: str) -> bool:
    """True only for Twilio's own "approved" status — a wrong/expired/
    already-used code is a normal False, not an exception; a genuine API
    failure still raises SMSError."""
    _require(settings.TWILIO_API_KEY_SID, settings.TWILIO_API_KEY_SECRET, settings.TWILIO_VERIFY_SERVICE_SID)
    response = requests.post(
        f"https://verify.twilio.com/v2/Services/{settings.TWILIO_VERIFY_SERVICE_SID}/VerificationCheck",
        auth=_auth(),
        data={"To": phone_number, "Code": code},
        timeout=TWILIO_API_TIMEOUT_SECONDS,
    )
    # Twilio returns 404 for "no pending verification for this number"
    # (expired, never sent, or already consumed) — a normal rejection, not
    # an error worth raising SMSError over.
    if response.status_code == 404:
        return False
    if response.status_code >= 400:
        raise SMSError(f"Twilio Verify check failed ({response.status_code}): {response.text}")
    return response.json().get("status") == "approved"


def send_sms(*, to: str, body: str) -> None:
    """Plain SMS, e.g. for apps.notifications — needs TWILIO_MESSAGING_FROM_NUMBER
    (a real purchased number/Messaging Service), a separate requirement
    from Verify above. Raises SMSUnavailable until one exists."""
    _require(
        settings.TWILIO_ACCOUNT_SID,
        settings.TWILIO_API_KEY_SID,
        settings.TWILIO_API_KEY_SECRET,
        settings.TWILIO_MESSAGING_FROM_NUMBER,
    )
    response = requests.post(
        f"https://api.twilio.com/2010-04-01/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json",
        auth=_auth(),
        data={"To": to, "From": settings.TWILIO_MESSAGING_FROM_NUMBER, "Body": body},
        timeout=TWILIO_API_TIMEOUT_SECONDS,
    )
    if response.status_code >= 400:
        raise SMSError(f"Twilio SMS send failed ({response.status_code}): {response.text}")
