# Spekooh — Product & Mobile App Scope Document (v0.1 Draft)

## 1. Problem Statement

Students at all education levels and across all types of examinations struggle to find past exam papers, especially with reliable marking guides. Existing sources are scattered, informal (WhatsApp groups, photocopies), and unverified. Spekooh centralizes exam paper collection — sourced primarily from students themselves — and routes each paper through a verified instructor for validation and marking-guide creation, turning informal knowledge-sharing into a structured, incentivized pipeline.

**Scope breadth is a deliberate differentiator:** Spekooh is not limited to the Anglophone GCE system (O-Level → A-Level → HND) — it covers **every sector and every level**, meaning both the Anglophone and Francophone education systems (GCE, BEPC, Probatoire, Baccalauréat, technical/commercial tracks, etc.) and every exam type within them. This is broader than any single existing competitor in this market (see §12).

**Who is affected:** students preparing for exams (all levels, all sectors, both linguistic systems), instructors who can monetize their expertise, and — indirectly — schools/institutions that benefit from better-prepared students.

**Cost of not solving it:** students rely on unverified or incomplete papers; instructors have no channel to monetize grading expertise; no single source of truth exists for exam prep material by subject/level/sector.

---

## 2. Actors & Roles

| Actor | Platform | Core Actions |
|---|---|---|
| **Student/Contributor** | Spekooh mobile app | Submit exam papers, earn bonus credits, browse/access papers |
| **Verified Instructor** | Partner platform (connected via integration) | Accept/reject proposed papers by subject, submit marking guide within 7 days, earn convertible credits |
| **Review Team (internal)** | Admin backend | Verify submissions for duplication, **separate MCQ from non-MCQ sections and mark MCQ answer keys in-house**, review returned marking guides, merge instructor guide + in-house MCQ key, approve credit attribution, manage payouts |
| **Spekooh Admin** | Admin backend | Manage subjects/levels taxonomy, monitor credit economics, handle disputes, oversee instructor roster |

**Confirmed:** the instructor platform is a genuinely separate third-party platform. Spekooh does not own instructor registration/verification — instructors are owned and managed entirely by that third-party platform. The data-sharing contract is now clear:
- **Spekooh receives** the list/data of already-**verified** instructors (only verified ones — unverified instructors are never shared).
- **Spekooh requests**, for each paper, approval/rejection from the matched instructor **before** the paper is actually sent over for the accept/reject decision — i.e., the request itself is a formal step (not just firing off the paper), which the integration needs to model as its own state (request sent → instructor responds → paper transferred if accepted).

This still needs to be built as an external partner API/webhook contract (not an internal service call), with its own auth and versioning — but the data scope itself (verified instructors only, request-then-transfer flow) is now settled.

---

## 3. Core Functional Scope (Student/Contributor side — Mobile App)

### 3.1 Must-Have (P0)
- **Account creation & profile** (email/phone, education level, region — used for future exam board matching)
- **Paper submission flow**: upload photo/PDF/scan of exam paper, tag subject, education level, exam type, year, exam board/institution (if known)
- **First-in-first-counted duplicate detection**: system checks incoming submission against existing corpus (hash/text-similarity matching) *before* granting bonus eligibility
- **Submission status tracking**: pending review → sent to instructor → instructor accepted/rejected → marking guide received → published (visible to the submitter as simple status states, e.g. "Received," "Under Review," "Approved," "Live")
- **Bonus/credit ledger** for the submitter (visible history of what was submitted, its status, and bonus earned)
- **Browse/search papers** by level, subject, exam type, year
- **Notifications** (push/in-app) when a submission status changes
- **Bilingual UI (English + French) as v1 default** — both languages are must-have from launch, not a future add-on; all user-facing copy (app UI, email templates to instructors) needs to ship in both from day one

