import pytest
from django.contrib.auth.models import Group
from django.core.management import call_command
from django.test import Client
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory

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


# --- seed_demo_notes -------------------------------------------------------


@pytest.mark.django_db
def test_seed_demo_notes_adds_only_the_four_missing_ones_and_is_idempotent():
    assert Note.objects.count() == 5  # the migration-seeded ones

    call_command("seed_demo_notes")
    assert Note.objects.count() == 9
    university = Note.objects.get(title="Introduction to Algorithms & Complexity")
    assert (university.subject_title, university.academic_level) == ("Computer Science", "University")
    assert university.subtitle == "Computer Science · University"

    call_command("seed_demo_notes")
    assert Note.objects.count() == 9  # no duplicates


@pytest.mark.django_db
def test_seed_demo_notes_never_overwrites_what_an_admin_edited():
    call_command("seed_demo_notes")
    Note.objects.filter(title="Fractions & Decimals Made Simple").update(subtitle="Edited by staff")
    Note.objects.filter(title="Acids, Bases & Salts").update(subtitle="Also edited")

    call_command("seed_demo_notes")

    assert Note.objects.get(title="Fractions & Decimals Made Simple").subtitle == "Edited by staff"
    assert Note.objects.get(title="Acids, Bases & Salts").subtitle == "Also edited"


@pytest.mark.django_db
def test_seed_demo_notes_remove_deletes_only_its_own_four():
    call_command("seed_demo_notes")
    authored = NoteFactory(title="Written by a real staff member")

    call_command("seed_demo_notes", "--remove")

    assert not Note.objects.filter(title="Fractions & Decimals Made Simple").exists()
    assert not Note.objects.filter(title="Introduction to Algorithms & Complexity").exists()
    assert Note.objects.filter(title="Mechanics: Newton’s Laws").exists()  # migration-seeded, kept
    assert Note.objects.filter(id=authored.id).exists()


# --- Support staff manage notes in the admin -------------------------------


def _support_client():
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Support"))
    client = Client()
    client.force_login(staff)
    return client


@pytest.mark.django_db
def test_support_staff_can_create_a_note_in_the_admin():
    client = _support_client()

    response = client.post(
        "/admin/notes/note/add/",
        {"title": "Vectors Revision", "subtitle": "", "subject_title": "Physics", "academic_level": "A Level", "sort_order": 10},
    )

    assert response.status_code == 302
    note = Note.objects.get(title="Vectors Revision")
    assert note.subtitle == "Physics · A Level"  # derived, so the app row is never blank


@pytest.mark.django_db
def test_a_typed_subtitle_is_not_overridden_by_the_derived_one():
    client = _support_client()

    client.post(
        "/admin/notes/note/add/",
        {"title": "Custom Line", "subtitle": "Exam tips", "subject_title": "Physics", "academic_level": "A Level", "sort_order": 1},
    )

    assert Note.objects.get(title="Custom Line").subtitle == "Exam tips"


@pytest.mark.django_db
def test_support_staff_can_update_a_note_in_the_admin():
    note = NoteFactory(title="Old title", subject_title="Physics", academic_level="O Level")
    client = _support_client()

    response = client.post(
        f"/admin/notes/note/{note.id}/change/",
        {"title": "New title", "subtitle": note.subtitle, "subject_title": "Physics", "academic_level": "O Level", "sort_order": 0},
    )

    assert response.status_code == 302
    note.refresh_from_db()
    assert note.title == "New title"


@pytest.mark.django_db
def test_support_staff_cannot_delete_a_note():
    note = NoteFactory()
    client = _support_client()

    response = client.post(f"/admin/notes/note/{note.id}/delete/", {"post": "yes"})

    assert response.status_code == 403
    assert Note.objects.filter(id=note.id).exists()
