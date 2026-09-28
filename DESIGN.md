# DESIGN.md — Spekooh design rules

Read this before any visual or UI decision. Do not deviate without explicit owner approval. In QA, flag anything that doesn't match it.

**Scope:** the Spekooh mobile app (Flutter, `app/`) and the Django admin (`backend/`, django-unfold). S@Learn is a separate product with its own `DESIGN.md` in its own repo — don't mix the two.

## Where the truth lives

| What | Where | Notes |
|---|---|---|
| Design tokens (colors, type, spacing, radii, shadows, gradients) | `app/lib/theme/*.dart` | **Authoritative.** Ported 1:1 from `tokens/*.css`. |
| The design system's story: voice, visual foundations, iconography | `README.md` (repo root) | Narrative source for this file. |
| Reusable widgets | `app/lib/widgets/` | `components/` and `ui_kits/spekooh-app/` are the original JSX references. |
| Specimen cards | `guidelines/*.card.html` | Visual reference for colors, type, spacing, radius. |
| Admin theme | `backend/config/settings/base.py` (`UNFOLD`) and `backend/apps/core/static/core/admin-theme.css` | Same palette and font as the app. |

If code and README disagree on a value, **the code wins**, and this file gets updated in the same PR. The README was derived from screenshots (its own caveats say so); the tokens are what ships.

## Principles

1. **One interactive color: gold**, taken from the logo cube. Everything warm — ink instead of navy, olive green, warm mauve, warm red-orange. Never introduce a cool blue/gray.
2. **Shadows separate, borders don't.** Cards are white with a soft shadow. 1px borders appear only on outline buttons, dividers and the search input.
3. **Round everything.** Cards 18–22px, icon chips 12px, buttons and pills fully round. Nothing is sharp-cornered.
4. **Flat backgrounds.** No textures, patterns, illustrated backdrops or photo heroes. Pamphlet covers are the only full-bleed imagery.
5. **Plain, honest, local.** Copy is direct and reassuring for students on patchy data. Numbers are stated plainly. Never a fabricated number or placeholder — show the real value or an honest empty state.
6. **A ladder, not a wall.** Reading stays open to guests; locked perks are small and framed as "sign up when you want to…".

## Color

| Token | Hex | Use |
|---|---|---|
| `ink900` / `ink800` / `ink700` | `#241A08` / `#362610` / `#4A3418` | Headings, primary text, dark surfaces |
| `gold50` | `#FBF3E1` | Light tint fills |
| `gold200` | `#EFCD83` | Soft accents |
| `gold400` | `#E2A52A` | Outline borders, gradient start |
| `gold500` | `#C8881C` | Primary accent, links on light |
| `gold600` | `#A8721A` | Deeper accent |
| `gold700` | `#835611` | Link text, gradient end |
| `green500` / `green600` / `green100` | `#6FA23A` / `#4C7A34` / `#EAF1D9` | Success, learning |
| `purple500` / `purple600` / `purple100` | `#A6709B` / `#7D5474` / `#F1E4EE` | Warm mauve accent |
| `red500` / `red100` | `#D1603C` / `#FBE3D8` | Danger, errors |
| `flameSpark` / `flameEmber` / `flameInferno` | `#D08400` / `#E06A1F` / `#D93A2B` | Earned streak flames, yellow → orange → red by tier |
| `surfaceBg` / `surfaceCard` / `surfaceSunken` | `#F7F4EE` / `#FFFFFF` / `#FBF8F2` | Screen, card, inset backgrounds |
| `borderSubtle` | `#EAE2D2` | Hairlines |
| `textPrimary` / `textSecondary` / `textTertiary` | `#241A08` / `#6B6155` / `#9C9184` | Text on light |
| `textOnDark` / `textOnDarkMuted` | `#FFFFFF` / `#D9C79A` | Text on ink or gold |

`blue*` and `amber*` are legacy names that **alias the gold ramp**. Use `gold*` in new code.

**Gradients** are stops along the same gold ramp, so nothing reads as an unrelated color. CTAs use a gradient, never a flat fill.

| Gradient | Stops | Use |
|---|---|---|
| `primary` | gold400 → gold700 | Main buttons, hero cards |
| `bot` | gold200 → gold600 | AI / Spekooh Bot accents |
| `goldSoft` | gold50 → gold200 | Soft surfaces |
| `goldDeep` | gold500 → gold700 | Rich accents, status marks |

## Typography

One typeface throughout: **Plus Jakarta Sans** (a flagged substitution — swap in the real font if one is supplied). No serif anywhere.

