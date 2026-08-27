import datetime

import pytest
from django.core.management import call_command
from django.test import Client
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.factories import UserFactory
from apps.admin_queue.models import AdminFlagQueue, FlagCategory

from .escrow import AlreadyRedeemedError, EscrowError, dispute, issue_qr, redeem_qr, self_confirm_receipt
from .factories import PamphletFactory
from .models import PamphletOrder, PamphletOrderStatus
from .services import place_order


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_catalog_is_public(api_client):
    PamphletFactory()
    response = api_client.get("/api/pamphlets/catalog/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert response.status_code == 200
    assert len(rows) == 1


@pytest.mark.django_db
def test_place_order_issues_qr_immediately_per_spec():
    """Spec §3.2 step 3: the buyer gets their QR ticket right after payment, no ops-approval step."""
    user = UserFactory()
    pamphlet = PamphletFactory(price_fcfa=3000, delivery_fee_fcfa=500)
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    assert order.amount_paid == 3000
    assert order.status == PamphletOrderStatus.QR_ISSUED
    assert order.qr_token
    assert order.qr_issued_at is not None


@pytest.mark.django_db
def test_place_order_with_delivery_adds_delivery_fee():
    user = UserFactory()
    pamphlet = PamphletFactory(price_fcfa=3000, delivery_fee_fcfa=500)
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=True, phone_number="670000000")
    assert order.amount_paid == 3500


@pytest.mark.django_db
def test_place_order_endpoint_issues_qr_immediately(api_client):
    user = UserFactory()
    pamphlet = PamphletFactory()
    api_client.force_authenticate(user=user)
    response = api_client.post(
        "/api/pamphlets/orders/place/",
        {"pamphlet": pamphlet.id, "is_delivery": False, "phone_number": "670000000"},
        format="json",
    )
    assert response.status_code == 201
    assert response.data["status"] == PamphletOrderStatus.QR_ISSUED
    assert response.data["qr_token"]  # the buyer's own order — safe and necessary to expose
    order = PamphletOrder.objects.get(id=response.data["id"])
    assert order.payment_transaction is not None
    assert order.qr_token
    assert order.released_at is None


@pytest.mark.django_db
def test_orders_list_shows_only_own_orders(api_client):
    me = UserFactory()
    other = UserFactory()
    pamphlet = PamphletFactory()
    place_order(user=me, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    place_order(user=other, pamphlet=pamphlet, is_delivery=False, phone_number="670000001")
    api_client.force_authenticate(user=me)
    response = api_client.get("/api/pamphlets/orders/")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    assert len(rows) == 1


@pytest.mark.django_db
def test_featured_endpoint_returns_the_featured_pamphlet(api_client):
    PamphletFactory(is_featured=False)
    featured = PamphletFactory(is_featured=True)
    response = api_client.get("/api/pamphlets/catalog/featured/")
    assert response.status_code == 200
    assert response.data["id"] == featured.id


@pytest.mark.django_db
def test_featured_endpoint_404s_when_none_configured(api_client):
    PamphletFactory(is_featured=False)
    response = api_client.get("/api/pamphlets/catalog/featured/")
    assert response.status_code == 404


@pytest.mark.django_db
def test_catalog_filters_by_subject_and_level(api_client):
    PamphletFactory(title="Physics pack", subject_title="Physics", academic_level="A Level")
    PamphletFactory(title="Biology pack", subject_title="Biology", academic_level="O Level")

    response = api_client.get("/api/pamphlets/catalog/?subject_title=Physics")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    titles = [r["title"] for r in rows]
    assert "Physics pack" in titles
    assert "Biology pack" not in titles

    response = api_client.get("/api/pamphlets/catalog/?academic_level=O Level")
    rows = response.data["results"] if isinstance(response.data, dict) else response.data
    titles = [r["title"] for r in rows]
    assert "Biology pack" in titles
    assert "Physics pack" not in titles


# --- Escrow + QR state machine (Stage 6) ---


@pytest.mark.django_db
def test_issue_qr_transitions_paid_held_to_qr_issued():
    """Isolated unit test of issue_qr() itself, against a manually-held order (place_order already auto-issues)."""
    user = UserFactory()
    pamphlet = PamphletFactory()
    held_order = PamphletOrder.objects.create(
        user=user, pamphlet=pamphlet, amount_paid=pamphlet.price_fcfa, status=PamphletOrderStatus.PAID_HELD
    )
    issued = issue_qr(held_order)
    assert issued.status == PamphletOrderStatus.QR_ISSUED
    assert issued.qr_token
    assert issued.qr_issued_at is not None


@pytest.mark.django_db
def test_issue_qr_rejects_already_issued_order():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    with pytest.raises(EscrowError):
        issue_qr(order)


@pytest.mark.django_db
def test_redeem_qr_releases_payment_minus_commission():
    user = UserFactory()
    pamphlet = PamphletFactory(price_fcfa=3000)
    pamphlet.partner.commission_percent = 5
    pamphlet.partner.save()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")

    released = redeem_qr(order.qr_token)
    assert released.status == PamphletOrderStatus.RELEASED
    assert released.payout_amount == 2850  # 3000 - 5%
    assert released.released_at is not None


@pytest.mark.django_db
def test_redeem_qr_rejects_repeat_scan_with_specific_message():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    redeem_qr(order.qr_token)

    with pytest.raises(AlreadyRedeemedError, match="Already redeemed at"):
        redeem_qr(order.qr_token)


@pytest.mark.django_db
def test_redeem_qr_rejects_invalid_token():
    with pytest.raises(EscrowError, match="invalid"):
        redeem_qr("not-a-real-token")


@pytest.mark.django_db
def test_redeem_qr_rejects_expired_token(monkeypatch):
    from . import escrow as escrow_module

    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")

    # Force verify_qr_token's max_age window (imported into escrow's namespace) to be already elapsed.
    monkeypatch.setattr(escrow_module, "QR_EXPIRY_DAYS", -1)
    with pytest.raises(EscrowError, match="expired"):
        redeem_qr(order.qr_token)


@pytest.mark.django_db
def test_self_confirm_only_allowed_by_order_owner():
    owner = UserFactory()
    other = UserFactory()
    pamphlet = PamphletFactory(delivery_available=True)
    order = place_order(user=owner, pamphlet=pamphlet, is_delivery=True, phone_number="670000000")
    with pytest.raises(EscrowError):
        self_confirm_receipt(order, user=other)
    confirmed = self_confirm_receipt(order, user=owner)
    assert confirmed.self_confirmed_at is not None


@pytest.mark.django_db
def test_self_confirm_rejects_non_delivery_order():
    owner = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=owner, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    with pytest.raises(EscrowError):
        self_confirm_receipt(order, user=owner)


@pytest.mark.django_db
def test_cron_expires_stale_unredeemed_tickets_and_flags_admin():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    PamphletOrder.objects.filter(id=order.id).update(qr_issued_at=timezone.now() - datetime.timedelta(days=31))

    call_command("process_pamphlet_expiry")

    order.refresh_from_db()
    assert order.status == PamphletOrderStatus.EXPIRED
    assert AdminFlagQueue.objects.filter(category=FlagCategory.PAMPHLET_EXPIRED).count() == 1


@pytest.mark.django_db
def test_cron_auto_releases_self_confirmed_delivery_after_three_days():
    user = UserFactory()
    pamphlet = PamphletFactory(delivery_available=True)
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=True, phone_number="670000000")
    self_confirm_receipt(order, user=user)
    PamphletOrder.objects.filter(id=order.id).update(
        self_confirmed_at=timezone.now() - datetime.timedelta(days=4)
    )

    call_command("process_pamphlet_expiry")

    order.refresh_from_db()
    assert order.status == PamphletOrderStatus.RELEASED
    assert order.payout_amount is not None


