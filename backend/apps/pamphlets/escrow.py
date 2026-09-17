import secrets

from django.conf import settings
from django.core import signing
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag
from apps.core.exceptions import SafeMessageError
from apps.core.sms import (
    SMSError,
    SMSUnavailable,
    check_verification_code,
    send_verification_code,
)

from .models import (
    PamphletOrder,
    PamphletOrderStatus,
    RedeemVerification,
    RedeemVerificationChannel,
)
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


def start_redeem_verification(order: PamphletOrder, *, channel: str) -> RedeemVerification:
    """
    Owner-reported security fix (2026-09-17): before this, redeem_qr ran
    off a single unauthenticated button click -- anyone holding the
    scanning phone could confirm someone else's handover. This sends a
    real one-time code to the *partner's own* registered email or phone
    (never the buyer's), which confirm_redeem_verification must approve
    before redeem_qr is allowed to run.
    """
    partner = order.pamphlet.partner
    verification = RedeemVerification.objects.create(order=order, channel=channel)
    if channel == RedeemVerificationChannel.EMAIL:
        if not partner.contact_email:
            raise EscrowError("This partner has no email on file to send a code to.")
        code = f"{secrets.randbelow(1_000_000):06d}"
        verification.code = code
        verification.save(update_fields=["code"])
        send_mail(
            subject="Spekooh pickup confirmation code",
            message=f"Your confirmation code is {code}. It expires in {RedeemVerification.TTL_MINUTES} minutes.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[partner.contact_email],
        )
    else:
        phone = partner.verification_phone
        if not phone:
            raise EscrowError("This partner has no verified phone number on file to send a code to.")
        try:
            send_verification_code(phone)
        except SMSUnavailable as exc:
            raise EscrowError("SMS verification isn't available right now. Try email instead.") from exc
        except SMSError as exc:
            raise EscrowError("Couldn't send the SMS code. Try again or use email instead.") from exc
    return verification


def confirm_redeem_verification(verification: RedeemVerification, *, code: str) -> bool:
    """True only for a genuinely correct, still-usable code -- never
    trusts the caller's own say-so. A wrong/expired/attempts-exhausted
    code is a normal False, counted against the same independent attempt
    cap SECURITY.md asks of every short numeric code in this app."""
    if not verification.is_usable:
        return False

    if verification.channel == RedeemVerificationChannel.EMAIL:
        correct = code == verification.code
    else:
        phone = verification.order.pamphlet.partner.verification_phone
        try:
            correct = check_verification_code(phone, code)
        except SMSError:
            correct = False

    verification.attempts += 1
    update_fields = ["attempts"]
    if correct:
        verification.used_at = timezone.now()
        update_fields.append("used_at")
    verification.save(update_fields=update_fields)
    return correct


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
