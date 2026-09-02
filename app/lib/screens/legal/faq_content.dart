/// Real FAQ content (owner-requested, 2026-09-02) — every answer here is
/// checked against what the app and backend actually do at the time this
/// was written, the same discipline privacy_policy_content.dart already
/// follows for its own content. Update this file, not just the copy,
/// whenever the underlying behavior changes:
///
/// - Free views (3/day) and the rewarded-ad top-up:
///   apps.papers.services.DAILY_FREE_VIEWS / record_paper_view.
/// - Marking-guide unlock price (500 FCFA) and the 7-day first-unlock-free
///   trial: apps.payments.services.PAPER_UNLOCK_PRICE_FCFA / TRIAL_DAYS.
/// - Exam-paper download pricing (50-100 FCFA by level) and reports' own
///   free-tier rule: apps.papers.services.PAPER_DOWNLOAD_PRICE_FCFA_BY_
///   CATEGORY / report_download_is_free.
/// - Spekooh Pro price (500 FCFA/month) and its real benefits:
///   apps.payments.services.PRO_MONTHLY_FCFA, lib/sheets/paywall_sheet.dart.
/// - Bonus credit and referral bonus: apps.credits.services
///   .award_contributor_bonus / award_referral_bonus — deliberately no
///   specific amount is quoted here, since that's an admin-configured
///   value (ContributorBonusConfig/ReferralBonusConfig), not a fixed
///   constant — same reason ContributionRewardScreen never shows a
///   fabricated "+N" figure.
/// - Guest accounts can submit but not report/flag a paper:
///   apps.papers.views.PaperSubmissionViewSet.get_permissions.
/// - Rejection verdicts and dismissing them: apps.papers.services
///   .reject_submission, PaperSubmissionViewSet.dismiss (2026-09-01).
///
/// English-only, not routed through the ARB files — same precedent as
/// privacy_policy_content.dart for a page that's mostly prose and would
/// otherwise roughly double the size of both .arb files for content this
/// size. Revisit if the owner asks for a French version specifically.
class FaqEntry {
  const FaqEntry(this.question, this.answer);
  final String question;
  final String answer;
}

const faqEntries = [
  FaqEntry(
    'How do I submit a past paper or academic report?',
    'Open the Submit tab, choose "Exam paper" or "Academic report", fill in the category/exam type/subject and '
        'year, then attach the file: take a photo (the camera automatically finds the page\'s edges and crops to '
        'it), choose a photo from your gallery, or pick a PDF. A guest can submit too, but needs to type a real '
        'name first so the submission is attributed to someone.',
  ),
  FaqEntry(
    'Do I need an account to submit a paper?',
    'No. You can submit as a guest. Creating a real account is only required to report/flag a paper, track your '
        'submissions over time on Profile, or earn bonus credit and badges.',
  ),
  FaqEntry(
    'What happens to my submission after I send it?',
    'It goes to the Review Team for verification. If it\'s accepted and published, you earn bonus credit. If it\'s '
        'rejected, you\'ll see a real popup on Profile with the Review Team\'s actual reason; dismiss it once '
        'you\'ve read it, then submit a corrected version.',
  ),
  FaqEntry(
    'Why was my submission rejected?',
    'The exact reason is always shown to you. Common ones are an unreadable scan, a duplicate of a paper '
        'already on Spekooh, or details that don\'t match the file (wrong subject or exam type). A rejected '
        'submission isn\'t automatically retried; submit a fresh, corrected one.',
  ),
  FaqEntry(
    'How many papers can I view for free?',
    '3 free views per day, with no account needed. Once you hit the limit, watching a rewarded ad unlocks one '
        'more view. Spekooh Pro removes the daily limit entirely.',
  ),
  FaqEntry(
    'Can I download the exam paper after viewing it?',
    'Viewing an exam paper in the app is always free. Downloading/saving the actual file is a separate, small '
        'purchase priced by exam level (roughly 50-100 FCFA). Academic reports work differently: Internship, '
        'Bachelor\'s, and HND reports are free to both view and download; Master\'s and PhD reports require a '
        'one-time unlock to view, which also covers the download.',
  ),
  FaqEntry(
    'How much does a marking guide unlock cost?',
    '500 FCFA per exam paper. Your very first unlock is free if it\'s within 7 days of creating your account.',
  ),
  FaqEntry(
    'What is Spekooh Pro?',
    '500 FCFA per month for unlimited paper views, zero ads, and instructor status alerts, with no more 3-a-day '
        'limit or rewarded ads.',
  ),
  FaqEntry(
    'How do I earn bonus credit?',
    'Every submission that\'s accepted and published (and isn\'t a duplicate) earns you real bonus credit, shown '
        'on your Profile. Enough contributions unlock a real discount code you can apply toward your next '
        'marking-guide unlock.',
  ),
  FaqEntry(
    'How does the referral program work?',
    'Share your referral code from Profile → Invite a friend. The first time the person you referred unlocks '
        'their first paper, you earn a bonus credit, once per referred friend, not repeatedly.',
  ),
  FaqEntry(
    'Can I change the app\'s language?',
    'Yes. Settings → Language → English or Français. If you\'re logged in, your choice is saved to your account '
        'and follows you to other devices.',
  ),
  FaqEntry(
    'Is it normal that I haven\'t set a profile picture?',
    'Yes. Until you set one, your profile shows your name\'s first letter instead. To add a real photo, tap '
        'your avatar on Profile and choose "Take a photo" or "Choose from gallery".',
  ),
  FaqEntry(
    'Can I edit my name, email, or phone number?',
    'Yes. Profile → the pencil (edit) icon. Changing your email resets its verified status and sends a fresh '
        'code to confirm the new address.',
  ),
  FaqEntry(
    'What if I forget my password?',
    'On the login screen, tap "Forgot password?" (or, if you\'re already logged in, Settings → Change password); '
        'a real reset code is emailed to you.',
  ),
  FaqEntry(
    'Is my submission checked for duplicates?',
    'Yes, automatically, against every other submission of the same exam type and subject already on Spekooh.',
  ),
  FaqEntry(
    'Where do I find study notes and partner pamphlets?',
    'Notes (from the Home menu) has topic study notes organized by subject. Shop has real partner pamphlets, '
        'picked up in person with a QR code at the partner bookshop.',
  ),
];
