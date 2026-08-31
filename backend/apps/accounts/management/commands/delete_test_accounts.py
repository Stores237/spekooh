from django.core.management.base import BaseCommand

from apps.accounts.models import User


class Command(BaseCommand):
    """Deletes User rows whose email ends in @example.com — the IANA/RFC
    2606 reserved test domain, never a real registration. Exists because
    live-testing a real deployment (see RENDER_STAGING.md) genuinely
    creates real rows in the real staging database — curl/browser
    round-trips against /api/auth/register/ that verify a fix works aren't
    mocked, so they leave the same kind of row a real signup would. Safe to
    run repeatedly: a no-op once none remain, and no real contributor will
    ever register with an @example.com address."""

    help = "Deletes test accounts (email ending in @example.com) left behind by live-testing staging."

    def handle(self, *args, **options):
        qs = User.objects.filter(email__iendswith="@example.com")
        count = qs.count()
        qs.delete()
        self.stdout.write(self.style.SUCCESS(f"Deleted {count} test account(s)."))
