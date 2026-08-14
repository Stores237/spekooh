from .models import AdminFlagQueue


def flag(*, subject, category: str, reason: str) -> AdminFlagQueue:
    return AdminFlagQueue.objects.create(subject=subject, category=category, reason=reason)


def assign(flag_entry: AdminFlagQueue, *, assignee) -> AdminFlagQueue:
    """Claiming a ticket also advances it to IN_PROGRESS if it's still fresh — assigning
    someone to a ticket and leaving it marked "New" would be a stale/misleading state."""
    from .models import FlagStatus

    flag_entry.assignee = assignee
    if flag_entry.status == FlagStatus.NEW:
        flag_entry.status = FlagStatus.IN_PROGRESS
    flag_entry.save(update_fields=["assignee", "status", "updated_at"])
    return flag_entry


def resolve(flag_entry: AdminFlagQueue, *, resolved_by, notes: str = "") -> AdminFlagQueue:
    from django.utils import timezone

    from .models import FlagStatus

    flag_entry.status = FlagStatus.RESOLVED
    flag_entry.resolved_by = resolved_by
    flag_entry.resolved_at = timezone.now()
    flag_entry.resolution_notes = notes
    flag_entry.save(update_fields=["status", "resolved_by", "resolved_at", "resolution_notes", "updated_at"])
    return flag_entry
