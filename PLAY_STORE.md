# Google Play Store readiness

Tracks what's actually in place for a Play Console submission vs. what's
still missing. This is a prep/config checklist, not a submission log — no
Play Console listing has been created yet.

## App identity

- Package name: `com.spekooh.spekooh` (`app/android/app/build.gradle.kts`)
- iOS bundle id matches: `com.spekooh.spekooh`
- Launcher label fixed to `Spekooh` (was lowercase `spekooh` in
  `AndroidManifest.xml`, 2026-09-29) — iOS `CFBundleDisplayName` was already
  correct.
- Version: `1.0.0+1` in `pubspec.yaml`. Beta APK builds use
  `--build-number` overrides (currently at build 4) — `pubspec.yaml`'s own
  `+1` should be bumped to match before any real Play upload, since Play
  tracks are keyed on version code.

## Signing

- Real upload key present and in use (`app/android/key.properties` +
  keystore, not the Flutter debug key). SHA-256 fingerprint:
  `5c31887210c1a79dd10225769cea75cc42e6e3aca1097a8bcc10a1707f53de3a`.
  Confirmed identical across beta builds 2, 3, and 4.
- Play App Signing: not yet opted into (happens during first Console
  upload — Google re-signs with its own key and keeps this one as the
  upload key). No action needed until the Console flow.

## Icons

- Legacy launcher icons only (`mipmap-*/ic_launcher.png`) — **no adaptive
  icon** (`mipmap-anydpi-v26/ic_launcher.xml` + foreground/background
  layers). Not a Play submission blocker by itself, but Play strongly
  recommends adaptive icons and some device launchers will letterbox a
  legacy icon awkwardly. Worth generating before the real listing.
- Play Console's 512×512 hi-res icon requirement is already satisfiable:
  `app/web/icons/Icon-512.png` and `Icon-maskable-512.png` are both
  confirmed 512×512 PNGs already in-repo.

## Store listing assets — missing

- Feature graphic (1024×500): not present anywhere in the repo.
- Real device screenshots of the Flutter app: not present. The only
  screenshots in the repo (`.gstack/qa-reports/screenshots/`) are of the
  marketing website, not the app.
- Short/full store description text: not drafted yet.

## Legal / policy

- Privacy Policy: live at `/legal/privacy-policy/` on the backend —
  satisfies Play's mandatory working policy URL requirement.
- Terms of Service: live at `/legal/terms-of-service/`.
- Both are served from the same Django backend the app talks to, so no
  separate hosting is needed for the listing.

## Data Safety form (drafting basis)

Third-party SDKs actually present, confirmed from `pubspec.yaml` and the
Android manifest — no Firebase Analytics/Crashlytics, no Sentry client
SDK, no Facebook/OneSignal:

- `google_mobile_ads` (AdMob), real production app ID
  `ca-app-pub-6272769995522353~8764029955` already in
  `AndroidManifest.xml`, real ad unit IDs in `app/lib/ads/ad_ids.dart`.
  → Declare: advertising ID collection/use, shared with AdMob for
  personalized/non-personalized ads per current consent setup.
- Twilio, server-side only (`backend/apps/core/sms.py`), used for phone
  verification SMS. → Declare: phone number shared with a third-party
  processor (Twilio) for verification, not for advertising.
- Payments are currently mocked (`MockPaymentProvider`) — no real payment
  processor is wired up yet, so nothing to declare there **today**. This
  must be revisited before the real payment provider goes live, since
  that will add a financial-info data type to the form.

## Known blockers to an actual public submission (not just config prep)

- Payments are still simulated end-to-end (`payments_are_live()` is
  `false`) — the in-app notice makes this visible to testers, but Play
  review may flag a "Buy Pro" flow that doesn't actually charge anyone as
  misleading if submitted as-is. This should be resolved (either ship
  with payments live, or gate the button) before a real listing goes
  public, not just before the config is finished.
- No production backend deploy has been confirmed independently of
  staging in this session.
- MVP sign-off checklist (device matrix testing, etc.) is still largely
  unverified per earlier discussion.

## Next steps (in order)

1. Generate an adaptive icon from the existing 512×512 source art.
2. Take real device screenshots (phone + optionally 7"/10" tablet) once a
   build is on a physical device or emulator — needed for the listing,
   not producible from this sandbox.
3. Commission or draft a 1024×500 feature graphic.
4. Draft short description (≤80 chars) and full description (≤4000
   chars) copy.
5. Bump `pubspec.yaml` version to match the real first Play upload before
   creating the Console listing.
6. Fill in the Data Safety form using the SDK inventory above.
7. Decide on the payments-blocker question above before flipping the
   listing from internal/closed testing to any public track.
