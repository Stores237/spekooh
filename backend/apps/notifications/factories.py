import factory

from .models import Notification, NotificationKind


class NotificationFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Notification

    user = factory.SubFactory("apps.accounts.factories.UserFactory")
    kind = NotificationKind.GENERIC
    title = "Test notification"
    body = "Test body"
