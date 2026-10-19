import django_filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import mixins, permissions, viewsets

from .models import Note
from .serializers import NoteDetailSerializer, NoteSerializer


class NoteFilter(django_filters.FilterSet):
    """Keeps the same query params (subject_title, academic_level) the app's
    public API always had, now resolved against the real Subject/ExamCategory
    FKs underneath rather than a free-text column."""

    subject_title = django_filters.CharFilter(field_name="subject__title", lookup_expr="exact")
    academic_level = django_filters.CharFilter(field_name="level__title", lookup_expr="exact")

    class Meta:
        model = Note
        fields = ["subject_title", "academic_level"]


class NoteViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = Note.objects.all()
    filter_backends = [DjangoFilterBackend]
    filterset_class = NoteFilter

    def get_serializer_class(self):
        return NoteDetailSerializer if self.action == "retrieve" else NoteSerializer
