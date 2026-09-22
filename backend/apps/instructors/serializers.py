from rest_framework import serializers

from .models import InstructorRequest


class InstructorRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = InstructorRequest
        fields = [
            "id",
            "paper",
            "instructor_id",
            "sent_at",
            "responds_by",
            "status",
            "responded_at",
            "guide_deadline",
        ]
        read_only_fields = fields


class InstructorResponseWebhookSerializer(serializers.Serializer):
    instructor_request_id = serializers.IntegerField()
    decision = serializers.ChoiceField(choices=["ACCEPTED", "REJECTED"])


class MarkingGuideQuestionSerializer(serializers.Serializer):
    question_type = serializers.ChoiceField(choices=["SHORT_ANSWER", "CALCULATION", "ESSAY"])
    text = serializers.CharField(required=False, allow_blank=True)
    answer = serializers.CharField(required=False, allow_blank=True)


class MarkingGuideSubmissionWebhookSerializer(serializers.Serializer):
    instructor_request_id = serializers.IntegerField()
    # content is always required, even in file mode: a per-question
    # {question_type} tally (real text/answer omitted) so credit calculation
    # still has something to count — see handle_marking_guide_submission.
    content = MarkingGuideQuestionSerializer(many=True)
    # Set only when the instructor uploaded a file instead of filling the
    # structured form on the partner platform's own UI.
    guide_file_url = serializers.URLField(required=False, allow_null=True)


class InstructorProfileUpdateWebhookSerializer(serializers.Serializer):
    """The partner platform's full current statement of who this instructor
    is and what they're qualified to mark — see
    apps.instructors.services.upsert_instructor_profile. Always the whole
    profile, never a partial patch: a field the partner omits is stored as
    blank/empty, not left at its previous value.
    """

    instructor_id = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    display_name = serializers.CharField(max_length=150, required=False, allow_blank=True, default="")
    # ExamCategory.key values, e.g. ["secondary", "university"] — validated
    # against real categories in upsert_instructor_profile, not here, so the
    # error names exactly which key(s) don't exist.
    qualified_categories = serializers.ListField(child=serializers.CharField(max_length=40), required=False, default=list)


class InstructorWebhookEnvelopeSerializer(serializers.Serializer):
    event_type = serializers.ChoiceField(
        choices=["instructor_response", "marking_guide_submission", "instructor_profile_update"]
    )


class PartnerCategoryListRequestSerializer(serializers.Serializer):
    """Empty on purpose — see PartnerEarningsRequestSerializer's own docstring
    reasoning: the signed channel still needs a body to sign, even an empty one."""


class PartnerPaperLinkRequestSerializer(serializers.Serializer):
    instructor_request_id = serializers.IntegerField()
    instructor_id = serializers.CharField(max_length=100)


class PartnerEarningsRequestSerializer(serializers.Serializer):
    instructor_id = serializers.CharField(max_length=100)
