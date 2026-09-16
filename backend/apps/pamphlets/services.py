from apps.core.exceptions import SafeMessageError
from apps.notifications.models import NotificationKind
from apps.notifications.services import notify
from apps.payments.models import PaymentPurpose, PaymentTransactionStatus
from apps.payments.services import charge

from .escrow import issue_qr
from .models import PamphletOrder, PamphletOrderStatus


class PamphletOrderError(SafeMessageError):
    pass


def place_order(*, user, pamphlet, is_delivery: bool, phone_number: str) -> PamphletOrder:
    """
    Per spec (§3.2, step 3): the buyer gets their QR pickup ticket
    immediately after payment — there's no separate ops-approval step in
    the confirmed flow, so the QR is issued right here rather than left for
    a manual issue_qr() call.
    """
    amount = pamphlet.price_fcfa + (pamphlet.delivery_fee_fcfa if is_delivery else 0)
    transaction = charge(
        user=user,
        purpose=PaymentPurpose.PAMPHLET_ORDER,
        amount_fcfa=amount,
        phone_number=phone_number,
        description=f"Pamphlet order: {pamphlet.title}",
    )
    if transaction.status != PaymentTransactionStatus.SUCCESS:
        raise PamphletOrderError(transaction.failure_reason or "Payment failed.")

    order = PamphletOrder.objects.create(
        user=user,
        pamphlet=pamphlet,
        is_delivery=is_delivery,
        amount_paid=amount,
        status=PamphletOrderStatus.PAID_HELD,
        payment_transaction=transaction,
    )
    order = issue_qr(order)

    # QR Vault (owner request, 2026-09-16): the pickup ticket is real and
    # ready the moment this returns (see the docstring above) -- surface
    # that with a real notification rather than only relying on the buyer
    # to remember to open the Recent Shop Items card on Home.
    notify(
        user=user,
        kind=NotificationKind.PAMPHLET_READY,
        title="Your pickup ticket is ready",
        body=f"{pamphlet.title} is ready for pickup at {pamphlet.partner.name}.",
        link=f"qr-vault/{order.id}",
    )
    return order
