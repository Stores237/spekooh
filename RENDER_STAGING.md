# Spekooh — Render Staging Deployment

Deploys the Django backend to Render's free tier as a permanent staging
environment for Flutter testing (and, once a real payment provider exists —
see "Not yet applicable" below — webhook testing).

**Purpose: staging only.** The free tier spins down after inactivity, which
is fine here and would not be fine in production.

This doc replaces an earlier draft that assumed a different project layout
(`spekooh.wsgi`/`spekooh.urls`, a Celery worker+beat, `dj-database-url`,
Flutterwave already wired up). None of those match this repo — the
corrections are called out inline below, not silently made.

**Status: live (2026-08-31, infra gaps closed 2026-09-02).**
`https://spekooh-staging.onrender.com` is deployed and verified end-to-end
— registration, login, the full papers taxonomy against real seeded data,
and real Supabase Storage uploads (avatars, papers) all confirmed working
against the actual site, not just locally. The real Android build points
at this URL permanently now. Three real infra gaps found and fixed live on
2026-09-02 — missing `REDIS_URL`, missing `AWS_STORAGE_BUCKET_NAME`, and a
wrong `AWS_S3_REGION_NAME` — see §4's env var table for what each one
actually needs.

---

## 0. What each piece does

Six different services are involved in "the app is live." None of them do
each other's job — this is the map of who's responsible for what, and why
each one is there rather than something else.

| Piece | Role | Why this one |
|---|---|---|
| **Render** | Runs the Django process itself (`gunicorn`), assigns the permanent `https://spekooh-staging.onrender.com` URL, builds on every push to `main` via `build.sh`, and polls `/healthz/` to decide whether a deploy is healthy. | Free web-service tier, no card required — the actual compute + hosting. |
| **Supabase** | Two separate real services, not one: (1) managed Postgres, reached through its connection **pooler** (port `6543`) since Render restarts the process on every deploy/spin-down and a pooler survives that churn better than direct connections; (2) S3-compatible **Storage**, for real uploaded files (paper scans, avatars) — private bucket, signed URLs only, MIME/size-restricted (§ below). | Already the same provider the app's local/dev setup uses — one less thing to keep in sync between environments. |
| **gunicorn** | The actual WSGI server that runs Django's application code and answers HTTP requests inside Render's container. | `runserver` (used locally) is explicitly not for real traffic; gunicorn is Django's own recommended production server. |
| **WhiteNoise** | Serves static files (admin CSS/JS, DRF browsable-API assets) directly from the Django process. | Render's free web-service plan has no separate static-asset host/CDN — WhiteNoise means one process does both jobs with no extra infrastructure. |
| **cron-job.org** | A free external scheduler that periodically POSTs to this app's own `/internal/tasks/<name>/` endpoint, which then runs one of this repo's real Django management commands (§6). | Render's free tier has no cron and no background-worker service at all — this is the entire workaround for that gap. |
| **GitHub Actions (CI)** | Runs the backend/app test suites on every PR before it can merge to `main` — the branch Render actually deploys from. | The gate that caught PR #51's own test-environment mismatch (§ below) before it reached staging; merging straight to `main` with no CI would mean Render deploys whatever broke. |
| **Redis** | Backs `CACHES["default"]`, which every rate-limited endpoint (login, register, guest signup, password reset, email verification) needs for its throttle counters. **Found missing entirely from this deployment, live (2026-09-02)** — every one of those endpoints 500'd until a real instance's connection string was set as `REDIS_URL` (see §4). | `django-redis`'s cache backend is what DRF's `ScopedRateThrottle` reads/writes to; without a real Redis reachable, it errors instead of just failing open. |

Two things that are **not** part of this architecture, on purpose:

- **cloudflared / the local tunnel** — was the *previous* way to get a real
  phone talking to a backend (tunneling into whatever machine happened to
  be running Django locally that session). It's now only used to distribute
  the built `.apk` file itself for download; the installed app's actual API
  traffic goes straight to Render, no tunnel involved, and keeps working
  after the tunnel (and the machine behind it) are long gone.
