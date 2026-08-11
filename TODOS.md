# Spekooh — Remaining Functionality To Live-Implement

Generated after a full audit of the Flutter app against the real Django backend and
`uploads/spekooh_scope.md`. Priority tiers (P0/P1/P2) match the scope doc's own framework
(§3.1–3.3) so this list stays consistent with product intent, not just engineering convenience.
Within each tier, items are ordered most-impactful first.

Legend: **Backend** = does a real Django endpoint/model exist · **Client** = does the Flutter
app actually call it for real (not a mock, not a dead tap, not fabricated display data).

---

## P0 — Must-have, confirmed in scope, still not fully live

### 1. Bilingual UI (English + French)
- **Backend:** partial — `User.language_pref` field exists (`en`/`fr`), never read by anything.
- **Client:** not implemented at all. No `flutter_localizations`, no `.arb` files, no `intl`
  wiring. Every screen's copy is a hardcoded English literal. The "EN/FR" pills on Home and the
  language rows on Settings are pure decoration — tapping "Français" in Settings only flips a
  local `bool`, no French string exists anywhere to switch to.
- **Why P0:** spec §3.1 lists this as must-have "from launch, not a future add-on."
- **Scope note:** this is a real, sizeable piece of work — full ARB extraction of every string
  in the app plus a French translation pass — not a quick wiring fix like the rest of this list.

### 2. Rewarded-ad unlock (the "watch an ad for +1 free view" mechanic)
- **Backend:** real — `POST /papers/ad-watch/` (`AdWatchView` → `record_ad_watch()`) already
  works and is covered by tests; `record_paper_view()` already checks for an unconsumed
  `AdWatchEvent` before blocking with a paywall error.
- **Client:** zero ad SDK integration anywhere (`app/pubspec.yaml` has no `google_mobile_ads` or
  equivalent). The old "Watch ad" button was a no-op and was removed rather than left fake — but
  removing it means the mechanic is currently just gone, not deferred honestly to the user.
- **Why P0:** spec §5.3 describes this as a core piece of the confirmed revenue model, directly
  tied to the P0 daily-free-view-limit feature.
- **Needs:** pick an ad SDK (spec recommends AdMob to start), integrate rewarded-video unit, call
  the real endpoint on completion, re-surface the "Watch ad" CTA on Home/paywall.

### 3. Flag/report an existing paper
- **Backend:** not built — no `PaperFlag`/report model exists in `apps/papers` or
  `apps/admin_queue` (the admin queue currently only handles the "no instructor accepted"
  escalation path, a different concept).
- **Client:** no report affordance anywhere in `paper_detail_screen.dart`.
- **Why P0-adjacent:** listed as P1 in §3.2, but it's the cheapest way to keep a
  guest-submission-driven corpus clean, so worth pulling forward.

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

### 5. Referral bonuses
- **Backend:** not built — no referral-code/tracking model anywhere.
- **Client:** not built — no referral UI anywhere.

### 6. Real share action for the redeem code
- **Backend:** N/A.
- **Client:** `profile_screen.dart`'s "Share" label next to the redeem code has no `onTap` at
  all — smallest item on this list, needs a `share_plus`-style native share sheet call with the
  real redeem code string (already fetched from `/credits/redeem-codes/`).

---

## P2 — Explicitly future/speculative in spec, or invented UI with no spec backing at all

### 7. In-app practice quiz auto-generated from submitted papers ("Past-paper practice")
- **Backend:** not built — no paper→quiz generation pipeline; `Quiz`/`QuizQuestion` are
  manually authored rows only.
- **Client:** shown honestly as "coming soon" (fixed this session — previously opened a
  hardcoded fake quiz regardless of what was tapped).
- Matches spec §3.3 P2 exactly ("in-app practice/quiz mode generated from paper content").

### 8. "Friday Arena" live elimination quiz
- **Backend:** not built — no live/scheduled quiz-session model, no real-time transport.
- **Client:** shown honestly as "coming soon" (fixed this session — previously a dead tap).
- **Not in the confirmed spec at all** — pure UI-mockup invention (closest real-world analogue
  is Kawlo's "live 1v1 quiz battles," which the spec itself flags in §12.4 as a P2 idea worth
  revisiting post-MVP, not committed scope). Lowest priority on this whole list.

### 9. Quiz anti-cheat / answer-hiding
- **Backend:** `correct_choice_index` is stripped from the list/detail serializer response
  (confirmed not sent to the client) but there's no protection against a user inspecting network
  traffic before answering, since the full grading logic still lives client-adjacent in spirit.
  Documented as a known, accepted gap in `apps/quizzes/models.py`'s own docstring — quizzes are
  P2/non-spec'd, so this was a deliberate corner-cut, not an oversight.

### 10. Subscription tier for marking-guide access
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

---

## Already fully real (for context — not on this TODO)

Papers (browse/detail/submit), Home (guest + logged-in), quiz streaks, the 7-day new-account
trial + first-unlock-free perk, the Pro subscription paywall, Forum (ask/reply/upvote), Notes,
Notifications, Shop/pamphlets (including the escrow+QR pickup flow), Profile, and the daily
quiz challenge + leaderboard.
