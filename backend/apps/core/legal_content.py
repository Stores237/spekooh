"""
Real Privacy Policy / Terms of Service content, served as real public HTML
pages (apps.core.views.privacy_policy_page / terms_of_service_page) —
2026-09-14, owner request: Play Console's Store Listing requires a real,
publicly reachable URL for the Privacy Policy (a validated field, not
optional), and the app's own copy of both documents only ever existed as
in-app Flutter screens with no URL at all.

This is a deliberate content DUPLICATE of app/lib/screens/legal
/privacy_policy_content.dart and .../terms_of_service_content.dart, not a
shared source of truth — there's no realistic way to share a Dart const
list and a Django template's data at build time without real extra
tooling this app doesn't have. Copied verbatim at the time this was
written; if you edit one, edit both, the same discipline the Dart files'
own top comments already ask of themselves for their own factual claims.
"""

PRIVACY_POLICY_LAST_UPDATED = "August 28, 2026"

PRIVACY_POLICY_INTRO = (
    'This notice describes how Spekooh ("we", "us", "our") collects, uses, and shares information when you '
    "use the Spekooh mobile app and any related services. If you do not agree with this notice, please do not "
    "use Spekooh. Questions or concerns can be sent to storefix237@gmail.com."
)

PRIVACY_POLICY_SECTIONS = [
    (
        "1. What information we collect",
        ("Information you give us directly: your name, email address, phone number, and password when you create "
        "an account; a profile photo if you choose to add one; the exam papers, marking guides, or academic "
        "reports you submit, along with any subject, exam board, or institution details you enter for them; "
        "messages you send us for support; and the phone number you provide when paying to unlock a marking "
        "guide, a paper download, a subscription, or a pamphlet order (used only to route that one mobile-money "
        "charge, e.g. via MTN Mobile Money or Orange Money; Spekooh does not store your mobile-money PIN).\n\n"
        "Information collected automatically: standard technical data every server receives (IP address, device/"
        "browser type, request timestamps), and basic in-app activity needed to run real features honestly: for "
        'example, which papers you have viewed (so a paywall or "already unlocked" state is accurate) and which '
        "quizzes you have completed (so quiz stats and badges reflect real activity, not fabricated numbers).\n\n"
        "Camera and photo library access: requested only when you choose to submit a scanned paper or set a "
        "profile photo; you can decline and use the equivalent feature (e.g. Choose from gallery) instead, or "
        "revoke access anytime in your device settings.\n\n"
        "What we do not collect: Spekooh does not request your device's location, and does not currently send "
        "push notifications. If a future version adds either, this notice will be updated first."),
    ),
    (
        "2. How we use your information",
        ("To create and secure your account, including verifying your email address and letting you reset a "
        "forgotten password.\n"
        "• To operate the actual service: matching your submitted papers to instructors for marking, publishing "
        "reviewed papers and guides, detecting duplicate submissions, processing a real mobile-money charge when "
        "you unlock content or subscribe, and crediting referral or contributor bonuses.\n"
        "• To respond to support requests, paper reports/flags, and other messages you send us.\n"
        "• To show you a rewarded ad, through Google AdMob, on the occasions you choose to watch one in exchange "
        "for a free unlock.\n"
        "• To keep the service secure: detecting abuse, fraud, or violations of our submission rules.\n"
        "• To comply with a legal obligation, such as a valid request from a Cameroonian or other authority."),
    ),
    (
        "3. Legal bases for processing (EEA/UK/Switzerland residents)",
        ("If you are in the EEA, UK, or Switzerland, we rely on: your consent (e.g. to receive optional emails, "
        "withdrawable at any time by contacting us); performance of a contract (running the account and paid "
        "features you signed up for); legitimate interests (keeping the service secure, improving it, and "
        "showing relevant ads to free-tier users); and legal obligations, where applicable."),
    ),
    (
        "4. When we share information",
        ("We do not sell your personal information. We share it only:\n\n"
        "• With Google, through the AdMob SDK, only when you choose to watch a rewarded ad; Google's own "
        "privacy practices apply to that processing; see policies.google.com/privacy.\n"
        "• With the mobile-money network you choose (MTN Mobile Money or Orange Money) to route a payment you "
        "initiated; only the phone number and amount needed to complete that one charge.\n"
        "• With an instructor, in anonymized form, when your submitted paper is routed for marking; instructors "
        "see the exam paper itself, not your account details.\n"
        "• In a merger, acquisition, or sale of Spekooh's business, as with any company.\n"
        "• When required by law, or to protect the rights, safety, or property of Spekooh, our users, or others."),
    ),
    (
        "5. Third-party links",
        ("Spekooh may link out to third-party sites or services we do not control (for example, a support contact "
        "on WhatsApp, or content in an ad shown through AdMob). This notice does not cover their practices; "
        "review their own privacy notices before sharing information with them."),
    ),
    (
        "6. How long we keep your information",
        ("We keep your information for as long as you have a Spekooh account, plus a limited period afterward where "
        "needed for fraud prevention, dispute resolution, or a legal obligation. When there is no remaining "
        "reason to keep it, we delete or anonymize it."),
    ),
    (
        "7. How we keep your information safe",
        ("We use reasonable technical and organizational measures, including encrypted transport (HTTPS) and "
        "access-controlled storage, to protect your information. No system is 100% secure, so we cannot "
        "guarantee against every possible unauthorized access, and use of Spekooh is at your own risk."),
    ),
    (
        "8. Your privacy rights",
        ("Depending on where you live, you may have the right to access, correct, or request deletion of your "
        "personal information, restrict or object to some processing, or receive a copy of your data. The "
        "quickest way to review or correct your name, email, or phone number is Profile → the edit (pencil) "
        "icon, right in the app, no request needed. For anything else, including deleting your account "
        "entirely (which Spekooh does not yet support as a self-service action), email storefix237@gmail.com and "
        "we will handle it directly. If you are in the EEA or UK, you also have the right to complain to your "
        "local data protection authority."),
    ),
    (
        "9. Do Not Track",
        ('Spekooh does not currently respond to browser "Do Not Track" signals, as no common standard for handling '
        "them exists yet."),
    ),
    (
        "10. California residents (CCPA)",
        ("If you are a California resident, the categories of personal information Spekooh has collected in the "
        "past 12 months are: identifiers (name, email, phone number, account ID); personal records under Cal. "
        "Civ. Code §1798.80 (name, contact details, education level, if provided); commercial information "
        "(your purchase/unlock history, e.g. which marking guide or subscription you paid for); internet/network "
        "activity limited to which papers or quizzes you engaged with inside Spekooh; and education information "
        "(the exam papers, subjects, and academic level associated with your submissions and activity). We have "
        "not collected protected classifications, biometric data, precise geolocation, audio/visual recordings, "
        "professional/employment history, or drawn inferences about you as a profile. We do not sell or share "
        "this information for cross-context behavioral advertising. To exercise a CCPA right (know, delete, "
        "correct, or opt out), email storefix237@gmail.com; we will verify your identity before acting on the "
        "request."),
    ),
    (
        "11. Changes to this notice",
        ('We may update this notice as Spekooh changes. The "Last updated" date at the top will change when we do, '
        "and a material change will be flagged in the app, not just posted silently."),
    ),
    (
        "12. Contact us",
        ("Questions, requests, or complaints about this notice: storefix237@gmail.com, or +237 659 802 679 (also "
        "reachable on WhatsApp)."),
    ),
]

