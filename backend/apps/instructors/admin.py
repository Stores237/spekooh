from django.contrib import admin, messages
from django.utils import timezone
from unfold.admin import ModelAdmin
from unfold.decorators import display

from .models import (
    InstructorCreditLedger,
    InstructorMarkingGuide,
    InstructorProfileCache,
    InstructorRequest,
    InstructorRequestStatus,
    InstructorSubjectQueue,
    PartnerCredential,
    WithdrawalRequest,
    WithdrawalStatus,
)

REQUEST_STATUS_LABELS = {
    InstructorRequestStatus.PENDING: "warning",
    InstructorRequestStatus.ACCEPTED: "info",
    InstructorRequestStatus.REJECTED: "danger",
    InstructorRequestStatus.TIMED_OUT: "danger",
}

WITHDRAWAL_STATUS_LABELS = {
    WithdrawalStatus.PENDING: "warning",
    WithdrawalStatus.APPROVED: "info",
    WithdrawalStatus.PAID: "success",
}


@admin.register(InstructorProfileCache)
class InstructorProfileCacheAdmin(ModelAdmin):
    list_display = ("instructor_id", "display_name", "email")
    search_fields = ("instructor_id", "display_name", "email")


@admin.register(InstructorSubjectQueue)
class InstructorSubjectQueueAdmin(ModelAdmin):
    list_display = ("subject", "instructor_id", "priority_order", "active")
    list_filter = ("subject", "active")
    ordering = ("subject", "priority_order")


@admin.register(InstructorRequest)
class InstructorRequestAdmin(ModelAdmin):
    list_display = ("paper", "instructor_id", "status_badge", "sla_countdown", "sent_at")
    list_filter = ("status",)
    readonly_fields = ("sent_at", "responded_at")
    ordering = ("status", "responds_by")

    @display(description="Status", label=REQUEST_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @display(description="SLA")
    def sla_countdown(self, obj):
        deadline = obj.guide_deadline if obj.status == InstructorRequestStatus.ACCEPTED else obj.responds_by
        if deadline is None or obj.status in (InstructorRequestStatus.REJECTED, InstructorRequestStatus.TIMED_OUT):
            return "—"
        remaining = deadline - timezone.now()
        if remaining.total_seconds() < 0:
            return f"Overdue by {abs(remaining.days)}d {abs(remaining.seconds) // 3600}h"
        return f"{remaining.days}d {remaining.seconds // 3600}h left"


@admin.register(InstructorMarkingGuide)
class InstructorMarkingGuideAdmin(ModelAdmin):
    list_display = ("paper", "instructor_id", "submitted_at")


@admin.register(InstructorCreditLedger)
class InstructorCreditLedgerAdmin(ModelAdmin):
    list_display = ("instructor_id", "paper", "amount", "created_at")
    search_fields = ("instructor_id",)


@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(ModelAdmin):
    list_display = ("instructor_id", "amount", "payout_method", "status_badge", "kyc_status", "created_at")
    list_filter = ("status", "kyc_status")
    ordering = ("status", "-created_at")
    actions = ["approve_selected", "mark_paid_selected"]

    @display(description="Status", label=WITHDRAWAL_STATUS_LABELS, ordering="status")
    def status_badge(self, obj):
        return obj.status

    @admin.action(description="Approve selected (pending → approved)")
    def approve_selected(self, request, queryset):
        updated = queryset.filter(status=WithdrawalStatus.PENDING).update(
            status=WithdrawalStatus.APPROVED, updated_at=timezone.now()
        )
        self.message_user(request, f"Approved {updated} withdrawal request(s).", level=messages.SUCCESS)

    @admin.action(description="Mark paid (approved → paid)")
    def mark_paid_selected(self, request, queryset):
        updated = queryset.filter(status=WithdrawalStatus.APPROVED).update(
            status=WithdrawalStatus.PAID, updated_at=timezone.now()
        )
        self.message_user(request, f"Marked {updated} withdrawal request(s) as paid.", level=messages.SUCCESS)


@admin.register(PartnerCredential)
class PartnerCredentialAdmin(ModelAdmin):
    list_display = ("partner_id", "is_active")
