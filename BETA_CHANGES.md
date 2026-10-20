# Beta changes log — 2026-09-28

Every change made in this stretch of work, why it was made, where it lives, how to check it, and what it does to real data. Written for the owner, and for whoever deploys next.

**Read this first**

- **Merge order matters** — see "Rollout order" at the bottom. Two earlier mistakes are recorded there so they don't repeat.
- **Three migrations change real data when staging deploys** (staging runs `migrate` on every deploy): the credit → points carry-over (`xp/0003`), the discount-code backfill (`credits/0008`), and the Support notes permission (`accounts/0016`). Each is idempotent and reversible; details in each section. **None has been applied to any database yet.**
- Production is still documented as not deployed (`RENDER_PRODUCTION.md`), so none of this has reached real users.

## Beta window

**Beta started 2026-10-20, time-boxed to one month (ends 2026-11-20).** Owner decision. Until then:
beta build 5 (`spekooh-beta-1.0.0-build5.apk`, SHA-256 `6730d89f25e1fac1a04d2833b95eaf3c2b58646541e57d8094f8975d05091318`) is the distributed build — no app-code changes have shipped since it was built, only the backend fix below, so testers already on build 5 need no reinstall. Priority for this window should default to P0 stability/bug fixes over new features (see `TODOS.md`'s own P0/P1/P2 split) unless the owner says otherwise. No Play Console submission during this window — that's a separate, not-yet-started track (see `PLAY_STORE.md`).

## At a glance

| # | Change | Where | PR | Changes real data? |
|---|---|---|---|---|
| 1 | S@Learn database brought up to date; qualification-save bug fixed | S@Learn repo + its Supabase DB | S@Learn #13 | Yes (schema, applied by hand) |
| 2 | Instructor requests can no longer be created by hand in the admin | Backend | #193 | No |
| 3 | Root `.env` git-ignored for everyone | Repo | #194 | No |
| 4 | Practice mode opens Notes; PRO badge; "Plus" → "Pro"; more mock notes | App | #195 | No |
| 5 | Support staff can create and update notes; demo-notes seed command | Backend | #196 | **Yes** (Support permissions) |
| 6 | `DESIGN.md` created; `CLAUDE.md` points at it | Docs | #197 | No |
| 7 | Credits and XP merged into one **Points** balance | Backend + app + docs | #199 (replaces #198) | **Yes** (balances) |
| 8 | Terms of Service rewritten for Points and Pro | Backend + app | #199 and #200 | No |
| 9 | Automatic, accumulating discount codes | Backend + app + docs | #200 | **Yes** (codes created) |
| 10 | Terms versioning and a re-accept prompt | Backend + app + docs | #201 | Adds a table; every existing registered user is asked to accept once |
| 11 | Summary notes: text, assignment to support staff, dashboard card | Backend + app + docs | #204 | No |
| 12 | "Test mode" notice wherever money changes hands | Backend + app + docs | #203 | No |
| 13 | AI assistant chat history, on the phone | App + docs | #202 | No |
| 14 | Papers tab: hardware back steps through the drill-down instead of jumping to Home | App | the papers-back-button PR | No |
| 15 | Play Store prep: launcher label and a real adaptive icon | App | #212 | No |
| 16 | Summary notes: compulsory fields; Subject/Academic level picked, not typed | Backend | #223 | Adds 1 subject row; backfills existing notes' subject/level |
| 17 | Papers/reports couldn't be submitted at all (staging) — root cause: Sentry trace headers breaking S3 signatures | Backend | #224–#228 | No |

---

## 1. S@Learn instructor rollout (separate repo)

**Problem.** Saving an instructor's qualifications in S@Learn failed, and the live database was behind the code.

- **Database.** The live S@Learn database was missing migration 0063 (`m0063_cols` came back 0). I could not reach it from here, so I produced one script that brings it to date from *any* starting point: migrations 0061–0064 with every statement made idempotent (`if not exists`, `drop … if exists`). I tested it on a throwaway Postgres in three states (empty, run twice, and 0061/0062-applied with existing rows). You ran it in the Supabase SQL editor; the check then returned the qualifications table and `m0063_cols = 3`.
- **Bug.** `spekooh-qualifications` read `profiles.email` through the caller's session, but migration 0046 revoked column access to it, so every save failed with "Could not load your profile". Fix (S@Learn PR #13): take the email from the verified session and read only `full_name`. Deployed to project `hzcdcjtngxhxbzeirbmz`; a real save then returned `{"ok":true}`, which also confirms the staging webhook URL and secret match.
- **Verify.** S@Learn → Spekooh Marking → Qualifications → tick a level → Save → "Qualifications saved."; then the level shows in the **Qualified for** column of the Spekooh admin.
- **Still open:** every queued instructor must save their levels (Spekooh routing fails closed until they do); an end-to-end paper test on staging; **revoke the Supabase access token** (it was pasted into chat and lived in `.env`) and delete the `AQ.Ab8R…` API key pasted earlier.

## 2. Instructor request admin crash (#193)

Adding an "instructor request" by hand in the Django admin crashed with `NotNullViolation` on `sent_at`: the field is read-only there and has no default, so the form inserted NULL. That row must only be created by `route_next_instructor`, which sets it and fires the S@Learn webhook, so manual creation is now disabled (same pattern as `RedeemVerification`). Test: `test_instructor_request_admin_disallows_manual_add`. **To test routing**, call `POST /api/instructors/route/<paper_id>/` for a real paper instead.

## 3. `.env` (#194)

The root `.env` (holds `SUPABASE_ACCESS_TOKEN`) was excluded only by `.git/info/exclude`, which is local to one clone. `/.env` is now in the tracked `.gitignore`. Neither `.env` file was ever tracked.

## 4. Practice mode, Pro badge, mock notes (#195)

- **Practice mode → Notes.** The Home card "Practice mode / Learn without countdown pressure" opened Papers; it now opens Notes, reads "Browse real summary notes by subject and level." (EN/FR) and has a book icon. Files: `logged_in_home_screen.dart`, `app_en.arb`, `app_fr.arb`. Tests: copy (EN/FR), tap opens Notes and not Papers (mutation-checked), tap lands on a Notes list.
- **PRO badge.** Pro members get a gold PRO pill (crown, screen-reader label) beside their name on Profile; the "Get Spekooh Pro" upsell row is hidden for them. New widget `widgets/pro_badge.dart`.
- **"Plus" → "Pro".** One name for the paid tier everywhere users read. The code flag `isPlusSubscriber` and the backend API field keep their old names on purpose.
- **Mock notes.** Four more (Primary, O Level, Seconde, University), nine in total.

## 5. Notes: Support staff and the seed command (#196)

- **Support can create and update notes.** Migration `accounts/0016_support_notes_permissions` gives the Support group `view_note`, `add_note`, `change_note` — **not delete**. It adds to Support's read-only permissions rather than replacing them, and forces permission creation first so it works on a fresh database (0012's "skip if missing" pattern could silently grant nothing there). Support is still read-only everywhere else; `test_support_group_is_read_only_except_for_authoring_notes` pins that exact set, and `SECURITY.md` says so.
- **Blank subtitles.** `NoteAdmin` fills a blank subtitle from "Subject · Level", so a note created in the admin never shows an empty second line.
- **Seed.** `python manage.py seed_demo_notes` creates the four newer demo notes (the first five already come from migrations). Matched by title, created only when missing, never overwrites admin edits; `--remove` deletes only its own four. **Not run anywhere yet** — run it on staging when ready.

