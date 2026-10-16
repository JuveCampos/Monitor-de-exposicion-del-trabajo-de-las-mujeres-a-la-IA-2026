# Auditoría metodológica del Monitor (15 de octubre de 2026)

Se revisó la cadena completa que sostiene las conclusiones: índice de la OIT
(Gmyrek et al., 2025), correspondencia SINCO-CIUO-08, imputaciones y
clasificaciones provisionales, procesamiento de la ENOE, indicadores
derivados (gradientes, ocupaciones de escritorio, cuidados, STEM), datos de
ENDUTIH y las afirmaciones del texto de la aplicación. Las cifras se
recalcularon con la ENOE 2026-T2.

## Veredicto

El procesamiento de la ENOE y los agregados por sexo son sólidos y
reproducen las cifras oficiales. La debilidad está en la capa de
clasificación: la correspondencia SINCO-CIUO se construyó con la tabla del
SINCO 2011 y se aplica a códigos del SINCO 2019, y la categoría "Mixto",
que es un artefacto de la correspondencia y no un nivel de exposición,
concentra al 18% de la población ocupada. Ninguno de los dos problemas
invalida las conclusiones generales, pero sí cambian cifras que la app
presenta con precisión de persona.

## Hallazgos por severidad

### 1. La correspondencia usa la tabla del SINCO 2011 aplicada a códigos del SINCO 2019 (alta)

- La tabla `sinco_tablas_comparativas.xlsx` dice en su encabezado "SINCO
  2011, actualización noviembre de 2012". La ENOE y el catálogo usan SINCO
  2019. Entre ambas versiones hay 28 códigos nuevos, 13 eliminados y 39 con
  título distinto.
- El bloque de médicos especialistas (2412 a 2428) se renumeró. Hoy el
  catálogo asigna a "Dentistas" (2412, 135 mil personas) el CIUO de médicos
  especialistas; a "Cirujanos" (2422) el de optometristas; a "Ginecólogos"
  (2423) el de nutriólogos; a "Pediatras" (2426) el de enfermeras; a
  "Psiquiatras" (2427) el de fisioterapeutas; a "Radiólogos" (2428) el de
  farmacólogos; a "Médicos internos" (2424) el de seguridad e higiene; a
  "Patólogos" (2425) el de medicina tradicional. Estas filas aparecen con
  `metodo_score = directo`, es decir, sin marca de duda.
- Impacto: unas 200 mil personas, casi todas en "No expuesto" o "Mínima",
  así que los agregados apenas cambian. Pero es un error de correspondencia
  y la nota metodológica afirma que el mapeo se hizo "a partir de la tabla
  comparativa oficial" del SINCO 2019.
- Qué hacer: usar la tabla comparativa SINCO 2019-CIUO-08 del INEGI (si
  existe publicada) o, como mínimo, revisar a mano los 39 códigos con título
  distinto y los 28 nuevos, y marcarlos como revisados.

### 2. "Mixto" no es un gradiente y esconde exposición alta (alta)

- "Mixto" se asigna cuando una ocupación SINCO corresponde a varios CIUO con
  categorías distintas. Son 56 ocupaciones con 10.8 millones de personas
  (18.0% de los ocupados), incluida la ocupación más grande del país
  (comerciantes en establecimientos, 3.1 millones) y 19.6% de las mujeres.
- En la app "Mixto" se ordena como un nivel intermedio entre "Mínima" y
  "Baja", con color amarillo, y en la imputación modal se trata como
  categoría de severidad intermedia. Ninguna de las dos cosas se sostiene:
  dentro de "Mixto" hay 7 ocupaciones con score medio entre 0.5 y 0.6
  (931 mil personas) y 2 con score de 0.6 o más (209 mil), que por media
  caerían en significativa o máxima. Ejemplos: auxiliares en contabilidad
  (2512, 406 mil, rango 0.49 a 0.64), agentes de seguros (4222, 204 mil,
  0.53 a 0.64), cajeros y taquilleros (3121, 640 mil, 0.39 a 0.58).
- Consecuencia: el total de personas en "exposición significativa y máxima"
  (3.0 millones, 7.95% de las mujeres) y los top 10 están subestimados, y
  no se sabe cuánto porque depende de la regla que se adopte.
- Qué hacer: resolver "Mixto" con una regla explícita. Opciones, de más a
  menos defendible: (a) ponderar los CIUO por empleo si se consigue una
  distribución (no la hay en ENOE); (b) tomar el CIUO "principal" de la
  tabla del INEGI (la primera fila) y usar su categoría; (c) reclasificar
  con la media y la desviación promedio aplicando la Tabla 5 del WP140. En
  cualquier caso, dejar "Mixto" como bandera de incertidumbre, no como
  nivel.

### 3. La regla de herencia del crosswalk es un supuesto propio (media)

- Cuando una ocupación SINCO de 4 dígitos no tiene CIUO en su fila, el
  parser le hereda el último CIUO visto en el mismo subgrupo. Así se
  resolvieron 35 ocupaciones; otras 26 traen "No tiene correspondencia"
  explícito y 12 quedaron vacías. La convención del INEGI de "llenar solo la
  primera fila" no está documentada en la tabla; es una lectura del equipo.