@pytest.mark.django_db
def test_cron_does_not_release_self_confirmed_before_three_days():
    user = UserFactory()
    pamphlet = PamphletFactory(delivery_available=True)
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=True, phone_number="670000000")
    self_confirm_receipt(order, user=user)

    call_command("process_pamphlet_expiry")

    order.refresh_from_db()
    assert order.status == PamphletOrderStatus.QR_ISSUED


@pytest.mark.django_db
def test_dispute_flags_admin_queue():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    disputed = dispute(order, reason="Partner claims scanned, buyer says not received.")
    assert disputed.status == PamphletOrderStatus.DISPUTED
    assert AdminFlagQueue.objects.filter(category=FlagCategory.PAMPHLET_DISPUTE).count() == 1


@pytest.mark.django_db
def test_redeem_page_get_shows_confirm_form():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    client = Client()
    response = client.get(f"/redeem/{order.qr_token}/")
    assert response.status_code == 200
    assert b"Confirm pamphlet handover" in response.content


@pytest.mark.django_db
def test_redeem_page_post_releases_and_shows_success():
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = place_order(user=user, pamphlet=pamphlet, is_delivery=False, phone_number="670000000")
    client = Client()
    response = client.post(f"/redeem/{order.qr_token}/")
    assert response.status_code == 200
    assert b"Handover confirmed" in response.content
    order.refresh_from_db()
    assert order.status == PamphletOrderStatus.RELEASED


@pytest.mark.django_db
def test_redeem_page_shows_invalid_for_garbage_token():
    client = Client()
    response = client.get("/redeem/garbage-token/")
    assert response.status_code == 200
    assert b"invalid" in response.content.lower()


@pytest.mark.django_db
def test_issue_qr_endpoint_requires_staff(api_client):
    user = UserFactory()
    pamphlet = PamphletFactory()
    order = PamphletOrder.objects.create(
        user=user, pamphlet=pamphlet, amount_paid=pamphlet.price_fcfa, status=PamphletOrderStatus.PAID_HELD
    )
    api_client.force_authenticate(user=user)
    response = api_client.post(f"/api/pamphlets/orders/{order.id}/issue-qr/")
    assert response.status_code == 403


@pytest.mark.django_db
def test_issue_qr_endpoint_works_for_staff(api_client):
    user = UserFactory()
    admin_user = UserFactory(is_staff=True)
    pamphlet = PamphletFactory()
    order = PamphletOrder.objects.create(
        user=user, pamphlet=pamphlet, amount_paid=pamphlet.price_fcfa, status=PamphletOrderStatus.PAID_HELD
    )
    api_client.force_authenticate(user=admin_user)
    response = api_client.post(f"/api/pamphlets/orders/{order.id}/issue-qr/")
    assert response.status_code == 200
    assert response.data["status"] == PamphletOrderStatus.QR_ISSUED
