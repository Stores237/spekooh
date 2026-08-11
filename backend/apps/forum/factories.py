import factory

from .models import ForumPost, ForumReply, ForumUpvote


class ForumPostFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ForumPost

    author = factory.SubFactory("apps.accounts.factories.UserFactory")
    tag = "Physics"
    title = "How do I approach this mechanics question?"
    body = "Stuck on a Newton's Laws problem from the 2023 paper."


class ForumReplyFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ForumReply

    post = factory.SubFactory(ForumPostFactory)
    author = factory.SubFactory("apps.accounts.factories.UserFactory")
    body = "Try drawing a free-body diagram first."


class ForumUpvoteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ForumUpvote

    post = factory.SubFactory(ForumPostFactory)
    user = factory.SubFactory("apps.accounts.factories.UserFactory")
