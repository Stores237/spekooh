# Spekooh — Developer README

This README is the build guide for engineers implementing the Spekooh mobile app and backend. It distills the full product scope (`spekooh_scope.md`) into what you actually need to start writing code: confirmed stack, data model, business rules, state machines, and API surface. **When in doubt about *why* a rule exists, check the referenced section (§) in the scope doc — this README states *what* to build, the scope doc explains *why*.**

---

## 1. What Spekooh Is (one paragraph)

Spekooh crowdsources exam papers from students **and individuals more broadly** — anyone who can contribute any exam paper type available in Cameroon, not students alone (all levels, all sectors, Anglophone + Francophone systems, Cameroon v1), routes each paper to a verified instructor on a separate third-party platform for marking-guide creation, and monetizes through ads + a Pro subscription + pay-per-unlock marking guides + a commission on partner pamphlet sales. Contributors earn bonus credits (redeemable as discount codes) for contributing; instructors earn convertible cash credits for marking guides.

---

## 2. Confirmed Tech Stack

| Layer | Choice |
|---|---|
| Mobile app | **Flutter** (single codebase, iOS + Android) |
| Backend API | **Django** (Python) — owns API/business logic, connects to Supabase's Postgres via ORM (not through Supabase's auto-generated APIs) |
| Database | **Supabase** (managed Postgres + auth + row-level security) |
| Object storage | **Supabase Storage** (paper scans, PDFs) |
| OCR / duplicate detection | Tesseract or Google Cloud Vision (OCR) + text-embedding cosine similarity for near-duplicate matching |
| Email delivery | SendGrid / Postmark / AWS SES (transactional — core to the instructor workflow) |
| Push notifications | Firebase Cloud Messaging |
| Ads / rewarded video | Google AdMob (launch); add AppLovin MAX mediation later if fill rates are weak |
| Payments / payouts | Flutterwave (covers MTN MoMo + Orange Money in one integration) + Stripe/PayPal as secondary for diaspora instructors |
| Pamphlet escrow ledger | Custom table on Supabase Postgres (not a third-party escrow product) |
| QR generation/scanning | Standard server-side QR library; scanning = phone camera opening a web link, no native scanner app |
| Admin dashboard | Django admin (free, comes with the backend choice) — doubles as the internal ticketing system (§4, `AdminFlagQueue`/`Ticket`) rather than integrating a separate Jira/Linear tool |
| Target market (v1) | **Cameroon** — bilingual EN/FR UI is P0, currency is **XAF** |

---

## 3. Architecture

```
┌─────────────────┐        ┌──────────────────────┐        ┌───────────────────────┐
│  Spekooh Mobile  │◄──────►│   Django Backend      │◄──────►│  Instructor Platform   │
│  App (Flutter)   │  REST  │   (API + Rules        │ Email/ │  (external/partner —   │
│                  │        │   Engine + Admin)      │  API   │  Spekooh doesn't own   │
└─────────────────┘        └───────────┬──────────┘        │  instructor data)      │
                                        │                    └───────────────────────┘
                ┌───────────────┬───────┼───────┬────────────────┐
                ▼               ▼       ▼       ▼                ▼
         ┌────────────┐  ┌───────────┐ ┌────────────────┐ ┌──────────────────┐
         │ Duplicate  │  │ Credit    │ │ Payment/Payout  │ │ Escrow Ledger +   │
         │ Detection  │  │ Engine    │ │ Provider        │ │ QR Redemption     │
         │ (OCR+NLP)  │  │ (rules-   │ │ (Flutterwave)   │ │ (pamphlets)       │
         │            │  │ based)    │ │                 │ │                   │
         └────────────┘  └───────────┘ └────────────────┘ └──────────────────┘
                │                                                    │
                ▼                                                    ▼
         ┌────────────────┐                                  ┌──────────────────┐
         │ Supabase        │                                  │ Partner Bookshop  │
         │ Storage         │                                  │ Redemption Portal │
         │ (scans/PDFs)    │                                  │ (QR scan/confirm) │
         └────────────────┘                                  └──────────────────┘
```

**Golden rule for the instructor integration:** the instructor platform is a genuine external third party. Spekooh never owns instructor accounts. Every interaction is request/response over a webhook/API contract, never a direct DB join. Build this integration behind an interface/adapter layer from day one — you will need auth, versioning, and retry handling that an internal call wouldn't need.

---

## 4. Core Data Model (sketch)

This is not a final schema — it's the entity list and relationships an engineer needs to start modeling in Django.

