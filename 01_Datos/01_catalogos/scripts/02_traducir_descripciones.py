"""
Paso 2: Traducir descripciones de exposición IA al español usando Gemma4
vía la API de Ollama.

Procesa en lotes con requests concurrentes para acelerar.
Guarda progreso incremental para poder reanudar si se interrumpe.

Input:  sinco_descripciones_en.csv
Output: sinco_descripciones_es.csv
"""

import csv
import json
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
INPUT = BASE / "sinco_descripciones_en.csv"
OUTPUT = BASE / "sinco_descripciones_es.csv"
PROGRESS = BASE / "sinco_descripciones_es_progress.json"

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "gemma4:e4b"
MAX_WORKERS = 2  # Ollama maneja concurrencia limitada en local

PROMPT_TEMPLATE = (
    "Traduce el siguiente texto técnico al español de forma precisa. "
    "Mantén los números, scores y nombres de tareas entre comillas. "
    "Devuelve SOLO la traducción, sin comentarios ni explicaciones.\n\n"
    "Texto:\n{text}"
)


def traducir(text):
    """Traduce un texto usando la API de Ollama."""
    payload = json.dumps({
        "model": MODEL,
        "prompt": PROMPT_TEMPLATE.format(text=text),
        "stream": False,
        "options": {
            "temperature": 0.1,
            "num_predict": 2048
        }
    }).encode("utf-8")

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            return result.get("response", "").strip()
    except Exception as e:
        return f"ERROR: {e}"


def cargar_progreso():
    """Carga traducciones ya completadas."""
    if PROGRESS.exists():
        with open(PROGRESS, encoding="utf-8") as f:
            return json.load(f)
    return {}


def guardar_progreso(progreso):
    """Guarda progreso incremental."""
    with open(PROGRESS, "w", encoding="utf-8") as f:
        json.dump(progreso, f, ensure_ascii=False, indent=2)


def main():
    # Leer input
    rows = []
    with open(INPUT, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)

    total = len(rows)
    con_texto = [r for r in rows if r["descripcion_en"].strip()]
    sin_texto = [r for r in rows if not r["descripcion_en"].strip()]

    print(f"Total ocupaciones: {total}")
    print(f"  Con descripción a traducir: {len(con_texto)}")
    print(f"  Sin descripción (se omiten): {len(sin_texto)}")

    # Cargar progreso previo
    progreso = cargar_progreso()
    ya_traducidas = len(progreso)
    pendientes = [
        r for r in con_texto
        if r["unitario_4d"] not in progreso
    ]

    if ya_traducidas > 0:
        print(f"  Ya traducidas (progreso previo): {ya_traducidas}")

    print(f"  Pendientes: {len(pendientes)}")

    if not pendientes:
        print("Nada que traducir. Generando CSV final...")
    else:
        # Estimar tiempo
        est_min = (len(pendientes) * 50) / 60 / MAX_WORKERS
        print(f"\nEstimación: ~{est_min:.0f} minutos "
              f"({MAX_WORKERS} workers, ~50s/traducción)")
        print("Iniciando traducciones...\n")

        completadas = ya_traducidas
        t0 = time.time()

        # Procesar con ThreadPoolExecutor
        def procesar(row):
            sinco_4d = row["unitario_4d"]
            texto_en = row["descripcion_en"]
            traduccion = traducir(texto_en)
            return sinco_4d, traduccion

        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            futures = {
                executor.submit(procesar, r): r
                for r in pendientes
            }

            for future in as_completed(futures):
                sinco_4d, traduccion = future.result()
                progreso[sinco_4d] = traduccion
                completadas += 1

                # Progreso cada 10
                if completadas % 10 == 0 or completadas == total:
                    elapsed = time.time() - t0
                    rate = (completadas - ya_traducidas) / elapsed
                    restantes = len(con_texto) - completadas
                    eta_min = (restantes / rate / 60) if rate > 0 else 0
                    print(
                        f"  [{completadas}/{len(con_texto)}] "
                        f"{elapsed/60:.1f}min transcurridos, "
                        f"ETA ~{eta_min:.0f}min"
                    )

                # Guardar progreso cada 20 traducciones
                if completadas % 20 == 0:
                    guardar_progreso(progreso)

        # Guardar progreso final
        guardar_progreso(progreso)
        elapsed = time.time() - t0
        print(f"\nTraducción completada en {elapsed/60:.1f} minutos")

    # --- Generar CSV final ---
    print(f"\nGenerando {OUTPUT.name}...")
    output_rows = []
    for row in rows:
        sinco_4d = row["unitario_4d"]
        output_rows.append({
            "unitario_4d": sinco_4d,
            "unitario_titulo": row["unitario_titulo"],
            "descripcion_en": row["descripcion_en"],
            "descripcion_es": progreso.get(sinco_4d, ""),
            "n_tareas": row["n_tareas"]
        })

    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["unitario_4d", "unitario_titulo",
                         "descripcion_en", "descripcion_es", "n_tareas"]
        )
        writer.writeheader()
        writer.writerows(output_rows)

    con_trad = sum(1 for r in output_rows if r["descripcion_es"])
    print(f"  {con_trad} ocupaciones con traducción")
    print("Listo.")


if __name__ == "__main__":
    main()