| Style | Size | Weight | Line height |
|---|---|---|---|
| display | 28 | 800 | 1.2 |
| h1 | 22 | 700 | 1.2 |
| h2 | 19 | 700 | 1.2 |
| h3 | 17 | 600 | 1.2 |
| body | 15 | 400 | 1.4 |
| bodySm | 13 | 400 | 1.4 (secondary text color) |
| caption | 11 | 600 | 1.4, +0.06 tracking (tertiary text color) |

Section labels are **uppercase, tracked caps** at caption size ("LANGUAGE", "PRACTICE MODE"). Everything else is sentence case.

## Spacing, layout, radii, elevation

- **4px base rhythm:** `space1`–`space9` = 4, 8, 12, 16, 20, 24, 32, 40, 48. Screen padding is `16`. Gaps inside stacked cards are 8–14. Leave generous space between grouped sections.
- **The floating AI assistant button** sits bottom-right on every logged-in tab. Scrollable tab bodies use `AppSpacing.fabClearance` (96) as bottom padding, and any bottom-right control uses `AppSpacing.fabHorizontalClearance` (76) as its right offset, or the two overlap and block taps (found live at 390px, 2026-09-14).
- **Radii:** `sm` 8 · `md` 12 · `lg` 18 · `xl` 22 · `chip` 12 · `pill` 999. Outer cards are `lg`/`xl`.
- **Elevation:** `card` (default), `cardHover`, `sheet`, `button`. The shadow tints are leftover cool-navy values kept verbatim from the source token file; don't "fix" them piecemeal.
- Grouped list rows live **inside one card**, divided by hairlines, never one card per row.

## Components (as built)

- **`SpekoohButton`** — the only button shape: a pill. Variants: `primary` (gold gradient, white bold text, button shadow), `secondary` (gold50 fill, gold500 text), `outline` (gold400 1.5px border), `ghost` (plain text, no padding), `dark` (ink900 fill). Sizes `sm`/`md`/`lg`. Disabled = 50% opacity. Press = scale to 0.97 over 120ms, **no color change**.
- **`SpekoohBadge`** — uppercase pill tag for metadata ("MOCK", "3 papers"). Tones: blue (gold), amber, green, neutral, dark. Flat fill.
- **`IconChip`** — tinted rounded square around one line icon; precedes almost every list-row title. Tints: blue, amber, green, purple, red, gold.
- **Status marks** — a status the user *has* (rather than a count) uses a gradient pill with an icon, so it doesn't read as another metadata tag. Spekooh Pro members get a gold `goldDeep` **PRO** pill with a crown beside their name on Profile (`app/lib/widgets/pro_badge.dart`).
- **Bottom sheets** slide up over a dimmed, slightly blurred backdrop. This is the only blur in the product.
- Also in `widgets/`: bottom nav, segmented tabs, list row, stat row, subject card, search input, toggle, banner, avatar, loader.

## Iconography

**Line icons inside tinted rounded-square chips** — never bare on a plain background, never emoji, never PNG icon sets. The app uses Lucide (`lucide_icons_flutter`): outlined, thin-to-medium stroke, rounded joins. The one custom glyph is the Spekooh Bot mark (a sparkle in a speech-bubble on a gold gradient); treat it as brand IP. The logo is the gold 3D cube "S" mark; no flat wordmark exists.

## Content and copy

- **Voice:** plain, direct, reassuring, second person ("you"). Casual register. The AI helper "explains it like a big brother would" — warm and local, not corporate-AI.
- **No emoji in UI copy.**
- **Bilingual, always.** Every user-visible string goes in **both** `app/lib/l10n/app_en.arb` and `app_fr.arb`, then run `flutter gen-l10n` (the generated `app_localizations*.dart` are committed). Tests cover both languages for anything new.
- **Money is explicit and local:** FCFA amounts and MTN MoMo / Orange Money named directly on the button or row, with a plain trust line under payment CTAs.
- **The paid tier is called "Pro"** ("Spekooh Pro", badge "PRO"). The code flag `isPlusSubscriber` is a legacy name — never show "Plus" to a user.
- **There is one reward balance, and it is called Points.** Users never see "credits", "bonus credit" or "XP". It is earned from quizzes (10, or 25 for the daily challenge), an accepted paper (50) and a referral (200) — the last two are editable by ops in the admin — and spent at 500 points for +1 offline download slot for 3 days. Discount codes are a **separate reward, earned automatically** when a contributor's paper is accepted; they are not bought with points and cannot be requested, so don't describe them as either. A contributor has **one** code at a time, and each newly accepted paper upgrades that same code in place (higher discount when a new tier is reached, later expiry) instead of creating another. Show the user their code, its discount and when it expires, and **never the tier table**: it is an ops setting, kept out of the app on purpose. Internal names keep `xp` (the `XPLedgerEntry` table, the `xp_balance` API field) so older app builds keep working; only what users read says "points". Instructor payouts are a different, cash-based economy and keep the word "credits".
- **Practice mode is the summary notes,** not the papers list: it opens Notes, and its copy says "summary notes".