- Qué hacer: verificar contra el PDF de la tabla comparativa una muestra de
  los 35 casos y documentar la regla en la nota.

### 4. Promedio simple de CIUO múltiples (media)

- 137 ocupaciones SINCO corresponden a 2 o más CIUO (hasta 7). El score se
  promedia sin pesos, por lo que una ocupación con un CIUO masivo y uno
  marginal queda a la mitad. La nota lo declara ("se promedian"), pero no
  advierte el sesgo. Relacionado con el hallazgo 2.

### 5. Inconsistencias entre la nota metodológica y el catálogo (media)

- La nota dice "34 ocupaciones sin correspondencia directa"; el catálogo
  tiene 66 sin ningún CIUO (62 con clasificación provisional y 4 no
  imputables). Dice "436 ocupaciones" del índice; el archivo de scores de
  la OIT contiene 427 códigos CIUO con categoría. Dice "483 ocupaciones";
  el catálogo tiene 488.
- La etiqueta de Gradiente 2 en la app dice "variabilidad mixta de tareas";
  el WP140 la define como "exposición moderada, alta variabilidad".
- Qué hacer: corregir los tres números y la etiqueta.

### 6. Reproducibilidad del catálogo (media)

- `build_crosswalk.py` y `build_layered.py` leen
  `/tmp/gmyrek_2025_ciuo4d_unique.csv`, un archivo intermedio que no está
  en el repositorio ni tiene script que lo genere, y apuntan a rutas de
  `Claude Encargos/36-dataton-genero`. El catálogo no se puede regenerar
  desde el repo. El insumo original sí está (`Gmyrek_et_al_2025_Final_
  Scores_ISCO08.xlsx`, a nivel tarea).
- Qué hacer: agregar el paso que colapsa el Excel a un CIUO por fila y
  parametrizar las rutas.

### 7. Definición STEM heredada (media, ya señalada)

- Incluye economía y finanzas (campos 314 y 413) en "ciencias" y excluye a
  las ciencias de la salud. Además la variable de carrera (`cs_p14_c`)
  existe para normal, carrera técnica, licenciatura, maestría y doctorado,
  así que "formación STEM" mezcla técnicos y universitarios (la carrera
  técnica aporta cerca del 9% de quienes reportan carrera).
- Qué hacer: decidir si se quita economía y finanzas (con eso el grupo
  "Ciencias" pierde 231 mil personas, el 42% de ese campo) y si se restringe
  a licenciatura o más. Documentar lo que se decida en la nota (ya está
  explicado el criterio actual).

### 8. "Ingreso mediano ponderado" es un promedio de medianas (baja)

- El indicador por gradiente es un promedio ponderado por empleo de las
  medianas de cada ocupación, no la mediana del gradiente. La diferencia
  suele ser pequeña, pero el nombre induce a leerlo como mediana. Sugerencia:
  llamarlo "ingreso mediano típico (promedio ponderado de medianas
  ocupacionales)" en la nota, o calcular la mediana real en el script 01.

### 9. Afirmaciones del texto sin fuente o con matiz pendiente (baja)

- "El grupo expuesto es más pequeño en México que en las economías de
  ingresos altos" (Resumen ejecutivo): no cita fuente en la app. El WP140 sí
  ofrece cifras comparables por nivel de ingreso; conviene citarlas o
  quitar la frase.
- "Las mujeres usan la tecnología para cumplir necesidades prácticas de
  género" (Brecha tecnológica): dice "de acuerdo con distintos estudios" sin
  citar ninguno. Hay que citar o reescribir como lectura de la gráfica.
- "Las ocupaciones de cuidados presentan niveles bajos de exposición": se
  sostiene (6 de 8 en "No expuesto"), pero dos están en "Mixto" y
  "Auxiliares en enfermería" tiene rango 0.14 a 0.53. El texto debería
  decir "bajos o mixtos".
- Las afirmaciones centrales sí se sostienen con los datos: las mujeres
  concentran más empleo en significativa y máxima (7.95% contra 2.93% de
  los hombres), esa alta exposición coincide con mayor ingreso, mayor
  escolaridad y menor informalidad (mujeres: informalidad de 17.5% a 20%
  contra 67% en "No expuesto"), y el 83% de las mujeres en alta exposición
  están en la división de trabajadoras auxiliares administrativas.

### 10. ENDUTIH: datos correctos pero ya hay edición 2025 (baja)

- Las series 2021 a 2024 de usuarios de internet y celular por sexo
  coinciden con la presentación oficial de la ENDUTIH 2024. El INEGI ya
  publicó la ENDUTIH 2025 (boletín de 2026): mujeres 85.6% y hombres 86.6%
  en internet, brecha de 1.0 pp. La sección sigue en 2024 y el texto habla
  de "brecha 2024".
- Los datos de uso de aplicaciones están incrustados a mano en `app.R` sin
  referencia al tabulado de origen; conviene anotar el cuadro exacto.

