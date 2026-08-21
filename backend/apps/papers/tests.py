import io

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from pypdf import PdfReader
from reportlab.pdfgen import canvas
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.payments.factories import SubscriptionFactory
from apps.payments.models import PaperUnlock

from .factories import ExamCategoryFactory, ExamTypeFactory, PaperSubmissionFactory, SubjectFactory
from .models import AdWatchEvent, ExamCategory, ExamType, PaperStatus, PaperSubmission, PaperViewLog, Subject
from .services import DAILY_FREE_VIEWS, PaywallError, record_ad_watch, record_paper_view, user_can_view_file


def _real_pdf_bytes(text: str = "Original report content") -> bytes:
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(400, 300))
    c.drawString(50, 150, text)
    c.save()
    return buf.getvalue()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def authed_client(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    return api_client, user


@pytest.mark.django_db
def test_taxonomy_was_seeded_by_migration():
    assert ExamCategory.objects.count() == 6
    assert ExamType.objects.filter(category__key="secondary", system="anglophone").count() == 2
    assert Subject.objects.filter(language="fr").count() == 6
    bepc = ExamType.objects.get(category__key="secondary", name="BEPC")
    assert bepc.tracks == ["Général", "Technique"]
    assert bepc.requires_track is True
    fslc = ExamType.objects.get(category__key="primary", name="FSLC")
    assert fslc.requires_track is False


@pytest.mark.django_db
def test_categories_endpoint_is_public(api_client):
    ExamCategoryFactory()
    response = api_client.get("/api/papers/categories/")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) >= 1


@pytest.mark.django_db
def test_exam_types_endpoint_filters_by_category_and_system(api_client):
    cat = ExamCategoryFactory(key="secondary")
    ExamTypeFactory(category=cat, system="anglophone", name="O Level")
    ExamTypeFactory(category=cat, system="francophone", name="BEPC")
    response = api_client.get(f"/api/papers/exam-types/?category={cat.id}&system=anglophone")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    names = [row["name"] for row in rows]
    assert "O Level" in names
    assert "BEPC" not in names


