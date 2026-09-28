from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import mixins, permissions, viewsets

from .models import Note
from .serializers import NoteDetailSerializer, NoteSerializer


class NoteViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Note.objects.all()
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["subject_title", "academic_level"]

    def get_serializer_class(self):
        return NoteDetailSerializer if self.action == "retrieve" else NoteSerializer
