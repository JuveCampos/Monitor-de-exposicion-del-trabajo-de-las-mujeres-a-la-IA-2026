# Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026

> **DAT4CCIÓN · Datatón Regional para la Igualdad 2026**
>
> Una herramienta para estimar el grado en que las ocupaciones del mercado laboral mexicano pueden ser ejecutadas o apoyadas por sistemas de IA generativa, con foco en las brechas de género, la cobertura tecnológica y la protección jurídica del trabajo.

---

## 📌 Sobre el proyecto

Este repositorio contiene los datos, scripts y la aplicación web que sustentan el **Monitor de Exposición del Trabajo de las Mujeres a la IA**, presentado en el marco del *DAT4CCIÓN, Datatón Regional para la Igualdad (2026)*. El proyecto clasifica las **483 ocupaciones del Sistema Nacional de Clasificación de Ocupaciones (SINCO 2019)** según su grado de exposición a la IA generativa, integrando información sobre brecha tecnológica de los hogares mexicanos y sobre el marco internacional de protección laboral.

| Indicador | Valor |
|---|---|
| Ocupaciones SINCO clasificadas | **483** |
| Ocupaciones CIUO-08 base | **436** |
| Validaciones humanas (corpus OIT) | **52,000+** |
| Correlación modelo–humanos | **0.92** |

---

## 🔬 Metodología

### Estimación de la exposición a la IA

La *exposición a la inteligencia artificial* se refiere al grado en que las tareas principales de una ocupación pueden ser ejecutadas o apoyadas por sistemas de IA, especialmente generativa. El concepto permite distinguir escenarios de **sustitución** y de **complementariedad** tecnológica.

La clasificación se basa en la metodología desarrollada por **Gmyrek, Berg y Bescond (2025)** para la OIT, publicada en el *Working Paper 140: Generative AI and Jobs: A Refined Global Index of Occupational Exposure*.

### Mapeo SINCO ↔ CIUO-08

El índice original evalúa 436 ocupaciones internacionales bajo CIUO-08. Para aplicarlo a México se construyó un mapeo entre el SINCO 2019 del INEGI y la CIUO-08, a partir de la tabla comparativa oficial del INEGI:

- Cuando una ocupación SINCO corresponde a múltiples códigos CIUO-08, se promedian los scores de exposición.
- Para las **34 ocupaciones sin correspondencia directa** se aplicó **imputación jerárquica** (promedio de subgrupo, grupo o división) y mapeo manual revisado por el equipo.

### Fundamento empírico

> La metodología de Gmyrek et al. combina tres fuentes de evidencia:
> 1. **Validación humana** con más de 52,000 evaluaciones de trabajadores reales sobre qué tareas de su ocupación pueden ser automatizadas o aumentadas por IA generativa.
> 2. **Deliberación de expertos internacionales** mediante el método Delphi.
> 3. **Modelos de lenguaje** entrenados sobre el corpus validado para predecir scores a escala global.
>
> La correlación entre las predicciones del modelo y las evaluaciones humanas es de **0.92**.

### Gradientes de exposición

Cada ocupación recibe una calificación continua de **0 a 1** y se clasifica en gradientes que van desde *“No expuesto”* (ocupaciones manuales y físicas con impacto mínimo de la IA) hasta *“Exposición máxima”* (ocupaciones administrativas, financieras y de comunicación con alto potencial de automatización). Las ocupaciones con correspondencias heterogéneas entre SINCO y CIUO-08 se clasifican como *“Mixto”*.

### Fuentes complementarias

- **Brecha tecnológica:** Encuesta Nacional sobre Disponibilidad y Uso de Tecnologías de la Información en los Hogares (**ENDUTIH 2024**, INEGI), usada para indicadores de acceso y uso como proxy de las capacidades tecnológicas de la población.
- **Protección jurídica:** bases de datos de derecho internacional provenientes de la OIT, la Oficina del Alto Comisionado de las Naciones Unidas para los Derechos Humanos y otros organismos.
- **Microdatos laborales:** ENOE cuarto trimestre de 2025 (INEGI).

---

## 🛠️ Herramientas técnicas

| Herramienta | Uso |
|---|---|
| **Stata** | Procesamiento de microdatos de la ENOE 2025-T4 mediante do-files reproducibles. |
| **R + Shiny + Plotly** | Aplicación web interactiva y visualizaciones del monitor. |
| **Python** | Construcción del crosswalk SINCO ↔ CIUO-08 y traducción de descripciones ocupacionales. |
| **IA generativa** | Apoyo supervisado en mapeo ocupacional y documentación auxiliar, sin sustituir la validación humana. |

