import factory
from django.core.files.base import ContentFile

from .models import Pamphlet, PartnerBookshop


class PartnerBookshopFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PartnerBookshop

    name = factory.Sequence(lambda n: f"Bookshop {n}")
    # Real defaults for the compulsory KYC fields (owner decision,
    # 2026-09-17) -- so tests exercising the real redeem-verification flow
    # (which needs a real contact_email/verification_phone to send a code
    # to) get one without every call site having to set it explicitly.
    full_name = factory.Sequence(lambda n: f"Partner Owner {n}")
    contact_email = factory.Sequence(lambda n: f"partner{n}@example.com")
    orange_money_number = "670000000"
    cni_number = "1234567890"
    nui_number = "P000000000000A"
    location = "Molyko, Buea"

    @factory.lazy_attribute
    def cni_document(self):
        return ContentFile(b"fake-cni-scan", name="cni.jpg")

    @factory.lazy_attribute
    def nui_document(self):
        return ContentFile(b"fake-nui-scan", name="nui.jpg")


class PamphletFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Pamphlet

    partner = factory.SubFactory(PartnerBookshopFactory)
    title = "GCE A Level Physics: Full Course Pack"
    price_fcfa = 3000
    delivery_available = True
    delivery_fee_fcfa = 500
