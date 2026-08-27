import datetime

import pytest
from django.contrib.admin.sites import AdminSite
from django.contrib.auth.models import Group
from django.core.management import call_command
from django.test import Client
from django.utils import timezone
from rest_framework.test import APIClient

from .admin import UserAdmin
from .factories import UserFactory
from .models import AccountType, User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_register_creates_registered_user_and_returns_tokens(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "new@example.com", "name": "New User", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["user"]["email"] == "new@example.com"
    assert response.data["user"]["account_type"] == AccountType.REGISTERED
    assert "access" in response.data and "refresh" in response.data
    new_user = User.objects.get(email="new@example.com")
    assert new_user.check_password("S0mePass!23")
    assert new_user.terms_accepted_at is not None


@pytest.mark.django_db
def test_register_rejects_weak_password(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "weak@example.com", "name": "Weak", "password": "123", "terms_accepted": True},
        format="json",
    )
    assert response.status_code == 400


@pytest.mark.django_db
def test_register_rejects_missing_terms_acceptance(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "noconsent@example.com", "name": "No Consent", "password": "S0mePass!23"},
        format="json",
    )
    assert response.status_code == 400
    assert not User.objects.filter(email="noconsent@example.com").exists()


@pytest.mark.django_db
def test_register_rejects_explicit_terms_declined(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "declined@example.com", "name": "Declined", "password": "S0mePass!23", "terms_accepted": False},
        format="json",
    )
    assert response.status_code == 400
    assert not User.objects.filter(email="declined@example.com").exists()


@pytest.mark.django_db
def test_login_with_correct_credentials_returns_tokens(api_client):
    UserFactory(email="login@example.com", password="correcthorse123")
    response = api_client.post(
        "/api/auth/login/", {"email": "login@example.com", "password": "correcthorse123"}, format="json"
    )
    assert response.status_code == 200
    assert "access" in response.data and "refresh" in response.data
    assert response.data["user"]["email"] == "login@example.com"


@pytest.mark.django_db
def test_login_with_wrong_password_is_rejected(api_client):
    UserFactory(email="login2@example.com", password="correcthorse123")
    response = api_client.post(
        "/api/auth/login/", {"email": "login2@example.com", "password": "wrongpass"}, format="json"
    )
    assert response.status_code == 401


@pytest.mark.django_db
def test_refresh_issues_new_access_token(api_client):
    UserFactory(email="refresh@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "refresh@example.com", "password": "correcthorse123"}, format="json"
    )
    response = api_client.post("/api/auth/refresh/", {"refresh": login.data["refresh"]}, format="json")
    assert response.status_code == 200
    assert "access" in response.data


@pytest.mark.django_db
def test_guest_endpoint_creates_real_guest_user_row(api_client):
    response = api_client.post("/api/auth/guest/", {}, format="json")
    assert response.status_code == 201
    assert response.data["user"]["account_type"] == AccountType.GUEST
    guest_id = response.data["user"]["id"]
    guest = User.objects.get(id=guest_id)
    assert guest.is_guest
    assert guest.has_usable_password() is False


@pytest.mark.django_db
def test_guest_endpoint_uses_a_real_contributor_name_when_given(api_client):
    """A contributor without an account still has to be identified by the
    real name they typed (Submit's contributor-name field) — not left as
    an anonymous auto-generated 'Guest xxxxxx' label."""
    response = api_client.post("/api/auth/guest/", {"name": "Aïcha Mballa"}, format="json")
    assert response.status_code == 201
    assert response.data["user"]["name"] == "Aïcha Mballa"
    guest = User.objects.get(id=response.data["user"]["id"])
    assert guest.name == "Aïcha Mballa"
    assert guest.is_guest


@pytest.mark.django_db
def test_guest_endpoint_falls_back_to_generated_name_for_blank_input(api_client):
    response = api_client.post("/api/auth/guest/", {"name": "   "}, format="json")
    assert response.status_code == 201
    assert response.data["user"]["name"].startswith("Guest ")


