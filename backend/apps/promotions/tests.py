import pytest
from rest_framework.test import APIClient

from .factories import PromotionFactory


@pytest.mark.django_db
def test_active_promotions_endpoint_is_public_and_empty_by_default():
    """The whole point of this scaffold (owner request, 2026-09-11): safe
    to call from day one, with nothing to show until a real sponsor deal
    exists — an inactive Promotion row (the factory default) must not
    leak into this response."""
    PromotionFactory()
    response = APIClient().get("/api/promotions/active/")
    assert response.status_code == 200
    assert response.data == []


@pytest.mark.django_db
def test_active_promotions_endpoint_returns_only_active_rows_in_sort_order():
    PromotionFactory(title="Second", is_active=True, sort_order=2)
    PromotionFactory(title="Hidden", is_active=False, sort_order=0)
    PromotionFactory(title="First", is_active=True, sort_order=1)

    response = APIClient().get("/api/promotions/active/")

    assert response.status_code == 200
    assert [row["title"] for row in response.data] == ["First", "Second"]