## 6. `DESIGN.md` (#197)

`CLAUDE.md` told every session to read `DESIGN.md`, but the file never existed. It now does: tokens (colors, gradients, type, spacing, radii, shadows), components as built, iconography, copy rules, the admin theme, and a dated decision log. **The code tokens in `app/lib/theme/` win over the document**; if they disagree, fix the document in the same PR. `CLAUDE.md` now states its scope (Spekooh app and admin, not S@Learn), that rule, and the "every string in both `.arb` files, then `flutter gen-l10n`" rule.

## 7. One Points balance (#199)

**Why.** Credits only ever went up and nothing could spend them; XP was the only balance that bought anything; one contribution paid into both, and users assumed one converted to the other. **Owner decision:** one balance, named **Points**; contribution **50**, referral **200** (the numbers users already knew as credits), quizzes unchanged (10, or 25 for the daily challenge). The extra +15 / +10 XP that used to ride along is dropped. 500 points still buy +1 offline slot for 3 days.

**Backend**
- `award_contributor_bonus` / `award_referral_bonus` now write to `XPLedgerEntry` at the existing ops-editable amounts (`ContributorBonusConfig`, `ReferralBonusConfig`). `award_contribution_xp` / `award_referral_xp` and their callers are gone.
- `CreditLedgerEntry` is retired: nothing writes to it, it is read-only in the admin, and `/credits/ledger/` stays for old app builds.
- **`xp/0003_carry_over_credit_balances`** adds each user's total credit balance to the points ledger as one entry (reason "Carried over from bonus credits"), 1:1 so nobody loses anything. Idempotent, and reversing it removes only those entries; the credit rows are untouched as the audit trail.
- `xp/0002` and `credits/0006` only relabel the two ledgers in the admin ("points ledger entries", "credit ledger entries (retired)").
- Internal names keep `xp` (the table, the `xp_balance` API field) so older builds keep working; only what users read changed.
- Bug found and fixed on the way: the "your paper is published" notification crashed after this change; a test now checks it says points.

