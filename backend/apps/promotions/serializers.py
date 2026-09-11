from rest_framework import serializers

from .models import Promotion


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ["id", "title", "subtitle", "sponsor_name", "icon_name", "cta_label", "cta_url"]
