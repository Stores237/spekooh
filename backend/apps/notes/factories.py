import factory

from apps.papers.factories import ExamCategoryFactory, SubjectFactory

from .models import Note


class NoteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Note

    title = factory.Sequence(lambda n: f"Note {n}")
    subtitle = "Physics · Secondary"
    subject = factory.SubFactory(SubjectFactory)
    level = factory.SubFactory(ExamCategoryFactory)
    body = "Placeholder body text for tests."
