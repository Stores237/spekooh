from django.contrib import admin, messages
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .escrow import release_order
from .models import Pamphlet, PamphletOrder, PamphletOrderStatus, PartnerBookshop

ORDER_STATUS_LABELS = {
    PamphletOrderStatus.PAID_HELD: "info",
    PamphletOrderStatus.QR_ISSUED: "warning",
    PamphletOrderStatus.RELEASED: "success",
    PamphletOrderStatus.EXPIRED: "danger",
    PamphletOrderStatus.DISPUTED: "danger",
}


@admin.register(PartnerBookshop)
class PartnerBookshopAdmin(ModelAdmin):
    list_display = ("name", "contact_email", "contact_phone", "location", "commission_percent")
    search_fields = ("name", "contact_email")


@admin.register(Pamphlet)
class PamphletAdmin(ModelAdmin):
    list_display = ("title", "partner", "subject_title", "academic_level", "price_fcfa", "display_order", "is_active", "is_featured")
    list_filter = ("partner", "is_active", "is_featured", "subject_title", "academic_level")
    search_fields = ("title", "partner__name")
    # Integration Ops (owner request, 2026-09-16): reorder the shop listing
    # without opening each pamphlet -- lower sorts first, ties broken
    # alphabetically (Pamphlet.Meta.ordering). is_featured still always
    # wins the top slot regardless of this value.
    list_editable = ("display_order", "is_active", "is_featured")


@admin.register(PamphletOrder)
class PamphletOrderAdmin(ModelAdmin):
    list_display = ("pamphlet", "user", "amount_paid", "status_badge", "payout_amount", "released_at", "created_at")
    list_filter = ("status", "is_delivery")
    search_fields = ("pamphlet__title", "user__name", "qr_token")
    readonly_fields = ("qr_token", "qr_issued_at", "self_confirmed_at", "payout_amount", "released_at")
    actions = ["resolve_dispute_release"]

    @display(description="Status", label=ORDER_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @admin.action(description="Resolve dispute (release to partner)")
    def resolve_dispute_release(self, request, queryset):
        # Refund-side resolution isn't wired up yet -- no payment-gateway
        # refund integration exists anywhere in this codebase today (owner
        # decision, 2026-09-16: ship release-side now, refund is a real
        # follow-up, not faked here). This action only ever moves a
        # DISPUTED order forward to RELEASED, never touches money going
        # the other way.
        disputed = list(queryset.filter(status=PamphletOrderStatus.DISPUTED))
        for order in disputed:
            release_order(order)
        skipped = queryset.count() - len(disputed)
        self.message_user(
            request,
            f"Released {len(disputed)} order(s) to their partner."
            + (f" Skipped {skipped} not currently disputed." if skipped else ""),
            level=messages.SUCCESS if disputed else messages.WARNING,
        )
