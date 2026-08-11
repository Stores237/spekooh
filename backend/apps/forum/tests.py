import pytest
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory

from .factories import ForumPostFactory, ForumReplyFactory, ForumUpvoteFactory
from .models import ForumPost, ForumReply, ForumUpvote


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_list_posts_is_public_and_includes_counts(api_client):
    post = ForumPostFactory()
    ForumReplyFactory(post=post)
    ForumReplyFactory(post=post)
    ForumUpvoteFactory(post=post)

    response = api_client.get("/api/forum/posts/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = next(r for r in rows if r["id"] == post.id)
    assert row["reply_count"] == 2
    assert row["upvote_count"] == 1
    assert row["has_upvoted"] is False


@pytest.mark.django_db
def test_has_upvoted_reflects_requesting_user(api_client):
    user = UserFactory()
    post = ForumPostFactory()
    ForumUpvoteFactory(post=post, user=user)
    api_client.force_authenticate(user=user)
    response = api_client.get("/api/forum/posts/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = next(r for r in rows if r["id"] == post.id)
    assert row["has_upvoted"] is True


@pytest.mark.django_db
def test_create_post_requires_authentication(api_client):
    response = api_client.post("/api/forum/posts/", {"tag": "Biology", "title": "Q", "body": "B"}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_create_post_sets_author_from_request(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post(
        "/api/forum/posts/", {"tag": "Biology", "title": "Enzyme question", "body": "Help?"}, format="json"
    )
    assert response.status_code == 201
    post = ForumPost.objects.get(id=response.data["id"])
    assert post.author == user


@pytest.mark.django_db
def test_reply_endpoint_lists_and_creates(api_client):
    post = ForumPostFactory()
    ForumReplyFactory(post=post, body="First reply")
    user = UserFactory()
    api_client.force_authenticate(user=user)

    list_response = api_client.get(f"/api/forum/posts/{post.id}/replies/")
    assert list_response.status_code == 200
    assert len(list_response.data) == 1

    create_response = api_client.post(f"/api/forum/posts/{post.id}/replies/", {"body": "Second reply"}, format="json")
    assert create_response.status_code == 201
    assert ForumReply.objects.filter(post=post, author=user, body="Second reply").exists()


@pytest.mark.django_db
def test_upvote_action_toggles_idempotently(api_client):
    post = ForumPostFactory()
    user = UserFactory()
    api_client.force_authenticate(user=user)

    first = api_client.post(f"/api/forum/posts/{post.id}/upvote/")
    assert first.status_code == 200
    assert first.data["has_upvoted"] is True
    assert ForumUpvote.objects.filter(post=post, user=user).exists()

    second = api_client.post(f"/api/forum/posts/{post.id}/upvote/")
    assert second.data["has_upvoted"] is False
    assert not ForumUpvote.objects.filter(post=post, user=user).exists()
