import json
import requests
from django.conf import settings

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-8b-instant"  # Alternativa de más calidad: "llama-3.3-70b-versatile"

def generar_explicacion_modalidad(modalidad, respuestas):
    # Asegura que 'respuestas' sea texto legible (por si es dict/list)
    if not isinstance(respuestas, str):
        try:
            respuestas = json.dumps(respuestas, ensure_ascii=False)
        except Exception:
            respuestas = str(respuestas)

    system_msg = (
        "Eres un orientador vocacional empático. Responde en español, "
        "con tono juvenil, claro y motivador. Sé breve (80–120 palabras) "
        "y evita tecnicismos innecesarios."
    )

    user_prompt = f"""
Eres un orientador vocacional para estudiantes de colegio. Un estudiante de grado 9 ha realizado un test y el modelo ha sugerido la modalidad técnica "{modalidad}".

Las respuestas del test (1=No me interesa, 4=Me gusta) fueron:
{respuestas}

Con base en esto, redacta una explicación clara, educativa, breve y motivadora sobre por qué se le recomienda esta modalidad. Usa un lenguaje juvenil y positivo.
""".strip()

    headers = {
        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
        "Content-Type": "application/json",
    }

    data = {
        "model": GROQ_MODEL,
        "messages": [
            {"role": "system", "content": system_msg},
            {"role": "user", "content": user_prompt},
        ],
        # Opcional: ajusta a tu gusto
        "temperature": 0.7,
        "max_tokens": 300,
    }

    try:
        response = requests.post(GROQ_API_URL, headers=headers, json=data, timeout=30)

        # Logs útiles para depuración
        print("🟡 Groq status:", response.status_code)
        try:
            print("🟡 Groq response body:", response.text[:2000])
        except Exception:
            pass

        if response.status_code == 200:
            payload = response.json()
            return payload["choices"][0]["message"]["content"].strip()

        # Devuelve el mensaje de error de Groq para saber exactamente qué pasó
        try:
            err = response.json()
        except Exception:
            err = {"raw": response.text}
        return f"No se pudo generar la explicación (status {response.status_code}): {err}"

    except requests.Timeout:
        return "Error: tiempo de espera agotado al conectar con Groq."
    except Exception as e:
        print("🔴 Error al conectar con Groq:", str(e))
        return f"Error al conectar con Groq: {str(e)}"
