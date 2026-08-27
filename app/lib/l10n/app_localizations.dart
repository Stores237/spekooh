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
  /// **'WhatsApp support'**
  String get helpWhatsappTitle;

  /// No description provided for @helpWhatsappSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp'**
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

  /// No description provided for @authTermsCheckboxLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get authTermsCheckboxLabel;

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

  /// No description provided for @authErrorGuest.
  ///
  /// In en, this message translates to:
  /// **'Could not continue as guest. Check your connection and try again.'**
  String get authErrorGuest;

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
  /// **'Exploring: no account'**
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
  /// **'No papers published yet. Check back soon.'**
  String get homeNoPapersYet;

  /// No description provided for @homePaperLabelWithYear.
  ///
  /// In en, this message translates to:
  /// **'{label} {year}'**
  String homePaperLabelWithYear(String label, int year);

  /// No description provided for @homeFreeToView.
  ///
  /// In en, this message translates to:
  /// **'Free to view (marking guide sold separately)'**
  String get homeFreeToView;

  /// No description provided for @homeFreeToViewReport.
  ///
  /// In en, this message translates to:
  /// **'Free to view and download'**
  String get homeFreeToViewReport;

  /// No description provided for @homeReportPaymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment required to view'**
  String get homeReportPaymentRequired;

  /// No description provided for @homeContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution: earn credit'**
  String get homeContributionTitle;

  /// No description provided for @homeContributionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Got a past paper or report we don\'t have?'**
  String get homeContributionPrompt;

  /// No description provided for @homeContributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo, tag it, and earn bonus credit once it\'s verified. First contribution counts.'**
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
  /// **'Reading papers stays open to everyone: 3 free views a day, no account needed.'**
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

  /// No description provided for @readyOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready offline'**
  String get readyOfflineTitle;

  /// No description provided for @offlineDownloadsCount.
  ///
  /// In en, this message translates to:
  /// **'Downloads · {count}'**
  String offlineDownloadsCount(int count);

  /// No description provided for @offlineReadyTag.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE READY'**
  String get offlineReadyTag;

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

  /// No description provided for @papersTitle.
  ///
  /// In en, this message translates to:
  /// **'Past papers'**
  String get papersTitle;

  /// No description provided for @papersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every level, every system, from Primary to Concours des Grandes Écoles.'**
  String get papersSubtitle;

  /// No description provided for @searchExamOrSubject.
  ///
  /// In en, this message translates to:
  /// **'Search exam type or subject...'**
  String get searchExamOrSubject;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get categoryLabel;

  /// No description provided for @chooseSystemHeader.
  ///
  /// In en, this message translates to:
  /// **'{category}: choose system'**
  String chooseSystemHeader(String category);

  /// No description provided for @examTypeStepHeaderWithSystem.
  ///
  /// In en, this message translates to:
  /// **'{category} · {system}'**
  String examTypeStepHeaderWithSystem(String category, String system);

  /// No description provided for @searchExamType.
  ///
  /// In en, this message translates to:
  /// **'Search exam type...'**
  String get searchExamType;

  /// No description provided for @examTypeOfficialPlus.
  ///
  /// In en, this message translates to:
  /// **'Official + {variant}'**
  String examTypeOfficialPlus(String variant);

  /// No description provided for @examTypeOfficialOnly.
  ///
  /// In en, this message translates to:
  /// **'Official only'**
  String get examTypeOfficialOnly;

  /// No description provided for @chooseTrackHeader.
  ///
  /// In en, this message translates to:
  /// **'{examType}: choose track'**
  String chooseTrackHeader(String examType);

  /// No description provided for @searchSubjects.
  ///
  /// In en, this message translates to:
  /// **'Search subjects...'**
  String get searchSubjects;

  /// No description provided for @subjectCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Papers + marking guides'**
  String get subjectCardSubtitle;

  /// No description provided for @paperMarkingGuideAvailable.
  ///
  /// In en, this message translates to:
  /// **'Marking guide available'**
  String get paperMarkingGuideAvailable;

  /// No description provided for @paperUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get paperUnderReview;

  /// No description provided for @noPapersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No papers yet'**
  String get noPapersYetTitle;

  /// No description provided for @noPapersYetBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody has submitted a {subject} paper for this exam type yet. Be the first to submit one from the Submit tab.'**
  String noPapersYetBody(String subject);

  /// No description provided for @noReportsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody has submitted a {examType} yet. Be the first to submit one from the Submit tab.'**
  String noReportsYetBody(String examType);

  /// No description provided for @contributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get contributionTitle;

  /// No description provided for @contributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a past paper or an academic report. Every contribution helps another student.'**
  String get contributionSubtitle;

  /// No description provided for @contributorNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Contributor name'**
  String get contributorNameTitle;

  /// No description provided for @contributorNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No account needed to contribute. We\'ll credit this to the name you give us.'**
  String get contributorNameSubtitle;

  /// No description provided for @contributorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get contributorNameLabel;

  /// No description provided for @examPaperTab.
  ///
  /// In en, this message translates to:
  /// **'Exam paper'**
  String get examPaperTab;

  /// No description provided for @academicReportTab.
  ///
  /// In en, this message translates to:
  /// **'Academic report'**
  String get academicReportTab;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get notAvailableYet;

  /// No description provided for @academicReportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Academic report submissions aren\'t wired to the backend yet. Only exam papers can be submitted right now. Check back soon.'**
  String get academicReportComingSoon;

  /// No description provided for @takePhotoOrUploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload a PDF'**
  String get takePhotoOrUploadPdf;

  /// No description provided for @fileFormatsHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF · up to 20MB'**
  String get fileFormatsHint;

  /// No description provided for @fileFormatsHintWithSize.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF · up to {maxMb}MB'**
  String fileFormatsHintWithSize(int maxMb);

  /// No description provided for @tapToReplace.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace'**
  String get tapToReplace;

  /// No description provided for @educationLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Education level'**
  String get educationLevelLabel;

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLabel;

  /// No description provided for @examTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam type'**
  String get examTypeLabel;

  /// No description provided for @trackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackLabel;

  /// No description provided for @subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectLabel;

  /// No description provided for @addCustomSubject.
  ///
  /// In en, this message translates to:
  /// **'Add a subject'**
  String get addCustomSubject;

  /// No description provided for @customSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Geology'**
  String get customSubjectHint;

  /// No description provided for @addCustomSubjectCta.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addCustomSubjectCta;

  /// No description provided for @addCustomSubjectError.
  ///
  /// In en, this message translates to:
  /// **'Could not add that subject. Try again.'**
  String get addCustomSubjectError;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @examBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Exam board / school (optional)'**
  String get examBoardHint;

  /// No description provided for @contributionBonusBanner.
  ///
  /// In en, this message translates to:
  /// **'New, verified submissions earn bonus credit, redeemable toward marking-guide unlocks.'**
  String get contributionBonusBanner;

  /// No description provided for @submitPaperButton.
  ///
  /// In en, this message translates to:
  /// **'Submit paper'**
  String get submitPaperButton;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get reportTypeLabel;

  /// No description provided for @institutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Institution / University'**
  String get institutionLabel;

  /// No description provided for @disciplineLabel.
  ///
  /// In en, this message translates to:
  /// **'Discipline / Department'**
  String get disciplineLabel;

  /// No description provided for @supervisorOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Supervisor (optional)'**
  String get supervisorOptionalLabel;

  /// No description provided for @submitReportButton.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReportButton;

  /// No description provided for @selectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPlaceholder;

  /// No description provided for @nothingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Nothing available.'**
  String get nothingAvailable;

  /// No description provided for @submitAnother.
  ///
  /// In en, this message translates to:
  /// **'Submit another'**
  String get submitAnother;

  /// No description provided for @contributionReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution received'**
  String get contributionReceivedTitle;

  /// No description provided for @contributionReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll check it against existing papers first. If it\'s new, it moves to instructor review. Track it under Profile.'**
  String get contributionReceivedBody;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String submissionFailed(String error);

  /// No description provided for @fileTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'File is too large. This report type allows up to {maxMb}MB.'**
  String fileTooLargeError(int maxMb);

  /// No description provided for @choosePdfOrImage.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF or image'**
  String get choosePdfOrImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @forumFilterMySubjects.
  ///
  /// In en, this message translates to:
  /// **'My subjects'**
  String get forumFilterMySubjects;

  /// No description provided for @forumFilterUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get forumFilterUnanswered;

  /// No description provided for @forumFilterSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get forumFilterSolved;

  /// No description provided for @forumMySubjectsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Personalizing by subject isn\'t available yet.'**
  String get forumMySubjectsUnavailable;

  /// No description provided for @forumSolvedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Marking questions as solved isn\'t available yet.'**
  String get forumSolvedUnavailable;

  /// No description provided for @forumNoUnanswered.
  ///
  /// In en, this message translates to:
  /// **'No unanswered questions right now.'**
  String get forumNoUnanswered;

  /// No description provided for @forumNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first to ask.'**
  String get forumNoPosts;

  /// No description provided for @forumAskButton.
  ///
  /// In en, this message translates to:
  /// **'+ Question'**
  String get forumAskButton;

  /// No description provided for @forumAnswersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} answers'**
  String forumAnswersCount(int count);

  /// No description provided for @questionTitle.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionTitle;

  /// No description provided for @repliesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} replies'**
  String repliesCount(int count);

  /// No description provided for @writeReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get writeReplyHint;

  /// No description provided for @askForumTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the forum'**
  String get askForumTitle;

  /// No description provided for @askSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Subject (e.g. Physics)'**
  String get askSubjectHint;

  /// No description provided for @askQuestionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Question title'**
  String get askQuestionTitleHint;

  /// No description provided for @askExplainHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what you need help with…'**
  String get askExplainHint;

  /// No description provided for @askFormRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Title and question are required.'**
  String get askFormRequiredError;

  /// No description provided for @postingLabel.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get postingLabel;

  /// No description provided for @postQuestionButton.
  ///
  /// In en, this message translates to:
  /// **'Post question'**
  String get postQuestionButton;

  /// No description provided for @quizzesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizzesPageTitle;

  /// No description provided for @dailyChallengeCapsLabel.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get dailyChallengeCapsLabel;

  /// No description provided for @resetsInLabel.
  ///
  /// In en, this message translates to:
  /// **'Resets in {hours}h {minutes}m'**
  String resetsInLabel(int hours, int minutes);

  /// No description provided for @dailyQuestionsAndPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {played} students played'**
  String dailyQuestionsAndPlayed(int count, int played);

  /// No description provided for @dailyStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String dailyStreakLabel(int count);

  /// No description provided for @playDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Play daily challenge'**
  String get playDailyChallenge;

  /// No description provided for @timedPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Timed practice'**
  String get timedPracticeTitle;

  /// No description provided for @timedPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exam conditions'**
  String get timedPracticeSubtitle;

  /// No description provided for @revisionModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revision mode'**
  String get revisionModeTitle;

  /// No description provided for @revisionModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No timer, hints on'**
  String get revisionModeSubtitle;

  /// No description provided for @pastPaperPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Past-paper practice'**
  String get pastPaperPracticeTitle;

  /// No description provided for @pastPaperPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated from submitted papers (coming soon)'**
  String get pastPaperPracticeSubtitle;

  /// No description provided for @fridayArenaTitle.
  ///
  /// In en, this message translates to:
  /// **'Friday Arena'**
  String get fridayArenaTitle;

  /// No description provided for @fridayArenaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live elimination quiz (coming soon)'**
  String get fridayArenaSubtitle;

  /// No description provided for @topPlayers.
  ///
  /// In en, this message translates to:
  /// **'Top players'**
  String get topPlayers;

  /// No description provided for @bySubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'By subject'**
  String get bySubjectTitle;

  /// No description provided for @statQuestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get statQuestionsLabel;

  /// No description provided for @statSuggestedLabel.
  ///
  /// In en, this message translates to:
  /// **'suggested'**
  String get statSuggestedLabel;

  /// No description provided for @statPlayedLabel.
  ///
  /// In en, this message translates to:
  /// **'played'**
  String get statPlayedLabel;

  /// No description provided for @timerRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Timer 8:00'**
  String get timerRowLabel;

  /// No description provided for @hintsRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Hints  2 available'**
  String get hintsRowLabel;

  /// No description provided for @shuffleRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffle questions'**
  String get shuffleRowLabel;

  /// No description provided for @quizScoreLine.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} / {total}'**
  String quizScoreLine(int score, int total);

  /// No description provided for @startQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuizButton;

  /// No description provided for @submittingLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submittingLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @submissionsCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} submissions'**
  String submissionsCountBadge(int count);

  /// No description provided for @quizzesCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} quizzes'**
  String quizzesCountBadge(int count);

  /// No description provided for @bonusCreditBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'BONUS CREDIT BALANCE'**
  String get bonusCreditBalanceLabel;

  /// No description provided for @ptsLabel.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get ptsLabel;

  /// No description provided for @submissionsScaleNote.
  ///
  /// In en, this message translates to:
  /// **'{count} papers submitted · redeem code value scales with your contributions'**
  String submissionsScaleNote(int count);

  /// No description provided for @redeemCodeNotActive.
  ///
  /// In en, this message translates to:
  /// **'No active redeem code'**
  String get redeemCodeNotActive;

  /// No description provided for @redeemCodeReady.
  ///
  /// In en, this message translates to:
  /// **'Redeem code ready'**
  String get redeemCodeReady;

  /// No description provided for @redeemCodeEarnHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get one once a verified submission earns a bonus tier.'**
  String get redeemCodeEarnHint;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @shareRedeemCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Use my Spekooh redeem code {code}: {subtitle}'**
  String shareRedeemCodeMessage(String code, String subtitle);

  /// No description provided for @shareRedeemCodeSubject.
  ///
  /// In en, this message translates to:
  /// **'Spekooh redeem code'**
  String get shareRedeemCodeSubject;

  /// No description provided for @inviteAFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend'**
  String get inviteAFriendTitle;

  /// No description provided for @inviteAFriendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You earn bonus credit once they unlock their first paper.'**
  String get inviteAFriendSubtitle;

  /// No description provided for @shareReferralMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Spekooh. Sign up with my referral code {code}.'**
  String shareReferralMessage(String code);

  /// No description provided for @shareReferralSubject.
  ///
  /// In en, this message translates to:
  /// **'Spekooh referral code'**
  String get shareReferralSubject;

  /// No description provided for @badgesSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesSectionLabel;

  /// No description provided for @submissionStatusSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Submission status'**
  String get submissionStatusSectionLabel;

  /// No description provided for @profileLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your profile'**
  String get profileLoginPrompt;

  /// No description provided for @profileLoginPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your submissions, credit balance, and badges show up here once you have an account.'**
  String get profileLoginPromptSubtitle;

  /// No description provided for @shopHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Partner pamphlets · pay in-app, pick up with a QR code'**
  String get shopHeaderSubtitle;

  /// No description provided for @searchPamphlets.
  ///
  /// In en, this message translates to:
  /// **'Search pamphlets...'**
  String get searchPamphlets;

  /// No description provided for @pamphletSoldByQr.
  ///
  /// In en, this message translates to:
  /// **'Sold by {partner} · QR pickup'**
  String pamphletSoldByQr(String partner);

  /// No description provided for @notesScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Topic study notes, contributed alongside papers'**
  String get notesScreenSubtitle;

  /// No description provided for @searchTopics.
  ///
  /// In en, this message translates to:
  /// **'Search topics...'**
  String get searchTopics;

  /// No description provided for @academicLevelFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get academicLevelFilterLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @adNotCompletedError.
  ///
  /// In en, this message translates to:
  /// **'Ad not completed. No view granted.'**
  String get adNotCompletedError;

  /// No description provided for @adLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load an ad: {error}'**
  String adLoadError(String error);

  /// No description provided for @unlockFailedError.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed: {error}'**
  String unlockFailedError(String error);

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file.'**
  String get couldNotOpenFile;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;

  /// No description provided for @viewOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'View only. Unlock to download a copy'**
  String get viewOnlyNotice;

  /// No description provided for @reportThanksMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks! The Review Team has been notified.'**
  String get reportThanksMessage;

  /// No description provided for @reportSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send report: {error}'**
  String reportSendError(String error);

  /// No description provided for @noPaperSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'No paper selected'**
  String get noPaperSelectedTitle;

  /// No description provided for @noPaperSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'Browse the Papers tab and pick a subject to open a real paper.'**
  String get noPaperSelectedBody;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @publishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedStatus;

  /// No description provided for @reportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with this paper'**
  String get reportTooltip;

  /// No description provided for @noScannedFileYet.
  ///
  /// In en, this message translates to:
  /// **'No scanned file on this submission yet.'**
  String get noScannedFileYet;

  /// No description provided for @openScannedPaper.
  ///
  /// In en, this message translates to:
  /// **'Open scanned paper'**
  String get openScannedPaper;

  /// No description provided for @saveOffline.
  ///
  /// In en, this message translates to:
  /// **'Save offline'**
  String get saveOffline;

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline'**
  String get offlineSaved;

  /// No description provided for @offlineSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save for offline: {error}'**
  String offlineSaveError(String error);

  /// No description provided for @examBoardLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam board: {board}'**
  String examBoardLabel(String board);

  /// No description provided for @watchAdForView.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for +1 view'**
  String get watchAdForView;

  /// No description provided for @markingGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Marking guide'**
  String get markingGuideTitle;

  /// No description provided for @markingGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instructor-authored + in-house MCQ key'**
  String get markingGuideSubtitle;

  /// No description provided for @reportDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download access'**
  String get reportDownloadTitle;

  /// No description provided for @reportDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Viewing in the app is free. Unlock once to save a copy for offline reading'**
  String get reportDownloadSubtitle;

  /// No description provided for @unlockedForAmount.
  ///
  /// In en, this message translates to:
  /// **'Unlocked for {amount} FCFA.'**
  String unlockedForAmount(int amount);

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock: 500 FCFA'**
  String get unlockButton;

  /// No description provided for @alreadyUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked.'**
  String get alreadyUnlocked;

  /// No description provided for @viewButton.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewButton;

  /// No description provided for @reportLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This report requires unlocking'**
  String get reportLockedTitle;

  /// No description provided for @reportLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'PhD and Master\'s theses require payment to view. Unlock below to read it.'**
  String get reportLockedMessage;

  /// No description provided for @unlockToDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock below to save a copy for offline reading.'**
  String get unlockToDownloadHint;

  /// No description provided for @haveRedeemCode.
  ///
  /// In en, this message translates to:
  /// **'Have a redeem code?'**
  String get haveRedeemCode;

  /// No description provided for @redeemCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Redeem code'**
  String get redeemCodeHint;

  /// No description provided for @mcqDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.'**
  String get mcqDisclaimer;

  /// No description provided for @reportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportDialogTitle;

  /// No description provided for @reportWhatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get reportWhatsWrong;

  /// No description provided for @reportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetailsOptional;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @contributeNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Help other students'**
  String get contributeNudgeTitle;

  /// No description provided for @contributeNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'If you have a past paper or academic report, submitting it accurately and as soon as you can helps other students who need it right now. Every contribution makes a real difference.'**
  String get contributeNudgeBody;

  /// No description provided for @contributeNudgeCta.
  ///
  /// In en, this message translates to:
  /// **'Contribute now'**
  String get contributeNudgeCta;

  /// No description provided for @contributeNudgeDismiss.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get contributeNudgeDismiss;

  /// No description provided for @reasonWrongAnswers.
  ///
  /// In en, this message translates to:
  /// **'Wrong or missing answers'**
  String get reasonWrongAnswers;

  /// No description provided for @reasonPoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor scan quality / unreadable'**
  String get reasonPoorQuality;

  /// No description provided for @reasonWrongSubject.
  ///
  /// In en, this message translates to:
  /// **'Wrong subject or exam type'**
  String get reasonWrongSubject;

  /// No description provided for @reasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of another paper'**
  String get reasonDuplicate;

  /// No description provided for @reasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright concern'**
  String get reasonCopyright;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @paywallEnterPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter your MTN MoMo or Orange Money number.'**
  String get paywallEnterPhoneError;

  /// No description provided for @paywallSubscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed: {error}'**
  String paywallSubscriptionFailed(String error);

  /// No description provided for @paywallYoureProTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Pro'**
  String get paywallYoureProTitle;

  /// No description provided for @paywallGetProTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Spekooh Pro'**
  String get paywallGetProTitle;

  /// No description provided for @paywallRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}.'**
  String paywallRenewsOn(String date);

  /// No description provided for @paywallDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlimited question-paper views and an ad-free app. Marking guides are always unlocked separately.'**
  String get paywallDescription;

  /// No description provided for @paywallBenefitViews.
  ///
  /// In en, this message translates to:
  /// **'Unlimited question paper views'**
  String get paywallBenefitViews;

  /// No description provided for @paywallBenefitAds.
  ///
  /// In en, this message translates to:
  /// **'Zero ads while you study'**
  String get paywallBenefitAds;

  /// No description provided for @paywallBenefitAlerts.
  ///
  /// In en, this message translates to:
  /// **'Instructor status alerts'**
  String get paywallBenefitAlerts;

  /// No description provided for @spekoohProCaps.
  ///
  /// In en, this message translates to:
  /// **'SPEKOOH PRO'**
  String get spekoohProCaps;

  /// No description provided for @momoOrangeLabel.
  ///
  /// In en, this message translates to:
  /// **'MTN MOMO OR ORANGE MONEY NUMBER'**
  String get momoOrangeLabel;

  /// No description provided for @payButton.
  ///
  /// In en, this message translates to:
  /// **'Pay 500 FCFA'**
  String get payButton;

  /// No description provided for @paywallDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Official Spekooh merchant · we never ask for your PIN · receipt + SMS within 2 min'**
  String get paywallDisclaimer;

  /// No description provided for @pamphletSoldBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by {partner}'**
  String pamphletSoldBy(String partner);

  /// No description provided for @escrowExplanation.
  ///
  /// In en, this message translates to:
  /// **'Spekooh holds your payment in escrow. You\'ll get a one-time QR ticket to collect it at the bookshop. Payment only releases to the partner once they scan it.'**
  String get escrowExplanation;

  /// No description provided for @pickupInStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP · IN-STORE'**
  String get pickupInStoreLabel;

  /// No description provided for @payAndReserve.
  ///
  /// In en, this message translates to:
  /// **'Pay & reserve: {amount} FCFA'**
  String payAndReserve(String amount);

  /// No description provided for @processingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processingLabel;

  /// No description provided for @escrowFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Held in escrow · released to partner only after pickup is confirmed · 5% platform commission'**
  String get escrowFooterNote;

  /// No description provided for @pickupTicketReady.
  ///
  /// In en, this message translates to:
  /// **'Pickup ticket ready'**
  String get pickupTicketReady;

  /// No description provided for @showQrAtPartner.
  ///
  /// In en, this message translates to:
  /// **'Show this QR at {partner}. Single-use, expires in 30 days. Payment releases to the partner once they scan it.'**
  String showQrAtPartner(String partner);

  /// No description provided for @ticketRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket ref: {ref}…'**
  String ticketRefLabel(String ref);

  /// No description provided for @paymentFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Check your connection and try again.'**
  String get paymentFailedGeneric;

  /// No description provided for @paywallBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Daily free view limit reached. Watch a rewarded ad or upgrade to Pro.'**
  String get paywallBlockedMessage;

  /// No description provided for @alreadyReportedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reported this paper.'**
  String get alreadyReportedMessage;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Spekooh Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explains topics using real past papers'**
  String get aiAssistantSubtitle;

  /// No description provided for @aiPromptExplainPhysics.
  ///
  /// In en, this message translates to:
  /// **'Explain a hard Physics topic'**
  String get aiPromptExplainPhysics;

  /// No description provided for @aiPromptMathsQuestions.
  ///
  /// In en, this message translates to:
  /// **'Give me 5 Maths practice questions'**
  String get aiPromptMathsQuestions;

  /// No description provided for @aiPromptSummarizeGuide.
  ///
  /// In en, this message translates to:
  /// **'Summarize this paper\'s marking guide'**
  String get aiPromptSummarizeGuide;

  /// No description provided for @aiAssistantInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about a topic or paper...'**
  String get aiAssistantInputHint;
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
