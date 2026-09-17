from django.core import signing
from django.shortcuts import render
from django.views.decorators.csrf import csrf_protect
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest

from .escrow import (
    AlreadyRedeemedError,
    EscrowError,
    confirm_redeem_verification,
    dispute,
    redeem_qr,
    self_confirm_receipt,
    start_redeem_verification,
)
from .models import (
    Pamphlet,
    PamphletOrder,
    PamphletOrderStatus,
    RedeemVerification,
    RedeemVerificationChannel,
)
from .qr import QR_EXPIRY_DAYS, verify_qr_token
from .serializers import (
    DisputeRequestSerializer,
    PamphletOrderSerializer,
    PamphletSerializer,
    PlaceOrderRequestSerializer,
)
from .services import PamphletOrderError, place_order


class PamphletViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Pamphlet.objects.filter(is_active=True).select_related("partner")
    serializer_class = PamphletSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["subject_title", "academic_level"]

    @action(detail=False, methods=["get"])
    def featured(self, request):
        pamphlet = self.get_queryset().filter(is_featured=True).first()
        if pamphlet is None:
            return Response({"detail": "No featured pamphlet configured."}, status=status.HTTP_404_NOT_FOUND)
        return Response(PamphletSerializer(pamphlet, context={"request": request}).data)


class PamphletOrderViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    # Hardening (2026-09-06): was plain IsAuthenticated, which a guest JWT
    # also satisfies — the app has never actually sent one here (no
    # guestAccessToken plumbing exists for ordering), but every other
    # paid/account-gated endpoint in this codebase (PaperUnlockViewSet,
    # AdWatchView, notifications, ...) uses IsAuthenticatedNotGuest
    # explicitly rather than relying on the app simply not trying.
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = PamphletOrderSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return PamphletOrder.objects.none()
        return PamphletOrder.objects.filter(user=self.request.user)

    @action(detail=True, methods=["post"])
    def self_confirm(self, request, pk=None):
        order = self.get_object()
        try:
            confirmed = self_confirm_receipt(order, user=request.user)
        except EscrowError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_400_BAD_REQUEST)
        return Response(PamphletOrderSerializer(confirmed, context={"request": request}).data)

    @action(detail=True, methods=["post"])
    def dispute(self, request, pk=None):
        order = self.get_object()
        serializer = DisputeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        disputed = dispute(order, reason=serializer.validated_data["reason"])
        return Response(PamphletOrderSerializer(disputed, context={"request": request}).data)


class PlacePamphletOrderView(APIView):
    # Same hardening as PamphletOrderViewSet above.
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=PlaceOrderRequestSerializer, responses=PamphletOrderSerializer)
    def post(self, request):
        serializer = PlaceOrderRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            pamphlet = Pamphlet.objects.get(id=data["pamphlet"], is_active=True)
        except Pamphlet.DoesNotExist:
            return Response({"detail": "Pamphlet not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            order = place_order(
                user=request.user,
                pamphlet=pamphlet,
                is_delivery=data["is_delivery"],
                phone_number=data["phone_number"],
                quantity=data["quantity"],
                delivery_address=data["delivery_address"],
            )
        except PamphletOrderError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_402_PAYMENT_REQUIRED)
        # context={"request": request} so qr_redeem_url resolves to a real
        # absolute URL here too, not just on the list/retrieve endpoints
        # (which get it for free via GenericViewSet.get_serializer_context).
        return Response(PamphletOrderSerializer(order, context={"request": request}).data, status=status.HTTP_201_CREATED)


class IssueQrView(APIView):
    """Ops-triggered: mint the pickup QR token once an order is ready for handover."""

    permission_classes = [permissions.IsAdminUser]

    @extend_schema(request=None, responses=PamphletOrderSerializer)
    def post(self, request, order_id):
        from .escrow import issue_qr

        try:
            order = PamphletOrder.objects.get(id=order_id)
        except PamphletOrder.DoesNotExist:
            return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)
        try:
            issued = issue_qr(order)
        except EscrowError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_400_BAD_REQUEST)
        return Response(PamphletOrderSerializer(issued, context={"request": request}).data)


def _mask_email(email: str) -> str:
    name, _, domain = email.partition("@")
    visible = name[:1] or "*"
    return f"{visible}{'*' * max(len(name) - 1, 3)}@{domain}"


def _mask_phone(phone: str) -> str:
    if len(phone) <= 4:
        return "*" * len(phone)
    return f"{phone[:2]}{'*' * (len(phone) - 4)}{phone[-2:]}"


def _session_key(token: str) -> str:
    return f"pamphlet_redeem_verification_{token}"


