from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class ForumPost(TimeStampedModel):
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="forum_posts")
    tag = models.CharField(max_length=80)
    title = models.CharField(max_length=200)
    body = models.TextField()

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title


class ForumReply(TimeStampedModel):
    post = models.ForeignKey(ForumPost, on_delete=models.CASCADE, related_name="replies")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="forum_replies")
    body = models.TextField()

    class Meta:
        ordering = ["created_at"]
        verbose_name_plural = "forum replies"

    def __str__(self):
        return f"Reply to {self.post_id} by {self.author}"


class ForumUpvote(TimeStampedModel):
    post = models.ForeignKey(ForumPost, on_delete=models.CASCADE, related_name="upvotes")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="forum_upvotes")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["post", "user"], name="unique_upvote_per_user_per_post"),
        ]

    def __str__(self):
        return f"{self.user} upvoted {self.post_id}"
