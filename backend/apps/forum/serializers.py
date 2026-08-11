from rest_framework import serializers

from .models import ForumPost, ForumReply


class ForumReplySerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)

    class Meta:
        model = ForumReply
        fields = ["id", "post", "author", "author_name", "body", "created_at"]
        read_only_fields = ["id", "author", "author_name", "created_at"]


class ForumReplyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ForumReply
        fields = ["body"]


class ForumPostListSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)
    reply_count = serializers.IntegerField(read_only=True)
    upvote_count = serializers.IntegerField(read_only=True)
    has_upvoted = serializers.SerializerMethodField()

    class Meta:
        model = ForumPost
        fields = [
            "id",
            "author",
            "author_name",
            "tag",
            "title",
            "body",
            "reply_count",
            "upvote_count",
            "has_upvoted",
            "created_at",
        ]
        read_only_fields = ["id", "author", "author_name", "created_at"]

    def get_has_upvoted(self, obj) -> bool:
        request = self.context.get("request")
        if request is None or not request.user.is_authenticated:
            return False
        return obj.upvotes.filter(user=request.user).exists()


class ForumPostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ForumPost
        fields = ["id", "tag", "title", "body"]
        read_only_fields = ["id"]

    def create(self, validated_data):
        validated_data["author"] = self.context["request"].user
        return super().create(validated_data)
