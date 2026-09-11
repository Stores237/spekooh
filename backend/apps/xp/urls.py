from django.urls import path

from .views import RedeemSlotBonusView

app_name = "xp"

urlpatterns = [
    path("redeem-slot-bonus/", RedeemSlotBonusView.as_view(), name="redeem-slot-bonus"),
]
