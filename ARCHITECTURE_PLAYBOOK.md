<!--
This is a portable copy of the reference doc behind the globally-installed
"app-architecture-playbook" Claude Code skill (~/.claude/skills/app-architecture-playbook/).
Read it stand-alone, copy it into a new app's repo, or hand it to someone else directly — no
Claude Code dependency either way. If you update one copy, update the other; they're meant to
stay in sync, not drift into two different versions of the same advice.
-->

# App architecture playbook

Extracted from building and operating Spekooh (Django+DRF backend, Flutter app, Supabase,
Render). This is the *process*, not the product — nothing about exam papers or the Points economy
belongs in a new app; the stack choices, the deploy/test/debug discipline, and the documentation
conventions do.

Every claim below traces to a real file or a real incident in this codebase, not generic
Django/Flutter advice. Where it says "found live," that means: reproduced against a real deployed
environment, not inferred from reading code — see "Debugging discipline" for why that distinction
matters more than it sounds like it should.

---

## 1. The stack, and why each piece

| Piece | Role | Why this one, not an alternative |
|---|---|---|
| **Django + DRF** | Backend API | Batteries-included admin (free internal tooling), migrations, and an ORM mature enough that `django-storages`/`django-filter`/`simplejwt` all just work rather than needing custom glue. |
| **Flutter** | Mobile client | One codebase, two platforms; the repo pattern (below) keeps the UI layer honest about what's real vs. mocked during early development. |
| **Supabase** | Managed Postgres **and** S3-compatible object storage, as two separate services under one account | One provider for both halves of "where does state live," one less set of credentials to keep in sync between local/staging/production. Reached through its **connection pooler** (port 6543, not 5432) from any host that restarts/redeploys often — a direct connection accumulates and exhausts the connection limit across restarts; the pooler in transaction mode survives that churn. |
| **Render** | Hosts the Django process (`gunicorn`) in a Docker container | Free tier for staging (no card required), a paid "Starter" tier for production. `render.yaml` as a Blueprint — the whole infra is in version control, not hand-clicked. |
| **WhiteNoise** | Serves static files from the Django process itself | Free-tier Render has no separate static-asset host/CDN; this means zero extra infrastructure for admin CSS/JS. |
| **A free external cron** (e.g. cron-job.org) hitting a token-gated internal endpoint | Scheduled jobs on the free tier | Render's free tier has no native cron or background-worker service — this is a complete workaround, not a half-measure: see "Scheduled jobs on a free tier," below. |
| **Sentry** | Error tracking + optional light tracing | No-ops entirely when its DSN env var is unset, so a fresh clone works with zero signup. **Read the "Sentry + signed requests" lesson below before enabling tracing** — this bit a real deploy hard. |

**Deliberately not used:** Celery/a message broker (every "background job" is a plain Django
management command, cron-triggered — see below); a native mobile codebase per platform; any ORM
other than Django's own.

---

## 2. Repo layout

```
repo-root/
  backend/              # Django project
    config/
      settings/
        base.py         # shared; env-driven, safe defaults for a fresh clone
        dev.py           # DEBUG=True, local-disk fallback
        prod.py           # DEBUG=False, WhiteNoise, SECURE_* flags
    apps/
      <domain>/          # one Django app per bounded domain (accounts, papers, notes, …)
        models.py migrations/ serializers.py views.py urls.py admin.py
        tests.py factories.py   # Factory Boy fixtures, not raw .objects.create() in tests
    Dockerfile
    requirements.txt + requirements/*.txt   # pinned; dependabot keeps these current
  app/                   # Flutter client
    lib/
      data/
        api_client.dart          # one HTTP client, dart-define API_BASE_URL
        repositories/            # interface + a real `http/` impl per domain
      models/ screens/ theme/ l10n/
  render.yaml             # Blueprint — staging + production + cron jobs, all in one file
  CLAUDE.md                # points every session at DESIGN.md, skill routing, conventions
  DESIGN.md                # tokens + a dated decision log (see "Documentation" below)
  BETA_CHANGES.md          # a living changelog written for "whoever deploys next"
  TODOS.md                 # owner-action-items vs. engineering work, kept separate on purpose
  RENDER_STAGING.md / RENDER_PRODUCTION.md   # infra docs, staging and prod never share secrets
```

