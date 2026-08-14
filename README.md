# Spekooh Design System

## Company & product context

**Spekooh** is a mobile app (Flutter, Cameroon v1, bilingual EN/FR) that crowdsources exam papers from students and the public — across **every education sector and level, both Anglophone (GCE, HND) and Francophone (BEPC, Probatoire, Baccalauréat) systems** — and routes each paper to a verified instructor (on a separate partner platform) who writes a marking guide. Revenue is ads + a Pro subscription (unlimited paper views, ad-free) + pay-per-unlock marking guides + a 5% commission on partner pamphlet sales (escrow + QR pickup/delivery confirmation). Contributors earn redeemable bonus credits; instructors earn cash-convertible credits. Full spec: `uploads/spekooh_scope.md` (product/business) and `uploads/README.md` (engineering — stack: Flutter, Django, Supabase, Flutterwave).

**Important correction:** earlier versions of this design system conflated Spekooh with **Kawlo** (`cameroongcerevision.com`), an existing Anglophone-only GCE revision app. Kawlo is Spekooh's **named competitor/benchmark**, not the same product — the 24 screenshots this system was originally built from are Kawlo's UI, used here only as a *stylistic* freemium/edtech reference point (list-row patterns, pill buttons, paywall sheet), not as Spekooh's actual feature set. Spekooh's real, confirmed differentiators — crowdsourced paper submission, instructor accept/reject + 7‑day marking-guide flow, a credit/redeem-code ledger, and pamphlet escrow+QR — have **no equivalent screens in the current `ui_kits/spekooh-app/`build**. The scope doc explicitly says UI should follow **the logo's own gold/black/dark-brown palette** (confirmed independently of this correction — the gold rework already done here is correct and should stay).

**Sources:** `uploads/spekooh_scope.md` (product scope v0.1), `uploads/README.md` (dev/build guide), 24 Kawlo-app screenshots + Spekooh logo (`uploads/WhatsApp Image*.jpeg`, `uploads/3D_S-Logo-removebg.png`) used for visual-style reference only, a screen recording (`uploads/Screen recording*.webm`, unread by this tool), and a `Spekooh/` local codebase folder (not yet explored this turn — attach/confirm if it should replace the screenshot-derived styling).

## Content fundamentals

- **Voice:** plain, direct, reassuring — written for students who may have unreliable data/electricity. "Saved papers open without internet — even in the village." "Reading papers, corrections, notes & quizzes stays open to everyone."
- **Address:** second person ("you"), casual register: "Sign up only when you want to…", "Chat with a real person."
- **Casing:** sentence case for body copy and most titles ("Help & support", "Join our WhatsApp group"); section labels are uppercase tracked caps ("LANGUAGE", "HELP", "ABOUT", "BY SUBJECT", "EXAM LEVELS").
- **Numbers as trust signals:** counts appear constantly and plainly — "1308 students played", "11 years of past questions", "39 QUIZZES", "18 topics" — never dressed up, just stated.
- **Spekooh Bot personality line:** "Spekooh Bot explains it like a big brother would" — warm, local, informal framing for the AI feature, not corporate-AI language.
- **No emoji in UI copy** (a 🏆 trophy appears only as an icon glyph, never inline in text).
- **Pricing is explicit and local:** FCFA amounts and MTN MoMo / Orange Money stated directly in buttons and rows ("Pay 500 FCFA", "+237 670 12 34 56"), with a plain trust line under payment CTAs ("Official Spekooh merchant · we never ask for your PIN · receipt + SMS within 2 min").
- **Freemium framed as a ladder, not a wall:** "Sign up only when you want to…" followed by small locked perks (streak/XP, forum posting, competitions, sync) — reading/papers/quizzes stay open to guests.

## Visual foundations

