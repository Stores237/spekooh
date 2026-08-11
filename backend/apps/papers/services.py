from django.db import transaction
from django.utils import timezone

from apps.payments.models import Subscription

from .duplicate_detection import DuplicateDetector, TfidfDuplicateDetector, exact_duplicate_hash
from .models import AdWatchEvent, PaperSubmission, PaperViewLog
from .ocr import extract_text

DAILY_FREE_VIEWS = 3


class PaywallError(Exception):
    pass


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
    text = extract_text(paper_submission.file_ref)
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
