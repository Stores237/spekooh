from dataclasses import dataclass


class AIError(Exception):
    pass


class AIRateLimited(AIError):
    pass


class AIUnavailable(AIError):
    pass


class AIRefused(AIError):
    """The provider itself declined — a safety block, or a genuinely empty response."""


@dataclass
class AIResult:
    text: str
    model: str
    tokens_in: int = 0
    tokens_out: int = 0


class BaseProvider:
    name = "base"

    def generate(self, *, system: str, user: str, max_tokens: int = 2048, temperature: float = 0.3) -> AIResult:
        raise NotImplementedError
