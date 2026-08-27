import logging

import requests
from django.conf import settings
from django.core.mail import send_mail

from .models import EmailVerificationCode, User

logger = logging.getLogger(__name__)


def send_verification_email(user: "User") -> EmailVerificationCode:
    """Issues a fresh EmailVerificationCode and emails it. Called both right
    at registration (RegisterView) and from the resend endpoint — kept here
    rather than inlined in either, since both need the exact same code."""
    verification = EmailVerificationCode.issue(user)
    send_mail(
        subject="Verify your Spekooh email",
        message=(
            f"Your Spekooh email verification code is {verification.code}. "
            "It expires in 30 minutes."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
    )
    return verification


def email_domain_is_verifiable(email: str) -> bool:
    """Calls the deployed Supabase Edge Function (verify-email-domain) to
    check the email's domain actually has MX records — catches typo'd
    domains (gmial.com) at registration time. See
    supabase/functions/verify-email-domain/index.ts for what it actually
    checks (syntax + DNS MX lookup, not mailbox existence).

    Fails OPEN (returns True — "let it through") whenever:
    - the edge function isn't configured at all (fresh clone, no Supabase
      project wired up yet — same posture as Sentry/Redis being optional), or
    - the call times out or errors for any other reason (a third-party
      outage shouldn't be able to block every new registration).

    Only an explicit `{"valid": false}` response actually rejects.
    """
    if not settings.SUPABASE_EDGE_FUNCTION_BASE_URL:
        return True
    try:
        response = requests.post(
            f"{settings.SUPABASE_EDGE_FUNCTION_BASE_URL}/verify-email-domain",
            json={"email": email},
            headers={"X-Verification-Secret": settings.EMAIL_VERIFY_SHARED_SECRET or ""},
            timeout=3,
        )
        response.raise_for_status()
        return response.json().get("valid", True)
    except (requests.RequestException, ValueError):
        logger.warning("verify-email-domain call failed; letting registration through.", exc_info=True)
        return True
