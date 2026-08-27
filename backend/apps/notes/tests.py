import pytest
from rest_framework.test import APIClient

from .factories import NoteFactory
from .models import Note


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_notes_were_seeded_by_migration():
    assert Note.objects.count() == 5
    newton = Note.objects.get(title__contains="Newton")
    assert "—" not in newton.title  # 0004 backfill also fixed the em dash left over in 0002's seed data
    assert newton.subject_title == "Physics"
    assert newton.academic_level == "A Level"


@pytest.mark.django_db
def test_notes_endpoint_is_public(api_client):
    response = api_client.get("/api/notes/")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) == 5


@pytest.mark.django_db
def test_notes_endpoint_returns_title_subtitle_and_filter_fields(api_client):
    NoteFactory(title="Extra Note", subtitle="Extra · Subject", subject_title="Extra", academic_level="Subject")
    response = api_client.get("/api/notes/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = next(r for r in rows if r["title"] == "Extra Note")
    assert row["subtitle"] == "Extra · Subject"
    assert row["subject_title"] == "Extra"
    assert row["academic_level"] == "Subject"
    assert set(row.keys()) == {"id", "title", "subtitle", "subject_title", "academic_level"}


@pytest.mark.django_db
def test_notes_endpoint_filters_by_subject_and_level(api_client):
    NoteFactory(title="Physics note", subject_title="Physics", academic_level="A Level")
    NoteFactory(title="Biology note", subject_title="Biology", academic_level="O Level")

    response = api_client.get("/api/notes/?subject_title=Physics")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    titles = [r["title"] for r in rows]
    assert "Physics note" in titles
    assert "Biology note" not in titles

    response = api_client.get("/api/notes/?academic_level=O Level")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    titles = [r["title"] for r in rows]
    assert "Biology note" in titles
    assert "Physics note" not in titles
