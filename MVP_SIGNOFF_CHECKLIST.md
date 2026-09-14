# Spekooh — MVP Sign-Off Checklist

One page, one purpose: turn "the MVP is tested" from a feeling into a
record. Every row is a real flow that exists in this codebase today — not
a generic template. Whoever tests a row initials it; a blank row means
untested, not "probably fine."

Test against `https://spekooh-staging.onrender.com` (or a local run —
see `RUNNING_LOCALLY.md`) with a real device where noted. Log any FAIL in
the Notes column with enough detail to reproduce, and don't check PASS
until a fix is verified, not just made.

---

## Accounts

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 1 | Register (email) | Sign up with a real email + password, accept Terms | ☐ | ☐ | | |
| 2 | Email verification | Confirm the 6-digit code sent at registration | ☐ | ☐ | | |
| 3 | Resend verification code | Request a fresh code; old one stops working | ☐ | ☐ | | |
| 4 | Login | Log out, log back in with the same credentials | ☐ | ☐ | | |
| 5 | Password reset | Request a code, confirm it, log in with the new password | ☐ | ☐ | | |
| 6 | Guest mode | Use the app without registering; submit as a guest | ☐ | ☐ | | |
| 7 | Guest → registered | A guest's referral code / prior activity carries over correctly after registering | ☐ | ☐ | | |
| 8 | Phone verification | Add a phone number in Profile, request + confirm an SMS code (needs a Twilio-verified test number — see `RENDER_PRODUCTION.md` §7) | ☐ | ☐ | | |
| 9 | Edit profile | Change name/education level/region/language; avatar upload | ☐ | ☐ | | |
| 10 | Referral bonus | Register with a real referral code, confirm the referrer is credited on the referred user's first real action | ☐ | ☐ | | |

## Papers & Reports

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 11 | Browse taxonomy | Navigate category → subject → year without a real submission yet | ☐ | ☐ | | |
| 12 | Submit a paper | Upload a real PDF, fill required fields, submit | ☐ | ☐ | | |
| 13 | Submit a report | Same, for the higher-tier academic report path (title/institution/discipline required) | ☐ | ☐ | | |
| 14 | Reject a bad upload | Submit a file with a wrong extension-vs-content (e.g. a `.txt` renamed `.pdf`) — must be rejected, not silently accepted | ☐ | ☐ | | |
| 15 | View a free paper | Open a published paper that doesn't require payment | ☐ | ☐ | | |
| 16 | Unlock a paid report | Pay (mock provider) to unlock a payment-gated report, confirm it's viewable after | ☐ | ☐ | | |
| 17 | OCR pipeline | A newly published submission gets real `ocr_text` within a few minutes (`process_pending_ocr`) | ☐ | ☐ | | |
| 18 | AI summary | Once OCR'd, request a real AI-generated summary for a paper | ☐ | ☐ | | |
| 19 | Per-paper AI chat | Ask the paper-specific chatbot a real question about its content | ☐ | ☐ | | |
| 20 | Flag a paper | Report a real submission, confirm it lands in the admin queue | ☐ | ☐ | | |
| 21 | Duplicate detection | Submit the same paper twice, confirm the duplicate is caught | ☐ | ☐ | | |
| 22 | Daily free-view limit | Confirm the free daily view cap actually triggers after the limit | ☐ | ☐ | | |

## Spekooh Assistant (general AI)

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 23 | Open the Assistant | Tap the gold sparkle FAB from any screen | ☐ | ☐ | | |
| 24 | Real conversation | Ask a real, non-paper-specific question; confirm a real (not canned) reply | ☐ | ☐ | | |
| 25 | Formatting renders correctly | A reply with bold/lists shows real formatting, not literal `**`/`-` characters | ☐ | ☐ | | |
| 26 | Accented/French text renders correctly | Ask a question in French, confirm no mojibake (garbled accented characters) | ☐ | ☐ | | |
| 27 | Daily quota | Confirm the free-message daily cap triggers and the upgrade prompt appears | ☐ | ☐ | | |

## Instructors (marking guides)

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 28 | Request routes to an instructor | A real marking-guide request reaches a real instructor via the webhook flow | ☐ | ☐ | | |
| 29 | Instructor accepts | A real acceptance response updates the request's state | ☐ | ☐ | | |
| 30 | Instructor rejects | A real rejection routes to the next instructor in queue, not a dead end | ☐ | ☐ | | |
| 31 | Marking guide delivered | A submitted guide merges and publishes correctly | ☐ | ☐ | | |
| 32 | Timeout handling | An instructor who doesn't respond in time is correctly reassigned (`process_instructor_timeouts`) | ☐ | ☐ | | |
| 33 | Appeal a rejection | The real appeal path for a rejected/disputed request | ☐ | ☐ | | |

