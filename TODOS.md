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
- ~~**File/media storage**~~ — done. Real Supabase Storage bucket (`spekooh-media`, S3-compatible
  API) is configured via `AWS_*` env vars in `.env` and verified live (round-tripped a real
  save/exists/signed-url/delete against it, 2026-08-23) — this is what the watermarking and
  report-viewer work earlier this session was already tested against. `STORAGES` in
  `config/settings/base.py` falls back to local disk only when `AWS_STORAGE_BUCKET_NAME` is
  unset, so a fresh clone without these credentials still works out of the box.
- **Firebase project** — only if real push notifications are wanted (current notifications are
  in-app only, which may be enough for v1 per spec).
- **App store accounts** — Apple Developer + Google Play Console, once a build is ready to ship.
- **Sentry DSN** (2026-08-26): `sentry-sdk` is fully wired in `config/settings/base.py`
  (Django integration, `send_default_pii=False` — consistent with the admin PII-redaction work),
  but with no `SENTRY_DSN` set it has no transport and never makes a network call, so a fresh
  clone still works out of the box. Create a Sentry project and set `SENTRY_DSN` to start
  actually receiving error reports — right now a production exception's first sign of life is
  someone reporting it.
- **Managed Redis for production** (2026-08-26): `CACHES` now points at Redis (local
  `rediscache://localhost:6379/0` by default, same fallback pattern as `DATABASE_URL`) — it
  backs the new guest-mint rate limit (`apps.accounts.views.GuestView`, 10/hour per IP; see
  `apps.accounts.tests.test_guest_endpoint_is_rate_limited_per_ip`). Dev/CI use a real local/
  containerized Redis; production needs a real managed instance (Upstash, Redis Cloud, etc.) —
  set `REDIS_URL` to switch, no code change either way.
- **Real email provider for password-reset codes** (2026-08-27): the "forgot password" flow
  (backend `apps.accounts.views.PasswordResetRequestView`/`PasswordResetConfirmView`, app
  `PasswordResetSheet`) is fully real end-to-end — verified against the live local backend,
  including logging in with the actually-changed password afterward — but `EMAIL_BACKEND` is
  Django's console backend (`config/settings/dev.py`), so a reset code currently prints to the
  server's own console/log instead of reaching the user's inbox. `base.py` has no `EMAIL_BACKEND`
  override, so as-is `prod.py` would fall through to Django's default SMTP backend and fail
  outright without real settings. Needs a real provider (SendGrid, Postmark, SES, or plain SMTP)
  and its credentials — then set `EMAIL_BACKEND`/`EMAIL_HOST`/etc. (or `DEFAULT_FROM_EMAIL` if
  just the sender address changes) via env vars, no code change.
