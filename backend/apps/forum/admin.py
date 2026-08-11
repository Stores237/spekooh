from django.contrib import admin

from .models import ForumPost, ForumReply, ForumUpvote


@admin.register(ForumPost)
class ForumPostAdmin(admin.ModelAdmin):
    list_display = ("title", "author", "tag", "created_at")
    list_filter = ("tag",)
    search_fields = ("title", "body", "author__email")


@admin.register(ForumReply)
class ForumReplyAdmin(admin.ModelAdmin):
    list_display = ("post", "author", "created_at")


@admin.register(ForumUpvote)
class ForumUpvoteAdmin(admin.ModelAdmin):
    list_display = ("post", "user", "created_at")
