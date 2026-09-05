"""
Shared settings for every environment. dev.py / prod.py layer on top.
"""

from datetime import timedelta
from pathlib import Path

import environ
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY", default="dev-secret-key-change-me-please-at-least-32-bytes-long")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])

# No-ops when SENTRY_DSN is unset (sentry-sdk's own documented behavior),
# so a fresh clone with no Sentry project still works out of the box —
# same fallback pattern as DATABASE_URL/REDIS_URL/AWS_* above and below.
sentry_sdk.init(
    dsn=env("SENTRY_DSN", default=None),
    integrations=[DjangoIntegration()],
    environment="development" if DEBUG else "production",
    # Errors are always captured regardless of this — this is the *trace*
    # sample rate for performance monitoring, kept low since this isn't a
    # latency-critical service and a low-traffic beta doesn't need every
    # request traced to get useful signal.
    traces_sample_rate=0.1,
    send_default_pii=False,
)

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
    "rest_framework_simplejwt.token_blacklist",
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
    "apps.ai",
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

# Local Redis by default so a fresh clone with no managed Redis still
# works out of the box (mirrors DATABASE_URL's own fallback). Backs DRF's
# throttle classes (see the guest-mint rate limit below) and is the
# obvious place to move any future hot-path counter (e.g. the daily
# free-view count) if that ever needs to stop being a live COUNT query.
CACHES = {"default": env.cache("REDIS_URL", default="rediscache://localhost:6379/0")}

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

# Local disk storage stays the default so a fresh clone with no Supabase
# credentials still works out of the box (mirrors DATABASE_URL's fallback
# to local Postgres). Set AWS_STORAGE_BUCKET_NAME (+ the other AWS_* vars
# below) to switch to real Supabase Storage — no model change either way,
# PaperSubmission.uploaded_file stays a plain FileField.
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
FILE_UPLOAD_MAX_MEMORY_SIZE = 20 * 1024 * 1024  # 20MB, matches the app's stated upload limit

_aws_bucket = env("AWS_STORAGE_BUCKET_NAME", default=None)
STORAGES = {
    "default": (
        {
            "BACKEND": "storages.backends.s3.S3Storage",
            "OPTIONS": {
                "access_key": env("AWS_ACCESS_KEY_ID", default=None),
                "secret_key": env("AWS_SECRET_ACCESS_KEY", default=None),
                "bucket_name": _aws_bucket,
                "endpoint_url": env("AWS_S3_ENDPOINT_URL", default=None),
                "region_name": env("AWS_S3_REGION_NAME", default=None),
                "signature_version": "s3v4",
                # Bucket is private (Supabase Storage default) — every
                # file_url is a freshly signed, expiring link, not a static
                # public path. 3600s matches django-storages' own default;
                # generated fresh per API response, not cached, so this
                # only needs to outlive the time between the response and
                # the user actually opening the file.
                "querystring_auth": True,
                "querystring_expire": 3600,
                "default_acl": None,
            },
        }
        if _aws_bucket
        else {"BACKEND": "django.core.files.storage.FileSystemStorage"}
    ),
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": ("django_filters.rest_framework.DjangoFilterBackend",),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    # Backed by CACHES["default"] (Redis) above — DRF's throttles use
    # whatever the default cache is automatically, no extra wiring.
    "DEFAULT_THROTTLE_RATES": {
        # Per-IP. A real contributor mints one guest per submission
        # attempt; 10/hour is generous for retries but stops scripted
        # spam from creating unlimited real accounts.
        "guest_mint": "10/hour",
        # Security hardening (2026-09-02): login and registration had no
        # rate limit at all — LoginView/RegisterView declared no
        # throttle_classes, and DEFAULT_THROTTLE_RATES alone does nothing
        # without a view opting in. Left credential-stuffing/brute-force
        # against login, and spam account creation against registration,
        # completely unthrottled. Per-IP, same mechanism as guest_mint —
        # generous enough that a real user mistyping a password or retrying
        # a signup isn't affected, tight enough to slow a script down hard.
        "login": "20/hour",
        "register": "10/hour",
        # Per-IP. A real user retrying a typo'd email is rare; a script
        # probing which emails are registered is the thing this stops.
        "password_reset_request": "5/hour",
        # Deliberately looser than the request scope — a real user re-typing
        # a 6-digit code has several legitimate retries; PasswordResetCode's
        # own attempts-cap (5) is what actually stops brute-forcing one code.
        "password_reset_confirm": "20/hour",
        "email_verification_confirm": "20/hour",
        # Per-user (authenticated), not per-IP — a real user asking for a
        # fresh code a couple times while typing is normal; unlimited resends
        # would just be a way to spam their own inbox.
        "email_verification_resend": "5/hour",
        # Per-IP, same reasoning as password_reset_request/confirm — the
        # unauthenticated recovery path, so the same enumeration concern
        # applies here that doesn't apply to the authenticated pair above.
        "email_verification_request_by_email": "5/hour",
        "email_verification_confirm_by_email": "20/hour",
    },
}

