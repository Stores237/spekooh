from rest_framework.routers import DefaultRouter

from .views import AdminFlagQueueViewSet

app_name = "admin_queue"

router = DefaultRouter()
router.register("flags", AdminFlagQueueViewSet, basename="flag")

urlpatterns = router.urls
