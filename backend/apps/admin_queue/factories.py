import factory

from apps.papers.factories import PaperSubmissionFactory

from .models import AdminFlagQueue, FlagCategory


class AdminFlagQueueFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = AdminFlagQueue

    subject = factory.SubFactory(PaperSubmissionFactory)
    category = FlagCategory.UNASSIGNED_PAPER
    reason = "No instructor accepted within the routing window."