**App.** Profile shows one "Your points" balance with how to earn and spend it (`pointsBalanceHint`). My Downloads, the FAQ, and the contribution/referral copy say points (EN/FR). `creditBalance` is gone from the user model and Profile no longer fetches the credit ledger. The interim "Credits and XP" explainer card (built first, then superseded) was removed.

**Verify.** In the admin, *Points ledger entries* shows "Carried over from bonus credits" rows; a user's Profile points = old XP + old credits; publishing a test paper adds 50.

## 8. Terms of Service

Section 5 is now "Points, rewards, and redeem codes": one balance; how points are earned and spent; earlier credits converted one-for-one; redeem codes are a separate reward, are not bought with points and cannot be requested; we may limit codes per account; no cash value; revocable for fraud. "Spekooh Plus" → "Spekooh Pro"; "farm contributor bonuses" → "farm points or redeem codes"; last-updated date 28 Sep 2026.

- The Terms exist twice (`app/lib/screens/legal/terms_of_service_content.dart`, `backend/apps/core/legal_content.py`, served publicly at `/legal/terms-of-service/`). A new test, `test_the_backend_and_app_copies_of_the_terms_are_identical`, fails if they drift.
- **There is no Terms version or re-acceptance flow** (only a `terms_accepted_at` timestamp), so existing users are not asked to agree again. Whether that needs a notice is a legal call for you.
- Other user-visible "Plus" strings changed too: the AI chat-limit message and the payment description.

## 9. Automatic, accumulating discount codes

**Problem.** Any signed-in user, even with no accepted paper, could call an endpoint and mint unlimited discount codes (the lowest tier was "0 papers → 5%"). The app never called it, so contributors never actually received codes either.

**Owner decisions.** Earned automatically; one code per contributor that improves with each newly accepted paper; each paper counts once; sharing stays; the tier table stays **out of the app**.

**How it works** (`apps/credits/services.py`, `grant_redeem_code`). When a paper is accepted and published:
1. No active code (never had one, used, or expired) → a new code at the tier for their total of accepted papers.
2. An active code exists → the **same** code is upgraded in place: discount = the higher of its current value and the new tier's; expiry = the later of its current expiry and today + the tier's validity. It never gets worse.
3. Each accepted paper counts once (`RedeemCodeContribution.paper_submission` is unique); duplicates and unaccepted papers never count.
4. If no tier is configured it grants nothing and publishing still succeeds.

