from django.core.files.base import ContentFile
from django.db import transaction
from django.utils import timezone

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag
from apps.payments.models import PaperUnlock, Subscription

from .duplicate_detection import DuplicateDetector, TfidfDuplicateDetector, exact_duplicate_hash
from .models import AdWatchEvent, PaperFlag, PaperStatus, PaperSubmission, PaperViewLog
from .ocr import extract_text, extract_text_from_fieldfile
from .watermark import watermark_bytes

DAILY_FREE_VIEWS = 3


def user_can_view_file(user, paper_submission: PaperSubmission) -> bool:
    """
    Owner decision: PhD/Master's-tier academic reports require payment even
    to view (ExamType.requires_payment_to_view) — everything else (exam
    papers, and lower-tier reports) is free to view. The submitter and
    staff always see the real file regardless — nobody should have to pay
    to see their own upload, or to review it.
    """
    if not paper_submission.exam_type.requires_payment_to_view:
        return True
    if not user.is_authenticated:
        return False
    if user.is_staff or paper_submission.submitted_by_id == user.id:
        return True
    return PaperUnlock.objects.has_unlocked(user, paper_submission)


def report_download_is_free(paper_submission: PaperSubmission) -> bool:
    """
    Owner decision: Internship/Bachelor's/HND-tier reports are free to
    both view AND download — no PaperUnlock required. Master's/PhD-tier
    reports (already paid to view) still require a real unlock to
    download, and exam papers are untouched by this — their PaperUnlock
    also gates the marking guide, so that stays a real purchase.
    """
    return (
        paper_submission.category.key == "reports"
        and not paper_submission.exam_type.requires_payment_to_view
    )


class PaywallError(Exception):
    pass


class AlreadyFlaggedError(Exception):
    pass


def report_paper(*, user, paper_submission, reason, details="") -> PaperFlag:
    """Spec §3.2 flag/report — one flag per user per paper, each also creates
    a Review Team ticket in the same queue every other event uses (§2.1)."""
    if PaperFlag.objects.filter(paper_submission=paper_submission, flagged_by=user).exists():
        raise AlreadyFlaggedError("You've already reported this paper.")
    paper_flag = PaperFlag.objects.create(
        paper_submission=paper_submission, flagged_by=user, reason=reason, details=details
    )
    flag(
        subject=paper_submission,
        category=FlagCategory.PAPER_REPORTED,
        reason=f"Reported by user #{user.id}: {paper_flag.get_reason_display()}"
        + (f": {details}" if details else ""),
    )
    return paper_flag


def watermark_report_submission(paper_submission: PaperSubmission) -> PaperSubmission:
    """
    Owner decision: Academic Report uploads get an automatic, static Spekooh
    watermark — applied once here at submission time, not per-viewer.
    Exam papers are untouched (marking guides aren't meant to be
    redistributed the way a shareable report is).
    """
    if paper_submission.category.key != "reports" or not paper_submission.uploaded_file:
        return paper_submission

    field_file = paper_submission.uploaded_file
    field_file.open("rb")
    try:
        original_bytes = field_file.read()
    finally:
        field_file.close()

    old_name = field_file.name
    storage = field_file.storage
    watermarked = watermark_bytes(original_bytes, old_name)
    # save=False: the caller decides when to persist — see perform_create,
    # which needs this done before the response serializes file_url.
    paper_submission.uploaded_file.save(old_name.rsplit("/", 1)[-1], ContentFile(watermarked), save=False)
    update_fields = ["uploaded_file", "updated_at"]
    # file_ref (local-disk storage only, see PaperSubmission.save) mirrored
    # the pre-watermark path — refresh it too, or OCR's fast path tries to
    # read a file this function is about to delete below.
    if paper_submission.file_ref:
        try:
            paper_submission.file_ref = paper_submission.uploaded_file.path
        except NotImplementedError:
            paper_submission.file_ref = ""
        update_fields.append("file_ref")
    paper_submission.save(update_fields=update_fields)
    # Storage backends with overwrite-on-save enabled (the default for
    # django-storages' S3Storage) reuse the exact same key for the new
    # upload — deleting old_name there would delete the watermarked file
    # that now lives at that same key. Only clean up when the storage
    # actually generated a distinct key (overwrite disabled, or a
    # collision-avoidance suffix got appended).
    new_name = paper_submission.uploaded_file.name
    if new_name != old_name:
        storage.delete(old_name)
    return paper_submission


