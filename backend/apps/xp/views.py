from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAuthenticatedNotGuest

from .services import InsufficientXPError, redeem_slot_bonus


class RedeemSlotBonusView(APIView):
    """Spends 250 XP for a real +1 offline download slot, 3 days —
    see apps.xp.services.redeem_slot_bonus. Guests can't earn XP at all
    (quiz submission is IsAuthenticatedNotGuest-gated), so this is too."""

    permission_classes = [IsAuthenticatedNotGuest]

    def post(self, request):
        try:
            expires_at = redeem_slot_bonus(request.user)
        except InsufficientXPError as exc:
            return Response({"detail": exc.detail}, status=status.HTTP_402_PAYMENT_REQUIRED)
        return Response({"bonus_offline_slot_until": expires_at}, status=status.HTTP_200_OK)
