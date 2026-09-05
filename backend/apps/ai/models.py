import hashlib

from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models


# Phase 1 (2026-09-05): a real, cached AI summary of a paper's own OCR'd
# text — nothing else yet. Adding a new kind (quiz, simplified note,
# translation) is meant to be a one-line addition here plus a new prompt
# module, not a redesign; see apps/ai/prompts/ and the "Phase 2+" note in
# apps/ai/README-equivalent (this docstring) for what's deliberately
# deferred: quiz generation (structured JSON output), FR prompts, and
# pre-warming on publish all need a real product decision on cost first
# (see apps/ai/providers/gemini.py's own module docstring).
class ArtifactKind(models.TextChoices):
    SUMMARY = "summary", "Summary"


class ArtifactStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    RUNNING = "running", "Running"
    READY = "ready", "Ready"
    FAILED = "failed", "Failed"


class GeneratedArtifact(models.Model):
    """
    Content-addressed cache: one row per (source object, kind, language,
    prompt version). Generated once by generate_pending_artifacts (a real
    Django management command, triggered the same way every other
    background job in this codebase is — see apps.core.views
    .TRIGGERABLE_COMMANDS — not Celery, which this project deliberately
    doesn't run; Render's free web-service tier has no worker-service
    concept at all, the same reason apps.instructors
    .process_instructor_timeouts and friends are cron-driven commands
    instead), then served from Postgres to every student who opens that
    paper — the AI cost is per-paper, not per-view.

    content_type/object_id mirrors apps.admin_queue.models.AdminFlagQueue's
    own GenericForeignKey — the established pattern in this codebase for
    "one row can point at a submission, a pamphlet order, an instructor
    request, whatever" without every app importing every other app's
    models. object_id is a CharField (not an integer field) for the same
    reason AdminFlagQueue's is: some of this project's own models key on a
    UUID (User), not an autoincrementing int.
    """

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.CharField(max_length=64)
    source = GenericForeignKey("content_type", "object_id")

    kind = models.CharField(max_length=32, choices=ArtifactKind.choices)
    language = models.CharField(max_length=5, default="en")  # "en" only in phase 1 — see prompts/summarise.py

    prompt_version = models.PositiveSmallIntegerField()
    # Detects a stale artifact (e.g. a corrected re-upload) without diffing
    # text — set from the exact input text handed to the provider.
    source_hash = models.CharField(max_length=64, blank=True, db_index=True)

    status = models.CharField(max_length=16, choices=ArtifactStatus.choices, default=ArtifactStatus.PENDING)
    body = models.TextField(blank=True)

    model_used = models.CharField(max_length=64, blank=True)
    tokens_in = models.PositiveIntegerField(default=0)
    tokens_out = models.PositiveIntegerField(default=0)
    error = models.TextField(blank=True)
    attempts = models.PositiveSmallIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("content_type", "object_id", "kind", "language", "prompt_version")]
        indexes = [models.Index(fields=["status", "kind"])]

    def __str__(self) -> str:
        return f"{self.get_kind_display()} ({self.language}) for {self.content_type}#{self.object_id} — {self.status}"

    @staticmethod
    def hash_source(raw: str) -> str:
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()
