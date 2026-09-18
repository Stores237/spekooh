import logging

import requests
from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from .models import EmailVerificationCode, User

logger = logging.getLogger(__name__)


def revoke_other_sessions(user: "User", *, keep_jti: str | None = None) -> None:
    """Single-active-session enforcement (owner-reported, 2026-09-18): the
    actual reported gap was shared/stolen credentials letting a second
    device quietly ride alongside the real owner's session, indefinitely
    and undetected -- not multi-device login by itself. Every successful
    login (tokens_for_user, EmailTokenObtainPairSerializer) and a real
    password reset (PasswordResetConfirmSerializer) now revokes every
    OTHER outstanding refresh token for the account immediately, so the
    real owner is signed out -- and can tell something happened -- the
    moment anyone else signs in, rather than both sessions silently
    coexisting forever.

    keep_jti is the jti of the session that should survive (the one just
    issued by this same call) -- pass None to revoke every session
    including the caller's own, which is what a password reset needs
    (it issues no new token itself; the user must log in fresh
    afterward).

    Only ever touches refresh tokens already tracked by
    rest_framework_simplejwt.token_blacklist (ROTATE_REFRESH_TOKENS +
    BLACKLIST_AFTER_ROTATION are already on, see SIMPLE_JWT settings) --
    an already-issued access token (ACCESS_TOKEN_LIFETIME=5 minutes)
    keeps working until it naturally expires, since access tokens aren't
    individually blacklistable; the next refresh attempt on any other
    device is what actually gets rejected.
    """
    from rest_framework_simplejwt.token_blacklist.models import (
        BlacklistedToken,
        OutstandingToken,
    )

    others = OutstandingToken.objects.filter(user=user, expires_at__gt=timezone.now())
    if keep_jti is not None:
        others = others.exclude(jti=keep_jti)
    for outstanding in others:
        BlacklistedToken.objects.get_or_create(token=outstanding)


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
    except Exception:  # deliberately blind: this docstring's own
        # "fails open ... or errors for any other reason" promise wasn't actually
        # kept — only (RequestException, ValueError) were caught, so an
        # unexpected shape from the edge function (e.g. a 200 with a non-dict
        # body, raising AttributeError on .get()) crashed registration with a
        # real 500 instead of failing open. Real bug found live 2026-09-15:
        # registering with an empty email 500'd on staging but not locally
        # against the same edge function code — the exact staging-side cause
        # wasn't confirmed (no Sentry access from this pass), but this check
        # is optional and best-effort by design, so no exception from it
        # should ever be able to block a real registration.
        logger.warning("verify-email-domain call failed; letting registration through.", exc_info=True)
        return True
