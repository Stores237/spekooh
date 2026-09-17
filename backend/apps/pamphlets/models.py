from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel
from apps.payments.models import PaymentTransaction


class PartnerBookshop(TimeStampedModel):
    name = models.CharField(max_length=150)
    # The real individual Integration Ops is onboarding, distinct from the
    # shop's own trading name above (owner decision, 2026-09-17, partner
    # KYC hardening) -- required so a handover-redemption OTP (see
    # RedeemVerification) is always tied to an accountable real person.
    full_name = models.CharField(max_length=150, default="")
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=20, blank=True)
    # Separate from contact_phone (owner request, 2026-09-16, QR Vault
    # pickup card): not every bookshop's WhatsApp is the same number they
    # answer calls on, and the app needs to know which numbers support
    # which contact method rather than assuming one number does both.
    whatsapp_number = models.CharField(max_length=20, blank=True)
    # Owner decision (2026-09-17, partner KYC hardening): real mobile-money
    # numbers, not just a general contact_phone -- Cameroonian OM/MoMo SIMs
    # are ID-linked at registration by the carriers, which is what makes
    # these numbers (not contact_phone, which could be a shared shop
    # landline) trustworthy enough to anchor the handover-redemption OTP
    # (RedeemVerification's PHONE channel) to a real accountable person.
    # At least one of the two is required -- see clean().
    orange_money_number = models.CharField("Orange Money number", max_length=20, blank=True, default="")
    momo_number = models.CharField("MTN MoMo number", max_length=20, blank=True, default="")
    # Real Cameroonian ID documents (owner decision, 2026-09-17) -- required
    # so a partner can be held accountable if a handover dispute ever needs
    # real-world escalation, the same reasoning CNI/NUI collection serves
    # for any real merchant onboarding in Cameroon. The number alone isn't
    # enough to actually verify anything -- a scan/photo of each real
    # document is required too (owner correction, 2026-09-17), same
    # ImageField-on-a-model pattern as Pamphlet.cover_image.
    cni_number = models.CharField("CNI number", max_length=30, default="")
    cni_document = models.FileField("CNI document", upload_to="partner_kyc/%Y/%m/", null=True, blank=True)
    nui_number = models.CharField("NUI number", max_length=30, default="")
    nui_document = models.FileField("NUI document", upload_to="partner_kyc/%Y/%m/", null=True, blank=True)
    # Free text, same rationale as Pamphlet.subject_title/academic_level:
    # partners are entered one at a time via admin, not picked from a
    # geocoded address taxonomy this app doesn't have.
    location = models.CharField(max_length=255)
    commission_percent = models.PositiveSmallIntegerField(default=5)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name

    def clean(self):
        from django.core.exceptions import ValidationError

        if not self.orange_money_number and not self.momo_number:
            raise ValidationError("Provide at least one of Orange Money number or MoMo number.")

    @property
    def verification_phone(self) -> str:
        """The real, ID-linked number a handover-redemption OTP is sent to
        (RedeemVerification's PHONE channel) -- Orange Money preferred,
        falling back to MoMo, since clean() guarantees at least one exists
        on any partner actually onboarded through the required-fields form."""
        return self.orange_money_number or self.momo_number


class Pamphlet(TimeStampedModel):
    """subject_title/academic_level are free text, same rationale as
    apps.notes.Note: partners list one pamphlet at a time via admin, not
    picked from the contributor-facing papers taxonomy — a lighter,
    independent field fits better than an FK dependency. They back the
    app's Subject/Academic level filter chips on the Shop screen."""

    partner = models.ForeignKey(PartnerBookshop, on_delete=models.CASCADE, related_name="pamphlets")
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    # Owner request, 2026-09-17: shown on the Featured Pamphlet card at a
    # fixed 76x96 slot (BoxFit.cover on the Flutter side, same pattern as
    # Promotion.logo) -- whatever aspect ratio Integration Ops uploads gets
    # cropped to fit, never stretched. Optional: falls back to the existing
    # gold subject/level placeholder when unset, same "real data or nothing
    # fabricated" rule FeaturedPamphletCard already follows.
    cover_image = models.ImageField(upload_to="pamphlets/%Y/%m/", null=True, blank=True)
    subject_title = models.CharField(max_length=100, blank=True)
    academic_level = models.CharField(max_length=100, blank=True)
    price_fcfa = models.PositiveIntegerField()
    delivery_available = models.BooleanField(default=False)
    delivery_fee_fcfa = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    # Integration Ops-controlled shop ranking (owner request, 2026-09-16):
    # lower sorts first. Only breaks ties among non-featured pamphlets --
    # is_featured still always wins the top slot regardless of this value.
    display_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-is_featured", "display_order", "title"]

    def __str__(self):
        return f"{self.title} ({self.partner})"


class PamphletOrderStatus(models.TextChoices):
    PAID_HELD = "PAID_HELD", "Paid, held in escrow"
    QR_ISSUED = "QR_ISSUED", "QR issued"
    RELEASED = "RELEASED", "Released to partner"
    EXPIRED = "EXPIRED", "Expired, flagged for admin review"
    DISPUTED = "DISPUTED", "Disputed"


