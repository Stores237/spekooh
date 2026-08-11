"""
The data-driven instructor credit calculator (spec §5.2):

    Paper Credit = Σ (question_i base_rate × complexity_multiplier)
                 × subject_demand_factor

MCQ exclusion is enforced in exactly one place: calculate() raises if any
question is MCQ, since MCQ is marked in-house and never carries instructor
credit cost. All rates are read from the DB config tables at call time, so
ops can retune numbers without a deploy.
"""

import dataclasses
from decimal import Decimal

from .models import ComplexityLevel, LevelComplexityMultiplier, QuestionType, QuestionTypeRate, SubjectDemandFactor


class CreditRulesError(Exception):
    pass


@dataclasses.dataclass(frozen=True)
class MarkingQuestion:
    question_type: str  # a QuestionType value; MCQ is rejected by calculate()


class PaperCreditCalculator:
    """Stateless — safe to instantiate per call or share as a module-level singleton."""

    def calculate(self, *, questions: list[MarkingQuestion], level: str, subject) -> int:
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
        total = subtotal * demand
        return int(total.quantize(Decimal("1")))


__all__ = ["PaperCreditCalculator", "MarkingQuestion", "CreditRulesError", "ComplexityLevel", "QuestionType"]