def _today_start():
    now = timezone.now()
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


@transaction.atomic
def record_paper_view(*, user, paper_submission) -> PaperViewLog:
    """
    Enforces the 3-free-views/day paywall (spec §5.3): Pro subscribers get
    unlimited views; everyone else gets 3/day, then must spend an unconsumed
    rewarded-ad watch for one more, or be blocked.
    """
    if Subscription.objects.has_active(user):
        return PaperViewLog.objects.create(user=user, paper_submission=paper_submission)

    today_views = PaperViewLog.objects.filter(user=user, created_at__gte=_today_start()).count()
    if today_views < DAILY_FREE_VIEWS:
        return PaperViewLog.objects.create(user=user, paper_submission=paper_submission)

    ad_watch = (
        AdWatchEvent.objects.select_for_update(skip_locked=True)
        .filter(user=user, consumed_by_view_log__isnull=True, created_at__gte=_today_start())
        .first()
    )
    if ad_watch is None:
        raise PaywallError("Daily free view limit reached. Watch a rewarded ad or upgrade to Pro.")

    log = PaperViewLog.objects.create(user=user, paper_submission=paper_submission)
    ad_watch.consumed_by_view_log = log
    ad_watch.save(update_fields=["consumed_by_view_log", "updated_at"])
    return log


def record_ad_watch(*, user) -> AdWatchEvent:
    return AdWatchEvent.objects.create(user=user)


_detector: DuplicateDetector = TfidfDuplicateDetector()


def process_ocr_and_duplicate_check(paper_submission: PaperSubmission) -> PaperSubmission:
    """
    Runs OCR over the submitted file, then checks for near-duplicates among
    other submissions of the same exam type + subject. Bonus-credit eligibility
    (stage 7) reads paper_submission.is_duplicate rather than re-deriving it.
    """
    # file_ref is only populated for local-disk storage (see
    # PaperSubmission.save) — for remote storage (real Supabase Storage),
    # it's blank and OCR has to stage the file through a temp copy instead.
    if paper_submission.file_ref:
        text = extract_text(paper_submission.file_ref)
    else:
        text = extract_text_from_fieldfile(paper_submission.uploaded_file)
    paper_submission.ocr_text = text
    paper_submission.duplicate_hash = exact_duplicate_hash(text)

    candidates = list(
        PaperSubmission.objects.filter(
            exam_type=paper_submission.exam_type,
            subject=paper_submission.subject,
        )
        .exclude(id=paper_submission.id)
        .exclude(ocr_text="")
        .values_list("id", "ocr_text")
    )

    match = _detector.find_duplicate(text, candidates)
    if match is not None:
        paper_submission.is_duplicate = True
        paper_submission.duplicate_of_id = match.candidate_id
    else:
        paper_submission.is_duplicate = False
        paper_submission.duplicate_of = None

    paper_submission.save(
        update_fields=["ocr_text", "duplicate_hash", "is_duplicate", "duplicate_of", "updated_at"]
    )
    return paper_submission


def mark_published(paper: PaperSubmission) -> PaperSubmission:
    """
    Ops-triggered for now — the full instructor-accept -> marking-guide ->
    merge pipeline (stage 8) will call award_contributor_bonus from this
    same transition instead of duplicating the logic. Shared by the DRF
    action and the admin dashboard action so the two never diverge.
    """
    from apps.credits.services import award_contributor_bonus

    paper.status = PaperStatus.PUBLISHED
    paper.save(update_fields=["status", "updated_at"])
    award_contributor_bonus(paper)
    return paper
