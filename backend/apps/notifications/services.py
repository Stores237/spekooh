from .models import Notification, NotificationKind


def notify(*, user, kind: str = NotificationKind.GENERIC, title: str, body: str) -> Notification:
    """The one place a Notification row gets created — called from real domain
    events in apps.papers/apps.instructors/apps.credits services."""
    return Notification.objects.create(user=user, kind=kind, title=title, body=body)
