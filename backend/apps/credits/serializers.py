from rest_framework import serializers

from .models import CreditLedgerEntry, RedeemCode


class CreditLedgerEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = CreditLedgerEntry
        fields = ["id", "user", "paper_submission", "amount", "reason", "created_at"]
        read_only_fields = fields


class RedeemCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = RedeemCode
        fields = [
            "id",
            "code",
            "owner",
            "value_percent",
            "tier_at_issuance",
            "status",
            "expires_at",
            "redeemed_by",
            "redeemed_at",
            "created_at",
        ]
        read_only_fields = ["id", "code", "owner", "status", "redeemed_by", "redeemed_at", "created_at"]


class RedeemCodeApplySerializer(serializers.Serializer):
    code = serializers.CharField(max_length=20)
