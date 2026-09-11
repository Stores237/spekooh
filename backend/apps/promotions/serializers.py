from rest_framework import serializers

from .models import Promotion


class PromotionSerializer(serializers.ModelSerializer):
    logo_url = serializers.SerializerMethodField()

    class Meta:
        model = Promotion
        fields = ["id", "title", "subtitle", "sponsor_name", "icon_name", "logo_url", "cta_label", "cta_url"]

    def get_logo_url(self, obj) -> str | None:
        if not obj.logo:
            return None
        request = self.context.get("request")
        url = obj.logo.url
        return request.build_absolute_uri(url) if request else url
