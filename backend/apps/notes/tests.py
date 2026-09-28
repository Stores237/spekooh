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


# --- the note text and its public API --------------------------------------


@pytest.mark.django_db
def test_the_list_carries_no_text_and_never_the_assignment(api_client):
    NoteFactory(title="Listed", body="secret body text", assigned_to=None)

    rows = api_client.get("/api/notes/").data
    rows = rows["results"] if isinstance(rows, dict) else rows
    row = next(r for r in rows if r["title"] == "Listed")

    assert "body" not in row
    assert "assigned_to" not in row


@pytest.mark.django_db
def test_one_note_returns_its_text_and_still_never_the_assignment(api_client):
    support = UserFactory(name="Amina", is_staff=True)
    support.groups.add(Group.objects.get(name="Support"))
    note = NoteFactory(title="Readable", body="First paragraph.\n\n## Heading\n- a bullet", assigned_to=support)

    response = api_client.get(f"/api/notes/{note.id}/")

    assert response.status_code == 200
    assert response.data["body"].startswith("First paragraph.")
    assert response.data["title"] == "Readable"
    assert "assigned_to" not in response.data


@pytest.mark.django_db
def test_an_unknown_note_is_a_404(api_client):
    assert api_client.get("/api/notes/999999/").status_code == 404


# --- seed_demo_notes -------------------------------------------------------


@pytest.mark.django_db
def test_seed_gives_every_level_a_note_with_real_text_and_is_idempotent():
    from .demo_notes import DEMO_NOTES

    assert Note.objects.count() == 5  # the migration-seeded ones, no text yet
    assert not Note.objects.exclude(body="").exists()

    call_command("seed_demo_notes")

    assert Note.objects.count() == len(DEMO_NOTES) == 17
    assert not Note.objects.filter(body="").exists()  # all seventeen can be read
    levels = set(Note.objects.values_list("academic_level", flat=True))
    assert {"Primary", "BEPC", "Seconde", "O Level", "A Level", "Probatoire", "Terminale", "Baccalauréat", "HND", "University"} <= levels

    call_command("seed_demo_notes")
    assert Note.objects.count() == 17  # no duplicates


@pytest.mark.django_db
def test_seed_gives_text_to_the_five_migration_notes_without_touching_their_other_fields():
    Note.objects.filter(title="Acids, Bases & Salts").update(subtitle="Chemistry · O Level (edited)", sort_order=99)

    call_command("seed_demo_notes")

    note = Note.objects.get(title="Acids, Bases & Salts")
    assert "neutralisation" in note.body.lower()
    assert note.subtitle == "Chemistry · O Level (edited)"
    assert note.sort_order == 99


@pytest.mark.django_db
def test_seed_never_overwrites_text_staff_wrote():
    call_command("seed_demo_notes")
    Note.objects.filter(title="Fractions & Decimals Made Simple").update(body="Rewritten by the support team.")
    Note.objects.filter(title="Cell Structure & Function").update(body="Also rewritten.")

    call_command("seed_demo_notes")

    assert Note.objects.get(title="Fractions & Decimals Made Simple").body == "Rewritten by the support team."
    assert Note.objects.get(title="Cell Structure & Function").body == "Also rewritten."


@pytest.mark.django_db
def test_seed_remove_deletes_only_demo_notes_that_are_still_untouched():
    call_command("seed_demo_notes")
    authored = NoteFactory(title="Written by a real staff member", body="Mine.")
    Note.objects.filter(title="Supply and Demand Basics").update(body="Staff improved this one.")

    call_command("seed_demo_notes", "--remove")

    assert not Note.objects.filter(title="Fractions & Decimals Made Simple").exists()  # untouched demo: removed
    assert Note.objects.filter(title="Supply and Demand Basics").exists()  # edited by staff: kept
    assert Note.objects.filter(title="Mechanics: Newton’s Laws").exists()  # migration-seeded: never removed
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


# --- assignment to support staff, and who can do what in the admin -------------


def _staff(group=None, **kwargs):
    user = UserFactory(is_staff=True, **kwargs)
    if group:
        user.groups.add(Group.objects.get(name=group))
    return user


def _client_for(user):
    client = Client()
    client.force_login(user)
    return client


def _note_post(**overrides):
    data = {"title": "New note", "subtitle": "", "subject_title": "Physics", "academic_level": "O Level", "sort_order": 1}
    data.update(overrides)
    return data


@pytest.mark.django_db
def test_the_owner_can_add_update_and_delete_a_summary_note():
    owner = UserFactory(is_staff=True, is_superuser=True)
    client = _client_for(owner)

    created = client.post("/admin/notes/note/add/", _note_post(title="Owner note", body="Some text."))
    assert created.status_code == 302
    note = Note.objects.get(title="Owner note")
    assert note.body == "Some text."

    updated = client.post(f"/admin/notes/note/{note.id}/change/", _note_post(title="Owner note", body="Better text."))
    assert updated.status_code == 302
    note.refresh_from_db()
    assert note.body == "Better text."

    deleted = client.post(f"/admin/notes/note/{note.id}/delete/", {"post": "yes"})
    assert deleted.status_code == 302
    assert not Note.objects.filter(id=note.id).exists()


