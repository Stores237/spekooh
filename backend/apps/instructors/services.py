import datetime

from django.db import transaction
from django.utils import timezone

from apps.admin_queue.models import FlagCategory
from apps.admin_queue.services import flag
from apps.credits.rules_engine import ComplexityLevel, MarkingQuestion, PaperCreditCalculator
from apps.credits.services import award_contributor_bonus
from apps.notifications.models import NotificationKind
from apps.notifications.services import notify
from apps.papers.models import PaperStatus, PaperSubmission, PublishedGuide

from .models import (
    InstructorCreditLedger,
    InstructorMarkingGuide,
    InstructorRequest,
    InstructorRequestStatus,
    InstructorSubjectQueue,
    WithdrawalRequest,
)

REQUEST_TIMEOUT_HOURS = 48
GUIDE_WINDOW_DAYS = 7
GUIDE_REMINDER_DAYS = [4, 6]


class RoutingError(Exception):
    pass


def _tried_instructor_ids(paper) -> set[str]:
    return set(
        InstructorRequest.objects.filter(paper=paper)
        .exclude(status=InstructorRequestStatus.PENDING)
        .values_list("instructor_id", flat=True)
    )


@transaction.atomic
def route_next_instructor(paper: PaperSubmission) -> InstructorRequest | None:
    """
    Sends the request to the next untried instructor in the paper's subject
    queue (spec §4.3: strictly sequential). If the queue is exhausted, flags
    the paper for admin review rather than leaving it unassigned forever.
    """
    if paper.subject_id is None:
        raise RoutingError("Paper has no subject, cannot route to an instructor.")

    already_tried = _tried_instructor_ids(paper)
    next_entry = (
        InstructorSubjectQueue.objects.select_for_update()
        .filter(subject_id=paper.subject_id, active=True)
        .exclude(instructor_id__in=already_tried)
        .order_by("priority_order")
        .first()
    )

    if next_entry is None:
        paper.status = PaperStatus.UNASSIGNED_ADMIN_QUEUE
        paper.save(update_fields=["status", "updated_at"])
        flag(
            subject=paper,
            category=FlagCategory.UNASSIGNED_PAPER,
            reason="No instructor in the subject queue accepted this paper.",
        )
        return None

    now = timezone.now()
    request = InstructorRequest.objects.create(
        paper=paper,
        instructor_id=next_entry.instructor_id,
        sent_at=now,
        responds_by=now + datetime.timedelta(hours=REQUEST_TIMEOUT_HOURS),
    )
    paper.status = PaperStatus.INSTRUCTOR_REQUEST_SENT
    paper.save(update_fields=["status", "updated_at"])
    return request


class WebhookAppliedResult:
    def __init__(self, applied: bool, detail: str = ""):
        self.applied = applied
        self.detail = detail


@transaction.atomic
def handle_instructor_response(*, instructor_request_id: int, decision: str) -> WebhookAppliedResult:
    """decision is 'ACCEPTED' or 'REJECTED'. Never trusts the payload blindly against stale local state."""
    try:
        request = InstructorRequest.objects.select_for_update().get(id=instructor_request_id)
    except InstructorRequest.DoesNotExist:
        return WebhookAppliedResult(applied=False, detail="Unknown instructor_request_id.")

    if request.status != InstructorRequestStatus.PENDING:
        flag(
            subject=request,
            category=FlagCategory.WEBHOOK_ANOMALY,
            reason=(
                f"Received '{decision}' for instructor_request {request.id}, "
                f"but it is already {request.status} locally."
            ),
        )
        return WebhookAppliedResult(applied=False, detail=f"Request is already {request.status}.")

    now = timezone.now()
    paper = request.paper

    if decision == InstructorRequestStatus.ACCEPTED:
        request.status = InstructorRequestStatus.ACCEPTED
        request.responded_at = now
        request.guide_deadline = now + datetime.timedelta(days=GUIDE_WINDOW_DAYS)
        request.save(update_fields=["status", "responded_at", "guide_deadline", "updated_at"])
        paper.status = PaperStatus.AWAITING_MARKING_GUIDE
        paper.save(update_fields=["status", "updated_at"])
        return WebhookAppliedResult(applied=True)

    if decision == InstructorRequestStatus.REJECTED:
        request.status = InstructorRequestStatus.REJECTED
        request.responded_at = now
        request.save(update_fields=["status", "responded_at", "updated_at"])
        route_next_instructor(paper)
        return WebhookAppliedResult(applied=True)

    raise RoutingError(f"Unknown decision: {decision}")