@pytest.mark.django_db
def test_guest_endpoint_is_rate_limited_per_ip(api_client, monkeypatch):
    """Without a real throttle, scripting this endpoint mints unlimited
    real User rows (see GuestView's own docstring). Redis-backed via
    CACHES["default"] — this hits the real local Redis, not a mock, so a
    genuine connection failure would fail this test too, not just a wrong
    assertion.

    Note: DRF bakes DEFAULT_THROTTLE_RATES into SimpleRateThrottle.THROTTLE_RATES
    as a class attribute at import time — once any earlier test has imported
    rest_framework.throttling, overriding settings.REST_FRAMEWORK no longer
    reaches it. Monkeypatching the dict DRF actually reads from at request
    time is the reliable way to test a specific rate.
    """
    from rest_framework.throttling import SimpleRateThrottle

    monkeypatch.setitem(SimpleRateThrottle.THROTTLE_RATES, "guest_mint", "2/hour")

    first = api_client.post("/api/auth/guest/", {}, format="json")
    second = api_client.post("/api/auth/guest/", {}, format="json")
    third = api_client.post("/api/auth/guest/", {}, format="json")

    assert first.status_code == 201
    assert second.status_code == 201
    assert third.status_code == 429


@pytest.mark.django_db
def test_me_requires_authentication(api_client):
    response = api_client.get("/api/auth/me/")
    assert response.status_code == 401


