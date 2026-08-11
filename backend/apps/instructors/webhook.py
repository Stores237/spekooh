"""
HMAC-signed, timestamped instructor-platform webhook contract — mirrors the
standard Stripe/GitHub pattern. See PartnerCredential for per-partner secret
rotation and settings.INSTRUCTOR_WEBHOOK_MAX_SKEW_SECONDS for the replay window.
"""

import hashlib
import hmac
import time

from django.conf import settings

from .models import PartnerCredential


class WebhookError(Exception):
    pass


def verify_webhook_request(*, partner_id: str, raw_body: bytes, signature_header: str, timestamp_header: str) -> PartnerCredential:
    if not partner_id or not signature_header or not timestamp_header:
        raise WebhookError("Missing required webhook headers.")

    try:
        credential = PartnerCredential.objects.get(partner_id=partner_id, is_active=True)
    except PartnerCredential.DoesNotExist:
        raise WebhookError("Unknown or inactive partner.") from None

    try:
        timestamp = int(timestamp_header)
    except (TypeError, ValueError):
        raise WebhookError("Invalid timestamp header.") from None

    skew = abs(time.time() - timestamp)
    if skew > settings.INSTRUCTOR_WEBHOOK_MAX_SKEW_SECONDS:
        raise WebhookError("Timestamp outside the allowed replay window.")

    signed_payload = f"{timestamp_header}.".encode() + raw_body
    expected_digest = hmac.new(credential.hmac_secret.encode(), signed_payload, hashlib.sha256).hexdigest()

    provided_digest = signature_header.removeprefix("sha256=")
    if not hmac.compare_digest(expected_digest, provided_digest):
        raise WebhookError("Invalid signature.")

    return credential


def sign_payload(*, secret: str, timestamp: str, raw_body: bytes) -> str:
    """Test/partner-integration helper — mirrors verify_webhook_request's exact scheme."""
    signed_payload = f"{timestamp}.".encode() + raw_body
    digest = hmac.new(secret.encode(), signed_payload, hashlib.sha256).hexdigest()
    return f"sha256={digest}"
