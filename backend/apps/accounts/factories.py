import factory

from .models import AccountType, User


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    name = factory.Faker("name")
    account_type = AccountType.REGISTERED
    password = factory.PostGenerationMethodCall("set_password", "testpass123")
