from rest_framework import serializers

from .models import Pamphlet, PamphletOrder, PartnerBookshop


class PartnerBookshopSerializer(serializers.ModelSerializer):
    class Meta:
        model = PartnerBookshop
        fields = ["id", "name"]


class PamphletSerializer(serializers.ModelSerializer):
    partner_name = serializers.CharField(source="partner.name", read_only=True)

    class Meta:
        model = Pamphlet
        fields = [
            "id",
            "partner",
            "partner_name",
            "title",
            "description",
            "subject_title",
            "academic_level",
            "price_fcfa",
            "delivery_available",
            "delivery_fee_fcfa",
            "is_featured",
        ]


class PamphletOrderSerializer(serializers.ModelSerializer):
    # "pamphlet" alone is just the FK's id (ModelSerializer default) — the
    # app's "recent shop items" Home card needs a real title to show
    # without a second round-trip per order, same pattern as
    # PamphletSerializer.partner_name above.
    pamphlet_title = serializers.CharField(source="pamphlet.title", read_only=True)

    class Meta:
        model = PamphletOrder
        fields = [
            "id",
            "pamphlet",
            "pamphlet_title",
            "is_delivery",
            "amount_paid",
            "status",
            # Safe to expose: this endpoint is always scoped to the
            # requesting user's own orders — it's their pickup ticket.
            "qr_token",
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


class DisputeRequestSerializer(serializers.Serializer):
    reason = serializers.CharField()
