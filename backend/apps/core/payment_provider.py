"""
The seam a real Flutterwave (or other) integration will implement later.
`apps.payments` wires whichever concrete class is active behind this
interface; nothing else in the codebase should import a provider directly.
"""

import abc
import dataclasses
import uuid


@dataclasses.dataclass(frozen=True)
class PaymentResult:
    success: bool
    provider_reference: str
    failure_reason: str = ""


class PaymentProvider(abc.ABC):
    @abc.abstractmethod
    def charge(self, *, amount_fcfa: int, phone_number: str, description: str) -> PaymentResult:
        """Attempt to charge `phone_number` for `amount_fcfa`. Returns a PaymentResult."""
        raise NotImplementedError


class MockPaymentProvider(PaymentProvider):
    """Simulates an instantly-successful mobile-money charge. No network calls."""

    def charge(self, *, amount_fcfa: int, phone_number: str, description: str) -> PaymentResult:
        return PaymentResult(success=True, provider_reference=f"mock-{uuid.uuid4().hex[:12]}")
