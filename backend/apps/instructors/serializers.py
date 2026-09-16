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


class InstructorWebhookEnvelopeSerializer(serializers.Serializer):
    event_type = serializers.ChoiceField(choices=["instructor_response", "marking_guide_submission"])
