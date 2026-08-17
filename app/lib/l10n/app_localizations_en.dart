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

  @override
  String get homeWelcomeGreeting => 'Welcome';

  @override
  String get guestLabel => 'Guest';

  @override
  String get joinFree => 'Join free';

  @override
  String get homeExploringBadge => 'Exploring — no account';

  @override
  String get homeFreeViewsLabel => 'FREE PAPER VIEWS';

  @override
  String get homeFreeViewsCount => '3 a day';

  @override
  String get homeFreeViewsHint =>
      'No account needed. Sign up to track usage and unlock more.';

  @override
  String get goPro => 'Go Pro';

  @override
  String get homeNoPapersYet => 'No papers published yet — check back soon.';

  @override
  String homePaperLabelWithYear(String label, int year) {
    return '$label $year';
  }

  @override
  String get homeFreeToView => 'Free to view — marking guide sold separately';

  @override
  String get homeContributionTitle => 'Contribution — earn credit';

  @override
  String get homeContributionPrompt =>
      'Got a past paper or report we don\'t have?';

  @override
  String get homeContributionSubtitle =>
      'Snap a photo, tag it, earn bonus credit once it\'s verified — first contribution counts.';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesSubtitle => 'Topic study notes by subject';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSubtitle => 'Partner pamphlets, QR pickup';

  @override
  String get partnerPamphletsTitle => 'Partner pamphlets';

  @override
  String get homeNoPamphlet => 'No featured pamphlet right now.';

  @override
  String homePamphletSoldBy(String partner) {
    return 'Sold by $partner · pick up with a QR code.';
  }

  @override
  String get buy => 'Buy';

  @override
  String get homeSignUpPrompt => 'SIGN UP ONLY WHEN YOU WANT TO…';

  @override
  String get homeLockedCredits => 'Earn & redeem contributor credits';

  @override
  String get homeLockedTrackContributions => 'Track your contributions';

  @override
  String get homeLockedInstructorAlerts => 'Get instructor status alerts';

  @override
  String get homeReadingOpenNote =>
      'Reading papers stays open to everyone — 3 free views a day, no account needed.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get practiceModeLabel => 'PRACTICE MODE';

  @override
  String get practiceModeTitle => 'Learn without countdown pressure';

  @override
  String get practiceModeSubtitle =>
      'Browse real past papers by subject and year.';

  @override
  String get trialLabel => 'YOUR FREE TRIAL';

  @override
  String get trialFirstUnlockFree => 'Open your first marking guide free';

  @override
  String get trialUnlimitedViews => 'Unlimited paper views during your trial';

  @override
  String trialDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get trialFeatures => 'Unlimited paper views · AI assistant';

  @override
  String get trialKeepAccess => 'Keep my access';

  @override
  String get quickActionContribute => 'Contribute';

  @override
  String get dailyChallengeLabel => 'Daily challenge';

  @override
  String get dailyChallengeLoading => 'Loading…';

  @override
  String dailyChallengeInfo(String title, int count) {
    return '$title · $count questions';
  }

  @override
  String get playNow => 'Play now';

  @override
  String streakDayCount(int count) {
    return '$count-DAY STREAK';
  }

  @override
  String get startAStreak => 'START A STREAK';

  @override
  String streakDaysCount(int count) {
    return '$count days';
  }

  @override
  String get streakStart => 'Start';

  @override
  String get streakKeepGoing => 'Keep it going';

  @override
  String get streakPlayToBegin => 'Play a quiz to begin';
}
