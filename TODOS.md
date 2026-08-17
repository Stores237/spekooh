# Spekooh — Remaining Functionality To Live-Implement

Generated after a full audit of the Flutter app against the real Django backend and
`uploads/spekooh_scope.md`. Priority tiers (P0/P1/P2) match the scope doc's own framework
(§3.1–3.3) so this list stays consistent with product intent, not just engineering convenience.
Within each tier, items are ordered most-impactful first.

Legend: **Backend** = does a real Django endpoint/model exist · **Client** = does the Flutter
app actually call it for real (not a mock, not a dead tap, not fabricated display data).

---

## Owner action items — not engineering work, blocks engineering work

Everything below needs an account, real content, a decision, or a person — none of it is code
I can write unilaterally. Grouped by what each one unblocks.

### Accounts & credentials to set up
- **Real payment provider**: the backend runs on `MockPaymentProvider` (explicitly a stand-in,
  documented as such in the code) for subscriptions, marking-guide unlocks, and pamphlet
  payments. Going live needs a real MTN MoMo / Orange Money merchant integration, or an
  aggregator (Flutterwave, Notch Pay) that bundles both — business registration + API keys.
- **File/media storage**: uploaded papers currently save to local disk on the dev server
  (documented as a placeholder for Supabase Storage). Production needs a real Supabase Storage
  bucket or S3-compatible bucket with credentials.
- **Firebase project** — only if real push notifications are wanted (current notifications are
  in-app only, which may be enough for v1 per spec).
- **App store accounts** — Apple Developer + Google Play Console, once a build is ready to ship.

### Content only the owner can provide
- **Real papers to seed the app**: the papers database is genuinely empty right now
  (`getLatestPublished()` correctly shows "no papers yet"). The app won't feel real until actual
  exam papers are submitted and pushed to `PUBLISHED` — via the Django admin, or real users.
- **Academic Reports taxonomy**: the "reports" category exists with zero exam-type rows and no
  discipline/institution fields — the field shape (internship? mémoire? thèse? by what
  institution?) needs a decision before this can be built for real instead of "coming soon."
- **French translations**: the biggest P0 gap (bilingual UI, below) needs real French copy for
  every string in the app. A first draft can be AI-assisted, but a native-speaker review for the
  Cameroon market should happen before shipping.
- **Support destinations**: a real WhatsApp group link, support contact, and live website URL —
  Settings currently has five dead links because none of these exist yet to point at.
- **Privacy policy / terms content** — legal text, not something that should be drafted as if real.

### People/ops
- **Instructor recruitment**: the marking-guide pipeline (accept/reject, 7-day deadline, credits)
  is fully built and tested, but inert without real instructors onboarded to receive requests.
- **A review team**: someone needs to actually use the admin queue to trigger OCR/duplicate-check
  and `mark_published` on submissions — a manual admin action by design.

### Decisions still open
- **Offline downloads platform target** (blocks P1 #4 below): mobile-only (standard
  `path_provider` approach) or web too (needs browser storage, a different implementation)?
- **Marking-guide subscription tier** (P2 #9 below): still wanted, or does pay-per-unlock stay
  the only path?

---

## P0 — Must-have, confirmed in scope, still not fully live

### 1. Bilingual UI (English + French) — infrastructure done, string coverage in progress
- **Register/tone decision (researched, not guessed):** standard/formal French, not Camfranglais
  (the Douala/Yaoundé youth slang blend) — Cameroonian educators actively discourage Camfranglais
  as undermining real French acquisition, and real local apps in this space (Orange Money) use
  plain standard French, not invented "local" phrasing. Education vocabulary already in the
  taxonomy (BEPC, Probatoire, Mémoire de Licence, Rattrapage, etc.) already gets the real
  Cameroonian terms right — new UI copy extends that same register.
- **Adaptive locale (done):** `LocaleController` (`app/lib/data/locale_controller.dart`) resolves,
  in order: an explicit choice already made on this device → that account's own
  `language_pref` synced in from another device (only if this device has no explicit choice of
  its own yet) → the device's system locale, clamped to {en, fr} (anything else defaults to
  English). `Settings`' language rows now call it for real — no more local dead `bool`.
  `User.language_pref` now actually gets read (`RegisterSerializer`/login response) and written
  (`PATCH /auth/me/` via a new `ProfileRepository.setLanguagePreference`), closing the
  previously-dead backend field.
- **Client wiring (done):** `flutter_localizations` + `intl` + ARB codegen
  (`app/lib/l10n/app_{en,fr}.arb` → generated `AppLocalizations`), `MaterialApp.locale` reactive
  to `LocaleController` via a `ListenableBuilder` in `main.dart`.
