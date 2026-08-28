# Running Spekooh — backend, web, and a real phone

Every step below is copy-pasted from commands that were actually run and verified end-to-end
(2026-08-28) — not aspirational setup instructions. If a step stops matching reality, fix the
doc in the same PR that changes the thing it describes.

There are three progressively more real ways to run Spekooh locally:

1. **Backend only** — Django API, for testing endpoints directly.
2. **Backend + web app** — the fastest full loop for day-to-day development.
3. **Backend + a real installable Android app on a real phone** — for actually feeling the
   product, not just looking at a browser tab.

---

## 0. Prerequisites

| Tool | Version used | Check with |
|---|---|---|
| Python | 3.13 | `python3 --version` |
| PostgreSQL | 17 (any recent 14+ works) | `psql --version` |
| Flutter | 3.44.9, stable channel | `flutter --version` |
| Android SDK + build-tools | installed via `flutter doctor` / Android Studio | `flutter doctor -v` — look for a green checkmark under "Android toolchain" |
| Java (for Gradle) | OpenJDK 21 | `java -version` |

Run `flutter doctor -v` first. If "Android toolchain" isn't green, you can't build a real APK
(step 3 below) — you can still do steps 1 and 2 without it.

---

## 1. Backend (Django)

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env
```

Edit `.env`:
- `DATABASE_URL` — point it at a local Postgres you control, e.g.
  `postgres://postgres:<your-password>@localhost:5432/spekooh` (create the `spekooh` database
  first: `createdb spekooh` or `psql -c "CREATE DATABASE spekooh;"`). The real project's `.env`
  points at a Supabase Postgres instead — either works, nothing else in settings changes.
- Everything else in `.env.example` has a working default; only add the optional blocks
  (Redis, Sentry, Supabase Storage) if you're specifically testing those.

Then:

```bash
.venv/bin/python manage.py migrate
.venv/bin/python manage.py createsuperuser   # optional, for /admin/
.venv/bin/python manage.py runserver 0.0.0.0:8000
```

Verify: `curl http://localhost:8000/api/papers/categories/` should return real JSON, not an
error page. `0.0.0.0` (not `127.0.0.1`) matters later — it's what makes the server reachable
from outside the machine in step 3.

**Note on `ALLOWED_HOSTS`:** `config/settings/dev.py` sets `ALLOWED_HOSTS = ["*"]` — deliberately
permissive, because this is the dev-only settings module (`DEBUG = True` here regardless) and a
real phone or another machine hitting this server by IP/tunnel hostname needs its `Host` header
accepted. Never carry `["*"]` into a real production settings module.

---

## 2. Web app (fastest loop, same machine)

In a second terminal:

```bash
cd app
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

Open `http://localhost:8080` in a browser. The app defaults to `http://localhost:8000/api` for
the backend when running on web (see `lib/data/api_client.dart`) — no extra flags needed as
long as the backend from step 1 is running on port 8000 on the same machine.

**If you ever see a blank white page after a code change and a hot-restart doesn't fix it:**
run `flutter clean && flutter pub get` and relaunch. `flutter run`'s incremental web compiler
cache can get into a bad state after many rapid restarts — a full clean rebuild is the fix, not
more debugging. Symptom to recognize: the page returns real 200s for every asset/script, but
`document.querySelectorAll('canvas')` never returns anything and nothing after `main()`
appears in the browser console — the compiled bundle loaded but never actually ran.

---

## 3. A real installed app, on a real phone

This is the part that needs care: your phone is a genuinely separate device, so `localhost`
means nothing to it. It needs a real, reachable URL for the backend, and the Android app needs
permission to make network calls at all.

### 3.1 Get a real, phone-reachable backend URL

Two options — use whichever fits:

**Option A — same Wi-Fi, ChromeOS/router port forwarding.** Find your machine's LAN IP (e.g.
`192.168.8.197`), forward TCP port 8000 to it (ChromeOS: Settings → Advanced → Developers →
Linux development environment → Port forwarding). This is entirely local — no data leaves your
network — but depends on your router/OS actually passing the traffic through, which isn't
always reliable and only works while the phone is on the same network.