- **Color:** deep warm ink (`--ink-900`, a near-black brown — replaces the earlier navy so dark surfaces sit in the same warm family as the logo) for headings/dark surfaces; **gold** — pulled from the Spekooh logo cube — as the one primary interactive color (buttons, links, active states): `--gold-50 #FBF3E1`, `--gold-200 #EFCD83`, `--gold-400 #E2A52A`, `--gold-500 #C8881C`, `--gold-600 #A8721A`, `--gold-700 #835611`. CTAs use gold **gradients**, never flat fill: `--gradient-primary` (gold-400→gold-700, main buttons), `--gradient-bot` (gold-200→gold-600, AI/bot accents), `--gradient-gold-deep` and `--gradient-gold-soft` for other rich/soft surfaces — all four gradients are stops along the same gold ramp, so nothing reads as an unrelated color. The three semantic accents (green/mauve/red) were re-tuned to sit in the same warm family instead of clashing cool tones: green shifted toward olive (`--green-500 #6FA23A`), the old cool violet shifted to a warm mauve (`--purple-500 #A6709B`), and red shifted toward a warm red-orange (`--red-500 #D1603C`). Background, card, and border neutrals were warmed to match (`--surface-bg #F7F4EE`, `--border-subtle #EAE2D2`) instead of the earlier blue-gray. *(Legacy `--blue-*`/`--amber-*`/`--navy-*` token names are kept for compatibility and now alias the gold/ink scale — see `tokens/colors.css`.)*
- **Type:** one geometric sans throughout, bold/extrabold for headings, regular for body, gray for secondary text. No serif anywhere. **Substitution flagged:** no font files were supplied; `Plus Jakarta Sans` (Google Fonts) is used as the nearest open match to the rounded-geometric weight/shape seen in the screenshots. Please supply the real webfont files if the app uses a licensed/custom typeface.
- **Spacing:** consistent ~16px screen padding, ~8–14px gaps inside stacked cards, generous white space between grouped sections (never cramped).
- **Backgrounds:** flat color only — no photography-heavy hero sections, no illustrated backgrounds, no textures/grain/patterns visible anywhere in the app. The one full-bleed asset is the pamphlet cover art shown inside the shop tiles.
- **Corner radii:** large and consistent — outer cards ~18–22px, icon chips ~12px, buttons and pills fully rounded (999px). Nothing is sharp-cornered.
- **Cards:** white fill, soft low-elevation shadow (barely-there, no hard drop shadow), no visible border in most cases; grouped list-rows live inside one card divided by hairlines rather than each row being its own card.
- **Buttons:** always pill-shaped. Primary = gold gradient fill with white bold text; secondary/outline = bordered or light-tint fill; text/ghost links (e.g. "Shop", "See all") are plain gold-700 text, no underline until hover.
- **Press/hover states:** buttons shrink slightly on press (no color darkening observed); no visible hover states (mobile-only product). List rows have no visible pressed background change beyond the chevron affordance.
- **Borders/shadows:** shadows are the primary separation device, not borders — borders (1px, very light gray) appear only for outline buttons, dividers, and the search input.
- **Transparency/blur:** the paywall bottom sheet uses a dimmed, slightly blurred backdrop behind it — the only blur usage seen.
- **Imagery tone:** the few photographic assets (pamphlet covers) are warm, colorful, editorial stock-style — not part of the core UI chrome.
- **Motion:** not directly observable from static screenshots; the bottom-sheet paywall implies a slide-up transition. No other animation evidence — treat easing/duration as undefined until confirmed.

## Iconography

Spekooh uses simple **line icons** inside tinted rounded-square chips (never bare on a plain background, never emoji, never PNG icon sets). No icon-font glyphs or custom SVG sprite were recoverable from screenshots. This system substitutes **Lucide** (CDN, `unpkg.com/lucide`) as the closest open stroke-icon set to what's on screen (thin/medium stroke weight, rounded joins, outlined not filled) — flagged as a substitution; swap in the app's real icon export if available. The one custom glyph is the Spekooh Bot mark: a sparkle inside a speech-bubble/rounded-square, on a gold gradient — treat that specific glyph as brand IP, not a generic Lucide icon, if rebuilding it exactly.

## Index

- `styles.css` — root stylesheet, imports everything under `tokens/`
- `tokens/` — `colors.css`, `typography.css`, `spacing.css`, `radius.css`, `shadows.css`
- `assets/logo/spekooh-s-mark-3d.png` — Spekooh's gold 3D cube mark (no flat 2D wordmark supplied)
- `guidelines/` — foundation specimen cards (Colors, Type, Spacing, Brand)
- `components/` — reusable primitives, grouped by concern:
  - `core/` — **Button**, **Badge**, **IconChip**
  - `navigation/` — **BottomNav**, **SegmentedTabs**
  - `data-display/` — **ListItemRow**, **StatRow**, **SubjectCard**, **Avatar**
  - `forms/` — **SearchInput**, **Toggle**
  - `feedback/` — **Banner**
- `ui_kits/spekooh-app/` — interactive click-through recreation of the Spekooh mobile app (Home, Papers/exam picker, Quizzes, Forum, Settings, Paywall)
- `SKILL.md` — portable skill file for using this system outside this tool

## Intentional additions

None of the standard primitives were invented beyond what's directly evidenced in screenshots — `Badge`, `IconChip`, `StatRow`, and `SegmentedTabs` are named generically but every instance ties back to a specific screen shown above.

## Caveats — please help us iterate

1. **No codebase/Figma access** — this system is screenshot-derived only. Exact hex values, spacing, and the real typeface are best-guesses, not extracted values.
2. **Font substitution** — Plus Jakarta Sans stands in for the real Spekooh typeface. Please share the actual font files.
3. **No flat 2D logo/wordmark found** — only the 3D gold cube mark was supplied. If Spekooh has a flat lockup or wordmark, please attach it.
4. **Screen recording unread** — the `.webm` walkthrough couldn't be opened by this tool; if it shows flows/screens not in the static screenshots, they're missing here.
5. **claude.ai share link inaccessible** — please paste its content directly, or re-share a reachable link, if it contains design specs.
6. **Screenshots predate the rebrand** — they show "Kawlo" copy/branding; all rebuilt copy here says "Spekooh" per your correction, but exact spacing/values are still read from the old screenshots.
