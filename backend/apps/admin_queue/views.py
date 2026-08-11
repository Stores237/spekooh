from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import mixins, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import AdminFlagQueue
from .serializers import AdminFlagQueueSerializer, ResolveFlagSerializer
from .services import resolve


class AdminFlagQueueViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [permissions.IsAdminUser]
    queryset = AdminFlagQueue.objects.all()
    serializer_class = AdminFlagQueueSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ["status", "category"]

    @action(detail=True, methods=["post"])
    def resolve(self, request, pk=None):
        flag_entry = self.get_object()
        serializer = ResolveFlagSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        resolved = resolve(flag_entry, resolved_by=request.user, notes=serializer.validated_data["notes"])
        return Response(AdminFlagQueueSerializer(resolved).data)
