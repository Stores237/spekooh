// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navPapers => 'Papers';

  @override
  String get navForum => 'Forum';

  @override
  String get navQuizzes => 'Quizzes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Account & app';

  @override
  String get spekoohProTitle => 'Spekooh Pro';

  @override
  String get spekoohProSubtitle => 'Unlimited paper views · no ads';

  @override
  String get languageSection => 'Language';

  @override
  String get helpSection => 'Help';

  @override
  String get helpSupportTitle => 'Help & support';

  @override
  String get helpSupportSubtitle => 'Chat with a real person';

  @override
  String get helpWhatsappTitle => 'Join our WhatsApp group';

  @override
  String get helpWhatsappSubtitle => 'Tips & updates';

  @override
  String get helpContactTitle => 'Contact us';

  @override
  String get helpContactSubtitle => 'Questions or feedback';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutWebsiteTitle => 'Visit our website';

  @override
  String get aboutPrivacyTitle => 'Privacy policy';

  @override
  String get logOut => 'Log out';

  @override
  String get logIn => 'Log in';

  @override
  String get authCreateAccountTitle => 'Create your account';

  @override
  String get authLoginTitle => 'Log in to Spekooh';

  @override
  String get authNameLabel => 'NAME';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authEmailLabel => 'EMAIL';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordLabel => 'PASSWORD';

  @override
  String get authReferralLabel => 'REFERRAL CODE (OPTIONAL)';

  @override
  String get authReferralHint => 'e.g. A1B2C3D4';

  @override
  String get authPleaseWait => 'Please wait…';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authLoginButton => 'Log in';

  @override
  String get authSwitchToLogin => 'Already have an account? Log in';

  @override
  String get authSwitchToRegister => 'New here? Create an account';

  @override
  String get authErrorLogin => 'Login failed. Check your email and password.';

  @override
  String get authErrorRegisterReferral =>
      'Registration failed. Check your details, and that the referral code is correct.';

  @override
  String get authErrorRegisterGeneric =>
      'Registration failed. That email may already be in use.';

  @override
  String get authErrorUnknown =>
      'Something went wrong. Check your connection and try again.';
}
