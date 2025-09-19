import numpy as np
import joblib
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction
from rest_framework.views import APIView
from rest_framework import status, viewsets
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action

from .models import TestGrado9
from .serializers import TestGrado9Serializer
from .groq_service import generar_explicacion_modalidad  # 👈 Importado aquí

# Rutas a los modelos entrenados
MODEL_RF_PATH = "test_grado9/ml_model/test_grado9_model.pkl"

# Cargar modelos
model_rf = joblib.load(MODEL_RF_PATH)

# ----------------- 🔧 Constantes / utilidades de progreso -----------------
TOTAL_PREGUNTAS = 40
RESP_VALIDAS = {"A", "B", "C", "D"}
LETRA_A_VALOR = {"A": 4, "B": 3, "C": 2, "D": 1}
VALOR_A_MODALIDAD = {1: "Industrial", 2: "Comercio", 3: "Promoción Social", 4: "Agropecuaria"}


def _contar_respondidas(respuestas: dict) -> int:
    if not isinstance(respuestas, dict):
        return 0
    return sum(1 for i in range(1, TOTAL_PREGUNTAS + 1)
               if respuestas.get(f"pregunta_{i}") in RESP_VALIDAS)


def _ultima_pregunta(respuestas: dict) -> int:
    if not isinstance(respuestas, dict):
        return 0
    last = 0
    for i in range(1, TOTAL_PREGUNTAS + 1):
        if respuestas.get(f"pregunta_{i}") in RESP_VALIDAS:
            last = i
    return last


def _finalizar_y_predecir(test_instance: TestGrado9):
    """
    Lógica de finalización: predice con RF + explicación Groq.
    Usa exactamente tu mapeo y formato de resultado.
    """
    respuestas = test_instance.respuestas or {}

    # Validación final estricta (40/40 presentes y válidas)
    required_fields = [f"pregunta_{i}" for i in range(1, TOTAL_PREGUNTAS + 1)]
    if not all((f in respuestas) for f in required_fields):
        return  # no finaliza

    if not all(respuestas[f] in RESP_VALIDAS for f in required_fields):
        return  # no finaliza

    # Array numérico
    input_data = np.array([
        LETRA_A_VALOR[respuestas[f"pregunta_{i}"]] for i in range(1, TOTAL_PREGUNTAS + 1)
    ]).reshape(1, -1)

    # Predicción RF
    prediction_rf = model_rf.predict(input_data)
    modalidad_rf = VALOR_A_MODALIDAD.get(int(prediction_rf[0]), "Desconocido")

    # Respuestas codificadas (1..4) para Groq
    respuestas_codificadas = {
        f"pregunta_{i}": LETRA_A_VALOR[respuestas[f"pregunta_{i}"]] for i in range(1, TOTAL_PREGUNTAS + 1)
    }

    # Explicación Groq
    explicacion = generar_explicacion_modalidad(modalidad_rf, respuestas_codificadas)

    # Resultado final (mismo formato que ya usas)
    resultado_completo = (
        f"Técnico sugerido por ALI: {modalidad_rf}\n\n"
        f"Explicación: {explicacion}"
    )

    # Marcar finalizado
    test_instance.resultado = resultado_completo
    test_instance.estado = TestGrado9.ESTADO_FINALIZADO
    test_instance.fecha_realizacion = timezone.now()
    test_instance.save(update_fields=['resultado', 'estado', 'fecha_realizacion', 'fecha_ultima_actividad'])


