import json
import numpy as np
import joblib
import pickle
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import TestGrado9
from .serializers import TestGrado9Serializer

# Cargar el modelo y los encoders
MODEL_PATH = "test_grado9/ml_model/test_grado9_model.pkl"
ENCODER_PATH = "test_grado9/ml_model/test_grado9_encoders.pkl"
TARGET_ENCODER_PATH = "test_grado9/ml_model/test_grado9_target_encoder.pkl"

model = joblib.load(MODEL_PATH)

with open(ENCODER_PATH, "rb") as f:
    encoders = pickle.load(f)

with open(TARGET_ENCODER_PATH, "rb") as f:
    target_encoder = pickle.load(f)


class TestGrado9ViewSet(viewsets.ModelViewSet):
    """
    API para gestionar los tests de grado 9 con predicción automática.
    """
    queryset = TestGrado9.objects.all()
    serializer_class = TestGrado9Serializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        """
        Asigna automáticamente el usuario autenticado al test y ejecuta la predicción.
        """
        test_instance = serializer.save(usuario=self.request.user)

        # Obtener respuestas del test
        respuestas = test_instance.respuestas

        try:
            # Verificar que todas las preguntas estén presentes
            required_fields = ["pregunta_1", "pregunta_2", "pregunta_3"]
            if not all(field in respuestas for field in required_fields):
                test_instance.resultado = "Error: Faltan respuestas en la solicitud"
                test_instance.save()
                return

            # Transformar respuestas usando los encoders
            try:
                input_data = np.array([
                    encoders["pregunta_1"].transform([respuestas["pregunta_1"]])[0],
                    encoders["pregunta_2"].transform([respuestas["pregunta_2"]])[0],
                    encoders["pregunta_3"].transform([respuestas["pregunta_3"]])[0]
                ]).reshape(1, -1)
            except ValueError:
                test_instance.resultado = "Error: Respuesta inválida"
                test_instance.save()
                return

            # Realizar predicción
            prediction = model.predict(input_data)

            # Decodificar la predicción
            career = target_encoder.inverse_transform(prediction)[0]

            # Guardar resultado en la base de datos
            test_instance.resultado = career
            test_instance.save()

        except Exception as e:
            test_instance.resultado = f"Error en la predicción: {str(e)}"
            test_instance.save()
