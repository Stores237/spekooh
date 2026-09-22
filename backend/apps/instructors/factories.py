import factory

from .models import InstructorProfileCache, InstructorSubjectQueue, PartnerCredential


class InstructorProfileCacheFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = InstructorProfileCache
        django_get_or_create = ("instructor_id",)

    instructor_id = factory.Sequence(lambda n: f"instructor-{n}")
    display_name = ""
    email = factory.LazyAttribute(lambda o: f"{o.instructor_id}@example.com")
    qualified_categories = factory.LazyFunction(lambda: ["secondary"])


class InstructorSubjectQueueFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = InstructorSubjectQueue
        # The qualified_categories post-generation hook below never mutates
        # the queue row itself (it creates a separate InstructorProfileCache
        # row), so the extra post-hook save factory_boy otherwise does is
        # pure overhead.
        skip_postgeneration_save = True

    subject = factory.SubFactory("apps.papers.factories.SubjectFactory")
    instructor_id = factory.Sequence(lambda n: f"instructor-{n}")
    priority_order = 1
    active = True

    @factory.post_generation
    def qualified_categories(obj, create, extracted, **kwargs):
        """Test convenience only — in production this data always comes from
        the partner's own instructor_profile_update webhook event (see
        apps.instructors.services.upsert_instructor_profile), never from the
        queue row itself. Defaults to ["secondary"], matching every test
        paper's default category (_routable_paper) — pass an explicit list
        (e.g. qualified_categories=["university"], or [] for "no profile
        pushed yet") to test a real qualification mismatch."""
        if not create:
            return
        InstructorProfileCacheFactory(
            instructor_id=obj.instructor_id, qualified_categories=extracted if extracted is not None else ["secondary"]
        )


class PartnerCredentialFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = PartnerCredential

    partner_id = "partner-platform-1"
    hmac_secret = "test-shared-secret"
    is_active = True