## Lo que se verificó y se sostiene

- Procesamiento ENOE 2026-T2: 60,040,094 ocupados con código SINCO y TIL1
  de 55.1% (54.6% hombres, 55.8% mujeres), idénticos al boletín 503/26 del
  INEGI (60.0 millones, 55.1%). Filtros (r_def 00, c_res 1 y 3, 15 a 98
  años), definición de ocupación (clase1 y clase2 = 1), informalidad
  (emp_ppal = 1) y mediana ponderada replican el flujo oficial.
- Cobertura de la clasificación: 97.5% de la población ocupada tiene score
  directo, 2.3% imputado o provisional (marcado en la app) y 0.2% sin
  clasificar (fuerzas armadas, códigos operativos y no especificadas).
- La traducción de categorías y los umbrales del WP140 (Tabla 5) son
  consistentes con el índice, salvo la etiqueta del Gradiente 2.
- Composición del empleo por división (27.7% en divisiones 1 a 3) y top 10
  por sexo se calculan directamente de los datos.
- Las cifras STEM se calculan correctamente con la definición vigente.

## Orden sugerido de corrección

1. Resolver "Mixto" con una regla explícita (hallazgo 2) y revisar el
   bloque 2412 a 2428 y los 39 códigos con título distinto (hallazgo 1).
   Ambos cambian cifras publicadas y deben hacerse antes de la salida en el
   sitio de MCV.
2. Corregir la nota metodológica (hallazgo 5) y dejar reproducible el
   catálogo (hallazgo 6).
3. Decidir la definición STEM (hallazgo 7) y actualizar ENDUTIH a 2025
   (hallazgo 10).
4. Ajustar textos y citas (hallazgos 8 y 9).

## Fuentes consultadas

- Gmyrek, P. et al. (2025). Generative AI and jobs: A refined global index
  of occupational exposure. ILO Working Paper 140, Tabla 5.
- INEGI (2026). Indicadores de ocupación y empleo, segundo trimestre de
  2026. Boletín 503/26. https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2026/enoe/enoe2026_08.pdf
- INEGI (2025). Presentación de resultados ENDUTIH 2024.
  https://inegi.org.mx/contenidos/programas/endutih/2024/doc/presentacion_endutih2024.pdf
- INEGI (2026). ENDUTIH 2025, resultados.
  https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2026/endutih/ENDUTIH_25_RR.pdf
- INEGI (2012). SINCO 2011. Tablas comparativas, actualización noviembre
  de 2012 (archivo `01_Datos/01_catalogos/sinco_tablas_comparativas.xlsx`).

## Correcciones aplicadas el 15 de octubre de 2026 (sin decisiones pendientes)

- Hallazgo 3: la regla de herencia quedó documentada en la nota y en
  `build_crosswalk.py` (columna `origen` en
  `crosswalk_sinco_ciuo08_long.csv`); las 32 ocupaciones con puntuación
  heredada llevan `metodo_score = directo_heredado_3d` en los tres
  catálogos.
- Hallazgo 5: la nota ahora dice 488 ocupaciones (483 más 5), 427 CIUO-08
  evaluadas, 410 directas, 34 imputadas por promedio y 68 provisionales;
  la etiqueta del Gradiente 2 es "Exposición moderada, alta variabilidad de
  tareas" en la app, en el script 02 y en la documentación.
- Hallazgo 6: nuevo `00_colapsar_scores_gmyrek.py` genera
  `datasets/gmyrek_2025_ciuo4d_unique.csv`; `build_crosswalk.py` y
  `build_layered.py` usan rutas relativas al repo (variable `CATALOGOS_DIR`
  para pruebas) y conservan las columnas de pasos posteriores. La cadena
  completa se corrió en una copia y reprodujo celda por celda el catálogo
  vigente.
- Hallazgo 8: el indicador se llama "ingreso mediano típico" en la app y la
  nota explica que es un promedio ponderado de medianas ocupacionales.
- Hallazgo 9: la comparación con economías de ingresos altos cita el 34% del
  WP140 y la cifra propia de México (14.6% en gradientes más 18.0% en
  "Mixto"); la frase sobre "necesidades prácticas de género" se sustituyó
  por la lectura de la gráfica de aplicaciones de la ENDUTIH 2025; cuidados
  dice "bajos o mixtos".
- Hallazgo 10: ENDUTIH actualizada a 2025 (series 2022 a 2025 e
  internet/celular/aplicaciones por sexo del reporte 19/26, gráficas 3, 13 y
  16), con la fuente anotada en `app.R` y en la nota.
- Hallazgo 1: la nota ya declara que la tabla comparativa es la del SINCO
  2011 y que los códigos renumerados están en revisión. La reasignación de
  los 39 códigos sigue pendiente de validación.
- Hallazgos 2 y 7 (decisiones pendientes): anexos
  `sensibilidad_mixto_2026T2.md` y `sensibilidad_stem_2026T2.md`, generados
  por los scripts 05 y 06 de `Scripts_procesamiento_ENOE_R/`.
