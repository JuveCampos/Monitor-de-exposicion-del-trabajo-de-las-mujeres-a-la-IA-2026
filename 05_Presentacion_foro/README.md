# Presentación para el foro sobre informalidad e inteligencia artificial

Intervención de diez minutos sobre la relación entre informalidad laboral y
exposición del empleo a la IA generativa en México. La pieza de contenido es
el artículo "¿Y si la IA viene primero por los trabajos con IMSS y
prestaciones?".

## Entregable

`informalidad_e_IA_foro.pptx`: 15 diapositivas en formato 4:3 (10 × 7.5
pulgadas), con notas del expositor en cada una (minutaje y guion hablado).

## Cómo se reproduce

Los cuatro scripts se corren en orden **desde la raíz del repositorio**:

```bash
Rscript 05_Presentacion_foro/codigo/01_calcula_cifras.R
Rscript 05_Presentacion_foro/codigo/02_genera_figuras.R
Rscript 05_Presentacion_foro/codigo/03_genera_treemaps.R
python3 05_Presentacion_foro/codigo/04_construye_pptx.py
```

| Script | Qué hace |
|---|---|
| `01_calcula_cifras.R` | Cruce exposición × informalidad con ENOE 1T2026. Escribe los CSV de respaldo `respaldo_0*.csv` en `figuras/` |
| `02_genera_figuras.R` | Figuras 1 a 5, en dos versiones: `fig0*.png` (con título y fuente, para documentos) y `deck_0*.png` (sin título, para el deck) |
| `03_genera_treemaps.R` | Treemaps del mercado laboral total y femenino, mismas dos versiones. Reutiliza la flexión de género de `04_Aplicación/app.R` |
| `04_construye_pptx.py` | Arma el .pptx con python-pptx |

Las figuras del deck van sin título ni pie porque en la diapositiva el
título es el de la lámina y la fuente va al pie. Las versiones `fig0*` sí
los llevan y sirven para pegarlas en un documento.

## Estructura del deck

| # | Lámina | Figura |
|---|---|---|
| 1 | Portada | |
| 2 | ¿Cuál fue tu primer empleo formal? | |
| 3 | Más de la mitad del país trabaja sin seguridad social | `deck_01` |
| 4 | Nadie está midiendo la adopción de IA en México | |
| 5 | ¿Qué significa que un trabajo esté expuesto? | |
| 6 | De dónde sale el dato (cadena metodológica) | |
| 7 | Así se ve el mercado laboral mexicano | `deck_06` |
| 8 | El mismo mapa, solo con el empleo de las mujeres | `deck_07` |
| 9 | El dato que rompe la intuición | `deck_02` |
| 10 | Y en el empleo formal, ellas son las más expuestas | `deck_03` |
| 11 | La tesis: el escalón se estrecha | `deck_04` |
| 12 | Con nombre y apellido | `deck_05` |
| 13 | En México el efecto no se verá en el desempleo | |
| 14 | Cuatro cosas que sí se pueden hacer | |
| 15 | Cierre | |

Las láminas 6 y 10 están marcadas en las notas como material de respaldo: se
pueden saltar si el tiempo va justo y sirven sobre todo para responder
preguntas sobre el método.

## Identidad visual

Paleta de México, ¿Cómo vamos?: morado #6950D8 (dominante), coral #FF6260,
verde #00B783, lila claro #F0EDFB para las tarjetas, gris #777777. Los
gradientes de exposición conservan la escala verde-rojo del Monitor para que
las gráficas se lean junto al treemap. Tipografía Helvetica Neue, que existe
en macOS y sobrevive a la conversión a Keynote.

## Verificación hecha

Conversión a PDF con LibreOffice, revisión visual de las 15 láminas,
corrector ortográfico es_MX sobre el texto extraído, búsqueda de
marcadores de texto pendiente y validación estructural del archivo. Se
corrigieron desbordamientos de texto en tarjetas, títulos cortados por el
borde, duplicación de títulos entre figura y lámina, y solapamientos de
anotaciones dentro de las gráficas.

## Advertencias sobre las cifras

Todas las cifras propias salen de ENOE 1T2026 cruzada con el catálogo SINCO
de exposición del Monitor. Se calculan con el factor de expansión como
ponderador de frecuencia, **sin declarar el diseño muestral complejo de la
ENOE**: los puntos estimados son válidos, los intervalos de confianza están
pendientes. Conviene replicarlos con `srvyr` antes de publicar.

Las cifras de informalidad (54.8 %, 29.5 %, 12.9 %, 8.7 %, 3.7 %) provienen
de la publicación de México, ¿Cómo vamos? con ENOE 1T2026, no de cálculo
propio.
