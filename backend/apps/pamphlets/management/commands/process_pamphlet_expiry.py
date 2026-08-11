"""
Cron-driven (see scripts/crontab.example) — no Celery/Redis. Race-safe via
select_for_update(skip_locked=True) so an overlapping run just skips rows
already locked by another run, matching the instructor-timeout pattern.
"""

import datetime

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag

from ...escrow import release_order
from ...models import PamphletOrder, PamphletOrderStatus
from ...qr import COURIER_SELF_CONFIRM_DAYS, QR_EXPIRY_DAYS


class Command(BaseCommand):
    help = "Expires unredeemed pamphlet QR tickets past 30 days, and auto-releases self-confirmed deliveries past 3 days."

    def handle(self, *args, **options):
        expired_count = self._expire_stale_tickets()
        released_count = self._auto_release_self_confirmed()
        self.stdout.write(self.style.SUCCESS(f"Expired {expired_count}, auto-released {released_count}."))

    def _expire_stale_tickets(self) -> int:
        cutoff = timezone.now() - datetime.timedelta(days=QR_EXPIRY_DAYS)
        count = 0
        candidate_ids = PamphletOrder.objects.filter(
            status=PamphletOrderStatus.QR_ISSUED, qr_issued_at__lte=cutoff
        ).values_list("id", flat=True)

        for order_id in candidate_ids:
            with transaction.atomic():
                order = (
                    PamphletOrder.objects.select_for_update(skip_locked=True)
                    .filter(id=order_id, status=PamphletOrderStatus.QR_ISSUED, qr_issued_at__lte=cutoff)
                    .first()
                )
                if order is None:
                    continue
                order.status = PamphletOrderStatus.EXPIRED
                order.save(update_fields=["status", "updated_at"])
                flag(
                    subject=order,
                    category=FlagCategory.PAMPHLET_EXPIRED,
                    reason=f"QR ticket unredeemed {QR_EXPIRY_DAYS} days after issuance.",
                )
                count += 1
        return count

    def _auto_release_self_confirmed(self) -> int:
        cutoff = timezone.now() - datetime.timedelta(days=COURIER_SELF_CONFIRM_DAYS)
        count = 0
        candidate_ids = PamphletOrder.objects.filter(
            status=PamphletOrderStatus.QR_ISSUED,
            is_delivery=True,
            self_confirmed_at__isnull=False,
            self_confirmed_at__lte=cutoff,
        ).values_list("id", flat=True)

        for order_id in candidate_ids:
            with transaction.atomic():
                order = (
                    PamphletOrder.objects.select_for_update(skip_locked=True)
                    .filter(
                        id=order_id,
                        status=PamphletOrderStatus.QR_ISSUED,
                        self_confirmed_at__isnull=False,
                        self_confirmed_at__lte=cutoff,
                    )
                    .first()
                )
                if order is None:
                    continue
                release_order(order)
                count += 1
        return count
