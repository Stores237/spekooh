import factory
from django.utils import timezone

from .models import Quiz, QuizAttempt, QuizQuestion


class QuizFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Quiz

    title = factory.Sequence(lambda n: f"Quiz {n}")
    subtitle = "5 topics"


class QuizQuestionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = QuizQuestion

    quiz = factory.SubFactory(QuizFactory)
    text = "What is 2 + 2?"
    choices = ["3", "4", "5", "6"]
    correct_choice_index = 1
    order = 0


class QuizAttemptFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = QuizAttempt

    quiz = factory.SubFactory(QuizFactory)
    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    answers = [1]
    score = 1
    completed_at = factory.LazyFunction(timezone.now)
