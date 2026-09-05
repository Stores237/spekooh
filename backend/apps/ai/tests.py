import uuid
from unittest import mock

import pytest
from django.core.management import call_command
from django.test import override_settings
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.admin_queue.models import AdminFlagQueue, FlagCategory
from apps.papers.factories import PaperSubmissionFactory
from apps.papers.models import PaperStatus
from apps.payments.factories import SubscriptionFactory

from .models import ArtifactKind, ArtifactStatus, GeneratedArtifact
from .providers.base import AIRateLimited, AIRefused, AIResult, AIUnavailable
from .providers.groq import GroqProvider
from .quota import consume_chat_quota
from .services import (
    get_or_queue_artifact,
    run_pending_generation,
    send_chat_message,
    validate_chat_messages,
)


@pytest.fixture
def api_client():
    return APIClient()


def _published_paper(**kwargs):
    kwargs.setdefault("status", PaperStatus.PUBLISHED)
    kwargs.setdefault("ocr_text", "Question 1: Define photosynthesis. Question 2: ...")
    return PaperSubmissionFactory(**kwargs)


class TestGetOrQueueArtifact:
    @pytest.mark.django_db
    def test_creates_a_real_pending_row_the_first_time(self):
        paper = _published_paper()
        artifact, is_ready = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        assert is_ready is False
        assert artifact.status == ArtifactStatus.PENDING
        assert GeneratedArtifact.objects.count() == 1

    @pytest.mark.django_db
    def test_the_same_source_kind_language_version_reuses_one_row(self):
        paper = _published_paper()
        first, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        second, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        assert first.pk == second.pk
        assert GeneratedArtifact.objects.count() == 1

    @pytest.mark.django_db
    def test_a_ready_artifact_reports_itself_ready(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        artifact.status = ArtifactStatus.READY
        artifact.body = "Already generated."
        artifact.save()
        _, is_ready = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        assert is_ready is True


class TestRunPendingGeneration:
    @pytest.mark.django_db
    def test_a_real_success_marks_the_artifact_ready_with_real_usage_data(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with mock.patch(
            "apps.ai.services.GeminiProvider.generate",
            return_value=AIResult(text="A real summary.", model="gemini-2.5-flash", tokens_in=500, tokens_out=120),
        ):
            run_pending_generation(artifact)

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.READY
        assert artifact.body == "A real summary."
        assert artifact.model_used == "gemini-2.5-flash"
        assert artifact.tokens_in == 500
        assert artifact.tokens_out == 120
        assert artifact.source_hash  # a real hash of the ocr_text that was actually sent

    @pytest.mark.django_db
    def test_no_ocr_text_yet_fails_without_calling_the_provider_at_all(self):
        paper = _published_paper(ocr_text="")
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with mock.patch("apps.ai.services.GeminiProvider.generate") as mocked:
            with pytest.raises(AIUnavailable):
                run_pending_generation(artifact)
            mocked.assert_not_called()

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.FAILED
        assert "no OCR text" in artifact.error

    @pytest.mark.django_db
    def test_a_provider_refusal_fails_the_row_but_creates_no_ticket_before_three_attempts(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with mock.patch("apps.ai.services.GeminiProvider.generate", side_effect=AIRefused("safety block")), pytest.raises(AIRefused):
            run_pending_generation(artifact)

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.FAILED
        assert artifact.attempts == 1
        assert AdminFlagQueue.objects.count() == 0

    @pytest.mark.django_db
    def test_the_third_failed_attempt_raises_a_real_review_team_ticket(self):
        """Matches this codebase's own established pattern (apps.admin_queue
        .services.flag) — every event needing human attention lands in the
        same queue, not a separate ticketing system."""
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        artifact.attempts = 2  # simulate two prior failed cron runs
        artifact.save(update_fields=["attempts"])

        with mock.patch("apps.ai.services.GeminiProvider.generate", side_effect=AIRefused("safety block")), pytest.raises(AIRefused):
            run_pending_generation(artifact)

        artifact.refresh_from_db()
        assert artifact.attempts == 3
        ticket = AdminFlagQueue.objects.get()
        assert ticket.category == FlagCategory.OTHER
        assert ticket.object_id == str(paper.pk)
        assert "3 attempts" in ticket.reason


class TestGeneratePendingArtifactsCommand:
    @pytest.mark.django_db
    def test_generates_a_real_pending_row_end_to_end(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with mock.patch(
            "apps.ai.services.GeminiProvider.generate",
            return_value=AIResult(text="Cron-generated summary.", model="gemini-2.5-flash"),
        ):
            call_command("generate_pending_artifacts")

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.READY
        assert artifact.body == "Cron-generated summary."

    @pytest.mark.django_db
    def test_ai_enabled_false_is_a_real_kill_switch(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with override_settings(AI_ENABLED=False), mock.patch("apps.ai.services.GeminiProvider.generate") as mocked:
            call_command("generate_pending_artifacts")
            mocked.assert_not_called()

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.PENDING  # untouched, not silently failed

    @pytest.mark.django_db
    def test_an_exhausted_daily_budget_stops_the_run_without_touching_the_row(self):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")

        with (
            mock.patch("apps.ai.management.commands.generate_pending_artifacts.consume_provider_budget", return_value=False),
            mock.patch("apps.ai.services.GeminiProvider.generate") as mocked,
        ):
            call_command("generate_pending_artifacts")
            mocked.assert_not_called()

        artifact.refresh_from_db()
        assert artifact.status == ArtifactStatus.PENDING


class TestPaperSummaryView:
    @pytest.mark.django_db
    def test_a_guest_gets_a_pending_response_for_a_fresh_free_paper(self, api_client):
        paper = _published_paper()
        response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 202
        assert response.data["status"] == "pending"

    @pytest.mark.django_db
    def test_a_ready_artifact_is_served_straight_from_the_cache(self, api_client):
        paper = _published_paper()
        artifact, _ = get_or_queue_artifact(paper, ArtifactKind.SUMMARY, language="en")
        artifact.status = ArtifactStatus.READY
        artifact.body = "Cached summary body."
        artifact.save()

        response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 200
        assert response.data["body"] == "Cached summary body."

    @pytest.mark.django_db
    def test_an_unpublished_papers_summary_404s_for_a_stranger(self, api_client):
        paper = _published_paper(status=PaperStatus.PENDING_REVIEW)
        response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 404

    @pytest.mark.django_db
    def test_a_paywalled_reports_summary_requires_the_same_real_payment_as_the_file_itself(self, api_client):
        """Real gate: an AI summary of a paper someone hasn't paid to view
        would otherwise be a free way around user_can_view_file's own
        paywall (apps.papers.services) — this asserts that gate actually
        applies here too, not just to the file endpoint."""
        from apps.papers.factories import ExamTypeFactory

        # A distinct name/system, or django_get_or_create (keyed on
        # category/system/name) would just return the shared default
        # "O Level" ExamType other fixtures already created — silently
        # ignoring requires_payment_to_view entirely.
        exam_type = ExamTypeFactory(system="francophone", name="PhD Thesis", requires_payment_to_view=True)
        paper = _published_paper(exam_type=exam_type, category=exam_type.category)
        response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 402

    @pytest.mark.django_db
    def test_the_papers_own_submitter_can_see_a_pending_summary_even_before_publication(self, api_client):
        user = UserFactory()
        paper = _published_paper(submitted_by=user, status=PaperStatus.PENDING_REVIEW)
        api_client.force_authenticate(user=user)
        response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 202  # visible at all, not a 404 — the real assertion here

    @pytest.mark.django_db
    def test_ai_enabled_false_is_a_real_kill_switch_on_the_endpoint_too(self, api_client):
        paper = _published_paper()
        with override_settings(AI_ENABLED=False):
            response = api_client.get(f"/api/ai/papers/{paper.pk}/summary/")
        assert response.status_code == 503


class TestConsumeChatQuota:
    """Direct tests of the quota primitive itself — TestPaperChatView below
    covers it through the real endpoint. A fresh uuid identity per test
    means no two tests ever share a cache key, real Redis or not."""

    def test_allows_up_to_the_limit_then_blocks(self):
        identity = f"test-{uuid.uuid4()}"
        for expected_remaining in (2, 1, 0):
            allowed, remaining = consume_chat_quota(identity, limit=3)
            assert allowed is True
            assert remaining == expected_remaining

        allowed, remaining = consume_chat_quota(identity, limit=3)
        assert allowed is False
        assert remaining == 0

    def test_two_different_identities_never_share_a_counter(self):
        a, b = f"test-{uuid.uuid4()}", f"test-{uuid.uuid4()}"
        assert consume_chat_quota(a, limit=1) == (True, 0)
        assert consume_chat_quota(b, limit=1) == (True, 0)  # not blocked by a's own count


class TestGroqProvider:
    def test_a_real_success_extracts_text_and_usage(self):
        response_json = {
            "model": "llama-3.3-70b-versatile",
            "choices": [{"message": {"role": "assistant", "content": "Photosynthesis converts light into energy."}, "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 300, "completion_tokens": 40},
        }
        with mock.patch("apps.ai.providers.groq.requests.post") as mocked_post:
            mocked_post.return_value = mock.Mock(status_code=200, json=lambda: response_json)
            with override_settings(GROQ_API_KEY="test-key"):
                result = GroqProvider().chat(system="You are a tutor.", messages=[{"role": "user", "content": "Explain question 1."}])

        assert result.text == "Photosynthesis converts light into energy."
        assert result.tokens_in == 300
        assert result.tokens_out == 40

    def test_no_api_key_fails_cleanly_without_a_real_request(self):
        with mock.patch("apps.ai.providers.groq.requests.post") as mocked_post, override_settings(GROQ_API_KEY=None):
            with pytest.raises(AIUnavailable):
                GroqProvider().chat(system="s", messages=[{"role": "user", "content": "hi"}])
            mocked_post.assert_not_called()

    def test_a_429_raises_ai_rate_limited(self):
        with mock.patch("apps.ai.providers.groq.requests.post") as mocked_post, override_settings(GROQ_API_KEY="test-key"):
            mocked_post.return_value = mock.Mock(status_code=429, text="rate limited")
            with pytest.raises(AIRateLimited):
                GroqProvider().chat(system="s", messages=[{"role": "user", "content": "hi"}])

    def test_a_content_filter_finish_reason_raises_ai_refused(self):
        response_json = {"choices": [{"message": {"content": ""}, "finish_reason": "content_filter"}]}
        with mock.patch("apps.ai.providers.groq.requests.post") as mocked_post, override_settings(GROQ_API_KEY="test-key"):
            mocked_post.return_value = mock.Mock(status_code=200, json=lambda: response_json)
            with pytest.raises(AIRefused):
                GroqProvider().chat(system="s", messages=[{"role": "user", "content": "hi"}])


class TestValidateChatMessages:
    @pytest.mark.parametrize(
        "messages",
        [
            None,
            [],
            "not a list",
            [{"role": "system", "content": "hi"}],  # system isn't a client-supplied role
            [{"role": "user"}],  # missing content
            [{"role": "user", "content": "   "}],  # blank content
            [{"role": "user", "content": "hi"}, {"role": "assistant", "content": "hi"}] * 7,  # too many (14 > 12)
            [{"role": "user", "content": "x" * 5000}],  # too many total chars
            [{"role": "user", "content": "hi"}, {"role": "assistant", "content": "reply"}],  # doesn't end on the user
        ],
    )
    def test_rejects_malformed_or_oversized_input(self, messages):
        assert validate_chat_messages(messages) is not None

    def test_accepts_a_real_well_formed_conversation(self):
        messages = [
            {"role": "user", "content": "What does question 2 want?"},
            {"role": "assistant", "content": "It's asking you to define photosynthesis."},
            {"role": "user", "content": "Can you explain that more simply?"},
        ]
        assert validate_chat_messages(messages) is None


class TestSendChatMessage:
    @pytest.mark.django_db
    def test_forwards_the_papers_own_ocr_text_and_returns_the_real_reply(self):
        paper = _published_paper(ocr_text="Question 1: Define photosynthesis.")
        with mock.patch("apps.ai.services.GroqProvider.chat", return_value=AIResult(text="It's how plants make food.", model="llama-3.3-70b-versatile")) as mocked_chat:
            result = send_chat_message(paper=paper, messages=[{"role": "user", "content": "Explain question 1."}])

        assert result.text == "It's how plants make food."
        _, kwargs = mocked_chat.call_args
        assert "Define photosynthesis" in kwargs["system"]


class TestPaperChatView:
    @pytest.mark.django_db
    def test_an_unauthenticated_request_is_rejected(self, api_client):
        paper = _published_paper()
        response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code in (401, 403)

    @pytest.mark.django_db
    def test_an_unpublished_papers_chat_404s_for_a_stranger(self, api_client):
        user = UserFactory()
        paper = _published_paper(status=PaperStatus.PENDING_REVIEW)
        api_client.force_authenticate(user=user)
        response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 404

    @pytest.mark.django_db
    def test_a_paywalled_reports_chat_requires_the_same_real_payment_as_the_file_itself(self, api_client):
        from apps.papers.factories import ExamTypeFactory

        user = UserFactory()
        exam_type = ExamTypeFactory(system="francophone", name="Chat-Gated Thesis", requires_payment_to_view=True)
        paper = _published_paper(exam_type=exam_type, category=exam_type.category)
        api_client.force_authenticate(user=user)
        response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 402

    @pytest.mark.django_db
    def test_no_ocr_text_yet_is_a_real_409_not_a_crash(self, api_client):
        user = UserFactory()
        paper = _published_paper(ocr_text="")
        api_client.force_authenticate(user=user)
        response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 409

    @pytest.mark.django_db
    def test_malformed_messages_are_a_400_before_ever_touching_groq(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with mock.patch("apps.ai.services.GroqProvider.chat") as mocked_chat:
            response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": []}, format="json")
        assert response.status_code == 400
        mocked_chat.assert_not_called()

    @pytest.mark.django_db
    def test_a_free_user_gets_a_real_reply_and_a_shrinking_quota(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with override_settings(AI_CHAT_DAILY_LIMIT=2), mock.patch(
            "apps.ai.services.GroqProvider.chat", return_value=AIResult(text="A real reply.", model="llama-3.3-70b-versatile")
        ):
            first = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
            second = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi again"}]}, format="json")
            third = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "one more"}]}, format="json")

        assert first.status_code == 200
        assert first.data["content"] == "A real reply."
        assert first.data["quota_remaining"] == 1
        assert second.status_code == 200
        assert second.data["quota_remaining"] == 0
        assert third.status_code == 429
        assert third.data["upgrade_required"] is True

    @pytest.mark.django_db
    def test_a_pro_subscriber_is_never_quota_blocked(self, api_client):
        """Owner decision (resolved via AskUserQuestion): Pro skips the
        per-user daily cap entirely — real value for the existing
        Subscription/Pro flow, same reasoning as ad-free + unlimited
        paper views."""
        user = UserFactory()
        SubscriptionFactory(user=user)
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with override_settings(AI_CHAT_DAILY_LIMIT=1), mock.patch(
            "apps.ai.services.GroqProvider.chat", return_value=AIResult(text="A real reply.", model="llama-3.3-70b-versatile")
        ):
            responses = [
                api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": f"question {i}"}]}, format="json")
                for i in range(3)
            ]

        assert all(r.status_code == 200 for r in responses)
        assert all(r.data["quota_remaining"] is None for r in responses)

    @pytest.mark.django_db
    def test_an_exhausted_provider_budget_is_a_503_not_a_charge_against_the_users_own_quota(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with mock.patch("apps.ai.views.consume_provider_budget", return_value=False), mock.patch("apps.ai.services.GroqProvider.chat") as mocked_chat:
            response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 503
        mocked_chat.assert_not_called()

    @pytest.mark.django_db
    def test_a_provider_refusal_is_a_real_200_with_an_honest_canned_reply(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with mock.patch("apps.ai.services.GroqProvider.chat", side_effect=AIRefused("safety block")):
            response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 200
        assert "can't help" in response.data["content"]

    @pytest.mark.django_db
    def test_a_provider_rate_limit_is_a_503_not_a_500(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with mock.patch("apps.ai.services.GroqProvider.chat", side_effect=AIRateLimited("groq 429")):
            response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 503

    @pytest.mark.django_db
    def test_ai_chat_enabled_false_is_a_real_kill_switch_independent_of_ai_enabled(self, api_client):
        user = UserFactory()
        paper = _published_paper()
        api_client.force_authenticate(user=user)
        with override_settings(AI_ENABLED=True, AI_CHAT_ENABLED=False):
            response = api_client.post(f"/api/ai/papers/{paper.pk}/chat/", {"messages": [{"role": "user", "content": "hi"}]}, format="json")
        assert response.status_code == 503
