import factory

from .models import XPLedgerEntry


class XPLedgerEntryFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = XPLedgerEntry

    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    amount = 10
    reason = "Completed quiz: Sample quiz"
