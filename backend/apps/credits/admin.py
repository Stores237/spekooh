from django.contrib import admin

from .models import (
    ContributorBonusConfig,
    CreditLedgerEntry,
    LevelComplexityMultiplier,
    QuestionTypeRate,
    RedeemCode,
    RedeemCodeTierConfig,
    SubjectDemandFactor,
)


@admin.register(CreditLedgerEntry)
class CreditLedgerEntryAdmin(admin.ModelAdmin):
    list_display = ("user", "amount", "reason", "created_at")
    search_fields = ("user__email", "reason")


@admin.register(RedeemCode)
class RedeemCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "owner", "value_percent", "status", "expires_at", "redeemed_by")
    list_filter = ("status",)
    search_fields = ("code", "owner__email")


@admin.register(QuestionTypeRate)
class QuestionTypeRateAdmin(admin.ModelAdmin):
    list_display = ("question_type", "base_rate_xaf")


@admin.register(LevelComplexityMultiplier)
class LevelComplexityMultiplierAdmin(admin.ModelAdmin):
    list_display = ("level", "multiplier")


@admin.register(SubjectDemandFactor)
class SubjectDemandFactorAdmin(admin.ModelAdmin):
    list_display = ("subject", "factor")


@admin.register(RedeemCodeTierConfig)
class RedeemCodeTierConfigAdmin(admin.ModelAdmin):
    list_display = ("min_submissions", "value_percent", "expiry_days")


@admin.register(ContributorBonusConfig)
class ContributorBonusConfigAdmin(admin.ModelAdmin):
    list_display = ("amount",)