class TestGrado9ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 9 con predicción automática.
    (Se añadió seguimiento de progreso sin alterar tu flujo final)
    """
    serializer_class = TestGrado9Serializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = TestGrado9.objects.all()

        if user.is_staff or user.is_superuser:
            # ✅ Filtro opcional por estado: ?estado=EN_PROGRESO | FINALIZADO
            estado = self.request.query_params.get('estado')
            if estado in (TestGrado9.ESTADO_EN_PROGRESO, TestGrado9.ESTADO_FINALIZADO):
                qs = qs.filter(estado=estado)

            # ✅ Orden opcional por actividad reciente: ?orden=actividad
            # Si no lo pides, se mantiene tu orden original por fecha_realizacion
            orden = self.request.query_params.get('orden')
            if orden == 'actividad':
                return qs.order_by('-fecha_ultima_actividad', '-id')

            return qs.order_by('-fecha_realizacion', '-id')

        # Estudiante: comportamiento original (orden por fecha_realizacion)
        return TestGrado9.objects.filter(usuario=user).order_by('-fecha_realizacion', '-id')

    def perform_create(self, serializer):
        """
        Guarda el test con el usuario autenticado.
        ✅ Si ya vienen 40/40 válidas, predice y finaliza (tu lógica original).
        ✅ Si vienen parciales, lo deja EN_PROGRESO sin error y actualiza progreso.
        """
        test_instance = serializer.save(usuario=self.request.user)
        respuestas = test_instance.respuestas or {}

        # Actualizar progreso (no rompe tu lógica)
        test_instance.respondidas = _contar_respondidas(respuestas)
        test_instance.ultima_pregunta = _ultima_pregunta(respuestas)

        try:
            # Si no están todas, EN_PROGRESO (antes devolvías "Error: Faltan...")
            if test_instance.respondidas < TOTAL_PREGUNTAS:
                test_instance.estado = TestGrado9.ESTADO_EN_PROGRESO
                test_instance.save(update_fields=['respondidas', 'ultima_pregunta', 'estado'])
                return  # 👈 No predice aún

            # Validación estricta (todas válidas)
            required_fields = [f"pregunta_{i}" for i in range(1, TOTAL_PREGUNTAS + 1)]
            if not all(respuestas[f] in RESP_VALIDAS for f in required_fields):
                test_instance.resultado = "Error: Las respuestas deben ser solo A, B, C o D"
                test_instance.estado = TestGrado9.ESTADO_EN_PROGRESO
                test_instance.save(update_fields=['resultado', 'estado', 'respondidas', 'ultima_pregunta'])
                return

            # ✅ Aquí está completo: finaliza + predice + explicación (tu flujo)
            _finalizar_y_predecir(test_instance)

        except Exception as e:
            test_instance.resultado = f"Error interno: {str(e)}"
            test_instance.save(update_fields=['resultado'])

    # ----------------- 🔄 Acciones opcionales para progreso en tiempo real -----------------
    @action(detail=False, methods=['post'], url_path='iniciar')
    def iniciar(self, request):
        """
        Crea o devuelve un test EN_PROGRESO para el usuario actual.
        (No interfiere con tu POST estándar si envías 40/40 al final)
        """
        user = request.user
        draft = (TestGrado9.objects
                 .filter(usuario=user, estado=TestGrado9.ESTADO_EN_PROGRESO)
                 .order_by('-fecha_ultima_actividad')
                 .first())
        if not draft:
            draft = TestGrado9.objects.create(usuario=user, respuestas={})
        return Response(TestGrado9Serializer(draft).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'], url_path='progreso')
    def progreso(self, request, pk=None):
        """
        Actualiza respuestas parciales para reflejar progreso en vivo.
        No afecta tu endpoint de creación/resultado final.
        Admite:
          - {"pregunta": 7, "respuesta": "B"}
          - {"respuestas": {"pregunta_7": "B", "pregunta_8": "A"}, "ultima_pregunta": 8}
        """
        user = request.user
        try:
            test = TestGrado9.objects.get(pk=pk)
        except TestGrado9.DoesNotExist:
            return Response({"error": "Test no existe."}, status=status.HTTP_404_NOT_FOUND)

        if not (user.is_staff or user.is_superuser or test.usuario_id == user.id):
            return Response({"error": "No tienes permiso para modificar este test."},
                            status=status.HTTP_403_FORBIDDEN)

        if test.estado == TestGrado9.ESTADO_FINALIZADO:
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
            if not (1 <= n <= TOTAL_PREGUNTAS):
                return Response({"error": "Índice de pregunta fuera de 1..40."}, status=400)
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
                if 1 <= idx <= TOTAL_PREGUNTAS and r in RESP_VALIDAS:
                    updates[f"pregunta_{idx}"] = r
                else:
                    return Response({"error": f"Inválida {k} (A/B/C/D y 1..40)."}, status=400)

        if not updates:
            return Response({"error": "No hay respuestas válidas para actualizar."}, status=400)

        with transaction.atomic():
            respuestas.update(updates)
            test.respuestas = respuestas
            test.respondidas = _contar_respondidas(respuestas)

            # ultima_pregunta explícita o calculada
            up_exp = data.get('ultima_pregunta')
            if isinstance(up_exp, int) and 1 <= up_exp <= TOTAL_PREGUNTAS:
                test.ultima_pregunta = up_exp
            else:
                test.ultima_pregunta = _ultima_pregunta(respuestas)

            # estado según completitud
            if test.respondidas >= TOTAL_PREGUNTAS:
                test.estado = TestGrado9.ESTADO_FINALIZADO
            else:
                test.estado = TestGrado9.ESTADO_EN_PROGRESO

            test.save()

        # Si se completó aquí, finaliza y predice (tu formato)
        if test.estado == TestGrado9.ESTADO_FINALIZADO:
            try:
                _finalizar_y_predecir(test)
            except Exception as e:
                test.resultado = f"Error interno: {str(e)}"
                test.save(update_fields=['resultado'])

        return Response({
            "id": test.id,
            "estado": test.estado,
            "respondidas": test.respondidas,
            "total": TOTAL_PREGUNTAS,
            "progreso_pct": round((test.respondidas / TOTAL_PREGUNTAS) * 100, 2),
            "ultima_pregunta": test.ultima_pregunta,
            "fecha_ultima_actividad": test.fecha_ultima_actividad,
        }, status=200)


# ----------------- Tus APIView existentes (SIN CAMBIOS) -----------------
class ResultadoTest9PorIDView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, test_id):
        user = request.user

        try:
            # Si es admin, puede ver cualquier test
            if user.is_staff or user.is_superuser:
                test = TestGrado9.objects.get(id=test_id)
            else:
                # Usuario normal solo puede ver sus propios tests
                test = TestGrado9.objects.get(id=test_id, usuario=user)
        except TestGrado9.DoesNotExist:
            return Response({"error": "No tienes acceso a este test o no existe."}, status=status.HTTP_404_NOT_FOUND)

        serializer = TestGrado9Serializer(test)
        return Response(serializer.data)


class TestsDeUsuarioPorAdminView(APIView):
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

        tests = TestGrado9.objects.filter(usuario=usuario).order_by('-fecha_realizacion')
        serializer = TestGrado9Serializer(tests, many=True)
        return Response(serializer.data)


class FiltroPorTecnicoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(
                {"error": "No tienes permisos para ver esta información."},
                status=status.HTTP_403_FORBIDDEN
            )

        tecnico = request.query_params.get("tecnico", "").strip()

        if not tecnico:
            return Response(
                {"error": "Debes especificar un técnico en el parámetro 'tecnico'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        tests_filtrados = TestGrado9.objects.filter(resultado__icontains=tecnico).order_by("-fecha_realizacion")
        serializer = TestGrado9Serializer(tests_filtrados, many=True)
        return Response(serializer.data)
