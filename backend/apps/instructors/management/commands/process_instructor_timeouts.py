"""
Cron-driven (see scripts/crontab.example), no Celery/Redis. Race-safe via
select_for_update(skip_locked=True) — an overlapping run just skips rows
already locked by another run, so double-advancing is impossible.
"""

import datetime

from django.core.mail import send_mail
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from ...models import InstructorProfileCache, InstructorRequest, InstructorRequestStatus
from ...services import GUIDE_REMINDER_DAYS, route_next_instructor


class Command(BaseCommand):
    help = "Auto-advances timed-out instructor requests, and sends day-4/day-6 marking-guide deadline reminders."

    def handle(self, *args, **options):
        timed_out = self._process_timeouts()
        reminders = self._send_reminders()
        self.stdout.write(self.style.SUCCESS(f"Timed out {timed_out} request(s), sent {reminders} reminder(s)."))

    def _process_timeouts(self) -> int:
        now = timezone.now()
        count = 0
        candidate_ids = InstructorRequest.objects.filter(
            status=InstructorRequestStatus.PENDING, responds_by__lte=now
        ).values_list("id", flat=True)

        for request_id in candidate_ids:
            with transaction.atomic():
                request = (
                    InstructorRequest.objects.select_for_update(skip_locked=True)
                    .filter(id=request_id, status=InstructorRequestStatus.PENDING, responds_by__lte=now)
                    .first()
                )
                if request is None:
                    continue
                request.status = InstructorRequestStatus.TIMED_OUT
                request.responded_at = now
                request.save(update_fields=["status", "responded_at", "updated_at"])
                route_next_instructor(request.paper)
                count += 1
        return count

    def _send_reminders(self) -> int:
        now = timezone.now()
        count = 0
        for days in GUIDE_REMINDER_DAYS:
            field = f"day{days}_reminder_sent_at"
            cutoff = now - datetime.timedelta(days=days)
            candidates = InstructorRequest.objects.filter(
                status=InstructorRequestStatus.ACCEPTED,
                responded_at__lte=cutoff,
                guide_deadline__gt=now,
                **{f"{field}__isnull": True},
            )
            for request in candidates:
                with transaction.atomic():
                    locked = InstructorRequest.objects.select_for_update(skip_locked=True).filter(
                        id=request.id, **{f"{field}__isnull": True}
                    ).first()
                    if locked is None:
                        continue
                    cached_profile = InstructorProfileCache.objects.filter(instructor_id=locked.instructor_id).first()
                    recipient = (cached_profile.email if cached_profile and cached_profile.email else None) or (
                        f"{locked.instructor_id}@partner-platform.invalid"
                    )
                    send_mail(
                        subject="Reminder: marking guide deadline approaching",
                        message=(
                            f"Your marking guide for paper {locked.paper_id} is due by "
                            f"{locked.guide_deadline:%Y-%m-%d}. This is your day-{days} reminder."
                        ),
                        from_email="noreply@spekooh.local",
                        recipient_list=[recipient],
                        fail_silently=True,
                    )
                    setattr(locked, field, now)
                    locked.save(update_fields=[field, "updated_at"])
                    count += 1
        return count
