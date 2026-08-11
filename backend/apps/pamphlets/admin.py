from django.contrib import admin

from .models import Pamphlet, PamphletOrder, PartnerBookshop


@admin.register(PartnerBookshop)
class PartnerBookshopAdmin(admin.ModelAdmin):
    list_display = ("name", "contact_email", "commission_percent")


@admin.register(Pamphlet)
class PamphletAdmin(admin.ModelAdmin):
    list_display = ("title", "partner", "price_fcfa", "is_active", "is_featured")
    list_filter = ("partner", "is_active", "is_featured")


@admin.register(PamphletOrder)
class PamphletOrderAdmin(admin.ModelAdmin):
    list_display = ("pamphlet", "user", "amount_paid", "status", "payout_amount", "released_at", "created_at")
    list_filter = ("status", "is_delivery")
    readonly_fields = ("qr_token", "qr_issued_at", "self_confirmed_at", "payout_amount", "released_at")