@pytest.mark.django_db
def test_submit_requires_authentication(api_client):
    response = api_client.post("/api/papers/submissions/", {}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_submit_creates_paper_owned_by_requesting_user(authed_client):
    client, user = authed_client
    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    subject = SubjectFactory()
    upload = SimpleUploadedFile("gce-bio-2024.pdf", b"%PDF-1.4 fake pdf bytes", content_type="application/pdf")
    response = client.post(
        "/api/papers/submissions/",
        {
            "category": category.id,
            "exam_type": exam_type.id,
            "subject": subject.id,
            "system": "anglophone",
            "year": 2024,
            "uploaded_file": upload,
        },
        format="multipart",
    )
    assert response.status_code == 201
    submission = PaperSubmission.objects.get(id=response.data["id"])
    assert submission.submitted_by == user
    assert submission.status == PaperStatus.PENDING_REVIEW
    assert submission.uploaded_file
    # file_ref mirrors uploaded_file.path only for storage backends that have
    # a local filesystem path (local disk). Remote storage (S3/Supabase) has
    # no .path() by design, so file_ref stays blank there instead — see
    # PaperSubmission.save().
    try:
        expected_file_ref = submission.uploaded_file.path
    except NotImplementedError:
        expected_file_ref = ""
    assert submission.file_ref == expected_file_ref


@pytest.mark.django_db
def test_submit_auto_creates_a_verification_ticket(authed_client):
    """Spec §2.1: every new submission creates a Review Team ticket, not just a silent DB row."""
    from apps.admin_queue.models import AdminFlagQueue, FlagCategory, FlagStatus

    client, _ = authed_client
    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    subject = SubjectFactory()
    upload = SimpleUploadedFile("gce-bio-2024.pdf", b"%PDF-1.4 fake pdf bytes", content_type="application/pdf")
    response = client.post(
        "/api/papers/submissions/",
        {
            "category": category.id,
            "exam_type": exam_type.id,
            "subject": subject.id,
            "system": "anglophone",
            "year": 2024,
            "uploaded_file": upload,
        },
        format="multipart",
    )
    submission = PaperSubmission.objects.get(id=response.data["id"])

    ticket = AdminFlagQueue.objects.get(category=FlagCategory.PAPER_VERIFICATION)
    assert ticket.subject == submission
    assert ticket.status == FlagStatus.NEW


@pytest.mark.django_db
def test_submit_requires_a_real_file(authed_client):
    client, _ = authed_client
    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    response = client.post(
        "/api/papers/submissions/",
        {"category": category.id, "exam_type": exam_type.id, "system": "anglophone", "year": 2024},
        format="multipart",
    )
    assert response.status_code == 400
    assert "uploaded_file" in response.data


@pytest.mark.django_db
def test_submit_academic_report_with_no_subject_but_real_institution_fields(authed_client):
    """Reports have no Subject taxonomy of their own — institution/discipline
    are free text instead, and supervisor_name is genuinely optional."""
    client, user = authed_client
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    report_type = ExamTypeFactory(category=reports_category, system=None, name="Mémoire")
    upload = SimpleUploadedFile("memoire.pdf", b"%PDF-1.4 fake pdf bytes", content_type="application/pdf")
    response = client.post(
        "/api/papers/submissions/",
        {
            "category": reports_category.id,
            "exam_type": report_type.id,
            "year": 2024,
            "institution": "Université de Douala",
            "discipline": "Computer Engineering",
            "uploaded_file": upload,
        },
        format="multipart",
    )
    assert response.status_code == 201
    submission = PaperSubmission.objects.get(id=response.data["id"])
    assert submission.subject is None
    assert submission.institution == "Université de Douala"
    assert submission.discipline == "Computer Engineering"
    assert submission.supervisor_name == ""  # never sent, genuinely optional


@pytest.mark.django_db
def test_report_exam_types_were_seeded_by_migration():
    reports = ExamType.objects.filter(category__key="reports").order_by("sort_order")
    assert reports.count() == 5
    assert list(reports.values_list("name", flat=True))[:2] == [
        "Internship Report",
        "Bachelor’s Report (Mémoire de Licence)",
    ]
    assert all(t.system is None for t in reports)


@pytest.mark.django_db
def test_only_masters_and_phd_reports_require_payment_to_view():
    gated = set(
        ExamType.objects.filter(category__key="reports", requires_payment_to_view=True).values_list(
            "name", flat=True
        )
    )
    assert gated == {"Master’s Thesis (Mémoire)", "PhD Thesis (Thèse)"}


@pytest.mark.django_db
def test_submitting_a_report_watermarks_the_real_file(authed_client):
    client, user = authed_client
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    report_type = ExamTypeFactory(category=reports_category, system=None, name="Internship Report")
    original = _real_pdf_bytes()
    upload = SimpleUploadedFile("internship.pdf", original, content_type="application/pdf")

    response = client.post(
        "/api/papers/submissions/",
        {
            "category": reports_category.id,
            "exam_type": report_type.id,
            "year": 2024,
            "institution": "ENSP Yaoundé",
            "discipline": "Software Engineering",
            "uploaded_file": upload,
        },
        format="multipart",
    )
    assert response.status_code == 201
    submission = PaperSubmission.objects.get(id=response.data["id"])

    submission.uploaded_file.open("rb")
    try:
        stored_bytes = submission.uploaded_file.read()
    finally:
        submission.uploaded_file.close()

    assert stored_bytes != original  # a real watermark was actually applied
    text = PdfReader(io.BytesIO(stored_bytes)).pages[0].extract_text()
    assert "Original report content" in text  # the real submission survives
    assert "Spekooh" in text  # the watermark is really there


@pytest.mark.django_db
def test_submitting_an_exam_paper_is_not_watermarked(authed_client):
    """Watermarking is a reports-only behavior — marking guides aren't a
    shareable document the way a report is."""
    client, user = authed_client
    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    subject = SubjectFactory()
    original = _real_pdf_bytes()
    upload = SimpleUploadedFile("gce-bio-2024.pdf", original, content_type="application/pdf")

    response = client.post(
        "/api/papers/submissions/",
        {
            "category": category.id,
            "exam_type": exam_type.id,
            "subject": subject.id,
            "system": "anglophone",
            "year": 2024,
            "uploaded_file": upload,
        },
        format="multipart",
    )
    submission = PaperSubmission.objects.get(id=response.data["id"])
    submission.uploaded_file.open("rb")
    try:
        stored_bytes = submission.uploaded_file.read()
    finally:
        submission.uploaded_file.close()
    assert stored_bytes == original


@pytest.mark.django_db
def test_free_tier_report_is_viewable_by_anyone_without_unlock():
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    internship = ExamTypeFactory(category=reports_category, system=None, name="Internship Report")
    submission = PaperSubmissionFactory(category=reports_category, exam_type=internship, subject=None)
    other_user = UserFactory()
    assert user_can_view_file(other_user, submission) is True


@pytest.mark.django_db
def test_masters_and_phd_reports_are_hidden_until_unlocked(authed_client):
    client, user = authed_client
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    phd = ExamTypeFactory(category=reports_category, system=None, name="PhD Thesis (Thèse)", requires_payment_to_view=True)
    submission = PaperSubmissionFactory(
        category=reports_category,
        exam_type=phd,
        subject=None,
        status=PaperStatus.PUBLISHED,
        uploaded_file=SimpleUploadedFile("thesis.pdf", _real_pdf_bytes(), content_type="application/pdf"),
    )
    other_user = UserFactory()

    # Not unlocked yet — the file is real, but withheld — for anyone,
    # including `other_user` (checked directly) and `user` (checked via the
    # real API response `client` is authed as).
    assert user_can_view_file(other_user, submission) is False
    response = client.get(f"/api/papers/submissions/{submission.id}/")
    assert response.data["requires_unlock"] is True
    assert response.data["file_url"] is None

    PaperUnlock.objects.create(user=user, paper_submission=submission, amount_paid=500)
    response = client.get(f"/api/papers/submissions/{submission.id}/")
    assert response.data["requires_unlock"] is False
    assert response.data["file_url"] is not None


@pytest.mark.django_db
def test_submitter_always_sees_their_own_gated_report(authed_client):
    """Nobody should have to pay to see the report they themselves uploaded."""
    client, user = authed_client
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    masters = ExamTypeFactory(
        category=reports_category, system=None, name="Master’s Thesis (Mémoire)", requires_payment_to_view=True
    )
    submission = PaperSubmissionFactory(
        submitted_by=user,
        category=reports_category,
        exam_type=masters,
        subject=None,
        uploaded_file=SimpleUploadedFile("thesis.pdf", _real_pdf_bytes(), content_type="application/pdf"),
    )
    assert user_can_view_file(user, submission) is True
    response = client.get(f"/api/papers/submissions/{submission.id}/")
    assert response.data["requires_unlock"] is False
    assert response.data["file_url"] is not None


@pytest.mark.django_db
def test_staff_always_sees_gated_reports_without_unlocking():
    reports_category = ExamCategoryFactory(key="reports", requires_system=False)
    phd = ExamTypeFactory(category=reports_category, system=None, name="PhD Thesis (Thèse)", requires_payment_to_view=True)
    submission = PaperSubmissionFactory(category=reports_category, exam_type=phd, subject=None)
    staff_user = UserFactory(is_staff=True)
    assert user_can_view_file(staff_user, submission) is True


@pytest.mark.django_db
def test_exam_type_serializer_exposes_requires_payment_to_view(api_client):
    category = ExamCategoryFactory(key="reports", requires_system=False)
    phd = ExamTypeFactory(category=category, system=None, name="PhD Thesis (Thèse)", requires_payment_to_view=True)
    response = api_client.get(f"/api/papers/exam-types/?category={category.id}")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = next(r for r in rows if r["id"] == phd.id)
    assert row["requires_payment_to_view"] is True


@pytest.mark.django_db
def test_list_shows_only_summary_fields(authed_client):
    client, user = authed_client
    PaperSubmissionFactory(submitted_by=user)
    response = client.get("/api/papers/submissions/")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    row = rows[0]
    assert "exam_type_name" in row
    assert "ocr_text" not in row


@pytest.mark.django_db
def test_detail_returns_full_fields(authed_client):
    client, user = authed_client
    submission = PaperSubmissionFactory(submitted_by=user)
    response = client.get(f"/api/papers/submissions/{submission.id}/")
    assert response.status_code == 200
    assert response.data["status"] == PaperStatus.PENDING_REVIEW
    assert response.data["file_url"] is None  # factory doesn't attach a real uploaded file


@pytest.mark.django_db
def test_guest_can_browse_published_papers_but_not_others(api_client):
    published = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    PaperSubmissionFactory(status=PaperStatus.PENDING_REVIEW)
    response = api_client.get("/api/papers/submissions/")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    ids = [row["id"] for row in rows]
    assert published.id in ids
    assert len(rows) == 1


@pytest.mark.django_db
def test_authed_user_sees_own_pending_papers_plus_everyones_published(authed_client):
    client, user = authed_client
    own_pending = PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PENDING_REVIEW)
    others_published = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    others_pending = PaperSubmissionFactory(status=PaperStatus.PENDING_REVIEW)
    response = client.get("/api/papers/submissions/")
    ids = [row["id"] for row in response.data]
    assert own_pending.id in ids
    assert others_published.id in ids
    assert others_pending.id not in ids


