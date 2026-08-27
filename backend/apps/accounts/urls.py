from django.urls import path

from .views import (
    EmailVerificationConfirmByEmailView,
    EmailVerificationConfirmView,
    EmailVerificationRequestByEmailView,
    EmailVerificationResendView,
    GuestView,
    LoginView,
    MeView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RefreshView,
    RegisterView,
)

app_name = "accounts"

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", RefreshView.as_view(), name="refresh"),
    path("guest/", GuestView.as_view(), name="guest"),
    path("me/", MeView.as_view(), name="me"),
    path("password-reset/", PasswordResetRequestView.as_view(), name="password-reset"),
    path("password-reset/confirm/", PasswordResetConfirmView.as_view(), name="password-reset-confirm"),
    path("verify-email/", EmailVerificationConfirmView.as_view(), name="verify-email"),
    path("verify-email/resend/", EmailVerificationResendView.as_view(), name="verify-email-resend"),
    # Unauthenticated recovery path — see EmailVerificationRequestByEmailSerializer's
    # docstring for why this exists alongside the authenticated pair above.
    path("verify-email/request-by-email/", EmailVerificationRequestByEmailView.as_view(), name="verify-email-request-by-email"),
    path("verify-email/confirm-by-email/", EmailVerificationConfirmByEmailView.as_view(), name="verify-email-confirm-by-email"),
]
