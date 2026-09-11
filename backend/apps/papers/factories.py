import factory
from django.utils import timezone

from .models import ExamCategory, ExamType, PaperSubmission, PublishedGuide, Subject


class ExamCategoryFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ExamCategory
        django_get_or_create = ("key",)

    key = "secondary"
    title = "Secondary"
    requires_system = True


class ExamTypeFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = ExamType
        django_get_or_create = ("category", "system", "name")

    category = factory.SubFactory(ExamCategoryFactory)
    system = "anglophone"
    name = "O Level"


class SubjectFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Subject
        django_get_or_create = ("key",)

    key = "biology"
    title = "Biology"
    code = "0510"
    language = "en"


class PaperSubmissionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PaperSubmission

    submitted_by = factory.SubFactory("apps.accounts.factories.UserFactory")
    category = factory.SubFactory(ExamCategoryFactory)
    exam_type = factory.SubFactory(ExamTypeFactory)
    subject = factory.SubFactory(SubjectFactory)
    year = 2023
    file_ref = "papers/sample.pdf"


class PublishedGuideFactory(factory.django.DjangoModelFactory):
    """Same shape apps.instructors.services.merge_and_publish actually
    produces — see PublishedGuide.content's own field comment."""

    class Meta:
        model = PublishedGuide

    paper_submission = factory.SubFactory(PaperSubmissionFactory)
    content = factory.LazyFunction(
        lambda: {
            "mcq": {"1": "B", "2": "A", "3": "D"},
            "non_mcq": [
                {"question_type": "SHORT_ANSWER", "text": "Name the site of aerobic respiration.", "answer": "The mitochondrion."},
                {"question_type": "ESSAY", "text": "Explain how enzymes lower activation energy.", "answer": "Enzymes are proteins that act as biological catalysts."},
            ],
        }
    )
    published_at = factory.LazyFunction(timezone.now)
