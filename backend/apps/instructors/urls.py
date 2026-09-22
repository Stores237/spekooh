from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    InstructorRequestViewSet,
    InstructorWebhookView,
    MergeAndPublishView,
    PartnerCategoryListView,
    PartnerEarningsView,
    PartnerPaperLinkView,
    RouteToInstructorView,
)

app_name = "instructors"

router = DefaultRouter()
router.register("requests", InstructorRequestViewSet, basename="request")

urlpatterns = [
    path("papers/<int:paper_id>/route/", RouteToInstructorView.as_view(), name="route"),
    path("papers/<int:paper_id>/merge-and-publish/", MergeAndPublishView.as_view(), name="merge-and-publish"),
    path("webhook/", InstructorWebhookView.as_view(), name="webhook"),
    path("partner/paper-link/", PartnerPaperLinkView.as_view(), name="partner-paper-link"),
    path("partner/earnings/", PartnerEarningsView.as_view(), name="partner-earnings"),
    path("partner/categories/", PartnerCategoryListView.as_view(), name="partner-categories"),
    path("", include(router.urls)),
]
