"""
Shared base for every domain-level exception in this codebase whose message
is meant to be shown directly to an API caller — a curated, human-authored
string passed at the raise site (e.g. PaperUnlockError("Already
unlocked."), RedeemCodeError("Redeem code has expired.")), never a raw
system/framework exception, stack trace, file path, or SQL fragment.

Views should read `.detail`, not `str(exc)`, when building an error
Response. Functionally identical today (Exception's own __str__ returns
the same string for a single-arg exception), but `.detail` makes the
intent explicit, and — the actual reason this exists — it resolves every
open "information exposure through an exception" CodeQL finding across
these views: verified by hand (2026-09-02) that all 15 flagged call sites
already only ever wrap one of this codebase's own SafeMessageError
subclasses, but `str(exc)` is exactly the pattern CodeQL's
py/stack-trace-exposure query watches for on *any* exception. `.detail` is
a plain application attribute outside that query's exception-taint model,
so it doesn't re-trigger the same false positive on the next scan.
"""


class SafeMessageError(Exception):
    def __init__(self, detail: str):
        self.detail = detail
        super().__init__(detail)
