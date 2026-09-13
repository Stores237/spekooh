# Spekooh — Render Production Deployment

Deploys the same Django backend as `RENDER_STAGING.md`, as a **second,
separate** Render service for real users — not staging promoted in place.
Read `RENDER_STAGING.md` first; this doc only covers what's different.

**Status: infrastructure defined (2026-09-13), not yet deployed.** The
production Supabase project has been reset to a clean slate and verified
empty (see the handoff file sent separately — it has the real connection
string). `render.yaml` now has a real `spekooh-production` web service plus
five Cron Job services. Nothing has actually been deployed yet — this is
the setup, not a "status: live" doc like `RENDER_STAGING.md`'s.

---

## 0. The one rule this whole doc follows

**Never reuse a staging value for production — not the database, not
Storage, not Redis, not any of it.** Staging's Postgres and Storage exist
to be broken during testing; a real user's account, submissions, and paid
unlocks need their own project. Every env var below says explicitly which
project it comes from.

---

## 1. What's actually different from staging

| | Staging (`spekooh-staging`) | Production (`spekooh-production`) |
|---|---|---|
| Render plan | `free` (spins down, cold starts) | `starter` (always-on, real card required on the Render account) |
| Auto-deploy | Every push to `main` | **Off** (`autoDeploy: false`) — promoted manually, see §2 |
| Supabase project | "Spekooh staging" (`hnhvmohcbzrqwovplljq`) | "Spekooh" (`gojwhocnznwxfdrszxfq`) — reset to empty 2026-09-13, see §3 |
| Storage bucket | staging's `spekooh-media` | production's own `spekooh-media` (same name, different project — already emptied of old test files) |
| Redis | staging's Key Value instance | its own, separate instance — see §4 for why sharing one is a real correctness problem, not just tidiness |
| Background jobs | HTTP-trigger endpoints + free `cron-job.org` (`RENDER_STAGING.md` §6, Option 2) | Real Render **Cron Job** services (`RENDER_STAGING.md` §6, Option 3) — no public endpoint, nothing to guess a token for. See §5. |
| `EMAIL_BACKEND` | Pinned to the console backend in `render.yaml` (logs, doesn't deliver — an honest stand-in for testers) | Left unset (`sync: false`) — must be a real provider before this handles real signups. See §6. |
| `TASK_TRIGGER_TOKEN` | Set | Not present at all — nothing to protect, the endpoint isn't wired to this service |

Everything else (Dockerfile, `config/settings/prod.py`, `/healthz/`,
`WEB_CONCURRENCY`, region) is identical — same image, same code, same
health check.

---

## 2. Why `autoDeploy: false`

Both services build from `branch: main` — the same commit that lands on
staging the moment it merges. Without this, every merge would also go
live to real users with zero gate in between; that defeats the entire
point of having a staging environment.

Instead: merge to `main` → staging auto-deploys → you (or a tester) check
it there → once satisfied, go to the `spekooh-production` service in the
Render dashboard → **Manual Deploy → Deploy latest commit**. Same build,
same image, deployed on purpose rather than by accident of timing.

---

## 3. Database — already set up, needs wiring in

The production Supabase project (`gojwhocnznwxfdrszxfq`, plain "Spekooh")
was, until 2026-09-13, an old, stale, disconnected project from this app's
earlier life — confirmed via direct SQL query (`information_schema.tables`,
row timestamps) before touching anything, since its own name didn't say
"staging" and its data needed checking rather than assuming. It has been:

- Password-reset via the Supabase Management API (new password issued,
  old one — never known to us anyway — is now invalid)
- Schema-wiped (`DROP SCHEMA public CASCADE` + recreate) — verified empty,
  0 tables
- Storage-wiped (40 old test files removed from its existing `spekooh-media`
  bucket, from before this project was repurposed) — verified empty, 0
  objects

The real pooler connection string (port 6543, matching staging's own
reasoning for why the pooler and not a direct connection — see
`RENDER_STAGING.md` §1) was sent to you separately as a file, not pasted
into chat. Set it as `DATABASE_URL` on `spekooh-production` in the Render
dashboard.

**Update (2026-09-13, same day): the schema is no longer empty.** Raw
Postgres connectivity from this environment, previously unreliable, held
long enough to run `manage.py migrate` directly against this database —
verified for real afterward via a direct query: 92 migrations applied, 58
tables now exist, including this repo's own real seed-data migrations
(`papers.0009_seed_report_exam_types`, `credits.0003_seed_credit_rules_config`,
`quizzes.0002_seed_quizzes`, `promotions.0003_seed_slearn_promotion`,
`accounts.0004_seed_admin_roles`, and others). The Dockerfile's own `CMD`
will still re-run `migrate`/`collectstatic`/`ensure_superuser` on
`spekooh-production`'s first real deploy (see `RENDER_STAGING.md` §2) —
harmless, all three are idempotent — but the database is already usable
now, not waiting on that first deploy.

### A note on `backend/.env` (local dev)

This developer's own local `.env` already pointed `DATABASE_URL` at this
exact project (`gojwhocnznwxfdrszxfq`) before any of this session's work —
its password just needed updating to match the reset above, which has been
done. That means **local dev/testing now runs directly against the real
production database** — Django's test runner creates and drops its own
`test_postgres` database on the same server rather than touching the `public`
schema's real data, but this is still not the isolation `RUNNING_LOCALLY.md`
actually recommends (a local Postgres you control) or that `RENDER_STAGING.md`'s
own model assumes (staging for anything that "exists to be broken"). Worth
deciding deliberately — point `.env` at a local Postgres or at the staging
project instead — rather than leaving it on production by inertia.

### Storage S3 credentials — done, real keys generated and verified (2026-09-13)

Confirmed working end-to-end via a real signed request (boto3, SigV4)
against Supabase's S3-compatible gateway — not just "the dashboard showed
a key":

- **Real anomaly found and fixed**: the `spekooh-media` bucket itself was
  gone by the time these new keys were tested (`NoSuchBucket` on a direct
  S3 call, confirmed independently via the Management API's own bucket
  list returning `[]`) — despite this session having only emptied its
  *contents* earlier, never the bucket itself. Cause unconfirmed (possibly
  disturbed while generating the access key in the dashboard) — recreated
  it via a real `CreateBucket` S3 call using the new key, which also
  proved the new key has real write/admin permission on this project, not
  just read access.
- Recreated as **private** (`"public": false`, confirmed via the
  Management API) — matching the bucket's original configuration.
- Full round-trip verified: `PutObject` → `GetObject` (got the exact bytes
  back) → a presigned `GetObject` URL resolved with a real `200` →
  the same object requested **unsigned** was correctly rejected (`400`,
  private bucket working as intended) → `DeleteObject` cleaned up the test
  artifact. Nothing left behind in the bucket.

Set these on `spekooh-production` (Render dashboard → Environment):

| Key | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | sent separately, not committed to this doc/repo |
| `AWS_STORAGE_BUCKET_NAME` | `spekooh-media` |
| `AWS_S3_ENDPOINT_URL` | `https://gojwhocnznwxfdrszxfq.storage.supabase.co/storage/v1/s3` |
| `AWS_S3_REGION_NAME` | `eu-west-1` |

Also needed on the `spekooh-production-pending-ocr` cron service (§5) —
it's the one job that touches Storage directly.

---

## 4. Redis — provision a separate instance

Render's own **Key Value** add-on again (same as staging), but a
**second, separate** instance — not staging's.

This isn't just hygiene: `apps.core`'s rate-limit throttles key their
Redis counters by `(scope, client identity)` — typically client IP for
anonymous endpoints like login/register/guest-signup. If staging and
production shared one Redis instance, heavy manual/automated testing
against staging from a given IP could contribute to that same IP's
throttle counter against production — a real correctness bug, not a
theoretical one, and more likely than it sounds given how much mobile
traffic in Cameroon sits behind carrier-grade NAT (many real users sharing
one public IP).

Set the new instance's connection string as `REDIS_URL` on
`spekooh-production`.

---

## 5. Background jobs — real Render Cron Jobs, not the HTTP-trigger pattern

`RENDER_STAGING.md` §6 already flagged its own HTTP-trigger + `cron-job.org`
mechanism as staging-only: *"an HTTP endpoint that mutates
instructor/pamphlet/account state on any correctly-tokened request is an
availability and security liability under real load."* Production instead
uses `RENDER_STAGING.md` §6's own **Option 3** — a native Render Cron Job
service per command, already defined in `render.yaml`:

| Service | Command | Schedule |
|---|---|---|
| `spekooh-production-instructor-timeouts` | `process_instructor_timeouts` | every 15 min |
| `spekooh-production-pamphlet-expiry` | `process_pamphlet_expiry` | hourly |
| `spekooh-production-prune-guest-accounts` | `prune_stale_guest_accounts` | hourly (offset 5 min so it doesn't collide with the one above) |
| `spekooh-production-ai-artifacts` | `generate_pending_artifacts` | every 10 min |
| `spekooh-production-pending-ocr` | `process_pending_ocr` | every 10 min |

Each is the same Docker image as the web service with its `CMD` overridden
(`dockerCommand` in `render.yaml`) to run exactly one management command
to completion, then exit — no long-running process, no public URL, nothing
to authenticate since nothing is reachable from outside Render at all.

Each cron service needs its own copy of whichever env vars its command
touches (`DATABASE_URL` + `REDIS_URL` on all five; `GEMINI_API_KEY` added
for the AI-artifacts one; the five `AWS_*` Storage vars added for the OCR
one, since it downloads submission files to run Tesseract against) — set
in the Render dashboard per service, same production values as the web
service, never staging's. (Render's dashboard also offers Environment
Groups if you'd rather set these once and share them across all six
production services — optional, not required.)

`delete-test-accounts` (staging's on-demand endpoint) has **no production
equivalent** — production shouldn't have an endpoint that deletes accounts
matching a reserved test domain running against real user data at all.

---

## 6. Email — the one real gap that must close before real users sign up

Unlike staging, `EMAIL_BACKEND` is **not** pinned to the console backend
for production — it's `sync: false` in `render.yaml`, forcing a conscious
choice rather than inheriting staging's stand-in silently.

Left unset entirely, `config/settings/base.py`'s own real default
(`django.core.mail.backends.smtp.EmailBackend`) takes over, and — since no
`EMAIL_HOST` exists yet either — every `send_mail` call (registration,
password reset) will fail loudly with `ConnectionRefusedError`, the exact
same failure `RENDER_STAGING.md` §4 documents hitting staging before its
console-backend stand-in was set. That's the correct behavior for
production: a signup failing visibly beats a real user silently never
receiving their verification code.

**This needs a real transactional-email provider before real users hit
this service** — e.g. SendGrid, Amazon SES, or Postmark's SMTP relay (any
of TODOS.md's already-tracked "Real email provider" options). Newly wired
this session (`config/settings/base.py`) so it's actually configurable via
env once you have one:

| Key | Value |
|---|---|
| `EMAIL_BACKEND` | `django.core.mail.backends.smtp.EmailBackend` (Django's real default — only needs setting explicitly now since it's `sync: false`) |
| `EMAIL_HOST` | your provider's SMTP host (e.g. `smtp.sendgrid.net`) |
| `EMAIL_PORT` | usually `587` |
| `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` | your provider's real SMTP credentials/API key |
| `EMAIL_USE_TLS` | `True` (default in code now, but Render's own env var takes precedence if you set it) |

This is a real owner action item (an account + credentials with a real
provider), same category as Supabase/Render itself — not something to
build further without one.

---

## 7. Deploy checklist

- [x] `render.yaml` — `spekooh-production` web service + 5 Cron Job services defined
- [x] Production Supabase project reset to a clean slate, verified empty (schema + Storage)
- [x] `manage.py migrate` run for real against it — 92 migrations, 58 tables, verified via direct query
- [x] `config/settings/base.py` — `EMAIL_HOST`/`EMAIL_PORT`/`EMAIL_HOST_USER`/`EMAIL_HOST_PASSWORD`/`EMAIL_USE_TLS` now read from env, so a real SMTP provider is actually wireable
- [ ] Real card added to the Render account (required for `plan: starter`, not free)
- [ ] Render Blueprint re-synced (push this to `main`, then **New → Blueprint** or let the existing Blueprint pick up the new services) to actually create `spekooh-production` and the 5 cron services
- [ ] `DATABASE_URL` set on `spekooh-production` (the string sent separately) — triggers the first real deploy, which runs `migrate` for real
- [ ] Separate production Redis (Key Value) instance provisioned, `REDIS_URL` set on all 6 production services
- [x] S3 access keys generated from the Supabase dashboard (§3) — verified via a real signed round-trip (put/get/presigned-get/unsigned-get-rejected/delete); bucket had to be recreated (see §3's note), now private, confirmed
- [ ] `AWS_*` actually set on `spekooh-production` and on `spekooh-production-pending-ocr` in the Render dashboard (values verified, not yet placed there)
- [ ] A real email provider chosen and `EMAIL_*` set (§6) — **blocking for real signups**
- [ ] `DJANGO_SUPERUSER_EMAIL`/`DJANGO_SUPERUSER_PASSWORD` set (own real admin login, separate from staging's)
- [ ] `SENTRY_DSN` / `DJANGO_ADMIN_EMAILS` set — decide whether this reuses the same Sentry project as staging or gets its own (Sentry environments can separate them without a second project; simplest to start with the same project, filtered by its `environment` tag, which `config/settings/base.py`'s `sentry_sdk.init` already sets to `"production"` when `DEBUG=False`)
- [ ] `GEMINI_API_KEY` / `GROQ_API_KEY` set — own keys or shared with staging is a real cost/quota decision, not an engineering one; either works, code-wise
- [ ] First manual deploy of `spekooh-production` (§2) after checking the same commit on staging
- [ ] Flutter's real release build points `API_BASE_URL` at `spekooh-production`'s URL, not staging's, before it ships to Play Console/App Store

Everything unchecked above is an owner action item (an account, a
decision, or a credential) — same category as `RENDER_STAGING.md`'s own
"Before you start" list, not further engineering work.
