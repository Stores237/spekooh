/// Real Terms of Service content (2026-09-13, owner blocker: registration's
/// checkbox has said "I agree to the Terms of Service and Privacy Policy"
/// since before this file existed, but only the Privacy Policy was ever
/// reachable — users were agreeing to a document that didn't exist).
/// Structured and fact-checked the same way privacy_policy_content.dart
/// was (owner decision, 2026-08-28): a standard consumer-app Terms of
/// Service structure, adapted to what Spekooh's real, live app and
/// backend actually do at the time this was written — not a generic
/// template left unedited, and not an invented feature set.
///
/// Deliberately included because it's real: the 3-free-question-papers/day
/// limit + rewarded-ad/Pro unlock (apps.papers.services.record_paper_view),
/// marking-guide/paper-download pay-per-unlock via mobile money, Kawlo Plus
/// subscription, contributor bonus credits + redeem codes, XP + the 250-XP
/// offline-slot redemption, referral bonuses, academic-report contribution
/// with automatic watermarking, MCQ answers marked in-house (never sent to
/// an outside instructor), duplicate-submission detection, the paper
/// report/flag feature, and the pamphlet marketplace's real escrow model
/// (held → QR-confirmed handover → released to the partner, or a 3-day
/// auto-release/30-day expiry — apps.pamphlets.models). Deliberately NOT
/// claimed: a live real-money payment processor (MockPaymentProvider is
/// still what actually runs behind every charge as of this writing — see
/// apps.payments.services — so payment terms here describe the real
/// *product design*, which does not change once a real processor is
/// wired in, not a specific processor's own terms), self-service account
/// deletion or refunds, or any guarantee about instructor turnaround time
/// (spec leaves this genuinely open).
///
/// **Flagged for real legal review, not just engineering sign-off**:
/// Section 9 (Payments/Refunds), Section 12 (Limitation of Liability), and
/// Section 15 (Governing Law) make real legal commitments this file's
/// author is not qualified to finalize alone — ship this once a person
/// with real authority to accept that risk has actually read it, the same
/// "owner decision" bar the Privacy Policy's own adaptation was held to.
class TermsSection {
  const TermsSection(this.heading, this.body);
  final String heading;
  final String body;
}

const termsOfServiceLastUpdated = 'September 13, 2026';

const termsOfServiceIntro =
    'These Terms of Service ("Terms") govern your use of the Spekooh mobile app and any related services '
    '(together, "Spekooh", "we", "us", "our"). By creating an account or using Spekooh, you agree to these '
    'Terms and to our Privacy Policy. If you do not agree, please do not use Spekooh. Questions can be sent to '
    'storefix237@gmail.com.';

