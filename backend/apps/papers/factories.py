import factory

from .models import ExamCategory, ExamType, PaperSubmission, Subject


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
