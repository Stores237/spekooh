from django.contrib import admin

from .models import PaperUnlock, PaymentTransaction, Subscription


@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ("user", "purpose", "amount_fcfa", "status", "created_at")
    list_filter = ("purpose", "status")
    search_fields = ("user__email", "provider_reference")


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "renews_at")
    list_filter = ("status",)


@admin.register(PaperUnlock)
class PaperUnlockAdmin(admin.ModelAdmin):
    list_display = ("user", "paper_submission", "amount_paid", "created_at")
    search_fields = ("user__email",)
