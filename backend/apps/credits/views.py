from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest

from .models import CreditLedgerEntry, RedeemCode
from .serializers import CreditLedgerEntrySerializer, RedeemCodeApplySerializer, RedeemCodeSerializer
from .services import CreditEngineError, RedeemCodeError, RedeemCodeIssuer, redeem_code


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
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(RedeemCodeSerializer(redeemed).data)


class RedeemCodeIssueView(APIView):
    """Request a new redeem code sized to the caller's own accepted-submission tier."""

    permission_classes = [IsAuthenticatedNotGuest]

    @extend_schema(request=None, responses=RedeemCodeSerializer)
    def post(self, request):
        from apps.papers.models import PaperStatus, PaperSubmission

        accepted_count = PaperSubmission.objects.filter(
            submitted_by=request.user, status=PaperStatus.PUBLISHED
        ).count()
        try:
            issued = RedeemCodeIssuer().issue_for(owner=request.user, accepted_submission_count=accepted_count)
        except CreditEngineError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(RedeemCodeSerializer(issued).data, status=status.HTTP_201_CREATED)