# Security hardening (2026-09-02): explicitly pinning simplejwt's own
# unconfigured defaults (5-minute access, 1-day refresh) so a future
# library upgrade can't silently change real session behavior — the
# lifetimes below are unchanged from what was already in effect. The real
# addition is rotation + blacklisting: without it, one refresh token stays
# valid, unrevocable, for its full lifetime even if it leaks — a client
# could keep minting fresh access tokens from a stolen refresh token
# indefinitely, and there was no way to invalidate it short of rotating
# DJANGO_SECRET_KEY (which would log out every user, not just the
# compromised one). With rotation on, every refresh both issues a new
# refresh token AND blacklists the one just used — a legitimate client
# that keeps refreshing stays logged in seamlessly (app/lib/data/
# auth_session.dart's refreshAccessToken() now persists the rotated
# token), but a stolen refresh token becomes a single-use item: the moment
# either the real client or the attacker uses it, the other's copy is
# blacklisted on the next attempt — turning "permanently valid until it
# expires" into "detectably invalidated on reuse."
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=5),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Spekooh API",
    "DESCRIPTION": "Past-paper marketplace, instructor marking, credits, and pamphlet escrow.",
    "VERSION": "1.0.0",
}

CORS_ALLOW_ALL_ORIGINS = True

# QR pamphlet-pickup token signing (django.core.signing).
QR_SIGNING_SALT = env("QR_SIGNING_SALT", default="spekooh-pamphlet-qr")

# Password-reset codes (and anything else transactional) send from this
# address. dev.py points EMAIL_BACKEND at the console — no real provider is
# wired up yet, see TODOS.md's "Owner action items" for what prod needs
# (an EMAIL_HOST/API-key-based backend, e.g. SendGrid/SES/Postmark).
DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="no-reply@spekooh.app")

# Left at Django's real default (SMTP) so actual production fails loudly if
# it's ever run with no real provider configured, rather than silently
# discarding emails. dev.py overrides this to the console backend directly
# (not via env — it's the file that's guaranteed to have no real provider).
# Found live (2026-08-31): staging had neither dev.py's override nor a real
# EMAIL_HOST, so registration's send_mail crashed every single signup with
# an unhandled ConnectionRefusedError (localhost:25 refused) — a real 500,
# reproduced locally against config.settings.prod before this existed.
# RENDER_STAGING.md sets EMAIL_BACKEND=...console.EmailBackend via env for
# the staging service specifically, so its registrations work (logged, not
# delivered) without pretending it has a real provider it doesn't have.
EMAIL_BACKEND = env("EMAIL_BACKEND", default="django.core.mail.backends.smtp.EmailBackend")

# Supabase Edge Function that verifies a registration email's domain has
# real MX records (see supabase/functions/verify-email-domain) — both unset
# by default, same no-op-safely pattern as SENTRY_DSN/REDIS_URL above: a
# fresh clone with no Supabase edge function deployed just skips the check
# (see apps.accounts.services.email_domain_is_verifiable) rather than
# failing to start or blocking every registration.
SUPABASE_EDGE_FUNCTION_BASE_URL = env("SUPABASE_EDGE_FUNCTION_BASE_URL", default=None)
EMAIL_VERIFY_SHARED_SECRET = env("EMAIL_VERIFY_SHARED_SECRET", default=None)

