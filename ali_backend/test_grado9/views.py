import numpy as np
import joblib
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import TestGrado9
from .serializers import TestGrado9Serializer

# Rutas a los modelos entrenados
MODEL_RF_PATH = "test_grado9/ml_model/test_grado9_model.pkl"
MODEL_KNN_PATH = "test_grado9/ml_model/modelo_knn.pkl"

# Cargar modelos
model_rf = joblib.load(MODEL_RF_PATH)
model_knn = joblib.load(MODEL_KNN_PATH)

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
        Guarda el test con el usuario autenticado y predice la modalidad según las respuestas.
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

            # Predecir con ambos modelos
            prediction_rf = model_rf.predict(input_data)
            prediction_knn = model_knn.predict(input_data)

            # Mapear valor numérico a modalidad
            modalidad_mapeo_inverso = {
                1: "Industrial",
                2: "Comercio",
                3: "Promoción Social",
                4: "Agropecuaria"
            }

            modalidad_rf = modalidad_mapeo_inverso.get(int(prediction_rf[0]), "Desconocido")
            modalidad_knn = modalidad_mapeo_inverso.get(int(prediction_knn[0]), "Desconocido")

            # Combinar resultados (puedes separar esto si deseas campos diferentes)
            resultado_completo = f"RandomForest: {modalidad_rf} | KNN: {modalidad_knn}"
            test_instance.resultado = resultado_completo
            test_instance.save()

        except Exception as e:
            test_instance.resultado = f"Error interno: {str(e)}"
            test_instance.save()
