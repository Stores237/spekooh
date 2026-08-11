from django.db import transaction
from django.utils import timezone

from .models import Quiz, QuizAttempt


class QuizError(Exception):
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
