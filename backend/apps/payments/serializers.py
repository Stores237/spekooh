from rest_framework import serializers

from .models import PaperUnlock, PaymentTransaction, Subscription


class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = ["id", "purpose", "amount_fcfa", "status", "provider_reference", "created_at"]
        read_only_fields = fields


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subscription
        fields = ["id", "status", "renews_at", "created_at"]
        read_only_fields = fields


class SubscribeRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)


class PaperUnlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaperUnlock
        fields = ["id", "paper_submission", "amount_paid", "redeem_code_applied", "created_at"]
        read_only_fields = fields


class UnlockRequestSerializer(serializers.Serializer):
    paper_submission = serializers.IntegerField()
    phone_number = serializers.CharField(max_length=20)
    redeem_code = serializers.CharField(max_length=20, required=False, allow_blank=True)
