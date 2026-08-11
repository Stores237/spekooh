import factory

from .models import Pamphlet, PartnerBookshop


class PartnerBookshopFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PartnerBookshop

    name = factory.Sequence(lambda n: f"Bookshop {n}")


class PamphletFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Pamphlet

    partner = factory.SubFactory(PartnerBookshopFactory)
    title = "GCE A Level Physics — Full Course Pack"
    price_fcfa = 3000
    delivery_available = True
    delivery_fee_fcfa = 500
