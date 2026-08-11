from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from .models import AccountType, User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone_number",
            "name",
            "account_type",
            "education_level",
            "region",
            "language_pref",
            "created_at",
        ]
        read_only_fields = ["id", "account_type", "created_at"]


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = ["email", "phone_number", "name", "password", "education_level", "region", "language_pref"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(account_type=AccountType.REGISTERED, **validated_data)
        user.set_password(password)
        user.save(update_fields=["password"])
        return user


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds the serialized user alongside the token pair on login."""

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data


def tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}
