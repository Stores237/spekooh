from rest_framework.routers import DefaultRouter

from .views import QuizViewSet

app_name = "quizzes"

router = DefaultRouter()
router.register("", QuizViewSet, basename="quiz")

urlpatterns = router.urls
