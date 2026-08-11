import datetime

import factory
from django.utils import timezone

from .models import CreditLedgerEntry, RedeemCode


class CreditLedgerEntryFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = CreditLedgerEntry

    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    amount = 200
    reason = "Paper accepted"


class RedeemCodeFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = RedeemCode

    owner = factory.SubFactory("apps.accounts.factories.UserFactory")
    value_percent = 10
    tier_at_issuance = 5
    expires_at = factory.LazyFunction(lambda: timezone.now() + datetime.timedelta(days=30))