**The tier table** (ops setting, admin → Redeem code tier configs, now with a readable *Accepted papers* column):

| Accepted papers | Discount | Valid for |
|---|---|---|
| 1–4 | 5% | 7 days |
| 5–14 | 10% | 14 days |
| 15–23 | 15% | 21 days |
| 24 or more | 20% | 30 days |

(The seeded first band starts at 0; a code only exists once a paper is accepted, so it is shown from 1.)

**Also**
- The open `POST /credits/redeem-codes/issue/` endpoint is **removed** (it now answers 404/405); `RedeemCodeIssuer` is gone.
- **Migration `credits/0007`** adds `RedeemCodeContribution`. **Migration `credits/0008` backfills**: every contributor who already has accepted papers gets **one** code at their current tier (not one per old paper), and their old papers are marked counted so they cannot earn again; an existing active code is upgraded instead of duplicated. Idempotent. Reversing removes the counted-paper records only; codes stay.
- The "your paper is published" notification now says "…you earned 50 points and a 5% discount code", or "…your discount code is now 10% off" when it was upgraded.
- **Profile** shows the code, its discount and "Expires in N days" (EN/FR), and ignores a code that is already past its expiry (its status only flips to EXPIRED when someone tries to apply it). The empty-state hint now says the code arrives automatically.

**Verify on staging.** Publish a test paper for a user with no code → +50 points and a 5% code on their Profile; publish a second one → same code, later expiry; a user's 5th accepted paper → the same code becomes 10%.

## 10. Terms versioning and re-acceptance

**Why.** The Terms had a "last updated" date but no version and no way to ask users to agree again, although section 14 promises that "a material change will be flagged in the app, not just posted silently". `terms_accepted_at` only ever held the latest time, so it could not show what anyone had agreed to earlier.

**How it works**
- **One version, in one place.** `TERMS_OF_SERVICE_VERSION` in `backend/apps/core/legal_content.py` (currently `2026-09-28`); the app reads it from the server, so it is never duplicated. **Bump it only for a material change** (takes a benefit away, adds an obligation, or changes payment, refund, liability or data-use terms). A wording fix only changes the "last updated" date.
- **Append-only history.** `accounts.TermsAcceptance` (user, version, time; unique per user and version; migration `accounts/0017`). Rows are never edited or deleted, and each user's admin page lists them read-only, so a bump leaves the earlier consent intact as evidence.
- **The API.** `GET /auth/me/` now returns `terms_version` and `needs_terms_acceptance`. `POST /auth/terms/accept/` (body `{"version": …}`) records the acceptance; it refuses any version that is not the current one (400) and refuses guests (403). Registration records the current version.
- **The prompt.** After every sign-in and app start, the shell asks `/auth/me/` (one request). If the account still has to accept, a blocking dialog appears: "We've updated our Terms of Service", **Read the Terms**, a tick box, **Accept and continue** (disabled until ticked) and **Log out instead**. No barrier tap, no back gesture. A failed check never blocks the app; the next sign-in asks again. English and French.
- **Who is asked.** Registered accounts with no acceptance of the current version, **including every existing account**, since none has agreed to a specific version yet. So **each existing tester sees the prompt once** after this deploys; that also gives you a clean consent record for the current text. Guests are never asked. (If you would rather grandfather existing users, that is a one-line data migration that records the current version for them; say so.)

**Limits.** Enforcement is in the app: the API does not refuse requests from an account that has not accepted, so an old app build that has no prompt keeps working. Add server-side blocking later only if you decide it is needed.

**A bug found on the way.** Signing in notifies the shell while the login sheet is still open, and the sheet then pops itself with `Navigator.pop`, which pops whatever is on top, so a fast check could show the dialog and have the sheet's own pop close it. The prompt now waits until the shell is the visible screen. A test signs in through the real sheet to cover it.

**To require re-acceptance later.** Change the Terms text in both copies (the drift test keeps them equal), set `TERMS_OF_SERVICE_LAST_UPDATED`, and bump `TERMS_OF_SERVICE_VERSION`. Every registered user is asked again on their next launch.

