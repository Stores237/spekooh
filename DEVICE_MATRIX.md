# Spekooh — Real Device Matrix & Beta Testing Plan

Every real-device pass logged in `TODOS.md`/`MVP_SIGNOFF_CHECKLIST.md` so far was on **one
physical Android phone**, plus `flutter test` (headless) and the web build in a browser. That's
enough to catch a class of bug web/emulator testing structurally can't (missing `INTERNET`
permission, the notch/bottom-nav layout gap, native file-picker dialogs) — but it's one point on
a real spread of Android OS versions, screen sizes, and RAM tiers, not the spread itself. This doc
is the plan for closing that gap before Play Console setup, using real market data instead of
guessing which devices "probably" matter.

**iOS is worse than one data point — it's zero.** See "iOS: from-scratch verification" below;
everything above this section is Android-only.

## What the app is actually built against

From the release APK itself (`aapt dump badging`), not assumed:

- **minSdkVersion 24** (Android 7.0 Nougat) — the real floor. Anything below this can't install
  the app at all; anything at or above it is a real supported user, not an edge case to skip.
- **targetSdkVersion 36** (Android 16) — the real ceiling Google Play requires targeting.
- **compileSdk 36**.

## Real target-market data (not assumed)

Cameroon-specific, via [StatCounter](https://gs.statcounter.com), August 2026 snapshot:

**Android version share** ([source](https://gs.statcounter.com/android-version-market-share/all/cameroon)):

| Version | Share |
|---|---|
| Android 13 | 20.18% |
| Android 12 | 15.55% |
| Android 14 | 12.80% |
| Android 11 | 12.32% |
| Android 10 | 9.02% |
| Android 16 | 7.75% |
| Everything else (9 and below, 15) | ~22.4%, not itemized by StatCounter |

Android 10–14 alone is ~70% of the real market — this is NOT a "mostly-latest-OS" market the way
a US/EU-focused app could assume. The ~22% long tail almost certainly includes real Android 8/9
devices still in daily use, which is exactly why minSdk 24 isn't a throwaway compatibility floor
here.

**Mobile screen width share** ([source](https://gs.statcounter.com/screen-resolution-stats/mobile/cameroon)):

| Resolution | Share |
|---|---|
| 360×806 | 18.24% |
| 360×800 | 11.64% |
| 414×896 | 9.94% |
| 360×820 | 5.05% |
| 360×780 | 3.80% |
| 360×640 | 3.39% |

**360dp-wide phones dominate** (five of the top six rows) — this is a narrow/budget-phone market,
not a large-flagship one. `360×640` specifically is a *short* 16:9 screen (older aspect ratio,
less vertical space) — the exact shape that already broke this app's bottom-nav layout once (see
`TODOS.md`'s notch/`extendBody` history) on a taller device; a short-and-narrow real device is a
genuinely different failure mode, not just "the same bug again."

No tablet-share data is called out here because this app has no tablet-specific layout or design
doc — treat tablet behavior as "must not crash," not "must look designed for," and say so plainly
in any test note rather than grading it against a bar the app never claimed to hit.

## The matrix to actually test

Six cells, chosen to cover the real floor/ceiling and the real market centroid — not an arbitrary
"test everything" spread that never gets finished:

| # | Android version | Screen | Why this cell |
|---|---|---|---|
| 1 | 7 or 8 (API 24–26) | Small, 360×640-class | The real floor. Oldest OS *and* the short/narrow screen shape that already broke layout once. Highest-risk cell in the matrix. |
| 2 | 10 or 11 (API 29–30) | 360×800-class | Real market centroid (~21% combined) — if this cell is broken, a fifth of the real target market is broken. |
| 3 | 12 or 13 (API 31–33) | 360×806/820-class | The single largest real slice (~35% combined) — the "most representative user" cell. |
| 4 | 14 (API 34) | 414×896-class | Larger/newer-shape screen, to catch anything that only breaks on more available vertical/horizontal space. |
| 5 | 16 (API 36) | Any current mid/large phone | The real ceiling — targetSdk 36's own new runtime behaviors (permission changes, predictive back, etc.) need a real check, not just "it compiled." |
| 6 | Any, but **2 GB RAM or less** | Any | RAM tier, not OS/screen — camera-based document scanning (`cunning_document_scanner`), image picking, and PDF viewing are the real memory-pressure paths in this app; a flagship test device won't surface an OOM crash a budget device will. |

## App-specific risk areas per device (not generic "does it open")

Real native plugins this app depends on (`app/pubspec.yaml`), each with its own real
device-specific failure mode a browser/emulator pass can't exercise:

- **`cunning_document_scanner` / `image_picker`** (paper/report submission, CNI/NUI document
  upload): real camera permission prompts, real camera hardware behavior, and the actual memory
  pressure of processing a real photo — this is the top OOM-crash risk on a low-RAM device (cell 6
  above).
- **`file_picker`**: the real native OS file-picker UI, which varies meaningfully across Android
  versions (scoped storage behavior changed materially between API 29 and 33+) — already flagged
  once in `MVP_SIGNOFF_CHECKLIST.md` row 9 as unverifiable outside a real device.
- **`local_auth`** (QR Vault fingerprint/Face ID unlock): depends on the device's own enrolled
  biometric hardware, not Google Play Services — a real device with fingerprint hardware *and* one
  with none enrolled both need a pass, to confirm the PIN fallback genuinely works when biometrics
  aren't available, not just when they are.
- **`google_mobile_ads`**: the one real Google Play Services dependency in this app. A non-GMS or
  GMS-stripped device (uncommon but real in this market — some budget/regional Android builds ship
  without Play Services) should fail to load ads gracefully, not crash. Worth one real check on a
  device known to lack GMS if one is reachable during beta; not worth blocking the whole matrix on.
- **`flutter_secure_storage`**: backed by Android Keystore — real behavior differs across OEM
  Keystore implementations more than across raw OS version; a real budget-OEM device (Tecno,
  Itel, Infinix — genuinely common in this market) is a better test than another Pixel/Samsung.

## How to actually get these devices (without buying a fleet)

Owning six physical phones spanning API 24–36 isn't realistic for this project. Three real,
practical paths, roughly in the order to reach for them:

1. **Firebase Test Lab** (free tier: 10 physical/virtual device tests + 5 virtual per day). Real
   Google-hosted physical devices, selectable by exact OS version and model — this is the direct
   way to fill cells 1–5 above without owning the hardware. Upload the release APK, pick device
   models matching the matrix, run Robo test (automatic crawl) at minimum, a real instrumented
   test script if one exists. Needs a Firebase project (new, or reuse one if `GEMINI_API_KEY`'s
   project already exists) — no Play Console account required for this step.

   **This side is already wired up** — `.github/workflows/device-matrix.yml`
   (`workflow_dispatch`, run per cell or all of cells 1–5 at once) and
   `app/scripts/run_device_matrix.sh` (same thing, run locally — also the way to fill cell 6,
   since that one needs a real low-RAM model picked from the live catalog, not an API level).
   Both need real setup before they'll actually run anything, owner action, not engineering work:
   1. Create a Firebase project (console.firebase.google.com) — reuse an existing GCP project if
      one's already around (e.g. wherever `GEMINI_API_KEY`/`GROQ_API_KEY` live), or a fresh one.
      Firebase Test Lab enables the underlying Cloud Testing API automatically.
   2. Create a service account with the **Firebase Test Lab Admin** (or **Cloud Testing Service
      Agent**) role in that project's IAM settings, and download its JSON key.
   3. In this repo's GitHub Settings → Secrets and variables → Actions, add:
      - `FIREBASE_TEST_LAB_SA_KEY` — the full contents of that JSON key file.
      - `FIREBASE_PROJECT_ID` — that project's id.
   4. Once those two secrets exist, replace the `REPLACE_WITH_REAL_MODEL_ID` placeholders in
      `device-matrix.yml` with real, currently-available model ids — run
      `gcloud firebase test android models list --filter="supportedVersionIds=<api-level>"`
      (or trigger the workflow once with a placeholder to get a clear "model not found" error
      listing valid options) rather than trusting any model id written down here, since Test
      Lab's real device catalog changes over time and this doc can't stay current with it.
2. **Google Play Console's Pre-launch report.** The moment a build is uploaded to *any* testing
   track (Internal testing is the lightest — no review, live in minutes), Play Console
   automatically runs it across a real matrix of physical devices in Google's own lab and reports
   crashes, ANRs, and screenshots per device, for free. This is the single most practical way to
   get broad real coverage with zero hardware owned — and it means "set up Play Console" isn't
   purely downstream of this device matrix; standing up just the Internal testing track (not a
   full public listing) is itself a fast, low-commitment way to *get* device coverage, not
   something that has to wait until testing is "done" by hand first.
3. **Real borrowed/secondhand devices for the highest-risk cells.** Cells 1 and 6 (oldest OS +
   short screen; lowest RAM) are worth a genuinely real, in-hand device if at all reachable —
   Firebase Test Lab and the pre-launch report catch crashes and layout screenshots well, but a
   real person tapping through the actual paper-submission camera flow on a real 1–2GB-RAM phone
   surfaces jank and "technically didn't crash but felt broken" issues neither automated pass will.

## Beta testing phases

**Phase 0 — pre-Play-Console smoke pass.** Firebase Test Lab Robo test across the six matrix
cells on the current release APK. Goal: catch any hard crash/ANR before a single real tester (or
Google's own review) sees one. Blocking bar: zero crashes on app launch + login + one core flow
(Papers taxonomy browse) across all six cells.

**Phase 1 — Play Console Internal testing track.** Small (Google caps this at 100), invite-only
group — the owner plus a handful of real people who own real devices you don't, deliberately
recruited to cover gaps the matrix above can't reach otherwise (ask directly: "what phone brand
and roughly how old is it?" before inviting, don't just take whoever's available). This is also
when the automatic Pre-launch report starts running on every new build. Duration: until the
`MVP_SIGNOFF_CHECKLIST.md` flows all pass on at least one real device per matrix cell, not a fixed
number of days.

**Phase 2 — Closed testing, wider group.** Once Phase 1's matrix is genuinely green, open a
larger (still invite-only, no public listing yet) closed testing track for real day-to-day use at
volume — this is where the load-pass numbers from `TODOS.md`'s "Load pass at realistic volume"
section meet real, varied client behavior instead of a synthetic script. Graduate to a public
listing only after this phase, as its own separate decision.

## iOS: from-scratch verification (2026-09-18)

Everything above this section is Android. Before today, this project's iOS side had never
produced a real build, let alone run on a real device or reached TestFlight — `ios/Podfile` (the
file CocoaPods needs to link any plugin's native code at all) had never existed in this repo's
history, from the very first commit. Every fix ever made to `ios/Runner/Info.plist`
(`NSCameraUsageDescription`, `NSFaceIDUsageDescription`) was made by reading each plugin's own
documentation, not by ever actually triggering the crash they prevent — real, necessary fixes,
but unverified ones. Treating that gap as a formality would mean the first real signal on whether
any of it actually works is a rejected TestFlight build or a crash report from an actual iOS user.

**Real audit performed today, not just "should be fine":**

- Cross-checked every installed plugin's own `.podspec` (`~/.pub-cache`, not assumption) against
  `ios/Runner.xcodeproj`'s real `IPHONEOS_DEPLOYMENT_TARGET` (13.0): `image_picker_ios`,
  `cunning_document_scanner`, `local_auth_darwin`, and `google_mobile_ads` (`Google-Mobile-Ads-SDK
  ~> 13.7`) each declare `13.0` as their own minimum; `file_picker`'s `12.0` is already covered.
  No version conflict that would have failed `pod install` for real.
- Audited `Info.plist` against every plugin actually used for a permission gap, not just the ones
  already fixed: **found `NSPhotoLibraryUsageDescription` missing.**
  `ProfileScreen`'s avatar picker offers `ImageSource.gallery` as well as `.camera`
  (`profile_screen.dart`) — without this key, iOS crashes outright the moment a real user picks
  "gallery", not a permission-denied dialog. `NSCameraUsageDescription` never covered this path.
  Fixed.
- Found `Info.plist` itself was not well-formed XML — a pre-existing `--` inside an existing
  comment (`NSFaceIDUsageDescription`'s own), illegal inside an XML comment anywhere except its
  closing `-->`. CoreFoundation's plist parser tolerates this in practice (which is exactly why it
  was never caught — nothing in this project's history has ever actually parsed this file with
  Xcode or `plutil`), but it's real, latent breakage in a file no stricter tool has ever touched.
  Fixed, along with not repeating the mistake in the new `NSPhotoLibraryUsageDescription` comment.

**Fixed as a result:**

- `ios/Podfile` — created from this exact Flutter SDK version's own template
  (`flutter/packages/flutter_tools/templates/cocoapods/Podfile-ios`), with `platform :ios, '13.0'`
  pinned explicitly (uncommented, unlike the bare template) to match the real deployment target
  verified above, rather than left to CocoaPods' own older implicit default.
- `Info.plist` — `NSPhotoLibraryUsageDescription` added; the file is now genuinely well-formed XML.

**Automated as a result:** `.github/workflows/ios.yml` — a real macOS runner (`macos-14`, real
Xcode + CocoaPods), `pod install` then `flutter build ios --release --no-codesign` on every
push/PR touching `app/`. `--no-codesign` deliberately skips needing an Apple Developer
certificate (owner-gated, same as Google Play Console — see `TODOS.md`), while still proving the
Podfile is correct and every plugin's native code actually compiles and links — the two things
that were previously completely unverified, ever, on any machine.

**Known, documented, deliberately not silently fixed:**

- **`SKAdNetworkItems`** — Apple's ad-attribution requirement for `google_mobile_ads`'s mediation
  network partners on iOS 14+. Missing this doesn't crash the app, but real ad fill on iOS will be
  degraded without it. Deliberately not hand-typed here: Google maintains the current, correct
  list at [Add SKAdNetwork IDs to your iOS apps](https://support.google.com/admob/answer/9905780)
  because the network partner list changes over time — copying a snapshot into this doc would
  silently go stale. Add the current list from that page to `Info.plist` before any real iOS ad
  revenue matters.
- **App Tracking Transparency**: no `NSUserTrackingUsageDescription`, no ATT prompt requested
  anywhere in the app. This is a *valid* configuration (Apple doesn't require the ATT prompt,
  only requires it if the app intends to track) — `google_mobile_ads` will serve non-personalized
  ads by default without it. Left as an explicit, documented decision rather than an accidental
  default: revisit only as a deliberate call to trade a real ATT prompt for better ad revenue, not
  a silent gap to "eventually fix."

**Still genuinely owner-gated, not engineering work:**

- **Apple Developer Program membership** ($99/year) — required for any real code-signed build,
  TestFlight, or App Store submission. Nothing above needed it; the next real step does.
- **A physical iPhone, or continued CI-only verification.** `.github/workflows/ios.yml` proves the
  app compiles; it does not prove the camera, Face ID, or file-picker flows actually work on real
  iOS hardware. No iOS-equivalent to the Android device matrix above exists yet because there's
  been no real device to build it from — the first task once a Developer account exists is a
  genuinely real (not simulator-only) pass through `MVP_SIGNOFF_CHECKLIST.md`'s flows, the same
  bar the one Android phone already cleared.
- **TestFlight** — the iOS equivalent of Play Console's Internal testing track (Phase 1 above);
  same phased approach applies once a Developer account and at least one real device exist.

## Tracking table

Same convention as `MVP_SIGNOFF_CHECKLIST.md`: blank means untested, not "probably fine." Fill in
as each cell is actually run, whether via Firebase Test Lab, the Pre-launch report, or a real
person's hands.

| Cell | Device / OS / Screen | Method | Pass | Fail | Tester / Date | Notes |
|---|---|---|:-:|:-:|---|---|
| 1 | Android 7–8, 360×640-class | | ☐ | ☐ | | |
| 2 | Android 10–11, 360×800-class | | ☐ | ☐ | | |
| 3 | Android 12–13, 360×806/820-class | | ☐ | ☐ | | |
| 4 | Android 14, 414×896-class | | ☐ | ☐ | | |
| 5 | Android 16, current mid/large phone | | ☐ | ☐ | | |
| 6 | Any OS, ≤2GB RAM | | ☐ | ☐ | | |
