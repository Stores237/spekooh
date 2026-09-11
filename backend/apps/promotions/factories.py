import factory

from .models import Promotion


class PromotionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Promotion

    title = "Sample sponsor"
    subtitle = "Sample promotion"
    sponsor_name = "Example Sponsor"
    is_active = False
