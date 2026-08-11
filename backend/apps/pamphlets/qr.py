from django.conf import settings
from django.core import signing

QR_EXPIRY_DAYS = 30
COURIER_SELF_CONFIRM_DAYS = 3


def _signer() -> signing.TimestampSigner:
    return signing.TimestampSigner(salt=settings.QR_SIGNING_SALT)


def generate_qr_token(order_id: int) -> str:
    return _signer().sign(str(order_id))


def verify_qr_token(token: str, max_age_seconds: int) -> int:
    """Returns the order id if the token is valid and unexpired; raises signing errors otherwise."""
    value = _signer().unsign(token, max_age=max_age_seconds)
    return int(value)
