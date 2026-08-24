"""
Cron-driven (see scripts/crontab.example), no Celery/Redis. Race-safe via
select_for_update(skip_locked=True), matching the instructor-timeout /
pamphlet-expiry pattern.

A guest account (AccountType.GUEST) is minted the moment a contributor
types a name — before their upload is known to succeed (see
AuthSession.mintGuestAccessToken on the app side). An abandoned upload, a
network failure, or a cancelled submission leaves the guest's User row
behind with nothing pointing at it. Nothing else ever prunes these, so
without this command they accumulate forever. A guest that went on to own
at least one PaperSubmission is never touched here — deleting it would
CASCADE-delete their own submission (PaperSubmission.submitted_by).
"""

import datetime

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Exists, OuterRef
from django.utils import timezone

from apps.papers.models import PaperSubmission

from ...models import AccountType, User

# Comfortably longer than any real upload attempt takes, short enough that
# unclaimed rows don't linger — see the module docstring.
GUEST_ACCOUNT_ORPHAN_TTL_HOURS = 24


class Command(BaseCommand):
    help = "Deletes guest accounts older than 24h that never ended up owning a submission."

    def handle(self, *args, **options):
        count = self._delete_orphaned_guests()
        self.stdout.write(self.style.SUCCESS(f"Deleted {count} orphaned guest account(s)."))

    def _delete_orphaned_guests(self) -> int:
        cutoff = timezone.now() - datetime.timedelta(hours=GUEST_ACCOUNT_ORPHAN_TTL_HOURS)
        has_submission = PaperSubmission.objects.filter(submitted_by=OuterRef("pk"))
        candidate_ids = (
            User.objects.filter(account_type=AccountType.GUEST, created_at__lte=cutoff)
            .annotate(has_submission=Exists(has_submission))
            .filter(has_submission=False)
            .values_list("id", flat=True)
        )

        count = 0
        for user_id in list(candidate_ids):
            with transaction.atomic():
                user = (
                    User.objects.select_for_update(skip_locked=True)
                    .annotate(has_submission=Exists(has_submission))
                    .filter(
                        id=user_id,
                        account_type=AccountType.GUEST,
                        created_at__lte=cutoff,
                        has_submission=False,
                    )
                    .first()
                )
                if user is None:
                    continue
                user.delete()
                count += 1
        return count