```
User (student/contributor)
├─ id, name, email/phone, education_level, region, language_pref (en/fr)
├─ account_type: guest | registered   (guest browsing allowed, per Kawlo-benchmark pattern)
└─ 1:N → PaperSubmission, CreditLedgerEntry, RedeemCode, PaperUnlock, Subscription, PamphletOrder

PaperSubmission
├─ id, subject, education_level, exam_type, exam_board, year, submitted_by (User), status
├─ file_ref (Supabase Storage), ocr_text, duplicate_hash
├─ status: PENDING_REVIEW → INSTRUCTOR_REQUEST_SENT → INSTRUCTOR_ACCEPTED / INSTRUCTOR_REJECTED
│           → AWAITING_MARKING_GUIDE → GUIDE_SUBMITTED → MERGED → PUBLISHED
│           (or → UNASSIGNED_ADMIN_QUEUE if no instructor accepts)
├─ mcq_section (JSON/ref) — split out, handled in-house by Review Team, never sent to instructor
├─ non_mcq_section (JSON/ref) — the only part sent to the instructor
└─ 1:1 → MCQAnswerKey, 1:1 → InstructorMarkingGuide, 1:1 → PublishedGuide (merge of both)

InstructorRequest  (tracks the request-BEFORE-transfer step — see §4.1 of scope doc)
├─ paper_id, instructor_id (external ref, not a local User), sent_at, responds_by (sent_at + 24-48h)
├─ status: PENDING → CONFIRMED → PAPER_SENT → ACCEPTED / REJECTED / TIMED_OUT
└─ on TIMED_OUT or REJECTED → system auto-creates the next InstructorRequest for the next
   instructor in the subject queue (strictly sequential — never two open requests for one paper)

InstructorMarkingGuide
├─ paper_id, instructor_id (external ref), submitted_at, deadline (accepted_at + 7 days)
└─ status: IN_PROGRESS → SUBMITTED → UNDER_REVIEW → APPROVED / REJECTED_BACK_TO_INSTRUCTOR

MCQAnswerKey
└─ paper_id, authored_by (Review Team user), content

CreditLedgerEntry (contributor bonus credits — NOT cash)
├─ user_id, paper_submission_id, amount, reason, created_at

RedeemCode
├─ user_id (owner), value_percent, expires_at, status: ACTIVE | REDEEMED | EXPIRED
├─ tier_at_issuance (based on contributor's total accepted submission count — 24+ threshold band)
└─ can be applied by a *different* user at redemption time (shareable), but fully consumed on first use

InstructorCreditLedger (instructor credits — convertible to cash)
├─ instructor_id (external ref), paper_submission_id, amount (from credit formula, §5.2), created_at

WithdrawalRequest (instructors only)
├─ instructor_id, amount, kyc_status, payout_method (MoMo/Orange Money/bank), status: PENDING → APPROVED → PAID

Subscription (Pro tier)
├─ user_id, status: ACTIVE | EXPIRED, renews_at
└─ grants: ad-free + unlimited paper views. Does NOT grant marking-guide access (always pay-per-unlock).

PaperUnlock (pay-per-unlock — marking guides only)
├─ user_id, paper_submission_id, amount_paid, redeem_code_applied (nullable), unlocked_at

PaperViewLog (drives the daily free-view limit)
├─ user_id, paper_submission_id, viewed_at
└─ used to compute "views today" against the free limit of 3; reset daily

AdWatchEvent
├─ user_id, paper_submission_id, watched_at → grants +1 paper view

Pamphlet (catalog item, supplied by partner bookshop)
├─ id, partner_id, title, price, level, subject

PamphletOrder  (escrow state machine — see §5 below)
├─ id, user_id, pamphlet_id, partner_id, amount, commission_amount (5%)
├─ qr_token (signed, single-use), expires_at (30 days if unredeemed)
├─ fulfillment_type: PICKUP | DELIVERY
└─ status: PAID_HELD → REDEEMED → RELEASED  |  EXPIRED_FLAGGED | DISPUTED

AdminFlagQueue / Ticket  (general-purpose internal ticketing for the Review Team — not just
                          the no-instructor-accepted and pamphlet-dispute cases; every event
                          needing Review Team action creates a ticket)
├─ subject_type: PAPER_VERIFICATION | INSTRUCTOR_ESCALATION | GUIDE_REVIEW | PAMPHLET_DISPUTE
│                | WITHDRAWAL_APPROVAL, subject_id, reason
├─ status: NEW → IN_PROGRESS → RESOLVED, assignee (Review Team member)
├─ created_at, age (surfaced in Django admin — matters given 7-day/30-day SLAs elsewhere)
└─ Build as an internal Jira-lite on Django admin, not a third-party Jira/Linear integration
   for v1 — cheaper, tailored to Spekooh's exact workflow, no second source of truth to sync.
   Revisit only if the Review Team scales past what Django admin's UI can comfortably handle.
```