---

## 📁 Estructura del repositorio

```
.
├── 00_Códigos/
│   └── Scripts_procesamiento_ENOE/        # Do-files de Stata para ENOE 2025-T4
│       ├── script_enoe_ccs_ocup_SINCO.do
│       ├── script_enoe_ccs_ocup_SINCO_cuidados.do
│       └── script_enoe_ccs_ocup_SINCO_stem.do
│
├── 01_Datos/
│   ├── 01_catalogos/                      # Catálogos, crosswalks e índices base
│   │   ├── sinco_con_exposicion_ia.csv    # ⭐ Catálogo SINCO con scores de exposición
│   │   ├── crosswalk_sinco_ciuo08_long.csv
│   │   ├── sinco_2019_jerarquico.csv
│   │   ├── sinco_descripciones_es.csv / _en.csv
│   │   ├── mapeo_manual_propuesto.csv
│   │   ├── INEGI_Tabla_Comparativa_SINCO_CIUO08.pdf
│   │   ├── datasets/                      # Insumos Gmyrek et al. (2025) y WB LAC
│   │   ├── papers/                        # ILO WP140, WP121, WP96
│   │   └── scripts/                       # Python: crosswalk y descripciones
│   └── 02_sinco/                          # SINCO 2019 oficial
│
├── 03_Archivos/
│   └── Bibliografía/                      # Referencias (OCDE, etc.)
│
├── 04_Aplicación/                         # Aplicación Shiny
│   ├── app.R                              # ⭐ Punto de entrada de la app
│   ├── proyecto_dashboard.Rproj
│   ├── catalogos_sinco/                   # Insumos cargados por la app
│   ├── assets/ · www/                     # Imágenes, logos, marco jurídico
│   ├── zcalculos_Y2025T04_4d.dta          # Resultados ENOE procesados
│   └── rsconnect/                         # Despliegue en shinyapps.io
│
├── notametodologica.pdf                   # Nota metodológica completa
├── README.md
└── README.html
```

---

## 🚀 Aplicación web

La aplicación interactiva está construida en **R Shiny** con visualizaciones en **Plotly** y publicada en `shinyapps.io` bajo el slug `dataton_genero_2026_exposicion_ia_trabajos`.

Para ejecutarla localmente:

```r
# Desde R / RStudio
setwd("04_Aplicación")
shiny::runApp("app.R")
```

---

## 📚 Insumos clave

- `SINCO 2019` — Sistema Nacional de Clasificación de Ocupaciones (INEGI).
- `CIUO-08` — Clasificación Internacional Uniforme de Ocupaciones.
- `ENOE 2025-T4` — Encuesta Nacional de Ocupación y Empleo.
- `ENDUTIH 2024` — Disponibilidad y uso de TIC en hogares.
- `ILO WP140` — Gmyrek, Berg & Bescond (2025), *Refined Global Index of Occupational Exposure*.
- `ILO WP121` — *Buffer or Bottleneck* — América Latina y el Caribe (2024).
- `ILO WP96` — *GenAI and Jobs — Global Analysis* (2023).

---

## ♻️ Reproducibilidad

Todo el flujo —desde el procesamiento de microdatos en Stata, la construcción del crosswalk en Python, hasta la aplicación Shiny en R— está versionado en este repositorio. Las herramientas de IA generativa se utilizaron como apoyo supervisado en tareas acotadas (mapeo ocupacional y documentación auxiliar) sin reemplazar la validación humana, sirviendo como aceleración metodológica frente a la restricción de tiempo del datatón.

---

## 📄 Documento metodológico

La nota metodológica completa se encuentra en [`notametodologica.pdf`](./notametodologica.pdf) e incluye los detalles sobre construcción del índice, mapeo SINCO–CIUO-08, fuentes complementarias y herramientas técnicas utilizadas.

---

<sub>Repositorio: [JuveCampos/Monitor-de-exposicion-del-trabajo-de-las-mujeres-a-la-IA-2026](https://github.com/JuveCampos/Monitor-de-exposicion-del-trabajo-de-las-mujeres-a-la-IA-2026) · Presentado en el **DAT4CCIÓN · Datatón Regional para la Igualdad 2026**.</sub>
