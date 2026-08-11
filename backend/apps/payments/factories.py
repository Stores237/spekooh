import datetime

import factory
from django.utils import timezone

from .models import PaymentPurpose, PaymentTransaction, PaymentTransactionStatus, Subscription


class PaymentTransactionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PaymentTransaction

    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    purpose = PaymentPurpose.SUBSCRIPTION
    amount_fcfa = 500
    phone_number = "670000000"
    status = PaymentTransactionStatus.SUCCESS
    provider_reference = "mock-test"


class SubscriptionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Subscription

    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    renews_at = factory.LazyFunction(lambda: timezone.now() + datetime.timedelta(days=30))