**Verify on staging.** Sign in as a registered user: the prompt appears once; tick and accept; sign out and in again: no prompt. In the admin, that user's page shows the acceptance.

## 11. Summary notes: text, assignment and a dashboard card

**Why the earlier notes change was invisible.** #196 only changed *permissions* (the Owner already had them) and quietly filled blank subtitles. The Notes admin was also the one admin still using plain Django styling instead of the project's Unfold theme, the dashboard had no place for notes, and in the app a note was only a title: its chevron did nothing, and the model had nowhere to store the actual summary.

**What changed**
- **A note now has text.** `Note.body` (plain text: a blank line is a new paragraph, `## ` a heading, `- ` a bullet). The app opens a note on tap and shows it; a note with no text yet says so instead of showing an empty page. New public endpoint `GET /api/notes/<id>/`; the list stays text-free and light.
- **Assignment to support staff.** `Note.assigned_to`: only people in the Support group can be picked, shown **by name only, never an email** (a staff member with no name shows as "Staff member N"). It is internal and never sent to the app. In the admin: an *Assigned to* column you can edit straight from the list, a filter (*Assigned to me*, *Unassigned*, or one person), and two bulk actions, **Assign selected notes to me** (Support members only) and **Remove the assignment**.
- **Add, update, delete.** Owner, Reviewer and Integration Ops can do all three; Support can add and update but **not delete** (unchanged decision from #196).
- **Dashboard card "Summary notes":** total notes, still to write, unassigned, assigned to me, each a link to the filtered list, plus an **Add a note** button. Shown only to roles that may view notes.
- **A "Summary text" filter** (*Still to write* / *Written*) and a search that also searches the text. The admin model is now called "Summary notes" and uses the Unfold theme like the rest.
- **Real demo content for every level.** `python manage.py seed_demo_notes` now creates 17 notes with real, readable summaries (Primary, BEPC, Seconde, O Level, A Level, Probatoire, Terminale, Baccalauréat, HND, University; English or French to match the level) and gives text to the five older notes that had none. It never overwrites anything staff wrote, and `--remove` deletes only demo notes that are still untouched. **Not run on any database yet.**

**Data.** Migration `notes/0007` adds two nullable/blank columns; nothing existing changes. Rollback: `migrate notes 0006`.

**Verify on staging.** Run `seed_demo_notes`; open the admin dashboard (the Summary notes card); open Summary notes, assign one to a Support member, filter by *Assigned to me*; then in the app, Practice mode, tap a note and read it.

## 12. "Test mode" notices where money changes hands

**Why.** Payments are simulated: `MockPaymentProvider` approves every charge and moves no money, yet the Pro subscription, marking-guide and download unlocks, and pamphlet purchases all behave exactly like real ones. Anyone using the app, testers and you included, could take that for live.

**What.** A small notice, "Test mode: payments aren't live yet. This works like the real thing, but no money is charged." (English and French), shown right above the payment field in all four places: the Pro paywall (before and after subscribing), unlocking a marking guide, unlocking a paper download, and reserving a pamphlet. The flows still work as before; they are just honest.

**The server decides, so the notice removes itself.** A public endpoint `GET /api/status/features/` returns `{"payments_live": false}`. It is computed from the payment provider actually wired in (`apps.payments.services.payments_are_live`), not a flag someone must remember to flip, so the day a real provider replaces the mock the notice disappears with **no app release**. The app caches a good answer for 10 minutes, and if it cannot reach the server it shows the notice (the cautious answer: a missing warning on a fake payment is worse than one that lingers). The endpoint is public, rate-limited (300/hour per IP) and returns nothing but that boolean.

**What is deliberately not covered.** Things already labelled in the app ("coming soon" quizzes, past-paper practice, the Friday arena, academic-report submission) keep their own message. Text-message verification has no screen in the app yet, so there was nothing to label.

**Adding the next one.** If another feature can look live while not being so, add a key in `apps/core/feature_status.py`, a field on the app's `FeatureStatus`, and a notice widget beside it.

**Verify.** Open the Pro paywall on staging: the notice is there; it is also above the phone field when you unlock a guide or reserve a pamphlet. `curl https://spekooh-staging.onrender.com/api/status/features/` returns `{"payments_live": false}`.

## 13. AI assistant chat history (on the phone)

**What.** The Spekooh Assistant used to forget everything when you left the screen. Now every chat saves itself once the assistant has replied. Two new buttons in the assistant's header: **Chat history** (a list of saved chats, newest first, each with its first question as the title, message count and date; tap one to reopen it and carry on in the same chat) and **New chat** (starts a blank one and keeps the old one). In the history you can delete a chat, or **Clear all**; both ask first. English and French.

**Decision, and why: on the phone only, per account.** Chats are stored in a file on the device (one per signed-in account, so a second account on the same phone never sees them), not on your servers. Saving students' typed messages server-side would be new data collection: it changes your privacy promises, needs a Privacy Policy update and a way to delete it on request. The trade-off is that history does not follow a student to a new phone. Server-side history with sync can come later, as its own decision.

**Limits and behaviour.** The 30 most recent chats are kept; a single chat keeps its last 200 messages. Saving is best effort: any storage failure (full disk, damaged file) looks like an empty history and never interrupts chatting. A damaged entry is skipped without losing the others. Uninstalling the app, or **Clear all**, removes everything; logging out does not (it is per account).

**Not changed:** the chat itself, the daily quota, and what is sent to the AI provider (each reply still needs the conversation sent to it, as before).

**⚠️ Privacy Policy gap to look at (not changed here).** The Privacy Policy does not mention the AI assistant at all. It should say that what a student types into the assistant is sent to an outside AI provider to produce the reply, and that the chat history is kept on their phone only. Worth a legal review; it is a text change plus a bump of `TERMS_OF_SERVICE_VERSION` only if you decide it is material.

**Verify.** Sign in, open the assistant, ask something; leave and come back; open **Chat history**: the chat is there. Tap it, ask a follow-up, check it is still one chat. Delete it and check the assistant starts blank.

## 14. Papers tab: the hardware back button skipped the whole drill-down

**The bug.** Papers browsing is a step-by-step drill-down (category -> system -> exam type -> track -> subject -> paper list), each screen's own back chevron correctly steps back one level. The hardware/system back button did not: `RootShellState`'s single `PopScope` only knew about tabs, so pressing back from anywhere inside that drill-down jumped straight to the Home tab, skipping every intermediate step.

**The fix.** `PapersScreenState` (made public so `RootShellState` can hold a `GlobalKey` to it) gained `maybeStepBack()`: steps back one level and returns `true`, or returns `false` at the very first (category) step, where there is nothing left to step back through. `RootShellState`'s back handling now offers the Papers tab this call first, and only falls through to its existing "back goes to Home" behavior when it returns `false` — the same behavior every other tab already had, unchanged.

**Why not two separate `PopScope` widgets.** Both Papers and RootShell sit on the same single route (Papers is a tab, not a pushed screen), and Flutter's `ModalRoute` fires every registered `PopScope`'s callback when a pop is blocked, not just the "nearest" one — nesting one inside the other would have run both `maybeStepBack()` and the jump-to-Home at once. The fix keeps one `PopScope`, owned by `RootShellState`, and has it ask Papers what to do first.

**Tests.** Real system-back gestures (`tester.binding.handlePopRoute()`, not the on-screen chevron): one step back from the system step lands back on the category step, not Home; the full depth (category -> system -> exam type -> subject -> paper list) steps back one level at a time all the way to category, and only the next back after that goes to Home; from the category step alone, back still goes straight to Home as before. Mutation-checked: reverting the fix makes the deep-stepping tests fail with the exact reported symptom.

---

## 15. Play Store prep: launcher label and a real adaptive icon

**The gap.** The Android manifest's launcher label was lowercase `spekooh` (iOS's `CFBundleDisplayName` was already the correct `Spekooh`). The app also only shipped legacy square launcher icons (`mipmap-*/ic_launcher.png`) with no adaptive icon (`mipmap-anydpi-v26` + foreground/background layers) — Play recommends one, and some launchers letterbox a legacy-only icon.

