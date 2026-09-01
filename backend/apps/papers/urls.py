from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdWatchView,
    ExamCategoryViewSet,
    ExamTypeViewSet,
    PaperSubmissionViewSet,
    SubjectViewSet,
)

app_name = "papers"

router = DefaultRouter()
router.register("categories", ExamCategoryViewSet, basename="category")
router.register("exam-types", ExamTypeViewSet, basename="examtype")
router.register("subjects", SubjectViewSet, basename="subject")
router.register("submissions", PaperSubmissionViewSet, basename="submission")

urlpatterns = [
    path("ad-watch/", AdWatchView.as_view(), name="ad-watch"),
    path("", include(router.urls)),
]
