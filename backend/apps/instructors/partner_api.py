"""
Read-only data the partner platform (S@Learn) pulls on demand, over the same
HMAC-signed channel as the webhook (see .webhook).

Two things are pulled rather than pushed, both for the same reason: Spekooh is
the source of truth and the pushed copy goes stale.

* A paper link. Storage links are signed and short-lived (see
  STORAGES["default"]["OPTIONS"]["querystring_expire"]), but an instructor has
  days to respond. A link pushed once inside `new_request` was dead by the
  time anyone read it, so the partner asks for a fresh one each time the
  instructor actually opens the paper.
* Earnings. InstructorCreditLedger and WithdrawalRequest live here, so the
  instructor's balance and payout status are computed here and never copied.
"""

import mimetypes
import os

from django.db.models import Sum

from apps.core.exceptions import SafeMessageError
from apps.papers.models import PaperStatus

from .models import (
    ACTIVE_INSTRUCTOR_REQUEST_STATUSES,
    InstructorCreditLedger,
    InstructorRequest,
    WithdrawalRequest,
    WithdrawalStatus,
)

# Short on purpose: the partner fetches a fresh link every time the paper is
# opened, so nothing needs to outlive a single viewing.
PAPER_LINK_TTL_SECONDS = 15 * 60

# How many rows of history one earnings pull returns.
EARNINGS_HISTORY_LIMIT = 50

# The paper stops being something the instructor needs to read once their
# guide is in; the request itself stays ACCEPTED, so the paper's own status is
# what says whether the work is still open.
_PAPER_STATUSES_WITH_OPEN_WORK = [PaperStatus.INSTRUCTOR_REQUEST_SENT, PaperStatus.AWAITING_MARKING_GUIDE]


class PartnerLookupError(SafeMessageError):
    """No such request for this instructor. Deliberately identical for 'does
    not exist' and 'belongs to someone else' so a caller cannot probe ids."""


class PaperLinkUnavailableError(SafeMessageError):
    """The request exists and is theirs, but is no longer open."""


def _signed_url(fieldfile, ttl_seconds: int) -> str:
    # S3-compatible storage takes a per-call expiry; local disk storage (dev,
    # CI) has no signing at all and its url() takes no such argument.
    try:
        return fieldfile.storage.url(fieldfile.name, expire=ttl_seconds)
    except TypeError:
        return fieldfile.storage.url(fieldfile.name)


def fresh_paper_link(*, instructor_request_id: int, instructor_id: str) -> dict:
    try:
        request = InstructorRequest.objects.select_related("paper").get(
            id=instructor_request_id, instructor_id=instructor_id
        )
    except InstructorRequest.DoesNotExist:
        raise PartnerLookupError("Unknown request for this instructor.") from None

    paper = request.paper
    is_open = request.status in ACTIVE_INSTRUCTOR_REQUEST_STATUSES and paper.status in _PAPER_STATUSES_WITH_OPEN_WORK
    if not is_open:
        raise PaperLinkUnavailableError("This request is no longer open.")
    if not paper.uploaded_file:
        raise PaperLinkUnavailableError("This paper has no file attached.")

    file_name = os.path.basename(paper.uploaded_file.name)
    content_type = mimetypes.guess_type(file_name)[0] or "application/octet-stream"
    return {
        "url": _signed_url(paper.uploaded_file, PAPER_LINK_TTL_SECONDS),
        "expires_in": PAPER_LINK_TTL_SECONDS,
        "file_name": file_name,
        "content_type": content_type,
        "request_status": request.status,
    }


def earnings_summary(*, instructor_id: str) -> dict:
    ledger = InstructorCreditLedger.objects.filter(instructor_id=instructor_id)
    withdrawals = WithdrawalRequest.objects.filter(instructor_id=instructor_id)

    total_earned = ledger.aggregate(total=Sum("amount"))["total"] or 0

    def withdrawn(*statuses):
        return withdrawals.filter(status__in=statuses).aggregate(total=Sum("amount"))["total"] or 0

    paid_out = withdrawn(WithdrawalStatus.PAID)
    in_review = withdrawn(WithdrawalStatus.PENDING, WithdrawalStatus.APPROVED)

    return {
        "currency": "XAF",
        "total_earned": total_earned,
        # A withdrawal reserves its amount the moment it is asked for, not
        # once it is paid -- otherwise the same credits could be requested
        # twice while the first payout is still being approved.
        "available": total_earned - paid_out - in_review,
        "in_review": in_review,
        "paid_out": paid_out,
        "ledger": [
            {
                "id": entry.id,
                "paper_id": entry.paper_id,
                "subject": entry.paper.subject.title if entry.paper and entry.paper.subject_id else None,
                "paper_status": entry.paper.status if entry.paper else None,
                "amount": entry.amount,
                "created_at": entry.created_at.isoformat(),
            }
            for entry in ledger.select_related("paper__subject")[:EARNINGS_HISTORY_LIMIT]
        ],
        "withdrawals": [
            {
                "id": withdrawal.id,
                "amount": withdrawal.amount,
                "status": withdrawal.status,
                "kyc_status": withdrawal.kyc_status,
                "payout_method": withdrawal.payout_method,
                "created_at": withdrawal.created_at.isoformat(),
                "updated_at": withdrawal.updated_at.isoformat(),
            }
            for withdrawal in withdrawals[:EARNINGS_HISTORY_LIMIT]
        ],
    }
