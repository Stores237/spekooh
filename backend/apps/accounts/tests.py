import pytest
from rest_framework.test import APIClient

from .factories import UserFactory
from .models import AccountType, User


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_register_creates_registered_user_and_returns_tokens(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "new@example.com", "name": "New User", "password": "S0mePass!23"},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["user"]["email"] == "new@example.com"
    assert response.data["user"]["account_type"] == AccountType.REGISTERED
    assert "access" in response.data and "refresh" in response.data
    assert User.objects.get(email="new@example.com").check_password("S0mePass!23")


@pytest.mark.django_db
def test_register_rejects_weak_password(api_client):
    response = api_client.post(
        "/api/auth/register/",
        {"email": "weak@example.com", "name": "Weak", "password": "123"},
        format="json",
    )
    assert response.status_code == 400


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
        {"email": "coded@example.com", "name": "Coded User", "password": "S0mePass!23"},
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
        },
        format="json",
    )
    assert response.status_code == 400
    assert not User.objects.filter(email="bad-code@example.com").exists()
