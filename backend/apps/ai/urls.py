from django.urls import path

from .views import PaperSummaryView

app_name = "ai"

urlpatterns = [
    path("papers/<int:pk>/summary/", PaperSummaryView.as_view(), name="paper-summary"),
]
