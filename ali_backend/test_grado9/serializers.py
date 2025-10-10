from rest_framework import serializers
from .models import TestGrado9
from django.conf import settings

TOTAL_PREGUNTAS = getattr(settings, "GRADO9_TOTAL_PREGUNTAS", 48)

class TestGrado9Serializer(serializers.ModelSerializer):
    usuario_email = serializers.ReadOnlyField(source="usuario.email")
    progreso_pct = serializers.SerializerMethodField()

    class Meta:
        model = TestGrado9
        fields = [
            # 🔹 Campos originales (intactos)
            "id",
            "usuario",
            "usuario_email",
            "respuestas",
            "resultado",
            "fecha_realizacion",

            # 🔹 Nuevos campos de progreso/seguimiento
            "estado",
            "ultima_pregunta",
            "respondidas",
            "progreso_pct",
            "fecha_inicio",
            "fecha_ultima_actividad",
        ]
        read_only_fields = [
            # Mantén estos como solo-lectura para no romper tu flujo actual
            "resultado",
            "fecha_realizacion",
            "progreso_pct",
            "fecha_inicio",
            "fecha_ultima_actividad",
            "respondidas",         # se calcula del JSON de respuestas
        ]

    def get_progreso_pct(self, obj: TestGrado9):
        # El modelo expone .progreso_pct como @property; si no, calculamos aquí por seguridad.
        try:
            return getattr(obj, "progreso_pct", None) or round((obj.respondidas / TOTAL_PREGUNTAS) * 100, 2)
        except Exception:
            return 0.0
