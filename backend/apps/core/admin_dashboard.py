"""
Feeds the real ops-queue widgets shown on the Django admin index page.
Referenced by settings.UNFOLD["DASHBOARD_CALLBACK"]. Every number here is a
direct DB aggregate against the same models/status enums the rest of the
app already uses — nothing here is illustrative or placeholder data.
"""

from datetime import timedelta
from urllib.parse import urlencode

from django.db.models import Count, Sum
from django.urls import reverse
from django.utils import timezone


def _changelist_url(model, **params):
    url = reverse(f"admin:{model._meta.app_label}_{model._meta.model_name}_changelist")
    if params:
        url += "?" + urlencode(params)
    return url


def dashboard_callback(request, context):
    from apps.admin_queue.models import AdminFlagQueue, FlagStatus
    from apps.credits.models import RedeemCode, RedeemCodeStatus
    from apps.instructors.models import (
        InstructorRequest,
        InstructorRequestStatus,
        WithdrawalRequest,
        WithdrawalStatus,
    )
    from apps.papers.models import PaperStatus, PaperSubmission
    from apps.payments.models import (
        PaymentTransaction,
        PaymentTransactionStatus,
        Subscription,
        SubscriptionStatus,
    )

    now = timezone.now()

    papers_funnel = [
        {
            "label": label,
            "count": PaperSubmission.objects.filter(status=value).count(),
            "url": _changelist_url(PaperSubmission, status=value),
        }
        for value, label in PaperStatus.choices
    ]

    # "Open" here means not yet resolved (NEW or IN_PROGRESS) — the ticket
    # queue (spec §2.1) has three states now, not just open/resolved.
    open_flags = AdminFlagQueue.objects.exclude(status=FlagStatus.RESOLVED)
    flags_by_category = list(
        open_flags.values("category").annotate(count=Count("id")).order_by("-count")
    )

    revenue_by_purpose = list(
        PaymentTransaction.objects.filter(status=PaymentTransactionStatus.SUCCESS)
        .values("purpose")
        .annotate(total=Sum("amount_fcfa"))
        .order_by("-total")
    )

    context["spekooh_dashboard"] = {
        "papers_funnel": papers_funnel,
        "open_flags_count": open_flags.count(),
        "flags_by_category": flags_by_category,
        "flags_url": _changelist_url(AdminFlagQueue),
        "pending_instructor_requests": InstructorRequest.objects.filter(
            status=InstructorRequestStatus.PENDING
        ).count(),
        "overdue_instructor_requests": InstructorRequest.objects.filter(
            status=InstructorRequestStatus.PENDING, responds_by__lt=now
        ).count(),
        "instructor_requests_url": _changelist_url(
            InstructorRequest, status=InstructorRequestStatus.PENDING
        ),
        "pending_withdrawals": WithdrawalRequest.objects.filter(
            status=WithdrawalStatus.PENDING
        ).count(),
        "withdrawals_url": _changelist_url(WithdrawalRequest, status=WithdrawalStatus.PENDING),
        "active_redeem_codes": RedeemCode.objects.filter(status=RedeemCodeStatus.ACTIVE).count(),
        "stale_redeem_codes": RedeemCode.objects.filter(
            status=RedeemCodeStatus.ACTIVE, expires_at__lt=now
        ).count(),
        "redeem_codes_url": _changelist_url(RedeemCode, status=RedeemCodeStatus.ACTIVE),
        "failed_transactions_7d": PaymentTransaction.objects.filter(
            status=PaymentTransactionStatus.FAILED, created_at__gte=now - timedelta(days=7)
        ).count(),
        "failed_transactions_url": _changelist_url(
            PaymentTransaction, status=PaymentTransactionStatus.FAILED
        ),
        "revenue_by_purpose": revenue_by_purpose,
        "expiring_subscriptions_7d": Subscription.objects.filter(
            status=SubscriptionStatus.ACTIVE, renews_at__lte=now + timedelta(days=7)
        ).count(),
        "subscriptions_url": _changelist_url(Subscription, status=SubscriptionStatus.ACTIVE),
    }
    return context
