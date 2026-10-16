#!/usr/bin/env python3
"""
Paso 0: colapsar el archivo de puntuaciones de Gmyrek et al. (2025), que
viene a nivel tarea, a una fila por ocupación CIUO-08 de 4 dígitos.

Entrada:  datasets/Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx (hoja Sheet1)
Salida:   datasets/gmyrek_2025_ciuo4d_unique.csv

Las columnas mean_score_2025, SD_2025 y potential25 (y sus equivalentes de
2023) ya vienen repetidas en cada tarea de la ocupación; aquí sólo se toma
la primera aparición de cada código y se verifica que no haya valores
contradictorios dentro de una misma ocupación.

Uso: python3 00_colapsar_scores_gmyrek.py
     (la carpeta de catálogos se puede cambiar con la variable de entorno
     CATALOGOS_DIR; por defecto es la carpeta padre de este script)
"""
import csv
import os
from pathlib import Path

import openpyxl

BASE = Path(os.environ.get(
    "CATALOGOS_DIR", Path(__file__).resolve().parent.parent
))
ENTRADA = BASE / "datasets" / "Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx"
SALIDA = BASE / "datasets" / "gmyrek_2025_ciuo4d_unique.csv"

COLUMNAS = ["ISCO_08", "Title", "mean_score_2023", "mean_score_2025",
            "SD_2023", "SD_2025", "potential25", "potential23", "n_tareas"]

wb = openpyxl.load_workbook(ENTRADA, read_only=True, data_only=True)
ws = wb["Sheet1"]
filas = ws.iter_rows(values_only=True)
encabezado = [str(c).strip() if c is not None else "" for c in next(filas)]
idx = {nombre: encabezado.index(nombre) for nombre in COLUMNAS[:-1]}

ocupaciones = {}
contradicciones = 0
for fila in filas:
    codigo = fila[idx["ISCO_08"]]
    if codigo is None:
        continue
    codigo = str(codigo).strip().zfill(4)
    registro = {c: fila[idx[c]] for c in COLUMNAS[:-1]}
    registro["ISCO_08"] = codigo
    if codigo not in ocupaciones:
        registro["n_tareas"] = 1
        ocupaciones[codigo] = registro
        continue
    ocupaciones[codigo]["n_tareas"] += 1
    previo = ocupaciones[codigo]
    for c in ("mean_score_2025", "SD_2025", "potential25"):
        if previo[c] != registro[c]:
            contradicciones += 1
wb.close()

def _fmt(v):
    if v is None:
        return ""
    if isinstance(v, float):
        return f"{v:.4f}".rstrip("0").rstrip(".") if v != int(v) else str(int(v))
    return str(v)

with open(SALIDA, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=COLUMNAS)
    w.writeheader()
    for codigo in sorted(ocupaciones):
        w.writerow({c: _fmt(v) for c, v in ocupaciones[codigo].items()})

con_cat = sum(1 for r in ocupaciones.values() if r["potential25"])
print(f"Ocupaciones CIUO-08 4d: {len(ocupaciones)} "
      f"(con categoría 2025: {con_cat}; contradicciones internas: "
      f"{contradicciones})")
print("Escrito:", SALIDA)