**The fix.** Manifest label capitalized to `Spekooh`. Added `flutter_launcher_icons` (dev dependency, Android-only) and generated a real adaptive icon from the existing PWA icon source (`app/web/icons/Icon-512.png` for the legacy icon, `Icon-maskable-512.png` — already W3C safe-zone padded — as the adaptive foreground) with a flat background color (`#F5E0B2`) sampled from that same gradient's corners, since Android's adaptive background layer must be a single drawable, not a gradient bitmap.

**Not done yet.** Feature graphic, real device screenshots, and the Data Safety form draft — see `PLAY_STORE.md` (new, repo root) for the full readiness checklist and what's still missing before an actual Console submission.

**Verify.** `flutter analyze` clean; regenerated icons visually checked against the existing brand mark (legacy square icon and the adaptive foreground both render the "S" mark correctly, no cropping artifacts).

---

## 16. Summary notes: compulsory fields, and Subject/Academic level picked, not typed

**The gap.** A note's Subject and Academic level were free-text fields — nothing stopped two notes about the same subject being spelled two different ways, nothing proposed the levels the app already has defined, and nothing stopped saving a note with no summary text at all.

**The fix.** `Note.subject`/`Note.level` are now real foreign keys into the same `apps.papers` taxonomy every other part of the app already uses — `Subject` and `ExamCategory` — instead of free-text `subject_title`/`academic_level` columns. In the admin, Subject proposes from the app's own subject list with a '+' to add one that's missing (Support can now do this — `papers.add_subject` only, nothing wider); Academic level proposes from the six already-defined categories with no way to add a new one, since that set is already complete. `body` (the summary text) is now required — a note with nothing to read is a placeholder, not something to publish. The public API's wire format is unchanged: `subject_title`/`academic_level` still come back as plain strings, now sourced from the FK's title.

