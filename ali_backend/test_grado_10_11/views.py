import numpy as np
import joblib
from django.utils import timezone
from django.db import transaction
from django.contrib.auth import get_user_model
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.views import APIView
from .groq_service import generar_explicacion_carrera  # 👈 nuevo import


from .models import TestGrado10_11
from .serializers import TestGrado10_11Serializer

# =========================
# Config / utilidades
# =========================
MODEL_PATH = "test_grado_10_11/ml_model/test_grado10y11_model.pkl"
model = joblib.load(MODEL_PATH)

TOTAL_PREGUNTAS_1011 = 40   # ⚠️ AJUSTA si tu test tiene otro número de preguntas
RESP_VALIDAS = {"A", "B", "C", "D"}
LETRA_A_VALOR = {"A": 4, "B": 3, "C": 2, "D": 1}

CARRERA_MAP = {
    1: "Medicina",
    2: "Ingeniería",
    3: "Administración",
    4: "Psicología",
    5: "Derecho",
    6: "Educación",
    7: "Sistemas/Software",
    8: "Contaduría",
    9: "Diseño Gráfico",
    10: "Ciencias Naturales",
}

def _contar_respondidas(respuestas: dict) -> int:
    if not isinstance(respuestas, dict):
        return 0
    return sum(1 for i in range(1, TOTAL_PREGUNTAS_1011 + 1)
               if respuestas.get(f"pregunta_{i}") in RESP_VALIDAS)

def _ultima_pregunta(respuestas: dict) -> int:
    if not isinstance(respuestas, dict):
        return 0
    last = 0
    for i in range(1, TOTAL_PREGUNTAS_1011 + 1):
        if respuestas.get(f"pregunta_{i}") in RESP_VALIDAS:
            last = i
    return last

def _finalizar_y_predecir(test_instance: TestGrado10_11):
    """
    Lógica de finalización cuando hay 40/40 válidas:
    - Predice carrera con tu modelo ya cargado
    - Genera explicación con Groq (estilo igual al de 9)
    - Guarda resultado como TEXTO (compat con tu front y filtros)
    """
    respuestas = test_instance.respuestas or {}
    required = [f"pregunta_{i}" for i in range(1, TOTAL_PREGUNTAS_1011 + 1)]
    if not all((k in respuestas) for k in required):
        return
    if not all(respuestas[k] in RESP_VALIDAS for k in required):
        return

    # Array numérico para tu modelo
    input_data = np.array([
        LETRA_A_VALOR[respuestas[f"pregunta_{i}"]] for i in range(1, TOTAL_PREGUNTAS_1011 + 1)
    ]).reshape(1, -1)

    prediction = model.predict(input_data)
    carrera_predicha = CARRERA_MAP.get(int(prediction[0]), "Desconocido")

    # Respuestas codificadas 1..4 para Groq (mismo patrón que 9)
    respuestas_codificadas = {
        f"pregunta_{i}": LETRA_A_VALOR[respuestas[f"pregunta_{i}"]]
        for i in range(1, TOTAL_PREGUNTAS_1011 + 1)
    }

    # Explicación Groq (NO cambia tu formato de guardado)
    explicacion = generar_explicacion_carrera(carrera_predicha, respuestas_codificadas)

    # Resultado final en TEXTO (como 9, mantienes front y filtros icontains)
    resultado_completo = (
        f"Carrera sugerida por ALI: {carrera_predicha}\n\n"
        f"Explicación: {explicacion}"
    )

    test_instance.resultado = resultado_completo
    test_instance.estado = TestGrado10_11.ESTADO_FINALIZADO
    if not test_instance.fecha_realizacion:
        test_instance.fecha_realizacion = timezone.now()
    test_instance.save(update_fields=['resultado', 'estado', 'fecha_realizacion', 'fecha_ultima_actividad'])