@pytest.mark.django_db
def test_me_returns_authenticated_user_profile(api_client):
    UserFactory(email="me@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "me@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
    response = api_client.get("/api/auth/me/")
    assert response.status_code == 200
    assert response.data["email"] == "me@example.com"


@pytest.mark.django_db
def test_registered_user_requires_email_at_db_level():
    with pytest.raises(Exception):
        User.objects.create(account_type=AccountType.REGISTERED, email=None)


@pytest.mark.django_db
def test_register_returns_a_referral_code(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "coded@example.com", "name": "Coded User", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )
    assert response.status_code == 201
    assert len(response.data["user"]["referral_code"]) == 8


@pytest.mark.django_db
def test_register_with_valid_referral_code_sets_referred_by(api_client):
    referrer = UserFactory()
    response = api_client.post(
        "/api/auth/register/",
        {
            "email": "referred@example.com",
            "name": "Referred User",
            "password": "S0mePass!23",
            "referral_code": referrer.referral_code.lower(),  # case-insensitive
            "terms_accepted": True,
        },
        format="json",
    )
    assert response.status_code == 201
    new_user = User.objects.get(email="referred@example.com")
    assert new_user.referred_by_id == referrer.id


@pytest.mark.django_db
def test_register_rejects_an_unknown_referral_code(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {
            "email": "bad-code@example.com",
            "name": "Bad Code",
            "password": "S0mePass!23",
            "referral_code": "NOTREAL1",
            "terms_accepted": True,
        },
        format="json",
    )
    assert response.status_code == 400
    assert not User.objects.filter(email="bad-code@example.com").exists()


@pytest.mark.django_db
def test_prune_stale_guest_accounts_deletes_an_orphaned_guest_past_the_ttl():
    guest = User.objects.create_guest(name="Abandoned Upload")
    User.objects.filter(id=guest.id).update(created_at=timezone.now() - datetime.timedelta(hours=25))

    call_command("prune_stale_guest_accounts")

    assert not User.objects.filter(id=guest.id).exists()


@pytest.mark.django_db
def test_prune_stale_guest_accounts_keeps_a_guest_within_the_ttl():
    """An upload in progress right now must not get its identity yanked
    out from under it — see AuthSession.mintGuestAccessToken, which
    creates this row before the submission itself is known to succeed."""
    guest = User.objects.create_guest(name="Mid Upload")

    call_command("prune_stale_guest_accounts")

    assert User.objects.filter(id=guest.id).exists()


@pytest.mark.django_db
def test_prune_stale_guest_accounts_never_deletes_a_guest_that_owns_a_submission():
    from apps.papers.factories import PaperSubmissionFactory

    guest = User.objects.create_guest(name="Real Contributor")
    User.objects.filter(id=guest.id).update(created_at=timezone.now() - datetime.timedelta(hours=25))
    PaperSubmissionFactory(submitted_by=guest)

    call_command("prune_stale_guest_accounts")

    assert User.objects.filter(id=guest.id).exists()


@pytest.mark.django_db
def test_prune_stale_guest_accounts_never_touches_registered_users():
    old_registered = UserFactory()
    User.objects.filter(id=old_registered.id).update(created_at=timezone.now() - datetime.timedelta(days=30))

    call_command("prune_stale_guest_accounts")

    assert User.objects.filter(id=old_registered.id).exists()


@pytest.mark.django_db
def test_user_admin_never_exposes_email_or_phone_for_browsing():
    """Owner decision (data minimization): nobody browsing this admin —
    not even a superuser — sees a user's raw email or phone number. name
    is the only identifying field. Email stays settable on account
    *creation* only (add_fieldsets), since that's typing in credentials
    you already know, not browsing an existing user's PII."""
    admin_instance = UserAdmin(User, AdminSite())
    assert "email" not in admin_instance.list_display
    assert "email" not in admin_instance.search_fields
    assert "phone_number" not in admin_instance.search_fields
    editable_fields = [field for _, opts in admin_instance.fieldsets for field in opts["fields"]]
    assert "email" not in editable_fields
    assert "phone_number" not in editable_fields
    assert "name" in admin_instance.list_display


@pytest.mark.django_db
def test_reviewer_group_has_expected_moderation_permissions():
    reviewer = Group.objects.get(name="Reviewer")
    codenames = set(reviewer.permissions.values_list("codename", flat=True))
    assert {"view_papersubmission", "change_papersubmission"} <= codenames
    assert {"view_mcqanswerkey", "add_mcqanswerkey", "change_mcqanswerkey"} <= codenames
    assert "view_user" not in codenames  # no user-account access at all


@pytest.mark.django_db
def test_support_group_is_read_only_with_no_moderation_access():
    support = Group.objects.get(name="Support")
    codenames = set(support.permissions.values_list("codename", flat=True))
    assert {"view_user", "view_papersubmission", "view_paymenttransaction"} <= codenames
    assert not any(c.startswith(("change_", "add_", "delete_")) for c in codenames)


@pytest.mark.django_db
def test_support_staff_can_view_but_not_edit_a_paper_submission():
    """Support has view_papersubmission but not change_papersubmission —
    Django admin renders the change page read-only in that case (a real
    200, not a 403), so the actual proof is that a POST can't mutate the
    record, not the GET status code."""
    from apps.papers.factories import PaperSubmissionFactory
    from apps.papers.models import PaperStatus

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Support"))
    paper = PaperSubmissionFactory(status=PaperStatus.PENDING_REVIEW)

    client = Client()
    client.force_login(staff)

    assert client.get("/admin/papers/papersubmission/").status_code == 200
    change_url = f"/admin/papers/papersubmission/{paper.id}/change/"
    assert client.get(change_url).status_code == 200
    client.post(change_url, {"status": PaperStatus.PUBLISHED, "year": paper.year})
    paper.refresh_from_db()
    assert paper.status == PaperStatus.PENDING_REVIEW


@pytest.mark.django_db
def test_reviewer_staff_can_edit_a_paper_submission():
    from apps.papers.factories import PaperSubmissionFactory

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Reviewer"))
    paper = PaperSubmissionFactory()

    client = Client()
    client.force_login(staff)

    assert client.get(f"/admin/papers/papersubmission/{paper.id}/change/").status_code == 200


@pytest.mark.django_db
def test_password_reset_full_round_trip(api_client, mailoutbox):
    user = UserFactory(email="reset-me@example.com")
    user.set_password("OldPass!23")
    user.save()

    request_response = api_client.post("/api/auth/password-reset/", {"email": "reset-me@example.com"}, format="json")
    assert request_response.status_code == 200
    assert len(mailoutbox) == 1
    assert "reset-me@example.com" in mailoutbox[0].to
    code = mailoutbox[0].body.split()[6]  # "...reset code is 123456. It expires..."
    assert len(code.rstrip(".")) == 6

    confirm_response = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "reset-me@example.com", "code": code.rstrip("."), "new_password": "NewPass!456"},
        format="json",
    )
    assert confirm_response.status_code == 200

    user.refresh_from_db()
    assert user.check_password("NewPass!456")
    assert not user.check_password("OldPass!23")

    # The code is single-use — a second confirm with the same code fails.
    replay_response = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "reset-me@example.com", "code": code.rstrip("."), "new_password": "AnotherPass!789"},
        format="json",
    )
    assert replay_response.status_code == 400


