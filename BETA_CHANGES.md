# Beta changes log — 2026-09-28

Every change made in this stretch of work, why it was made, where it lives, how to check it, and what it does to real data. Written for the owner, and for whoever deploys next.

**Read this first**

- **Merge order matters** — see "Rollout order" at the bottom. Two earlier mistakes are recorded there so they don't repeat.
- **Three migrations change real data when staging deploys** (staging runs `migrate` on every deploy): the credit → points carry-over (`xp/0003`), the discount-code backfill (`credits/0008`), and the Support notes permission (`accounts/0016`). Each is idempotent and reversible; details in each section. **None has been applied to any database yet.**
- Production is still documented as not deployed (`RENDER_PRODUCTION.md`), so none of this has reached real users.

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

---

## Owner decisions recorded in this stretch

| Decision | Choice |
|---|---|
| Merge credits and XP? | Yes — one balance called **Points** |
| Contribution / referral amounts | 50 / 200; quizzes 10 / 25 |
| Discount code rules | Automatic; one accumulating code; sharing stays; table hidden from the app |
| Support and notes | Support may create and update notes, not delete |
| The "Pro" name | Replaces "Plus" everywhere users read |

## Rollout order

1. Merge #200 **after** #199 (already merged) (it is built on `main` as it stands now).
2. Staging deploys and migrates automatically. Expect: `accounts/0016`, `xp/0002–0003`, `credits/0006–0008`.
3. Check the admin: points carry-over rows, one code per contributor, the tier table, and a Support account editing (but not deleting) a note.
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
| Support notes permission | `migrate accounts 0015` |
| Anything else | It is code only: revert the PR |

## Open items

- Merge #200; run the S@Learn follow-ups (section 1).
- Decide whether the Terms change needs a user notice (no re-acceptance flow exists).
- Revoke the exposed Supabase token; delete the pasted API key; remove the unused `test-lab-ci-751` service account.
- Firebase Test Lab is still manual (billing blocked); cell 6 (≤2 GB RAM) has not been run.
