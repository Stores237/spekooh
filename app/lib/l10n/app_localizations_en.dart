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
  String get accountSection => 'Account';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'We\'ll email you a code to confirm it\'s you';

  @override
  String get languageSection => 'Language';

  @override
  String get helpSection => 'Help';

  @override
  String get helpSupportTitle => 'Help & support';

  @override
  String get helpSupportSubtitle => 'Chat with a real person';

  @override
  String get helpWhatsappTitle => 'WhatsApp support';

  @override
  String get helpWhatsappSubtitle => 'Chat with us on WhatsApp';

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
  String get authTermsCheckboxLabel =>
      'I agree to the Terms of Service and Privacy Policy';

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
  String get authErrorLoginEmailNotVerified =>
      'Please verify your email before logging in.';

  @override
  String get verifyEmailLoginRecoveryDoneMessage =>
      'Email verified — log in again to continue.';

  @override
  String get authErrorRegisterReferral =>
      'Registration failed. Check your details, and that the referral code is correct.';

  @override
  String get authErrorRegisterGeneric =>
      'Registration failed. That email may already be in use.';

  @override
  String get authErrorRegisterInvalidEmailDomain =>
      'That email domain doesn\'t appear to accept mail. Check for a typo.';

  @override
  String get authErrorGuest =>
      'Could not continue as guest. Check your connection and try again.';

  @override
  String get authErrorUnknown =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get authErrorPasswordResetRequest =>
      'Could not send a reset code. Check your connection and try again.';

  @override
  String get authErrorPasswordResetConfirm =>
      'That code is invalid or has expired.';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordEmailPrompt =>
      'Enter your email and we\'ll send you a reset code.';

  @override
  String get resetPasswordCodeSentMessage =>
      'If that email is registered, a code is on its way. Enter it below along with a new password.';

  @override
  String get resetPasswordCodeLabel => 'CODE';

  @override
  String get resetPasswordCodeHint => '6-digit code';

  @override
  String get resetPasswordNewPasswordLabel => 'NEW PASSWORD';

  @override
  String get resetPasswordSendCodeButton => 'Send code';

  @override
  String get resetPasswordConfirmButton => 'Reset password';

  @override
  String get resetPasswordBackToLogin => 'Back to log in';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailPrompt =>
      'We sent a code to your email. Enter it below to verify your account.';

  @override
  String get verifyEmailCodeLabel => 'CODE';

  @override
  String get verifyEmailCodeHint => '6-digit code';

  @override
  String get verifyEmailConfirmButton => 'Verify';

  @override
  String get verifyEmailResendLink => 'Resend code';

  @override
  String get verifyEmailResendSentMessage => 'A new code is on its way.';

  @override
  String get verifyEmailSkipLink => 'Skip for now';

  @override
  String get authErrorEmailVerificationConfirm =>
      'That code is invalid or has expired.';

  @override
  String get authErrorEmailVerificationResend =>
      'Could not resend a verification code. Check your connection and try again.';

  @override
  String get homeWelcomeGreeting => 'Welcome';

  @override
  String get guestLabel => 'Guest';

  @override
  String get joinFree => 'Join free';

  @override
  String get homeExploringBadge => 'Exploring: no account';

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
  String get homeNoPapersYet => 'No papers published yet. Check back soon.';

  @override
  String homePaperLabelWithYear(String label, int year) {
    return '$label $year';
  }

  @override
  String get homeFreeToView => 'Free to view (marking guide sold separately)';

  @override
  String get homeFreeToViewReport => 'Free to view and download';

  @override
  String get homeReportPaymentRequired => 'Payment required to view';

  @override
  String get homeContributionTitle => 'Contribution: earn credit';

  @override
  String get homeContributionPrompt =>
      'Got a past paper or report we don\'t have?';

  @override
  String get homeContributionSubtitle =>
      'Snap a photo, tag it, and earn bonus credit once it\'s verified. First contribution counts.';

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
      'Reading papers stays open to everyone: 3 free views a day, no account needed.';

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
  String get readyOfflineTitle => 'Ready offline';

  @override
  String offlineDownloadsCount(int count) {
    return 'Downloads · $count';
  }

  @override
  String get offlineReadyTag => 'OFFLINE READY';

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

  @override
  String get papersTitle => 'Past papers';

  @override
  String get papersSubtitle =>
      'Every level, every system, from Primary to Concours des Grandes Écoles.';

  @override
  String get categoryLabel => 'CATEGORY';

  @override
  String chooseSystemHeader(String category) {
    return '$category: choose system';
  }

  @override
  String examTypeStepHeaderWithSystem(String category, String system) {
    return '$category · $system';
  }

  @override
  String examTypeOfficialPlus(String variant) {
    return 'Official + $variant';
  }

  @override
  String get examTypeOfficialOnly => 'Official only';

  @override
  String chooseTrackHeader(String examType) {
    return '$examType: choose track';
  }

  @override
  String get searchSubjects => 'Search subjects...';

  @override
  String get subjectCardSubtitle => 'Papers + marking guides';

  @override
  String get paperMarkingGuideAvailable => 'Marking guide available';

  @override
  String get paperMarkingGuideNotYetAvailable =>
      'Marking guide not yet available';

  @override
  String get paperUnderReview => 'Under review';

  @override
  String get noPapersYetTitle => 'No papers yet';

  @override
  String noPapersYetBody(String subject) {
    return 'Nobody has submitted a $subject paper for this exam type yet. Be the first to submit one from the Submit tab.';
  }

  @override
  String noReportsYetBody(String examType) {
    return 'Nobody has submitted a $examType yet. Be the first to submit one from the Submit tab.';
  }

  @override
  String get searchPapersInCategory => 'Search by year...';

  @override
  String get paperSearchNoResultsTitle => 'No matches';

  @override
  String get paperSearchNoResultsBody => 'No papers here match your search.';

  @override
  String get contributionTitle => 'Contribution';

  @override
  String get contributionSubtitle =>
      'Share a past paper or an academic report. Every contribution helps another student.';

  @override
  String get contributorNameTitle => 'Contributor name';

  @override
  String get contributorNameSubtitle =>
      'No account needed to contribute. We\'ll credit this to the name you give us.';

  @override
  String get contributorNameLabel => 'Your name';

  @override
  String get examPaperTab => 'Exam paper';

  @override
  String get academicReportTab => 'Academic report';

  @override
  String get notAvailableYet => 'Not available yet';

  @override
  String get academicReportComingSoon =>
      'Academic report submissions aren\'t wired to the backend yet. Only exam papers can be submitted right now. Check back soon.';

  @override
  String get takePhotoOrUploadPdf => 'Take a photo or upload a PDF';

  @override
  String get fileFormatsHint => 'JPG, PNG or PDF · up to 20MB';

  @override
  String fileFormatsHintWithSize(int maxMb) {
    return 'JPG, PNG or PDF · up to ${maxMb}MB';
  }

  @override
  String get tapToReplace => 'Tap to replace';

  @override
  String get educationLevelLabel => 'Education level';

  @override
  String get systemLabel => 'System';

  @override
  String get examTypeLabel => 'Exam type';

  @override
  String get trackLabel => 'Track';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get addCustomSubject => 'Add a subject';

  @override
  String get customSubjectHint => 'e.g. Geology';

  @override
  String get addCustomSubjectCta => 'Add';

  @override
  String get addCustomSubjectError => 'Could not add that subject. Try again.';

  @override
  String get contributorNameRequiredForSubjectError =>
      'Enter your name above first, so we know who to credit.';

  @override
  String get yearLabel => 'Year';

  @override
  String get examBoardHint => 'Exam board / school (optional)';

  @override
  String get contributionBonusBanner =>
      'New, verified submissions earn bonus credit, redeemable toward marking-guide unlocks.';

  @override
  String get submitPaperButton => 'Submit paper';

  @override
  String get reportTypeLabel => 'Report type';

  @override
  String get institutionLabel => 'Institution / University';

  @override
  String get disciplineLabel => 'Discipline / Department';

  @override
  String get supervisorOptionalLabel => 'Supervisor (optional)';

  @override
  String get submitReportButton => 'Submit report';

  @override
  String get selectPlaceholder => 'Select';

  @override
  String get nothingAvailable => 'Nothing available.';

  @override
  String get submitAnother => 'Submit another';

  @override
  String get contributionReceivedTitle => 'Contribution received';

  @override
  String get contributionReceivedBody =>
      'We\'ll check it against existing papers first. If it\'s new, it moves to instructor review. Track it under Profile.';

  @override
  String submissionFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String fileTooLargeError(int maxMb) {
    return 'File is too large. This report type allows up to ${maxMb}MB.';
  }

  @override
  String get choosePdfOrImage => 'Choose PDF or image';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get avatarUploadError =>
      'Could not update your photo. Check your connection and try again.';

  @override
  String get filterAll => 'All';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterDone => 'Done';

  @override
  String get forumFilterMySubjects => 'My subjects';

  @override
  String get forumFilterUnanswered => 'Unanswered';

  @override
  String get forumFilterSolved => 'Solved';

  @override
  String get forumMySubjectsUnavailable =>
      'Personalizing by subject isn\'t available yet.';

  @override
  String get forumSolvedUnavailable =>
      'Marking questions as solved isn\'t available yet.';

  @override
  String get forumNoUnanswered => 'No unanswered questions right now.';

  @override
  String get forumNoPosts => 'No posts yet. Be the first to ask.';

  @override
  String get forumAskButton => '+ Question';

  @override
  String forumAnswersCount(int count) {
    return '$count answers';
  }

  @override
  String get questionTitle => 'Question';

  @override
  String repliesCount(int count) {
    return '$count replies';
  }

  @override
  String get writeReplyHint => 'Write a reply…';

  @override
  String get askForumTitle => 'Ask the forum';

  @override
  String get askSubjectHint => 'Subject (e.g. Physics)';

  @override
  String get askQuestionTitleHint => 'Question title';

  @override
  String get askExplainHint => 'Explain what you need help with…';

  @override
  String get askFormRequiredError => 'Title and question are required.';

  @override
  String get postingLabel => 'Posting…';

  @override
  String get postQuestionButton => 'Post question';

  @override
  String get quizzesPageTitle => 'Quiz';

  @override
  String get dailyChallengeCapsLabel => 'DAILY CHALLENGE';

  @override
  String resetsInLabel(int hours, int minutes) {
    return 'Resets in ${hours}h ${minutes}m';
  }

  @override
  String dailyQuestionsAndPlayed(int count, int played) {
    return '$count questions · $played students played';
  }

  @override
  String dailyStreakLabel(int count) {
    return '$count-day streak';
  }

  @override
  String get playDailyChallenge => 'Play daily challenge';

  @override
  String get timedPracticeTitle => 'Timed practice';

  @override
  String get timedPracticeSubtitle => 'Exam conditions';

  @override
  String get revisionModeTitle => 'Revision mode';

  @override
  String get revisionModeSubtitle => 'No timer, hints on';

  @override
  String get pastPaperPracticeTitle => 'Past-paper practice';

  @override
  String get pastPaperPracticeSubtitle =>
      'Auto-generated from submitted papers (coming soon)';

  @override
  String get fridayArenaTitle => 'Friday Arena';

  @override
  String get fridayArenaSubtitle => 'Live elimination quiz (coming soon)';

  @override
  String get topPlayers => 'Top players';

  @override
  String get bySubjectTitle => 'By subject';

  @override
  String get statQuestionsLabel => 'questions';

  @override
  String get statSuggestedLabel => 'suggested';

  @override
  String get statPlayedLabel => 'played';

  @override
  String get timerRowLabel => 'Timer 8:00';

  @override
  String get hintsRowLabel => 'Hints  2 available';

  @override
  String get shuffleRowLabel => 'Shuffle questions';

  @override
  String quizScoreLine(int score, int total) {
    return 'You scored $score / $total';
  }

  @override
  String get startQuizButton => 'Start quiz';

  @override
  String get submittingLabel => 'Submitting…';

  @override
  String get doneLabel => 'Done';

  @override
  String get profileTitle => 'Profile';

  @override
  String submissionsCountBadge(int count) {
    return '$count submissions';
  }

  @override
  String quizzesCountBadge(int count) {
    return '$count quizzes';
  }

  @override
  String get bonusCreditBalanceLabel => 'BONUS CREDIT BALANCE';

  @override
  String get ptsLabel => 'pts';

  @override
  String submissionsScaleNote(int count) {
    return '$count papers submitted · redeem code value scales with your contributions';
  }

  @override
  String get redeemCodeNotActive => 'No active redeem code';

  @override
  String get redeemCodeReady => 'Redeem code ready';

  @override
  String get redeemCodeEarnHint =>
      'You\'ll get one once a verified submission earns a bonus tier.';

  @override
  String get shareLabel => 'Share';

  @override
  String shareRedeemCodeMessage(String code, String subtitle) {
    return 'Use my Spekooh redeem code $code: $subtitle';
  }

  @override
  String get shareRedeemCodeSubject => 'Spekooh redeem code';

  @override
  String get inviteAFriendTitle => 'Invite a friend';

  @override
  String get inviteAFriendSubtitle =>
      'You earn bonus credit once they unlock their first paper.';

  @override
  String shareReferralMessage(String code) {
    return 'Join me on Spekooh. Sign up with my referral code $code.';
  }

  @override
  String get shareReferralSubject => 'Spekooh referral code';

  @override
  String get badgesSectionLabel => 'Badges';

  @override
  String get submissionStatusSectionLabel => 'Submission status';

  @override
  String get profileLoginPrompt => 'Log in to see your profile';

  @override
  String get profileLoginPromptSubtitle =>
      'Your submissions, credit balance, and badges show up here once you have an account.';

  @override
  String get shopHeaderSubtitle =>
      'Partner pamphlets · pay in-app, pick up with a QR code';

  @override
  String get searchPamphlets => 'Search pamphlets...';

  @override
  String pamphletSoldByQr(String partner) {
    return 'Sold by $partner · QR pickup';
  }

  @override
  String get notesScreenSubtitle =>
      'Topic study notes, contributed alongside papers';

  @override
  String get searchTopics => 'Search topics...';

  @override
  String get academicLevelFilterLabel => 'Level';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get adNotCompletedError => 'Ad not completed. No view granted.';

  @override
  String adLoadError(String error) {
    return 'Could not load an ad: $error';
  }

  @override
  String couldNotLoadOptionsError(String error) {
    return 'Could not load options: $error';
  }

  @override
  String unlockFailedError(String error) {
    return 'Unlock failed: $error';
  }

  @override
  String get couldNotOpenFile => 'Could not open the file.';

  @override
  String get couldNotOpenLink => 'Could not open the link.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileUsernameLabel => 'Username';

  @override
  String get editProfilePhoneLabel => 'Phone';

  @override
  String get editProfilePhoneHint => '670 12 34 56';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String editProfileError(String error) {
    return 'Could not save your changes: $error';
  }

  @override
  String get editProfileEmailChangedNotice =>
      'We sent a new verification code to your updated email.';

  @override
  String get achievementSparkDescription =>
      'Submit your first exam paper or report';

  @override
  String get achievementEmberDescription => 'Submit 5 papers or reports';

  @override
  String get achievementInfernoDescription => 'Submit 15 papers or reports';

  @override
  String get achievementScholarDescription => 'Complete 10 quizzes';

  @override
  String badgesSectionCount(int count) {
    return 'All $count';
  }

  @override
  String get allBadgesSheetTitle => 'Badges';

  @override
  String get badgeEarnedLabel => 'Earned';

  @override
  String get badgeLockedLabel => 'Locked';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get viewPrivacyPolicyLink => 'View Privacy Policy';

  @override
  String get viewOnlyNotice => 'View only. Unlock to download a copy';

  @override
  String get reportThanksMessage =>
      'Thanks! The Review Team has been notified.';

  @override
  String reportSendError(String error) {
    return 'Could not send report: $error';
  }

  @override
  String get noPaperSelectedTitle => 'No paper selected';

  @override
  String get noPaperSelectedBody =>
      'Browse the Papers tab and pick a subject to open a real paper.';

  @override
  String get backButton => 'Back';

  @override
  String get publishedStatus => 'Published';

  @override
  String get reportTooltip => 'Report an issue with this paper';

  @override
  String get noScannedFileYet => 'No scanned file on this submission yet.';

  @override
  String get openScannedPaper => 'Open scanned paper';

  @override
  String get saveOffline => 'Save offline';

  @override
  String get offlineSaved => 'Saved offline';

  @override
  String offlineSaveError(String error) {
    return 'Could not save for offline: $error';
  }

  @override
  String examBoardLabel(String board) {
    return 'Exam board: $board';
  }

  @override
  String get watchAdForView => 'Watch ad for +1 view';

  @override
  String get markingGuideTitle => 'Marking guide';

  @override
  String get markingGuideSubtitle => 'Instructor-authored + in-house MCQ key';

  @override
  String get markingGuideNotYetAvailable =>
      'The paper is here, but its marking guide isn\'t ready yet. Check back soon.';

  @override
  String get reportDownloadTitle => 'Download access';

  @override
  String get reportDownloadSubtitle =>
      'Viewing in the app is free. Unlock once to save a copy for offline reading';

  @override
  String unlockedForAmount(int amount) {
    return 'Unlocked for $amount FCFA.';
  }

  @override
  String get unlockButton => 'Unlock: 500 FCFA';

  @override
  String get alreadyUnlocked => 'Unlocked.';

  @override
  String get viewButton => 'View';

  @override
  String get reportLockedTitle => 'This report requires unlocking';

  @override
  String get reportLockedMessage =>
      'PhD and Master\'s theses require payment to view. Unlock below to read it.';

  @override
  String get unlockToDownloadHint =>
      'Unlock below to save a copy for offline reading.';

  @override
  String unlockDownloadButton(int amount) {
    return 'Unlock download: $amount FCFA';
  }

  @override
  String get haveRedeemCode => 'Have a redeem code?';

  @override
  String get redeemCodeHint => 'Redeem code';

  @override
  String get mcqDisclaimer =>
      'Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.';

  @override
  String get reportDialogTitle => 'Report an issue';

  @override
  String get reportWhatsWrong => 'What\'s wrong?';

  @override
  String get reportDetailsOptional => 'Details (optional)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get submitButton => 'Submit';

  @override
  String get contributeNudgeTitle => 'Help other students';

  @override
  String get contributeNudgeBody =>
      'If you have a past paper or academic report, submitting it accurately and as soon as you can helps other students who need it right now. Every contribution makes a real difference.';

  @override
  String get contributeNudgeCta => 'Contribute now';

  @override
  String get contributeNudgeDismiss => 'Maybe later';

  @override
  String get reasonWrongAnswers => 'Wrong or missing answers';

  @override
  String get reasonPoorQuality => 'Poor scan quality / unreadable';

  @override
  String get reasonWrongSubject => 'Wrong subject or exam type';

  @override
  String get reasonDuplicate => 'Duplicate of another paper';

  @override
  String get reasonCopyright => 'Copyright concern';

  @override
  String get reasonOther => 'Other';

  @override
  String get paywallEnterPhoneError =>
      'Enter your MTN MoMo or Orange Money number.';

  @override
  String paywallSubscriptionFailed(String error) {
    return 'Subscription failed: $error';
  }

  @override
  String get paywallYoureProTitle => 'You\'re Pro';

  @override
  String get paywallGetProTitle => 'Get Spekooh Pro';

  @override
  String paywallRenewsOn(String date) {
    return 'Renews $date.';
  }

  @override
  String get paywallDescription =>
      'Unlimited question-paper views and an ad-free app. Marking guides are always unlocked separately.';

  @override
  String get paywallBenefitViews => 'Unlimited question paper views';

  @override
  String get paywallBenefitAds => 'Zero ads while you study';

  @override
  String get paywallBenefitAlerts => 'Instructor status alerts';

  @override
  String get spekoohProCaps => 'SPEKOOH PRO';

  @override
  String get momoOrangeLabel => 'MTN MOMO OR ORANGE MONEY NUMBER';

  @override
  String get payButton => 'Pay 500 FCFA';

  @override
  String get paywallDisclaimer =>
      'Official Spekooh merchant · we never ask for your PIN · receipt + SMS within 2 min';

  @override
  String pamphletSoldBy(String partner) {
    return 'Sold by $partner';
  }

  @override
  String get escrowExplanation =>
      'Spekooh holds your payment in escrow. You\'ll get a one-time QR ticket to collect it at the bookshop. Payment only releases to the partner once they scan it.';

  @override
  String get pickupInStoreLabel => 'PICKUP · IN-STORE';

  @override
  String payAndReserve(String amount) {
    return 'Pay & reserve: $amount FCFA';
  }

  @override
  String get processingLabel => 'Processing…';

  @override
  String get escrowFooterNote =>
      'Held in escrow · released to partner only after pickup is confirmed · 5% platform commission';

  @override
  String get pickupTicketReady => 'Pickup ticket ready';

  @override
  String showQrAtPartner(String partner) {
    return 'Show this QR at $partner. Single-use, expires in 30 days. Payment releases to the partner once they scan it.';
  }

  @override
  String ticketRefLabel(String ref) {
    return 'Ticket ref: $ref…';
  }

  @override
  String get paymentFailedGeneric =>
      'Payment failed. Check your connection and try again.';

  @override
  String get paywallBlockedMessage =>
      'Daily free view limit reached. Watch a rewarded ad or upgrade to Pro.';

  @override
  String get alreadyReportedMessage => 'You\'ve already reported this paper.';

  @override
  String get aiAssistantTitle => 'Spekooh Assistant';

  @override
  String get aiAssistantSubtitle => 'Explains topics using real past papers';

  @override
  String get aiPromptExplainPhysics => 'Explain a hard Physics topic';

  @override
  String get aiPromptMathsQuestions => 'Give me 5 Maths practice questions';

  @override
  String get aiPromptSummarizeGuide => 'Summarize this paper\'s marking guide';

  @override
  String get aiAssistantInputHint => 'Ask about a topic or paper...';
}