**Backfill.** Four of the existing demo notes' subjects (Mathematics, Science, Français, Geography) had no exact match in the original 12-subject curated list — real, ordinary school subjects missing from it, not anything specific to notes, so the migration adds them rather than force-fitting a note onto the wrong subject. "Physique" (no standalone entry, only "Physique-Chimie") is aliased to the existing one instead, since a near-duplicate would be redundant. Academic-level free text ("O Level", "BEPC", "Terminale", "Seconde", …) is mapped to the real category it belongs to (all of it collapses to Secondary; "Primary"/"University" already matched a category title directly). If a future deploy has a note the migration can't match, it fails loudly rather than silently leaving a required field unset.

**Verify.** `python manage.py check` and `makemigrations --check` clean; full `apps.notes`/`apps.accounts`/`apps.papers` suites (262 tests) pass; `ruff check` clean on every touched file.

---

## 17. Papers and reports couldn't be submitted at all (staging), root-caused through four PRs

**The bug.** Every paper/report submission on staging 500'd, both upload paths (direct multipart and the presigned `storage_key` path) — reported live by a real tester. Avatar upload (`apps.accounts`, unrelated code) hit the identical crash, ruling out app-specific logic from the start.

**Why it took four PRs to find.** Staging runs `DJANGO_DEBUG=False` (correct for a public server) with no `DJANGO_ADMIN_EMAILS` set and no `SENTRY_DSN` wired into that service's `render.yaml` block — so the first real finding (#224) wasn't the bug itself, it was that **every unhandled exception on staging left zero trace anywhere**: Django's own console log handler is gated behind `require_debug_true`, and its email-the-admins fallback silently no-ops with an empty `ADMINS` list. Once that was fixed, the actual traceback showed `botocore.exceptions.ClientError: An error occurred () when calling the PutObject operation:` — which *looked* like an unparseable, empty response (leading #225's checksum-compat fix and #226's follow-up SigV4-regression fix, both real, legitimate issues in their own right, neither the actual cause). #227 added temporary wire-level debug logging specifically to stop guessing from a truncated error string — and the real response turned out to be a perfectly well-formed `<Code>SignatureDoesNotMatch</Code>` the whole time.

