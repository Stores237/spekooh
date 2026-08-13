"""
Shared settings for every environment. dev.py / prod.py layer on top.
"""

from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY", default="dev-secret-key-change-me-please-at-least-32-bytes-long")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])

INSTALLED_APPS = [
    "unfold",  # must precede django.contrib.admin to override its templates
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "django_filters",
    "django_extensions",
    "drf_spectacular",
    "apps.core",
    "apps.accounts",
    "apps.papers",
    "apps.instructors",
    "apps.credits",
    "apps.payments",
    "apps.pamphlets",
    "apps.admin_queue",
    "apps.notes",
    "apps.forum",
    "apps.quizzes",
    "apps.notifications",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        # DIRS is checked before any app's own templates/ dir (including
        # unfold's), so this is where project-level admin template
        # overrides like templates/admin/index.html take effect.
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {"default": env.db("DATABASE_URL", default="postgres://postgres@localhost:5432/spekooh")}

AUTH_USER_MODEL = "accounts.User"

# Without this, Django falls back to its hardcoded default
# "/accounts/profile/" after a login that has no `next` param (e.g. a
# direct visit to /admin/login/ rather than being redirected there from
# /admin/) — a route that doesn't exist anywhere in this URLconf, so it
# 404s and looks like the app is broken rather than just landing you back
# on the admin dashboard.
LOGIN_REDIRECT_URL = "/admin/"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Local disk storage — the free substitute for Supabase Storage (no
# credentials exist for this project). Swapping to real Supabase Storage
# later is a storage-backend swap (e.g. django-storages), not a model change:
# PaperSubmission.uploaded_file stays a FileField either way.
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
FILE_UPLOAD_MAX_MEMORY_SIZE = 20 * 1024 * 1024  # 20MB, matches the app's stated upload limit

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": ("django_filters.rest_framework.DjangoFilterBackend",),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Spekooh API",
    "DESCRIPTION": "Past-paper marketplace, instructor marking, credits, and pamphlet escrow.",
    "VERSION": "1.0.0",
}

CORS_ALLOW_ALL_ORIGINS = True

# QR pamphlet-pickup token signing (django.core.signing).
QR_SIGNING_SALT = env("QR_SIGNING_SALT", default="spekooh-pamphlet-qr")

# Instructor webhook HMAC replay-protection window.
INSTRUCTOR_WEBHOOK_MAX_SKEW_SECONDS = env.int("INSTRUCTOR_WEBHOOK_MAX_SKEW_SECONDS", default=300)

# django-unfold admin theme — brand palette ported 1:1 from tokens/colors.css
# (the same tokens the Flutter app's design system uses). The 50/900/950
# extremes and a few mid-ramp steps aren't literal token values (the token
# file only defines ~6 gold and ~4 ink/neutral anchors, not an 11-step
# Tailwind ramp) — they're interpolated between the real anchors below, not
# fabricated from nothing. No real logo file exists in the repo yet (see
# TODOS.md), so SITE_LOGO is intentionally omitted in favor of a text header.
UNFOLD = {
    "SITE_TITLE": "Spekooh Admin",
    "SITE_HEADER": "Spekooh Admin",
    "SITE_SUBHEADER": "Review & ops",
    "DASHBOARD_CALLBACK": "apps.core.admin_dashboard.dashboard_callback",
    "SITE_SYMBOL": "school",
    "SHOW_HISTORY": True,
    "SHOW_VIEW_ON_SITE": True,
    "BORDER_RADIUS": "0.75rem",
    "STYLES": [
        lambda request: f"/{STATIC_URL}core/admin-theme.css",
    ],
    "COLORS": {
        "base": {
            "50": "#F7F4EE",  # surface-bg
            "100": "#F0EAD9",  # interpolated
            "200": "#EAE2D2",  # border-subtle
            "300": "#D9CDB5",  # interpolated
            "400": "#C2B294",  # interpolated
            "500": "#9C9184",  # text-tertiary
            "600": "#6B6155",  # text-secondary
            "700": "#4A3418",  # ink-700
            "800": "#362610",  # ink-800
            "900": "#241A08",  # ink-900
            "950": "#180F04",  # interpolated, darker than ink-900 for dark-mode bg
        },
        "primary": {
            "50": "#FBF3E1",  # gold-50
            "100": "#F6E7C7",  # interpolated
            "200": "#EFCD83",  # gold-200
            "300": "#E8BC56",  # interpolated
            "400": "#E2A52A",  # gold-400
            "500": "#C8881C",  # gold-500
            "600": "#A8721A",  # gold-600
            "700": "#835611",  # gold-700
            "800": "#6B460E",  # interpolated
            "900": "#53370B",  # interpolated
            "950": "#3A2607",  # interpolated
        },
    },
}
