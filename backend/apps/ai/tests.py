from unittest import mock

import pytest
from django.core.management import call_command
from django.test import override_settings
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.admin_queue.models import AdminFlagQueue, FlagCategory
from apps.papers.factories import PaperSubmissionFactory
from apps.papers.models import PaperStatus

from .models import ArtifactKind, ArtifactStatus, GeneratedArtifact
from .providers.base import AIRefused, AIResult, AIUnavailable
from .services import get_or_queue_artifact, run_pending_generation


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
