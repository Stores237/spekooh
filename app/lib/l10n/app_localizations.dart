import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Papers'**
  String get navPapers;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get navForum;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get navQuizzes;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account & app'**
  String get settingsSubtitle;

  /// No description provided for @spekoohProTitle.
  ///
  /// In en, this message translates to:
  /// **'Spekooh Pro'**
  String get spekoohProTitle;

  /// No description provided for @spekoohProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited paper views · no ads'**
  String get spekoohProSubtitle;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @helpSection.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpSection;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupportTitle;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with a real person'**
  String get helpSupportSubtitle;

  /// No description provided for @helpWhatsappTitle.
  ///
  /// In en, this message translates to:
  /// **'Join our WhatsApp group'**
  String get helpWhatsappTitle;

  /// No description provided for @helpWhatsappSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips & updates'**
  String get helpWhatsappSubtitle;

  /// No description provided for @helpContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get helpContactTitle;

  /// No description provided for @helpContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions or feedback'**
  String get helpContactSubtitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutWebsiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit our website'**
  String get aboutWebsiteTitle;

  /// No description provided for @aboutPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacyTitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccountTitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Spekooh'**
  String get authLoginTitle;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authNameHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get authPasswordLabel;

  /// No description provided for @authReferralLabel.
  ///
  /// In en, this message translates to:
  /// **'REFERRAL CODE (OPTIONAL)'**
  String get authReferralLabel;

  /// No description provided for @authReferralHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. A1B2C3D4'**
  String get authReferralHint;

  /// No description provided for @authPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get authPleaseWait;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginButton;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authSwitchToLogin;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authSwitchToRegister;

  /// No description provided for @authErrorLogin.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your email and password.'**
  String get authErrorLogin;

  /// No description provided for @authErrorRegisterReferral.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Check your details, and that the referral code is correct.'**
  String get authErrorRegisterReferral;

  /// No description provided for @authErrorRegisterGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. That email may already be in use.'**
  String get authErrorRegisterGeneric;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get authErrorUnknown;

  /// No description provided for @homeWelcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcomeGreeting;

  /// No description provided for @guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestLabel;

  /// No description provided for @joinFree.
  ///
  /// In en, this message translates to:
  /// **'Join free'**
  String get joinFree;

  /// No description provided for @homeExploringBadge.
  ///
  /// In en, this message translates to:
  /// **'Exploring — no account'**
  String get homeExploringBadge;

  /// No description provided for @homeFreeViewsLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE PAPER VIEWS'**
  String get homeFreeViewsLabel;

  /// No description provided for @homeFreeViewsCount.
  ///
  /// In en, this message translates to:
  /// **'3 a day'**
  String get homeFreeViewsCount;

  /// No description provided for @homeFreeViewsHint.
  ///
  /// In en, this message translates to:
  /// **'No account needed. Sign up to track usage and unlock more.'**
  String get homeFreeViewsHint;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @homeNoPapersYet.
  ///
  /// In en, this message translates to:
  /// **'No papers published yet — check back soon.'**
  String get homeNoPapersYet;

  /// No description provided for @homePaperLabelWithYear.
  ///
  /// In en, this message translates to:
  /// **'{label} {year}'**
  String homePaperLabelWithYear(String label, int year);

  /// No description provided for @homeFreeToView.
  ///
  /// In en, this message translates to:
  /// **'Free to view — marking guide sold separately'**
  String get homeFreeToView;

  /// No description provided for @homeContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution — earn credit'**
  String get homeContributionTitle;

  /// No description provided for @homeContributionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Got a past paper or report we don\'t have?'**
  String get homeContributionPrompt;

  /// No description provided for @homeContributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo, tag it, earn bonus credit once it\'s verified — first contribution counts.'**
  String get homeContributionSubtitle;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @notesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Topic study notes by subject'**
  String get notesSubtitle;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Partner pamphlets, QR pickup'**
  String get shopSubtitle;

  /// No description provided for @partnerPamphletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner pamphlets'**
  String get partnerPamphletsTitle;

  /// No description provided for @homeNoPamphlet.
  ///
  /// In en, this message translates to:
  /// **'No featured pamphlet right now.'**
  String get homeNoPamphlet;

  /// No description provided for @homePamphletSoldBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by {partner} · pick up with a QR code.'**
  String homePamphletSoldBy(String partner);

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @homeSignUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP ONLY WHEN YOU WANT TO…'**
  String get homeSignUpPrompt;

  /// No description provided for @homeLockedCredits.
  ///
  /// In en, this message translates to:
  /// **'Earn & redeem contributor credits'**
  String get homeLockedCredits;

  /// No description provided for @homeLockedTrackContributions.
  ///
  /// In en, this message translates to:
  /// **'Track your contributions'**
  String get homeLockedTrackContributions;

  /// No description provided for @homeLockedInstructorAlerts.
  ///
  /// In en, this message translates to:
  /// **'Get instructor status alerts'**
  String get homeLockedInstructorAlerts;

  /// No description provided for @homeReadingOpenNote.
  ///
  /// In en, this message translates to:
  /// **'Reading papers stays open to everyone — 3 free views a day, no account needed.'**
  String get homeReadingOpenNote;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @practiceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE MODE'**
  String get practiceModeLabel;

  /// No description provided for @practiceModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn without countdown pressure'**
  String get practiceModeTitle;

  /// No description provided for @practiceModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse real past papers by subject and year.'**
  String get practiceModeSubtitle;

  /// No description provided for @trialLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR FREE TRIAL'**
  String get trialLabel;

  /// No description provided for @trialFirstUnlockFree.
  ///
  /// In en, this message translates to:
  /// **'Open your first marking guide free'**
  String get trialFirstUnlockFree;

  /// No description provided for @trialUnlimitedViews.
  ///
  /// In en, this message translates to:
  /// **'Unlimited paper views during your trial'**
  String get trialUnlimitedViews;

  /// No description provided for @trialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String trialDaysLeft(int days);

  /// No description provided for @trialFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlimited paper views · AI assistant'**
  String get trialFeatures;

  /// No description provided for @trialKeepAccess.
  ///
  /// In en, this message translates to:
  /// **'Keep my access'**
  String get trialKeepAccess;

  /// No description provided for @quickActionContribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get quickActionContribute;

  /// No description provided for @dailyChallengeLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallengeLabel;

  /// No description provided for @dailyChallengeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get dailyChallengeLoading;

  /// No description provided for @dailyChallengeInfo.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count} questions'**
  String dailyChallengeInfo(String title, int count);

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @streakDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count}-DAY STREAK'**
  String streakDayCount(int count);

  /// No description provided for @startAStreak.
  ///
  /// In en, this message translates to:
  /// **'START A STREAK'**
  String get startAStreak;

  /// No description provided for @streakDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakDaysCount(int count);

  /// No description provided for @streakStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get streakStart;

  /// No description provided for @streakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it going'**
  String get streakKeepGoing;

  /// No description provided for @streakPlayToBegin.
  ///
  /// In en, this message translates to:
  /// **'Play a quiz to begin'**
  String get streakPlayToBegin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
