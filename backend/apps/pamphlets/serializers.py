from django.urls import reverse
from rest_framework import serializers

from .models import Pamphlet, PamphletOrder, PartnerBookshop


class PartnerBookshopSerializer(serializers.ModelSerializer):
    class Meta:
        model = PartnerBookshop
        fields = ["id", "name", "contact_phone", "whatsapp_number", "location"]


class PamphletSerializer(serializers.ModelSerializer):
    partner_name = serializers.CharField(source="partner.name", read_only=True)
    # Owner request, 2026-09-17: the "collect at shop" step needs the real
    # pickup address before the buyer has even ordered yet, not just after
    # (PamphletOrderSerializer's partner_location already covers the
    # post-order QR Vault ticket).
    partner_location = serializers.CharField(source="partner.location", read_only=True)
    cover_image_url = serializers.SerializerMethodField()

    def get_cover_image_url(self, obj) -> str | None:
        if not obj.cover_image:
            return None
        request = self.context.get("request")
        url = obj.cover_image.url
        return request.build_absolute_uri(url) if request else url

    class Meta:
        model = Pamphlet
        fields = [
            "id",
            "partner",
            "partner_name",
            "partner_location",
            "title",
            "description",
            "subject_title",
            "academic_level",
            "price_fcfa",
            "delivery_available",
            "delivery_fee_fcfa",
            "is_featured",
            "cover_image_url",
        ]


class PamphletOrderSerializer(serializers.ModelSerializer):
    # "pamphlet" alone is just the FK's id (ModelSerializer default) — the
    # app's "recent shop items" Home card needs a real title to show
    # without a second round-trip per order, same pattern as
    # PamphletSerializer.partner_name above.
    pamphlet_title = serializers.CharField(source="pamphlet.title", read_only=True)
    # QR Vault (owner request, 2026-09-16): the pickup card needs to show
    # which real bookshop and where, not just the pamphlet's own title.
    partner_name = serializers.CharField(source="pamphlet.partner.name", read_only=True)
    partner_location = serializers.CharField(source="pamphlet.partner.location", read_only=True)
    partner_phone = serializers.CharField(source="pamphlet.partner.contact_phone", read_only=True)
    partner_whatsapp = serializers.CharField(source="pamphlet.partner.whatsapp_number", read_only=True)
    qr_redeem_url = serializers.SerializerMethodField()

    def get_qr_redeem_url(self, obj) -> str | None:
        if not obj.qr_token:
            return None
        request = self.context.get("request")
        url = reverse("pamphlet-redeem", args=[obj.qr_token])
        return request.build_absolute_uri(url) if request else url

    class Meta:
        model = PamphletOrder
        fields = [
            "id",
            "pamphlet",
            "pamphlet_title",
            "partner_name",
            "partner_location",
            "partner_phone",
            "partner_whatsapp",
            "is_delivery",
            "quantity",
            "delivery_address",
            "amount_paid",
            "status",
            # Safe to expose: this endpoint is always scoped to the
            # requesting user's own orders — it's their pickup ticket.
            "qr_token",
            "qr_redeem_url",
            "qr_issued_at",
            "self_confirmed_at",
            "payout_amount",
            "released_at",
            "created_at",
        ]
        read_only_fields = fields


class PlaceOrderRequestSerializer(serializers.Serializer):
    pamphlet = serializers.IntegerField()
    is_delivery = serializers.BooleanField(default=False)
    phone_number = serializers.CharField(max_length=20)
    quantity = serializers.IntegerField(default=1, min_value=1)
    # Real pre-existing gap (owner request, 2026-09-17): is_delivery was
    # already a flag with nowhere to actually say where to deliver to.
    delivery_address = serializers.CharField(max_length=255, required=False, allow_blank=True, default="")

    def validate(self, attrs):
        if attrs["is_delivery"] and not attrs.get("delivery_address", "").strip():
            raise serializers.ValidationError({"delivery_address": "A delivery address is required for delivery orders."})
        return attrs


class DisputeRequestSerializer(serializers.Serializer):
    reason = serializers.CharField()
