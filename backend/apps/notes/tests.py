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
    assert Note.objects.filter(title__contains="Newton").exists()


@pytest.mark.django_db
def test_notes_endpoint_is_public(api_client):
    response = api_client.get("/api/notes/")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) == 5


@pytest.mark.django_db
def test_notes_endpoint_returns_title_and_subtitle_only(api_client):
    NoteFactory(title="Extra Note", subtitle="Extra · Subject")
    response = api_client.get("/api/notes/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = next(r for r in rows if r["title"] == "Extra Note")
    assert row["subtitle"] == "Extra · Subject"
    assert set(row.keys()) == {"id", "title", "subtitle"}
