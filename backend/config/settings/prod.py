import os

from .base import *

# TEMPORARY (2026-09-03): diagnosing a live 500 on every write endpoint
# (register/guest/password-reset) where DEBUG=False's blank error page and
# a total absence of server-side logging (no ADMINS, no SENTRY_DSN
# configured) leaves genuinely zero way to see the real traceback. Reverts
# to the hardcoded `DEBUG = False` immediately after capturing it — see
# TODOS.md/commit history for the follow-up that removes this again.
DEBUG = env.bool("DJANGO_DEBUG", default=False)

SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Render injects this at runtime — the service's own onrender.com hostname
# isn't known until the first deploy assigns it, so it can't be a fixed
# value in DJANGO_ALLOWED_HOSTS. See RENDER_STAGING.md.
RENDER_HOST = os.getenv("RENDER_EXTERNAL_HOSTNAME")
if RENDER_HOST:
    ALLOWED_HOSTS = [*ALLOWED_HOSTS, RENDER_HOST]
    CSRF_TRUSTED_ORIGINS = [f"https://{RENDER_HOST}"]

# WhiteNoise serves static files directly from the app process — Render's
# free web-service plan has no separate static-asset host. Inserted right
# after SecurityMiddleware (WhiteNoise's own documented placement), rather
# than redeclaring the whole MIDDLEWARE list, so base.py stays the one
# source of truth for everything else in it.
MIDDLEWARE = list(MIDDLEWARE)
MIDDLEWARE.insert(
    MIDDLEWARE.index("django.middleware.security.SecurityMiddleware") + 1,
    "whitenoise.middleware.WhiteNoiseMiddleware",
)

# base.py never needed this (dev serves static files via runserver's own
# auto-discovery, no collectstatic step) — collectstatic errors out without
# it. Media (STORAGES["default"]) stays whatever base.py already resolved
# (real Supabase Storage when AWS_STORAGE_BUCKET_NAME is set, local disk
# otherwise) — only STATICFILES_STORAGE changes for prod.
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    **STORAGES,
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
}

# Required with Supabase's transaction-mode pooler (port 6543, see
# RENDER_STAGING.md §1): that pooler doesn't support Postgres session
# state persisting across requests the way a normal connection pool
# expects, so Django must open a fresh connection every request rather
# than reusing one.
DATABASES["default"]["CONN_MAX_AGE"] = 0
