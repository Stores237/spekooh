from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    PaperUnlockViewSet,
    PaymentTransactionViewSet,
    SubscribeView,
    SubscriptionViewSet,
    UnlockPaperView,
)

app_name = "payments"

router = DefaultRouter()
router.register("transactions", PaymentTransactionViewSet, basename="transaction")
router.register("subscriptions", SubscriptionViewSet, basename="subscription")
router.register("unlocks", PaperUnlockViewSet, basename="unlock")

urlpatterns = [
    path("subscribe/", SubscribeView.as_view(), name="subscribe"),
    path("unlock/", UnlockPaperView.as_view(), name="unlock"),
    path("", include(router.urls)),
]