# Owner switch: once flipped True, a registered (non-guest) account with an
# unconfirmed email is refused at login (EmailTokenObtainPairSerializer).
# Defaults False — WITH NO REAL EMAIL PROVIDER WIRED UP YET (see
# DEFAULT_FROM_EMAIL's comment above), flipping this on would strand every
# real signup with no way to ever receive their code. Flip it once that's
# actually fixed. Registration itself is never gated by this — a brand
# new account still gets tokens immediately so EmailVerificationSheet can
# confirm it in the same session; this only affects *later* logins.
REQUIRE_EMAIL_VERIFICATION = env.bool("REQUIRE_EMAIL_VERIFICATION", default=False)

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

# AI features (2026-09-05) — Lane A only so far (batch generation against
# Spekooh's own content; see apps/ai/models.py). No student-typed text is
# ever sent to Gemini — see apps/ai/prompts/summarise.py's own note on
# why that split is deliberate, not incidental.
#
# Same no-op-safely-when-unconfigured posture as SENTRY_DSN/REDIS_URL/
# AWS_* above: a fresh clone with no GEMINI_API_KEY set doesn't crash —
# generate_pending_artifacts just fails each row with a clear
# "not configured" error (apps.ai.providers.gemini.GeminiProvider) instead
# of a confusing HTTP exception, and AI_ENABLED=False turns the whole
# feature off outright without touching any of the above.
AI_ENABLED = env.bool("AI_ENABLED", default=True)
GEMINI_API_KEY = env("GEMINI_API_KEY", default=None)
AI_MODELS = {
    # Verify the current free-tier model roster before launch — these
    # rosters change often; see https://ai.google.dev/pricing
    "gemini_primary": env("GEMINI_MODEL", default="gemini-2.5-flash"),
    # Groq's own model roster also changes often — see
    # https://console.groq.com/docs/models
    "groq_chat": env("GROQ_CHAT_MODEL", default="llama-3.3-70b-versatile"),
}
# Bump this to invalidate every cached artifact at once (e.g. after a real
# prompt-quality improvement) — old rows stay valid until a new
# (source, kind, language, prompt_version) row generates lazily; no
# migration, no mass delete.
AI_PROMPT_VERSION = env.int("AI_PROMPT_VERSION", default=1)
# Below the real ~1,500/day Gemini Flash ceiling, deliberately, so a
# traffic spike doesn't have the account itself throttled by Google —
# generate_pending_artifacts just waits for tomorrow's reset instead.
GEMINI_DAILY_BUDGET = env.int("GEMINI_DAILY_BUDGET", default=1200)

# Lane B (2026-09-05): the Groq real-time student chatbot. A separate
# switch from AI_ENABLED — chat is a materially different cost/abuse
# profile from Lane A's cron-batch summaries (interactive, per-message,
# no queue to just stop draining), so it needs to be killable on its own
# without also taking summaries down.
AI_CHAT_ENABLED = env.bool("AI_CHAT_ENABLED", default=True)
GROQ_API_KEY = env("GROQ_API_KEY", default=None)
# Owner decision (resolved via AskUserQuestion): free for everyone with a
# daily per-user message quota, then an upgrade prompt pointing at the
# existing Subscription/Pro flow (apps.payments) — a Pro subscriber skips
# this cap entirely (see apps.ai.chat.views), same "give Pro real value"
# reasoning already covering ad-free + unlimited paper views.
AI_CHAT_DAILY_LIMIT = env.int("AI_CHAT_DAILY_LIMIT", default=15)
# A hard, provider-wide daily ceiling that even a Pro subscriber's
# unlimited-seeming chat is still subject to — the same defense-in-depth
# GEMINI_DAILY_BUDGET already provides for Lane A, against a runaway bug
# or abuse producing a surprise bill regardless of any one user's own cap.
GROQ_DAILY_BUDGET = env.int("GROQ_DAILY_BUDGET", default=500)
