from django.contrib import admin, messages
from django.utils import timezone
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import (
    ContributorBonusConfig,
    CreditCeilingConfig,
    CreditLedgerEntry,
    LevelComplexityMultiplier,
    QuestionTypeRate,
    RedeemCode,
    RedeemCodeStatus,
    RedeemCodeTierConfig,
    ReferralBonusConfig,
    SubjectDemandFactor,
)

REDEEM_STATUS_LABELS = {
    RedeemCodeStatus.ACTIVE: "success",
    RedeemCodeStatus.REDEEMED: "info",
    RedeemCodeStatus.EXPIRED: "danger",
}


@admin.register(CreditLedgerEntry)
class CreditLedgerEntryAdmin(ModelAdmin):
    """Retired 2026-09-28 (credits merged into the Points balance, see
    apps.xp.XPLedgerEntry): history only. Adding or editing a row here would
    change nothing anyone can see, so it is not allowed."""

    list_display = ("user", "amount", "reason", "created_at")
    search_fields = ("user__name", "reason")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(RedeemCode)
class RedeemCodeAdmin(ModelAdmin):
    list_display = ("code", "owner", "value_percent", "status_badge", "expiry_countdown", "redeemed_by")
    list_filter = ("status",)
    search_fields = ("code", "owner__name")
    ordering = ("status", "expires_at")
    actions = ["expire_stale_selected"]

    @display(description="Status", label=REDEEM_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="Expires")
    def expiry_countdown(self, obj):
        if obj.status != RedeemCodeStatus.ACTIVE:
            return "-"
        remaining = obj.expires_at - timezone.now()
        if remaining.total_seconds() < 0:
            return "Expired (not yet marked)"
        return f"{remaining.days}d left"

    @admin.action(description="Mark expired (status=ACTIVE past expires_at → EXPIRED)")
    def expire_stale_selected(self, request, queryset):
        stale = queryset.filter(status=RedeemCodeStatus.ACTIVE, expires_at__lt=timezone.now())
        updated = stale.update(status=RedeemCodeStatus.EXPIRED, updated_at=timezone.now())
        self.message_user(request, f"Marked {updated} redeem code(s) as expired.", level=messages.SUCCESS)


@admin.register(QuestionTypeRate)
class QuestionTypeRateAdmin(ModelAdmin):
    list_display = ("question_type", "base_rate_xaf")


@admin.register(LevelComplexityMultiplier)
class LevelComplexityMultiplierAdmin(ModelAdmin):
    list_display = ("level", "multiplier")


@admin.register(SubjectDemandFactor)
class SubjectDemandFactorAdmin(ModelAdmin):
    list_display = ("subject", "factor")


@admin.register(RedeemCodeTierConfig)
class RedeemCodeTierConfigAdmin(ModelAdmin):
    list_display = ("min_submissions", "value_percent", "expiry_days")


@admin.register(ContributorBonusConfig)
class ContributorBonusConfigAdmin(ModelAdmin):
    list_display = ("amount",)


@admin.register(CreditCeilingConfig)
class CreditCeilingConfigAdmin(ModelAdmin):
    list_display = ("max_credit_per_paper_xaf",)


@admin.register(ReferralBonusConfig)
class ReferralBonusConfigAdmin(ModelAdmin):
    list_display = ("amount",)
