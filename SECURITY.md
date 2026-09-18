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
- **Single-active-session enforcement (owner-reported, 2026-09-18)**: the
  reported gap was shared/stolen credentials letting a second device log
  in and quietly coexist with the real owner's session indefinitely,
  undetected. Every successful login, registration, and guest mint
  (`apps/accounts/services.py`'s `revoke_other_sessions`, called from
  `tokens_for_user` and `EmailTokenObtainPairSerializer.validate`) now
  blacklists every other outstanding refresh token for that account
  immediately — the real owner is signed out, and can tell something
  happened, the moment anyone else signs in, rather than both sessions
  silently coexisting forever. A real password reset
  (`PasswordResetConfirmSerializer.save`) revokes every session
  including the caller's own, since that's exactly the moment a
  compromised session should end too. The Flutter client
  (`app/lib/data/auth_session.dart`'s `_performRefresh`) detects the
  specific "Token is blacklisted" response, proactively logs itself out,
  and flags `RootShell` to explain why rather than surfacing a
  generic/unexplained 401. Access tokens (5-minute lifetime) aren't
  individually blacklistable, so a kicked-out device can keep making
  calls for up to 5 more minutes before its next refresh attempt is
  rejected — an accepted, bounded window, not an oversight.
  `apps/accounts/tests.py::test_a_second_login_revokes_the_first_devices_session`
  and friends prove this end-to-end.

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
- **Resolved 2026-09-14** (was a known gap): real magic-byte
  content-sniffing now runs on both upload paths
  (`apps/papers/validation.py` + `PaperSubmissionCreateSerializer
  .validate()`) — a file renamed to claim a PDF/JPEG/PNG extension it
  isn't is genuinely rejected, not just trusted by its declared
  `Content-Type`. The direct-to-storage path (Django never receives the
  bytes at upload time) is handled by a Range GET fetching just the first
  8 bytes from Supabase Storage after the client reports the upload
  done — a mismatched object is deleted immediately rather than left
  behind as an orphan. Avatars were already covered separately: `User
  .avatar` is a real Django `ImageField`, which does its own Pillow-based
  image validation on upload.

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

**Resolved 2026-09-17** (owner-reported: was a real gap) — the *partner*-
side redemption page (`/redeem/<token>/`, scanned by whoever's phone
reads the buyer's QR) used to release escrow off a single unauthenticated
button click. Anyone holding the scanning phone — not necessarily the
registered partner — could confirm a handover that never happened. It
now requires a real one-time code, sent to the partner's own registered
email or phone (never the buyer's), before `redeem_qr` is allowed to run
(`RedeemVerification`, `apps/pamphlets/escrow.py`'s
`start_redeem_verification`/`confirm_redeem_verification`) — same OTP
shape (TTL + independent attempt cap) as `PasswordResetCode`/
`EmailVerificationCode`, scoped per-order so a code sent for one
redemption can't be reused on another. The phone channel is anchored to
`PartnerBookshop.verification_phone` (Orange Money, falling back to
MoMo) rather than the general `contact_phone`, specifically because
Cameroonian mobile-money SIMs are ID-linked at registration by the
carriers — a real accountability anchor a shared shop landline number
isn't. Partner onboarding (`PartnerBookshopAdmin`) now requires a real
full name, email, CNI, and NUI, and at least one of Orange Money/MoMo,
so this identity check has real data to work with for every partner
going forward. CNI/NUI are now real uploaded documents
(`PartnerBookshop.cni_document`/`nui_document`), not just typed-in
numbers — the number fields alone can't actually be verified against
anything.

**Added 2026-09-17** — a support-override escape hatch for the same flow:
if a partner genuinely can't receive either the email or SMS code (a real
carrier/network issue) and calls support, Integration Ops staff can
generate a fresh code for that exact order and read it to them over the
phone (`PamphletOrderAdmin.generate_support_code`,
`apps/pamphlets/escrow.py`'s `generate_support_override_code`). This is
never self-service — the redeem page's channel-selection step explicitly
rejects `SUPPORT` as a chosen value even though it's a real
`RedeemVerificationChannel`, and the admin action itself re-checks group
membership (`request.user.is_superuser or ...groups.filter(name="Integration
Ops")`) at call time rather than relying on Django's action-visibility
gating alone, consistent with how every other security-sensitive custom
admin action in this codebase is gated. The code is deliberately
shorter-lived than the normal 10 minutes (`SUPPORT_TTL_MINUTES = 3`)
since it's relayed by a human who hasn't proven control of a registered
channel the way the email/SMS codes do, and it's checked independent of
the redeeming browser's session (so it still works if the partner is
now on a different device/browser than the one that started the original
flow). `RedeemVerification` is registered read-only in admin for audit
visibility into every code ever issued for an order, including who
issued a support override.

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
- **Standing rotation cadence (added 2026-09-18)**: this was previously
  reactive only — an AWS key, a database password, `DJANGO_SECRET_KEY`,
  a task token, and the Spekooh↔S@Learn webhook secret were each rotated
  this project only after a real trigger (a leak, or a sandbox reset
  wiping a local copy). Every credential now gets rotated on a real
  schedule instead of waiting for one of those triggers:
  - **Every 90 days**: `DJANGO_SECRET_KEY`, the Spekooh↔S@Learn webhook
    shared secret, `EMAIL_VERIFY_SHARED_SECRET`, any long-lived API key
    (Twilio, storage provider, payment provider once real).
  - **Every 180 days, or immediately on team-member offboarding**:
    database password, Render/hosting-provider account credentials.
  - **Immediately, every time, regardless of schedule**: anything pasted
    into a chat/terminal session (see the standing policy above), or
    anything the app-signing keystore/store password itself would fall
    under if it could be rotated at all (it can't — see "App signing"
    below, which is why that one is backed up instead of rotated).
  - Owner is responsible for actually running this cadence today — no
    automated reminder exists yet; adding one (a scheduled check, or a
    calendar-based process) is itself a fair TODOS.md item once this
    cadence has been followed manually at least once.

## App signing

- Android release builds sign with a single, persistent keystore
  (`app/android/keystore/upload-keystore.jks`) via one `signingConfig`
  (`app/android/app/build.gradle.kts`), git-ignored (`app/android/
  .gitignore`) — never committed, same as any other secret. Falls back to
  debug signing automatically when `key.properties` isn't present (e.g. a
  fresh clone, or CI), so a real release keystore is opt-in per machine,
  not required just to build.
- **Critical, and currently unmitigated**: this keystore file is the
  app's permanent signing identity. If the machine holding it is ever
  lost or reset without a backup, no future release build can ever be
  installed as an *update* to an existing install signed with the
  original key again (Android treats a signature mismatch as a different
  app) — on Google Play specifically, it would permanently block
  publishing further updates to the existing listing at all. **Action
  needed, not yet done**: back up `upload-keystore.jks` plus its store/key
  passwords (from `key.properties`) to the owner's password manager or
  equivalent secure storage outside this machine — never to the repo,
  never pasted into chat.

## Known gaps, stated plainly

- **No WAF or edge rate-limiting layer in front of the API.** Render's
  free tier has no equivalent to Vercel's WAF or a CDN's edge filtering;
  the per-endpoint throttles above are enforced in the Django process
  itself (Redis-backed, see `CACHES["default"]`), which is real
  protection against scripted abuse but not against a large, distributed
  attacker the way an edge layer would be.
  **Decision (2026-09-14, MVP exit-criteria security sign-off): fix
  before launch**, not accepted as a v1 gap — Cloudflare in front of the
  Render domain. Blocked on a real prerequisite that isn't in place yet:
  Cloudflare's proxy/WAF needs a domain the owner controls pointed at
  it — an `onrender.com` subdomain can't be proxied since Render owns
  that domain, not this project. No custom domain is registered yet, so
  the actual next step is registering one (e.g. `spekooh.app`), not a
  Cloudflare config step.
- **Resolved 2026-09-14** (was: no file-content-type validation on
  uploads beyond size) — see "File uploads" above. **Extended
  2026-09-18**: the 2026-09-14 fix only covered the papers/avatar
  upload path. Three admin-only upload fields added 2026-09-17
  (`Note.pdf_file`, `PartnerBookshop.cni_document`/`nui_document`) went
  in without it — a gap this session's own review caught rather than a
  new incident. Same magic-byte check now runs on all three
  (`apps/papers/validation.py`'s `validate_pdf_file_content`/
  `validate_document_file_content`, wired as model-field validators).
- **Decided, not built: self-service account deletion (2026-09-18).**
  The Privacy Policy promises deletion on request, fulfilled today by a
  manual, email-a-human process — fine at current scale (tens of users),
  a real support cost once that volume grows. Deliberately not built now
  rather than left as a silent scaling problem: revisit when the account
  base crosses roughly 200 registered users, or actual deletion-request
  volume exceeds about 2/week, whichever comes first — either signal
  means the manual process has started costing real time. Owner decides
  when to schedule the actual build once triggered.
- **The real payment provider isn't integrated yet** — see "Payments"
  above. No real financial risk today since nothing charges real money,
  but the real provider's own error-handling hasn't been exercised.
  **Decision (2026-09-15, MVP exit-criteria security sign-off): fix
  before launch**, not accepted as a v1 gap — already tracked as a P0
  blocker on the release roadmap. Blocked on a real prerequisite that
  isn't in place yet: the owner's own MTN Mobile Money / Orange Money
  (or Flutterwave/Notch Pay) merchant registration — not an engineering
  task until those credentials exist.
- **Resolved 2026-09-13** (was: zero server-side error visibility on
  staging) — a real Sentry project and Django's own independent `ADMINS`
  email-alert channel are both live; see the release roadmap for the
  full verification. Historical note, unchanged: found the hard way
  (2026-09-02), three real infra misconfigurations (missing `REDIS_URL`,
  missing `AWS_STORAGE_BUCKET_NAME`, wrong `AWS_S3_REGION_NAME`) were
  causing live 500s with no way to see why — diagnosing them required a
  temporary, deliberate code change to bypass `DEBUG=False` for one
  request, which is not a sustainable way to debug production.