- **Celery / a message broker** — this codebase has never used one. Its
  three scheduled jobs are plain Django management commands, cron-driven
  locally (`scripts/crontab.example`) and HTTP-triggered on Render (§6) —
  not tasks queued onto a broker.

---

## 1. Before you start

You need:

- The backend repo on GitHub (see `RUNNING_LOCALLY.md` for the local
  scaffold)
- A **separate** Supabase project for staging — not the production one
- A Render account (free, no card required)
- Flutterwave sandbox keys — **only once a real payment integration
  exists**; it doesn't yet (see §8)

**All of the above are owner action items** — an account, a decision, or a
person, same category as everything already listed under TODOS.md's "Owner
action items." Nothing below can substitute for actually creating them.

### Create the staging Supabase project first

supabase.com → New Project → name it `spekooh-staging`.

From Project Settings → Database, copy the **connection pooler** string
(port `6543`), not the direct connection on `5432`:

```
postgresql://postgres.abcdefgh:PASSWORD@aws-0-eu-west-1.pooler.supabase.com:6543/postgres
```

Why the pooler: Render restarts the service on every deploy and every
spin-down/wake cycle. Direct connections accumulate and exhaust Supabase's
connection limit; the pooler in transaction mode handles this — paired with
`CONN_MAX_AGE = 0` in `config/settings/prod.py` (already set, see §3).

You'll also want a separate Storage bucket on this staging project (same
role as the real `spekooh-media` bucket documented in TODOS.md) — required,
not optional, if you want staging file uploads to actually land somewhere
real rather than silently falling back to local disk. See the
`AWS_STORAGE_BUCKET_NAME`/`AWS_S3_REGION_NAME` rows in §4's env var table
below for the two easy-to-get-wrong values found live (2026-09-02).

You'll also need a real Redis instance (Render's own **Key Value** add-on
is the simplest option — same dashboard, same region) for `REDIS_URL` —
see that row in §4 too. Also found missing live (2026-09-02): every
rate-limited endpoint (login, register, guest signup, password reset)
needs it and 500s outright without it.

---

## 2. Files already added to the repo

Everything in this section is already committed — nothing to create.

### `backend/build.sh`

```bash
#!/usr/bin/env bash
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate
```

Already executable (`chmod +x` + `git update-index --chmod=+x` done).

### `render.yaml` (repo root, not `backend/`)

This is a monorepo (`app/` + `backend/`) — Render's Blueprint feature looks
for `render.yaml` at the repo root regardless of where the actual service
lives, so it sets `rootDir: backend` and every build/start command runs
relative to that.

```yaml
services:
  - type: web
    name: spekooh-staging
    runtime: python
    plan: free
    region: frankfurt
    branch: main
    rootDir: backend
    buildCommand: "./build.sh"
    startCommand: "gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers ${WEB_CONCURRENCY:-2}"
    healthCheckPath: /healthz/
    envVars:
      - key: PYTHON_VERSION
        value: 3.13.5
      - key: DJANGO_SETTINGS_MODULE
        value: config.settings.prod
      - key: DJANGO_SECRET_KEY
        generateValue: true
      - key: DJANGO_DEBUG
        value: "False"
      - key: WEB_CONCURRENCY
        value: 2
      - key: DATABASE_URL
        sync: false
      - key: AWS_ACCESS_KEY_ID
        sync: false
      - key: AWS_SECRET_ACCESS_KEY
        sync: false
      - key: AWS_STORAGE_BUCKET_NAME
        sync: false
      - key: AWS_S3_ENDPOINT_URL
        sync: false
      - key: AWS_S3_REGION_NAME
        sync: false
      - key: TASK_TRIGGER_TOKEN
        sync: false
      - key: DJANGO_SUPERUSER_EMAIL
        sync: false
      - key: DJANGO_SUPERUSER_PASSWORD
        sync: false
```

Three real corrections from the earlier draft, all already applied above:

- **`config.wsgi:application`**, not `spekooh.wsgi` — this project's Django
  package is `config`, not `spekooh` (see `manage.py`).
