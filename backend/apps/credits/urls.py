from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CreditLedgerEntryViewSet,
    RedeemCodeApplyView,
    RedeemCodeViewSet,
)

app_name = "credits"

router = DefaultRouter()
router.register("ledger", CreditLedgerEntryViewSet, basename="ledger")
router.register("redeem-codes", RedeemCodeViewSet, basename="redeemcode")

urlpatterns = [
    path("redeem-codes/apply/", RedeemCodeApplyView.as_view(), name="redeemcode-apply"),
    path("", include(router.urls)),
]