**Root cause (#228).** `SignedHeaders` included `baggage` and `sentry-trace` — `sentry-sdk` auto-enables its Boto3 integration whenever boto3 is importable, and by default (`trace_propagation_targets=[".*"]`) injects distributed-tracing headers into *every* outgoing HTTP call made during a request, including boto3's own SigV4-signed S3 calls. Supabase Storage's gateway recomputes the signature from what actually hits the wire and rejects it. This is also why it was unreproducible locally for most of the investigation: it only happens with an active Sentry transaction (a real deployed request), never in a `manage.py shell` session, and never on the presigned-URL leg (a separate request made by an external client, outside Django's own transaction). Fix: `trace_propagation_targets=[]` — this app has no other first-party service to maintain trace continuity with, so nothing legitimately needs these headers propagated anywhere.

**PRs.** #224 (error visibility), #225 (checksum compat — real fix, not the cause), #226 (SigV4 regression #225 introduced — real fix, not the cause), #227 (temporary debug logging, reverted by #228), #228 (the actual fix).

**Verify.** Live, not from the diff: minted a real guest token against `spekooh-staging.onrender.com` and confirmed `201` on both the direct multipart submit and the presigned `storage_key` submit, plus `200` on avatar upload — all three had been a reproducible `500` before #228.

---

## Owner decisions recorded in this stretch

| Decision | Choice |
|---|---|
| Merge credits and XP? | Yes — one balance called **Points** |
| Contribution / referral amounts | 50 / 200; quizzes 10 / 25 |
| Discount code rules | Automatic; one accumulating code; sharing stays; table hidden from the app |
| Support and notes | Support may create and update notes, not delete |
| Terms consent | Versioned, with a blocking re-accept prompt; existing users are asked once |
| Summary notes | Real text, assignable to support staff, a dashboard card; demo notes for every level |
| The "Pro" name | Replaces "Plus" everywhere users read |

## Rollout order

1. Merge #200. It is built on `main` after #199, which has already landed.
2. Staging deploys and migrates automatically. Expect: `accounts/0016`, `xp/0002–0003`, `credits/0006–0008`.
3. Check the admin: points carry-over rows, a user's Terms acceptance, one code per contributor, the tier table, and a Support account editing (but not deleting) a note.
4. Optionally run `seed_demo_notes` on staging.
5. Finish S@Learn's open items (section 1).

**Two mistakes worth remembering**
- **Stacked PRs.** #198 was stacked on #195's branch; #195 was squash-merged first, so #198 merged into a dead branch and none of it reached `main` (the "can't be automatically merged" banner). It was rebuilt as #199. Don't stack a PR on one that is about to be squash-merged; wait for it to land on `main` first.
- **CI lint.** CI runs `ruff check .` before the tests; a failing lint hides the test result behind it. Run it locally before every push.

## Rolling back

| To undo | Do |
|---|---|
| Points carry-over | `migrate xp 0002` removes only the "Carried over from bonus credits" entries |
| Discount-code backfill | `migrate credits 0007` removes the counted-paper records (codes stay; delete by hand if needed) |
| Support notes permission | `migrate accounts 0015` (this also undoes the Terms table below, which depends on it) |
| Terms versioning only | `migrate accounts 0016` drops the acceptance table (the prompt then never appears) |
| Anything else | It is code only: revert the PR |

## Open items

- Merge #200; run the S@Learn follow-ups (section 1).
- Decide whether the Terms change needs a user notice (no re-acceptance flow exists).
- Revoke the exposed Supabase token; delete the pasted API key; remove the unused `test-lab-ci-751` service account.
- Firebase Test Lab is still manual (billing blocked); cell 6 (≤2 GB RAM) has not been run.
