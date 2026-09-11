from rest_framework import generics, permissions

from .models import Promotion
from .serializers import PromotionSerializer


class ActivePromotionsView(generics.ListAPIView):
    """
    Public and always safe to call — returns an empty list until a real
    sponsor deal exists and someone flips is_active on in admin (see
    Promotion's own doc comment). The Flutter client hides its section
    entirely on an empty response, same as this queryset being empty today.
    """

    permission_classes = [permissions.AllowAny]
    serializer_class = PromotionSerializer
    queryset = Promotion.objects.filter(is_active=True)
