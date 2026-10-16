# Flujo completo en R, desde cero

Esta carpeta reconstruye todo el Monitor a partir de los insumos originales,
con scripts de R numerados que se corren en orden. No toca los archivos que
hoy usa la aplicación (`04_Aplicación/`); todas las salidas quedan en
`salidas/`, así que se puede correr y comparar sin riesgo.

## Qué cambia respecto al flujo original

1. **Todo en R.** Los pasos que estaban en Python (colapso de puntuaciones,
   crosswalk, capas de imputación, descripciones) ahora son scripts de R con
   tidyverse. Los de la ENOE (pasos 7 y 9) son los mismos que ya estaban
   validados contra Stata; solo cambian rutas y parámetros.
2. **Correspondencia SINCO 2019 a CIUO-08 por la vía oficial.** La única
   tabla comparativa que el INEGI ha publicado es la del SINCO 2011 (2012).
   La ENOE codifica con el SINCO 2019, que renumeró 16 grupos unitarios y
   creó 19 nuevos (anexo del documento SINCO 2019). El flujo original
   aplicaba la tabla 2011 a los códigos 2019 como si fueran iguales; ahora
   el paso 2 lee la tabla de equivalencia 2011-2019 del PDF del INEGI y el
   paso 3 la usa para asignar la CIUO correcta. El caso más visible es el
   bloque médico 2412-2438 (dentistas, especialidades médicas, enfermeras).
3. **Estructura completa del SINCO 2019.** Se toma del documento de
   clasificaciones de la ENOE (490 grupos unitarios); el jerárquico anterior
   tenía 480.
4. **Traducciones con Claude.** El paso 6 traduce con la interfaz de línea
   de comandos de Claude Code (`claude -p`), en lotes y con caché; no usa
   Gemma ni requiere clave de API. La caché (`salidas/06_traducciones_claude_cache.csv`)
   se conserva en el repositorio para que el resto del flujo sea
   determinista aunque no se vuelva a llamar al modelo.
5. **Tareas en formato de tabla.** Además del párrafo descriptivo, el paso 8
   deja `08_tareas_app.csv` con una fila por tarea evaluada (en español, con
   su puntuación), para que la app las muestre como tabla o lista.

## Pasos

| Script | Qué hace | Entrada principal | Salida |
|---|---|---|---|
| `00_configuracion.R` | Rutas, trimestre, etiquetas y utilidades | | |
| `01_puntuaciones_gmyrek.R` | Colapsa el archivo a nivel tarea de Gmyrek et al. (2025) a una fila por CIUO-08 | `Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx` | `01_gmyrek_2025_ciuo4d.csv` |
| `02_estructura_sinco_2019.R` | Lee la estructura del SINCO 2019 (PDF de clasificaciones de la ENOE) y la tabla de equivalencia 2011-2019 (PDF del SINCO 2019) | dos PDF del INEGI | `02_sinco_2019_estructura.csv`, `02_equivalencia_sinco_2019_2011.csv` |
| `03_crosswalk_sinco_ciuo.R` | Reconstruye la tabla SINCO 2011 a CIUO-08 del INEGI (con la regla de herencia dentro del subgrupo) y la traslada a códigos 2019 | `sinco_tablas_comparativas.xlsx` | `03_crosswalk_sinco2011_ciuo08.csv`, `03_crosswalk_sinco2019_ciuo08.csv` |
| `04_catalogo_exposicion.R` | Puntuación, categoría ("Mixto" si las CIUO difieren), estado e imputación por promedio del nivel superior | pasos 1 a 3 | `04_catalogo_exposicion_ia.csv` |
| `05_descripciones_en.R` | Tareas evaluadas por ocupación (formato largo) y resumen en inglés | Excel de Gmyrek, paso 4 | `05_tareas_por_ocupacion.csv`, `05_descripciones_en.csv` |
| `06_traducir_claude.R` | Traduce títulos CIUO, tareas y justificaciones con Claude (lotes, caché, reanudable) | paso 5 | `06_traducciones_claude_cache.csv`, `06_tareas_por_ocupacion_es.csv`, `06_descripciones_es.csv` |
| `07_procesar_enoe.R` | Microdatos ENOE (SDEM + COE1) a colapsos por sexo y SINCO 1d a 4d | DBF del INEGI | `enoe/zcalculos_Y{año}T0{trim}_{1d,2d,3d,4d}.dta` |
| `08_provisionales_catalogo_app.R` | Clasificaciones provisionales (mapeo manual e imputación modal) y catálogo final para la app | pasos 4, 6, 7 e `insumos/mapeo_manual_ciuo.csv` | `08_ocupaciones_provisionales.csv`, `08_catalogo_app.csv`, `08_tareas_app.csv` |
| `09_procesar_stem.R` | Población ocupada con formación STEM por sexo | DBF del INEGI | `enoe/..._stem_campos.dta`, `enoe/..._4d_stem.dta` |
| `10_verificacion.R` | Compara con los archivos vigentes y calcula las cifras de cabecera con ambos catálogos | todo lo anterior | `10_verificacion.md` |
| `99_correr_todo.R` | Encadena los pasos (`--sin-traduccion` omite el paso 6) | | |

## Cómo correrlo

Desde la raíz del repositorio o desde esta carpeta:

```
Rscript 05_Reproduccion_R/99_correr_todo.R
```

Para cambiar de trimestre se edita `anio_enoe` y `trim_enoe` en
`00_configuracion.R` (o se pasan como argumentos a los pasos 7 y 9). La ruta
del disco con los DBF se cambia ahí mismo o con la variable de entorno
`DIR_DBF_ENOE`.

Requisitos: R con tidyverse, readxl, haven, foreign, pdftools, jsonlite y
processx; Claude Code instalado y con sesión iniciada para el paso 6 (el
modelo se elige con `MODELO_CLAUDE`, por defecto `sonnet`). Si en
`~/.Renviron` hay una `ANTHROPIC_API_KEY`, el paso 6 la ignora para usar la
sesión.

## Insumos que dependen de un criterio del equipo

- `insumos/mapeo_manual_ciuo.csv`: CIUO-08 análoga propuesta para las
  ocupaciones que no tienen correspondencia oficial ni por la tabla 2011 ni
  por la equivalencia 2019. La columna `aprobado` está vacía: el paso 8 las
  usa como provisionales y lo marca en el catálogo. Incluye, además de las
  propuestas anteriores, las siete especialidades médicas nuevas en 2019
  (2422 a 2428) ligadas a la CIUO 2212, que es la correspondencia oficial
  del grupo del que se desprendieron.
- `insumos/INEGI_ENOE_clasificaciones_2023.pdf`: copia del documento del
  INEGI con la estructura del SINCO 2019 (origen en el encabezado de
  `00_configuracion.R`).

## Qué se verificó

- Paso 1 reproduce exactamente `gmyrek_2025_ciuo4d_unique.csv`.
- Paso 3 reproduce exactamente los 663 pares de `crosswalk_sinco_ciuo08_long.csv`.
- Pasos 7 y 9 reproducen exactamente los seis `.dta` de 2026-T2.
- Con el catálogo nuevo, las cifras de cabecera del Monitor no cambian
  (7.94% de las mujeres y 2.92% de los hombres en exposición significativa o
  máxima); cambian de categoría 14 ocupaciones con 142,785 personas, casi
  todas del bloque médico y de servicios de alquiler. El detalle está en
  `salidas/10_verificacion.md`.
