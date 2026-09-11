from django.db import models

from apps.core.models import TimeStampedModel


class Promotion(TimeStampedModel):
    """
    Sponsor/promotion slots on Home (owner request, 2026-09-11) — scaffolded
    ahead of any real sponsor deal existing yet, deliberately not visible:
    is_active defaults to False so a freshly created row never shows until
    someone deliberately flips it on, and the Home section itself hides
    entirely whenever the active queryset is empty (see
    apps.promotions.views.ActivePromotionsView and LoggedInHomeScreen's own
    ListenableBuilder-less FutureBuilder for it) — the same "no section
    rather than a fake one" pattern already used elsewhere in this app for
    Past-paper practice/Friday Arena/an empty offline-downloads list.
    """

    title = models.CharField(max_length=100)
    subtitle = models.CharField(max_length=200, blank=True)
    sponsor_name = models.CharField(max_length=100, blank=True)
    # A named icon from the app's existing icon set (see IconLookup on the
    # Flutter side) rather than an uploaded image — keeps this scaffold
    # dependency-free until a real sponsor deal decides it needs artwork.
    icon_name = models.CharField(max_length=60, blank=True)
    cta_label = models.CharField(max_length=60, blank=True)
    cta_url = models.URLField(blank=True)
    is_active = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "-created_at"]

    def __str__(self):
        return f"{self.title} ({'active' if self.is_active else 'inactive'})"
