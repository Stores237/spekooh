from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import MarkAllReadView, NotificationViewSet

app_name = "notifications"

router = DefaultRouter()
router.register("", NotificationViewSet, basename="notification")

urlpatterns = [
    path("mark-all-read/", MarkAllReadView.as_view(), name="mark-all-read"),
    path("", include(router.urls)),
]
