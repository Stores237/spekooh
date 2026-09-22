import datetime
from unittest import mock

import pytest
from django.contrib.admin.sites import AdminSite
from django.contrib.auth.models import Group
from django.contrib.auth.tokens import default_token_generator
from django.core.management import call_command
from django.db import IntegrityError
from django.test import Client, RequestFactory, override_settings
from django.utils import timezone
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework.test import APIClient

from .admin import StaffAccountAddForm, StaffAccountAdmin, UserAdmin
from .factories import UserFactory
from .models import AccountType, StaffAccount, User


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
def test_refresh_rotates_the_refresh_token_and_blacklists_the_old_one(api_client):
    """Security hardening (2026-09-02): SIMPLE_JWT.ROTATE_REFRESH_TOKENS +
    BLACKLIST_AFTER_ROTATION — a leaked refresh token is now single-use
    instead of valid, unrevocable, for its whole lifetime. Real end-to-end
    check, not just a settings assertion: an old refresh token that's
    already been rotated away actually gets rejected on reuse."""
    UserFactory(email="rotate@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "rotate@example.com", "password": "correcthorse123"}, format="json"
    )
    old_refresh = login.data["refresh"]

    first_refresh = api_client.post("/api/auth/refresh/", {"refresh": old_refresh}, format="json")
    assert first_refresh.status_code == 200
    new_refresh = first_refresh.data["refresh"]
    assert new_refresh != old_refresh  # a genuinely new token, not the same one echoed back

    reuse_attempt = api_client.post("/api/auth/refresh/", {"refresh": old_refresh}, format="json")
    assert reuse_attempt.status_code == 401  # the blacklisted old token no longer works

    still_works = api_client.post("/api/auth/refresh/", {"refresh": new_refresh}, format="json")
    assert still_works.status_code == 200  # the legitimate, rotated-to token is unaffected


@pytest.mark.django_db
def test_a_second_login_revokes_the_first_devices_session():
    """Owner-reported security gap (2026-09-18): shared/stolen credentials
    used to let a second device log in and quietly coexist with the real
    owner's session forever, undetected. A new login must now boot every
    other device's refresh token immediately."""
    UserFactory(email="shared-creds@example.com", password="correcthorse123")
    device_a = APIClient()
    device_b = APIClient()

    login_a = device_a.post(
        "/api/auth/login/", {"email": "shared-creds@example.com", "password": "correcthorse123"}, format="json"
    )
    assert login_a.status_code == 200
    refresh_a = login_a.data["refresh"]

    login_b = device_b.post(
        "/api/auth/login/", {"email": "shared-creds@example.com", "password": "correcthorse123"}, format="json"
    )
    assert login_b.status_code == 200
    refresh_b = login_b.data["refresh"]

    # Device A's session is dead the moment device B logs in.
    device_a_refresh = device_a.post("/api/auth/refresh/", {"refresh": refresh_a}, format="json")
    assert device_a_refresh.status_code == 401
    assert device_a_refresh.data["detail"] == "Token is blacklisted"

    # Device B, the one that just logged in, is unaffected.
    device_b_refresh = device_b.post("/api/auth/refresh/", {"refresh": refresh_b}, format="json")
    assert device_b_refresh.status_code == 200


@pytest.mark.django_db
def test_single_session_enforcement_catches_a_devices_rotated_refresh_token_too():
    """Not just the token from the original login -- a device that already
    rotated its refresh token at least once must also get kicked out by a
    later login elsewhere, since revoke_other_sessions has to look up every
    OutstandingToken row for the account, not just the newest one."""
    UserFactory(email="rotated-then-shared@example.com", password="correcthorse123")
    device_a = APIClient()
    device_b = APIClient()

    login_a = device_a.post(
        "/api/auth/login/",
        {"email": "rotated-then-shared@example.com", "password": "correcthorse123"},
        format="json",
    )
    rotated = device_a.post("/api/auth/refresh/", {"refresh": login_a.data["refresh"]}, format="json")
    assert rotated.status_code == 200
    rotated_refresh_a = rotated.data["refresh"]

    login_b = device_b.post(
        "/api/auth/login/",
        {"email": "rotated-then-shared@example.com", "password": "correcthorse123"},
        format="json",
    )
    assert login_b.status_code == 200

    device_a_refresh = device_a.post("/api/auth/refresh/", {"refresh": rotated_refresh_a}, format="json")
    assert device_a_refresh.status_code == 401


@pytest.mark.django_db
def test_password_reset_confirm_revokes_every_existing_session(mailoutbox):
    """A real password reset must boot out any live session on the
    account too, not just block future logins with the old password --
    if someone else already had a valid session, this is exactly the
    moment that should end it."""
    user = UserFactory(email="reset-kills-sessions@example.com")
    user.set_password("OldPass!23")
    user.save()
    api_client = APIClient()

    login = api_client.post(
        "/api/auth/login/", {"email": "reset-kills-sessions@example.com", "password": "OldPass!23"}, format="json"
    )
    assert login.status_code == 200
    old_refresh = login.data["refresh"]

    api_client.post("/api/auth/password-reset/", {"email": "reset-kills-sessions@example.com"}, format="json")
    code = mailoutbox[0].body.split()[6].rstrip(".")
    confirm = api_client.post(
        "/api/auth/password-reset/confirm/",
        {"email": "reset-kills-sessions@example.com", "code": code, "new_password": "NewPass!456"},
        format="json",
    )
    assert confirm.status_code == 200

    stale_refresh = api_client.post("/api/auth/refresh/", {"refresh": old_refresh}, format="json")
    assert stale_refresh.status_code == 401


@pytest.mark.django_db
def test_login_is_rate_limited_per_ip(api_client, monkeypatch):
    """Security hardening (2026-09-02): LoginView had no throttle at all —
    nothing stopped a script from brute-forcing/credential-stuffing a real
    account's password. Same monkeypatch approach as
    test_guest_endpoint_is_rate_limited_per_ip — see that test's docstring
    for why overriding settings.REST_FRAMEWORK directly wouldn't work
    here."""
    from rest_framework.throttling import SimpleRateThrottle

    monkeypatch.setitem(SimpleRateThrottle.THROTTLE_RATES, "login", "2/hour")
    UserFactory(email="throttlelogin@example.com", password="correcthorse123")

    first = api_client.post(
        "/api/auth/login/", {"email": "throttlelogin@example.com", "password": "wrongpass"}, format="json"
    )
    second = api_client.post(
        "/api/auth/login/", {"email": "throttlelogin@example.com", "password": "wrongpass"}, format="json"
    )
    third = api_client.post(
        "/api/auth/login/", {"email": "throttlelogin@example.com", "password": "wrongpass"}, format="json"
    )

    assert first.status_code == 401
    assert second.status_code == 401
    assert third.status_code == 429


