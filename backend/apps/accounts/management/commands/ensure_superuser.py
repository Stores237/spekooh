import os

from django.core.management.base import BaseCommand

from apps.accounts.models import User


class Command(BaseCommand):
    """Render's free web-service plan has no Shell tab and no one-off Jobs
    (both are paid-plan-only per render.com/docs/free) — the usual
    `python manage.py createsuperuser` has nowhere interactive to run. This
    runs unconditionally as part of build.sh on every deploy instead, and is
    deliberately a no-op unless both env vars are set AND no user with that
    email exists yet — safe to re-run on every single deploy, not just the
    first, unlike Django's own `createsuperuser --noinput` (which errors out
    if the account already exists — that would break `build.sh`'s
    `set -o errexit` on the second deploy onward).

    DJANGO_SUPERUSER_EMAIL / DJANGO_SUPERUSER_PASSWORD are the same env var
    names Django's own `createsuperuser --noinput` reads — not a bespoke
    convention invented here, just made idempotent.
    """

    help = "Idempotently creates a superuser from DJANGO_SUPERUSER_EMAIL/DJANGO_SUPERUSER_PASSWORD, if both are set."

    def handle(self, *args, **options):
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL")
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD")
        if not email or not password:
            self.stdout.write("DJANGO_SUPERUSER_EMAIL/DJANGO_SUPERUSER_PASSWORD not set — skipping.")
            return
        if User.objects.filter(email__iexact=email).exists():
            self.stdout.write(f"A user with email {email} already exists — skipping.")
            return
        User.objects.create_superuser(email=email, password=password)
        self.stdout.write(self.style.SUCCESS(f"Created superuser {email}."))
