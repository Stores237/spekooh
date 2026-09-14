from django.db.models import Count
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAuthenticatedNotGuest

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
        if self.action in ("create", "upvote"):
            return [IsAuthenticatedNotGuest()]
        # `replies` handles GET (read, open to everyone) and POST
        # (posting a reply, gated) in one action — see the method below
        # for the POST-only check, since get_permissions only sees the
        # action name, not the HTTP method.
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

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        # ForumPostCreateSerializer only writes {id, tag, title, body} — the
        # app's ForumPost model requires created_at/author_name/reply_count/
        # upvote_count/has_upvoted to parse a post, so responding with the
        # write serializer's own data threw client-side on every real
        # submission (confirmed live, 2026-09-14 /design-review: server
        # returned 201, app showed "Something went wrong" and the question
        # was silently posted anyway). Re-read through get_queryset() so the
        # response carries the same annotated counts a list/detail view has.
        instance = self.get_queryset().get(pk=serializer.instance.pk)
        output_serializer = ForumPostListSerializer(instance, context=self.get_serializer_context())
        headers = self.get_success_headers(output_serializer.data)
        return Response(output_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    @action(detail=True, methods=["get", "post"])
    def replies(self, request, pk=None):
        post = self.get_object()
        if request.method == "GET":
            return Response(ForumReplySerializer(post.replies.select_related("author"), many=True).data)

        permission = IsAuthenticatedNotGuest()
        if not permission.has_permission(request, self):
            self.permission_denied(request, message=getattr(permission, "message", None))

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