@pytest.mark.django_db
def test_register_is_rate_limited_per_ip(api_client, monkeypatch):
    """Security hardening (2026-09-02): RegisterView had no throttle at all
    — nothing stopped a script from creating unlimited real accounts."""
    from rest_framework.throttling import SimpleRateThrottle

    monkeypatch.setitem(SimpleRateThrottle.THROTTLE_RATES, "register", "2/hour")

    first = api_client.post(
        "/api/auth/register/",
        {"email": "throttle1@example.com", "name": "A", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )
    second = api_client.post(
        "/api/auth/register/",
        {"email": "throttle2@example.com", "name": "B", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )
    third = api_client.post(
        "/api/auth/register/",
        {"email": "throttle3@example.com", "name": "C", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )

    assert first.status_code == 201
    assert second.status_code == 201
    assert third.status_code == 429


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
def test_me_reports_is_plus_subscriber_honestly():
    """A brand new account isn't a subscriber; a real active Subscription
    row flips it — this is what LoggedInHomeScreen's post-trial banner
    gates on to avoid nagging a user who's already paying."""
    from apps.payments.factories import SubscriptionFactory

    user = UserFactory(email="plus@example.com", password="correcthorse123")
    api_client = APIClient()
    login = api_client.post("/api/auth/login/", {"email": "plus@example.com", "password": "correcthorse123"}, format="json")
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.get("/api/auth/me/")
    assert response.data["is_plus_subscriber"] is False

    SubscriptionFactory(user=user)
    response = api_client.get("/api/auth/me/")
    assert response.data["is_plus_subscriber"] is True


@pytest.mark.django_db
def test_registered_user_requires_email_at_db_level():
    with pytest.raises(IntegrityError):
        User.objects.create(account_type=AccountType.REGISTERED, email=None)


def _tiny_png():
    # A real, minimal (1x1 transparent pixel) PNG — not a fake/empty file,
    # since ImageField validates actual image content, not just an extension.
    import base64

    from django.core.files.uploadedfile import SimpleUploadedFile

    png_bytes = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    )
    return SimpleUploadedFile("avatar.png", png_bytes, content_type="image/png")


@pytest.mark.django_db
def test_me_patch_uploads_a_real_avatar(api_client):
    user = UserFactory(email="avatarme@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "avatarme@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.patch("/api/auth/me/", {"avatar": _tiny_png()}, format="multipart")

    assert response.status_code == 200
    assert response.data["avatar_url"] is not None
    user.refresh_from_db()
    assert user.avatar.name  # a real file was actually stored


@pytest.mark.django_db
def test_me_returns_null_avatar_url_when_none_set(api_client):
    UserFactory(email="noavatar@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "noavatar@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.get("/api/auth/me/")

    assert response.status_code == 200
    assert response.data["avatar_url"] is None


@pytest.mark.django_db
def test_me_patch_updates_name_and_phone_number(api_client):
    """The real "Edit profile" flow (owner decision, 2026-08-28, adapting a
    reference username/email/phone edit sheet) — no new endpoint needed,
    PATCH /auth/me/ already accepts these fields."""
    UserFactory(email="editme@example.com", password="correcthorse123", name="Old Name")
    login = api_client.post(
        "/api/auth/login/", {"email": "editme@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.patch(
        "/api/auth/me/", {"name": "New Name", "phone_number": "+237670000001"}, format="json"
    )

    assert response.status_code == 200
    assert response.data["name"] == "New Name"
    assert response.data["phone_number"] == "+237670000001"


@pytest.mark.django_db
def test_me_patch_changing_email_resets_verification_and_sends_a_new_code(api_client, mailoutbox):
    user = UserFactory(email="oldaddress@example.com", password="correcthorse123")
    user.email_verified_at = timezone.now()
    user.save(update_fields=["email_verified_at"])
    login = api_client.post(
        "/api/auth/login/", {"email": "oldaddress@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.patch("/api/auth/me/", {"email": "newaddress@example.com"}, format="json")

    assert response.status_code == 200
    assert response.data["email_verified"] is False
    user.refresh_from_db()
    assert user.email == "newaddress@example.com"
    assert user.email_verified_at is None
    assert len(mailoutbox) == 1
    assert "newaddress@example.com" in mailoutbox[0].to


@pytest.mark.django_db
def test_me_patch_keeping_the_same_email_does_not_reset_verification(api_client, mailoutbox):
    user = UserFactory(email="staysame@example.com", password="correcthorse123", name="Old Name")
    user.email_verified_at = timezone.now()
    user.save(update_fields=["email_verified_at"])
    login = api_client.post(
        "/api/auth/login/", {"email": "staysame@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    response = api_client.patch(
        "/api/auth/me/", {"name": "New Name", "email": "staysame@example.com"}, format="json"
    )

    assert response.status_code == 200
    assert response.data["email_verified"] is True
    user.refresh_from_db()
    assert user.email_verified_at is not None
    assert len(mailoutbox) == 0


@pytest.mark.django_db
def test_me_patch_replaces_an_existing_avatar(api_client):
    user = UserFactory(email="replaceavatar@example.com", password="correcthorse123")
    login = api_client.post(
        "/api/auth/login/", {"email": "replaceavatar@example.com", "password": "correcthorse123"}, format="json"
    )
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
    first = api_client.patch("/api/auth/me/", {"avatar": _tiny_png()}, format="multipart")
    assert first.status_code == 200
    user.refresh_from_db()
    assert user.avatar.name  # first upload actually landed

    # A second real upload succeeds the same way — this isn't a one-shot
    # "set once" field.
    second = api_client.patch("/api/auth/me/", {"avatar": _tiny_png()}, format="multipart")

    assert second.status_code == 200
    user.refresh_from_db()
    assert user.avatar.name


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


# --- ensure_superuser (2026-08-31, Render staging deployment) ---
# Render's free web-service plan has no Shell tab and no one-off Jobs — the
# usual interactive `createsuperuser` has nowhere to run. This command runs
# unconditionally on every deploy (see build.sh) instead, so it has to be a
# genuine no-op past the first successful run, not just "safe to run twice
# because nobody will."


@pytest.mark.django_db
def test_ensure_superuser_creates_one_from_env_vars(monkeypatch):
    monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "owner@example.com")
    monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "a-real-strong-password")

    call_command("ensure_superuser")

    user = User.objects.get(email="owner@example.com")
    assert user.is_staff is True
    assert user.is_superuser is True
    assert user.check_password("a-real-strong-password") is True


@pytest.mark.django_db
def test_ensure_superuser_is_a_noop_without_both_env_vars(monkeypatch):
    monkeypatch.delenv("DJANGO_SUPERUSER_EMAIL", raising=False)
    monkeypatch.delenv("DJANGO_SUPERUSER_PASSWORD", raising=False)

    call_command("ensure_superuser")

    assert User.objects.count() == 0


@pytest.mark.django_db
def test_ensure_superuser_does_not_recreate_or_error_on_a_second_deploy(monkeypatch):
    """The real scenario this exists for: build.sh runs this on every
    deploy, not just the first — a second run must not error out (breaking
    set -o errexit in build.sh) or reset the real password someone may have
    since changed via /admin/."""
    monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "owner@example.com")
    monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "a-real-strong-password")
    call_command("ensure_superuser")
    original_password_hash = User.objects.get(email="owner@example.com").password

    call_command("ensure_superuser")

    assert User.objects.filter(email="owner@example.com").count() == 1
    assert User.objects.get(email="owner@example.com").password == original_password_hash


# --- delete_test_accounts (2026-08-31) ---
# Live-testing a real deployment (see RENDER_STAGING.md) isn't mocked — a
# curl or browser round-trip against /api/auth/register/ that verifies a
# fix works leaves the same kind of real row a genuine signup would. This
# is the cleanup for that, gated to the one domain no real student uses.


@pytest.mark.django_db
def test_delete_test_accounts_removes_example_dot_com_users():
    UserFactory(email="staging-test-123@example.com")
    UserFactory(email="Reverify-Test-456@EXAMPLE.COM")  # case-insensitive match

    call_command("delete_test_accounts")

    assert User.objects.filter(email__iendswith="@example.com").count() == 0


@pytest.mark.django_db
def test_delete_test_accounts_never_touches_a_real_user():
    real_user = UserFactory(email="real-student@gmail.com")

    call_command("delete_test_accounts")

    assert User.objects.filter(id=real_user.id).exists()


@pytest.mark.django_db
def test_delete_test_accounts_is_a_noop_when_none_exist():
    UserFactory(email="real-student@gmail.com")

    call_command("delete_test_accounts")  # must not raise

    assert User.objects.count() == 1


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
def test_reviewer_group_can_manage_notes_and_pamphlets_content():
    """Owner decision (2026-09-01): Notes/Pamphlets were superuser-only —
    Reviewer (the team already moderating papers/guides) now manages this
    catalog content too. PartnerBookshop stays add/change only: deleting one
    cascades and deletes every pamphlet under it (Pamphlet.partner is
    on_delete=CASCADE) — a business decision the Owner tier keeps, not a
    content-moderation one."""
    reviewer = Group.objects.get(name="Reviewer")
    codenames = set(reviewer.permissions.values_list("codename", flat=True))
    assert {"view_note", "add_note", "change_note", "delete_note"} <= codenames
    assert {"view_pamphlet", "add_pamphlet", "change_pamphlet", "delete_pamphlet"} <= codenames
    assert {"view_partnerbookshop", "add_partnerbookshop", "change_partnerbookshop"} <= codenames
    assert "delete_partnerbookshop" not in codenames
    # The pre-existing paper-moderation permissions must still be there —
    # this migration adds to the group, it must never silently replace it.
    assert {"view_papersubmission", "change_papersubmission"} <= codenames


@pytest.mark.django_db
def test_reviewer_staff_can_actually_create_a_note_and_a_pamphlet():
    from apps.pamphlets.factories import PartnerBookshopFactory

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Reviewer"))
    partner = PartnerBookshopFactory()

    client = Client()
    client.force_login(staff)

    note_response = client.post(
        "/admin/notes/note/add/",
        {"title": "Physics Revision Notes", "subtitle": "", "subject_title": "", "academic_level": "", "sort_order": 0},
    )
    assert note_response.status_code == 302  # real redirect-after-save, not a re-rendered form with errors
    from apps.notes.models import Note

    assert Note.objects.filter(title="Physics Revision Notes").exists()

    pamphlet_response = client.post(
        "/admin/pamphlets/pamphlet/add/",
        {
            "partner": partner.id,
            "title": "GCE Physics Pack",
            "description": "",
            "subject_title": "",
            "academic_level": "",
            "price_fcfa": 2500,
            "delivery_available": False,
            "delivery_fee_fcfa": 0,
            "is_active": "on",
            "is_featured": "",
            "display_order": 0,
        },
    )
    assert pamphlet_response.status_code == 302
    from apps.pamphlets.models import Pamphlet

    assert Pamphlet.objects.filter(title="GCE Physics Pack").exists()


@pytest.mark.django_db
def test_reviewer_staff_cannot_delete_a_partner_bookshop():
    from apps.pamphlets.factories import PartnerBookshopFactory

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Reviewer"))
    partner = PartnerBookshopFactory()

    client = Client()
    client.force_login(staff)

    response = client.post(f"/admin/pamphlets/partnerbookshop/{partner.id}/delete/", {"post": "yes"})
    assert response.status_code == 403
    from apps.pamphlets.models import PartnerBookshop

    assert PartnerBookshop.objects.filter(id=partner.id).exists()


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
def test_integration_ops_group_has_expected_partner_pamphlet_permissions():
    """Owner decision (2026-09-16): Integration Ops is the partner-onboarding
    / pamphlet-pickup-ops team, distinct from Reviewer's content-moderation
    scope even though both touch Pamphlet/PartnerBookshop. PamphletOrder and
    AdminFlagQueue access (view/change) is new -- Reviewer never got those."""
    ops = Group.objects.get(name="Integration Ops")
    codenames = set(ops.permissions.values_list("codename", flat=True))
    assert {"view_pamphlet", "add_pamphlet", "change_pamphlet", "delete_pamphlet"} <= codenames
    assert {"view_partnerbookshop", "add_partnerbookshop", "change_partnerbookshop"} <= codenames
    assert "delete_partnerbookshop" not in codenames
    assert {"view_pamphletorder", "change_pamphletorder"} <= codenames
    assert {"view_adminflagqueue", "change_adminflagqueue"} <= codenames
    assert "view_user" not in codenames  # no user-account access at all


@pytest.mark.django_db
def test_integration_ops_staff_can_set_up_a_new_partner_and_pamphlet():
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))

    client = Client()
    client.force_login(staff)

    partner_response = client.post(
        "/admin/pamphlets/partnerbookshop/add/",
        {
            "name": "New Horizons Bookshop",
            "full_name": "Jean Mbarga",
            "contact_email": "jean@example.com",
            "contact_phone": "",
            "whatsapp_number": "",
            "orange_money_number": "670000000",
            "momo_number": "",
            "cni_number": "1234567890",
            "nui_number": "P000000000000A",
            "location": "Molyko, Buea",
            "commission_percent": 5,
        },
    )
    assert partner_response.status_code == 302
    from apps.pamphlets.models import PartnerBookshop

    partner = PartnerBookshop.objects.get(name="New Horizons Bookshop")

    pamphlet_response = client.post(
        "/admin/pamphlets/pamphlet/add/",
        {
            "partner": partner.id,
            "title": "GCE Chemistry Pack",
            "description": "",
            "subject_title": "",
            "academic_level": "",
            "price_fcfa": 2500,
            "delivery_available": False,
            "delivery_fee_fcfa": 0,
            "is_active": "on",
            "is_featured": "",
            "display_order": 0,
        },
    )
    assert pamphlet_response.status_code == 302
    from apps.pamphlets.models import Pamphlet

    assert Pamphlet.objects.filter(title="GCE Chemistry Pack", partner=partner).exists()


@pytest.mark.django_db
def test_integration_ops_cannot_register_a_partner_with_neither_mobile_money_number():
    """Owner decision (2026-09-17, partner KYC hardening): at least one of
    Orange Money/MoMo is required -- these are the real, ID-linked numbers
    a handover-redemption OTP gets sent to (see PartnerBookshop.clean/
    verification_phone), so a partner with neither can never actually
    confirm a pickup."""
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    response = client.post(
        "/admin/pamphlets/partnerbookshop/add/",
        {
            "name": "No Money Bookshop",
            "full_name": "Jean Mbarga",
            "contact_email": "jean@example.com",
            "contact_phone": "",
            "whatsapp_number": "",
            "orange_money_number": "",
            "momo_number": "",
            "cni_number": "1234567890",
            "nui_number": "P000000000000A",
            "location": "Molyko, Buea",
            "commission_percent": 5,
        },
    )
    assert response.status_code == 200  # re-rendered form, not a redirect
    from apps.pamphlets.models import PartnerBookshop

    assert not PartnerBookshop.objects.filter(name="No Money Bookshop").exists()


@pytest.mark.django_db
def test_integration_ops_cannot_register_a_partner_missing_a_compulsory_kyc_field():
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    response = client.post(
        "/admin/pamphlets/partnerbookshop/add/",
        {
            "name": "Missing CNI Bookshop",
            "full_name": "Jean Mbarga",
            "contact_email": "jean@example.com",
            "contact_phone": "",
            "whatsapp_number": "",
            "orange_money_number": "670000000",
            "momo_number": "",
            "cni_number": "",
            "nui_number": "P000000000000A",
            "location": "Molyko, Buea",
            "commission_percent": 5,
        },
    )
    assert response.status_code == 200
    from apps.pamphlets.models import PartnerBookshop

    assert not PartnerBookshop.objects.filter(name="Missing CNI Bookshop").exists()


@pytest.mark.django_db
def test_integration_ops_staff_can_upload_a_cover_image_when_creating_a_pamphlet():
    from apps.pamphlets.factories import PartnerBookshopFactory

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    partner = PartnerBookshopFactory()

    client = Client()
    client.force_login(staff)

    response = client.post(
        "/admin/pamphlets/pamphlet/add/",
        {
            "partner": partner.id,
            "title": "GCE Chemistry Pack",
            "description": "",
            "subject_title": "",
            "academic_level": "",
            "price_fcfa": 2500,
            "delivery_available": False,
            "delivery_fee_fcfa": 0,
            "is_active": "on",
            "is_featured": "",
            "display_order": 0,
            "cover_image": _tiny_png(),
        },
    )
    assert response.status_code == 302
    from apps.pamphlets.models import Pamphlet

    pamphlet = Pamphlet.objects.get(title="GCE Chemistry Pack")
    assert pamphlet.cover_image.name is not None


@pytest.mark.django_db
def test_integration_ops_staff_cannot_delete_a_partner_bookshop():
    from apps.pamphlets.factories import PartnerBookshopFactory

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    partner = PartnerBookshopFactory()

    client = Client()
    client.force_login(staff)

    response = client.post(f"/admin/pamphlets/partnerbookshop/{partner.id}/delete/", {"post": "yes"})
    assert response.status_code == 403
    from apps.pamphlets.models import PartnerBookshop

    assert PartnerBookshop.objects.filter(id=partner.id).exists()


@pytest.mark.django_db
def test_integration_ops_group_has_note_permissions():
    """Owner request (2026-09-17): Integration Ops uploads the PDF for a
    Note the same way it enters a Pamphlet's details -- layered onto the
    group's existing pamphlets/pamphletorder/adminflagqueue permissions
    from 0011, not replacing them."""
    ops = Group.objects.get(name="Integration Ops")
    codenames = set(ops.permissions.values_list("codename", flat=True))
    assert {"view_note", "add_note", "change_note", "delete_note"} <= codenames
    assert {"view_pamphlet", "add_pamphlet", "change_pamphlet", "delete_pamphlet"} <= codenames


@pytest.mark.django_db
def test_integration_ops_group_has_redeemverification_view_permission():
    """Owner request (2026-09-17): RedeemVerification is registered
    read-only in admin as an audit trail for handover codes, including
    support overrides -- view-only (RedeemVerificationAdmin itself blocks
    add/change/delete regardless of what permissions exist), layered onto
    the group's existing permissions, not replacing them."""
    ops = Group.objects.get(name="Integration Ops")
    codenames = set(ops.permissions.values_list("codename", flat=True))
    assert "view_redeemverification" in codenames
    assert {"view_pamphletorder", "change_pamphletorder"} <= codenames


@pytest.mark.django_db
def test_integration_ops_staff_can_view_the_redeemverification_audit_trail():
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    response = client.get("/admin/pamphlets/redeemverification/")

    assert response.status_code == 200


@pytest.mark.django_db
def test_integration_ops_can_upload_real_cni_and_nui_documents_for_a_partner():
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    from django.core.files.uploadedfile import SimpleUploadedFile

    png_bytes = _tiny_png().read()
    response = client.post(
        "/admin/pamphlets/partnerbookshop/add/",
        {
            "name": "Real Documents Bookshop",
            "full_name": "Jean Mbarga",
            "contact_email": "jean-real@example.com",
            "contact_phone": "",
            "whatsapp_number": "",
            "orange_money_number": "670000000",
            "momo_number": "",
            "cni_number": "1234567890",
            "cni_document": SimpleUploadedFile("cni.png", png_bytes, content_type="image/png"),
            "nui_number": "P000000000000A",
            "nui_document": SimpleUploadedFile("nui.png", png_bytes, content_type="image/png"),
            "location": "Molyko, Buea",
            "commission_percent": 5,
        },
    )
    assert response.status_code == 302
    from apps.pamphlets.models import PartnerBookshop

    partner = PartnerBookshop.objects.get(name="Real Documents Bookshop")
    assert partner.cni_document.name is not None
    assert partner.nui_document.name is not None


@pytest.mark.django_db
def test_integration_ops_cannot_upload_a_fake_cni_document_disguised_as_an_image():
    """Security hardening (2026-09-18): a real magic-byte check for these
    admin-only KYC uploads too, not just the extension -- same gap this
    app already closed for papers/avatars (apps.papers.validation)."""
    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    from django.core.files.uploadedfile import SimpleUploadedFile

    response = client.post(
        "/admin/pamphlets/partnerbookshop/add/",
        {
            "name": "Fake CNI Bookshop",
            "full_name": "Jean Mbarga",
            "contact_email": "jean-fake@example.com",
            "contact_phone": "",
            "whatsapp_number": "",
            "orange_money_number": "670000000",
            "momo_number": "",
            "cni_number": "1234567890",
            "cni_document": SimpleUploadedFile("cni.png", b"not a real png at all", content_type="image/png"),
            "nui_number": "P000000000000A",
            "location": "Molyko, Buea",
            "commission_percent": 5,
        },
    )
    assert response.status_code == 200  # re-rendered form with a validation error, not a redirect
    from apps.pamphlets.models import PartnerBookshop

    assert not PartnerBookshop.objects.filter(name="Fake CNI Bookshop").exists()


@pytest.mark.django_db
def test_integration_ops_staff_can_upload_a_pdf_for_a_note():
    from django.core.files.uploadedfile import SimpleUploadedFile

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))

    client = Client()
    client.force_login(staff)

    pdf = SimpleUploadedFile("physics-revision.pdf", b"%PDF-1.4 fake pdf bytes", content_type="application/pdf")
    response = client.post(
        "/admin/notes/note/add/",
        {
            "title": "Physics Revision Notes",
            "subtitle": "",
            "subject_title": "",
            "academic_level": "",
            "sort_order": 0,
            "pdf_file": pdf,
        },
    )
    assert response.status_code == 302
    from apps.notes.models import Note

    note = Note.objects.get(title="Physics Revision Notes")
    assert note.pdf_file.name is not None
    assert "physics-revision" in note.pdf_file.name


