import pytest
from rest_framework.test import APIClient

from .factories import PromotionFactory
from .models import Promotion


@pytest.mark.django_db
def test_the_real_seeded_slearn_promotion_is_active_and_public():
    """0003_seed_slearn_promotion seeded the first real content this
    scaffold has ever held (owner-provided, 2026-09-11) — this is what
    actually makes it visible on Home, not just a working-but-empty
    endpoint. Real logo bytes too, not a placeholder icon name."""
    promo = Promotion.objects.get(sponsor_name="S@Learn")
    assert promo.is_active is True
    assert promo.cta_url == "https://s-learn-beta.vercel.app/"
    assert promo.logo.name

    response = APIClient().get("/api/promotions/active/")
    assert response.status_code == 200
    titles = [row["sponsor_name"] for row in response.data]
    assert "S@Learn" in titles
    row = next(r for r in response.data if r["sponsor_name"] == "S@Learn")
    assert row["logo_url"] is not None
    assert row["cta_label"] == "Learn more"


@pytest.mark.django_db
def test_active_promotions_endpoint_never_leaks_an_inactive_row():
    """Still the whole point of this scaffold: an inactive Promotion row
    (the factory default) must never leak into this response, real seeded
    content or not."""
    PromotionFactory(title="Hidden", is_active=False)

    response = APIClient().get("/api/promotions/active/")

    assert response.status_code == 200
    assert "Hidden" not in [row["title"] for row in response.data]


@pytest.mark.django_db
def test_active_promotions_endpoint_returns_active_rows_in_sort_order():
    # The real seeded S@Learn row already occupies sort_order=0 — these
    # sort after it rather than assuming an empty table.
    PromotionFactory(title="Second", is_active=True, sort_order=2)
    PromotionFactory(title="Hidden", is_active=False, sort_order=1)
    PromotionFactory(title="First", is_active=True, sort_order=1)

    response = APIClient().get("/api/promotions/active/")

    assert response.status_code == 200
    titles = [row["title"] for row in response.data]
    assert titles.index("First") < titles.index("Second")
    assert "Hidden" not in titles