- ~~**Supabase Edge Function for registration email verification**~~ — done (2026-08-27). A real
  Deno edge function (`backend/supabase/functions/verify-email-domain`) is deployed to the
  project's actual Supabase instance and checks a registration email's domain has real MX
  records (catches typo'd domains like `gmial.com`), gated by a shared-secret header
  (`EMAIL_VERIFY_SHARED_SECRET`, set both as a Supabase secret and in `backend/.env`). Wired into
  `RegisterSerializer.validate_email` via `apps.accounts.services.email_domain_is_verifiable`,
  which fails *open* (lets registration through) if the function isn't configured or is
  unreachable — a third-party outage shouldn't block every signup. Verified live end-to-end: a
  real `curl` to the deployed function URL, then a real registration attempt against the local
  backend with a typo'd domain (rejected) and a real one (accepted). This checks domain
  deliverability only, not that a specific mailbox exists.
- ~~**Actual "confirm your email" verification code**~~ — done (2026-08-27). The domain check
  above answered "is this email real," but nothing asked the new user to actually confirm it —
  registering just worked instantly with no visible verification step at all. `RegisterView` now
  issues a real `EmailVerificationCode` (same OTP shape as password reset — 6-digit,
  `secrets.randbelow`, 30-min expiry, 5-attempt cap) and emails it as part of the same request;
  the app opens `EmailVerificationSheet` right after a successful registration if the account
  isn't verified yet. `POST /api/auth/verify-email/` (confirm) and `.../resend/` are both
  authenticated (registration already grants tokens, so there's no account-enumeration surface
  to design around here, unlike password reset). Confirming does **not** gate login/access —
  `User.email_verified_at` is a signal surfaced in the app, not an access-control mechanism —
  deliberately, since forcing it would strand every real signup until a real email provider is
  wired up (see the item above; still console-only). "Skip for now" in the sheet reflects that:
  either outcome leaves the user logged in exactly the same. Verified end-to-end against the
  real local backend: registered, pulled the real code from the `EmailVerificationCode` row,
  confirmed a wrong code (rejected) then the real one (accepted, `email_verified` flips true),
  confirmed the console-logged email is real and well-formed, cleaned up the test user.
- ~~**Gate account access behind email verification**~~ — done (2026-08-27), conditionally. Owner
  ask: "only after the verification is done that the user can access the account." New
  `REQUIRE_EMAIL_VERIFICATION` setting (env var, **default False**) — when flipped on,
  `EmailTokenObtainPairSerializer` refuses login for a registered account with no
  `email_verified_at` (`{"code": ["email_not_verified"]}`, a stable key the app matches on).
  Deliberately never gates the *initial* tokens registration itself grants (needed so
  `EmailVerificationSheet` can confirm in that same session) — only a *later* login. Default
  stays False because there's still no real email provider wired up (see the two items above) —
  flipping it on today would strand every real signup with no way to ever receive a code. Also
  added the recovery path a hard gate needs to not be a dead end: a user who skipped verifying,
  lost that session, and comes back to a blocked login has no authenticated session left to call
  the resend endpoint with — `POST /api/auth/verify-email/request-by-email/` and
  `.../confirm-by-email/` (both unauthenticated, both non-revealing about account state, same
  posture as password reset) close that loop. The app's login form shows the specific
  "verify your email" error and an inline code-entry recovery block automatically (no dead-end
  generic error). Verified end-to-end against the real local backend with the flag flipped on:
  registered, confirmed login is genuinely blocked, requested a fresh code by email, confirmed
  it, confirmed login then succeeds — cleaned up the test user.
- ~~**"Change password" reachable while logged in**~~ — done (2026-08-27). The only path to
  `PasswordResetSheet` was `AuthSheet`'s "Forgot password?" link, which only shows while logged
  *out* — a logged-in user had no way to change their password at all. Settings now has an
  "Account" section with a "Change password" row (shown only when logged in) that opens the same
  sheet — it re-verifies via an emailed code either way, so "forgot" and "want to change" are the
  same flow.
- ~~**Profile picture upload**~~ — done (2026-08-27). The avatar circle on Profile was a plain
  initial-letter placeholder with no `onTap` at all. `User.avatar` (ImageField, same Supabase
  Storage backend as paper scans) + `avatar_url` on `UserSerializer`; `PATCH /api/auth/me/` now
  accepts multipart to set/replace it (`ApiClient.postMultipart` gained a `method` param so PATCH
  multipart is possible, not just POST). Tapping the avatar offers "Take a photo"/"Choose from
  gallery" (same `image_picker` already used in Submit), uploads, and swaps in the real photo
  immediately. Verified end-to-end against the real local backend: registered, uploaded a real
  PNG via multipart PATCH, got back a real signed Supabase Storage URL, fetched that URL directly
  and confirmed it serves the actual image (`content-type: image/png`) — cleaned up the test user
  and the orphaned test files the earlier pytest run had left in the real bucket (transaction
  rollback undoes the DB row but not an S3 write — a pre-existing trait of this test suite's
  file-upload tests generally, not something new here).

### Content only the owner can provide
- **Real papers to seed the app**: the papers database is genuinely empty right now
  (`getLatestPublished()` correctly shows "no papers yet"). The app won't feel real until actual
  exam papers are submitted and pushed to `PUBLISHED` — via the Django admin, or real users.
- **French translations**: the biggest P0 gap (bilingual UI, below) needs real French copy for
  every string in the app. A first draft can be AI-assisted, but a native-speaker review for the
  Cameroon market should happen before shipping.
- ~~**Support destinations**~~ — mostly done (2026-08-23, owner-provided). "Help & support" now
  calls `+237659802679`, "WhatsApp support" opens a chat on the same number (`wa.me`) — there
  was never a real WhatsApp *group*, so the row was honestly retitled from "Join our WhatsApp
  group" rather than pointing a group-shaped label at a 1:1 chat — and "Contact us" opens
  `mailto:storefix237@gmail.com`. Still open: **live website URL** (owner confirmed not ready
  yet — "Visit our website" now shows an honest "Not available yet" instead of the previously
  fabricated `spekooh.app` subtitle) and **Privacy policy** (still a fully dead link, no content
  provided).
- **Privacy policy / terms content** — legal text, not something that should be drafted as if real.

### People/ops
- **Instructor recruitment**: the marking-guide pipeline (accept/reject, 7-day deadline, credits)
  is fully built and tested, but inert without real instructors onboarded to receive requests.
- **A review team**: someone needs to actually use the admin queue to trigger OCR/duplicate-check
  and `mark_published` on submissions — a manual admin action by design.

### Decisions still open
- **Marking-guide subscription tier** (P2 #11 below): still wanted, or does pay-per-unlock stay
  the only path?

---

## P0 — Must-have, confirmed in scope, still not fully live

### 1. ~~Bilingual UI (English + French)~~ — done
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
  messages, Home (both the guest and logged-in variants — greeting-by-time-of-day correctly
  collapses "Good morning"/"Good afternoon" to the single "Bonjour" French uses for both,
  distinct from "Bonsoir" in the evening, not a naive 3-way 1:1 mapping), Papers (the full
  category → system → exam-type → track → subject → paper-list drill-down) and Submit (the
  real exam-paper upload flow + the "Academic report" honest not-available state), Forum
  (post list/filters, post detail + replies, the "Ask the forum" sheet), Quizzes (daily
  challenge, practice modes, the coming-soon rows, leaderboard, quiz detail/scoring), Profile
  (credit balance, redeem-code + referral-code share cards, badges, submission status), and
  Shop (pamphlet list/search). Real exam names (BEPC, Probatoire, O Level, etc.) and the
  Francophone/Anglophone system labels are deliberately left untranslated — they're the actual
  proper names of those systems/exams in either language, not generic UI chrome. Found and
  fixed one real layout bug while translating Shop: the header title+subtitle Column wasn't
  wrapped in `Expanded`, so the longer French subtitle overflowed the Row — same class of
  fixed-width assumption a wider EN string could hit too, not French-specific (applied the same
  proactive `Expanded` fix to Notes' and Notifications' matching header pattern while there).
  Notes and Notifications, PaperDetailScreen (unlock/view/report flows, not just the report
  dialog), and the Paywall + Pamphlet-purchase sheets. Every hardcoded English literal in the
  app's real screens/sheets has an ARB key now — full coverage, not partial.
- **Real UI-layer exceptions carry no message (fixed while doing this pass):**
  `PaywallException`/`AlreadyReportedException` used to hardcode English text in the data layer
  and get displayed as-is; each has exactly one cause, so they're now parameterless marker
  classes and the widget supplies the localized string at the catch site — the data layer no
  longer bakes in a language. Dynamic/backend-echoed error text (e.g. `SubscriptionError`,
  which interpolates the real HTTP response body) intentionally stays English-only — that's
  genuinely variable content, not a fixed UI string to translate.
- **Why P0:** spec §3.1 lists this as must-have "from launch, not a future add-on."
- **What's NOT covered by design, not oversight:** real backend-driven content (post/quiz/
  paper titles, exam names like BEPC/O Level, notification bodies) — these are data, and Subject
  already has its own `language` field for bilingual *content* independent of UI chrome.
  Camfranglais slang was deliberately avoided (see the register note above) — this is standard
  French throughout, matching how real Cameroonian apps in this space (Orange Money) present.

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

### 4. ~~Offline-saved papers for later access~~ — done
- **Platform decision (made by the owner):** mobile-only, via `path_provider` — matches spec §6
  ("no web app in v1"); no browser-storage fallback was built.
- **Backend:** N/A (inherently client-side) — downloads the same signed file URL
  `PaperDetailScreen` already uses to open a paper (`PaperEntry.fileUrl`).
- **Client:** `OfflinePapersStore` (`app/lib/data/offline_papers_store.dart`) downloads a
  paper's real scanned file to on-device storage and keeps a small on-device JSON index so
  saved papers survive app restarts. Storage is behind an `OfflineFileStore` seam
  (`app/lib/data/offline_file_store.dart`) — `LocalOfflineFileStore` is the real
  `path_provider`-backed implementation, `InMemoryOfflineFileStore` lets tests run without
  touching real device storage or the network. `PaperDetailScreen` gets a real "Save
  offline"/"Saved offline" toggle (mobile-only, next to "Open scanned paper") and now prefers
  the local copy over re-fetching the remote URL once one exists — the actual point of saving
  for later. `LoggedInHomeScreen`'s "Ready offline" section (previously fabricated, then
  removed rather than faked) is now real: only appears once something's actually saved, shows
  the true download count, and opens the local file via `open_filex` (added alongside
  `path_provider` — `url_launcher`, already a dependency, explicitly isn't recommended for
  local `file://` URIs on Android per its own docs).
