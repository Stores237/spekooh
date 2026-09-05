from django.urls import path

from .views import PaperChatView, PaperSummaryView

app_name = "ai"

urlpatterns = [
    path("papers/<int:pk>/summary/", PaperSummaryView.as_view(), name="paper-summary"),
    path("papers/<int:pk>/chat/", PaperChatView.as_view(), name="paper-chat"),
]
