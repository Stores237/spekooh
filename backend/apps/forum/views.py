from django.db.models import Count
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import ForumPost, ForumReply, ForumUpvote
from .serializers import (
    ForumPostCreateSerializer,
    ForumPostListSerializer,
    ForumReplyCreateSerializer,
    ForumReplySerializer,
)


class ForumPostViewSet(
    mixins.ListModelMixin, mixins.RetrieveModelMixin, mixins.CreateModelMixin, viewsets.GenericViewSet
):
    def get_permissions(self):
        if self.action == "create" or self.action in ("reply", "upvote"):
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        return ForumPost.objects.select_related("author").annotate(
            reply_count=Count("replies", distinct=True),
            upvote_count=Count("upvotes", distinct=True),
        )

    def get_serializer_class(self):
        if self.action == "create":
            return ForumPostCreateSerializer
        return ForumPostListSerializer

    @action(detail=True, methods=["get", "post"])
    def replies(self, request, pk=None):
        post = self.get_object()
        if request.method == "GET":
            return Response(ForumReplySerializer(post.replies.select_related("author"), many=True).data)

        serializer = ForumReplyCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reply = ForumReply.objects.create(post=post, author=request.user, **serializer.validated_data)
        return Response(ForumReplySerializer(reply).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def upvote(self, request, pk=None):
        post = self.get_object()
        upvote, created = ForumUpvote.objects.get_or_create(post=post, user=request.user)
        if not created:
            upvote.delete()
        return Response({"has_upvoted": created})
