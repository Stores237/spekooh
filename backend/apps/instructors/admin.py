from django.contrib import admin

from .models import (
    InstructorCreditLedger,
    InstructorMarkingGuide,
    InstructorProfileCache,
    InstructorRequest,
    InstructorSubjectQueue,
    PartnerCredential,
    WithdrawalRequest,
)


@admin.register(InstructorProfileCache)
class InstructorProfileCacheAdmin(admin.ModelAdmin):
    list_display = ("instructor_id", "display_name", "email")
    search_fields = ("instructor_id", "display_name", "email")


@admin.register(InstructorSubjectQueue)
class InstructorSubjectQueueAdmin(admin.ModelAdmin):
    list_display = ("subject", "instructor_id", "priority_order", "active")
    list_filter = ("subject", "active")
    ordering = ("subject", "priority_order")


@admin.register(InstructorRequest)
class InstructorRequestAdmin(admin.ModelAdmin):
    list_display = ("paper", "instructor_id", "status", "sent_at", "responds_by", "guide_deadline")
    list_filter = ("status",)
    readonly_fields = ("sent_at", "responded_at")


@admin.register(InstructorMarkingGuide)
class InstructorMarkingGuideAdmin(admin.ModelAdmin):
    list_display = ("paper", "instructor_id", "submitted_at")


@admin.register(InstructorCreditLedger)
class InstructorCreditLedgerAdmin(admin.ModelAdmin):
    list_display = ("instructor_id", "paper", "amount", "created_at")
    search_fields = ("instructor_id",)


@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    list_display = ("instructor_id", "amount", "payout_method", "status", "kyc_status", "created_at")
    list_filter = ("status", "kyc_status")


@admin.register(PartnerCredential)
class PartnerCredentialAdmin(admin.ModelAdmin):
    list_display = ("partner_id", "is_active")
