from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest

from .models import CreditLedgerEntry, RedeemCode
from .serializers import (
    CreditLedgerEntrySerializer,
    RedeemCodeApplySerializer,
    RedeemCodeSerializer,
)
from .services import RedeemCodeError, redeem_code


class CreditLedgerEntryViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = CreditLedgerEntrySerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return CreditLedgerEntry.objects.none()
        return CreditLedgerEntry.objects.filter(user=self.request.user)


class RedeemCodeViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = RedeemCodeSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return RedeemCode.objects.none()
        return RedeemCode.objects.filter(owner=self.request.user)


class RedeemCodeApplyView(APIView):
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=RedeemCodeApplySerializer, responses=RedeemCodeSerializer)
    def post(self, request):
        serializer = RedeemCodeApplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            redeemed = redeem_code(serializer.validated_data["code"], redeemed_by=request.user)
        except RedeemCodeError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_400_BAD_REQUEST)
        return Response(RedeemCodeSerializer(redeemed).data)
