import 'package:flutter/widgets.dart';

import 'token_storage.dart';

/// Spec §3.1: bilingual EN/FR, "from launch, not a future add-on" — and
/// adaptive to the device's own language, not just a manual toggle.
const supportedLocaleCodes = ['en', 'fr'];

/// Resolves and persists the app's active language. Resolution order:
/// an explicit choice this user has made (on this device, or synced from
/// their account on another) always wins; otherwise the device's own
/// system locale, clamped to {en, fr} — anything else defaults to English.
class LocaleController extends ChangeNotifier {
  LocaleController({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  static LocaleController instance = LocaleController();

  @visibleForTesting
  static void debugSetInstance(LocaleController controller) => instance = controller;

  final TokenStorage _storage;
  static const _key = 'spekooh_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// True once this device has a locale it was actually told to use
  /// (by the user directly, or synced from their account) — distinct from
  /// just having fallen back to the system default.
  bool _explicit = false;

  Future<void> bootstrap() async {
    final saved = await _storage.read(_key);
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      _locale = Locale(saved);
      _explicit = true;
    } else {
      _locale = _systemDefault();
    }
    notifyListeners();
  }

  Locale _systemDefault() {
    // WidgetsBinding.instance.platformDispatcher, not the raw
    // dart:ui PlatformDispatcher.instance singleton — the latter isn't the
    // one Flutter's test framework overrides, so using it here would make
    // this unresolvable to a fixed locale under `flutter test`. Both point
    // at the same real dispatcher outside of tests.
    final systemCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(supportedLocaleCodes.contains(systemCode) ? systemCode : 'en');
  }

  /// Called once an account is resolved (login/register/guest) — applies
  /// that account's own language_pref, but only if this device doesn't
  /// already have an explicit choice of its own (a deliberate on-device
  /// pick shouldn't be silently overwritten by a stale value from signup
  /// on a different device).
  Future<void> syncFromAccount(String? languagePref) async {
    if (_explicit || languagePref == null || !supportedLocaleCodes.contains(languagePref)) return;
    await setLocale(languagePref);
  }

  Future<void> setLocale(String code) async {
    if (!supportedLocaleCodes.contains(code)) return;
    _locale = Locale(code);
    _explicit = true;
    await _storage.write(_key, code);
    notifyListeners();
  }
}
