package com.spekooh.spekooh

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (QR Vault fingerprint/biometric unlock, 2026-09-17) shows its
// prompt via a Fragment, which requires FlutterFragmentActivity rather than
// the plain FlutterActivity every other screen in this app has used so far.
class MainActivity : FlutterFragmentActivity()
