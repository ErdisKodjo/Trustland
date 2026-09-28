from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import Utilisateur


class TokenPairSerializer(TokenObtainPairSerializer):
    """Ajoute le rôle et le username dans le payload JWT."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['username'] = user.username
        token['role'] = user.role
        return token


class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ['id', 'username', 'email', 'role', 'is_active', 'date_joined', 'last_login']
        read_only_fields = ['date_joined', 'last_login', 'role', 'is_active']


class AdminUtilisateurSerializer(serializers.ModelSerializer):
    """Serializer complet pour la gestion des utilisateurs par un admin."""

    class Meta:
        model = Utilisateur
        fields = ['id', 'username', 'email', 'role', 'is_active', 'date_joined', 'last_login']
        read_only_fields = ['username', 'date_joined', 'last_login']

    def validate_role(self, value):
        allowed = [c[0] for c in Utilisateur.Role.choices]
        if value not in allowed:
            raise serializers.ValidationError("Rôle invalide.")
        return value


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, required=True, validators=[validate_password]
    )
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = Utilisateur
        fields = ['username', 'email', 'password', 'password2']

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {'password2': "Les deux mots de passe ne correspondent pas."}
            )
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        validated_data['role'] = Utilisateur.Role.PROPRIETAIRE
        return Utilisateur.objects.create_user(**validated_data)


class AdminCreateSerializer(serializers.ModelSerializer):
    """Création d'un compte par un admin — tous les rôles sont autorisés."""
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])

    class Meta:
        model = Utilisateur
        fields = ['username', 'email', 'password', 'role']

    def create(self, validated_data):
        return Utilisateur.objects.create_user(**validated_data)


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
