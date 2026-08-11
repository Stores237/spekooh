import factory

from .models import Note


class NoteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Note

    title = factory.Sequence(lambda n: f"Note {n}")
    subtitle = "Physics · O Level"