---

## 5. Business Rules & State Machines Engineers Must Get Right

These are the pieces where a shortcut now creates real financial or trust problems later. Read the referenced scope-doc section before implementing.

### 5.1 Duplicate detection (§3.1)
Must be **content-based** (OCR + text-embedding similarity), not filename/metadata matching. A submission only earns bonus credit if it passes this check. Near-duplicate farming (resubmitting a lightly edited paper) is the main abuse vector — similarity threshold needs tuning, not a hardcoded exact-match check.

### 5.2 MCQ/non-MCQ split (§4.1)
Every paper must be split into MCQ and non-MCQ sections **before** any instructor routing happens. Instructors never see MCQ content. MCQ answer keys are authored in-house by the Review Team. The published guide is a **merge** of both — don't publish the instructor's guide alone; it's incomplete without the MCQ key.

### 5.3 Sequential instructor routing with timeout (§4.1, §4.3)
- One paper → one active `InstructorRequest` at a time. Never fan out to multiple instructors simultaneously (double-payment/trust risk).
- Request timeout: 24–48h to respond → auto-advance to next instructor in subject queue.
- Marking-guide deadline: 7 days from acceptance, with reminders at day 4 and day 6.
- If the subject queue is exhausted with no acceptance → flag to `AdminFlagQueue`, don't leave it silently unassigned.

### 5.4 Credit formula (§5.2) — implement as a **configurable rules engine**, not hardcoded constants
```
Paper Credit = Σ (question_i base_rate × complexity_multiplier_i) × subject_demand_factor
```
Starting values (XAF, first-pass — validate against real instructor time-cost data):

| Question type | Base rate |
|---|---|
| Short-answer / structured | 200 |
| Calculation/derivation | 275 |
| Essay / long-form | 400 |

| Level | Multiplier |
|---|---|
| Primary/basic secondary | 1.0× |
| O-Level / BEPC / Probatoire | 1.2× |
| A-Level / Baccalauréat | 1.5× |
| University | 1.8× |

`subject_demand_factor` starts at 1.0× for every subject — **do not hand-guess this**, derive it from real instructor-availability counts once the partner integration is live. MCQ questions are excluded entirely from this formula (no instructor cost — see 5.2 above).

### 5.5 Redeem code tiering (§5.1)
- Redeem codes are **fully consumed on first use** — no partial/split redemption.
- Value and expiration scale with the contributor's total accepted-submission count (e.g., 24+ submissions = a first threshold band). The exact tier table (submission count → % value → expiration length) is still a rough estimate — build the lookup as a config table, not inline logic, so it can be tuned.
- A code is only ever redeemable as a **discount on a `PaperUnlock` transaction** — never cash, never airtime.