- **`DJANGO_SETTINGS_MODULE=config.settings.prod` is explicit.** Left out,
  the service silently falls back to `config/wsgi.py`'s own default
  (`config.settings.dev`) — permissive `ALLOWED_HOSTS`, no forced HTTPS, no
  secure cookies — in what's supposed to be the hardened settings module.
  This is the single easiest way to accidentally deploy "dev" to a public
  URL.
- **`--bind 0.0.0.0:$PORT`** on the start command — Render's native
  (non-Docker) Python runtime requires the process to listen on the port it
  assigns via `$PORT`; omitting `--bind` leaves gunicorn on its own default
  and the health check never connects. `--workers ${WEB_CONCURRENCY:-2}`
  also actually *uses* the `WEB_CONCURRENCY` env var — the earlier draft
  defined it but the start command never read it.

Secrets (`sync: false`) are deliberately absent from git — see §4 for where
each one actually comes from.

### `backend/requirements.txt`

Only two lines added, both real installs from this repo's own venv (same
`pip freeze` convention `requirements.txt` already followed):

```
gunicorn==26.2.0
whitenoise==6.12.0
```

Nothing else from the earlier draft's list was actually missing:
`Django`, `djangorestframework`, `psycopg`/`psycopg-binary`,
`django-cors-headers`, `redis`, `requests` were already pinned. `celery` was
**not** added — see §6, this repo doesn't use Celery anywhere.
`dj-database-url` and `python-dotenv` were **not** added either —
`django-environ` (already a dependency) already parses `DATABASE_URL` and
reads a local `.env` file (`config/settings/base.py`); adding a second,
overlapping library for the same job isn't worth it.

---

## 3. `config/settings/prod.py` — already updated

Render sets `DJANGO_SETTINGS_MODULE=config.settings.prod` (per the
`render.yaml` above), so all of this only applies to Render, never to local
dev or CI:

```python
import os

from .base import *  # noqa: F401,F403

DEBUG = False
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Render injects this at runtime — the onrender.com hostname isn't known
# until the first deploy assigns it.
RENDER_HOST = os.getenv("RENDER_EXTERNAL_HOSTNAME")
if RENDER_HOST:
    ALLOWED_HOSTS = [*ALLOWED_HOSTS, RENDER_HOST]
    CSRF_TRUSTED_ORIGINS = [f"https://{RENDER_HOST}"]

# WhiteNoise serves static files from the app process itself — Render's
# free web-service plan has no separate static-asset host.
MIDDLEWARE = list(MIDDLEWARE)
MIDDLEWARE.insert(
    MIDDLEWARE.index("django.middleware.security.SecurityMiddleware") + 1,
    "whitenoise.middleware.WhiteNoiseMiddleware",
)
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {**STORAGES, "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"}}

# Required with Supabase's transaction-mode pooler (port 6543, see §1).
DATABASES["default"]["CONN_MAX_AGE"] = 0
```

Two real corrections from the earlier draft:

- **Layered on top of `base.py` in `prod.py`**, not rewritten inline —
  `base.py` already builds `ALLOWED_HOSTS`/`MIDDLEWARE`/`STORAGES`/
  `DATABASES` from real env vars (`DATABASE_URL` via `django-environ`,
  `AWS_*` for Supabase Storage); re-declaring them from scratch in
  `prod.py` would have silently dropped that.
- **`STATIC_ROOT` didn't exist at all** — dev never needed it (`runserver`
  serves static files itself, no `collectstatic` step). Verified live:
  `collectstatic` failed outright (`ImproperlyConfigured`) without it, and
  succeeds now (194 files, confirmed against a real `config.settings.prod`
  run with `RENDER_EXTERNAL_HOSTNAME` set).

### `/healthz/`

Added to `apps/core/views.py` + wired in `config/urls.py`, as
`render.yaml`'s `healthCheckPath` requires — a failed health check makes
Render mark the deploy unhealthy and roll it back.

---

## 4. Deploy

1. Push to GitHub (already on `main` once this PR merges).
2. render.com → **New** → **Blueprint**.
3. Select the repo — Render reads the root `render.yaml`.
4. Approve the plan → **Apply**.

First build takes 3–5 minutes. You get a URL like
`https://spekooh-staging.onrender.com` that doesn't change.