### 3.2 Nice-to-Have (P1)
- Leaderboard / gamification (top contributors by subject)
- Ability to flag/report an existing paper (wrong answer, mislabeled, etc.)
- Offline-saved papers for later access
- Referral bonuses
- **Pamphlet in-app purchase with escrow + physical pickup confirmation**: pamphlets are supplied by partner bookshops, but — correcting the earlier assumption — payment happens **directly in-app on Spekooh**, not on an external storefront. Confirmed flow:
  1. User selects a pamphlet and pays in-app (via Spekooh's payment integration).
  2. Spekooh **holds the payment in escrow** rather than releasing it to the partner immediately.
  3. User receives a **purchase confirmation** by email and in-app, containing a unique **QR code / ticket**.
  4. For no-delivery-fee purchases, the user takes this confirmation physically to the partner bookshop.
  5. The bookshop **scans the QR code** to confirm the handover — this needs a scanning/verification mechanism on the partner side (see below).
  6. Only once the scan confirms pickup does Spekooh **release the held payment to the partner**, minus Spekooh's commission.
  - This is a genuine escrow/marketplace pattern (similar to event-ticket or delivery-pickup verification systems) — it's a bigger engineering lift than a simple redirect and needs its own mini-spec (payment holding/ledger, QR issuance and single-use validation, partner-side confirmation interface, payout trigger). See §5.3 (revenue) and §7 (architecture) for how this slots into the rest of the system.
  - **Confirmed — delivery path:** uses the **same QR mechanism** as in-store pickup, scanned by the delivery person/courier at handover instead of bookshop staff — one system for both paths rather than building two. Fallback for couriers without a smartphone/data: the user self-confirms "I received it" in-app, with an **auto-release after 3 days** if undisputed, so payment doesn't sit stuck in escrow indefinitely on a technicality.
  - **Confirmed — QR fraud safeguards:** the QR encodes a signed, single-use token tied to the specific transaction; once scanned and confirmed, it's marked redeemed server-side, and any repeat scan (e.g., a reused screenshot) is rejected with an "already redeemed [timestamp]" message. Unredeemed tickets **expire after 30 days**, at which point the held payment is flagged for Admin review (refund or reissue) rather than sitting in escrow forever. Disputes (partner claims they scanned, user claims non-receipt, or vice versa) route to the **Admin queue** for manual resolution — the same pattern already used for the "no instructor accepts" case (§4.3) — rather than trying to automate arbitration.

### 3.3 Future Considerations (P2)
- In-app practice/quiz mode generated from paper content
- Subscription tier for premium access to marking guides
- Additional languages beyond English/French

---

## 4. Core Functional Scope (Instructor side — Partner Platform Integration)

### 4.1 Must-Have (P0)
- **Before routing to any instructor, MCQ/objective questions are stripped out of the paper.** Instructors only ever see and receive the non-MCQ sections (short-answer, calculation, essay, etc.). MCQ answer keys are marked and finalized **in-house by the Spekooh Admin/Review Team**, not by external instructors — this needs a paper-structuring step (either automatic detection during submission processing, or a manual tagging step by the Review Team) that separates a paper into its MCQ and non-MCQ components before the non-MCQ portion is sent onward.
- Spekooh sends a **request** to the matched instructor (by subject) via the partner platform, asking whether they're available/willing to take on a paper — this precedes sending the actual paper
- The request has its own short timeout (recommended 24–48 hours, separate from the 7-day marking-guide deadline); if the instructor doesn't respond in time, auto-advance to the next instructor in the subject queue (see §4.3 for the sequential-vs-parallel rationale)
- Once the instructor confirms, they receive **email** with the proposed question paper attached (non-MCQ sections only)
- Instructor can **Accept** (propose to write marking guide) or **Reject** (paper is routed to another instructor or held for re-review)
- On acceptance, instructor gets a **7-day window**, tracked by the system, to submit the marking guide back
- Reminder notifications as the 7-day deadline approaches (e.g., day 4, day 6)
- Marking guide submission returns to the **Review Team**, not directly published
- The final published marking guide combines the **in-house MCQ answer key** (from the Review Team) with the **instructor-authored guide** for the non-MCQ sections — needs a merge step before publication
- Auto-escalation/reassignment logic if instructor misses the deadline or rejects
- If **no instructor accepts** a paper (expected to be a rare edge case), the paper is flagged and routed to the **Spekooh Admin queue** for manual resolution rather than left unassigned indefinitely

### 4.2 Nice-to-Have (P1)
- Instructor dashboard showing history of accepted/rejected papers and pending credits
- Instructor rating/quality score based on Review Team feedback (affects future paper routing priority)

### 4.3 Open Questions
- **Resolved:** the case where no instructor accepts a paper is expected to be rare, but if it happens, the paper should be **flagged and escalated to the Spekooh Admin** for manual resolution (rather than an automated bounty increase or silent retry). Recommend implementing this as a simple flag/queue state (e.g., "Unassigned — needs admin review") rather than a fully automated escalation path, since the hypothesis is that this will be a low-volume edge case in practice.
- **Recommended: strictly sequential, not parallel.** Offering the same paper to two instructors at once risks both accepting and both submitting a marking guide — forcing a choice between double-paying or rejecting completed work from one instructor, which damages trust on a platform Spekooh doesn't own (§2). Recommend keeping this consistent with the "first-in-first-counted" philosophy already used for student submissions: one paper → one active instructor at a time. To avoid sequential-mode slowness, add a **short timeout on the initial request step** (§4.1) — e.g., 24–48 hours to respond — separate from the 7-day marking-guide deadline; if the instructor doesn't respond in time, auto-advance to the next instructor in the subject queue.

---

## 5. Credit & Revenue Engine (This Is the Part That Needs the Most Rigor)

This is the financial core of Spekooh and the highest-risk area of the whole product — it needs to be modeled as its own mini-spec before engineering starts.

### 5.1 Contributor bonus (student side)
- Small, fixed or tiered bonus **credit** per accepted, non-duplicate submission — this is not cash paid to the student.
- Paid/credited only after first-in-first-counted validation passes (i.e., paper wasn't already submitted).
- **Redeem code mechanic:** accumulated bonus credits can be converted into a **redeem code**, redeemable specifically as a **reduction on the pay-per-unlock price for a marking guide** (§5.3) — not cash, not airtime, not a generic voucher. The student can use it themselves or **share it with friends**, who can then apply it toward their own marking-guide unlock. This directly ties the contributor-bonus loop back into the pay-per-unlock revenue stream: contributors are effectively earning discounts on the exact product their submissions help fund.
- **Risk:** need clear anti-gaming rules — e.g., a student submitting near-duplicate or slightly-edited papers to farm bonuses. Duplicate detection needs to be content-based (OCR + text similarity), not just filename/metadata.
- **Note:** since sharing with friends is the intended behavior (not a bug to prevent), this isn't a resale risk to restrict the way a cash-equivalent voucher would be — the discount only has value when actually spent on a pay-per-unlock, so it doesn't function as a liquid, sellable asset.
- **Confirmed:** a redeem code is **fully consumed on first use** (no partial/split redemption).
- **Confirmed — tiered value & expiration:** both the code's discount value and its expiration duration scale with how many papers the contributor has submitted (e.g., a contributor at 24+ submissions gets both a higher-value code and a longer window to use it than a contributor with fewer submissions). This needs a concrete tier table before engineering (e.g., submission-count bands mapped to value % and expiration length), but the underlying rule is settled: **more contribution → more valuable, longer-lived redeem codes.**

### 5.2 Instructor credit (marking guide side)
Per your description: credit per paper is based on an **estimated marking-guide cost**, calculated per-question, and this per-question rate **fluctuates**. This needs a concrete formula before it can be engineered. Recommended structure to formalize:

```
Paper Credit = Σ (question_i base_rate × complexity_multiplier_i) 
             × subject_demand_factor 
             × urgency_factor (optional)
```

Where:
- **base_rate** — a floor rate per question (e.g., set by internal benchmarking of instructor time-cost per question type: MCQ vs. essay vs. calculation)
- **complexity_multiplier** — adjusts for question type/length/subject difficulty
- **subject_demand_factor** — fluctuates based on supply/demand of instructors and papers for that subject (this is likely the "fluctuation" you're describing) — e.g., scarce subjects (e.g., advanced physics) pay more per question than oversupplied ones
- **profit-deficit guardrail** — the sum of all attributed credits for a paper must stay under a defined ceiling (e.g., % of what the paper is expected to generate in downstream revenue — see 5.3) so the platform never pays out more than it earns per asset

**This formula needs to be owned by finance/product, not just engineering** — it's the mechanism that prevents Spekooh from bleeding money per paper. Recommend building it as a configurable rules engine (not hardcoded), so rates can be tuned per subject/region without a code release.

**Recommended starting numbers (XAF, Cameroon) — first-pass estimates to validate, not final pricing:**

*Base rate per question, by question type (reflects marking effort, not just writing effort). Note: MCQ/objective questions are excluded here — they're marked in-house by the Spekooh Admin/Review Team (§4.1), not by instructors, so they carry no instructor credit cost.*

| Question type | Base rate (XAF/question) |
|---|---|
| Short-answer / structured | 200 |
| Calculation / derivation (math, physics, chemistry) | 275 |
| Essay / long-form | 400 |

*Complexity multiplier, by education level:*

| Level | Multiplier |
|---|---|
| Primary / basic secondary | 1.0× |
| O-Level / BEPC / Probatoire | 1.2× |
| A-Level / Baccalauréat | 1.5× |
| University | 1.8× |

*Subject demand factor:* start every subject at **1.0×**, and adjust up (e.g., 1.3–1.5× for scarce subjects like Further Maths or Advanced Physics where few verified instructors are available) or down (e.g., 0.9× for high-supply subjects like general English) based on actual instructor-availability data once the partner platform integration is live. Don't hand-guess this at launch — pull it from real subject-level instructor counts.

**Worked example:** an O-Level Physics paper with 4 essay questions **sent to the instructor** (the paper's 6 MCQ questions are excluded — marked in-house by Admin, per §4.1), subject_demand_factor 1.3 (physics treated as moderately scarce):
```
4 × 400 × 1.2 = 1,920
1,920 × 1.3 = 2,496 XAF ≈ 2,500 XAF per marking guide (non-MCQ portion only)
```

**Why this matters for the profit-deficit guardrail (§5.3):** at ~2,500 XAF instructor cost per paper (down from ~3,200 XAF when MCQ was included), a single pay-per-unlock sale at, say, 300–500 XAF doesn't come close to covering it — you'd need roughly 5–8 unlocks on that paper before it's profitable on pay-per-unlock revenue alone (fewer than before, since instructors are no longer being paid for MCQ marking). This is exactly why ads and subscriptions matter as complementary revenue (§5.3): pay-per-unlock alone likely can't carry the full instructor cost per paper unless a paper is unlocked many times over its lifetime. Recommend modeling expected unlocks-per-paper (e.g., how many students will realistically want a given past paper) before finalizing these rates — a low-demand paper (e.g., a niche subject at an obscure school) may need a lower instructor rate than a high-demand one (e.g., a national exam paper), which the subject_demand_factor partially captures but may need a paper-level "expected demand" input too.

### 5.3 Where does platform revenue actually come from?
**Confirmed:** Spekooh's revenue is a hybrid of three models, combined:

| Model | Role in Spekooh's model |
|---|---|
| **Ads** | Shown on **question paper views** for non-subscribed users, and used as a rewarded-unlock mechanic once the daily free-view limit is hit |
| **Freemium + subscription (Pro)** | Paying subscribers get an ad-free experience and unlimited paper views |
| **Pay-per-unlock** | Individual **marking guides** can be unlocked for a one-off fee, separate from paper viewing — this is the piece most directly tied to the cost driver in §5.2, since a marking guide is exactly what instructors are being paid credits to produce |

**Confirmed mechanics:**
- **Daily free limit:** non-subscribed users can view **3 question papers per day** at no cost.
- **After the limit is hit:** the user must either (a) watch a rewarded ad to unlock **1 additional paper view** (not a marking guide — just the question paper itself), or (b) upgrade to the **Pro subscription** for unlimited paper views.
- **Ad placement is scoped to paper viewing, not marking guides.** Marking guides are monetized separately via pay-per-unlock (or subscription-bundled access, if that's how you resolve the open question below) and are never ad-gated.
- **Once a user has paid to unlock a specific marking guide**, they see no ads tied to that specific guide/paper going forward — but if they haven't subscribed to Pro, they still see ads (or hit the daily limit) when viewing *other* question papers. Paying to unlock one guide does not grant ad-free status platform-wide; only the Pro subscription does that.

**Ad network/SDK — not yet chosen; here's a proposal:**

| Option | Why it fits |
|---|---|
| **Google AdMob** (primary) | Broadest global fill rate and mediation support, native Flutter/React Native SDKs, and rewarded-video ad format is a first-class unit — matches the "watch an ad to unlock 1 paper" mechanic exactly |
| **AppLovin MAX or Google's own mediation** (as a mediation layer over AdMob) | Blends multiple ad networks (AdMob, Meta Audience Network, Unity Ads) to improve fill rate and eCPM — worth it once volume justifies the setup, since fill rates for a single network can be inconsistent in Cameroon specifically |
| **Meta Audience Network** (secondary, via mediation) | Complements AdMob fill rate; strong in African markets as a secondary demand source |

**Recommendation:** launch with AdMob alone (fastest to integrate, rewarded-video unit built-in) and add a mediation layer (AppLovin MAX) once you have real traffic data showing fill-rate gaps — no need to over-engineer ad infrastructure before Phase 2 pilot volume exists.

**Confirmed:** the Pro subscription removes ads and unlocks **unlimited question paper views** — it does not include marking guides. Marking guides are **always pay-per-unlock**, separately, even for Pro subscribers. This keeps the subscription and the marking-guide revenue streams fully decoupled: Pro is a paper-viewing/ad-removal product, pay-per-unlock is the marking-guide product, and the two are billed independently.

**A fourth, smaller revenue stream — pamphlets (§3.2):** **Confirmed:** Spekooh charges the partner bookshop a **commission on each pamphlet payment made through the app** — this is now a real (if likely modest) revenue stream, not just a value-add. The mechanics: payment is collected in-app and held in escrow by Spekooh; only once the partner confirms handover (via QR scan, §3.2) is the payment released to the partner — **minus Spekooh's commission**, which Spekooh keeps at the point of release. **Confirmed commission rate: 5%** of each pamphlet payment.

### 5.4 Withdrawal / cash-out (instructors only)
- P0: **instructor** can request conversion of credits → cash, above a minimum threshold. This is distinct from the student flow — students redeem via **redeem codes** (§5.1), not cash withdrawal.
- Needs: KYC/identity verification before first payout (fraud/regulatory requirement), integration with a payment rail suited to **Cameroon** (v1 target country) — Mobile Money is essential (MTN MoMo, Orange Money are the two dominant providers), plus/or bank transfer; PayPal/Stripe can stay as a secondary option for diaspora instructors
- Payout should have a review/approval step, not instant auto-payout, at least in v1

---

## 6. Non-Goals (v1)

- **No cash withdrawal for students** — students redeem bonus credits via transferable redeem codes (§5.1), not direct cash payout; cash withdrawal (§5.4) is instructor-only in v1
- **No AI-generated marking guides** — all guides are human-authored by verified instructors in v1
- **No open marketplace where any instructor can grab any paper** — routing is subject-matched and likely sequential, not a free-for-all
- **No languages beyond English/French in v1** — English and French are both confirmed as must-have default languages (see §3.1); additional languages are a future consideration only
- **No web app in v1** (mobile-first, per your framing) — though the admin/review backend will need *some* interface, likely web-based internally

---

## 7. System Architecture (High-Level)

```
┌─────────────────┐        ┌──────────────────────┐        ┌───────────────────────┐
│  Spekooh Mobile  │◄──────►│   Spekooh Backend     │◄──────►│  Instructor Platform   │
│  App (Student)   │  API   │   (API + DB + Rules   │ Email/ │  (external/partner)    │
│                  │        │   Engine + Admin)     │  API   │                        │
└─────────────────┘        └───────────┬──────────┘        └───────────────────────┘
                                        │
                ┌───────────────┬───────┼───────┬────────────────┐
                ▼               ▼       ▼       ▼                ▼
         ┌────────────┐  ┌───────────┐ ┌────────────────┐ ┌──────────────────┐
         │ Duplicate  │  │ Credit    │ │ Payment/Payout  │ │ Escrow Ledger +   │
         │ Detection  │  │ Engine    │ │ Provider (MoMo, │ │ QR Redemption     │
         │ (OCR+NLP)  │  │ (rules-   │ │ bank, PayPal)   │ │ (pamphlets,       │
         │            │  │ based)    │ │                 │ │  §3.2/§5.3)       │
         └────────────┘  └───────────┘ └────────────────┘ └──────────────────┘
                │                                                    │
                ▼                                                    ▼
         ┌────────────────┐                                  ┌──────────────────┐
         │ Object Storage │                                  │ Partner Bookshop  │
         │ (paper scans/  │                                  │ Redemption Portal │
         │  PDFs, images) │                                  │ (QR scan/confirm) │
         └────────────────┘                                  └──────────────────┘
```

### Key components
1. **Mobile app** (student-facing) — the only piece explicitly in scope as "the mobile app" per your framing
2. **Backend API** — auth, submissions, status tracking, notifications
3. **Duplicate detection service** — OCR (for scanned/photographed papers) + text similarity matching against existing corpus before bonus eligibility is confirmed
4. **Credit/rules engine** — configurable, not hardcoded (see §5.2) — this is the component most likely to need iteration post-launch
5. **Email/integration layer** — sends structured emails to instructors on the partner platform (subject, paper attachment, accept/reject links, 7-day countdown), and ingests their responses
6. **Admin/Review dashboard** (internal, likely web — not mobile) — where the Review Team verifies marking guides and approves final credit attribution
7. **Object storage** — for paper scans/PDFs (S3-compatible)
8. **Payment/payout integration** — mobile money + bank rails depending on target market
9. **Escrow ledger + QR redemption system** (new, for pamphlets — §3.2, §5.3) — tracks each pamphlet payment's state (held → redeemed → released-minus-commission), issues single-use QR codes/tickets tied to a transaction, and exposes a lightweight **partner-facing redemption interface** (recommend a simple authenticated web page the partner opens by scanning the QR, rather than a full native app for partners — much lower build cost) where bookshop staff confirm handover and trigger the payout

---

## 8. Recommended Technology Stack

| Layer | Recommendation | Why |
|---|---|---|
| **Mobile app** | Flutter (single codebase, iOS + Android) | Given the emphasis on simplicity/autodidactic UX and likely limited initial dev budget, one codebase for both platforms reduces cost and keeps UI visually consistent across iOS and Android. |
| **Backend API** | Django (Python) | Productive for CRUD + workflow-heavy apps like this, and Django's built-in admin panel is a fast way to bootstrap the internal Review Team dashboard cheaply. **Pairs with the Supabase choice (§ above) as follows:** Django connects directly to Supabase's underlying Postgres database via its ORM, rather than going through Supabase's auto-generated REST/realtime APIs — Django owns the API layer and business logic, Supabase is used primarily as managed Postgres + storage + auth infrastructure underneath it. |
| **Database** | Supabase (managed Postgres + auth + auto-generated APIs) | Same relational integrity as raw PostgreSQL underneath (submissions → instructor assignment → guide → credit ledger are all relational, auditable records), but bundles auth, row-level security, and instant REST/realtime APIs — meaningfully faster to stand up the backend than wiring Postgres, auth, and an API layer separately |
| **OCR/duplicate detection** | Tesseract/Google Cloud Vision (OCR) + a text-embedding similarity check (e.g., cosine similarity on embeddings) | Needed to catch near-duplicate submissions, not just exact file matches |
| **Object storage** | Supabase Storage | Consolidates on one provider alongside the Supabase database — one less vendor to manage, and storage buckets integrate directly with Supabase's auth/row-level security for access control on paper scans/PDFs |
| **Email delivery** | SendGrid / Postmark / AWS SES | Transactional email is core to the instructor workflow — needs high deliverability and templating |
| **Push notifications** | Firebase Cloud Messaging | Free, standard for Flutter/RN apps |
| **Ads/rewarded video** | Google AdMob (see §5.3 for full rationale and phased mediation plan) | Native rewarded-video unit matches the "watch an ad to unlock 1 paper" mechanic |
| **Payments/payouts** | Flutterwave or MTN MoMo/Orange Money direct integration (**Cameroon confirmed as v1 target country**), + Stripe/PayPal as secondary option for diaspora instructors | Flutterwave is a practical single-integration path to reach both MoMo providers in Cameroon without separate direct contracts |
| **Pamphlet escrow ledger** | Custom-built on top of Supabase's Postgres database (a transactions table with a state machine: held → redeemed → released) rather than a third-party escrow product | Escrow logic here is simple enough (single buyer, single seller, one release trigger) that a bespoke ledger table is more practical than integrating a dedicated escrow-as-a-service platform, most of which target more complex multi-party marketplace scenarios |
| **QR code generation/scanning** | A standard QR library (e.g., `qrcode` for generation server-side; scanning handled by the phone camera opening a web link — no custom scanner app needed) | Keeps the partner-side redemption interface to a simple authenticated web page rather than a native app, minimizing build cost for a feature partners will use occasionally |
| **Admin dashboard** | Django admin | Internal-only, doesn't need to be pretty, needs to be fast to build — and since the backend is already Django (§ above), the built-in admin panel comes essentially free, with model-level CRUD, permissions, and search out of the box |

**Design/branding constraint noted:** UI should follow the logo's color palette (gold/black/dark-brown tones) and use simple, clean typography — this should go into a design system doc alongside this scope, not be improvised per-screen.

---

## 9. Feasibility Assessment

| Dimension | Assessment |
|---|---|
| **Technical feasibility** | High — nothing here requires novel technology. OCR + similarity matching + rules-based credit engine are all well-understood problems. |
| **Financial feasibility** | **Unresolved — this is the biggest risk.** The credit formula (§5.2) and revenue model (§5.3) must be modeled together with real numbers (expected papers/month, expected instructor cost/paper, expected revenue/paper) before committing to a build. Recommend a small financial model (spreadsheet) as a companion artifact before development starts. |
| **Operational feasibility** | Medium risk — requires an active, responsive Review Team to keep the 7-day instructor SLA meaningful, plus ongoing instructor recruitment/verification. This is a people-ops dependency, not just software. |
| **Legal/IP feasibility** | **Flag:** exam papers are sometimes the copyrighted property of the issuing school/exam board, not the student submitting them. Worth a legal review of how "sourced from students" papers are licensed/used, especially before institutional licensing (§5.3) is pursued. |
| **Market feasibility** | **Cameroon confirmed as v1 target country.** As a bilingual (EN/FR) market this aligns naturally with the bilingual UI requirement (§3.1). Worth sizing the addressable market: number of students across the education levels you plan to cover, and number of instructors willing to register on the partner platform, before finalizing the credit budget in §5.2. |

---

## 10. Methodology Recommendation

Given this is a 0→1 product with a genuinely novel core mechanic (the credit engine), recommend:

1. **Phase 0 — Financial modeling & legal review** (spreadsheet + legal opinion, no code)
2. **Phase 1 — MVP build** (Agile, 2-week sprints): submission flow, duplicate detection (basic), instructor email flow, manual/semi-manual credit calculation (don't over-engineer the rules engine until real data exists)
3. **Phase 2 — Pilot** with a small, single-subject cohort within **Cameroon** (the confirmed v1 country) to validate the whole loop end-to-end with real instructors and real students before scaling subjects/regions
4. **Phase 3 — Scale**: automate the credit rules engine fully, expand subjects/regions, add P1 features

This avoids building the most complex piece (the fluctuating, self-balancing credit engine) at full sophistication before you have real usage data to calibrate it against.

---

## 11. Open Questions (Blocking vs. Non-Blocking)

All previously-blocking questions are now resolved. Remaining items are non-blocking and can be resolved during build:

**Non-blocking (can resolve during build):**
- **Recommendation given, pending validation:** starting base_rate/complexity_multiplier numbers for the credit formula (§5.2) — these are first-pass estimates and should be checked against real instructor time-cost data before launch
- Exact tier table mapping submission count to redeem code value and expiration length (§5.1) — start with rough bands (e.g., 24+ submissions as a first threshold), tune with real data
- **Recommendation given, pending your confirmation:** sequential instructor offers with a 24–48h request timeout (§4.3) — flag if you'd rather go a different direction
- Gamification/leaderboard details (P1, not needed for MVP)

---

## 12. Competitive Landscape

### 12.1 Named incumbent: Kawlo (cameroongcerevision.com)

Kawlo is a live, established app in this exact market (Cameroon GCE revision) and is the most directly relevant competitor to benchmark against — not a hypothetical, but a real product students in this market already have on their phones.

**What Kawlo already offers:**

| Feature | Kawlo's approach |
|---|---|
| Verified answer guides / corrections | Centrally produced, by exam level (O-Level, A-Level, Commercial GCE) and subject — **not** crowdsourced from students |
| Past papers | Organized by subject, year, paper number, with mock exams included |
| School notes | Topic-level study notes matched to GCE subjects |
| Forum | Community Q&A, tagged by subject, upvotes, answer counts |
| Quizzes | Timed practice, revision mode (no timer, hints), daily challenge, live 1v1 "Quiz battle," leaderboards, streaks/XP |
| Video lessons | Short topic videos by teachers, downloadable for offline/no-data viewing |
| Pamphlet shop | Direct in-app sale, printed/digital (7,000–7,500 FCFA) — Kawlo processes the purchase and (presumably) fulfillment itself. **Spekooh's model differs:** pamphlets are supplied by partner bookshops, but purchase still happens **in-app on Spekooh** — Spekooh holds payment in escrow, the user picks up the pamphlet in person at the partner bookshop using a QR-coded confirmation, and Spekooh releases payment to the partner (minus a commission) only once pickup is confirmed (§3.2, §5.3). Spekooh acts as the payment/escrow layer; the partner handles physical inventory and fulfillment. |
| AI assistant ("Kawlo Bot") | 20 free questions/day on free tier, unlimited on paid tier |
| Monetization | **Kawlo Plus subscription: 500 FCFA/month** — unlimited downloads, unlimited AI, ad-free; ads shown to free-tier/guest users; guest browsing allowed with no account required for reading content |
| Account gating | Reading (papers, corrections, notes, quizzes) stays open to guests; account required only for streaks/XP, forum posting, video competitions, cross-device download sync |
| **Sector/level coverage** | **Anglophone system only** — GCE O-Level through A-Level, Commercial GCE, up to HND. No Francophone system content (no BEPC, Probatoire, Baccalauréat) and no coverage beyond this specific track. |

### 12.2 What this validates for Spekooh's scope

- **The ads + freemium/subscription hybrid (§5.3) is already proven in this exact market** — Kawlo's 500 FCFA/month price point is a useful anchor for Spekooh's own Pro subscription pricing. Worth benchmarking Spekooh's Pro price against this rather than picking a number in a vacuum.
- **Guest-first, account-optional browsing** is a pattern worth adopting for Spekooh's non-contributor students too — Kawlo lets anyone read freely and only gates account-requiring features (streaks, posting, sync). This fits Spekooh's stated "simple, autodidactic" design goal (intro) well.

### 12.3 Where Spekooh actually differentiates

Kawlo already covers "verified answer guides + past papers + notes + quizzes" — so **that alone is not Spekooh's wedge**; Spekooh would be entering as a me-too on that surface if it stopped there. Spekooh has **two real differentiators**, not one:

1. **Scope breadth.** Kawlo serves the Anglophone sector only (GCE through HND). Spekooh is scoped for **every sector and every level, both Anglophone and Francophone systems, every exam type** (§1) — a substantially larger addressable market within Cameroon alone, before even considering expansion beyond it. This alone is a meaningful wedge even if the underlying feature set looked identical.
2. **Supply-side mechanic**, which Kawlo does not have at all:
   - Crowdsourced paper collection directly from students, with a bonus/redeem-code incentive loop (§5.1)
   - A structured instructor pipeline (accept/reject → 7-day marking guide → credit payout, §4) that turns instructor expertise into a monetizable, on-demand service
   - This positions Spekooh less as "another GCE revision app" and more as **the supply chain that could, in principle, also feed content into apps like Kawlo** (licensing angle) or compete directly on freshness/coverage of papers Kawlo doesn't have yet.

**Recommendation:** lead positioning with both — the broader sector/level coverage (reaching Francophone students Kawlo doesn't serve at all) and the contribution/instructor pipeline as the mechanism that makes covering that much broader scope actually feasible without Spekooh having to centrally produce every guide itself the way Kawlo does.

### 12.4 P2 idea worth flagging (not scope for v1)

Kawlo's lightweight gamification (streaks, leaderboards, live 1v1 quiz battles) is a proven retention pattern in this exact user base. Spekooh's §3.3 already lists "leaderboard/gamification" as P2 — this is a signal that it's worth revisiting post-MVP rather than dismissing, though it should stay lightweight to not conflict with the "simple, autodidactic" design goal.



---

## Next Steps

Happy to go deeper on any single section — e.g., turn §5 (credit engine) into its own detailed spec with the actual formula worked out, or turn §7/§8 into a full technical architecture document with data models and API contracts. Let me know which piece to expand first.