**Option B — a public tunnel (what actually worked when Option A didn't).** No account needed:

```bash
curl -sL -o tools/cloudflared \
  "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
chmod +x tools/cloudflared
./tools/cloudflared tunnel --url http://localhost:8000
```

This prints a real `https://<random-words>.trycloudflare.com` URL that proxies straight to your
local backend — works from any network (Wi-Fi or mobile data), no router configuration at all.
**Caveats:** it's a free "quick tunnel" — no uptime guarantee, and the URL is different every
time you start it (see 3.4 for what that means for the APK). For anything longer-lived than a
same-day test, set up a [named tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps)
instead.

Verify before building anything: `curl https://<your-url>/api/papers/categories/` must return
real JSON.

### 3.2 The one Android permission that's easy to miss

`app/android/app/src/main/AndroidManifest.xml` needs:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Flutter's own debug/profile manifests already include this (for hot-reload's own use), which is
exactly why it's easy to miss — an app that only ever ran via `flutter run` on an emulator/web
never surfaces the gap. Without it in the **release** manifest, a real installed APK opens fine
(the splash screen has no network dependency) but every real request silently fails — no
crash, just an app that falls back to its own honest "no data yet" empty states. If a build
ever exhibits *"opens fine, nothing ever loads, login does nothing"* on a real device, this
permission is the first thing to check.

### 3.3 Build the APK

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-tunnel-or-lan-url>/api
```

- `--release` (not `--debug`): a debug build is 2-3x larger and slower — fine for the very first
  smoke test, not for something you actually want to use.
- Add `--target-platform android-arm64` if you want a smaller, faster build and don't need to
  support 32-bit or x86 Android devices (nearly every real phone from the last several years is
  arm64) — cuts the build roughly in half.
- `API_BASE_URL` is read via `String.fromEnvironment` in `lib/data/api_client.dart` — it's baked
  into the compiled binary at build time, not something you can change after the fact.

Output: `app/build/app/outputs/flutter-apk/app-release.apk`.

**Sanity-check what actually got baked in**, especially after copy-pasting a URL:

```bash
unzip -p app/build/app/outputs/flutter-apk/app-release.apk AndroidManifest.xml | strings -e l | grep -i internet
strings app/build/app/outputs/flutter-apk/app-release.apk/../lib/arm64-v8a/libapp.so | grep -i "your-tunnel-domain"
```

### 3.4 Get the file onto the phone

Simplest path if your backend already serves media files (`MEDIA_URL`/`MEDIA_ROOT`, on by
default when `DEBUG=True` — see `config/urls.py`): drop the APK straight into `backend/media/`
and it's downloadable from the same tunnel/LAN URL you already have running, no extra port or
transfer step:

```bash
cp app/build/app/outputs/flutter-apk/app-release.apk backend/media/spekooh.apk
```

Then on the phone, open `https://<your-tunnel-or-lan-url>/media/spekooh.apk` in a browser,
download it, and tap it to install. Android will ask to allow installing from that source once
— approve it. If a previous install of the app exists with a different signing key or a
different `applicationId`, uninstall it first or the install will silently fail.

### 3.5 If a tunnel URL changes

Free `trycloudflare.com` quick tunnels get a **new random URL every time the tunnel process
restarts** — there's no way to pin it without a named/paid tunnel. Since the URL is baked into
the compiled APK (3.3), a new tunnel URL means **rebuild the APK**, not just restart the tunnel.
Keep the tunnel and the backend running for as long as you want the installed app to keep
working — closing either one breaks the app until you restart them (and, if the tunnel URL
changed, reinstall).

---

## Troubleshooting quick-reference

| Symptom | Cause | Fix |
|---|---|---|
| `DisallowedHost` error in Django, or the phone gets "site can't be reached" | `ALLOWED_HOSTS` doesn't include the Host header the request actually arrives with | Use `config.settings.dev` (`ALLOWED_HOSTS = ["*"]`), or add the specific host |
| Web app: blank white page after a hot-restart, no console errors, `<canvas>` never appears | Corrupted `flutter run` incremental web-compiler cache | `flutter clean && flutter pub get`, relaunch |
| Real phone: app opens past splash, then everything acts like there's no data (empty states, login does nothing) | Missing `INTERNET` permission in `android/app/src/main/AndroidManifest.xml`, OR the backend/tunnel isn't actually reachable | Check the manifest (3.2); `curl` the exact URL baked into the APK from a machine *other than* the one running the backend |
| Phone: "app not installed" | Signature/applicationId conflict with a previous install | Uninstall the old one first |
| First `flutter build apk` takes 3-7 minutes | Cold Gradle daemon, cold Kotlin compiler | Normal — subsequent builds in the same environment are much faster (Gradle daemon stays warm) |