@pytest.mark.django_db
def test_list_can_filter_by_status(authed_client):
    client, user = authed_client
    PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PUBLISHED)
    PaperSubmissionFactory(submitted_by=user, status=PaperStatus.PENDING_REVIEW)
    response = client.get("/api/papers/submissions/?status=PUBLISHED")
    assert response.status_code == 200
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) == 1
    assert rows[0]["status"] == PaperStatus.PUBLISHED


@pytest.mark.django_db
def test_free_user_gets_three_views_per_day_then_blocked():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    for _ in range(DAILY_FREE_VIEWS):
        record_paper_view(user=user, paper_submission=paper)
    assert PaperViewLog.objects.filter(user=user).count() == DAILY_FREE_VIEWS
    with pytest.raises(PaywallError):
        record_paper_view(user=user, paper_submission=paper)


@pytest.mark.django_db
def test_watching_an_ad_grants_one_more_view_after_limit():
    user = UserFactory()
    paper = PaperSubmissionFactory()
    for _ in range(DAILY_FREE_VIEWS):
        record_paper_view(user=user, paper_submission=paper)

    record_ad_watch(user=user)
    log = record_paper_view(user=user, paper_submission=paper)
    assert log is not None

    # The ad watch is consumed — a second view past the limit is blocked again.
    with pytest.raises(PaywallError):
        record_paper_view(user=user, paper_submission=paper)
    assert AdWatchEvent.objects.get(user=user).consumed_by_view_log_id == log.id


