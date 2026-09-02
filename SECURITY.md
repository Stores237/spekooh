# Security Policy

Adapted for Spekooh's actual stack (2026-09-02) — the previous version of
this file described a different, unrelated project (a Vercel/Next.js
frontend backed entirely by Supabase, with a `middleware.ts` behavioral
firewall and Vercel WAF rules). Nothing about that architecture applies
here: Spekooh is a Django REST API on Render, a Postgres + S3-compatible
object store on Supabase used only as infrastructure, and a Flutter
mobile/web client. Every claim below was checked against this codebase's
actual code, not carried over.

## Reporting a vulnerability

Email **storefix237@gmail.com** with what you found and how to reproduce
it. Please don't open a public GitHub issue for anything you believe is
exploitable — give us a chance to ship a fix first. We'll acknowledge
within a few days.

## Architecture at a glance

- **Backend**: Django + Django REST Framework, deployed on Render
  (`render.yaml`, `RENDER_STAGING.md`).
- **Database**: Postgres, hosted on Supabase (used purely as a managed
  Postgres instance here — Supabase's own Auth/RLS features are not part
  of this stack; Django owns all authorization).
- **Object storage**: Supabase Storage (S3-compatible) for uploaded
  papers/avatars in production, via `django-storages`; local disk in dev.
- **Client**: Flutter, targeting Android/iOS/web from one codebase.
- **No CDN or WAF sits in front of the API today.** Render's platform-level
  DDoS protection applies to the underlying infrastructure; there is no
  additional edge layer (Cloudflare, Vercel WAF, etc.) — see "Known gaps"
  below.

## Authentication

