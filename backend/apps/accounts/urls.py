from django.urls import path

from .views import GuestView, LoginView, MeView, RefreshView, RegisterView

app_name = "accounts"

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", RefreshView.as_view(), name="refresh"),
    path("guest/", GuestView.as_view(), name="guest"),
    path("me/", MeView.as_view(), name="me"),
]