- **String coverage (in progress, screen-by-screen to keep each diff verifiable):** done —
  bottom nav labels, Settings screen, the auth (login/register) sheet including its error
  messages. Still hardcoded English — every other screen (Home, Papers, Submit, Forum, Quizzes,
  Profile, Shop, Notes, Notifications, and the sheets/dialogs within them).
- **Why P0:** spec §3.1 lists this as must-have "from launch, not a future add-on."

### 2. ~~Rewarded-ad unlock~~ — done
- Live: `google_mobile_ads` integrated (real AdMob App ID + rewarded-video ad unit); "Watch ad
  for +1 view" button re-surfaced on `PaperDetailScreen` once the daily free-view paywall blocks
  a paper. A real reward (`onUserEarnedReward`, not just closing the ad) calls
  `POST /papers/ad-watch/` and then retries the blocked view. Debug builds request Google's
  public test unit instead of the real one (AdMob policy — developer-triggered real-unit
  impressions count as invalid traffic). Mobile-only: `google_mobile_ads` has no web support, so
  the button doesn't render on the `flutter build web` dev target (`kIsWeb` gate), which is
  consistent with spec §6 ("no web app in v1").
- A debug APK now builds cleanly and was sideloaded to a real device (no emulator available in
  this sandbox). Getting there required two real, unrelated build fixes now committed
  separately: `file_picker` bumped `8.1.2` → `11.0.3` (compileSdk 36 requirement pulled in
  transitively by `google_mobile_ads`) and AGP pinned `9.0.1` → `8.13.2` (9.0.1 broke several
  plugins' legacy Kotlin application mid-transition).
- Still not verified end-to-end: the debug build's `API_BASE_URL` defaults to `10.0.2.2:8000`,
  an Android-*emulator*-only loopback alias that a real phone can't reach — so on-device, the
  daily view-limit paywall (and therefore the "Watch ad" button, gated behind it) has no working
  backend to trigger against yet. Confirming an actual ad renders on-device needs a rebuild
  pointed at a real reachable backend address, or the same network + port setup.

### 3. ~~Flag/report an existing paper~~ — done
- **Backend:** `PaperFlag` model (`apps/papers/models.py`) — one flag per user per paper
  (`unique_flag_per_user_per_paper`), 6 reasons (wrong answers, poor quality, wrong subject,
  duplicate, copyright, other). `report_paper()` service creates the flag row and a
  `PAPER_REPORTED` ticket in the same §2.1 `AdminFlagQueue`, matching every other
  auto-created ticket. New `POST /api/papers/submissions/{id}/report/` action — 401 if
  logged out, 404 if the paper isn't visible to this user (same visibility rules as
  everywhere else), 409 on a second report from the same user.
- **Client:** flag icon in `paper_detail_screen.dart`'s header opens a real dialog (reason
  dropdown + optional details), calls the endpoint, shows a real success/already-reported
  message — not a mock.
- Tests: 4 new backend tests (auth required, creates flag+ticket, duplicate conflicts,
  different users both succeed), 3 new Flutter widget tests (submit, cancel,
  already-reported message).

---

## P1 — Nice-to-have, confirmed in scope, not built

### 4. Offline-saved papers for later access
- **Backend:** N/A (inherently client-side).
- **Client:** not built. Explicitly scoped out of the Home-screen fix earlier this session (the
  fabricated "Ready offline — Downloads · 1" section was removed rather than faked) because
  this app is only tested via `flutter build web`, and the standard mobile approach
  (`path_provider` + local file writes) doesn't work in a browser.
- **Needs a platform decision first:** if Spekooh ships mobile, use `path_provider`; if web
  matters too, a real implementation needs browser storage (IndexedDB/Cache API) via a
  conditional/platform-specific implementation. Don't build either until that's decided — see
  spec §6 ("No web app in v1 (mobile-first)"), which suggests the mobile path is the real target
  and this Flutter Web testing setup is a dev-environment convenience, not the ship target.

### 5. ~~Referral bonuses~~ — done
- Spec only listed this as a one-liner with no mechanics, so the trigger and reward were
  decided with the owner before building (not invented): **trigger** = referred user's first
  real action (their first paper unlock, not bare signup — resists fake-account abuse);
  **reward** = a flat credit-ledger amount, same `CreditLedgerEntry` mechanism as the
  contributor bonus.