## Motion and states

Buttons shrink slightly on press; sheets slide up. Mobile-only product, so no hover states. List rows show no pressed background beyond the chevron. Any other easing or duration is **undefined** — ask before inventing one.

## Admin (Django, django-unfold)

The admin wears the same brand: site title "Spekooh Admin", subheader "Review & ops".
- **Palette:** Unfold's `primary` ramp is the gold ramp (50 `#FBF3E1` … 700 `#835611`, with interpolated 100/300/800–950); `base` is the warm neutral ramp (50 `#F7F4EE` surface, 200 `#EAE2D2` border, 900 `#241A08` ink). Border radius `0.75rem`.
- **Font:** Plus Jakarta Sans, self-hosted (`admin-theme.css`) so the admin has no external font dependency.
- **Sidebar and dashboard follow the signed-in staff member's role and permissions** — a role never sees sections it can't use. New admin models need real permissions, not template-level hiding.
- Name admin sections for what the person does, not for the Django model (see the "Staff Roles" rename).

## Working on UI

- CI runs `flutter analyze` and `flutter test`; both must pass. There is no formatter gate — match the surrounding file's style.
- Widget tests run on an 800×600 surface. If you add content to a scrolling screen, existing tests that tap below it must `ensureVisible` first.
- Reach for the token classes and existing widgets before writing new decoration. New colors, radii or shadows need owner approval and a row in the log below.

## Decision log

| Date | Decision |
|---|---|
| 2026-09-14 | Floating AI button clearance constants added after it covered a sponsor card and the Forum "Ask" pill at 390px. |
| 2026-09-16 | QR Vault is its own card beside the points card on Profile, not a badge on top of it. |
| 2026-09-21 | Earned streak flames colored yellow → orange → red by tier; locked flames stay grey. |
| 2026-09-28 | Practice mode opens Notes; Pro members get a PRO badge and no upsell row; the paid tier is named "Pro" everywhere. |
| 2026-09-28 | Credits and XP merged into one balance, **Points**: one ledger, 50 per accepted paper, 200 per referral, quizzes unchanged; existing credit balances carried over 1:1. Chosen over explaining two currencies because credits had nothing to spend them on and two balances hurt the app's "simple for every level" goal. |
| 2026-09-28 | Discount codes are earned automatically, one accumulating code per contributor (one accepted paper = one count, tier by total accepted papers: 1–4 → 5%/7 days, 5–14 → 10%/14 days, 15–23 → 15%/21 days, 24+ → 20%/30 days). The old open "request a code" endpoint is removed. The tier table is deliberately not shown in the app. Sharing a code stays allowed. |
| 2026-09-28 | Terms re-acceptance: the server holds the Terms version and each account's acceptances; when the version is bumped (material changes only) signed-in users get a blocking "We've updated our Terms" dialog with Read / tick to agree / Log out. Guests are never asked. A wording fix does not bump it. |
| 2026-09-28 | A summary note is readable: tapping a note in the list opens it (title, level, then paragraphs, headings and bullets); a note with no text yet says "The text for this note isn't available yet." instead of an empty page. |
| 2026-09-28 | Anything that looks live but isn't says so, right where it matters. Payments are simulated, so every payment screen shows "Test mode: payments aren't live yet…". The server reports what is live (`/api/status/features/`), so the notice disappears by itself once a real provider is wired in; if the server can't be reached the notice stays. |
| 2026-09-28 | The AI assistant keeps a chat history on the phone only (per account, 30 chats, 200 messages each), with History and New chat buttons in its header and delete / Clear all that ask first. Not stored on the server: that would be new data collection needing a Privacy Policy change. |
| 2026-09-28 | This file created; the repo had referenced a `DESIGN.md` that didn't exist. |

## Known gaps

No flat 2D logo or wordmark. The typeface is a substitution. Motion is undefined beyond press and sheet. The README's exact pixel values came from screenshots; the tokens above are what ships.
