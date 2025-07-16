import numpy as np
import joblib
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.response import Response
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import TestGrado9
from .serializers import TestGrado9Serializer
from .groq_service import generar_explicacion_modalidad  # 👈 Importado aquí

# Rutas a los modelos entrenados
MODEL_RF_PATH = "test_grado9/ml_model/test_grado9_model.pkl"

# Cargar modelos
model_rf = joblib.load(MODEL_RF_PATH)



class TestGrado9ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 9 con predicción automática.
    """
    serializer_class = TestGrado9Serializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return TestGrado9.objects.all().order_by('-fecha_realizacion')
        return TestGrado9.objects.filter(usuario=user).order_by('-fecha_realizacion')

    def perform_create(self, serializer):
        """
        Guarda el test con el usuario autenticado y predice la modalidad sugerida
        por ALI, incluyendo una explicación generada por Groq.
        """
        test_instance = serializer.save(usuario=self.request.user)
        respuestas = test_instance.respuestas

        try:
            # Validar que existan todas las preguntas 1-40
            required_fields = [f"pregunta_{i}" for i in range(1, 41)]
            if not all(field in respuestas for field in required_fields):
                test_instance.resultado = "Error: Faltan respuestas en la solicitud"
                test_instance.save()
                return

            # Validar que las respuestas estén en el conjunto válido
            respuestas_validas = {"A", "B", "C", "D"}
            if not all(respuestas[f"pregunta_{i}"] in respuestas_validas for i in range(1, 41)):
                test_instance.resultado = "Error: Las respuestas deben ser solo A, B, C o D"
                test_instance.save()
                return

            # Mapeo de letras a valores numéricos
            letra_a_valor = {
                "A": 4,  # Me gusta
                "B": 3,  # Me interesa
                "C": 2,  # No me gusta
                "D": 1   # No me interesa
            }

            # Convertir las respuestas a un array numérico
            input_data = np.array([
                letra_a_valor[respuestas[f"pregunta_{i}"]] for i in range(1, 41)
            ]).reshape(1, -1)

            # Predecir con modelo Random Forest únicamente
            prediction_rf = model_rf.predict(input_data)

            # Mapear valor numérico a modalidad
            modalidad_mapeo_inverso = {
                1: "Industrial",
                2: "Comercio",
                3: "Promoción Social",
                4: "Agropecuaria"
            }

            modalidad_rf = modalidad_mapeo_inverso.get(int(prediction_rf[0]), "Desconocido")

            # Preparar respuestas codificadas para Groq
            respuestas_codificadas = {
                f"pregunta_{i}": letra_a_valor[respuestas[f"pregunta_{i}"]] for i in range(1, 41)
            }

            # Generar explicación con Groq para la modalidad predicha
            explicacion = generar_explicacion_modalidad(modalidad_rf, respuestas_codificadas)

            # Resultado final con nuevo formato
            resultado_completo = (
                f"Técnico sugerido por ALI: {modalidad_rf}\n\n"
                f"Explicación: {explicacion}"
            )

            test_instance.resultado = resultado_completo
            test_instance.save()

        except Exception as e:
            test_instance.resultado = f"Error interno: {str(e)}"
            test_instance.save()



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
