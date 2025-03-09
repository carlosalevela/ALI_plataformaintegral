from rest_framework import serializers
from Usuario.models import Usuario

class UsuarioSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)  # Oculta la contraseña en respuestas

    class Meta:
        model = Usuario
        fields = ('id', 'username', 'nombre', 'email', 'rol', 'grado', 'edad', 'password')  # Eliminado `fecha_registro`
        extra_kwargs = {
            'password': {'write_only': True},  # No mostrar en respuestas
        }

    def create(self, validated_data):
        """Crea un nuevo usuario y encripta la contraseña antes de guardarlo."""
        password = validated_data.pop('password')
        usuario = Usuario(**validated_data)
        usuario.set_password(password)  # Hashear contraseña
        usuario.save()
        return usuario

    def update(self, instance, validated_data):
        """Actualiza un usuario, manejando correctamente la contraseña."""
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if password:
            instance.set_password(password)  # Hashear nueva contraseña
        instance.save()
        return instance
