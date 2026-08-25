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
    user = request.user

    # Role-gated: each flag mirrors the real model permission a role needs
    # to click through to the underlying records — a widget summarizing a
    # model nobody in this role can open is itself a data leak (aggregate
    # counts are still real information, e.g. "6 open flags" tells a
    # Support agent something about Review Team's queue they have no
    # access to). Query each section's data only when it'll actually be
    # shown, not just gate it in the template.
    can_view_papers = user.has_perm("papers.view_papersubmission")
    can_view_admin_queue = user.has_perm("admin_queue.view_adminflagqueue")
    can_view_instructor_requests = user.has_perm("instructors.view_instructorrequest")
    can_view_withdrawals = user.has_perm("instructors.view_withdrawalrequest")
    can_view_credits = user.has_perm("credits.view_redeemcode")
    can_view_transactions = user.has_perm("payments.view_paymenttransaction")
    can_view_subscriptions = user.has_perm("payments.view_subscription")

    dashboard = {
        "can_view_papers": can_view_papers,
        "can_view_admin_queue": can_view_admin_queue,
        "can_view_instructor_requests": can_view_instructor_requests,
        "can_view_withdrawals": can_view_withdrawals,
        "can_view_credits": can_view_credits,
        "can_view_transactions": can_view_transactions,
        "can_view_subscriptions": can_view_subscriptions,
    }

    if can_view_papers:
        dashboard["papers_funnel"] = [
            {
                "label": label,
                "count": PaperSubmission.objects.filter(status=value).count(),
                "url": _changelist_url(PaperSubmission, status=value),
            }
            for value, label in PaperStatus.choices
        ]

    if can_view_admin_queue:
        # "Open" here means not yet resolved (NEW or IN_PROGRESS) — the
        # ticket queue (spec §2.1) has three states, not just open/resolved.
        open_flags = AdminFlagQueue.objects.exclude(status=FlagStatus.RESOLVED)
        dashboard["open_flags_count"] = open_flags.count()
        dashboard["flags_by_category"] = list(
            open_flags.values("category").annotate(count=Count("id")).order_by("-count")
        )
        dashboard["flags_url"] = _changelist_url(AdminFlagQueue)

    if can_view_instructor_requests:
        dashboard["pending_instructor_requests"] = InstructorRequest.objects.filter(
            status=InstructorRequestStatus.PENDING
        ).count()
        dashboard["overdue_instructor_requests"] = InstructorRequest.objects.filter(
            status=InstructorRequestStatus.PENDING, responds_by__lt=now
        ).count()
        dashboard["instructor_requests_url"] = _changelist_url(
            InstructorRequest, status=InstructorRequestStatus.PENDING
        )

    if can_view_withdrawals:
        dashboard["pending_withdrawals"] = WithdrawalRequest.objects.filter(
            status=WithdrawalStatus.PENDING
        ).count()
        dashboard["withdrawals_url"] = _changelist_url(WithdrawalRequest, status=WithdrawalStatus.PENDING)

    if can_view_credits:
        dashboard["active_redeem_codes"] = RedeemCode.objects.filter(status=RedeemCodeStatus.ACTIVE).count()
        dashboard["stale_redeem_codes"] = RedeemCode.objects.filter(
            status=RedeemCodeStatus.ACTIVE, expires_at__lt=now
        ).count()
        dashboard["redeem_codes_url"] = _changelist_url(RedeemCode, status=RedeemCodeStatus.ACTIVE)

    if can_view_transactions:
        dashboard["failed_transactions_7d"] = PaymentTransaction.objects.filter(
            status=PaymentTransactionStatus.FAILED, created_at__gte=now - timedelta(days=7)
        ).count()
        dashboard["failed_transactions_url"] = _changelist_url(
            PaymentTransaction, status=PaymentTransactionStatus.FAILED
        )
        dashboard["revenue_by_purpose"] = list(
            PaymentTransaction.objects.filter(status=PaymentTransactionStatus.SUCCESS)
            .values("purpose")
            .annotate(total=Sum("amount_fcfa"))
            .order_by("-total")
        )

    if can_view_subscriptions:
        dashboard["expiring_subscriptions_7d"] = Subscription.objects.filter(
            status=SubscriptionStatus.ACTIVE, renews_at__lte=now + timedelta(days=7)
        ).count()
        dashboard["subscriptions_url"] = _changelist_url(Subscription, status=SubscriptionStatus.ACTIVE)

    context["spekooh_dashboard"] = dashboard
    return context
