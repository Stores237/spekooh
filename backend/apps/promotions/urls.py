from django.urls import path

from .views import ActivePromotionsView

app_name = "promotions"

urlpatterns = [
    path("active/", ActivePromotionsView.as_view(), name="active"),
]