### 5.6 Free-view paywall (§5.3)
- 3 free question-paper views/day for non-subscribed users (tracked via `PaperViewLog`, reset daily).
- On hitting the limit: user can watch a rewarded ad (`AdWatchEvent` → +1 view) or subscribe to Pro.
- Ads are scoped to paper viewing only — never shown on marking-guide unlock flows.
- Pro subscription ($/XAF TBD, benchmark against Kawlo's 500 FCFA/month) grants unlimited paper views + no ads. It does **not** grant marking-guide access — that's always a separate `PaperUnlock` even for subscribers.

### 5.7 Pamphlet escrow + QR redemption (§3.2, §5.3) — real money, needs care
1. User pays in-app → `PamphletOrder` created with status `PAID_HELD`.
2. Confirmation (email + in-app) includes a **signed, single-use QR token**.
3. Redemption (pickup at bookshop *or* delivery handover — same mechanism, different scanner) → partner/courier opens an authenticated web page by scanning the QR → confirms handover → order moves to `REDEEMED` → payment auto-releases to partner **minus 5% commission** → status `RELEASED`.
4. **Fraud/edge-case handling (must implement, not optional):**
   - Repeat scan of an already-redeemed QR → reject with "already redeemed [timestamp]," do not re-release funds.
   - Unredeemed after 30 days → auto-flag to `AdminFlagQueue` for refund/reissue decision — don't let it sit in `PAID_HELD` forever.
   - No smartphone/data available for courier confirmation → user can self-confirm "I received it" in-app, with **auto-release after 3 days** if undisputed.
   - Any dispute (partner says redeemed, user says not received, or vice versa) → route to `AdminFlagQueue`, resolve manually. Do not build automated arbitration for v1.

---

## 6. API Surface (high-level — Django REST Framework)

Not exhaustive, but the groupings an engineer should scaffold first:

```
/api/auth/*                      → via Supabase Auth (Django validates the token)

/api/papers/                     → GET (browse/search), POST (submit)
/api/papers/{id}/                → GET detail, status
/api/papers/{id}/unlock/         → POST — pay-per-unlock a marking guide (applies redeem code if given)
/api/papers/{id}/view/           → POST — logs a PaperViewLog entry, enforces daily limit
/api/papers/{id}/ad-unlock/      → POST — grant +1 view after confirmed ad watch

/api/instructor-webhook/         → inbound from partner platform: accept/reject responses,
                                    marking-guide submissions. Auth via partner API key/signature.

/api/credits/                    → GET — contributor's bonus credit ledger
/api/redeem-codes/               → GET (owned codes), POST /redeem/ (apply to an unlock)

/api/instructor/credits/         → GET — instructor's earned credit ledger (via partner-authenticated call)
/api/instructor/withdraw/        → POST — withdrawal request (instructor side)

/api/subscriptions/              → POST (start Pro), GET (status)

/api/pamphlets/                  → GET (catalog)
/api/pamphlets/{id}/order/       → POST — creates PamphletOrder, initiates payment + escrow hold
/redeem/{qr_token}/              → NOT under /api/ — a partner-facing authenticated WEB PAGE
                                    (not JSON), opened by scanning the QR. Confirms handover,
                                    triggers release. Keep this dead simple — one button, no app needed.

/admin/                          → Django admin (Review Team + Spekooh Admin use this directly,
                                    not custom-built screens, for v1)
```

---

## 7. Localization (P0, not P1)

English and French are both must-have from day one — this includes:
- All UI copy in the Flutter app (use a proper i18n framework, e.g. `easy_localization` or `flutter_localizations` + `.arb` files — don't hardcode strings anywhere)
- Instructor-facing email templates (both languages)
- Push notification copy

Do not treat French as a "translate later" pass — build the i18n scaffolding into the app from the first screen.

---

## 8. Environment / Config Checklist

```
SUPABASE_URL / SUPABASE_SERVICE_KEY
DJANGO_SECRET_KEY
SENDGRID_API_KEY (or Postmark/SES equivalent)
FCM_SERVER_KEY (push notifications)
ADMOB_APP_ID / ADMOB_REWARDED_UNIT_ID
FLUTTERWAVE_PUBLIC_KEY / FLUTTERWAVE_SECRET_KEY
INSTRUCTOR_PLATFORM_API_KEY / INSTRUCTOR_PLATFORM_WEBHOOK_SECRET
DEFAULT_CURRENCY=XAF
DEFAULT_LOCALES=en,fr
```

---

## 9. Build Order (maps to scope doc §10 methodology)

1. **Phase 0 (no code):** finance builds the real unit-economics model around the credit formula (§5.4 above) and revenue mix; legal reviews exam-paper copyright/licensing risk. Don't start Phase 1 until this exists.
2. **Phase 1 (MVP, Agile 2-week sprints):**
   - Paper submission + duplicate detection (basic threshold, not fully tuned)
   - MCQ/non-MCQ split + instructor request/accept/reject/timeout flow
   - Manual/semi-manual credit calculation (don't fully automate the rules engine yet — real data doesn't exist)
   - Basic paywall (3 free views, ad unlock, Pro subscription)
   - Pamphlet escrow + QR flow can be P1.5 — sequence it after core submission/instructor loop is proven, since it's a self-contained subsystem
3. **Phase 2 (Pilot):** single subject, Cameroon only, real instructors + real contributors, end-to-end validation before scaling subjects.
4. **Phase 3 (Scale):** fully automate the credit rules engine using real data, expand subjects, add P1 features (leaderboard, offline saves, referral bonuses).

---

## 10. Explicitly Out of Scope for v1 (don't build these yet)

- Cash withdrawal for contributors (they get redeem codes, not cash — §5.5)
- AI-generated marking guides (human instructors only)
- Parallel/open-marketplace instructor assignment (must be sequential — §5.3)
- Any language beyond English/French
- A web app (mobile-first; admin uses Django admin, not a custom web frontend)

---

## 11. Where to Go for More Detail

This README intentionally strips out the *rationale*, competitive analysis, and open-question tracking. For that, see `spekooh_scope.md` — specifically §5 (credit/revenue engine deep dive), §9 (feasibility risks), and §12 (competitive landscape vs. Kawlo) before making any change to pricing, credit formula, or monetization logic.
