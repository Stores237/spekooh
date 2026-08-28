/// The real Privacy Policy content (owner decision, 2026-08-28, adapting a
/// shared reference policy for Spekooh). Every factual claim here — what's
/// collected, which third-party SDK is used, what rights exist — was
/// checked against what the app and backend actually do at the time this
/// was written (see the section-by-section comments below); update this
/// file, not just the copy, whenever that changes.
///
/// Deliberately NOT claimed here because nothing in the codebase backs it:
/// geolocation collection, push notifications, Google Analytics, an
/// "offer wall"/third-party ad-click economy, or self-service account
/// deletion. Deliberately included because it's real: Google AdMob
/// (rewarded ads, see lib/ads/), mobile-money phone numbers collected for
/// payment (see PaywallSheet/UnlockPaperDownloadView), and the in-app Edit
/// profile screen as the real way to review/correct your own data.
class PolicySection {
  const PolicySection(this.heading, this.body);
  final String heading;
  final String body;
}

const privacyPolicyLastUpdated = 'August 28, 2026';

const privacyPolicyIntro =
    'This notice describes how Spekooh ("we", "us", "our") collects, uses, and shares information when you '
    'use the Spekooh mobile app and any related services. If you do not agree with this notice, please do not '
    'use Spekooh. Questions or concerns can be sent to storefix237@gmail.com.';

const privacyPolicySections = [
  PolicySection(
    '1. What information we collect',
    'Information you give us directly: your name, email address, phone number, and password when you create '
        'an account; a profile photo if you choose to add one; the exam papers, marking guides, or academic '
        'reports you submit, along with any subject, exam board, or institution details you enter for them; '
        'messages you send us for support; and the phone number you provide when paying to unlock a marking '
        'guide, a paper download, a subscription, or a pamphlet order (used only to route that one mobile-money '
        'charge, e.g. via MTN Mobile Money or Orange Money — Spekooh does not store your mobile-money PIN).\n\n'
        'Information collected automatically: standard technical data every server receives (IP address, device/'
        'browser type, request timestamps), and basic in-app activity needed to run real features honestly — for '
        'example, which papers you have viewed (so a paywall or "already unlocked" state is accurate) and which '
        'quizzes you have completed (so quiz stats and badges reflect real activity, not fabricated numbers).\n\n'
        'Camera and photo library access: requested only when you choose to submit a scanned paper or set a '
        'profile photo — you can decline and use the equivalent feature (e.g. Choose from gallery) instead, or '
        'revoke access anytime in your device settings.\n\n'
        'What we do not collect: Spekooh does not request your device\'s location, and does not currently send '
        'push notifications. If a future version adds either, this notice will be updated first.',
  ),
  PolicySection(
    '2. How we use your information',
    'To create and secure your account, including verifying your email address and letting you reset a '
        'forgotten password.\n'
        '• To operate the actual service: matching your submitted papers to instructors for marking, publishing '
        'reviewed papers and guides, detecting duplicate submissions, processing a real mobile-money charge when '
        'you unlock content or subscribe, and crediting referral or contributor bonuses.\n'
        '• To respond to support requests, paper reports/flags, and other messages you send us.\n'
        '• To show you a rewarded ad, through Google AdMob, on the occasions you choose to watch one in exchange '
        'for a free unlock.\n'
        '• To keep the service secure — detecting abuse, fraud, or violations of our submission rules.\n'
        '• To comply with a legal obligation, such as a valid request from a Cameroonian or other authority.',
  ),
  PolicySection(
    '3. Legal bases for processing (EEA/UK/Switzerland residents)',
    'If you are in the EEA, UK, or Switzerland, we rely on: your consent (e.g. to receive optional emails, '
        'withdrawable at any time by contacting us); performance of a contract (running the account and paid '
        'features you signed up for); legitimate interests (keeping the service secure, improving it, and '
        'showing relevant ads to free-tier users); and legal obligations, where applicable.',
  ),
  PolicySection(
    '4. When we share information',
    'We do not sell your personal information. We share it only:\n\n'
        '• With Google, through the AdMob SDK, only when you choose to watch a rewarded ad — Google\'s own '
        'privacy practices apply to that processing; see policies.google.com/privacy.\n'
        '• With the mobile-money network you choose (MTN Mobile Money or Orange Money) to route a payment you '
        'initiated — only the phone number and amount needed to complete that one charge.\n'
        '• With an instructor, in anonymized form, when your submitted paper is routed for marking — instructors '
        'see the exam paper itself, not your account details.\n'
        '• In a merger, acquisition, or sale of Spekooh\'s business, as with any company.\n'
        '• When required by law, or to protect the rights, safety, or property of Spekooh, our users, or others.',
  ),
  PolicySection(
    '5. Third-party links',
    'Spekooh may link out to third-party sites or services we do not control (for example, a support contact '
        'on WhatsApp, or content in an ad shown through AdMob). This notice does not cover their practices — '
        'review their own privacy notices before sharing information with them.',
  ),
  PolicySection(
    '6. How long we keep your information',
    'We keep your information for as long as you have a Spekooh account, plus a limited period afterward where '
        'needed for fraud prevention, dispute resolution, or a legal obligation. When there is no remaining '
        'reason to keep it, we delete or anonymize it.',
  ),
  PolicySection(
    '7. How we keep your information safe',
    'We use reasonable technical and organizational measures — including encrypted transport (HTTPS) and '
        'access-controlled storage — to protect your information. No system is 100% secure, so we cannot '
        'guarantee against every possible unauthorized access, and use of Spekooh is at your own risk.',
  ),
  PolicySection(
    '8. Your privacy rights',
    'Depending on where you live, you may have the right to access, correct, or request deletion of your '
        'personal information, restrict or object to some processing, or receive a copy of your data. The '
        'quickest way to review or correct your name, email, or phone number is Profile → the edit (pencil) '
        'icon, right in the app, no request needed. For anything else — including deleting your account '
        'entirely, which Spekooh does not yet support as a self-service action — email storefix237@gmail.com and '
        'we will handle it directly. If you are in the EEA or UK, you also have the right to complain to your '
        'local data protection authority.',
  ),
  PolicySection(
    '9. Do Not Track',
    'Spekooh does not currently respond to browser "Do Not Track" signals, as no common standard for handling '
        'them exists yet.',
  ),
  PolicySection(
    '10. California residents (CCPA)',
    'If you are a California resident, the categories of personal information Spekooh has collected in the '
        'past 12 months are: identifiers (name, email, phone number, account ID); personal records under Cal. '
        'Civ. Code §1798.80 (name, contact details, education level, if provided); commercial information '
        '(your purchase/unlock history, e.g. which marking guide or subscription you paid for); internet/network '
        'activity limited to which papers or quizzes you engaged with inside Spekooh; and education information '
        '(the exam papers, subjects, and academic level associated with your submissions and activity). We have '
        'not collected protected classifications, biometric data, precise geolocation, audio/visual recordings, '
        'professional/employment history, or drawn inferences about you as a profile. We do not sell or share '
        'this information for cross-context behavioral advertising. To exercise a CCPA right (know, delete, '
        'correct, or opt out), email storefix237@gmail.com; we will verify your identity before acting on the '
        'request.',
  ),
  PolicySection(
    '11. Changes to this notice',
    'We may update this notice as Spekooh changes. The "Last updated" date at the top will change when we do, '
        'and a material change will be flagged in the app, not just posted silently.',
  ),
  PolicySection(
    '12. Contact us',
    'Questions, requests, or complaints about this notice: storefix237@gmail.com, or +237 659 802 679 (also '
        'reachable on WhatsApp).',
  ),
];
