from rest_framework.routers import DefaultRouter

from django.urls import include, path

from .views import CreditLedgerEntryViewSet, RedeemCodeApplyView, RedeemCodeIssueView, RedeemCodeViewSet

app_name = "credits"

router = DefaultRouter()
router.register("ledger", CreditLedgerEntryViewSet, basename="ledger")
router.register("redeem-codes", RedeemCodeViewSet, basename="redeemcode")

urlpatterns = [
    path("redeem-codes/apply/", RedeemCodeApplyView.as_view(), name="redeemcode-apply"),
    path("redeem-codes/issue/", RedeemCodeIssueView.as_view(), name="redeemcode-issue"),
    path("", include(router.urls)),
]