- Verified with a real debug APK build (`flutter build apk --debug`), not just `flutter
  analyze`/tests — confirms the two new native plugins integrate cleanly into the actual
  Android build, not just the Dart layer.
- Tests: 9 new `OfflinePapersStore` unit tests (save/remove/overwrite/persistence-across-
  bootstrap/failed-download/listener notifications), 3 new `PaperDetailScreen` widget tests
  (toggle save/remove, failed download surfaces a real error), 2 new `LoggedInHomeScreen`
  widget tests (section absent when empty, present with real data — EN + FR).

### 5. ~~Academic Reports contribution page~~ — done
- Previously blocked on a real decision (no spec guidance existed at all — the field shape
  wasn't invented): **type + institution + discipline**, with supervisor genuinely optional —
  decided with the owner before building.
- **Backend:** the "reports" `ExamCategory` existed since the initial taxonomy seed with zero
  `ExamType` rows under it — 5 real report types now seeded (Internship Report, Bachelor's
  Report/Mémoire de Licence, HND Report, Master's Thesis/Mémoire, PhD Thesis/Thèse), ported
  1:1 from the Flutter mock taxonomy that had already anticipated these names. `PaperSubmission`
  gained `institution`/`discipline`/`supervisor_name` (all free text — reports have no `Subject`
  taxonomy of their own, unlike exam papers).
- **Client:** removed the parallel, never-wired `ReportType`/`getReportTypes()` concept (the
  real `HttpPapersRepository` implementation was silently returning hardcoded mock data even in
  "real" mode) — Academic Reports now reuses the same `getExamTypes()` taxonomy lookup as exam
  papers, since `reports` is a real category like any other. Submit's "Academic report" tab
  (previously an honest "coming soon" placeholder) is now a real form: report type picker,
  institution/discipline text fields (required), supervisor (optional), year, file upload —
  posts a real multipart submission via the same `submitPaper()` path as exam papers.
- Verified live end-to-end against the real backend (not just tests): registered a user,
  fetched the real seeded report types via the API, submitted a real report with a real file to
  real Supabase Storage, confirmed the response — institution/discipline round-tripped, subject
  stayed null, supervisor stayed empty (genuinely optional). Also caught and fixed a real bug
  during this pass: the migration seeded `badge_tone="red"`, a value the Flutter client's
  `SpekoohBadgeTone.values.byName()` doesn't recognize — would have crashed the picker the
  first time a real user opened it. Fixed to `"neutral"` in both the migration and the
  already-seeded dev rows.
- Verified with a real debug APK build too.
- Tests: 2 new backend tests (real submission round-trip, exam types seeded correctly), 2
  updated Flutter widget tests (exam-paper flow split out, new report-flow test walks the real
  taxonomy picker end to end).

### 6. ~~Report watermarking + payment-gated viewing/downloading~~ — done
- Owner decisions (not invented): a static Spekooh watermark, applied once at upload — not
  personalized per-viewer. Viewing is free for Internship/Bachelor's/HND reports, but
  Master's Thesis and PhD Thesis require payment even to view, not just download. Downloading
  *any* report always requires payment, regardless of view-tier. "Free to view" is enforced by
  a real in-app document viewer (not an OS handoff, which would let the user just hit that
  app's own Save button) — building that, not just gating the existing external-open flow, was
  itself an owner decision.
- **Backend:** `ExamType.requires_payment_to_view` (true only for the two thesis-tier report
  types, set via a data migration). `apps.papers.services.watermark_report_submission()` runs
  automatically on every "reports"-category submission — PDFs get a real diagonal overlay
  (`pypdf` + `reportlab`, merged via `PdfWriter(clone_from=...)`), images get one drawn
  directly (`PIL.ImageDraw`); a corrupt/unsupported upload falls back to the original bytes
  rather than failing the whole submission. The unwatermarked original is deleted from storage
  after the watermarked version is saved — checked for the case where the storage backend
  reuses the same key (S3's overwrite-by-default behavior), so cleanup can't delete the file it
  just wrote. `PaperSubmissionListSerializer`/`DetailSerializer`/`CreateSerializer` gained
  `category_key`, `requires_unlock` (server-withholds `file_url` entirely, not just a
  client-side flag — computed by `user_can_view_file()`, which exempts the submitter and staff)
  and `is_unlocked` (a real `PaperUnlock` exists — independent of `requires_unlock`, since even
  a free-to-view report needs one to download). Both gates reuse the exact same `PaperUnlock`/
  `unlock_paper()` mechanism exam papers' marking-guide unlock already uses — one real payment
  satisfies both the view-gate (if any) and the download-gate together.
- **Client:** `ReportViewerScreen` (new) renders PDFs via `pdfx` and images via `photo_view`
  entirely in-app — the actual mechanism behind "free to view, no download," since it never
  hands the user a file the OS could offer to save. `PaperDetailScreen`: a gated report shows a
  real locked message instead of the file preview; an accessible report's "View" pushes the
  real viewer (exam papers keep the existing external-open behavior, untouched); the
  Save-offline action (built earlier this session) is now hidden behind a real "Unlock below to
  download" hint until `is_unlocked` is genuinely true, for every report regardless of
  view-tier; the existing unlock card's copy switches from "Marking guide" to "Download access"
  for reports.
- Verified live end-to-end against the real backend, not just tests: submitted a real PhD
  thesis PDF, confirmed the submitter sees their own file immediately
  (`requires_unlock: false`) despite the thesis-tier gate, downloaded the stored file and
  confirmed it's genuinely watermarked (`pypdf` text extraction found both the original content
  and "Spekooh"), published it, confirmed a *different* user is correctly gated
  (`requires_unlock: true`, `file_url: null`), created a real `PaperUnlock` for that user, and
  confirmed access opened up (`file_url` now present, `is_unlocked: true`). Also verified with
  a real `flutter build apk --debug` (the two new native plugins, `pdfx`/`photo_view`, needed a
  real Android build to prove they integrate, not just `flutter analyze`).
- Tests: 8 new backend tests (real watermarking on a real PDF/verified via `pypdf` extraction,
  exam papers stay untouched, gated-until-unlocked, submitter/staff exemptions, serializer
  field exposure) — all against the real seeded taxonomy, not mocks. 3 new Flutter widget
  tests (locked message for gated reports, free-tier View pushes the real viewer — checked via
  a `NavigatorObserver` rather than letting `pdfx`'s native plugin actually render in a widget
  test, which it can't without a real device/platform, Save-offline gated until a real unlock).
- **Update, 2026-08-25 — owner correction:** "downloading *any* report always requires
  payment" (above) was flagged as wrong by the owner — a user shouldn't be asked to pay to
  download an Internship/Bachelor's/HND report that's already free to view. Policy is now:
  **Internship/Bachelor's/HND reports are free to both view and download** (no `PaperUnlock`
  needed at all); Master's/PhD-tier reports and every exam paper are unchanged — still require
  a real unlock to download. New `apps.papers.services.report_download_is_free()` is the single
  place this rule lives; `PaperAccessFieldsMixin.get_is_unlocked()` (drives the app's
  Save-offline gate and the "Download access" card) short-circuits to `True` for free-tier
  reports, and `apps.payments.services.unlock_paper()` now rejects a direct unlock attempt on
  one of them (`PaperUnlockError`) so nobody can be charged for something already free. Verified
  live: the Internship Report's "Unlock — 500 FCFA" button now correctly reads "Already
  unlocked" and Save-offline works immediately, no payment. 5 new tests (2 backend serializer
  tests — free tier needs no unlock, Master's/PhD tier still does; 2 `unlock_paper()` tests —
  rejects a free-tier report, still charges full price for a thesis-tier one).

### 7. ~~Referral bonuses~~ — done
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

### 8. In-app practice quiz auto-generated from submitted papers ("Past-paper practice")
- **Backend:** not built — no paper→quiz generation pipeline; `Quiz`/`QuizQuestion` are
  manually authored rows only.
- **Client:** shown honestly as "coming soon" (fixed this session — previously opened a
  hardcoded fake quiz regardless of what was tapped).
- Matches spec §3.3 P2 exactly ("in-app practice/quiz mode generated from paper content").

### 9. "Friday Arena" live elimination quiz
- **Backend:** not built — no live/scheduled quiz-session model, no real-time transport.
- **Client:** shown honestly as "coming soon" (fixed this session — previously a dead tap).
- **Not in the confirmed spec at all** — pure UI-mockup invention (closest real-world analogue
  is Kawlo's "live 1v1 quiz battles," which the spec itself flags in §12.4 as a P2 idea worth
  revisiting post-MVP, not committed scope). Lowest priority on this whole list.

### 10. Quiz anti-cheat / answer-hiding
- **Backend:** `correct_choice_index` is stripped from the list/detail serializer response
  (confirmed not sent to the client) but there's no protection against a user inspecting network
  traffic before answering, since the full grading logic still lives client-adjacent in spirit.
  Documented as a known, accepted gap in `apps/quizzes/models.py`'s own docstring — quizzes are
  P2/non-spec'd, so this was a deliberate corner-cut, not an oversight.

### 11. Subscription tier for marking-guide access
- Distinct from the already-real "Spekooh Pro" (ad-free + unlimited paper *views*, per §5.3 —
  confirmed to explicitly exclude marking guides). This P2 item is a *different*, not-yet-decided
  product idea (bundling marking-guide access into a subscription) — not started, and shouldn't
  be until product decides whether pay-per-unlock stays the only marking-guide monetization path.

### 12. Auto-extract paper metadata and auto-file submissions (2026-08-26, owner idea)
- **Idea:** when a contributor submits a scanned paper (`SubmitScreen` → `POST
  /api/papers/submissions/`), run OCR/document-understanding on the upload to recognize the
  essential fields — subject, exam board, year, level/grade, paper number — and auto-fill the
  submission's category/tags instead of relying entirely on what the contributor typed in by hand.
  Goal: less manual tagging work for contributors, more consistent categorization for review.
- **Backend:** not built — `PaperSubmission` today is filed purely by the fields the contributor
  submits (`apps/papers/models.py`); there is no OCR/extraction step anywhere in the upload
  pipeline, and no third-party OCR provider is wired in (`uploads/README.md` §2 lists
  "OCR/duplicate detection" as a confirmed but not-yet-implemented stack choice — this idea is the
  concrete feature that would consume it).
- **Scope note:** real OCR needs a provider decision (e.g. a hosted OCR/document-AI API vs.
  self-hosted) plus a review step, since auto-filed fields should stay contributor/reviewer-
  correctable rather than silently overriding what a human typed. Not started — needs its own
  design pass before implementation, not a drop-in addition.

---

## Recently shipped (2026-08-26 – 2026-08-30)

Owner-requested features and bugs found from live screenshots, in one batch. Each is a real,
tested, merged change (not a mock) — PR numbers are on `main`'s history for exact diffs.

- **Launch splash screen** (#27): shows the Spekooh logo briefly on app start before handing off
  to the real Home screen.
- **Contribute-now nudge** (#28): a one-time-per-session dialog on launch encouraging accurate,
  timely paper submissions, with a direct "Contribute now" CTA into the Submit tab.
- **Redis + Sentry** (#24 — see "Owner action items" above for the still-needed managed
  credentials): `guest_mint` rate limiting and error tracking, both real, both no-op safely with
  no config.
- **Em dash removed from user-facing text** (#29): the "—" used as a sentence-connector
  ("Contribution — earn credit") read as unpolished per owner feedback. Replaced across every
  `.arb` string, hardcoded UI string, and backend notification/error message that reaches the app
  or the Django admin. Genuine "no value" placeholders (a disabled field, an empty admin column)
  were left as a plain hyphen instead — a different, legitimate convention, not what was flagged.
- **Duplicated report titles fixed** (#30): reports (no Subject taxonomy) rendered
  "Internship Report, Internship Report 2022" — the title builder fell back to the exam type for
  both halves instead of only showing it once. Found from a live screenshot.
- **MCQ disclaimer hidden on reports** (#30): the "Objective/MCQ answers are marked in-house..."
  banner showed unconditionally, including on academic reports, which have no MCQ questions at
  all. Now gated the same way the rest of `PaperDetailScreen` already gates report-only behavior.
- **Add a custom subject when submitting a paper** (#31): the subject picker in `SubmitScreen` had
  no way to add a subject missing from the curated list. Backend get-or-creates a `Subject` by a
  slugified key (so retyping an existing one, any casing, reuses it instead of duplicating);
  gated to `IsAuthenticated` — guest accounts included, same bar as submitting a paper itself.
- **Non-functional search bars removed, one real one added** (#32): Papers had 3 `SearchInput`
  fields (category/exam-type/subject grids) with no `onChanged` at all — typing did nothing. All
  3 removed; one real, word-matching search added on the final paper-list step instead, scoped to
  papers already resolved for that category/exam-type/subject/track (not a global search). Notes/
  Quizzes/Shop already had real, working search and were left alone. Forum's decorative search
  icon (no `onTap`) was also removed — see "Not in the spec at all" below for the bell it left
  behind.
- **Subject/Academic level filters on Notes and Shop** (#33): both `Note` and `Pamphlet` gained
  `subject_title`/`academic_level` fields (free text — admin/partner-authored one row at a time,
  not picked from the contributor-facing taxonomy). Filter chip options are built from whatever
  distinct values actually exist, not a fabricated fixed list.
- **Exam papers publishable without waiting on the instructor pipeline** (2026-08-28, owner
  decision): a real marking guide can take an instructor a long time to produce, and a
  contributor's scan is useful to other students well before one exists — the admin's
  "Publish selected" action (`PaperSubmissionAdmin`) no longer requires
  `GUIDE_SUBMITTED`/`MERGED` status for exam papers, just "not already Published" (same rule
  reports already used). This never fabricates a guide: `has_marking_guide` (new field on both
  paper serializers, backed by whether a real `PublishedGuide` row exists — independent of
  publish status) tells the app the truth. The app now shows an honest "marking guide not yet
  available" message — no lock icon, no "Unlock: 500 FCFA" button, no redeem-code field — instead
  of ever offering to sell a guide that doesn't exist. The real instructor pipeline
  (`merge_and_publish`) is unaffected and still creates a real `PublishedGuide` exactly as before
  when it does complete; this is an additional path in, not a replacement. Verified end-to-end
  against the real local backend: published one real paper via `mark_published` (no guide) and a
  second via the full `merge_and_publish` pipeline (real instructor guide), confirmed
  `has_marking_guide` correctly reads `false`/`true` for each via the live API, cleaned up both.
- **Exam papers: free to view, small paid unlock to download** (2026-08-28, owner decision):
  "similar to academic report[s], exam paper[s] can only be view[ed] in the app and download
  [is] block[ed] ... user need to pay a small amount like 50-100 depending on the exam level."
  Exam papers now render in-app (the same `ReportViewerScreen` reports already use — genuinely
  generic despite the name, not a report-specific screen) instead of handing off to the OS's own
  PDF/photo app, which is exactly the loophole that let anyone "view for free, then use the OS's
  own Save" before a real download purchase existed for exam papers to gate against. New,
  deliberately separate `PaperDownloadUnlock` model/purchase (distinct from `PaperUnlock`, which
  still gates the marking guide, not the file) — priced by exam level via
  `PAPER_DOWNLOAD_PRICE_FCFA_BY_CATEGORY` (primary/secondary/tertiary/university/concours; retune
  freely, illustrative defaults within the owner's stated 50-100 range). New `paper_download_unlocked`
  / `paper_download_price_fcfa` fields on the paper serializers; the app shows a real "Unlock
  download: {price} FCFA" button (not a passive hint) when locked. Submitter and staff are always
  exempt, same pattern as the existing view-gate. Verified end-to-end against the real local
  backend: confirmed staff/submitter exemption, confirmed a fresh non-staff user is genuinely
  gated, unlocked for real (charged the correct category price), confirmed the field flips true,
  confirmed a second unlock attempt is correctly rejected — cleaned up all test data.
- **Real app icon replaces the default Flutter logo** (2026-08-28): every launcher/favicon asset
  (Android `mipmap-*/ic_launcher.png`, iOS `AppIcon.appiconset`, web `favicon.png` +
  `icons/Icon-*.png`) was still the stock blue Flutter "f" wordmark — the real
  `assets/branding/spekooh_logo.png` was only ever wired into the splash screen. Generated the
  full real set from a clean crop of the logo's gold-outlined "S" monogram (the "SPEKOOH" wordmark
  and flanking accent shapes don't read at icon sizes) on the same gold50→gold200 gradient the
  splash screen already uses, at every required platform size. Also fixed the leftover
  `"A new Flutter project."` boilerplate description/theme-color in `pubspec.yaml`,
  `web/manifest.json`, and `web/index.html`.
- **Profile: real "Edit profile" (username/email/phone)** (2026-08-28, owner decision, adapting a
  reference design): a pencil icon on the profile card now opens a real sheet, pre-filled from the
  account, that saves via `PATCH /auth/me/` — a real endpoint that already accepted these fields
  server-side before any UI reached it. Changing the email resets `email_verified_at` and sends a
  fresh verification code (`UserSerializer.update`, new) so an unverified new address is never
  left looking verified — the same real flow used at signup, not a new mechanism. 3 new backend
  tests, 5 new app tests.
- **Profile: real badges, replacing an always-empty grid** (2026-08-28, owner decision, adapting a
  reference design already sketched in this app's own `ui_kits/spekooh-app/ProfileScreen.jsx`
  mockup — the exact "Spark/Ember/Inferno/Scholar I" names were already there, just never backed
  by real data): `HttpProfileRepository.getAchievements` previously always returned `[]` with a
  comment explaining mock data would misrepresent a real user's progress. Now computes real
  earned/locked state client-side from counts the profile screen already fetches
  (`submissionsCount`/`quizzesCount`) — no new backend endpoint, same "compose from
  already-existing data" pattern `getUser()` uses. The "Badges" section header now shows a real
  "All N" count (N = however many are actually defined, never a fabricated round number) and opens
  a real list of every badge, earned or not, with what it actually takes to earn it.
- **Profile: "Spekooh Pro" promo card** (2026-08-28, owner decision, adapting a reference promo
  card): a second, more visible entry point to the real paywall (Settings already had one) — same
  real 500 FCFA/mo subscription, not a separate offer.
- **A real, readable Privacy Policy** (2026-08-28, owner-provided reference policy adapted for
  Spekooh): Settings' "Privacy policy" row had no `onTap` at all, and the signup screen asked every
  new user to agree to a "Privacy Policy" that didn't exist anywhere reachable in the app. Adapted
  the owner's reference policy — same structure and thoroughness, but every claim in it checked
  against what Spekooh's own code actually does: real data categories (name/email/phone/photos/
  submitted papers, no location, no push notifications since neither exists in this codebase),
  the real third-party SDK (Google AdMob, for the opt-in rewarded-ad unlock only — not blanket
  display ads), and the real in-app way to review/correct your data (Profile's new Edit profile
  sheet above). No company name/address existed to state, so it refers to itself simply as
  "Spekooh" throughout (owner-confirmed) with the real support email/phone already used elsewhere
  in Settings. Wired into both the Settings row and a new "View Privacy Policy" link next to the
  signup terms checkbox.
- **Profile: settings button no longer shows a back-arrow** (2026-08-28, found from a live
  screenshot): the "open Settings" button on Profile's header reused `CircularBackButton` — the
  same small circular chevron-left widget as the real back button right next to it — so the
  header showed two identical back-arrows, one of which actually opened Settings. Added an
  `icon` param to `CircularBackButton` (defaults to chevron-left, every other call site
  unaffected) and passed a real settings-gear icon at this one call site.
- **Profile: real counts no longer stuck at 0 after returning from Settings** (2026-08-28, owner
  report: a real user's exam papers were submitted and published by admin, but Profile kept
  showing 0 submissions). The backend and API were verified correct live (the real user's 3
  published papers and 150 contributor-bonus credits both came back correctly from
  `/papers/submissions/?submitted_by=<id>` and `/credits/ledger/`) — a fresh Profile screen open
  already refetches fine. The real gap: popping back onto an *already-open* Profile screen from a
  screen pushed on top of it (e.g. Settings) never refetched at all, since `late final` futures
  were only ever computed once per screen instance. Added a `RouteObserver` (registered on the
  app's `MaterialApp`, `lib/shell/route_observers.dart`) and made `ProfileScreen` a `RouteAware` —
  `didPopNext()` now refetches the user/achievements/submissions futures for real whenever Profile
  becomes visible again, not just on first open.
- **Home: quick-actions restyled to one line, six distinct colors** (2026-08-28, found from a live
  screenshot): the 6 category cards (Papers/Notes/Contribute/Shop/Forum/Quizzes) stacked icon over
  label (2 lines) with the same uniform gold icon color on every card. Now icon and label sit on
  one line, and each card gets a genuinely distinct tint from `IconChipTint` — added `gold` as a
  6th tint (bg `gold200`/fg `gold700`, matching the avatar-circle color already used elsewhere) so
  the existing categorical-color system covers exactly 6 without reusing a color across two cards.
- **Home: daily-challenge card split into two, adapting a reference design** (2026-08-28): was one
  dark `ink900` card with an internal vertical divider between the challenge info and the streak.
  Now two separate white cards side by side (`IntrinsicHeight` + `CrossAxisAlignment.stretch` so
  they match height) — same real data as before, nothing new fabricated: the real quiz title, the
  real question count, the real streak from `quizzesRepository.getStreak()`. Added one genuinely
  new real field to the display: `quiz.suggestedTime` (already tracked, backed by
  `suggested_time_seconds` on the backend, previously shown only on the Quizzes tab) now shows as
  a small time pill next to the "DAILY CHALLENGE" label — not a fabricated duration.
- **`RUNNING_LOCALLY.md` + a real Android app on a real phone, for the first time this project**
  (2026-08-28): every previous run of this app was web or `flutter test` — this session did the
  first-ever real native install on a real device, which immediately surfaced two real gaps
  neither web nor mocked tests could ever catch: (1) `android/app/src/main/AndroidManifest.xml`
  had no `<uses-permission android:name="android.permission.INTERNET" />` at all — Flutter's
  debug/profile manifests carry it automatically (for hot-reload), the release one doesn't unless
  added explicitly, so a real installed release APK opened past its splash screen and then acted
  like the backend didn't exist (honest empty states everywhere, login/register silently doing
  nothing) — fixed; (2) `config.settings.dev`'s `ALLOWED_HOSTS` only allowed `localhost`/
  `127.0.0.1`, rejecting a real phone's request to the backend by LAN IP or tunnel hostname with
  `DisallowedHost` — widened to `["*"]` (dev-only settings module, `DEBUG` already `True`).
  Documented the full real path end-to-end in `RUNNING_LOCALLY.md`: backend setup, the web dev
  loop, and building+installing a real APK against a `cloudflared` quick tunnel (works from any
  network, no router config) including the exact troubleshooting for both bugs above. Also added
  `backend/requirements.txt` (previously untracked entirely — a fresh clone had no way to know
  what to `pip install`), generated from the real working environment via `pip freeze`.
- **Subject picker: long subject names no longer overflow their card** (2026-08-28, found from a
  live screenshot): `SubjectCard`'s title had no `maxLines`/`overflow`, and the subject grid
  (`papers_screen.dart`) uses a fixed `childAspectRatio` for every cell — a real, sometimes
  contributor-typed subject name ("Research méthodologie and scientific writing", "Fondation of
  data science and programming of data science") wrapped to 3+ lines and spilled out of its own
  card into whatever sat below it (in the reported case, onto the AI assistant FAB). Capped the
  title to 2 lines with ellipsis, tightened the card's internal padding/spacing, and gave the
  subject grid specifically more vertical room (`childAspectRatio` 1.15 → 0.92 — the category
  grid, which has no badge row and only ever shows short curated names, is untouched). Verified
  against the exact reported title plus a comparably-long one, at a real narrow-phone cell size,
  not just the default test viewport.
- **Bottom nav's raised center button no longer sits right of center** (2026-08-28, found from a
  live screenshot): `BottomNav` laid out all 5 tabs in one flat `Row` with
  `MainAxisAlignment.spaceBetween` — that distributes equal *gaps*, not equal *halves*, so
  asymmetric flanking label widths (French "Accueil"/"Épreuves" run noticeably wider than
  "Forum"/"Quiz") pushed the fixed-width center button visibly off true center. Split the
  flanking tabs into two independent `Expanded` halves, each spread with its own
  `spaceAround`, with the center button placed directly between them — its position is now the
  true geometric middle regardless of how wide either side's labels run, in any locale. New test
  reproduces the exact asymmetric-label scenario and asserts the center button's x-position
  directly (confirmed it fails against the old layout before the fix, not just that it passes
  after).
- **A real rewards explainer after a contribution, adapted from a reference design** (2026-08-30,
  owner-provided reference): the post-submission screen was a single checkmark + one paragraph —
  real, but told a contributor nothing about what contributing is actually worth. Adapted a
  reference gamified-rewards design's structure (decorative badge, headline, three benefit rows,
  CTA) — but every fact in it is real, nothing invented: Spekooh has exactly one currency (bonus
  credit, `CreditLedgerEntry`), not a fabricated points/XP/level system, and credit is only ever
  awarded once a submission is actually verified and published (`mark_published`) — never claimed
  as already earned on this screen, since nothing has been credited yet at submission time. The
  three rows: bonus credit (reuses the real `contributionBonusBanner` copy already shown on the
  submit form itself), a real redeem-code discount once enough contributions accumulate (reuses
  the real `redeemCodeEarnHint` copy already shown on Profile), and the real duplicate-check +
  instructor-routing explanation (reuses the original screen's own accurate copy). Extracted into
  its own `ContributionRewardScreen` widget so it's independently testable — `file_picker` needs a
  real platform channel unavailable in widget tests, so the full submit-to-success flow can't be
  driven end-to-end in a test; the extraction sidesteps that. New tests assert the real facts
  render and explicitly assert no fabricated "+N" amount ever appears.

---

## Not in the spec at all, and correctly left alone

These are decorative gaps found during this session's audit. Each was deliberately left
unfixed because "fixing" them for real would mean fabricating something that doesn't exist yet
(a support inbox, a WhatsApp group, a public website), which is exactly the dishonesty this
whole pass was hunting:

- **Settings → Visit our website / Privacy policy**: two still-dead links (down from five —
  Help & support/WhatsApp/Contact us are wired to real destinations, see above). Needs a live
  site and real legal text before these can point anywhere real.
- **Forum notification bell**: purely decorative, no `onTap` (2026-08-27: the search icon next to
  it has been removed — see "Recently shipped" below — the bell is what's left). Forum already has
  a working list; wiring real search would need a `?search=` query param the backend doesn't
  currently expose on `/forum/posts/`.
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