@csrf_protect
def redeem_page(request, token):
    """
    Plain HTML page (not DRF/JSON) — the partner-side redemption interface,
    scanned by bookshop staff or a courier's phone camera opening the link.

    Owner-reported security fix (2026-09-17): this used to release escrow
    off a single unauthenticated button click — anyone holding the
    scanning phone could confirm someone else's handover. Now a real
    one-time code, sent to the *partner's own* registered email or phone
    (never the buyer's), must be entered correctly first — see
    RedeemVerification and apps.pamphlets.escrow.start_redeem_verification
    / confirm_redeem_verification. Session-tracked across this view's
    plain-HTML POST steps since there's no account/JWT to key state to
    here (whoever scans this link is, by definition, not logged into the
    app).
    """
    try:
        order_id = verify_qr_token(token, max_age_seconds=QR_EXPIRY_DAYS * 86400)
        order = PamphletOrder.objects.select_related("pamphlet__partner").get(id=order_id)
    except signing.SignatureExpired:
        return render(request, "pamphlets/redeem.html", {"error": "This ticket has expired."})
    except (signing.BadSignature, PamphletOrder.DoesNotExist):
        return render(request, "pamphlets/redeem.html", {"error": "This ticket is invalid."})

    if order.status == PamphletOrderStatus.RELEASED:
        return render(
            request,
            "pamphlets/redeem.html",
            {"error": f"Already redeemed at {order.released_at:%Y-%m-%d %H:%M}."},
        )
    if order.status != PamphletOrderStatus.QR_ISSUED:
        return render(
            request,
            "pamphlets/redeem.html",
            {"error": f"This ticket cannot be redeemed (order is {order.get_status_display()})."},
        )

    partner = order.pamphlet.partner
    session_key = _session_key(token)

    def _channel_step(error: str | None = None):
        return render(
            request,
            "pamphlets/redeem.html",
            {
                "step": "channel",
                "pamphlet_title": order.pamphlet.title,
                "amount_paid": order.amount_paid,
                "has_email": bool(partner.contact_email),
                "has_phone": bool(partner.verification_phone),
                "error": error,
            },
        )

    def _code_step(verification: RedeemVerification, error: str | None = None):
        masked = (
            _mask_email(partner.contact_email)
            if verification.channel == RedeemVerificationChannel.EMAIL
            else _mask_phone(partner.verification_phone)
        )
        return render(
            request,
            "pamphlets/redeem.html",
            {
                "step": "code",
                "pamphlet_title": order.pamphlet.title,
                "amount_paid": order.amount_paid,
                "masked_destination": masked,
                "attempts_remaining": RedeemVerification.MAX_ATTEMPTS - verification.attempts,
                "error": error,
            },
        )

    if request.method == "POST":
        if "restart" in request.POST:
            request.session.pop(session_key, None)
            return _channel_step()

        if "channel" in request.POST:
            channel = request.POST.get("channel")
            # SUPPORT is deliberately excluded here even though it's a real
            # RedeemVerificationChannel value -- it must never be
            # self-service-selectable, only ever issued by Integration Ops
            # via generate_support_override_code. See has_support_form
            # below for how a support code is actually redeemed instead.
            if channel not in (RedeemVerificationChannel.EMAIL, RedeemVerificationChannel.PHONE):
                return _channel_step("Choose a real option.")
            try:
                verification = start_redeem_verification(order, channel=channel)
            except EscrowError as exc:
                return _channel_step(exc.detail)
            request.session[session_key] = verification.id
            return _code_step(verification)

        if "code" in request.POST:
            entered_code = request.POST.get("code", "").strip()

            # A live Integration-Ops-issued support code always takes
            # precedence when it matches -- it works independent of
            # session state by design (see generate_support_override_
            # code's own docstring: relayed over a phone call, often in a
            # different browser session entirely, e.g. via the standalone
            # support-code form on the channel step below), and checking it
            # first means a real email/phone verification's own attempt
            # counter is never penalized for a code that was never meant
            # for it.
            support_verification = (
                RedeemVerification.objects.filter(order=order, channel=RedeemVerificationChannel.SUPPORT, code=entered_code)
                .order_by("-created_at")
                .first()
            )
            if support_verification is not None and support_verification.is_usable:
                verification = support_verification
            else:
                verification_id = request.session.get(session_key)
                verification = RedeemVerification.objects.filter(id=verification_id, order=order).first()
                if verification is None:
                    return _channel_step("That code has expired. Choose how to receive a new one.")
                if not verification.is_usable:
                    request.session.pop(session_key, None)
                    return _channel_step("Too many attempts or the code expired. Choose how to receive a new one.")

            if confirm_redeem_verification(verification, code=entered_code):
                request.session.pop(session_key, None)
                try:
                    released = redeem_qr(token)
                except AlreadyRedeemedError as exc:
                    return render(request, "pamphlets/redeem.html", {"error": exc.detail})
                except EscrowError as exc:
                    return render(request, "pamphlets/redeem.html", {"error": exc.detail})
                return render(
                    request,
                    "pamphlets/redeem.html",
                    {
                        "released": True,
                        "pamphlet_title": released.pamphlet.title,
                        "payout_amount": released.payout_amount,
                    },
                )

            verification.refresh_from_db()
            if not verification.is_usable:
                request.session.pop(session_key, None)
                return _channel_step("Too many wrong attempts. Choose how to receive a new one.")
            return _code_step(verification, "Wrong code.")

    verification_id = request.session.get(session_key)
    verification = RedeemVerification.objects.filter(id=verification_id, order=order).first()
    if verification is not None and verification.is_usable:
        return _code_step(verification)
    request.session.pop(session_key, None)
    return _channel_step()
