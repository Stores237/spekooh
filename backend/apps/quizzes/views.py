from django.contrib.auth import get_user_model
from django.db.models import Count
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Quiz
from .serializers import (
    LeaderboardEntrySerializer,
    QuizAttemptSerializer,
    QuizDetailSerializer,
    QuizListSerializer,
    SubmitAttemptRequestSerializer,
)
from .services import QuizError, current_streak, submit_attempt


class QuizViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Quiz.objects.all()

    def get_serializer_class(self):
        if self.action == "retrieve":
            return QuizDetailSerializer
        return QuizListSerializer

    @extend_schema(responses=QuizDetailSerializer)
    @action(detail=False, methods=["get"])
    def daily_challenge(self, request):
        quiz = Quiz.objects.filter(is_daily_challenge=True).first()
        if quiz is None:
            return Response({"detail": "No daily challenge configured."}, status=status.HTTP_404_NOT_FOUND)
        return Response(QuizDetailSerializer(quiz).data)

    @extend_schema(responses=LeaderboardEntrySerializer(many=True))
    @action(detail=False, methods=["get"])
    def leaderboard(self, request):
        User = get_user_model()
        top_users = (
            User.objects.filter(quiz_attempts__isnull=False)
            .annotate(quizzes_played=Count("quiz_attempts", distinct=True))
            .order_by("-quizzes_played")[:10]
        )
        entries = [
            {"name": user.name or user.email or str(user.id), "rank": i + 1, "quizzes_played": user.quizzes_played}
            for i, user in enumerate(top_users)
        ]
        return Response(LeaderboardEntrySerializer(entries, many=True).data)

    @extend_schema(request=SubmitAttemptRequestSerializer, responses=QuizAttemptSerializer)
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def submit(self, request, pk=None):
        quiz = self.get_object()
        serializer = SubmitAttemptRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            attempt = submit_attempt(quiz=quiz, user=request.user, answers=serializer.validated_data["answers"])
        except QuizError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(QuizAttemptSerializer(attempt).data, status=status.HTTP_201_CREATED)

    @extend_schema(responses=None)
    @action(detail=False, methods=["get"], permission_classes=[permissions.IsAuthenticated])
    def my_stats(self, request):
        return Response({"quizzes_played": request.user.quiz_attempts.count()})

    @extend_schema(responses=None)
    @action(detail=False, methods=["get"], permission_classes=[permissions.IsAuthenticated])
    def streak(self, request):
        played_today = request.user.quiz_attempts.filter(
            quiz__is_daily_challenge=True, completed_at__date=timezone.localdate()
        ).exists()
        return Response({"current_streak": current_streak(request.user), "played_today": played_today})