class PamphletOrder(TimeStampedModel):
    """Escrow ledger row: held → QR issued → released (minus commission), or expired/disputed."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="pamphlet_orders")
    pamphlet = models.ForeignKey(Pamphlet, on_delete=models.PROTECT, related_name="orders")
    is_delivery = models.BooleanField(default=False)
    # Owner request, 2026-09-17: PamphletSheet previously always ordered
    # exactly one copy -- amount_paid already accounted for is_delivery's
    # fee, now also multiplies by this.
    quantity = models.PositiveIntegerField(default=1)
    # is_delivery already existed but nothing ever captured *where* to
    # deliver to -- a real pre-existing gap, not new scope creep. Blank for
    # pickup orders, required (validated in PlaceOrderRequestSerializer)
    # for delivery ones.
    delivery_address = models.CharField(max_length=255, blank=True)
    amount_paid = models.PositiveIntegerField()
    status = models.CharField(max_length=12, choices=PamphletOrderStatus.choices, default=PamphletOrderStatus.PAID_HELD)
    payment_transaction = models.ForeignKey(
        PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True, related_name="pamphlet_orders"
    )

    qr_token = models.CharField(max_length=200, blank=True, unique=True, null=True)
    qr_issued_at = models.DateTimeField(null=True, blank=True)
    # Delivery-only fallback: user self-confirms receipt, auto-released after
    # COURIER_SELF_CONFIRM_DAYS by the cron command if undisputed.
    self_confirmed_at = models.DateTimeField(null=True, blank=True)

    payout_amount = models.PositiveIntegerField(null=True, blank=True)
    released_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.pamphlet}, {self.user} ({self.status})"


class RedeemVerificationChannel(models.TextChoices):
    EMAIL = "EMAIL", "Email"
    PHONE = "PHONE", "Phone (SMS)"
    # Owner request (2026-09-17): a real network/carrier issue can mean a
    # partner never receives either the email or the SMS. If they call
    # support, Integration Ops can generate one of these for their exact
    # order instead -- see apps.pamphlets.escrow.generate_support_override_
    # code and PamphletOrderAdmin.generate_support_code (permission-gated
    # to that group specifically). Deliberately short-lived (3 minutes, not
    # the normal 10) since it's relayed by a human over a phone call rather
    # than a channel the partner already proved they control.
    SUPPORT = "SUPPORT", "Support override (Integration Ops)"


class RedeemVerification(TimeStampedModel):
    """
    Owner-reported security gap (2026-09-17): the redeem page previously
    let anyone holding the scanning phone confirm a handover with a single
    unauthenticated button click, releasing escrow to the partner without
    ever checking that the person scanning actually IS that partner. This
    is the real identity check that closes it -- a one-time code sent to
    the partner's own registered email or phone (never the buyer's), which
    must be entered correctly before apps.pamphlets.escrow.redeem_qr ever
    runs. Same OTP shape (TTL + independent attempt cap) as
    apps.accounts.models.EmailVerificationCode/PasswordResetCode, per
    SECURITY.md's own stated reasoning for why a short numeric code needs
    a cap independent of anything else.

    Scoped to a specific order rather than the partner generally: a fresh
    code is required per redemption, so a code sent for one order can't be
    reused to redeem a different one.

    code is only ever populated for the EMAIL and SUPPORT channels --
    PHONE uses Twilio Verify (apps.core.sms), which owns the code/expiry/
    attempt state itself, the same "no local OTP model" pattern
    apps.accounts.models.User.phone_verified_at's own docstring already
    established for phone verification in this codebase.
    """

    TTL_MINUTES = 10
    SUPPORT_TTL_MINUTES = 3
    MAX_ATTEMPTS = 5

    order = models.ForeignKey(PamphletOrder, on_delete=models.CASCADE, related_name="redeem_verifications")
    channel = models.CharField(max_length=10, choices=RedeemVerificationChannel.choices)
    code = models.CharField(max_length=6, blank=True)
    attempts = models.PositiveSmallIntegerField(default=0)
    used_at = models.DateTimeField(null=True, blank=True)
    # Who actually issued a SUPPORT-channel code -- blank for EMAIL/PHONE,
    # which the system itself sends. A real audit trail for a mechanism
    # that deliberately bypasses proving control of a registered channel.
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+"
    )

    class Meta:
        ordering = ["-created_at"]

    @property
    def ttl_minutes(self) -> int:
        return self.SUPPORT_TTL_MINUTES if self.channel == RedeemVerificationChannel.SUPPORT else self.TTL_MINUTES

    @property
    def is_expired(self) -> bool:
        from django.utils import timezone

        age = timezone.now() - self.created_at
        return age.total_seconds() > self.ttl_minutes * 60

    @property
    def is_usable(self) -> bool:
        return self.used_at is None and not self.is_expired and self.attempts < self.MAX_ATTEMPTS
