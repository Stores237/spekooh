import datetime

from django.db import transaction
from django.utils import timezone

from apps.core.exceptions import SafeMessageError

from .models import Quiz, QuizAttempt


class QuizError(SafeMessageError):
    pass


@transaction.atomic
def submit_attempt(*, quiz: Quiz, user, answers: list[int]) -> QuizAttempt:
    questions = list(quiz.questions.order_by("order"))
    if not questions:
        raise QuizError("This quiz has no questions.")

    score = sum(
        1
        for question, chosen in zip(questions, answers)
        if chosen == question.correct_choice_index
    )

    attempt = QuizAttempt.objects.create(
        quiz=quiz, user=user, answers=answers, score=score, completed_at=timezone.now()
    )
    Quiz.objects.filter(id=quiz.id).update(played_count=quiz.played_count + 1)
    return attempt


def current_streak(user) -> int:
    """
    Consecutive days (ending today or, if today hasn't been played yet,
    yesterday) with at least one completed daily-challenge attempt. Matches
    the Home screen's "N-day streak" — the only real activity that concept
    can be built on, since no other daily habit signal exists.
    """
    played_dates = set(
        QuizAttempt.objects.filter(user=user, quiz__is_daily_challenge=True)
        .values_list("completed_at__date", flat=True)
    )
    if not played_dates:
        return 0

    cursor = timezone.localdate()
    if cursor not in played_dates:
        cursor -= datetime.timedelta(days=1)

    streak = 0
    while cursor in played_dates:
        streak += 1
        cursor -= datetime.timedelta(days=1)
    return streak
