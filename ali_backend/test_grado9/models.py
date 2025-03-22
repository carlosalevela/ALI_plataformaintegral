from django.db import models
from django.conf import settings

class TestGrado9(models.Model):
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)  # Relación con Usuario
    respuestas = models.JSONField()  # Almacena respuestas en formato JSON
    resultado = models.TextField(blank=True, null=True)  # ML llenará este campo
    fecha_realizacion = models.DateTimeField(auto_now_add=True)  # Se registra la fecha automáticamente

    def __str__(self):
        return f"Test de {self.usuario.email} - {self.fecha_realizacion}"