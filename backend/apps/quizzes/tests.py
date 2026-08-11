import datetime

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory

from .factories import QuizAttemptFactory, QuizFactory, QuizQuestionFactory
from .models import Quiz, QuizAttempt
from .services import QuizError, current_streak, submit_attempt


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_quizzes_were_seeded_by_migration():
    assert Quiz.objects.count() == 5
    daily = Quiz.objects.get(is_daily_challenge=True)
    assert daily.title == "Group VII the Halogens Quiz"
    biology = Quiz.objects.get(title="Biology quiz")
    assert biology.question_count == 3


@pytest.mark.django_db
def test_list_endpoint_is_public(api_client):
    response = api_client.get("/api/quizzes/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert response.status_code == 200
    assert len(rows) == 5


@pytest.mark.django_db
def test_daily_challenge_endpoint(api_client):
    response = api_client.get("/api/quizzes/daily_challenge/")
    assert response.status_code == 200
    assert response.data["is_daily_challenge"] is True


@pytest.mark.django_db
def test_detail_endpoint_returns_real_questions_per_quiz(api_client):
    quiz = Quiz.objects.get(title="Biology quiz")
    response = api_client.get(f"/api/quizzes/{quiz.id}/")
    assert response.status_code == 200
    assert len(response.data["questions"]) == 3
    # Correct answer index is exposed (documented simplification — see model docstring).
    assert "correct_choice_index" not in response.data["questions"][0]


@pytest.mark.django_db
def test_submit_scores_correctly():
    quiz = QuizFactory()
    QuizQuestionFactory(quiz=quiz, order=0, correct_choice_index=1)
    QuizQuestionFactory(quiz=quiz, order=1, correct_choice_index=2)
    user = UserFactory()

    attempt = submit_attempt(quiz=quiz, user=user, answers=[1, 0])

    assert attempt.score == 1
    quiz.refresh_from_db()
    assert quiz.played_count == 1


@pytest.mark.django_db
def test_submit_rejects_quiz_with_no_questions():
    quiz = QuizFactory()
    with pytest.raises(QuizError):
        submit_attempt(quiz=quiz, user=UserFactory(), answers=[])


@pytest.mark.django_db
def test_submit_endpoint_requires_authentication(api_client):
    quiz = QuizFactory()
    QuizQuestionFactory(quiz=quiz)
    response = api_client.post(f"/api/quizzes/{quiz.id}/submit/", {"answers": [0]}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_submit_endpoint_end_to_end(api_client):
    quiz = QuizFactory()
    QuizQuestionFactory(quiz=quiz, correct_choice_index=1)
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post(f"/api/quizzes/{quiz.id}/submit/", {"answers": [1]}, format="json")
    assert response.status_code == 201
    assert response.data["score"] == 1
    assert QuizAttempt.objects.filter(quiz=quiz, user=user).exists()


@pytest.mark.django_db
def test_leaderboard_ranks_by_quizzes_played(api_client):
    top_user = UserFactory(name="Top Player")
    QuizAttemptFactory(user=top_user, quiz=QuizFactory())
    QuizAttemptFactory(user=top_user, quiz=QuizFactory())
    low_user = UserFactory(name="Low Player")
    QuizAttemptFactory(user=low_user, quiz=QuizFactory())

    response = api_client.get("/api/quizzes/leaderboard/")
    assert response.status_code == 200
    names = [row["name"] for row in response.data]
    assert names[0] == "Top Player"
    assert response.data[0]["quizzes_played"] == 2


@pytest.mark.django_db
def test_my_stats_endpoint_counts_own_attempts(api_client):
    user = UserFactory()
    QuizAttemptFactory(user=user)
    QuizAttemptFactory(user=user)
    QuizAttemptFactory(user=UserFactory())
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/quizzes/my_stats/")
    assert response.status_code == 200
    assert response.data["quizzes_played"] == 2


@pytest.mark.django_db
def test_streak_counts_consecutive_daily_challenge_days_ending_today():
    user = UserFactory()
    daily_quiz = QuizFactory(is_daily_challenge=True)
    today = timezone.localdate()
    for offset in (0, 1, 2):
        QuizAttemptFactory(
            user=user, quiz=daily_quiz,
            completed_at=timezone.make_aware(datetime.datetime.combine(today - datetime.timedelta(days=offset), datetime.time(12, 0))),
        )
    assert current_streak(user) == 3


@pytest.mark.django_db
def test_streak_still_counts_when_today_not_yet_played():
    user = UserFactory()
    daily_quiz = QuizFactory(is_daily_challenge=True)
    yesterday = timezone.localdate() - datetime.timedelta(days=1)
    QuizAttemptFactory(
        user=user, quiz=daily_quiz,
        completed_at=timezone.make_aware(datetime.datetime.combine(yesterday, datetime.time(12, 0))),
    )
    assert current_streak(user) == 1


@pytest.mark.django_db
def test_streak_breaks_on_a_gap():
    user = UserFactory()
    daily_quiz = QuizFactory(is_daily_challenge=True)
    today = timezone.localdate()
    QuizAttemptFactory(
        user=user, quiz=daily_quiz,
        completed_at=timezone.make_aware(datetime.datetime.combine(today, datetime.time(12, 0))),
    )
    QuizAttemptFactory(
        user=user, quiz=daily_quiz,
        completed_at=timezone.make_aware(datetime.datetime.combine(today - datetime.timedelta(days=3), datetime.time(12, 0))),
    )
    assert current_streak(user) == 1


@pytest.mark.django_db
def test_streak_ignores_non_daily_challenge_attempts():
    user = UserFactory()
    QuizAttemptFactory(user=user, quiz=QuizFactory(is_daily_challenge=False))
    assert current_streak(user) == 0


@pytest.mark.django_db
def test_streak_endpoint_requires_auth(api_client):
    response = api_client.get("/api/quizzes/streak/")
    assert response.status_code == 401


@pytest.mark.django_db
def test_streak_endpoint_returns_real_count(api_client):
    user = UserFactory()
    daily_quiz = QuizFactory(is_daily_challenge=True)
    QuizAttemptFactory(
        user=user, quiz=daily_quiz,
        completed_at=timezone.make_aware(datetime.datetime.combine(timezone.localdate(), datetime.time(12, 0))),
    )
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/quizzes/streak/")
    assert response.status_code == 200
    assert response.data["current_streak"] == 1
    assert response.data["played_today"] is True