const termsOfServiceSections = [
  TermsSection(
    '1. Who can use Spekooh',
    'Spekooh is built for secondary and higher-education students, contributors, and instructors, primarily in '
        'Cameroon. You must be able to form a binding agreement to use Spekooh; if you are under the age of '
        'majority where you live, you should have a parent or guardian\'s permission. You may also use Spekooh '
        'as a Guest, without a full account, for the limited features that remain open to Guests (currently: '
        'contributing an exam paper or report) — most of Spekooh, including viewing papers, chatting with the '
        'AI assistant, and unlocking content, requires a real, registered account.',
  ),
  TermsSection(
    '2. Your account',
    'You are responsible for the accuracy of the information you register with, for keeping your password '
        'confidential, and for all activity under your account. Tell us right away at storefix237@gmail.com if '
        'you believe your account has been accessed without your permission. We may suspend or terminate an '
        'account that violates these Terms, submits fraudulent or plagiarized content, or is used to abuse the '
        'service (see Section 7, Prohibited Conduct).',
  ),
  TermsSection(
    '3. What Spekooh does',
    'Spekooh lets students browse and view past exam papers and academic reports, contribute new ones, chat '
        'with an AI study assistant, take practice quizzes, and (once a paper is marked) access a marking guide. '
        'Non-subscribed users can view a limited number of question papers free each day; once that limit is '
        'reached, you may watch a rewarded video ad for one additional view, or subscribe to Kawlo Plus for '
        'unlimited views and an ad-free experience. Marking guides and, for most exam papers, downloading the '
        'scanned paper itself are separate, one-time purchases, paid for individually regardless of whether you '
        'subscribe to Kawlo Plus. We do not guarantee that a marking guide will exist or be produced for any '
        'specific paper, or how long that takes.',
  ),
  TermsSection(
    '4. Contributing content',
    'When you submit an exam paper, academic report, or other content to Spekooh, you confirm that you have '
        'the right to share it and that it does not infringe anyone else\'s rights. You grant Spekooh a '
        'worldwide, royalty-free license to host, reproduce, display, and distribute that content through the '
        'app, including applying a visible watermark to academic reports before publishing them. You keep '
        'ownership of your own original work; Spekooh does not claim authorship of a paper or report you '
        'contribute. Multiple-choice/objective answers are marked in-house by the Spekooh review team, never '
        'sent to an outside instructor; only the non-objective sections of a paper may be routed externally for '
        'marking. We may decline to publish, or may remove, any submission that is a duplicate, is plagiarized, '
        'is inaccurate, or otherwise violates these Terms, at our discretion.',
  ),
  TermsSection(
    '5. Contributor bonuses, credits, and XP',
    'A validated, non-duplicate contribution may earn a bonus credit, which can be converted into a redeem '
        'code usable toward the price of unlocking a marking guide — by you, or shared with someone else who '
        'redeems it themselves. A redeem code is fully consumed on first use. Referring a friend who goes on to '
        'unlock content may also earn a one-time bonus, credited once per referred account. Separately, '
        'completing quizzes earns XP, redeemable for in-app perks such as an extra offline-download slot. '
        'Credits, XP, and redeem codes have no cash value, cannot be exchanged for cash or transferred outside '
        'the mechanisms Spekooh actually provides, and may be adjusted or revoked if we determine they were '
        'earned through fraud, duplicate/near-duplicate submissions, or abuse of these bonus systems.',
  ),
  TermsSection(
    '6. The AI features',
    'Spekooh\'s AI study assistant and AI-generated paper summaries are produced by third-party AI models and '
        'are meant to help you learn, not to replace your own judgment or your teacher. They can be wrong, '
        'incomplete, or occasionally decline to answer. Do not rely on an AI reply as a final or authoritative '
        'answer, especially for anything graded. Free AI chat use is subject to a daily message limit; Kawlo '
        'Plus subscribers are not subject to that per-user limit, though Spekooh may still apply a shared, '
        'provider-wide limit across all users to keep the service available for everyone.',
  ),
  TermsSection(
    '7. Prohibited conduct',
    'You agree not to: submit content you don\'t have the right to share, or that is plagiarized, obscene, or '
        'unlawful; attempt to circumvent the daily view limit, a paywall, or a purchase by technical means; '
        'submit near-duplicate or slightly-edited papers to farm contributor bonuses; use Spekooh\'s AI features '
        'for anything unrelated to schoolwork, or to generate harmful content; scrape, reverse-engineer, or '
        'resell access to Spekooh\'s content or service; impersonate another person or misrepresent your '
        'affiliation with an institution; or interfere with the security or normal operation of the service.',
  ),
  TermsSection(
    '8. Instructors and marking',
    'An instructor accepting a paper for marking through Spekooh does so under whatever separate instructor '
        'agreement and credit-payout terms Spekooh presents at the time, which these Terms don\'t attempt to '
        'restate in full. Objective (MCQ) questions are never sent to an instructor; only non-objective sections '
        'are. Instructor credit payouts to cash are subject to identity verification and a review step before '
        'release.',
  ),
  TermsSection(
    '9. Payments, subscriptions, and refunds',
    'Paid features — marking-guide unlocks, exam-paper downloads, the Kawlo Plus subscription, and pamphlet '
        'purchases — are charged through the mobile money number you provide at the time (e.g. MTN Mobile Money '
        'or Orange Money); make sure it\'s correct, since Spekooh is not responsible for a charge sent to a '
        'wrong number you entered. Prices are shown in FCFA before you confirm a purchase and may change at any '
        'time for future purchases. A pamphlet order is held in escrow until you (or, for a delivery, the '
        'courier) confirm real handover by QR code, or it is auto-released after 3 days undisputed, or flagged '
        'for review if unredeemed after 30 days. Except where required by law, payments are generally final; if '
        'something has genuinely gone wrong with a charge, contact storefix237@gmail.com and we will look into '
        'it case by case — Spekooh does not yet support automatic, self-service refunds.',
  ),
  TermsSection(
    '10. Advertising',
    'Free-tier use of Spekooh shows ads, including rewarded video ads through Google AdMob when you choose to '
        'watch one for an extra paper view. Kawlo Plus removes ads for the paper-viewing experience. We are not '
        'responsible for the content of third-party ads shown through AdMob.',
  ),
  TermsSection(
    '11. Intellectual property',
    'The Spekooh name, logo, and the app itself (excluding content contributed by users and instructors, which '
        'remains theirs per Section 4) are owned by Spekooh. You may not use our branding without permission. If '
        'you believe content on Spekooh infringes your rights, contact storefix237@gmail.com with enough detail '
        'for us to locate and review it.',
  ),
  TermsSection(
    '12. Disclaimers and limitation of liability',
    'Spekooh is provided "as is," without warranties of any kind, to the extent permitted by law. We do not '
        'guarantee that any paper, marking guide, AI reply, or quiz is error-free, or that the service will be '
        'uninterrupted. To the fullest extent permitted by law, Spekooh is not liable for indirect, incidental, '
        'or consequential damages arising from your use of the service, including a missed exam, an incorrect '
        'AI answer relied on, or a failed mobile-money transfer to a number you provided. Nothing in this '
        'section limits liability that cannot lawfully be limited.',
  ),
  TermsSection(
    '13. Termination',
    'You may stop using Spekooh at any time. We may suspend or terminate your access if you violate these '
        'Terms, or if we discontinue the service, with notice where reasonably possible. Sections that by their '
        'nature should survive termination (including Sections 4, 9, 11, and 12) continue to apply after your '
        'account is closed.',
  ),
  TermsSection(
    '14. Changes to these Terms',
    'We may update these Terms as Spekooh changes. The "Last updated" date at the top will change when we do, '
        'and a material change will be flagged in the app, not just posted silently. Continuing to use Spekooh '
        'after a change means you accept the updated Terms.',
  ),
  TermsSection(
    '15. Governing law',
    'These Terms are governed by the laws of the Republic of Cameroon, without regard to conflict-of-law '
        'principles, unless a mandatory law in your own country of residence gives you additional rights that '
        'cannot be waived.',
  ),
  TermsSection(
    '16. Contact us',
    'Questions about these Terms: storefix237@gmail.com, or +237 659 802 679 (also reachable on WhatsApp).',
  ),
];
