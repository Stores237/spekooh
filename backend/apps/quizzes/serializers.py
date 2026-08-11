from rest_framework import serializers

from .models import Quiz, QuizAttempt, QuizQuestion


class QuizListSerializer(serializers.ModelSerializer):
    question_count = serializers.ReadOnlyField()

    class Meta:
        model = Quiz
        fields = ["id", "title", "subtitle", "subject", "question_count", "suggested_time_seconds", "played_count", "is_daily_challenge"]


class QuizQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizQuestion
        fields = ["id", "text", "choices", "order"]


class QuizDetailSerializer(serializers.ModelSerializer):
    question_count = serializers.ReadOnlyField()
    questions = QuizQuestionSerializer(many=True, read_only=True)

    class Meta:
        model = Quiz
        fields = [
            "id",
            "title",
            "subtitle",
            "subject",
            "question_count",
            "suggested_time_seconds",
            "played_count",
            "is_daily_challenge",
            "questions",
        ]


class SubmitAttemptRequestSerializer(serializers.Serializer):
    answers = serializers.ListField(child=serializers.IntegerField())


class QuizAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizAttempt
        fields = ["id", "quiz", "score", "completed_at"]
        read_only_fields = fields


class LeaderboardEntrySerializer(serializers.Serializer):
    name = serializers.CharField()
    rank = serializers.IntegerField()
    quizzes_played = serializers.IntegerField()
