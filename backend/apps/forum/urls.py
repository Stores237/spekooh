from rest_framework.routers import DefaultRouter

from .views import ForumPostViewSet

app_name = "forum"

router = DefaultRouter()
router.register("posts", ForumPostViewSet, basename="post")

urlpatterns = router.urls