The split between `RENDER_STAGING.md` and `RENDER_PRODUCTION.md` (not one combined doc) matters:
production's env vars, Supabase project, and Redis instance must **never** reuse staging's —
having two docs instead of one with "staging vs. prod" columns makes that much harder to get
wrong by copy-paste.

---

## 3. Backend setup

- **Settings split**: `base.py` (shared, every value has a safe fallback via `django-environ` so
  a fresh clone with zero env vars still runs), `dev.py`, `prod.py`. `prod.py` sets
  `DEBUG=False`, `SECURE_SSL_REDIRECT=True`, inserts WhiteNoise into `MIDDLEWARE`, and reads
  `RENDER_EXTERNAL_HOSTNAME` at runtime (Render assigns this; it isn't known until first deploy).
- **Storage**: `STORAGES["default"]` falls back to `FileSystemStorage` when
  `AWS_STORAGE_BUCKET_NAME` is unset, and to `storages.backends.s3.S3Storage` (S3-compatible,
  pointed at Supabase's Storage endpoint) when it is. Same model field (`FileField`) either way —
  the view/serializer code never branches on which storage backend is active.
- **Auth**: `rest_framework_simplejwt`, with refresh-token rotation + blacklisting (a stolen
  refresh token should stop working the first time it's reused after rotation, not keep working
  forever).
- **One DB, reached the same way everywhere**: local dev, CI, and tests all point at the same
  *kind* of Postgres (via the pooler) rather than local dev using SQLite and tests using
  something else — divergence there is exactly what let the real incident in §6 go unnoticed for
  weeks (passing tests, broken production).
- **Rate limiting**: DRF's `ScopedRateThrottle` backed by `django-redis`. This has a real failure
  mode worth building in from day one: without a reachable Redis, every throttled endpoint
  (login, register, guest signup, password reset) returns a raw `ConnectionError` 500, not a
  clean 429 or a bypassed throttle. **Redis is not optional the moment you add a single
  rate-limited endpoint** — provision it in the same PR that adds the first throttle, not later.

---

## 4. Deploy (Render + render.yaml)

- **One `render.yaml`, every environment.** Staging and production are two separate `services:`
  blocks in the same file — same Dockerfile, same build, different `plan`, different
  `autoDeploy`, and (critically) **entirely separate secrets** referenced as `sync: false`
  placeholders the owner fills in by hand in each service's own dashboard, never shared.
- **`autoDeploy: true` for staging, `false` for production.** Every push to `main` that passes CI
  redeploys staging automatically — "merged" means "a tester can see it in minutes." Production
  is promoted deliberately: **Render dashboard → Manual Deploy → Deploy latest commit**, on a
  commit that's already been checked on staging, not automatically the moment CI goes green.
- **Why Docker, not the platform's native runtime**: the native Python runtime on Render blocks
  `apt-get`/OS-level package installs entirely. If anything in the stack needs a real system
  binary — this app needed `tesseract-ocr` + `poppler-utils` for OCR — the native runtime simply
  can't provide it, full stop. Found live on first attempt; switched to `runtime: docker` with a
  real `Dockerfile` (`FROM python:3.13-slim`, `apt-get install -y tesseract-ocr poppler-utils`).
  **Decide this before writing any code that needs a system binary**, not after a failed deploy —
  it changes the whole service block's shape (`dockerfilePath`/`dockerContext` instead of
  `buildCommand`/`startCommand`).
- **Monorepo path gotcha, found live**: with `rootDir: backend` set on the Render service,
  `dockerfilePath`/`dockerContext` are resolved **relative to that `rootDir`, not the repo
  root** — despite Render's own docs claiming the opposite. Setting both to `backend/...` on top
  of `rootDir: backend` produces a literal, nonexistent `.../backend/backend` path. Trust a real
  failed deploy over the platform's own documentation here.
- **Migrate/collectstatic/ensure_superuser run at container *start*, not build time** — the
  Dockerfile's `CMD` is a shell chain: `collectstatic && migrate && ensure_superuser && exec
  gunicorn ...`. Real env vars (`DATABASE_URL`, secrets) only exist once Render *runs* the
  container; `docker build` never sees them, so anything that imports Django settings at build
  time raises `ImproperlyConfigured` before the image even finishes. All three steps are
  idempotent by design (`migrate` always is; `ensure_superuser` explicitly skips an existing
  user) so re-running them on every single container start/restart is safe. `exec gunicorn` (not
  a bare `gunicorn` in a sub-shell) so it becomes PID 1 and receives `SIGTERM` directly from
  Render on deploy/restart, instead of an intermediate shell swallowing it.
- **Long-running synchronous work needs a real worker timeout.** Gunicorn's own default worker
  timeout is 30s; this app runs synchronous OCR inside a request/response cycle for a background
  task trigger, and a real timed run took 150+ seconds under free-tier CPU. A worker that misses
  gunicorn's deadline gets killed outright, and Render's proxy reports a 502 — independent of
  whatever timeout the *calling* side used. Raise `--timeout` generously for any endpoint that
  does real synchronous heavy lifting, and prefer shrinking the batch size of what one request
  processes over trusting a bigger timeout alone.
- **Scheduled jobs on a free tier**: Render's free web-service plan has no native cron and no
  one-off Jobs. The real workaround used here: every "scheduled task" is a plain Django
  management command (no Celery, no broker) triggered two different ways depending on
  environment — locally via `crontab`, on staging via a free external scheduler
  (cron-job.org) POSTing to a token-gated `/internal/tasks/<name>/` endpoint. **Production**
  instead gets real Render **Cron Job** services (paid tier has them) running the same command
  directly — no public endpoint, nothing to guess a token for. Don't carry the staging-only
  HTTP-trigger pattern into production; it's "an endpoint that mutates state on any
  correctly-tokened request," which is fine for a free-tier stopgap and a real liability under
  real load.
- **`createsuperuser` has nowhere interactive to run** on a free-tier service with no Shell tab —
  that's *why* `ensure_superuser` exists as an idempotent management command baked into the
  container's own startup chain instead.

---

## 5. Testing

- **Tests run against the same kind of database production uses** — a real Postgres, reached
  through the pooler, not SQLite-for-tests-only. Add `--reuse-db` to `pytest-django`'s invocation
  when the database is a shared/pooled remote instance: without it, every test run tries to
  `DROP DATABASE`/`CREATE DATABASE`, which conflicts with a connection pooler holding the old one
  open and produces a confusing "database is being accessed by other users" error that looks
  like flakiness but isn't.
- **Factory Boy, not raw `Model.objects.create(...)` in every test** — one `factories.py` per
  app, `django_get_or_create` for anything that should reuse a seeded row (e.g. a taxonomy
  category) rather than creating a fresh duplicate per test.
- **Migrations that backfill real data are always idempotent and fail loudly, never silently.**
  The working pattern, used repeatedly in this codebase for exactly this reason: `AddField(null=
  True)` → `RunPython` backfill (two passes — validate every row first, write only after every
  row validates, with alias dicts for known-equivalent old values) → `AlterField(null=False)` →
  `RemoveField` of the old column, all in one migration file. If a future deploy has a row the
  backfill can't match, it should raise a real `RuntimeError` naming exactly which rows, rather
  than leaving a required field silently empty or guessing wrong.
- **A regression test for a concurrency bug has to actually force the race**, not just assert
  the fix "should" work — e.g. an in-flight-request memoization fix was tested by adding an
  artificial delay so two concurrent callers provably hit the same in-flight future, not two
  separate ones that happened not to collide in a fast CI run.

---

## 6. Debugging discipline — the one thing worth internalizing most

**A passing local test and a 500 on the real deployed service are both real facts; neither one
is false just because it contradicts the other.** The instinct to "figure out the fix by reading
the code harder" is the wrong move once a *deployed* environment disagrees with *local*
behavior — the honest next step is reproducing the failure live against the real service,
repeatedly, after every single hypothesis, and only believing a fix once that live
reproduction actually turns green.

This app's own history is the clearest evidence for this: a single reported bug ("can't submit a
paper") took five PRs to actually fix, and the first four were each individually correct,
real, justified fixes for real problems the investigation uncovered — none of them were *the*
bug. What made this *solvable at all*, rather than an endless guessing loop:

1. **Error visibility is a prerequisite, not a nice-to-have.** `DEBUG=False` + no `ADMINS` + no
   `SENTRY_DSN` meant a real deployed service was failing every single request and leaving
   **zero trace of why**, anywhere. Before debugging any live-only failure, confirm the
   deployed environment actually surfaces its own exceptions somewhere you can read them — don't
   assume this "just works" because Sentry/logging exists in the codebase; verify the specific
   environment actually has them wired up.
2. **An exception's string representation can lie by omission.** `"An error occurred () when
   calling the PutObject operation:"` looked like an empty, unparseable response — it wasn't;
   it was a perfectly normal, well-formed `SignatureDoesNotMatch` error that got truncated
   somewhere in how it was being read. Two real fixes got shipped chasing the "empty response"
   theory before temporary wire-level debug logging showed the literal bytes and ended the
   guessing.
3. **Reproduce the *specific* failing condition, not an approximation of it.** Every local
   attempt to reproduce this bug used `manage.py shell` — which never has an active
   request/transaction context. The actual bug only existed when there was one (Sentry only
   injects trace headers when there's a transaction to propagate). "It works when I test it
   locally" was true and also completely irrelevant, because the local test wasn't exercising
   the one condition that mattered.
4. **Re-test the exact original failure after every fix, not just the new symptom.** The
   checksum-compat fix (a real, correct fix for a real botocore/Supabase incompatibility)
   shipped, and the very next test happened to hit a *different* bug that fix had introduced
   (a SigV4 signature regression) — which looked like partial progress but actually meant the
   original failure was never re-verified at all. It took going back afterward to confirm the
   original bug was still there, unrelated to either fix. Always circle back to the literal
   original repro, not just whatever the most recent test showed.

---

## 7. Lessons learned (the specific, non-obvious ones)

| Symptom | Real cause | Fix |
|---|---|---|
| Every S3 write from the Django process to a Supabase Storage bucket fails with an unparseable `ClientError`, but a presigned URL used by an external client works fine against the same bucket | `sentry-sdk` auto-enables its Boto3 integration and, by default, injects `sentry-trace`/`baggage` headers into *any* outgoing HTTP call made during an active transaction — including boto3's own SigV4-signed calls. The signature gets computed over headers that don't match what the storage gateway reconstructs. | `sentry_sdk.init(..., trace_propagation_targets=[])` unless there's a real first-party service that needs trace continuity. |
| A new `botocore`/`boto3`/`urllib3` version makes `PutObject` to a non-AWS S3-compatible store fail | Recent `botocore` defaults to streaming uploads with an `aws-chunked` trailer-checksum envelope some S3-compatible gateways don't handle. | `botocore.config.Config(request_checksum_calculation="when_required", response_checksum_validation="when_required")`, passed as `client_config` in `django-storages`' `S3Storage` OPTIONS. |
| Presigned URLs silently switch from SigV4 to legacy SigV2 query-auth form the moment the fix above ships | `django-storages`' `S3Storage` only builds its own `Config(signature_version=...)` when `self.client_config is None` — setting `client_config` explicitly (for the checksum fix) silently discards a separate top-level `"signature_version"` OPTIONS key. | Put `signature_version` **inside** the same `Config` object as the checksum settings — one source of truth, not two settings that only cooperate when one is unset. |
| Redefining a Python logging `dictConfig` handler by name doesn't change what an existing logger actually uses | `dictConfig` only relinks a logger to a same-named handler if that logger is **also** re-declared in the same config call — otherwise it keeps pointing at whatever handler object the previous `dictConfig` pass created. | Re-declare the logger (e.g. Django's own `"django"` logger), not just the handler, in the same `LOGGING` dict. |
| Every rate-limited endpoint 500s with a raw `ConnectionError` instead of a clean 429 | `DEFAULT_THROTTLE_RATES` + `ScopedRateThrottle` need a real reachable cache backend (Redis); with none configured, the code's own documented local-dev fallback (`localhost:6379`) fails outright on a server with no local Redis. | Provision Redis (`REDIS_URL`) in the same change that adds the first rate-limited endpoint, not as a follow-up. |
| A direct-to-storage presign-then-PUT upload path, and the storage_key submit call that follows it, are treated as "the same bug" because both return a bare 500 | They can be two entirely different, unrelated server-side exceptions — a generic error page with no detail (correctly suppressed in production) looks identical regardless of cause. | Get real error visibility (see §6) before assuming two failures share a root cause just because the symptom looks the same. |
| A background/cron-triggered endpoint needs to mutate server state and is reachable by anyone who knows a token | Free-tier hosting has no native scheduler, so an HTTP-trigger-plus-external-cron pattern is a reasonable *stopgap* | Treat it as staging-only from day one; production gets a real scheduler (a paid tier's native Cron Job service) with no public endpoint at all. Don't let the stopgap migrate to production by inertia. |

---

## 8. Flutter app conventions

- **One `ApiClient`, base URL from `--dart-define=API_BASE_URL=...`** at build time — never
  hardcoded, never read from a settings screen. A beta build points permanently at the staging
  URL; swapping environments is a different build invocation, not a runtime toggle.
- **Repository pattern, with a real HTTP implementation and (where useful) a local-fallback one**
  — screens depend on an interface (`PapersRepository`), never on `ApiClient` directly, so a
  screen's tests can inject a fake without spinning up real HTTP.
- **A network failure on a tap should never look like nothing happened.** A repeated real bug in
  this codebase: a taxonomy-fetch failure behind a field picker left the field looking
  unresponsive with zero feedback. The fix pattern that stuck: wrap every such fetch in a guard
  that turns an exception into a visible `SnackBar`, every time, not case by case.
- **Guest identity is minted per-action, never stored as a real session.** A "contribute without
  an account" flow mints a one-off guest JWT right before the one request that needs it; nothing
  about that identity persists if the app closes, and it never touches the real
  login/`isLoggedIn` state.
- **Every user-visible string goes in both locale `.arb` files before `flutter gen-l10n` runs** —
  committing a feature with English-only strings is a recurring, avoidable regression class.

---

## 9. Beta distribution (before any Play Console listing)

A real device needs an installable `.apk`, and a quick-tunnel service is enough to distribute one
without a store listing:

1. `flutter build apk --release --dart-define=API_BASE_URL=<staging URL>/api --build-number=N`
   — increment `N` for every distinct build; `pubspec.yaml`'s own `version:` line can stay fixed
   until an actual Play Console upload needs it bumped.
2. **Verify before distributing, every time** — don't trust a successful build alone:
   - `aapt2 dump badging` — confirms package name, version code, label.
   - `apksigner verify --print-certs` — confirms the signing key's fingerprint is the expected
     one (continuity across builds, not a debug key).
   - Confirm `debuggable` is **not** set.
   - Extract `libapp.so` and `grep`/`strings` it for a value you know should be baked in (the API
     base URL, a recent string change) — this catches "the build succeeded but used stale/cached
     Dart code" in a way `flutter build`'s own exit code won't.
   - `sha256sum` before and after any copy/hosting step, to catch silent corruption.
3. **Host it**: `python3 -m http.server` locally, then a quick tunnel
   (`cloudflared tunnel --url http://localhost:PORT`) to get a public HTTPS link. If the tunnel
   provider defaults to QUIC/UDP and that protocol is unreliable in the hosting environment,
   force HTTP/2 explicitly (`cloudflared tunnel --protocol http2 --url ...`) rather than letting
   it retry QUIC repeatedly and fail. **The tunnel only lives as long as the host process does**
   — expect to re-host (not necessarily rebuild) after any environment restart, and verify the
   re-hosted file's SHA-256 still matches the original build exactly before calling it done.
4. **Don't rebuild when nothing changed.** If the only thing that changed since the last build
   was backend-only (no `app/` diff), the existing `.apk` is still correct — re-host it, don't
   waste a build cycle producing a byte-identical artifact under a new number.

---

## 10. Documentation conventions

These are what make "whoever deploys next" (including a future session with no memory of this
one) actually able to pick the project up correctly:

- **`BETA_CHANGES.md`**: a living, numbered changelog — one `## N. Title` section per
  logical change, each with **What/Why**, exactly **where** the change lives, **how to verify**
  it (a real command or a real click-path, not "should work"), and **whether it touches real
  data** (migrations get their own rollback instructions). A top "At a glance" table indexes
  every section by number. Written for a reader who wasn't there, not as a personal log.
- **`DESIGN.md`**: design tokens plus a **dated decision log** — every new color/radius/shadow/
  copy rule gets a logged row, not just a code change. The code's own token values are the
  source of truth if the doc and the code ever disagree; fix the doc in the same PR, don't leave
  it stale.
- **`TODOS.md`**: split into **owner action items** (needs an account, a decision, a person — not
  engineering work, and explicitly labeled as blocking engineering work until resolved) versus
  actual P0/P1/P2 engineering backlog, plus a running **"Recently shipped"** section dated by
  stretch of work. Keeping "things only the owner can unblock" visually separate from "things
  engineering can just go build" stops both lists from quietly blending into one undifferentiated
  backlog nobody trusts.
- **`RENDER_STAGING.md` / `RENDER_PRODUCTION.md`**: separate documents, not one doc with two
  columns — reinforces that the two environments' secrets, Supabase projects, and Redis instances
  must never be shared, in a way that's hard to accidentally violate by copy-pasting between
  columns in a single table.
- **A beta has a stated window.** Record the start date, the length, and what "beta" means for
  priority (bug fixes over new features, unless told otherwise) in whichever doc already tracks
  the beta — don't let "we're in beta" become an open-ended, undated state nobody can point to.

---

## Build order

For a genuinely new app following this shape, in the order that avoids the most rework:

1. Backend skeleton: Django + DRF + the settings split (§3), pointed at a real Supabase Postgres
   from day one (not SQLite "for now") — the single biggest source of "works locally, fails in
   staging" bugs in this codebase's own history was environment divergence, and starting on the
   real database kind from day one removes that whole category.
2. Auth (JWT + rotation/blacklisting) before building any other feature that needs a logged-in
   user — nothing else is testable realistically without it.
3. `render.yaml` with a staging service, Docker runtime decided **now** if any system binary is
   known to be needed later (§4) — changing this after the fact is a bigger diff than deciding it
   up front.
4. Redis + the first rate-limited endpoint, together, in the same change (§3, §7).
5. Real Supabase Storage wired in before the first file-upload feature is built against a
   local-disk assumption that later needs unwinding.
6. The Flutter app's `ApiClient` + repository pattern, pointed at the real staging URL via
   `--dart-define`, before writing UI that assumes a different data-fetch shape.
7. The documentation set (§10) started on day one, not backfilled later — a changelog written
   after the fact is a summary; one written alongside the work is a real record.
8. Beta APK build/verify/host workflow (§9) set up before the first real tester, so "ship a beta
   build" is a known, repeatable five-minute process by the time it's actually needed under time
   pressure.
