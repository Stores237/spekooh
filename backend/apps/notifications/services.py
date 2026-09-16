import logging

from .models import Notification, NotificationKind

logger = logging.getLogger(__name__)


def notify(
    *, user, kind: str = NotificationKind.GENERIC, title: str, body: str, link: str = "", sms: bool = False
) -> Notification:
    """The one place a Notification row gets created — called from real domain
    events in apps.papers/apps.instructors/apps.credits services.

    sms=True (2026-09-14, owner request) additionally best-effort sends the
    same content by SMS via Twilio — opt-in per call site, not automatic
    for every notify() call: which notification *kinds* actually warrant
    interrupting someone's phone is a product decision this function
    shouldn't make unilaterally. Requires both a verified phone number and
    TWILIO_MESSAGING_FROM_NUMBER configured (a real purchased Twilio
    number/Messaging Service — separate from the phone-verification
    TWILIO_VERIFY_SERVICE_SID, see apps.core.sms's own docstring); silently
    a no-op otherwise, same "best-effort, never blocks the in-app
    notification" posture as everything else optional in this codebase."""
    notification = Notification.objects.create(user=user, kind=kind, title=title, body=body, link=link)
    if sms and getattr(user, "phone_verified_at", None) and user.phone_number:
        from apps.core.sms import SMSError, SMSUnavailable, send_sms

        try:
            send_sms(to=user.phone_number, body=f"{title}: {body}")
        except SMSUnavailable:
            pass
        except SMSError:
            logger.warning("SMS notification failed for user %s", user.id, exc_info=True)
    return notification