@pytest.mark.django_db
def test_pro_subscriber_has_unlimited_views():
    user = UserFactory()
    SubscriptionFactory(user=user)
    paper = PaperSubmissionFactory()
    for _ in range(DAILY_FREE_VIEWS + 5):
        record_paper_view(user=user, paper_submission=paper)
    assert PaperViewLog.objects.filter(user=user).count() == DAILY_FREE_VIEWS + 5


@pytest.mark.django_db
def test_view_endpoint_enforces_paywall(api_client):
    user = UserFactory()
    paper = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    api_client.force_authenticate(user=user)
    for _ in range(DAILY_FREE_VIEWS):
        response = api_client.post(f"/api/papers/submissions/{paper.id}/view/")
        assert response.status_code == 201
    blocked = api_client.post(f"/api/papers/submissions/{paper.id}/view/")
    assert blocked.status_code == 402


@pytest.mark.django_db
def test_ad_watch_endpoint_records_event(api_client):
    user = UserFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post("/api/papers/ad-watch/")
    assert response.status_code == 201
    assert AdWatchEvent.objects.filter(user=user).count() == 1


# --- OCR + duplicate detection (Stage 5) ---


def _fixture_image(tmp_path, text, name="paper.png"):
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (600, 150), color="white")
    draw = ImageDraw.Draw(img)
    draw.text((10, 50), text, fill="black")
    path = tmp_path / name
    img.save(path)
    return str(path)


@pytest.mark.django_db
def test_process_ocr_extracts_text_and_sets_hash(tmp_path):
    from .services import process_ocr_and_duplicate_check

    file_path = _fixture_image(tmp_path, "Physics Paper One Mechanics Questions")
    paper = PaperSubmissionFactory(file_ref=file_path)
    processed = process_ocr_and_duplicate_check(paper)
    assert "Physics" in processed.ocr_text
    assert processed.duplicate_hash != ""
    assert processed.is_duplicate is False


@pytest.mark.django_db
def test_extract_text_from_fieldfile_stages_a_temp_copy(tmp_path):
    """
    Storage-agnostic path for apps.papers.ocr.extract_text_from_fieldfile —
    exercises the branch process_ocr_and_duplicate_check takes when
    file_ref is blank (real remote storage, e.g. Supabase Storage, where
    .path() raises NotImplementedError so PaperSubmission.save() can't
    populate it — see models.py). Works the same whether the actual
    storage backend under test is local disk or S3: the function only
    ever reads bytes via FieldFile.chunks(), never .path().
    """
    from .ocr import extract_text_from_fieldfile

    image_path = _fixture_image(tmp_path, "Chemistry Organic Reactions")
    with open(image_path, "rb") as fh:
        upload = SimpleUploadedFile("chem.png", fh.read(), content_type="image/png")
    paper = PaperSubmissionFactory(uploaded_file=upload, file_ref="")

    text = extract_text_from_fieldfile(paper.uploaded_file)
    assert "Chemistry" in text