- JWT via `djangorestframework-simplejwt`
  (`config/settings/base.py`'s `SIMPLE_JWT`): a 5-minute access token, a
  1-day refresh token, with **rotation and blacklisting enabled** — every
  refresh both issues a new refresh token and blacklists the one just
  used, so a leaked refresh token is single-use rather than valid,
  unrevocable, for its full lifetime (`apps/accounts/tests.py::
  test_refresh_rotates_the_refresh_token_and_blacklists_the_old_one`
  proves this end-to-end, not just as a settings assertion). The Flutter
  client persists the rotated token on every refresh
  (`app/lib/data/auth_session.dart`'s `refreshAccessToken`) — this only
  works because both sides agree on it.
- Login and registration are throttled per-IP
  (`"login": "20/hour"`, `"register": "10/hour"` in `DEFAULT_THROTTLE_RATES`)
  — added 2026-09-02; both were previously completely unthrottled, leaving
  credential-stuffing against login and spam account creation against
  registration unmitigated at the application layer.
- Password requirements are Django's standard validators
  (`AUTH_PASSWORD_VALIDATORS` in `config/settings/base.py`): minimum
  length, common-password rejection, similarity-to-user-info rejection,
  not-all-numeric.
- **Guest accounts** (`apps/accounts/views.py`'s `GuestView`) are real
  `User` rows with no usable password, minted specifically so a
  contributor can submit a paper without creating a full account. Rate
  limited (`"guest_mint": "10/hour"` per IP) since each mint is a
  permanent DB row until the daily prune job reaps stale ones. A guest
  identity is scoped to one request (see `mintGuestAccessToken`'s
  docstring) — it never becomes an app-wide logged-in session.
- Password reset and email verification (request + confirm, both the
  authenticated and by-email-recovery variants) are each individually
  throttled — see the full table in `DEFAULT_THROTTLE_RATES`. The reset
  code itself also has its own attempt cap (`PasswordResetCode`), so
  brute-forcing one specific code is bounded independently of the
  request-rate throttle.

## Authorization

- DRF's default permission is `IsAuthenticated` — every view has to
  explicitly opt into `AllowAny` (registration, login, guest, public
  taxonomy reads), rather than defaulting open.
- Ownership is checked explicitly even where queryset scoping alone would
  already 404 a non-owner — e.g. `PaperSubmissionViewSet.dismiss` checks
  `paper.submitted_by_id != request.user.id` directly, because staff
  users' `get_queryset()` is intentionally unfiltered (they can see any
  paper), and without the explicit check a staff account could "dismiss"
  a rejection on a contributor's behalf.
- Staff/admin access is role-scoped, not all-or-nothing: `Reviewer` and
  `Support` Django groups (seeded in `apps/accounts/migrations/
  0004_seed_admin_roles.py`, extended in `0008_reviewer_notes_pamphlets_
  permissions.py`) get different real Django model permissions, and the
  admin dashboard (`apps/core/admin_dashboard.py`) shows/hides whole
  sections per role — a Support agent's admin homepage never even queries
  Credits/Instructors data, not just hides it in the template.
- Django admin superuser creation is idempotent from
  `DJANGO_SUPERUSER_EMAIL`/`DJANGO_SUPERUSER_PASSWORD` env vars
  (`apps/accounts/management/commands/ensure_superuser.py`, run on every
  deploy) — no hardcoded credentials anywhere in the codebase.

## Webhooks

The instructor-partner webhook (`apps/instructors/webhook.py`) uses a
real HMAC-SHA256 signature scheme, the same shape as Stripe/GitHub's own
webhooks: a per-partner secret (`PartnerCredential`, rotatable), a
timestamp header checked against a replay window
(`INSTRUCTOR_WEBHOOK_MAX_SKEW_SECONDS`), and a **constant-time** signature
comparison (`hmac.compare_digest`, not `==`, which would leak timing
information about how many leading bytes matched).

## Internal operations endpoint

`/internal/tasks/<name>/` (`apps/core/views.py`) exists because Render's
free-tier web service has no Shell tab and no one-off Jobs — it's the only
way to run a real management command against the deployed instance (e.g.
the daily guest-account prune). Gated by a token compared with
`hmac.compare_digest` against `TASK_TRIGGER_TOKEN` (never a plain `==`),
restricted to a fixed allowlist of real command names (`TRIGGERABLE_
COMMANDS` — an unknown name 404s, it can't run arbitrary commands), and
POST-only (a GET, e.g. a crawler following the URL, gets a 405).

## File uploads

- Paper/avatar uploads go through a presigned direct-to-storage PUT URL
  (`apps/papers/services.py`'s `presign_paper_upload`) rather than
  routing the file through Django — the storage key is always
  server-generated (never client-chosen) with a random UUID component, so
  nothing lets one contributor guess or overwrite another's file, and the
  serializer validates any incoming key against that exact pattern before
  accepting it.
- Per-exam-type maximum upload size is enforced server-side
  (`ExamType.max_upload_mb`), not just suggested in the UI copy.
- **Known gap**: there's no content-sniffing (magic-byte) validation
  beyond size and the client-declared `Content-Type` — a file renamed to
  claim a JPEG/PDF content type isn't independently verified server-side.
  Not fixed as part of this pass; flagged honestly rather than silently
  left undocumented.

## Payments

`apps/core/payment_provider.py`'s `MockPaymentProvider` is the only
payment backend wired up today — it always succeeds and moves no real
money. A real provider (Flutterwave is the named candidate in code
comments) implements the same `PaymentProvider` interface;
`PaymentResult.failure_reason` is documented as a curated string a real
integration must populate itself, not a place to forward a raw
provider-SDK exception — see "Error handling" below for why that
distinction matters everywhere else in this codebase already.

Pamphlet pickup uses a signed, expiring QR token
(`django.core.signing`, `QR_EXPIRY_DAYS = 30`, `apps/pamphlets/qr.py`),
held in escrow until release, with an explicit ownership check on
self-confirmation (`apps/pamphlets/escrow.py`) — a customer can't confirm
someone else's order's receipt.

## Error handling

Every domain-level exception a view might catch and show to a caller
(`PaperUnlockError`, `RedeemCodeError`, `EscrowError`, and ten others)
inherits `apps/core/exceptions.py`'s `SafeMessageError`, carrying an
explicit `.detail` string that's always a hardcoded, human-authored
message — never a wrapped system exception, stack trace, file path, or
SQL fragment. This was hardened 2026-09-02 after CodeQL flagged 15
"information exposure through an exception" findings; all 15 turned out
to be false positives (every one already only exposed a curated message),
but the fix — reading `.detail` instead of `str(exc)` — makes that
provably true instead of relying on someone reading each raise site by
hand, and resolves the findings for good rather than needing them
re-dismissed on every scan.

The same audit found a real instance of the underlying problem on the
Flutter side: several screens' error `SnackBar`s interpolated a caught
exception's raw `toString()` directly — for a network failure, that's a
`SocketException` whose text includes the backend's real hostname and
port. Fixed via `app/lib/data/api_client.dart`'s `apiErrorDetail`, which
only ever surfaces a backend's own safe `detail` field, falling back to a
generic translated message otherwise.

`DEBUG` defaults to `False` (`config.settings.base`) — only
`config.settings.dev`, used exclusively for local development, turns it
on. Staging/production never render Django's own debug traceback pages.

## Transport & CORS

- `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE` are
  all on in `config/settings/prod.py`.
- `CORS_ALLOW_ALL_ORIGINS = True` is deliberate, not an oversight: every
  authenticated request uses a JWT Bearer token, not a cookie, so a
  malicious site making a cross-origin request has no ambient credential
  to ride along with the browser the way classic cookie-based CSRF
  depends on — it would need the actual token value, which isn't
  something a different origin can read. Public read-only endpoints
  (categories, exam types, subjects) are meant to be broadly fetchable
  anyway. If a future feature ever adds cookie-based session auth for the
  API itself, this reasoning needs revisiting.

## Dependency & static analysis

- Dependabot is enabled for all three ecosystems in this repo
  (`.github/dependabot.yml`): pip (`backend/`), pub (`app/`), and GitHub
  Actions — weekly, and PRs get merged after the same CI + review this
  file's own changes go through.
- CodeQL (GitHub Advanced Security) runs on every push/PR across Python,
  JavaScript/TypeScript, and GitHub Actions.
- `ruff` lints the backend in CI; `flutter analyze` lints the app.

## Secrets management

- Never committed. Local dev reads `backend/.env` (gitignored) via
  `django-environ`; staging/production secrets live in Render's
  dashboard (Environment tab) — `render.yaml` deliberately marks every
  real secret `sync: false` so Render never tries to source a value for
  it from the repo.
- `DJANGO_SECRET_KEY` is Render-blueprint-generated
  (`generateValue: true`), never hardcoded.
- **Standing policy**: any credential pasted directly into a chat/terminal
  session (an API key, a token) is treated as compromised from that
  moment, regardless of who typed it or how quickly it's replaced —
  rotate it, don't just stop mentioning it.

## Known gaps, stated plainly

- **No WAF or edge rate-limiting layer in front of the API.** Render's
  free tier has no equivalent to Vercel's WAF or a CDN's edge filtering;
  the per-endpoint throttles above are enforced in the Django process
  itself (Redis-backed, see `CACHES["default"]`), which is real
  protection against scripted abuse but not against a large, distributed
  attacker the way an edge layer would be. Worth revisiting (e.g. putting
  Cloudflare in front of the Render domain) if real abuse traffic shows
  up — not preemptively built here since there's no evidence it's needed
  yet.
- **No file-content-type validation on uploads beyond size** (see "File
  uploads" above).
- **The real payment provider isn't integrated yet** — see "Payments"
  above. No real financial risk today since nothing charges real money,
  but the real provider's own error-handling hasn't been exercised.
- **Staging's Supabase Storage credentials may not be fully configured**
  in Render's dashboard — a real, previously-observed symptom (an
  uploaded avatar's URL 404s) traces back to this, not to a code bug. An
  operational gap, not a security one, but noted here since it's the kind
  of thing that looks like "uploads aren't working right" without an
  obvious cause.
