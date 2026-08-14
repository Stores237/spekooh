"""
The data-driven instructor credit calculator (spec §5.2):

    Paper Credit = Σ (question_i base_rate × complexity_multiplier)
                 × subject_demand_factor

MCQ exclusion is enforced in exactly one place: calculate() raises if any
question is MCQ, since MCQ is marked in-house and never carries instructor
credit cost. All rates are read from the DB config tables at call time, so
ops can retune numbers without a deploy.

The raw formula total is then clamped against CreditCeilingConfig (spec
§5.2's "profit-deficit guardrail") — see calculate_detailed().
"""

import dataclasses
from decimal import Decimal

from .models import (
    ComplexityLevel,
    CreditCeilingConfig,
    LevelComplexityMultiplier,
    QuestionType,
    QuestionTypeRate,
)


class CreditRulesError(Exception):
    pass


@dataclasses.dataclass(frozen=True)
class MarkingQuestion:
    question_type: str  # a QuestionType value; MCQ is rejected by calculate()


@dataclasses.dataclass(frozen=True)
class CreditCalculationResult:
    amount: int  # the actual amount to pay — raw_amount, clamped to the ceiling if it exceeds it
    raw_amount: int  # what the formula alone produced, before any ceiling clamp
    capped: bool  # True if amount < raw_amount (the ceiling actually bit)


class PaperCreditCalculator:
    """Stateless — safe to instantiate per call or share as a module-level singleton."""

    def calculate(self, *, questions: list[MarkingQuestion], level: str, subject) -> int:
        """Convenience wrapper for callers that don't need ceiling-clamp detail."""
        return self.calculate_detailed(questions=questions, level=level, subject=subject).amount

    def calculate_detailed(self, *, questions: list[MarkingQuestion], level: str, subject) -> CreditCalculationResult:
        if not questions:
            raise CreditRulesError("At least one non-MCQ question is required.")

        for question in questions:
            if question.question_type == QuestionType.MCQ:
                raise CreditRulesError(
                    "MCQ questions are marked in-house by the Review Team and never carry instructor credit cost."
                )

        rates = {row.question_type: row.base_rate_xaf for row in QuestionTypeRate.objects.all()}
        missing_types = {q.question_type for q in questions} - rates.keys()
        if missing_types:
            raise CreditRulesError(f"No base rate configured for question type(s): {sorted(missing_types)}")

        try:
            multiplier = LevelComplexityMultiplier.objects.get(level=level).multiplier
        except LevelComplexityMultiplier.DoesNotExist:
            raise CreditRulesError(f"No complexity multiplier configured for level: {level}") from None

        demand_factor = getattr(subject, "demand_factor", None)
        demand = Decimal(demand_factor.factor) if demand_factor is not None else Decimal("1.0")

        subtotal = sum((Decimal(rates[q.question_type]) * multiplier for q in questions), Decimal("0"))
        raw_total = int((subtotal * demand).quantize(Decimal("1")))

        ceiling_config = CreditCeilingConfig.objects.first() or CreditCeilingConfig.objects.create()
        ceiling = ceiling_config.max_credit_per_paper_xaf
        if raw_total > ceiling:
            return CreditCalculationResult(amount=ceiling, raw_amount=raw_total, capped=True)
        return CreditCalculationResult(amount=raw_total, raw_amount=raw_total, capped=False)


__all__ = [
    "PaperCreditCalculator",
    "MarkingQuestion",
    "CreditCalculationResult",
    "CreditRulesError",
    "ComplexityLevel",
    "QuestionType",
]
