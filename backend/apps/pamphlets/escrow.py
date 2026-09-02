from django.core import signing
from django.db import transaction
from django.utils import timezone

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag
from apps.core.exceptions import SafeMessageError

from .models import PamphletOrder, PamphletOrderStatus
from .qr import QR_EXPIRY_DAYS, generate_qr_token, verify_qr_token


class EscrowError(SafeMessageError):
    pass


class AlreadyRedeemedError(EscrowError):
    pass


def issue_qr(order: PamphletOrder) -> PamphletOrder:
    if order.status != PamphletOrderStatus.PAID_HELD:
        raise EscrowError("QR can only be issued for orders currently held in escrow.")
    order.qr_token = generate_qr_token(order.id)
    order.qr_issued_at = timezone.now()
    order.status = PamphletOrderStatus.QR_ISSUED
    order.save(update_fields=["qr_token", "qr_issued_at", "status", "updated_at"])
    return order


def release_order(order: PamphletOrder) -> PamphletOrder:
    commission = order.pamphlet.partner.commission_percent
    order.payout_amount = round(order.amount_paid * (100 - commission) / 100)
    order.status = PamphletOrderStatus.RELEASED
    order.released_at = timezone.now()
    order.save(update_fields=["payout_amount", "status", "released_at", "updated_at"])
    return order


@transaction.atomic
def redeem_qr(token: str) -> PamphletOrder:
    """
    Called from the partner-facing (non-JSON) redemption page. A single-use,
    signed token: valid → release; already redeemed → explicit message with
    the original timestamp (not a generic error); expired → flag for admin.
    """
    try:
        order_id = verify_qr_token(token, max_age_seconds=QR_EXPIRY_DAYS * 86400)
    except signing.SignatureExpired:
        raise EscrowError("This ticket has expired.") from None
    except signing.BadSignature:
        raise EscrowError("This ticket is invalid.") from None

    try:
        order = PamphletOrder.objects.select_for_update().get(id=order_id)
    except PamphletOrder.DoesNotExist:
        raise EscrowError("This ticket is invalid.") from None

    if order.status == PamphletOrderStatus.RELEASED:
        raise AlreadyRedeemedError(f"Already redeemed at {order.released_at:%Y-%m-%d %H:%M}.")
    if order.status != PamphletOrderStatus.QR_ISSUED:
        raise EscrowError(f"This ticket cannot be redeemed (order is {order.status}).")

    return release_order(order)


def self_confirm_receipt(order: PamphletOrder, *, user) -> PamphletOrder:
    if order.user_id != user.id:
        raise EscrowError("Not your order.")
    if not order.is_delivery:
        raise EscrowError("Self-confirmation only applies to delivery orders.")
    if order.status != PamphletOrderStatus.QR_ISSUED:
        raise EscrowError(f"Order cannot be self-confirmed (currently {order.status}).")
    order.self_confirmed_at = timezone.now()
    order.save(update_fields=["self_confirmed_at", "updated_at"])
    return order


def dispute(order: PamphletOrder, *, reason: str) -> PamphletOrder:
    order.status = PamphletOrderStatus.DISPUTED
    order.save(update_fields=["status", "updated_at"])
    flag(subject=order, category=FlagCategory.PAMPHLET_DISPUTE, reason=reason)
    return order
