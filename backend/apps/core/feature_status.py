"""
What is really switched on, for the app's "not fully functional yet" notices.

Read from the live wiring rather than a hand-set flag, so it cannot drift from
the truth: payments are "live" only when the payment provider in use is not the
mock. Anything not listed here is either fully working or already labelled in
the app ("coming soon" quizzes, for example). Add a key here when another
feature can look live while not being so.
"""


def current_feature_status() -> dict[str, bool]:
    from apps.payments.services import payments_are_live

    return {"payments_live": payments_are_live()}
