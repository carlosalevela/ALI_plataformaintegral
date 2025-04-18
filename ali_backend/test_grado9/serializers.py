from rest_framework import serializers
from .models import TestGrado9

class TestGrado9Serializer(serializers.ModelSerializer):
    usuario_email = serializers.ReadOnlyField(source="usuario.email")  
    class Meta:
        model = TestGrado9
        fields = ["id", "usuario", "usuario_email", "respuestas", "resultado", "fecha_realizacion"]
        read_only_fields = ["resultado", "fecha_realizacion"]  