@pytest.mark.django_db
def test_password_reset_request_does_not_reveal_whether_email_exists(api_client, mailoutbox):
    response = api_client.post("/api/auth/password-reset/", {"email": "nobody-here@example.com"}, format="json")

    assert response.status_code == 200
    assert response.data == {"detail": "If that email is registered, a reset code has been sent."}
    assert len(mailoutbox) == 0  # no account, so no email — but the caller can't tell


@pytest.mark.django_db
def test_password_reset_confirm_rejects_wrong_code(api_client):
    from .models import PasswordResetCode

    user = UserFactory(email="wrong-code@example.com")
    PasswordResetCode.issue(user)

    response = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "wrong-code@example.com", "code": "000000", "new_password": "NewPass!456"},
        format="json",
    )

    assert response.status_code == 400
    user.refresh_from_db()
    assert user.check_password("testpass123")  # UserFactory's default — unchanged


@pytest.mark.django_db
def test_password_reset_confirm_locks_out_after_too_many_wrong_attempts(api_client):
    from .models import PASSWORD_RESET_MAX_ATTEMPTS, PasswordResetCode

    user = UserFactory(email="lockout@example.com")
    reset = PasswordResetCode.issue(user)

    for _ in range(PASSWORD_RESET_MAX_ATTEMPTS):
        api_client.post(
            "/api/auth/password-reset/confirm/",
            {"email": "lockout@example.com", "code": "000000", "new_password": "NewPass!456"},
            format="json",
        )

    # Even the *correct* code is now refused — the code's attempts budget is spent.
    response = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "lockout@example.com", "code": reset.code, "new_password": "NewPass!456"},
        format="json",
    )
    assert response.status_code == 400


@pytest.mark.django_db
def test_password_reset_confirm_rejects_expired_code(api_client):
    from .models import PasswordResetCode

    user = UserFactory(email="expired@example.com")
    reset = PasswordResetCode.issue(user)
    reset.created_at = timezone.now() - datetime.timedelta(minutes=16)
    reset.save(update_fields=["created_at"])

    response = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "expired@example.com", "code": reset.code, "new_password": "NewPass!456"},
        format="json",
    )
    assert response.status_code == 400


@pytest.mark.django_db
def test_password_reset_request_is_rate_limited_per_ip(api_client, monkeypatch):
    from rest_framework.throttling import SimpleRateThrottle

    monkeypatch.setitem(SimpleRateThrottle.THROTTLE_RATES, "password_reset_request", "2/hour")
    UserFactory(email="ratelimited@example.com")

    first = api_client.post("/api/auth/password-reset/", {"email": "ratelimited@example.com"}, format="json")
    second = api_client.post("/api/auth/password-reset/", {"email": "ratelimited@example.com"}, format="json")
    third = api_client.post("/api/auth/password-reset/", {"email": "ratelimited@example.com"}, format="json")

    assert first.status_code == 200
    assert second.status_code == 200
    assert third.status_code == 429
