from django.core import signing
from django.shortcuts import render
from django.views.decorators.csrf import csrf_protect
from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .escrow import AlreadyRedeemedError, EscrowError, dispute, redeem_qr, self_confirm_receipt
from .models import Pamphlet, PamphletOrder, PamphletOrderStatus
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

    @action(detail=False, methods=["get"])
    def featured(self, request):
        pamphlet = self.get_queryset().filter(is_featured=True).first()
        if pamphlet is None:
            return Response({"detail": "No featured pamphlet configured."}, status=status.HTTP_404_NOT_FOUND)
        return Response(PamphletSerializer(pamphlet).data)


class PamphletOrderViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.IsAuthenticated]
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
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(PamphletOrderSerializer(confirmed).data)

    @action(detail=True, methods=["post"])
    def dispute(self, request, pk=None):
        order = self.get_object()
        serializer = DisputeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        disputed = dispute(order, reason=serializer.validated_data["reason"])
        return Response(PamphletOrderSerializer(disputed).data)


class PlacePamphletOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

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
            )
        except PamphletOrderError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(PamphletOrderSerializer(order).data, status=status.HTTP_201_CREATED)


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
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(PamphletOrderSerializer(issued).data)


@csrf_protect
def redeem_page(request, token):
    """
    Plain HTML page (not DRF/JSON) — the partner-side redemption interface,
    scanned by bookshop staff or a courier's phone camera opening the link.
    """
    try:
        order_id = verify_qr_token(token, max_age_seconds=QR_EXPIRY_DAYS * 86400)
        order = PamphletOrder.objects.select_related("pamphlet").get(id=order_id)
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

    if request.method == "POST":
        try:
            released = redeem_qr(token)
        except AlreadyRedeemedError as exc:
            return render(request, "pamphlets/redeem.html", {"error": str(exc)})
        except EscrowError as exc:
            return render(request, "pamphlets/redeem.html", {"error": str(exc)})
        return render(
            request,
            "pamphlets/redeem.html",
            {
                "released": True,
                "pamphlet_title": released.pamphlet.title,
                "payout_amount": released.payout_amount,
            },
        )

    return render(
        request,
        "pamphlets/redeem.html",
        {"pamphlet_title": order.pamphlet.title, "amount_paid": order.amount_paid},
    )
