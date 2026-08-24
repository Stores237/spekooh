from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest
from apps.papers.models import PaperSubmission

from .models import PaperUnlock, PaymentTransaction, Subscription
from .serializers import (
    PaperUnlockSerializer,
    PaymentTransactionSerializer,
    SubscribeRequestSerializer,
    SubscriptionSerializer,
    UnlockRequestSerializer,
)
from .services import PaperUnlockError, SubscriptionError, subscribe, unlock_paper


class PaymentTransactionViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = PaymentTransactionSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return PaymentTransaction.objects.none()
        return PaymentTransaction.objects.filter(user=self.request.user)


class SubscriptionViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = SubscriptionSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Subscription.objects.none()
        return Subscription.objects.filter(user=self.request.user)


class SubscribeView(APIView):
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=SubscribeRequestSerializer, responses=SubscriptionSerializer)
    def post(self, request):
        serializer = SubscribeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            subscription = subscribe(user=request.user, phone_number=serializer.validated_data["phone_number"])
        except SubscriptionError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(SubscriptionSerializer(subscription).data, status=status.HTTP_201_CREATED)


class PaperUnlockViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticatedNotGuest]
    serializer_class = PaperUnlockSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return PaperUnlock.objects.none()
        return PaperUnlock.objects.filter(user=self.request.user)


class UnlockPaperView(APIView):
    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=UnlockRequestSerializer, responses=PaperUnlockSerializer)
    def post(self, request):
        serializer = UnlockRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            paper = PaperSubmission.objects.get(id=data["paper_submission"])
        except PaperSubmission.DoesNotExist:
            return Response({"detail": "Paper not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            unlock = unlock_paper(
                user=request.user,
                paper_submission=paper,
                phone_number=data["phone_number"],
                redeem_code_str=data.get("redeem_code") or None,
            )
        except PaperUnlockError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response(PaperUnlockSerializer(unlock).data, status=status.HTTP_201_CREATED)
