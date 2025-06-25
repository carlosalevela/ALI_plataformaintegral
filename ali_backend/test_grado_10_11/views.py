import numpy as np
import joblib
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import TestGrado10_11
from .serializers import TestGrado10_11Serializer

# Cargar el modelo ya entrenado
MODEL_PATH = "test_grado_10_11/ml_model/test_grado10y11_model.pkl"
model = joblib.load(MODEL_PATH)

class TestGrado10_11ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 10 y 11 con predicción automática de carrera recomendada.
    """
    serializer_class = TestGrado10_11Serializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return TestGrado10_11.objects.all().order_by('-fecha_realizacion')
        return TestGrado10_11.objects.filter(usuario=user).order_by('-fecha_realizacion')

    def perform_create(self, serializer):
        """
        Guarda el test con el usuario autenticado y predice la carrera recomendada según las respuestas.
        """
        test_instance = serializer.save(usuario=self.request.user)
        respuestas = test_instance.respuestas

        try:
            # Validar que todas las respuestas estén presentes y sean correctas
            required_fields = [f"pregunta_{i}" for i in range(1, 41)]
            if not all(field in respuestas for field in required_fields):
                test_instance.resultado = "Error: Faltan respuestas en la solicitud"
                test_instance.save()
                return

            respuestas_validas = {"A", "B", "C", "D"}
            if not all(respuestas[f"pregunta_{i}"] in respuestas_validas for i in range(1, 41)):
                test_instance.resultado = "Error: Las respuestas deben ser solo A, B, C o D"
                test_instance.save()
                return

            # Mapeo de las respuestas a valores numéricos
            letra_a_valor = {
                "A": 4,  # Me gusta
                "B": 3,  # Me interesa
                "C": 2,  # No me gusta
                "D": 1   # No me interesa
            }

            input_data = np.array([letra_a_valor[respuestas[f"pregunta_{i}"]] for i in range(1, 41)]).reshape(1, -1)

            # Realizar la predicción con el modelo cargado
            prediction = model.predict(input_data)

            # Mapeo de la predicción numérica a la carrera
            carrera_recomendada_mapeo_inverso = {
                1: "Medicina",
                2: "Ingeniería",
                3: "Administración",
                4: "Psicología",
                5: "Derecho",
                6: "Educación",
                7: "Sistemas/Software",
                8: "Contaduría",
                9: "Diseño Gráfico",
                10: "Ciencias Naturales"
            }

            # Obtener la carrera recomendada a partir de la predicción
            carrera_predicha = carrera_recomendada_mapeo_inverso.get(int(prediction[0]), "Desconocido")
            test_instance.resultado = carrera_predicha
            test_instance.save()

        except Exception as e:
            test_instance.resultado = f"Error interno: {str(e)}"
            test_instance.save()

    def get_queryset(self):
        """
        Devuelve los tests del usuario autenticado.
        Si es admin, devuelve todos los tests.
        """
        user = self.request.user
        if hasattr(user, 'rol') and user.rol == "admin":
            return TestGrado10_11.objects.all()
        return TestGrado10_11.objects.filter(usuario=user)

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

