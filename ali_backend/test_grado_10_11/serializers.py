from rest_framework import serializers
from .models import TestGrado10_11

class TestGrado10_11Serializer(serializers.ModelSerializer):
    usuario_email = serializers.ReadOnlyField(source='usuario.email')  # Para mostrar el email del usuario

    class Meta:
        model = TestGrado10_11
        fields = ['id', 'usuario', 'usuario_email', 'respuestas', 'resultado', 'fecha_realizacion']
        read_only_fields = ['id', 'usuario_email', 'fecha_realizacion', 'resultado']  # Estos campos no se pueden modificar
