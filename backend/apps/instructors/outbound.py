"""
Outbound half of the instructor-partner webhook contract — the inbound half
lives in .webhook. Signs with the same PartnerCredential.hmac_secret and
sign_payload() scheme the partner platform uses to sign its own calls back to
us, so one shared secret covers both directions.

Delivery failure never breaks routing: callers should schedule this via
transaction.on_commit rather than call it inline inside an atomic block, so a
slow/failed HTTP call never holds a DB transaction open, and a webhook that
fails to deliver doesn't roll back a real routing decision. The partner
platform is expected to reconcile missed pushes some other way (e.g. polling
InstructorRequestViewSet) if a push is ever lost.
"""

import json
import logging
import time

import requests
from django.conf import settings

from .models import PartnerCredential
from .webhook import sign_payload

logger = logging.getLogger(__name__)

OUTBOUND_TIMEOUT_SECONDS = 10


def send_partner_webhook(*, event_type: str, payload: dict) -> bool:
    if not settings.INSTRUCTOR_PARTNER_WEBHOOK_URL:
        return False

    try:
        credential = PartnerCredential.objects.get(partner_id=settings.INSTRUCTOR_PARTNER_ID, is_active=True)
    except PartnerCredential.DoesNotExist:
        logger.warning("No active PartnerCredential for %s; skipping outbound webhook.", settings.INSTRUCTOR_PARTNER_ID)
        return False

    raw_body = json.dumps({"event_type": event_type, **payload}).encode()
    timestamp = str(int(time.time()))
    signature = sign_payload(secret=credential.hmac_secret, timestamp=timestamp, raw_body=raw_body)

    try:
        response = requests.post(
            settings.INSTRUCTOR_PARTNER_WEBHOOK_URL,
            data=raw_body,
            headers={
                "Content-Type": "application/json",
                "X-Spekooh-Partner-Id": settings.INSTRUCTOR_PARTNER_ID,
                "X-Spekooh-Timestamp": timestamp,
                "X-Spekooh-Signature": signature,
            },
            timeout=OUTBOUND_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        return True
    except requests.RequestException as exc:
        logger.warning("Outbound instructor webhook (%s) to partner failed: %s", event_type, exc)
        return False


def notify_new_request(instructor_request) -> bool:
    return send_partner_webhook(
        event_type="new_request",
        payload={
            "instructor_request_id": instructor_request.id,
            "instructor_id": instructor_request.instructor_id,
            "paper_id": instructor_request.paper_id,
            "subject": instructor_request.paper.subject.name if instructor_request.paper.subject_id else None,
            "sent_at": instructor_request.sent_at.isoformat(),
            "responds_by": instructor_request.responds_by.isoformat(),
        },
    )


def notify_guide_reminder(instructor_request, *, day: int) -> bool:
    return send_partner_webhook(
        event_type="guide_reminder",
        payload={
            "instructor_request_id": instructor_request.id,
            "instructor_id": instructor_request.instructor_id,
            "paper_id": instructor_request.paper_id,
            "guide_deadline": instructor_request.guide_deadline.isoformat(),
            "day": day,
        },
    )