class TestGrado10_11ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 10 y 11 con predicción automática de carrera recomendada.
    - Si llegan parciales: EN_PROGRESO (no se toca 'resultado')
    - Si llegan 40/40 válidas: se predice y FINALIZA (tu flujo original)
    """
    serializer_class = TestGrado10_11Serializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = TestGrado10_11.objects.all()

        if user.is_staff or user.is_superuser:
            # Filtro opcional por estado: ?estado=EN_PROGRESO | FINALIZADO
            estado = self.request.query_params.get('estado')
            if estado in (TestGrado10_11.ESTADO_EN_PROGRESO, TestGrado10_11.ESTADO_FINALIZADO):
                qs = qs.filter(estado=estado)

            # Orden opcional por actividad: ?orden=actividad
            orden = self.request.query_params.get('orden')
            if orden == 'actividad':
                return qs.order_by('-fecha_ultima_actividad', '-id')

            # Comportamiento por defecto (como tenías)
            return qs.order_by('-fecha_realizacion', '-id')

        # Usuario normal: sus tests, por fecha_realizacion
        return TestGrado10_11.objects.filter(usuario=user).order_by('-fecha_realizacion', '-id')

    def perform_create(self, serializer):
        """
        Guarda el test con el usuario autenticado.
        - Si faltan respuestas: EN_PROGRESO
        - Si están todas y válidas: predice y finaliza
        """
        test_instance = serializer.save(usuario=self.request.user)
        respuestas = test_instance.respuestas or {}

        # Actualiza progreso
        test_instance.respondidas = _contar_respondidas(respuestas)
        test_instance.ultima_pregunta = _ultima_pregunta(respuestas)

        try:
            if test_instance.respondidas < TOTAL_PREGUNTAS_1011:
                # Parcial → EN_PROGRESO
                test_instance.estado = TestGrado10_11.ESTADO_EN_PROGRESO
                test_instance.save(update_fields=['respondidas', 'ultima_pregunta', 'estado'])
                return

            # Validación estricta (todas válidas)
            required = [f"pregunta_{i}" for i in range(1, TOTAL_PREGUNTAS_1011 + 1)]
            if not all(respuestas[k] in RESP_VALIDAS for k in required):
                test_instance.resultado = "Error: Las respuestas deben ser solo A, B, C o D"
                test_instance.estado = TestGrado10_11.ESTADO_EN_PROGRESO
                test_instance.save(update_fields=['resultado', 'estado', 'respondidas', 'ultima_pregunta'])
                return

            # Completo → predice y finaliza (tu lógica)
            _finalizar_y_predecir(test_instance)

        except Exception as e:
            test_instance.resultado = f"Error interno: {str(e)}"
            test_instance.save(update_fields=['resultado'])

    def update(self, request, *args, **kwargs):
        """
        Evita que los usuarios actualicen manualmente los resultados.
        """
        test = self.get_object()
        data = request.data.copy()
        if "resultado" in data:
            data.pop("resultado")
        serializer = self.get_serializer(test, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # ---------- Acciones para progreso en tiempo real ----------
    @action(detail=False, methods=['post'], url_path='iniciar')
    def iniciar(self, request):
        """
        Crea o devuelve un test EN_PROGRESO para el usuario actual.
        """
        user = request.user
        draft = (TestGrado10_11.objects
                 .filter(usuario=user, estado=TestGrado10_11.ESTADO_EN_PROGRESO)
                 .order_by('-fecha_ultima_actividad')
                 .first())
        if not draft:
            draft = TestGrado10_11.objects.create(usuario=user, respuestas={})
        return Response(TestGrado10_11Serializer(draft).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'], url_path='progreso')
    def progreso(self, request, pk=None):
        """
        Actualiza respuestas parciales (como en 9°).
        Body:
          - {"pregunta": 7, "respuesta": "B"}
          - {"respuestas": {"pregunta_7": "B", "pregunta_8": "A"}, "ultima_pregunta": 8}
        """
        user = request.user
        try:
            test = TestGrado10_11.objects.get(pk=pk)
        except TestGrado10_11.DoesNotExist:
            return Response({"error": "Test no existe."}, status=status.HTTP_404_NOT_FOUND)

        if not (user.is_staff or user.is_superuser or test.usuario_id == user.id):
            return Response({"error": "No tienes permiso para modificar este test."},
                            status=status.HTTP_403_FORBIDDEN)

        if test.estado == TestGrado10_11.ESTADO_FINALIZADO:
            return Response({"error": "El test ya está finalizado."}, status=status.HTTP_400_BAD_REQUEST)

        data = request.data
        respuestas = dict(test.respuestas or {})
        updates = {}

        # Carga simple
        if 'pregunta' in data and 'respuesta' in data:
            try:
                n = int(data['pregunta'])
            except Exception:
                return Response({"error": "Índice de pregunta inválido."}, status=400)
            r = str(data['respuesta']).strip().upper()
            if not (1 <= n <= TOTAL_PREGUNTAS_1011):
                return Response({"error": "Índice de pregunta fuera de rango."}, status=400)
            if r not in RESP_VALIDAS:
                return Response({"error": "Respuesta inválida (A/B/C/D)."}, status=400)
            updates[f"pregunta_{n}"] = r

        # Carga múltiple
        if 'respuestas' in data and isinstance(data['respuestas'], dict):
            for k, v in data['respuestas'].items():
                if not k.startswith('pregunta_'):
                    continue
                try:
                    idx = int(k.split('_')[1])
                except Exception:
                    continue
                r = str(v).strip().upper()
                if 1 <= idx <= TOTAL_PREGUNTAS_1011 and r in RESP_VALIDAS:
                    updates[f"pregunta_{idx}"] = r
                else:
                    return Response({"error": f"Inválida {k} (A/B/C/D y rango válido)."}, status=400)

        if not updates:
            return Response({"error": "No hay respuestas válidas para actualizar."}, status=400)

        with transaction.atomic():
            respuestas.update(updates)
            test.respuestas = respuestas
            test.respondidas = _contar_respondidas(respuestas)

            up_exp = data.get('ultima_pregunta')
            if isinstance(up_exp, int) and 1 <= up_exp <= TOTAL_PREGUNTAS_1011:
                test.ultima_pregunta = up_exp
            else:
                test.ultima_pregunta = _ultima_pregunta(respuestas)

            if test.respondidas >= TOTAL_PREGUNTAS_1011:
                test.estado = TestGrado10_11.ESTADO_FINALIZADO
                if not test.fecha_realizacion:
                    test.fecha_realizacion = timezone.now()
            else:
                test.estado = TestGrado10_11.ESTADO_EN_PROGRESO

            test.save()

        # Si se completó aquí, ejecuta la predicción para mantener tu flujo
        if test.estado == TestGrado10_11.ESTADO_FINALIZADO:
            try:
                _finalizar_y_predecir(test)
            except Exception as e:
                test.resultado = f"Error interno: {str(e)}"
                test.save(update_fields=['resultado'])

        return Response({
            "id": test.id,
            "estado": test.estado,
            "respondidas": test.respondidas,
            "total": TOTAL_PREGUNTAS_1011,
            "progreso_pct": round((test.respondidas / TOTAL_PREGUNTAS_1011) * 100, 2),
            "ultima_pregunta": test.ultima_pregunta,
            "fecha_ultima_actividad": test.fecha_ultima_actividad,
        }, status=200)


# =========================
# APIViews existentes (sin romper)
# =========================
class ResultadoTest10_11PorIDView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, test_id):
        user = request.user
        try:
            if user.is_staff or user.is_superuser:
                test = TestGrado10_11.objects.get(id=test_id)
            else:
                test = TestGrado10_11.objects.get(id=test_id, usuario=user)
        except TestGrado10_11.DoesNotExist:
            return Response(
                {"error": "No tienes acceso a este test o no existe."},
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = TestGrado10_11Serializer(test)
        return Response(serializer.data)

class TestsGrado10_11DeUsuarioView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"error": "No tienes permiso para ver esta información."},
                status=status.HTTP_403_FORBIDDEN
            )

        User = get_user_model()
        try:
            usuario = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({"error": "El usuario no existe."}, status=status.HTTP_404_NOT_FOUND)

        tests = TestGrado10_11.objects.filter(usuario=usuario).order_by('-fecha_realizacion')
        serializer = TestGrado10_11Serializer(tests, many=True)
        return Response(serializer.data)

class FiltroPorCarreraView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"error": "No tienes permisos para ver esta información."},
                status=status.HTTP_403_FORBIDDEN
            )

        carrera = request.query_params.get("carrera", "").strip()
        if not carrera:
            return Response(
                {"error": "Debes especificar una carrera en el parámetro 'carrera'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        tests_filtrados = TestGrado10_11.objects.filter(resultado__icontains=carrera).order_by("-fecha_realizacion")
        serializer = TestGrado10_11Serializer(tests_filtrados, many=True)
        return Response(serializer.data)