@pytest.mark.django_db
def test_process_ocr_flags_near_duplicate_same_exam_type_and_subject(tmp_path):
    from .services import process_ocr_and_duplicate_check

    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    subject = SubjectFactory()

    original_text = "Answer all questions in Section A and Section B on Physics mechanics and thermodynamics"
    original_path = _fixture_image(tmp_path, original_text, "original.png")
    original = PaperSubmissionFactory(exam_type=exam_type, subject=subject, file_ref=original_path)
    process_ocr_and_duplicate_check(original)

    duplicate_path = _fixture_image(tmp_path, original_text, "duplicate.png")
    duplicate = PaperSubmissionFactory(exam_type=exam_type, subject=subject, file_ref=duplicate_path)
    processed = process_ocr_and_duplicate_check(duplicate)

    assert processed.is_duplicate is True
    assert processed.duplicate_of_id == original.id


@pytest.mark.django_db
def test_process_ocr_does_not_flag_different_content_as_duplicate(tmp_path):
    from .services import process_ocr_and_duplicate_check

    category = ExamCategoryFactory()
    exam_type = ExamTypeFactory(category=category)
    subject = SubjectFactory()

    first_path = _fixture_image(tmp_path, "Chemistry organic reactions and bonding", "a.png")
    first = PaperSubmissionFactory(exam_type=exam_type, subject=subject, file_ref=first_path)
    process_ocr_and_duplicate_check(first)

    second_path = _fixture_image(tmp_path, "History colonial independence movements Africa", "b.png")
    second = PaperSubmissionFactory(exam_type=exam_type, subject=subject, file_ref=second_path)
    processed = process_ocr_and_duplicate_check(second)

    assert processed.is_duplicate is False
    assert processed.duplicate_of is None


@pytest.mark.django_db
def test_process_ocr_endpoint_requires_staff(tmp_path, authed_client):
    client, user = authed_client
    file_path = _fixture_image(tmp_path, "Some paper text")
    paper = PaperSubmissionFactory(submitted_by=user, file_ref=file_path)
    response = client.post(f"/api/papers/submissions/{paper.id}/process_ocr/")
    assert response.status_code == 403


@pytest.mark.django_db
def test_process_ocr_endpoint_works_for_staff(tmp_path, api_client):
    admin_user = UserFactory(is_staff=True)
    file_path = _fixture_image(tmp_path, "Some paper text for staff test")
    paper = PaperSubmissionFactory(file_ref=file_path)
    api_client.force_authenticate(user=admin_user)
    response = api_client.post(f"/api/papers/submissions/{paper.id}/process_ocr/")
    assert response.status_code == 200
    assert "paper text" in response.data["ocr_text"].lower()


@pytest.mark.django_db
def test_report_paper_requires_authentication(api_client):
    paper = PaperSubmissionFactory()
    response = api_client.post(f"/api/papers/submissions/{paper.id}/report/", {"reason": "WRONG_ANSWERS"}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_report_paper_creates_flag_and_ticket(authed_client):
    """Spec §3.2 flag/report an existing paper — creates both the flag row
    and a Review Team ticket in the same §2.1 queue every other event uses."""
    from apps.admin_queue.models import AdminFlagQueue, FlagCategory

    client, user = authed_client
    paper = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    response = client.post(
        f"/api/papers/submissions/{paper.id}/report/",
        {"reason": "POOR_QUALITY", "details": "Half the pages are blank."},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["reason"] == "POOR_QUALITY"

    from .models import PaperFlag

    paper_flag = PaperFlag.objects.get(paper_submission=paper, flagged_by=user)
    assert paper_flag.details == "Half the pages are blank."

    ticket = AdminFlagQueue.objects.get(
        content_type__model="papersubmission", object_id=str(paper.id), category=FlagCategory.PAPER_REPORTED
    )
    assert "Poor scan quality" in ticket.reason
    assert "Half the pages are blank." in ticket.reason


@pytest.mark.django_db
def test_report_paper_twice_by_same_user_conflicts(authed_client):
    client, _ = authed_client
    paper = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    first = client.post(f"/api/papers/submissions/{paper.id}/report/", {"reason": "OTHER"}, format="json")
    assert first.status_code == 201
    second = client.post(f"/api/papers/submissions/{paper.id}/report/", {"reason": "DUPLICATE"}, format="json")
    assert second.status_code == 409


@pytest.mark.django_db
def test_report_paper_by_different_users_both_succeed(authed_client, api_client):
    client, _ = authed_client
    paper = PaperSubmissionFactory(status=PaperStatus.PUBLISHED)
    first = client.post(f"/api/papers/submissions/{paper.id}/report/", {"reason": "OTHER"}, format="json")
    assert first.status_code == 201

    other_user = UserFactory()
    api_client.force_authenticate(user=other_user)
    second = api_client.post(f"/api/papers/submissions/{paper.id}/report/", {"reason": "COPYRIGHT"}, format="json")
    assert second.status_code == 201
