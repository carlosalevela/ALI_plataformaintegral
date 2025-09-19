# tests_grado1011/models.py  (o donde tengas este modelo)
from django.db import models
from django.conf import settings
from django.utils import timezone

class TestGrado10_11(models.Model):
    ESTADO_EN_PROGRESO = 'EN_PROGRESO'
    ESTADO_FINALIZADO  = 'FINALIZADO'
    ESTADO_CHOICES = [
        (ESTADO_EN_PROGRESO, 'En progreso'),
        (ESTADO_FINALIZADO,  'Finalizado'),
    ]

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    respuestas = models.JSONField(default=dict, blank=True)  # ahora permite parciales
    resultado = models.TextField(blank=True, null=True)

    # Seguimiento temporal
    fecha_inicio = models.DateTimeField(default=timezone.now, editable=False)  # reemplaza auto_now_add
    fecha_ultima_actividad = models.DateTimeField(auto_now=True)
    # ⚠️ Semántica: fecha_realizacion = cuándo finaliza
    fecha_realizacion = models.DateTimeField(blank=True, null=True)

    # Progreso
    estado = models.CharField(max_length=15, choices=ESTADO_CHOICES, default=ESTADO_EN_PROGRESO)
    ultima_pregunta = models.PositiveSmallIntegerField(default=0)
    respondidas = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        fin = self.fecha_realizacion.isoformat() if self.fecha_realizacion else "en_progreso"
        return f"Test 10/11 de {getattr(self.usuario, 'email', self.usuario_id)} - {fin}"

    @property
    def progreso_pct(self) -> float:
        total = 40  # ⚠️ AJUSTA al número real de preguntas del test 10/11
        if not self.respondidas:
            return 0.0
        return round((self.respondidas / total) * 100, 2)
