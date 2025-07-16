import requests
from django.conf import settings

def generar_explicacion_modalidad(modalidad, respuestas):
    prompt = f"""
Eres un orientador vocacional para estudiantes de colegio. Un estudiante de grado 9 ha realizado un test y el modelo ha sugerido la modalidad técnica "{modalidad}".

Las respuestas del test muestran lo siguiente (codificadas del 1 al 4 donde 4 es "Me gusta" y 1 es "No me interesa"):
{respuestas}.

Con base en esto, redacta una explicación clara, educativa, breve y motivadora sobre por qué se le recomienda esta modalidad. Usa un lenguaje juvenil y positivo.
"""

    headers = {
        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
        "Content-Type": "application/json"
    }

    data = {
        "model": "llama3-8b-8192",
        "messages": [{"role": "user", "content": prompt}]
    }

    try:
        response = requests.post("https://api.groq.com/openai/v1/chat/completions", headers=headers, json=data)

        # 👇 Imprime detalles en consola
        print("🟡 Groq status:", response.status_code)
        print("🟡 Groq response body:", response.text)

        if response.status_code == 200:
            return response.json()["choices"][0]["message"]["content"]
        return f"No se pudo generar la explicación (status {response.status_code})"
    except Exception as e:
        print("🔴 Error al conectar con Groq:", str(e))
        return f"Error al conectar con Groq: {str(e)}"