- **Backend:** `User.referral_code` (auto-generated, unique), `referred_by` (self FK, set at
  registration via an optional `referral_code` field on `RegisterSerializer` — 400 if the code
  doesn't exist), `referral_bonus_awarded_at` (idempotency guard). New
  `ReferralBonusConfig` singleton (default 200 credits, admin-configurable like
  `ContributorBonusConfig`). `award_referral_bonus()` fires from
  `apps.payments.services.unlock_paper()` on both the free-trial and paid branches — the
  guard means it only actually credits once, on whichever unlock happens first.
  `UserSerializer` exposes `referral_code` so the client can display it.
- **Client:** an optional "Referral code" field on the registration sheet; Profile shows a
  real "Invite a friend" card (own code + real `share_plus` share action), matching the
  existing redeem-code share pattern.
- Tests: 3 new credits-service tests (fires once, no-op without a referrer, no-op on repeat),
  2 new payments tests (end-to-end via `unlock_paper`, doesn't double-fire), 3 new accounts
  tests (code returned on register, valid code sets `referred_by`, invalid code 400s), 2 new
  Flutter widget tests (code included when given, omitted — not sent empty — when not), plus
  the existing Profile smoke test updated for the second real "Share" action now on the page.

---

## P2 — Explicitly future/speculative in spec, or invented UI with no spec backing at all

### 6. In-app practice quiz auto-generated from submitted papers ("Past-paper practice")
- **Backend:** not built — no paper→quiz generation pipeline; `Quiz`/`QuizQuestion` are
  manually authored rows only.
- **Client:** shown honestly as "coming soon" (fixed this session — previously opened a
  hardcoded fake quiz regardless of what was tapped).
- Matches spec §3.3 P2 exactly ("in-app practice/quiz mode generated from paper content").

### 7. "Friday Arena" live elimination quiz
- **Backend:** not built — no live/scheduled quiz-session model, no real-time transport.
- **Client:** shown honestly as "coming soon" (fixed this session — previously a dead tap).
- **Not in the confirmed spec at all** — pure UI-mockup invention (closest real-world analogue
  is Kawlo's "live 1v1 quiz battles," which the spec itself flags in §12.4 as a P2 idea worth
  revisiting post-MVP, not committed scope). Lowest priority on this whole list.

### 8. Quiz anti-cheat / answer-hiding
- **Backend:** `correct_choice_index` is stripped from the list/detail serializer response
  (confirmed not sent to the client) but there's no protection against a user inspecting network
  traffic before answering, since the full grading logic still lives client-adjacent in spirit.
  Documented as a known, accepted gap in `apps/quizzes/models.py`'s own docstring — quizzes are
  P2/non-spec'd, so this was a deliberate corner-cut, not an oversight.

### 9. Subscription tier for marking-guide access
- Distinct from the already-real "Spekooh Pro" (ad-free + unlimited paper *views*, per §5.3 —
  confirmed to explicitly exclude marking guides). This P2 item is a *different*, not-yet-decided
  product idea (bundling marking-guide access into a subscription) — not started, and shouldn't
  be until product decides whether pay-per-unlock stays the only marking-guide monetization path.

---

## Not in the spec at all, and correctly left alone

These are decorative gaps found during this session's audit. Each was deliberately left
unfixed because "fixing" them for real would mean fabricating something that doesn't exist yet
(a support inbox, a WhatsApp group, a public website), which is exactly the dishonesty this
whole pass was hunting:

- **Settings → Help & support / WhatsApp group / Contact us / Website / Privacy policy**: five
  dead links with no real destination URL. Needs the business to actually stand up a support
  channel, WhatsApp group, and public site before these can be wired to `url_launcher` (already
  in the app) instead of guessed-at placeholder URLs.
- **Forum header search icon and notification bell**: purely decorative, no `onTap`. Forum
  already has a working list; wiring real search would need a `?search=` query param the backend
  doesn't currently expose on `/forum/posts/`.
- **Forum's "My subjects" and "Solved" filter chips**: found this pass — all four filter chips
  visually highlighted on tap but never filtered anything; fixed "All" and "Unanswered" for real
  (client-side, no backend change needed), but "My subjects" (no per-user subject-preference
  field anywhere) and "Solved" (no resolved flag on `ForumPost`) now show an honest "not
  available yet" state rather than silently doing nothing under a tab that implies they work.

---

## Already fully real (for context — not on this TODO)

Papers (browse/detail/submit), Home (guest + logged-in), quiz streaks, the 7-day new-account
trial + first-unlock-free perk, the Pro subscription paywall, Forum (ask/reply/upvote/filter),
Notes, Notifications, Shop/pamphlets (including the escrow+QR pickup flow), Profile (including
the redeem-code share action), and the daily quiz challenge + leaderboard. The Django admin has
also been redesigned with the real brand theme and a live ops dashboard (papers pipeline,
admin-queue, instructor/withdrawal queues, credits, payments) — see the `feat: redesign the
Django admin` commit.
