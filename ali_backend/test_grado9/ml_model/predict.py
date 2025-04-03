import joblib
import pickle
import os
import numpy as np

def cargar_modelo_y_encoders():
    """Carga el modelo de ML y los encoders desde los archivos .pkl"""
    try:
        BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Subir un nivel
        ML_MODEL_DIR = os.path.join(BASE_DIR, "ml_model")  # Ruta correcta

        model_path = os.path.join(ML_MODEL_DIR, "test_grado9_model.pkl")
        encoders_path = os.path.join(ML_MODEL_DIR, "test_grado9_encoders.pkl")
        target_encoder_path = os.path.join(ML_MODEL_DIR, "test_grado9_target_encoder.pkl")

        model = joblib.load(model_path)
        with open(encoders_path, "rb") as f:
            encoders = pickle.load(f)
        with open(target_encoder_path, "rb") as f:
            target_encoder = pickle.load(f)

        return model, encoders, target_encoder

    except Exception as e:
        print(f"Error al cargar los archivos: {e}")
        return None, None, None

def predecir_carrera(respuestas):
    """
    Realiza una predicción basada en las respuestas del usuario.
    :param respuestas: Lista con respuestas (ej. ["A", "Y", "N"])
    :return: Carrera recomendada o mensaje de error
    """
    # Cargar el modelo y encoders
    model, encoders, target_encoder = cargar_modelo_y_encoders()
    if model is None:
        return "Error al cargar el modelo"
    
    try:
        # Codificar respuestas
        respuestas_codificadas = [
            encoders[col].transform([respuestas[i]])[0] if respuestas[i] in encoders[col].classes_ else -1
            for i, col in enumerate(encoders.keys())
        ]

        # Verificar si hay valores inválidos
        if -1 in respuestas_codificadas:
            return "Error: Respuestas inválidas"

        # Convertir a numpy array
        datos_transformados = np.array(respuestas_codificadas).reshape(1, -1)


        # Hacer predicción
        prediccion = model.predict(datos_transformados)


        # Decodificar la predicción (carrera recomendada)
        carrera_recomendada = target_encoder.inverse_transform(prediccion)

        return carrera_recomendada[0]
    
    except Exception as e:
        return f"Error en la predicción: {e}"


