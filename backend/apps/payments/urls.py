from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    PaperDownloadUnlockViewSet,
    PaperUnlockViewSet,
    PaymentTransactionViewSet,
    SubscribeView,
    SubscriptionViewSet,
    UnlockPaperDownloadView,
    UnlockPaperView,
)

app_name = "payments"

router = DefaultRouter()
router.register("transactions", PaymentTransactionViewSet, basename="transaction")
router.register("subscriptions", SubscriptionViewSet, basename="subscription")
router.register("unlocks", PaperUnlockViewSet, basename="unlock")
router.register("download-unlocks", PaperDownloadUnlockViewSet, basename="download-unlock")

urlpatterns = [
    path("subscribe/", SubscribeView.as_view(), name="subscribe"),
    path("unlock/", UnlockPaperView.as_view(), name="unlock"),
    path("unlock-download/", UnlockPaperDownloadView.as_view(), name="unlock-download"),
    path("", include(router.urls)),
]
