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

## 6. Email — done (Brevo), verified with a real send (2026-09-14)

Unlike staging, `EMAIL_BACKEND` is **not** pinned to the console backend
for production — it's `sync: false` in `render.yaml`, forcing a conscious
choice rather than inheriting staging's stand-in silently.

**SendGrid was tried first and rejected** — Twilio's own compliance/
vetting team declined to activate the account outright ("unable to
proceed with activating your account... at this time"), a business
decision with no specifics given, not a technical issue. Notable: this
account's separate Twilio (SMS/Verify, §7) account was already approved
and working fine — SendGrid runs its own, stricter vetting even under the
same parent company.

**Switched to Brevo instead, and it's real and confirmed working** — not
just "the credentials look right": a real email was sent through Brevo's
SMTP relay using `smtplib` directly (bypassing Django entirely, to test
the credentials in isolation) and the owner confirmed receiving it in
their real inbox. One real snag along the way, also resolved: the first
attempt failed with `535 Unauthorized IP address` — Brevo restricts SMTP
sending to an allowlist of IPs by default, unhelpful for a service like
Render with no fixed outbound IP on shared plans; disabling that
restriction in Brevo's own settings (Settings → SMTP & API → Authorised
IPs) fixed it. Worth knowing if this ever mysteriously stops working after
being previously fine.

Set on `spekooh-production` (and `spekooh-staging` too, if you'd rather
have real email there instead of the console-backend stand-in):

| Key | Value |
|---|---|
| `EMAIL_BACKEND` | `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | `smtp-relay.brevo.com` |
| `EMAIL_PORT` | `587` |
| `EMAIL_HOST_USER` | `b94b43001@smtp-brevo.com` |
| `EMAIL_HOST_PASSWORD` | the Brevo SMTP key (sent separately, not committed here) |
| `EMAIL_USE_TLS` | `True` |
| `DEFAULT_FROM_EMAIL` | `storefix237@gmail.com` — **must** match the verified Brevo sender exactly, or Brevo rejects the send even with valid SMTP credentials; overrides `base.py`'s own `no-reply@spekooh.app` default |

Free tier is 300 emails/day — fine for now, worth watching once real
signups start; Brevo's dashboard shows real send volume if it's ever
worth checking before it becomes a problem.

---

## 7. SMS (Twilio) — phone verification works now, notifications need a number

Added 2026-09-14 (owner request). Two independent capabilities with two
different real-world requirements — see `apps.core.sms`'s own docstring
for the full reasoning:

- **Phone verification** (`/api/auth/verify-phone/`, `/confirm/`) uses a
  Twilio Verify Service. Confirmed live: works with no purchased phone
  number, even on this account's current $0-balance Trial status. A real
  Verify Service ("Spekooh") already exists — its SID is one of the four
  Twilio values sent to you separately, alongside `TWILIO_ACCOUNT_SID`/
  `TWILIO_API_KEY_SID`/`TWILIO_API_KEY_SECRET`.
- **SMS notifications** (`apps.notifications.services.notify(sms=True)`,
  opt-in per call site — not wired to any existing notification yet) needs
  `TWILIO_MESSAGING_FROM_NUMBER`: a real purchased Twilio phone number or
  Messaging Service. This account has neither — buying one needs real
  funds (confirmed live: $0 balance, no trial credit available), a real
  owner action item like Render's card and SendGrid's sender verification.
  No-ops safely (in-app notification still created) until one exists.

**Important, confirmed live (2026-09-14):** this Twilio account is on
**Trial** status, which restricts SMS delivery to phone numbers verified
in the console as "Verified Caller IDs" — real users' numbers won't
receive anything until the account is upgraded (a card added, same
category as the above). Fine for your own testing with your own number;
not fine for real users yet.

Set on `spekooh-production` (and `spekooh-staging` if you want phone
verification there too — see `RENDER_STAGING.md` §4's own row for these):
`TWILIO_ACCOUNT_SID`, `TWILIO_API_KEY_SID`, `TWILIO_API_KEY_SECRET`,
`TWILIO_VERIFY_SERVICE_SID`. Leave `TWILIO_MESSAGING_FROM_NUMBER` unset
until a number/Messaging Service exists.

---

## 8. Deploy checklist

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
- [x] Real email provider chosen (Brevo, after SendGrid's compliance team rejected the account) and verified with an actual send + confirmed receipt (§6)
- [ ] `EMAIL_*`/`DEFAULT_FROM_EMAIL` actually set on `spekooh-production` in the Render dashboard (values verified, not yet placed there)
- [ ] `DJANGO_SUPERUSER_EMAIL`/`DJANGO_SUPERUSER_PASSWORD` set (own real admin login, separate from staging's)
- [ ] `SENTRY_DSN` / `DJANGO_ADMIN_EMAILS` set — decide whether this reuses the same Sentry project as staging or gets its own (Sentry environments can separate them without a second project; simplest to start with the same project, filtered by its `environment` tag, which `config/settings/base.py`'s `sentry_sdk.init` already sets to `"production"` when `DEBUG=False`)
- [ ] `GEMINI_API_KEY` / `GROQ_API_KEY` set — own keys or shared with staging is a real cost/quota decision, not an engineering one; either works, code-wise
- [x] Twilio Verify Service created and verified live (§7) — phone verification works with no purchased number even on this $0-balance Trial account
- [ ] `TWILIO_ACCOUNT_SID`/`TWILIO_API_KEY_SID`/`TWILIO_API_KEY_SECRET`/`TWILIO_VERIFY_SERVICE_SID` set on `spekooh-production` (values verified, not yet placed there)
- [ ] Twilio account upgraded off Trial (a card, real funds) before real users' phone verification will work — Trial restricts SMS to console-verified numbers only
- [ ] A Twilio phone number/Messaging Service purchased and `TWILIO_MESSAGING_FROM_NUMBER` set — only needed for SMS notifications, not phone verification
- [ ] First manual deploy of `spekooh-production` (§2) after checking the same commit on staging
- [ ] Flutter's real release build points `API_BASE_URL` at `spekooh-production`'s URL, not staging's, before it ships to Play Console/App Store

Everything unchecked above is an owner action item (an account, a
decision, or a credential) — same category as `RENDER_STAGING.md`'s own
"Before you start" list, not further engineering work.