TERMS_OF_SERVICE_LAST_UPDATED = "September 13, 2026"

TERMS_OF_SERVICE_INTRO = (
    'These Terms of Service ("Terms") govern your use of the Spekooh mobile app and any related services '
    '(together, "Spekooh", "we", "us", "our"). By creating an account or using Spekooh, you agree to these '
    "Terms and to our Privacy Policy. If you do not agree, please do not use Spekooh. Questions can be sent to "
    "storefix237@gmail.com."
)

TERMS_OF_SERVICE_SECTIONS = [
    (
        "1. Who can use Spekooh",
        ("Spekooh is built for secondary and higher-education students, contributors, and instructors, primarily in "
        "Cameroon. You must be able to form a binding agreement to use Spekooh; if you are under the age of "
        "majority where you live, you should have a parent or guardian's permission. You may also use Spekooh "
        "as a Guest, without a full account, for the limited features that remain open to Guests (currently: "
        "contributing an exam paper or report) — most of Spekooh, including viewing papers, chatting with the "
        "AI assistant, and unlocking content, requires a real, registered account."),
    ),
    (
        "2. Your account",
        ("You are responsible for the accuracy of the information you register with, for keeping your password "
        "confidential, and for all activity under your account. Tell us right away at storefix237@gmail.com if "
        "you believe your account has been accessed without your permission. We may suspend or terminate an "
        "account that violates these Terms, submits fraudulent or plagiarized content, or is used to abuse the "
        "service (see Section 7, Prohibited Conduct)."),
    ),
    (
        "3. What Spekooh does",
        ("Spekooh lets students browse and view past exam papers and academic reports, contribute new ones, chat "
        "with an AI study assistant, take practice quizzes, and (once a paper is marked) access a marking guide. "
        "Non-subscribed users can view a limited number of question papers free each day; once that limit is "
        "reached, you may watch a rewarded video ad for one additional view, or subscribe to Spekooh Plus for "
        "unlimited views and an ad-free experience. Marking guides and, for most exam papers, downloading the "
        "scanned paper itself are separate, one-time purchases, paid for individually regardless of whether you "
        "subscribe to Spekooh Plus. We do not guarantee that a marking guide will exist or be produced for any "
        "specific paper, or how long that takes."),
    ),
    (
        "4. Contributing content",
        ("When you submit an exam paper, academic report, or other content to Spekooh, you confirm that you have "
        "the right to share it and that it does not infringe anyone else's rights. You grant Spekooh a "
        "worldwide, royalty-free license to host, reproduce, display, and distribute that content through the "
        "app, including applying a visible watermark to academic reports before publishing them. You keep "
        "ownership of your own original work; Spekooh does not claim authorship of a paper or report you "
        "contribute. Multiple-choice/objective answers are marked in-house by the Spekooh review team, never "
        "sent to an outside instructor; only the non-objective sections of a paper may be routed externally for "
        "marking. We may decline to publish, or may remove, any submission that is a duplicate, is plagiarized, "
        "is inaccurate, or otherwise violates these Terms, at our discretion."),
    ),
    (
        "5. Contributor bonuses, credits, and XP",
        ("A validated, non-duplicate contribution may earn a bonus credit, which can be converted into a redeem "
        "code usable toward the price of unlocking a marking guide — by you, or shared with someone else who "
        "redeems it themselves. A redeem code is fully consumed on first use. Referring a friend who goes on to "
        "unlock content may also earn a one-time bonus, credited once per referred account. Separately, "
        "completing quizzes earns XP, redeemable for in-app perks such as an extra offline-download slot. "
        "Credits, XP, and redeem codes have no cash value, cannot be exchanged for cash or transferred outside "
        "the mechanisms Spekooh actually provides, and may be adjusted or revoked if we determine they were "
        "earned through fraud, duplicate/near-duplicate submissions, or abuse of these bonus systems."),
    ),
    (
        "6. The AI features",
        ("Spekooh's AI study assistant and AI-generated paper summaries are produced by third-party AI models and "
        "are meant to help you learn, not to replace your own judgment or your teacher. They can be wrong, "
        "incomplete, or occasionally decline to answer. Do not rely on an AI reply as a final or authoritative "
        "answer, especially for anything graded. Free AI chat use is subject to a daily message limit; Spekooh "
        "Plus subscribers are not subject to that per-user limit, though Spekooh may still apply a shared, "
        "provider-wide limit across all users to keep the service available for everyone."),
    ),
    (
        "7. Prohibited conduct",
        ("You agree not to: submit content you don't have the right to share, or that is plagiarized, obscene, or "
        "unlawful; attempt to circumvent the daily view limit, a paywall, or a purchase by technical means; "
        "submit near-duplicate or slightly-edited papers to farm contributor bonuses; use Spekooh's AI features "
        "for anything unrelated to schoolwork, or to generate harmful content; scrape, reverse-engineer, or "
        "resell access to Spekooh's content or service; impersonate another person or misrepresent your "
        "affiliation with an institution; or interfere with the security or normal operation of the service."),
    ),
    (
        "8. Instructors and marking",
        ("An instructor accepting a paper for marking through Spekooh does so under whatever separate instructor "
        "agreement and credit-payout terms Spekooh presents at the time, which these Terms don't attempt to "
        "restate in full. Objective (MCQ) questions are never sent to an instructor; only non-objective sections "
        "are. Instructor credit payouts to cash are subject to identity verification and a review step before "
        "release."),
    ),
    (
        "9. Payments, subscriptions, and refunds",
        ("Paid features — marking-guide unlocks, exam-paper downloads, the Spekooh Plus subscription, and pamphlet "
        "purchases — are charged through the mobile money number you provide at the time (e.g. MTN Mobile Money "
        "or Orange Money); make sure it's correct, since Spekooh is not responsible for a charge sent to a "
        "wrong number you entered. Prices are shown in FCFA before you confirm a purchase and may change at any "
        "time for future purchases. A pamphlet order is held in escrow until you (or, for a delivery, the "
        "courier) confirm real handover by QR code, or it is auto-released after 3 days undisputed, or flagged "
        "for review if unredeemed after 30 days. Except where required by law, payments are generally final; if "
        "something has genuinely gone wrong with a charge, contact storefix237@gmail.com and we will look into "
        "it case by case — Spekooh does not yet support automatic, self-service refunds."),
    ),
    (
        "10. Advertising",
        ("Free-tier use of Spekooh shows ads, including rewarded video ads through Google AdMob when you choose to "
        "watch one for an extra paper view. Spekooh Plus removes ads for the paper-viewing experience. We are not "
        "responsible for the content of third-party ads shown through AdMob."),
    ),
    (
        "11. Intellectual property",
        ("The Spekooh name, logo, and the app itself (excluding content contributed by users and instructors, which "
        "remains theirs per Section 4) are owned by Spekooh. You may not use our branding without permission. If "
        "you believe content on Spekooh infringes your rights, contact storefix237@gmail.com with enough detail "
        "for us to locate and review it."),
    ),
    (
        "12. Disclaimers and limitation of liability",
        ('Spekooh is provided "as is," without warranties of any kind, to the extent permitted by law. We do not '
        "guarantee that any paper, marking guide, AI reply, or quiz is error-free, or that the service will be "
        "uninterrupted. To the fullest extent permitted by law, Spekooh is not liable for indirect, incidental, "
        "or consequential damages arising from your use of the service, including a missed exam, an incorrect "
        "AI answer relied on, or a failed mobile-money transfer to a number you provided. Nothing in this "
        "section limits liability that cannot lawfully be limited."),
    ),
    (
        "13. Termination",
        ("You may stop using Spekooh at any time. We may suspend or terminate your access if you violate these "
        "Terms, or if we discontinue the service, with notice where reasonably possible. Sections that by their "
        "nature should survive termination (including Sections 4, 9, 11, and 12) continue to apply after your "
        "account is closed."),
    ),
    (
        "14. Changes to these Terms",
        ('We may update these Terms as Spekooh changes. The "Last updated" date at the top will change when we do, '
        "and a material change will be flagged in the app, not just posted silently. Continuing to use Spekooh "
        "after a change means you accept the updated Terms."),
    ),
    (
        "15. Governing law",
        ("These Terms are governed by the laws of the Republic of Cameroon, without regard to conflict-of-law "
        "principles, unless a mandatory law in your own country of residence gives you additional rights that "
        "cannot be waived."),
    ),
    (
        "16. Contact us",
        "Questions about these Terms: storefix237@gmail.com, or +237 659 802 679 (also reachable on WhatsApp).",
    ),
]