### Environment variables (Render dashboard → Environment)

| Key | Value |
|---|---|
| `DATABASE_URL` | staging Supabase pooler string (port 6543) |
| `REDIS_URL` | a real Redis instance's connection string (e.g. Render's own Key Value add-on). **Easy to miss — found missing live (2026-09-02)**: DEFAULT_THROTTLE_RATES (login, register, guest signup, password reset) all need this; without it every one of those 500s with `ConnectionError: Error 111 connecting to localhost:6379`, since that's the code's own safe local-dev fallback when this is unset. |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | staging Supabase Storage S3 credentials |
| `AWS_STORAGE_BUCKET_NAME` | staging Storage bucket's exact name. **Easy to skip entirely** — without it, uploads silently fall back to local disk (no error at all) regardless of the other AWS_* values being correct. |
| `AWS_S3_ENDPOINT_URL` | from Supabase's Storage → S3 Connection panel |
| `AWS_S3_REGION_NAME` | the real AWS-style region code from that same S3 Connection panel (e.g. `eu-west-1`) — **not the bucket name**. Found live (2026-09-02): pasting the bucket name here instead breaks S3's SigV4 request signing outright. |
| `TASK_TRIGGER_TOKEN` | long random string (see §6) |
| `DJANGO_SUPERUSER_EMAIL` / `DJANGO_SUPERUSER_PASSWORD` | your real admin login (see "Create an admin user" below — no Shell tab on the free plan) |
| `GEMINI_API_KEY` | (2026-09-05, optional) a real Gemini API key, from [Google AI Studio](https://aistudio.google.com/apikey). Without it, `generate_pending_artifacts` (see §6) fails every artifact with a clean "GEMINI_API_KEY is not configured" error instead of crashing — feature stays off, not broken. |
| `AI_ENABLED` | (optional, default `True`) set to `False` to kill-switch AI generation entirely — the cron command becomes a no-op and the summary endpoint returns 503, without touching `GEMINI_API_KEY`. |
| `GEMINI_MODEL` | (optional, default `gemini-2.5-flash`) |
| `AI_PROMPT_VERSION` | (optional, default `1`) bump this to force every cached summary to regenerate under a new prompt, without touching any existing row by hand — see `apps/ai/models.py`'s `GeneratedArtifact.prompt_version`. |
| `GEMINI_DAILY_BUDGET` | (optional, default `1200`) a hard cap on Gemini calls per day (`Africa/Douala` day boundary), enforced in Redis by `apps/ai/quota.py` — stops `generate_pending_artifacts` for the rest of the run once hit, rather than risking a surprise bill. |
| `GROQ_API_KEY` | (2026-09-05, optional) Lane B — the real-time student chatbot (`apps/ai/views.py`'s `PaperChatView`). From [console.groq.com](https://console.groq.com/keys). Without it, every chat request fails cleanly with "AI chat is currently unavailable" (503) instead of crashing — same no-op-safely posture as `GEMINI_API_KEY`. |
| `AI_CHAT_ENABLED` | (optional, default `True`) kill-switches Lane B only — independent of `AI_ENABLED`, since a live per-message chatbot has a different cost/abuse profile from Lane A's cron-batch summaries and needs to be stoppable on its own. |
| `GROQ_CHAT_MODEL` | (optional, default `llama-3.3-70b-versatile`) |
| `AI_CHAT_DAILY_LIMIT` | (optional, default `15`) free messages per user per day before an upgrade-to-Pro prompt (429). A `Subscription`-active (Kawlo Plus) user skips this cap entirely — see `PaperChatView`'s own comment. |
| `GROQ_DAILY_BUDGET` | (optional, default `500`) a hard, provider-wide daily call cap even a Pro user's "unlimited" chat is still subject to — the same defense-in-depth `GEMINI_DAILY_BUDGET` gives Lane A, against a runaway bug or abuse regardless of any one user's own quota. |

**Already set for you by `render.yaml`, not the dashboard:** `EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend`. Found live (2026-08-31): with no real email provider configured (see §8-adjacent "Owner action items" in `TODOS.md`), `config/settings/prod.py` had no `EMAIL_BACKEND` override at all, so Django's real default (SMTP, no host configured) crashed **every single registration** with an unhandled `ConnectionRefusedError` — a real 500 on the live site, not a hypothetical. The console backend just logs the email content instead of pretending to deliver it — an honest stand-in for staging, never appropriate for real production.

(No `SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_KEY`/`FLUTTERWAVE_*` rows — nothing
in this codebase reads those env vars today. Adding them now would be dead
config; see §8.)

Saving triggers a redeploy.

### Create an admin user

**Correction (2026-08-31, found live): the free plan has no Shell tab and no
one-off Jobs at all** — both are paid-plan-only (confirmed against Render's
own docs). The usual `python manage.py createsuperuser` has nowhere
interactive to run.

Instead, set two more env vars in the dashboard:

| Key | Value |
|---|---|
| `DJANGO_SUPERUSER_EMAIL` | your real admin email |
| `DJANGO_SUPERUSER_PASSWORD` | a real, strong password |

`build.sh` runs `python manage.py ensure_superuser` on every deploy — a
small idempotent command (`apps/accounts/management/commands/ensure_superuser.py`)
that creates exactly one superuser from those two env vars the first time,
then silently no-ops on every deploy after (it never resets the password if
you've since changed it via `/admin/`, and never errors out the way
Django's own `createsuperuser --noinput` would on a second run). Saving the
env vars triggers a redeploy, which creates the account.

Then log in at `https://spekooh-staging.onrender.com/admin/`.

---

## 5. Region and latency

`region: frankfurt` (already set). Render's regions are Oregon, Ohio,
Virginia, Frankfurt, and Singapore — none in Africa.

Frankfurt is the right default because Cameroonian traffic largely transits
European exchange points via the WACS, SAT-3, and ACE submarine cables.
Worth measuring from a real Douala or Yaoundé connection rather than
assuming, but Europe is the sane default for now.

---

## 6. Background tasks — the free tier limitation, and this repo's real architecture

**Render's free tier includes no background-worker or cron service.** The
earlier draft assumed a Celery worker + beat process — **this codebase has
no Celery anywhere.** Its scheduled work is already three plain, real
Django management commands, made safe for overlapping runs via
`select_for_update(skip_locked=True)` + Postgres partial unique indexes
(see each command's own docstring):

| Command | What it does | Real cadence (`scripts/crontab.example`) |
|---|---|---|
| `process_instructor_timeouts` | Instructor request timeouts + marking-guide day-4/day-6 reminders | every 15 min |
| `process_pamphlet_expiry` | 30-day pamphlet expiry flags + 3-day courier self-confirm fallback | hourly |
| `prune_stale_guest_accounts` | Removes guest accounts >24h old that never submitted anything | hourly |

Three options, in the order to adopt them:

### Option 1 — run them locally against staging (start here)

```bash
# .env.staging on your machine
DATABASE_URL=<staging pooler string>
```

```bash
DATABASE_URL=<staging pooler string> DJANGO_SETTINGS_MODULE=config.settings.prod \
  python manage.py process_instructor_timeouts
# ...repeat for the other two, or loop them on your own machine's crontab
```

Fine while you're the only tester. Runs only when your machine is on.

### Option 2 — token-protected trigger endpoints + free cron (already built)

`apps/core/views.py` exposes exactly this, wired to the three real commands
above via `call_command` — no fictional task functions, no broker:

```python
TRIGGERABLE_COMMANDS = {
    "process-instructor-timeouts": "process_instructor_timeouts",
    "process-pamphlet-expiry": "process_pamphlet_expiry",
    "prune-stale-guest-accounts": "prune_stale_guest_accounts",
    "delete-test-accounts": "delete_test_accounts",
    # AI generation (2026-09-05) — this same mechanism is also this
    # project's real replacement for a Celery task queue, which it
    # deliberately doesn't run (see apps.ai.management.commands
    # .generate_pending_artifacts's own docstring for why).
    "generate-ai-artifacts": "generate_pending_artifacts",
}


@csrf_exempt
@require_POST
def run_task(request, name):
    expected = os.environ.get("TASK_TRIGGER_TOKEN")
    received = request.headers.get("X-Task-Token")
    if not expected or not received or not hmac.compare_digest(received, expected):
        return HttpResponseForbidden()
    command = TRIGGERABLE_COMMANDS.get(name)
    if command is None:
        return JsonResponse({"error": "unknown task"}, status=404)
    call_command(command)
    return JsonResponse({"ran": command})
```

Routed at `config/urls.py`: `path('internal/tasks/<str:name>/', run_task)`.

At cron-job.org (free), create four jobs POSTing to:

```
https://spekooh-staging.onrender.com/internal/tasks/process-instructor-timeouts/
https://spekooh-staging.onrender.com/internal/tasks/process-pamphlet-expiry/
https://spekooh-staging.onrender.com/internal/tasks/prune-stale-guest-accounts/
https://spekooh-staging.onrender.com/internal/tasks/generate-ai-artifacts/
```

each with header `X-Task-Token: <the TASK_TRIGGER_TOKEN you set in §4>`, on
the same cadence as the real crontab table above. The fourth
(`generate-ai-artifacts`, added 2026-09-05) is this project's real
replacement for a Celery worker — see `apps/ai/management/commands
/generate_pending_artifacts.py`'s own docstring for why there isn't one.
Every few minutes is reasonable; it's a capped batch per run (`BATCH_SIZE
= 20`) and a no-op once nothing is pending. Requires `GEMINI_API_KEY` to
actually generate anything (see §4) — safe to schedule before that key
exists, it'll just no-op-fail each pending row until it's set.

A fourth endpoint on the same mechanism, but on-demand rather than
scheduled: `.../internal/tasks/delete-test-accounts/` deletes every `User`
row whose email ends in `@example.com` (the reserved test domain — see
`apps/accounts/management/commands/delete_test_accounts.py`). Live-testing
a real deployment (registering through curl or the app to confirm a fix
actually works) isn't mocked — it leaves real rows in the real staging
database, and the free plan has no Shell tab to delete them by hand. Safe
to hit any time; a no-op once none remain.

A side benefit: regular hits keep the instance warm, so testers hit the
cold start less often.

Tested: `apps/core/tests.py` covers the missing/wrong-token/wrong-method/
unknown-name/success paths, including that a real request actually invokes
`call_command` with the right command name — not a stand-in.

**This pattern is staging-only.** Production gets a real crontab (or
Render's own Cron Job service — see Option 3) — an HTTP endpoint that
mutates instructor/pamphlet/account state on any correctly-tokened request
is an availability and security liability under real load.

### Option 3 — Render Cron Jobs

Render has a dedicated **Cron Job** service type (distinct from a
Background Worker) that runs one command on a schedule and exits — no
broker, no always-on process, no Celery needed since this repo doesn't use
Celery. Point three Cron Job services at
`python manage.py process_instructor_timeouts` (etc.) on the crontab
cadence above. Simpler and cheaper than provisioning a Background Worker +
Key Value store for a broker nothing here would actually use.

---

## 7. Point Flutter at staging

```bash
flutter run --dart-define=API_BASE_URL=https://spekooh-staging.onrender.com/api
```

This already works exactly as-is — `app/lib/data/api_client.dart`'s
`ApiClient` already reads `API_BASE_URL` via `String.fromEnvironment` (the
same mechanism used all along for pointing the app at a local backend or a
cloudflared tunnel, see `RUNNING_LOCALLY.md`). No new config class needed.

### Cold starts are now handled

The instance spins down after 15 minutes idle; the next request takes
roughly a minute to wake it. `ApiClient` didn't have *any* request timeout
before this — an unreachable host just hung forever with no error and no
way for the UI to recover, staging or not. Every request path (`get`/
`post`/`patch`/`delete`/`postMultipart`/`putBytes`) now times out at 90s
(`_requestTimeout` in `api_client.dart`) instead.

(The earlier draft's example used `Dio`'s `connectTimeout`/`receiveTimeout`
— this app uses `package:http`, not Dio, so the equivalent is `.timeout(...)`
on each request future, which is what's actually in the code.)

Tell your testers about the cold start regardless — a 90-second wait on a
slow mobile connection still reads as "the app is broken" the first time,
even once it correctly resolves instead of hanging.

---

## 8. Flutterwave webhooks — not yet applicable

The earlier draft's webhook section assumed a real Flutterwave integration
already exists. **It doesn't.** `apps/payments` runs entirely on
`apps.core.payment_provider.MockPaymentProvider` (an instantly-successful
simulated charge, no network calls at all) — this is the same gap already
tracked in `TODOS.md`'s "Owner action items → Real payment provider," which
is itself blocked on business registration + real API keys, sandbox or
otherwise.

Building webhook-handling code against an API this repo doesn't call yet
would be pure speculation — there's no real request shape, no real
signature to verify, and nothing in `PaymentTransaction` (see
`apps/payments/models.py`) to reconcile it against. That integration is a
real feature in its own right (a new `PaymentProvider` subclass, real
Flutterwave SDK/API calls, a verify-then-credit flow, a webhook view with
real signature checking) — not a byproduct of a deploy target.

**When that integration exists**, its webhook URL on staging would be:

```
https://spekooh-staging.onrender.com/api/payments/webhook/
```

— permanent, no more updating it every session — and the receiving view
must, at minimum:

```python
import os
from django.http import HttpResponse, HttpResponseForbidden
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
def flutterwave_webhook(request):
    received = request.headers.get("verif-hash")
    expected = os.environ["FLUTTERWAVE_SECRET_HASH"]
    if not received or received != expected:
        return HttpResponseForbidden()

    # then re-verify the transaction against Flutterwave's own API
    # (amount, currency, status) before crediting anything — never trust
    # the webhook payload alone.
    return HttpResponse(status=200)
```

This is scaffolding for later, not something to add to `apps/payments/urls.py`
today — there is currently no `FLUTTERWAVE_SECRET_HASH`, no verify call, and
crediting an account from an unverified stub would be worse than not having
the endpoint at all.

---

## 9. Free tier limits worth knowing

- **750 instance hours per workspace per month** — one always-on service
  exceeds this, but a spinning-down staging service will not.
- **Spin-down after 15 minutes idle**, ~1 minute cold start.
- **No background workers, no cron, no Shell tab, no one-off Jobs at all** —
  confirmed against Render's own docs, not assumed. See §6 for background
  tasks and "Create an admin user" above for what replaces the Shell tab.
- **512 MB RAM** — sufficient for Django as this repo stands; tight if
  heavy PDF/OCR processing (already present — `apps.papers.ocr`) turns out
  to need more under real load. Worth watching, not yet a known problem.
- Render's own free Postgres expires after 30 days — irrelevant here,
  Supabase is the real database either way.

---

## 10. Deployment checklist

- [x] Separate staging Supabase project created — confirmed live (real seeded taxonomy loads)
- [x] Pooler connection string (port 6543) — `CONN_MAX_AGE = 0` already set in code
- [x] `backend/build.sh` — already committed and executable
- [x] `render.yaml` — already committed at repo root
- [x] `RENDER_EXTERNAL_HOSTNAME` / `DJANGO_SETTINGS_MODULE=config.settings.prod` — confirmed live (HTTPS redirect + plain prod 404 page prove it, not the dev fallback)
- [x] `/healthz/` — confirmed responding (200)
- [x] All secrets set in the Render dashboard, none in git
- [x] `DJANGO_SUPERUSER_EMAIL`/`DJANGO_SUPERUSER_PASSWORD` set, `ensure_superuser` mechanism tested — confirm your own `/admin/` login still works after any future redeploy
- [x] Flutter pointed at staging via `--dart-define=API_BASE_URL=...` — the real Android build now uses this permanently
- [x] Client timeouts — already raised to 90s in code
- [ ] Real Flutterwave integration built (§8) — **before** wiring a sandbox webhook URL, not after (still not built — see TODOS.md)

---

## 11. When to leave the free tier

Move to Render Starter (~$7/mo) or a Hetzner box before putting the app in
front of real students. A one-minute cold start on a slow mobile connection
reads as a broken app — free staging is for you and your testers, who know
to wait.
