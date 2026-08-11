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
    content = MarkingGuideQuestionSerializer(many=True)


class InstructorWebhookEnvelopeSerializer(serializers.Serializer):
    event_type = serializers.ChoiceField(choices=["instructor_response", "marking_guide_submission"])