## Payments & Credits

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 34 | Subscribe (Spekooh Plus) | Start a real subscription via the mock provider | ☐ | ☐ | | |
| 35 | First-unlock-free | A new user's first paper unlock is genuinely free | ☐ | ☐ | | |
| 36 | Credit ledger | Earn credits from a real contribution, confirm the balance updates | ☐ | ☐ | | |
| 37 | XP / redeem slot bonus | Earn XP, redeem the offline-slot bonus, confirm it actually applies | ☐ | ☐ | | |
| 38 | Failed payment | A deliberately-failed mock charge doesn't unlock anything and shows a real error | ☐ | ☐ | | |

## Pamphlets (physical goods)

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 39 | Browse the shop | View real partner bookshop pamphlets | ☐ | ☐ | | |
| 40 | Order a pamphlet | Place a real order end-to-end | ☐ | ☐ | | |
| 41 | QR pickup | Generate and (if possible) actually scan the pickup QR code | ☐ | ☐ | | |
| 42 | Courier self-confirm fallback | The 3-day self-confirm path when a courier doesn't confirm | ☐ | ☐ | | |
| 43 | Expiry | A 30-day-old unclaimed order flags correctly (`process_pamphlet_expiry`) | ☐ | ☐ | | |

## Forum, Quizzes, Notifications

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 44 | Post in the forum | Create a real post/reply | ☐ | ☐ | | |
| 45 | Take a quiz | Complete a real quiz, confirm XP is awarded | ☐ | ☐ | | |
| 46 | In-app notifications | A real domain event (e.g. paper approved) produces a real notification | ☐ | ☐ | | |
| 47 | Mark notifications read | Individually and "mark all read" | ☐ | ☐ | | |

## Admin & Moderation

| # | Flow | Steps | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 48 | Admin dashboard scoping | Log in as Reviewer/Support roles, confirm each sees only their own scoped sections | ☐ | ☐ | | |
| 49 | Resolve an admin queue ticket | Work a real flagged item to resolution | ☐ | ☐ | | |
| 50 | Error visibility | Deliberately trigger a real backend error, confirm it appears in Sentry within a minute | ☐ | ☐ | | |

---

## Load pass at realistic volume — done, 2026-09-14

Real run against live `spekooh-staging.onrender.com`, not a synthetic
local benchmark — a thread-pool script (`backend/scripts/load_test.py`)
hitting real endpoints with real concurrency. Goal per the release
roadmap's own P1 item: "not to find a ceiling, just to find the first
thing that falls over."

**No errors** — zero 5xx, zero connection failures, across every phase.
The app does not break under this load.

**It does queue, though — the real thing that "falls over" first:**

| Phase | Requests | Concurrency | p50 | p95 | max |
|---|---|---|---|---|---|
| Browse `/api/papers/categories/` (unthrottled, read-only) | 200 | 40 | 2.76s | 13.38s | 32.42s |
| Guest mint | 8 (per-IP throttle cap) | 8 | 2.65s | 2.81s | 2.81s |
| Register | 8 (per-IP throttle cap) | 8 | 15.49s | 21.99s | 21.99s |
| Login | 8 (per-IP throttle cap) | 8 | 14.53s | 19.70s | 19.70s |

Root cause: `WEB_CONCURRENCY=2` (2 gunicorn workers) on Render's free
tier, combined with bcrypt's deliberately expensive hashing on every
register/login — 8 concurrent requests to 2 workers queue almost
entirely serially, and each one is genuinely CPU-bound for real seconds.

**Note on scale honesty**: register/guest_mint/login are per-IP throttled
(10/hour, 10/hour, 20/hour — see `config/settings/base.py`). A single
sandbox machine can't simulate hundreds of concurrent *distinct users*
against those endpoints without just re-testing the throttle itself, not
real capacity — so those three phases intentionally stayed under each
endpoint's own cap. The unthrottled browse endpoint is the honest
volume signal here.

**Action taken**: `spekooh-production`'s `WEB_CONCURRENCY` raised from 2
to 4 in `render.yaml` (staging's stays at 2 — deliberately modest,
free-tier-appropriate, unchanged). Production is already on the paid
`starter` plan specifically for more headroom than free tier gives; this
makes it actually use that headroom rather than inheriting staging's
conservative default. Worth revisiting with real Sentry/latency data once
production has genuine traffic, rather than tuning further from one
synthetic run.

**To re-run**: `python backend/scripts/load_test.py [browse_n]
[concurrency]` (defaults: 200 requests at concurrency 40) from a machine
with network access to the target. Test accounts always use
`loadtest-<run-id>-*@example.com` — cleanable via the real
`/internal/tasks/delete-test-accounts/` endpoint with the real
`TASK_TRIGGER_TOKEN`.

---

## Sign-off

This MVP is considered tested and ready for the next release-roadmap
phase (see the Release Roadmap artifact) once every row above is either
checked PASS, or has a written, dated owner decision to defer it with a
reason — matching this same "decision, not silence" standard the
Release Roadmap and `SECURITY.md` already hold themselves to.

| Role | Name | Date | Signature/initials |
|---|---|---|---|
| Engineering | | | |
| Product owner | | | |
