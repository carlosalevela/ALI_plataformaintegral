import os, joblib, pandas as pd, numpy as np

BASE = os.path.join(os.path.dirname(__file__), "test_grado9_model")  # sin extensión

MODEL = joblib.load(f"{BASE}.pkl")
LE     = joblib.load(f"{BASE}_labelencoder.pkl")

# --- SANEAR XCOLS: quitar vacíos/nan/espacios y asegurar longitud ---
_raw = pd.read_csv(f"{BASE}_xcols.csv", header=None).iloc[:, 0]
XCOLS = [str(c).strip() for c in _raw if str(c).strip() not in ("", "nan", "None")]

# Chequeo de longitud (muy útil para detectar CSV con línea extra)
expected = int(getattr(MODEL, "n_features_in_", len(XCOLS)))
if len(XCOLS) != expected:
    # Si hay de más, truncamos; si hay menos, avisamos fuerte.
    if len(XCOLS) > expected:
        XCOLS = XCOLS[:expected]
    else:
        raise RuntimeError(
            f"XCOLS tiene {len(XCOLS)} columnas pero el modelo espera {expected}. "
            f"Revisa {BASE}_xcols.csv."
        )

MAPEO = {"Me encanta": 3, "Me interesa": 2, "No me gusta": 1}

PREGUNTAS_POR_TECNICO = {
    "Mantenimiento de Hardware y Software": list(range(1, 5)),
    "Robótica": list(range(5, 9)),
    "Electricidad y Electrónica": list(range(9, 13)),
    "Emprendimiento y Fomento Empresarial": list(range(13, 17)),
    "Diseño Gráfico": list(range(17, 21)),
    "Contabilidad y Finanzas": list(range(21, 25)),
    "Primera Infancia": list(range(25, 29)),
    "Seguridad y Salud en el Trabajo": list(range(29, 33)),
    "Promoción de la Salud": list(range(33, 37)),
    "Agroindustria": list(range(37, 43)),
    "Científico/Humanista": list(range(43, 49)),
}

def _vectorizar(respuestas_texto):
    if not isinstance(respuestas_texto, (list, tuple)) or len(respuestas_texto) != 48:
        raise ValueError("Se esperaban 48 respuestas en orden.")
    base = [MAPEO[r] for r in respuestas_texto]
    s = pd.Series(base, index=[f"pregunta_{i}" for i in range(1, 49)])
    # meta-features esperadas por el modelo
    for t, qs in PREGUNTAS_POR_TECNICO.items():
        col = f"suma_{t}"
        if col in XCOLS:
            s[col] = s[[f"pregunta_{q}" for q in qs]].sum()
    return s.reindex(XCOLS).to_numpy(dtype=np.float32).reshape(1, -1)

def predecir_tecnico(respuestas_texto, top_k: int = 3):
    X_new = _vectorizar(respuestas_texto)
    proba = MODEL.predict_proba(X_new)[0]
    idx = np.argsort(proba)[::-1]
    clases = LE.inverse_transform(idx)
    top_k = max(1, min(top_k, len(clases)))
    return {
        "tecnico_predicho": clases[0],
        "top3": list(zip(clases[:top_k].tolist(), proba[idx[:top_k]].round(4).tolist())),
        "probabilidades": dict(zip(LE.classes_.tolist(), proba.round(4).tolist())),
    }

def predecir_tecnico_con_regla(respuestas_texto, umbral=0.55, top_k: int = 3, margin_min: float = 4.0):
    """
    Reglas:
    1) Si la confianza del modelo < umbral => usar técnico ganador por suma_<bloque>.
    2) AUNQUE la confianza sea alta, si (suma_top - suma_segundo) >= margin_min => forzar técnico por suma.
       - Para bloques de 4 ítems, un perfil “puro” da margen = 12 - 4 = 8.
       - Para bloques de 6 ítems, margen = 18 - 6 = 12.
    """
    import pandas as _pd
    X_new = _vectorizar(respuestas_texto)
    proba = MODEL.predict_proba(X_new)[0]
    idx = np.argsort(proba)[::-1]
    clases = LE.inverse_transform(idx)

    pred_modelo = clases[0]
    prob_modelo = float(proba[idx[0]])

    # -- metasumas --
    base = [MAPEO[r] for r in respuestas_texto]
    s = _pd.Series(base, index=[f"pregunta_{i}" for i in range(1, 49)])

    sumas = []
    for t, qs in PREGUNTAS_POR_TECNICO.items():
        val = float(s[[f"pregunta_{q}" for q in qs]].sum())
        sumas.append((t, val))
    sumas.sort(key=lambda x: x[1], reverse=True)
    tec_top, suma_top = sumas[0]
    suma_seg = sumas[1][1] if len(sumas) > 1 else 0.0
    margen = float(suma_top - suma_seg)

    # regla combinada
    usar_por_suma = (prob_modelo < umbral) or (margen >= margin_min)
    tecnico_final = tec_top if usar_por_suma else pred_modelo

    top_k = max(1, min(top_k, len(clases)))
    return {
        "tecnico_predicho": tecnico_final,
        "top3": list(zip(clases[:top_k].tolist(), proba[idx[:top_k]].round(4).tolist())),
        "prob_modelo": prob_modelo,
        "regla_aplicada": bool(usar_por_suma),
        "motivo": "baja_confianza" if prob_modelo < umbral else ("margen_metasuma" if margen >= margin_min else "modelo"),
        "tecnico_por_suma": tec_top,
        "suma_top": suma_top,
        "suma_segundo": suma_seg,
        "margen": margen,
    }