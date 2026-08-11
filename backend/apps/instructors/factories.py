import factory

from .models import InstructorSubjectQueue, PartnerCredential


class InstructorSubjectQueueFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = InstructorSubjectQueue

    subject = factory.SubFactory("apps.papers.factories.SubjectFactory")
    instructor_id = factory.Sequence(lambda n: f"instructor-{n}")
    priority_order = 1
    active = True


class PartnerCredentialFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PartnerCredential

    partner_id = "partner-platform-1"
    hmac_secret = "test-shared-secret"
    is_active = True
