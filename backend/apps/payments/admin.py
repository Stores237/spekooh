from django.contrib import admin
from django.utils import timezone
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import PaperUnlock, PaymentTransaction, PaymentTransactionStatus, Subscription, SubscriptionStatus

TRANSACTION_STATUS_LABELS = {
    PaymentTransactionStatus.SUCCESS: "success",
    PaymentTransactionStatus.FAILED: "danger",
}

SUBSCRIPTION_STATUS_LABELS = {
    SubscriptionStatus.ACTIVE: "success",
    SubscriptionStatus.EXPIRED: "danger",
}


@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(ModelAdmin):
    list_display = ("user", "purpose", "amount_fcfa", "status_badge", "failure_reason", "created_at")
    list_filter = ("purpose", "status")
    search_fields = ("user__name", "provider_reference", "failure_reason")
    ordering = ("-created_at",)

    @display(description="Status", label=TRANSACTION_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status


@admin.register(Subscription)
class SubscriptionAdmin(ModelAdmin):
    list_display = ("user", "status_badge", "renewal_countdown")
    list_filter = ("status",)
    ordering = ("renews_at",)

    @display(description="Status", label=SUBSCRIPTION_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="Renews")
    def renewal_countdown(self, obj):
        if obj.status != SubscriptionStatus.ACTIVE:
            return "—"
        remaining = obj.renews_at - timezone.now()
        if remaining.total_seconds() < 0:
            return "Past due (not yet marked expired)"
        return f"{remaining.days}d left"


@admin.register(PaperUnlock)
class PaperUnlockAdmin(ModelAdmin):
    list_display = ("user", "paper_submission", "amount_paid", "created_at")
    search_fields = ("user__name",)