@pytest.mark.django_db
def test_integration_ops_cannot_upload_a_fake_pdf_for_a_note():
    """Security hardening (2026-09-18): a real magic-byte check for
    Note.pdf_file too -- a file renamed to claim a .pdf extension it
    isn't is genuinely rejected, not just trusted."""
    from django.core.files.uploadedfile import SimpleUploadedFile

    staff = UserFactory(is_staff=True)
    staff.groups.add(Group.objects.get(name="Integration Ops"))
    client = Client()
    client.force_login(staff)

    fake_pdf = SimpleUploadedFile("notes.pdf", b"just plain text, not a real pdf", content_type="application/pdf")
    response = client.post(
        "/admin/notes/note/add/",
        {
            "title": "Fake Notes",
            "subtitle": "",
            "subject_title": "",
            "academic_level": "",
            "sort_order": 0,
            "pdf_file": fake_pdf,
        },
    )
    assert response.status_code == 200  # re-rendered form with a validation error, not a redirect
    from apps.notes.models import Note

    assert not Note.objects.filter(title="Fake Notes").exists()


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


@pytest.mark.django_db
def test_register_rejects_an_unverifiable_email_domain(api_client, settings, monkeypatch):
    from . import services

    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"
    monkeypatch.setattr(services, "email_domain_is_verifiable", lambda email: False)

    response = api_client.post(
        "/api/auth/register/",
        {"email": "typo@gmial.com", "name": "Typo", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )

    assert response.status_code == 400
    assert not User.objects.filter(email="typo@gmial.com").exists()


@pytest.mark.django_db
def test_email_domain_check_fails_open_on_an_unexpected_response_shape(settings, monkeypatch):
    """Regression: real bug found live 2026-09-15 — registering with an empty
    email 500'd on staging (not reproducible locally against the same edge
    function code, so the exact staging-side cause wasn't confirmed without
    Sentry access). email_domain_is_verifiable's own docstring promises it
    "fails open ... or errors for any other reason", but the old except
    clause only covered (RequestException, ValueError) — a 200 response
    whose body isn't a dict (here, a bare list) raises AttributeError on
    `.get()`, which wasn't caught, crashing registration outright instead of
    failing open as designed."""
    from . import services

    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = "https://example.supabase.co/functions/v1"

    class _MalformedResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return []  # not a dict — .get() would raise AttributeError

    monkeypatch.setattr(services.requests, "post", lambda *a, **k: _MalformedResponse())

    assert services.email_domain_is_verifiable("someone@example.com") is True


@pytest.mark.django_db
def test_register_succeeds_when_edge_function_is_not_configured(api_client, settings):
    # Default posture (no SUPABASE_EDGE_FUNCTION_BASE_URL set): the check is
    # skipped entirely rather than blocking registration.
    settings.SUPABASE_EDGE_FUNCTION_BASE_URL = None

    response = api_client.post(
        "/api/auth/register/",
        {"email": "noedgefn@example.com", "name": "No Edge Fn", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )

    assert response.status_code == 201


@pytest.mark.django_db
def test_register_issues_and_sends_a_real_verification_code(api_client, mailoutbox):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "verifyme@example.com", "name": "Verify Me", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )

    assert response.status_code == 201
    assert response.data["user"]["email_verified"] is False
    assert len(mailoutbox) == 1
    assert "verifyme@example.com" in mailoutbox[0].to

    user = User.objects.get(email="verifyme@example.com")
    from .models import EmailVerificationCode

    assert EmailVerificationCode.objects.filter(user=user).exists()


@pytest.mark.django_db
def test_email_verification_full_round_trip(api_client, mailoutbox):
    from .models import EmailVerificationCode

    register_response = api_client.post(
        "/api/auth/register/",
        {"email": "confirmflow@example.com", "name": "Confirm Flow", "password": "S0mePass!23", "terms_accepted": True},
        format="json",
    )
    access_token = register_response.data["access"]
    code = EmailVerificationCode.objects.get(user__email="confirmflow@example.com").code

    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
    confirm_response = api_client.post("/api/auth/verify-email/", {"code": code}, format="json")

    assert confirm_response.status_code == 200
    assert confirm_response.data["email_verified"] is True
    user = User.objects.get(email="confirmflow@example.com")
    assert user.email_verified_at is not None


@pytest.mark.django_db
def test_email_verification_requires_authentication(api_client):
    response = api_client.post("/api/auth/verify-email/", {"code": "123456"}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_email_verification_rejects_wrong_code(api_client):
    from .models import EmailVerificationCode

    user = UserFactory(email="wrongcode@example.com")
    EmailVerificationCode.issue(user)
    api_client.force_authenticate(user)

    response = api_client.post("/api/auth/verify-email/", {"code": "000000"}, format="json")

    assert response.status_code == 400
    user.refresh_from_db()
    assert user.email_verified_at is None


@pytest.mark.django_db
def test_email_verification_resend_issues_a_fresh_code(api_client, mailoutbox):
    from .models import EmailVerificationCode

    user = UserFactory(email="resend@example.com")
    api_client.force_authenticate(user)

    response = api_client.post("/api/auth/verify-email/resend/", {}, format="json")

    assert response.status_code == 200
    assert len(mailoutbox) == 1
    assert EmailVerificationCode.objects.filter(user=user).count() == 1


@pytest.mark.django_db
def test_email_verification_resend_is_rate_limited(api_client, monkeypatch):
    from rest_framework.throttling import SimpleRateThrottle

    monkeypatch.setitem(SimpleRateThrottle.THROTTLE_RATES, "email_verification_resend", "2/hour")
    user = UserFactory(email="ratelimitresend@example.com")
    api_client.force_authenticate(user)

    first = api_client.post("/api/auth/verify-email/resend/", {}, format="json")
    second = api_client.post("/api/auth/verify-email/resend/", {}, format="json")
    third = api_client.post("/api/auth/verify-email/resend/", {}, format="json")

    assert first.status_code == 200
    assert second.status_code == 200
    assert third.status_code == 429


@pytest.mark.django_db
def test_login_allows_unverified_account_when_flag_is_off(api_client, settings):
    # Default posture — no real email provider is wired up yet, so this
    # must stay off by default (see REQUIRE_EMAIL_VERIFICATION's docstring).
    settings.REQUIRE_EMAIL_VERIFICATION = False
    UserFactory(email="unverified-flagoff@example.com")

    response = api_client.post(
        "/api/auth/login/", {"email": "unverified-flagoff@example.com", "password": "testpass123"}, format="json"
    )

    assert response.status_code == 200


@pytest.mark.django_db
def test_login_refuses_unverified_account_when_flag_is_on(api_client, settings):
    settings.REQUIRE_EMAIL_VERIFICATION = True
    UserFactory(email="unverified-flagon@example.com")

    response = api_client.post(
        "/api/auth/login/", {"email": "unverified-flagon@example.com", "password": "testpass123"}, format="json"
    )

    assert response.status_code == 400
    assert "email_not_verified" in response.data.get("code", [])


@pytest.mark.django_db
def test_login_allows_verified_account_when_flag_is_on(api_client, settings):
    settings.REQUIRE_EMAIL_VERIFICATION = True
    user = UserFactory(email="verified-flagon@example.com")
    user.email_verified_at = timezone.now()
    user.save(update_fields=["email_verified_at"])

    response = api_client.post(
        "/api/auth/login/", {"email": "verified-flagon@example.com", "password": "testpass123"}, format="json"
    )

    assert response.status_code == 200


@pytest.mark.django_db
def test_login_never_gates_guest_accounts(api_client, settings):
    # Guests have no email at all — email_verified_at is always null for
    # them, but they never log in via this endpoint (no password), so
    # there's nothing to actually assert beyond "the flag only ever
    # touches REGISTERED accounts" (see the serializer's account_type check).
    settings.REQUIRE_EMAIL_VERIFICATION = True
    guest = User.objects.create_guest(name="A Guest")
    assert guest.email_verified_at is None
    assert guest.account_type == AccountType.GUEST


@pytest.mark.django_db
def test_email_verification_request_by_email_issues_a_code_for_a_real_unverified_account(api_client, mailoutbox):
    from .models import EmailVerificationCode

    user = UserFactory(email="recoverme@example.com")

    response = api_client.post("/api/auth/verify-email/request-by-email/", {"email": "recoverme@example.com"}, format="json")

    assert response.status_code == 200
    assert len(mailoutbox) == 1
    assert EmailVerificationCode.objects.filter(user=user).exists()


@pytest.mark.django_db
def test_email_verification_request_by_email_does_not_reveal_account_state(api_client, mailoutbox):
    # Neither a nonexistent email nor an already-verified one gets a code —
    # but the caller sees the exact same response either way.
    verified_user = UserFactory(email="alreadyverified@example.com")
    verified_user.email_verified_at = timezone.now()
    verified_user.save(update_fields=["email_verified_at"])

    nonexistent_response = api_client.post(
        "/api/auth/verify-email/request-by-email/", {"email": "nobody@example.com"}, format="json"
    )
    verified_response = api_client.post(
        "/api/auth/verify-email/request-by-email/", {"email": "alreadyverified@example.com"}, format="json"
    )

    assert nonexistent_response.status_code == 200
    assert verified_response.status_code == 200
    assert nonexistent_response.data == verified_response.data
    assert len(mailoutbox) == 0


@pytest.mark.django_db
def test_email_verification_confirm_by_email_unlocks_a_stranded_login(api_client, settings):
    from .models import EmailVerificationCode

    settings.REQUIRE_EMAIL_VERIFICATION = True
    user = UserFactory(email="stranded@example.com")
    # Simulate the original signup code having long expired.
    verification = EmailVerificationCode.issue(user)

    blocked = api_client.post(
        "/api/auth/login/", {"email": "stranded@example.com", "password": "testpass123"}, format="json"
    )
    assert blocked.status_code == 400

    confirm = api_client.post(
        "/api/auth/verify-email/confirm-by-email/",
        {"email": "stranded@example.com", "code": verification.code},
        format="json",
    )
    assert confirm.status_code == 200

    unblocked = api_client.post(
        "/api/auth/login/", {"email": "stranded@example.com", "password": "testpass123"}, format="json"
    )
    assert unblocked.status_code == 200


@pytest.mark.django_db
def test_email_verification_confirm_by_email_rejects_wrong_code(api_client):
    from .models import EmailVerificationCode

    user = UserFactory(email="wrongcodebyemail@example.com")
    EmailVerificationCode.issue(user)

    response = api_client.post(
        "/api/auth/verify-email/confirm-by-email/",
        {"email": "wrongcodebyemail@example.com", "code": "000000"},
        format="json",
    )

    assert response.status_code == 400
    user.refresh_from_db()
    assert user.email_verified_at is None


# --- Phone verification (Twilio Verify, 2026-09-14) -------------------------


@pytest.mark.django_db
def test_verify_phone_requires_a_phone_number_on_the_account(api_client):
    user = UserFactory(phone_number=None)
    api_client.force_authenticate(user=user)

    response = api_client.post("/api/auth/verify-phone/", {}, format="json")

    assert response.status_code == 400


@pytest.mark.django_db
def test_verify_phone_sends_a_real_twilio_verification(api_client):
    user = UserFactory(phone_number="+237600000001")
    api_client.force_authenticate(user=user)

    with (
        override_settings(TWILIO_API_KEY_SID="SKtest", TWILIO_API_KEY_SECRET="secret", TWILIO_VERIFY_SERVICE_SID="VAtest"),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        mocked_post.return_value = mock.Mock(status_code=201)
        response = api_client.post("/api/auth/verify-phone/", {}, format="json")

    assert response.status_code == 200
    mocked_post.assert_called_once()
    assert mocked_post.call_args.kwargs["data"]["To"] == "+237600000001"


@pytest.mark.django_db
def test_verify_phone_is_unavailable_when_twilio_is_not_configured(api_client):
    user = UserFactory(phone_number="+237600000002")
    api_client.force_authenticate(user=user)

    with (
        override_settings(TWILIO_API_KEY_SID=None, TWILIO_API_KEY_SECRET=None, TWILIO_VERIFY_SERVICE_SID=None),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        response = api_client.post("/api/auth/verify-phone/", {}, format="json")

    assert response.status_code == 400
    mocked_post.assert_not_called()


@pytest.mark.django_db
def test_verify_phone_confirm_full_round_trip(api_client):
    user = UserFactory(phone_number="+237600000003")
    api_client.force_authenticate(user=user)

    with (
        override_settings(TWILIO_API_KEY_SID="SKtest", TWILIO_API_KEY_SECRET="secret", TWILIO_VERIFY_SERVICE_SID="VAtest"),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        mocked_post.return_value = mock.Mock(status_code=200, json=lambda: {"status": "approved"})
        response = api_client.post("/api/auth/verify-phone/confirm/", {"code": "123456"}, format="json")

    assert response.status_code == 200
    assert response.data["phone_verified"] is True
    user.refresh_from_db()
    assert user.phone_verified_at is not None


@pytest.mark.django_db
def test_verify_phone_confirm_rejects_a_code_twilio_does_not_approve(api_client):
    user = UserFactory(phone_number="+237600000004")
    api_client.force_authenticate(user=user)

    with (
        override_settings(TWILIO_API_KEY_SID="SKtest", TWILIO_API_KEY_SECRET="secret", TWILIO_VERIFY_SERVICE_SID="VAtest"),
        mock.patch("apps.core.sms.requests.post") as mocked_post,
    ):
        mocked_post.return_value = mock.Mock(status_code=200, json=lambda: {"status": "pending"})
        response = api_client.post("/api/auth/verify-phone/confirm/", {"code": "000000"}, format="json")

    assert response.status_code == 400
    user.refresh_from_db()
    assert user.phone_verified_at is None


@pytest.mark.django_db
def test_verify_phone_confirm_requires_authentication(api_client):
    response = api_client.post("/api/auth/verify-phone/confirm/", {"code": "123456"}, format="json")
    assert response.status_code == 401


@pytest.mark.django_db
def test_changing_phone_number_resets_verification(api_client):
    user = UserFactory(phone_number="+237600000005")
    user.phone_verified_at = timezone.now()
    user.save(update_fields=["phone_verified_at"])
    api_client.force_authenticate(user=user)

    response = api_client.patch("/api/auth/me/", {"phone_number": "+237600000006"}, format="json")

    assert response.status_code == 200
    assert response.data["phone_verified"] is False
    user.refresh_from_db()
    assert user.phone_verified_at is None


@pytest.mark.django_db
def test_keeping_the_same_phone_number_does_not_reset_verification(api_client):
    user = UserFactory(phone_number="+237600000007")
    user.phone_verified_at = timezone.now()
    user.save(update_fields=["phone_verified_at"])
    api_client.force_authenticate(user=user)

    response = api_client.patch("/api/auth/me/", {"phone_number": "+237600000007"}, format="json")

    assert response.status_code == 200
    assert response.data["phone_verified"] is True
    user.refresh_from_db()
    assert user.phone_verified_at is not None


# --- Staff onboarding: StaffAccount, IT Helpdesk, and the set-password link ---


def _it_helpdesk_user(**kwargs):
    user = User.objects.create_user(
        email=kwargs.pop("email", "helpdesk@example.com"), password="testpass123", is_staff=True, **kwargs
    )
    helpdesk_group, _ = Group.objects.get_or_create(name="IT Helpdesk")
    user.groups.add(helpdesk_group)
    return user


@pytest.mark.django_db
def test_it_helpdesk_group_exists_and_carries_no_permissions():
    """StaffAccountAdmin gates access with a hardcoded group check, not
    Django's permission system -- membership in the group is what matters,
    not any Permission object attached to it."""
    helpdesk = Group.objects.get(name="IT Helpdesk")
    assert helpdesk.permissions.count() == 0


@pytest.mark.django_db
def test_group_model_is_relabeled_for_clarity():
    assert Group._meta.verbose_name == "Staff role"
    assert Group._meta.verbose_name_plural == "Staff roles"


@pytest.mark.django_db
def test_it_helpdesk_can_onboard_a_new_staff_member_end_to_end(mailoutbox):
    helpdesk = _it_helpdesk_user()
    client = Client()
    client.force_login(helpdesk)

    response = client.post(
        "/admin/accounts/staffaccount/add/",
        {"email": "new-reviewer@example.com", "name": "New Reviewer", "role": Group.objects.get(name="Reviewer").pk},
    )

    assert response.status_code == 302
    created = User.objects.get(email="new-reviewer@example.com")
    assert created.is_staff is True
    assert created.is_active is True
    assert created.has_usable_password() is False
    assert list(created.groups.values_list("name", flat=True)) == ["Reviewer"]

    assert len(mailoutbox) == 1
    assert mailoutbox[0].to == ["new-reviewer@example.com"]
    assert "/staff/set-password/" in mailoutbox[0].body


@pytest.mark.django_db
def test_it_helpdesk_can_change_an_existing_staff_members_role():
    helpdesk = _it_helpdesk_user()
    staffer = User.objects.create_user(email="existing@example.com", password="x", is_staff=True)
    staffer.groups.add(Group.objects.get(name="Support"))
    client = Client()
    client.force_login(helpdesk)

    response = client.post(
        f"/admin/accounts/staffaccount/{staffer.pk}/change/",
        {"name": "Existing Person", "is_active": "on", "role": Group.objects.get(name="Integration Ops").pk},
    )

    assert response.status_code == 302
    staffer.refresh_from_db()
    assert list(staffer.groups.values_list("name", flat=True)) == ["Integration Ops"]


@pytest.mark.django_db
def test_it_helpdesk_cannot_reach_the_staff_onboarding_screen_without_membership():
    plain_staff = User.objects.create_user(email="plain-staff@example.com", password="x", is_staff=True)
    client = Client()
    client.force_login(plain_staff)

    response = client.get("/admin/accounts/staffaccount/add/")

    assert response.status_code == 403


@pytest.mark.django_db
def test_it_helpdesk_cannot_change_a_superusers_account():
    helpdesk = _it_helpdesk_user()
    owner = User.objects.create_superuser(email="owner@example.com", password="x")
    client = Client()
    client.force_login(helpdesk)

    response = client.get(f"/admin/accounts/staffaccount/{owner.pk}/change/")

    assert response.status_code == 403


@pytest.mark.django_db
def test_staff_account_add_form_never_exposes_a_way_to_grant_superuser():
    admin_instance = StaffAccountAdmin(StaffAccount, AdminSite())
    request = RequestFactory().get("/")
    request.user = User.objects.create_superuser(email="owner2@example.com", password="x")
    form_class = admin_instance.get_form(request, obj=None)
    assert "is_superuser" not in form_class.base_fields
    assert "is_staff" not in form_class.base_fields


@pytest.mark.django_db
def test_staff_account_add_form_creates_with_no_usable_password_and_assigns_role():
    role = Group.objects.get(name="Support")
    form = StaffAccountAddForm(data={"email": "formtest@example.com", "name": "Form Test", "role": role.pk})
    assert form.is_valid(), form.errors

    user = form.save()

    assert user.pk is not None
    assert user.is_staff is True
    assert user.has_usable_password() is False
    assert list(user.groups.all()) == [role]


@pytest.mark.django_db
def test_staff_account_admin_lists_only_staff_and_shows_their_role():
    helpdesk = _it_helpdesk_user()
    UserFactory(email="student@example.com")  # a plain app user, not staff
    admin_instance = StaffAccountAdmin(StaffAccount, AdminSite())
    request = RequestFactory().get("/")
    request.user = helpdesk

    listed_emails = set(admin_instance.get_queryset(request).values_list("email", flat=True))

    assert "student@example.com" not in listed_emails
    assert helpdesk.email in listed_emails
    assert admin_instance.role_display(helpdesk) == "IT Helpdesk"


@pytest.mark.django_db
def test_staff_set_password_link_sets_password_once_then_refuses_reuse():
    helpdesk_group = Group.objects.get(name="IT Helpdesk")
    user = User.objects.create_user(email="invited@example.com", is_staff=True)
    user.set_unusable_password()
    user.save()
    user.groups.add(helpdesk_group)
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    url = f"/staff/set-password/{uidb64}/{token}/"
    client = Client()

    get_response = client.get(url)
    assert get_response.status_code == 200
    assert "invalid" not in get_response.context

    post_response = client.post(url, {"new_password1": "GenuinelyStr0ng!", "new_password2": "GenuinelyStr0ng!"})
    assert post_response.status_code == 200
    assert post_response.context["done"] is True
    user.refresh_from_db()
    assert user.check_password("GenuinelyStr0ng!") is True

    # The token is bound to the password hash -- reusing the same link
    # after it's already been used must fail, not silently work twice.
    reuse = client.get(url)
    assert reuse.context["invalid"] is True


@pytest.mark.django_db
def test_staff_set_password_rejects_mismatched_passwords():
    user = User.objects.create_user(email="mismatch@example.com", is_staff=True)
    user.set_unusable_password()
    user.save()
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    client = Client()

    response = client.post(
        f"/staff/set-password/{uidb64}/{token}/", {"new_password1": "GenuinelyStr0ng!", "new_password2": "Different!23"}
    )

    assert response.status_code == 200
    assert "match" in response.context["error"]
    user.refresh_from_db()
    assert user.has_usable_password() is False


@pytest.mark.django_db
def test_staff_set_password_rejects_a_weak_password():
    user = User.objects.create_user(email="weak@example.com", is_staff=True)
    user.set_unusable_password()
    user.save()
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    client = Client()

    response = client.post(f"/staff/set-password/{uidb64}/{token}/", {"new_password1": "password", "new_password2": "password"})

    assert response.status_code == 200
    assert response.context["error"]
    user.refresh_from_db()
    assert user.has_usable_password() is False


@pytest.mark.django_db
def test_staff_set_password_link_rejects_a_tampered_token():
    user = User.objects.create_user(email="tampered@example.com", is_staff=True)
    user.set_unusable_password()
    user.save()
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    client = Client()

    response = client.get(f"/staff/set-password/{uidb64}/not-a-real-token/")

    assert response.context["invalid"] is True


@pytest.mark.django_db
def test_staff_set_password_link_never_works_for_a_non_staff_account():
    user = UserFactory(email="regular-app-user@example.com")  # is_staff=False by default
    uidb64 = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    client = Client()

    response = client.get(f"/staff/set-password/{uidb64}/{token}/")

    assert response.context["invalid"] is True
