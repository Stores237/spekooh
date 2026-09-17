from django.contrib import admin, messages
from django.utils.html import format_html
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .escrow import generate_support_override_code, release_order
from .models import (
    Pamphlet,
    PamphletOrder,
    PamphletOrderStatus,
    PartnerBookshop,
    RedeemVerification,
)

ORDER_STATUS_LABELS = {
    PamphletOrderStatus.PAID_HELD: "info",
    PamphletOrderStatus.QR_ISSUED: "warning",
    PamphletOrderStatus.RELEASED: "success",
    PamphletOrderStatus.EXPIRED: "danger",
    PamphletOrderStatus.DISPUTED: "danger",
}


@admin.register(PartnerBookshop)
class PartnerBookshopAdmin(ModelAdmin):
    list_display = ("name", "full_name", "contact_email", "orange_money_number", "momo_number", "location", "commission_percent")
    search_fields = ("name", "full_name", "contact_email", "cni_number", "nui_number")
    # Owner decision (2026-09-17, partner KYC hardening): full_name/
    # contact_email/location/cni_number/nui_number are model-required
    # (blank=False) so the admin form itself refuses to save a partner
    # missing any of them; PartnerBookshop.clean() additionally enforces
    # at least one of orange_money_number/momo_number, which Django's
    # ModelForm calls automatically via full_clean() on save.
    fieldsets = (
        (None, {"fields": ("name", "full_name", "location", "commission_percent")}),
        ("Contact", {"fields": ("contact_email", "contact_phone", "whatsapp_number")}),
        ("Mobile money (at least one required)", {"fields": ("orange_money_number", "momo_number")}),
        (
            "Identity documents",
            {"fields": ("cni_number", "cni_document", "nui_number", "nui_document")},
        ),
    )


@admin.register(Pamphlet)
class PamphletAdmin(ModelAdmin):
    list_display = ("cover_thumbnail", "title", "partner", "subject_title", "academic_level", "price_fcfa", "display_order", "is_active", "is_featured")
    list_display_links = ("title",)
    list_filter = ("partner", "is_active", "is_featured", "subject_title", "academic_level")
    search_fields = ("title", "partner__name")
    # Integration Ops (owner request, 2026-09-16): reorder the shop listing
    # without opening each pamphlet -- lower sorts first, ties broken
    # alphabetically (Pamphlet.Meta.ordering). is_featured still always
    # wins the top slot regardless of this value.
    list_editable = ("display_order", "is_active", "is_featured")

    @display(description="Cover")
    def cover_thumbnail(self, obj):
        if not obj.cover_image:
            return "-"
        return format_html('<img src="{}" style="height: 40px; border-radius: 4px;" />', obj.cover_image.url)


@admin.register(PamphletOrder)
class PamphletOrderAdmin(ModelAdmin):
    list_display = ("pamphlet", "user", "amount_paid", "status_badge", "payout_amount", "released_at", "created_at")
    list_filter = ("status", "is_delivery")
    search_fields = ("pamphlet__title", "user__name", "qr_token")
    readonly_fields = ("qr_token", "qr_issued_at", "self_confirmed_at", "payout_amount", "released_at")
    actions = ["resolve_dispute_release", "generate_support_code"]

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

    @admin.action(description="Generate a 3-minute support override code (Integration Ops only)")
    def generate_support_code(self, request, queryset):
        # Django's built-in permission gating doesn't scope custom actions
        # tightly enough on its own (established pattern this codebase
        # already relies on elsewhere) -- this bypasses a partner ever
        # proving control of their own registered email/phone, so it's
        # explicitly re-checked here rather than trusting action visibility.
        if not (request.user.is_superuser or request.user.groups.filter(name="Integration Ops").exists()):
            self.message_user(request, "Only Integration Ops can generate a support override code.", level=messages.ERROR)
            return
        if queryset.count() != 1:
            self.message_user(request, "Select exactly one order to generate a support code for.", level=messages.ERROR)
            return
        order = queryset.first()
        if order.status != PamphletOrderStatus.QR_ISSUED:
            self.message_user(
                request,
                f"Can't generate a code for an order that's {order.get_status_display()}.",
                level=messages.ERROR,
            )
            return
        verification = generate_support_override_code(order, issued_by=request.user)
        self.message_user(
            request,
            f"Support override code for order #{order.id}: {verification.code} "
            f"(expires in {RedeemVerification.SUPPORT_TTL_MINUTES} minutes). "
            "Read this to the partner over the phone -- never send it by email/SMS.",
            level=messages.SUCCESS,
        )


@admin.register(RedeemVerification)
class RedeemVerificationAdmin(ModelAdmin):
    """Read-only audit trail -- codes are issued/consumed through the
    redeem flow and the support-override action above, never edited here."""

    list_display = ("order", "channel", "attempts", "used_at", "issued_by", "created_at")
    list_filter = ("channel",)
    search_fields = ("order__pamphlet__title", "order__id")
    readonly_fields = [f.name for f in RedeemVerification._meta.fields]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
