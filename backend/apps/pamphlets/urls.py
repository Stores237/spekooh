from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import IssueQrView, PamphletOrderViewSet, PamphletViewSet, PlacePamphletOrderView

app_name = "pamphlets"

router = DefaultRouter()
router.register("catalog", PamphletViewSet, basename="pamphlet")
router.register("orders", PamphletOrderViewSet, basename="order")

urlpatterns = [
    path("orders/place/", PlacePamphletOrderView.as_view(), name="order-place"),
    path("orders/<int:order_id>/issue-qr/", IssueQrView.as_view(), name="order-issue-qr"),
    path("", include(router.urls)),
]
