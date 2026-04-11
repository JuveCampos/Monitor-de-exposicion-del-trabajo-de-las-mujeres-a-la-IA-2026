"""
Paso 1: Agregar descripciones de exposición IA por ocupación SINCO.

Lee el Excel de Gmyrek et al. (2025) con justificaciones a nivel tarea,
cruza con el catálogo SINCO vía códigos CIUO-08, y genera un resumen
en inglés por cada ocupación SINCO.

Output: sinco_descripciones_en.csv
"""

import csv
import openpyxl
from collections import defaultdict
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
GMYREK = BASE / "datasets" / "Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx"
SINCO = BASE / "sinco_con_exposicion_ia.csv"
OUTPUT = BASE / "sinco_descripciones_en.csv"

# --- 1. Leer tareas de Gmyrek agrupadas por ISCO-08 ---
print("Leyendo Gmyrek Excel...")
wb = openpyxl.load_workbook(GMYREK, read_only=True)
ws = wb["Sheet1"]

# Estructura: isco_code -> list of (task, score, justification)
tareas_por_isco = defaultdict(list)

for i, row in enumerate(ws.iter_rows(min_row=2, values_only=True)):
    isco_code = str(row[2]).strip()       # ISCO_08
    isco_title = str(row[3]).strip()      # Title
    task_name = str(row[5]).strip()       # Task_ISCO
    score = row[13]                        # score_2025
    justif = str(row[9] or "").strip()    # prediction_justification_gpt4o

    if score is None:
        continue

    tareas_por_isco[isco_code].append({
        "title": isco_title,
        "task": task_name,
        "score": float(score),
        "justification": justif
    })

wb.close()
print(f"  {len(tareas_por_isco)} códigos ISCO-08 con tareas")
print(f"  {sum(len(v) for v in tareas_por_isco.values())} tareas totales")

# --- 2. Leer catálogo SINCO ---
print("Leyendo catálogo SINCO...")
sinco_rows = []
with open(SINCO, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        sinco_rows.append(row)

print(f"  {len(sinco_rows)} ocupaciones SINCO")

# --- 3. Cruzar y generar resúmenes ---
print("Generando resúmenes por ocupación SINCO...")

resultados = []
con_descripcion = 0
sin_descripcion = 0

for sinco in sinco_rows:
    sinco_4d = sinco["unitario_4d"]
    sinco_titulo = sinco["unitario_titulo"]
    ciuo_raw = sinco["ciuo08_4d_correspondientes"].strip()
    score_ia = sinco["mean_score_ia_2025"]
    potencial = sinco["potencial_ia_2025"]

    # Si no tiene CIUO correspondiente, no hay descripción
    if not ciuo_raw:
        resultados.append({
            "unitario_4d": sinco_4d,
            "unitario_titulo": sinco_titulo,
            "descripcion_en": "",
            "n_tareas": 0
        })
        sin_descripcion += 1
        continue

    # Obtener códigos CIUO (pueden ser varios separados por ;)
    ciuo_codes = [c.strip() for c in ciuo_raw.split(";")]

    # Recopilar todas las tareas de los CIUO correspondientes
    todas_tareas = []
    for code in ciuo_codes:
        if code in tareas_por_isco:
            todas_tareas.extend(tareas_por_isco[code])

    if not todas_tareas:
        resultados.append({
            "unitario_4d": sinco_4d,
            "unitario_titulo": sinco_titulo,
            "descripcion_en": "",
            "n_tareas": 0
        })
        sin_descripcion += 1
        continue

    # Ordenar por score descendente
    todas_tareas.sort(key=lambda x: x["score"], reverse=True)

    # Construir resumen:
    # - Justificación de la tarea con mayor score (la más representativa)
    # - Lista compacta de todas las tareas con su score
    top_task = todas_tareas[0]
    n_tareas = len(todas_tareas)

    # Lista de tareas con scores
    task_list = "; ".join(
        f"{t['task'][:80]} ({t['score']:.2f})"
        for t in todas_tareas
    )

    # ISCO titles involucrados
    isco_titles = list({t["title"] for t in todas_tareas})
    isco_titles_str = "; ".join(isco_titles)

    # Texto combinado
    descripcion = (
        f"ISCO-08 occupation(s): {isco_titles_str}. "
        f"This occupation has {n_tareas} evaluated tasks. "
        f"Most exposed task: \"{top_task['task']}\" "
        f"(score {top_task['score']:.2f}). "
        f"{top_task['justification']} "
        f"All tasks with scores: {task_list}."
    )

    resultados.append({
        "unitario_4d": sinco_4d,
        "unitario_titulo": sinco_titulo,
        "descripcion_en": descripcion,
        "n_tareas": n_tareas
    })
    con_descripcion += 1

# --- 4. Escribir CSV intermedio ---
print(f"Escribiendo {OUTPUT.name}...")
print(f"  Con descripción: {con_descripcion}")
print(f"  Sin descripción: {sin_descripcion}")

with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=["unitario_4d", "unitario_titulo",
                     "descripcion_en", "n_tareas"]
    )
    writer.writeheader()
    writer.writerows(resultados)

print("Listo.")
