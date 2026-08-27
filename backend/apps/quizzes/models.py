from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class Quiz(TimeStampedModel):
    """
    Speculative — no Question/Attempt/Score model existed anywhere before
    this. Answers are visible in the detail payload before submission (no
    anti-cheat); acceptable for this non-spec'd, deferred (P2) feature, not
    silently shipped as if secure.
    """

    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    subject = models.ForeignKey("papers.Subject", on_delete=models.SET_NULL, null=True, blank=True, related_name="quizzes")
    suggested_time_seconds = models.PositiveIntegerField(default=480)
    is_daily_challenge = models.BooleanField(default=False)
    played_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["title"]
        verbose_name_plural = "quizzes"

    def __str__(self):
        return self.title

    @property
    def question_count(self) -> int:
        return self.questions.count()


class QuizQuestion(TimeStampedModel):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name="questions")
    text = models.TextField()
    choices = models.JSONField(default=list)
    correct_choice_index = models.PositiveSmallIntegerField()
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return self.text[:60]


class QuizAttempt(TimeStampedModel):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name="attempts")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="quiz_attempts")
    answers = models.JSONField(help_text="List of chosen choice indices, in question order.")
    score = models.PositiveIntegerField()
    completed_at = models.DateTimeField()

    class Meta:
        ordering = ["-completed_at"]

    def __str__(self):
        return f"{self.user}, {self.quiz}, {self.score}"