@pytest.mark.django_db
def test_a_note_can_be_assigned_to_a_support_team_member():
    owner = UserFactory(is_staff=True, is_superuser=True)
    support = _staff("Support", name="Amina")

    response = _client_for(owner).post("/admin/notes/note/add/", _note_post(title="Assigned note", assigned_to=support.pk))

    assert response.status_code == 302
    assert Note.objects.get(title="Assigned note").assigned_to == support


@pytest.mark.django_db
def test_only_support_team_members_can_be_picked_and_they_are_shown_by_name_never_email():
    owner = UserFactory(is_staff=True, is_superuser=True)
    _staff("Support", name="Amina Support")
    nameless = _staff("Support", name="", email="hidden.person@example.com")
    outsider = _staff("Reviewer", name="Rita Reviewer")

    page = _client_for(owner).get("/admin/notes/note/add/").content.decode()

    assert "Amina Support" in page
    assert f"Staff member {nameless.pk}" in page  # no name: a neutral label, not the email
    assert "hidden.person@example.com" not in page
    assert "Rita Reviewer" not in page  # not in the Support group, so not assignable
    assert outsider.name not in page


@pytest.mark.django_db
def test_assigning_someone_outside_support_is_refused():
    owner = UserFactory(is_staff=True, is_superuser=True)
    outsider = _staff("Reviewer", name="Rita Reviewer")

    response = _client_for(owner).post("/admin/notes/note/add/", _note_post(title="Bad assignment", assigned_to=outsider.pk))

    assert response.status_code == 200  # the form is shown again with an error, nothing saved
    assert not Note.objects.filter(title="Bad assignment").exists()


@pytest.mark.django_db
def test_a_support_member_can_take_notes_with_the_bulk_action():
    support = _staff("Support", name="Amina")
    notes = [NoteFactory() for _ in range(2)]

    response = _client_for(support).post(
        "/admin/notes/note/",
        {"action": "assign_to_me", "_selected_action": [n.pk for n in notes]},
    )

    assert response.status_code == 302
    assert all(Note.objects.get(pk=n.pk).assigned_to == support for n in notes)


@pytest.mark.django_db
def test_someone_outside_support_cannot_take_notes_with_the_bulk_action():
    owner = UserFactory(is_staff=True, is_superuser=True)
    note = NoteFactory()

    _client_for(owner).post("/admin/notes/note/", {"action": "assign_to_me", "_selected_action": [note.pk]})

    assert Note.objects.get(pk=note.pk).assigned_to is None


@pytest.mark.django_db
def test_the_assignment_can_be_cleared_in_bulk():
    owner = UserFactory(is_staff=True, is_superuser=True)
    support = _staff("Support", name="Amina")
    note = NoteFactory(assigned_to=support)

    _client_for(owner).post("/admin/notes/note/", {"action": "clear_assignment", "_selected_action": [note.pk]})

    assert Note.objects.get(pk=note.pk).assigned_to is None


@pytest.mark.django_db
def test_the_list_filters_find_unassigned_mine_and_still_to_write():
    support = _staff("Support", name="Amina")
    other = _staff("Support", name="Other")
    Note.objects.all().delete()
    mine = NoteFactory(title="Mine", body="text", assigned_to=support)
    theirs = NoteFactory(title="Theirs", body="", assigned_to=other)
    free = NoteFactory(title="Free", body="", assigned_to=None)
    client = _client_for(support)

    def titles(query):
        page = client.get(f"/admin/notes/note/?{query}").content.decode()
        return {n.title for n in (mine, theirs, free) if f">{n.title}<" in page}

    assert titles("assigned=me") == {"Mine"}
    assert titles("assigned=none") == {"Free"}
    assert titles(f"assigned={other.pk}") == {"Theirs"}
    assert titles("text=missing") == {"Theirs", "Free"}
    assert titles("text=written") == {"Mine"}
    assert titles("assigned=not-a-user-id") == set()  # garbage shows nothing, never everything


@pytest.mark.django_db
def test_the_dashboard_has_a_summary_notes_card_with_real_counts_and_a_link_to_add():
    from django.test import RequestFactory

    from apps.core.admin_dashboard import dashboard_callback

    owner = UserFactory(is_staff=True, is_superuser=True)
    support = _staff("Support", name="Amina")
    Note.objects.all().delete()
    NoteFactory(body="written", assigned_to=support)
    NoteFactory(body="", assigned_to=None)
    NoteFactory(body="", assigned_to=support)

    request = RequestFactory().get("/admin/")
    request.user = support
    d = dashboard_callback(request, {})["spekooh_dashboard"]

    assert d["can_view_notes"] is True
    assert (d["notes_total"], d["notes_to_write"], d["notes_unassigned"], d["notes_mine"]) == (3, 2, 1, 2)
    assert d["notes_add_url"].endswith("/admin/notes/note/add/")

    page = _client_for(owner).get("/admin/").content.decode()
    assert "Summary notes" in page
    assert "Add a note" in page


@pytest.mark.django_db
def test_the_dashboard_hides_the_card_from_someone_with_no_notes_access():
    from django.test import RequestFactory

    from apps.core.admin_dashboard import dashboard_callback

    it_helpdesk = _staff("IT Helpdesk", name="Ivo")
    request = RequestFactory().get("/admin/")
    request.user = it_helpdesk

    d = dashboard_callback(request, {})["spekooh_dashboard"]

    assert d["can_view_notes"] is False
    assert "notes_total" not in d
