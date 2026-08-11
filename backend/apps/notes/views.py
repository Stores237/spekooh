from rest_framework import mixins, permissions, viewsets

from .models import Note
from .serializers import NoteSerializer


class NoteViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Note.objects.all()
    serializer_class = NoteSerializer
