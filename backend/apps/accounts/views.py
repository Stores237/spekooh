from drf_spectacular.utils import extend_schema
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.notifications.models import NotificationKind
from apps.notifications.services import notify

from . import services
from .models import User
from .serializers import (
    EmailTokenObtainPairSerializer,
    EmailVerificationConfirmSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserSerializer,
    tokens_for_user,
)


class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        notify(
            user=user,
            kind=NotificationKind.ONBOARDING,
            title="Welcome to Spekooh 🎉",
            body="Browse past papers, join the forum, and start earning credits for what you contribute.",
        )
        # Real verification code, sent for real (console backend today —
        # see TODOS.md) — this is what makes "verify your email" an actual
        # step in signup rather than nothing happening. Doesn't gate the
        # tokens below: see User.email_verified_at's docstring for why.
        services.send_verification_email(user)
        return Response(
            {"user": UserSerializer(user).data, **tokens_for_user(user)},
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    permission_classes = [permissions.AllowAny]
    serializer_class = EmailTokenObtainPairSerializer


class RefreshView(TokenRefreshView):
    permission_classes = [permissions.AllowAny]


class GuestView(APIView):
    """AllowAny + unauthenticated means nothing else rate-limits this —
    without a real throttle, scripting this endpoint mints unlimited real
    User rows (each a permanent DB row until the 24h prune job reaps it —
    see prune_stale_guest_accounts). Redis-backed so the counter survives
    across worker processes, not just one."""

    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "guest_mint"

    @extend_schema(request=None, responses=UserSerializer)
    def post(self, request):
        # Optional — e.g. a contributor without an account typed their real
        # name on Submit before it called this. Falls back to an
        # auto-generated "Guest xxxxxx" label when absent (see create_guest).
        user = User.objects.create_guest(name=request.data.get("name"))
        return Response(
            {"user": UserSerializer(user).data, **tokens_for_user(user)},
            status=status.HTTP_201_CREATED,
        )


class PasswordResetRequestView(APIView):
    """Rate-limited per IP (same idea as guest_mint) — otherwise this is a
    free email-bombing/enumeration oracle. Always returns 200 with the same
    generic body, real account or not (see PasswordResetRequestSerializer)."""

    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset_request"

    @extend_schema(request=PasswordResetRequestSerializer, responses=None)
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.issue_code_if_real_account()
        return Response({"detail": "If that email is registered, a reset code has been sent."})


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset_confirm"

    @extend_schema(request=PasswordResetConfirmSerializer, responses=None)
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "Password reset. Log in with your new password."})


class EmailVerificationConfirmView(APIView):
    """Authenticated (RegisterView already grants tokens at signup, so
    there's always a session to confirm from) — no email/enumeration
    concern to design around, unlike password reset."""

    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "email_verification_confirm"

    @extend_schema(request=EmailVerificationConfirmSerializer, responses=UserSerializer)
    def post(self, request):
        serializer = EmailVerificationConfirmSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data)


class EmailVerificationResendView(APIView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "email_verification_resend"

    @extend_schema(request=None, responses=None)
    def post(self, request):
        if request.user.email:
            services.send_verification_email(request.user)
        return Response({"detail": "A new code has been sent."})


class MeView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user