def _complexity_level_for(paper: PaperSubmission) -> str:
    category_key = paper.category.key
    exam_type_name = paper.exam_type.name
    if category_key == "primary":
        return ComplexityLevel.BASIC
    if category_key == "secondary":
        return ComplexityLevel.A_LEVEL if "A Level" in exam_type_name or "Bac" in exam_type_name else ComplexityLevel.O_LEVEL
    return ComplexityLevel.UNIVERSITY


def handle_marking_guide_submission(*, instructor_request_id: int, content: list[dict]) -> InstructorMarkingGuide:
    # The stale-state branch below writes an audit flag and must survive even
    # when the operation is rejected — so the flag() call happens outside
    # this atomic block, not inside it (a raise inside atomic would roll the
    # flag back along with everything else).
    with transaction.atomic():
        try:
            request = InstructorRequest.objects.select_for_update().get(id=instructor_request_id)
        except InstructorRequest.DoesNotExist:
            request = None

        if request is None:
            stale_reason = None
        elif request.status != InstructorRequestStatus.ACCEPTED:
            stale_reason = f"Received a marking-guide submission for request {request.id}, but it is {request.status}."
        else:
            stale_reason = False  # valid — proceed with the mutation below

        if stale_reason is False:
            paper = request.paper
            guide = InstructorMarkingGuide.objects.create(
                paper=paper, instructor_id=request.instructor_id, content=content, submitted_at=timezone.now()
            )
            paper.status = PaperStatus.GUIDE_SUBMITTED
            paper.save(update_fields=["status", "updated_at"])

            questions = [MarkingQuestion(question_type=item["question_type"]) for item in content]
            credit_result = PaperCreditCalculator().calculate_detailed(
                questions=questions, level=_complexity_level_for(paper), subject=paper.subject
            )
            InstructorCreditLedger.objects.create(
                instructor_id=request.instructor_id, paper=paper, amount=credit_result.amount
            )

            review_reason = "Instructor marking guide returned, needs review team merge with in-house MCQ key."
            if credit_result.capped:
                review_reason += (
                    f" Credit ceiling applied: formula produced {credit_result.raw_amount} XAF, "
                    f"capped to {credit_result.amount} XAF (see CreditCeilingConfig), worth checking "
                    f"whether this paper/subject's rate config needs tuning."
                )
            flag(subject=guide, category=FlagCategory.GUIDE_REVIEW, reason=review_reason)

    if request is None:
        raise RoutingError("Unknown instructor_request_id.")
    if stale_reason:
        flag(subject=request, category=FlagCategory.WEBHOOK_ANOMALY, reason=stale_reason)
        raise RoutingError(f"Request is not in ACCEPTED state (currently {request.status}).")

    return guide


class MergeError(Exception):
    pass


@transaction.atomic
def merge_and_publish(paper: PaperSubmission) -> PublishedGuide:
    """Combines the in-house MCQ key with the instructor guide, then publishes and pays the contributor bonus."""
    if paper.status != PaperStatus.GUIDE_SUBMITTED:
        raise MergeError(f"Paper must be GUIDE_SUBMITTED to merge (currently {paper.status}).")

    try:
        instructor_guide = paper.instructor_marking_guide
    except InstructorMarkingGuide.DoesNotExist:
        raise MergeError("No instructor marking guide submitted for this paper.") from None

    mcq_key = getattr(paper, "mcq_answer_key", None)

    merged_content = {
        "mcq": mcq_key.content if mcq_key else None,
        "non_mcq": instructor_guide.content,
    }
    published = PublishedGuide.objects.create(
        paper_submission=paper, content=merged_content, published_at=timezone.now()
    )

    paper.status = PaperStatus.PUBLISHED
    paper.save(update_fields=["status", "updated_at"])
    bonus_entry = award_contributor_bonus(paper)

    notify(
        user=paper.submitted_by,
        kind=NotificationKind.SUBMISSION_STATUS,
        title="Your paper is published!",
        body=(
            "Your submission's marking guide is live"
            + (f", and you earned {bonus_entry.amount} credits" if bonus_entry else "")
            + "."
        ),
    )

    return published


def request_withdrawal(*, instructor_id: str, amount: int, payout_method: str) -> WithdrawalRequest:
    """
    Single entry point for creating a WithdrawalRequest (spec §5.4), so the
    KYC/payout approval ticket (§2.1) is created every time regardless of
    where the request comes from — currently only the Django admin, but
    this is the seam a future partner-platform withdrawal API would call
    into too, rather than that API duplicating the flag() call itself.
    """
    withdrawal = WithdrawalRequest.objects.create(
        instructor_id=instructor_id, amount=amount, payout_method=payout_method
    )
    flag(
        subject=withdrawal,
        category=FlagCategory.WITHDRAWAL_APPROVAL,
        reason=f"Instructor {instructor_id} requested a {amount} XAF withdrawal, needs KYC/payout approval.",
    )
    return withdrawal
