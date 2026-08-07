# Adenda a la nota metodológica (julio de 2026)

Este documento contiene dos textos para actualizar `notametodologica.pdf`:
la sección nueva "Clasificaciones provisionales" (se sugiere insertarla
después de "Gradientes de exposición") y el texto de reemplazo del primer
párrafo de "Herramientas técnicas y código".

---

## Clasificaciones provisionales

Tras aplicar el mapeo SINCO-CIUO-08 y las estrategias de imputación
descritas en las secciones anteriores, 73 ocupaciones del catálogo
permanecían sin gradiente de exposición asignado y se mostraban en la
aplicación como "Sin información". A ellas se sumaron cinco códigos de la
actualización del SINCO que la ENOE ya reporta y que no formaban parte del
catálogo original (INEGI, 2025). En conjunto, estas ocupaciones concentraban
alrededor de 1.5 millones de personas ocupadas en el primer trimestre de
2026 (2.5% de la población ocupada), de las cuales 709 mil eran mujeres.

En julio de 2026 se incorporó al catálogo una clasificación provisional para
68 de estas ocupaciones, construida con dos estrategias:

1. **Mapeo manual a una ocupación análoga (28 ocupaciones).** Cuando la
   tabla comparativa oficial del INEGI no ofrece una correspondencia
   directa, el equipo asignó la ocupación de la CIUO-08 cuyo contenido de
   tareas resulta más cercano y la ocupación heredó la puntuación media
   estimada por Gmyrek et al. (2025) para esa análoga. Cada
   asignación quedó documentada con su justificación en el repositorio del
   proyecto. El caso de mayor población es el de las enfermeras y
   paramédicos profesionales, que se asignaron a la ocupación 2221 de la
   CIUO-08 (profesionales de enfermería).

2. **Imputación modal jerárquica (40 ocupaciones).** Cuando tampoco existe
   una análoga evaluada, la ocupación recibió la categoría más frecuente
   entre las ocupaciones ya clasificadas de su mismo subgrupo (tres
   dígitos), con respaldo en el grupo principal (dos dígitos) y en la
   división (un dígito) cuando el nivel inferior contaba con menos de
   dos ocupaciones clasificadas. En caso de empate entre categorías se adoptó
   la de menor exposición, como criterio conservador. La puntuación
   provisional corresponde al promedio de las ocupaciones del nivel
   utilizado o, cuando ya existía, a la puntuación imputada
   jerárquicamente que se describió en la sección de mapeo.

Las 10 ocupaciones restantes no admiten imputación y conservan la categoría
"Sin información": seis corresponden a las fuerzas armadas, que el índice de
Gmyrek et al. (2025) excluye porque el corpus de tareas de la OIT no cubre
al gran grupo 0 de la CIUO-08; tres son códigos operativos de la ENOE que no
describen ocupaciones de mercado; y una agrupa a las ocupaciones no
especificadas. Tras esta actualización, la población ocupada sin
clasificación se redujo a cerca de 122 mil personas (0.2% del total).

Las clasificaciones provisionales se señalan de forma explícita en la
aplicación: la etiqueta "(provisional)" acompaña a la categoría en las
ventanas emergentes y el texto descriptivo de cada ocupación explica el
método con el que se estimó. Estas clasificaciones deben leerse como una
aproximación al perfil de exposición del grupo ocupacional y no como una
evaluación directa de las tareas específicas de cada ocupación en México.
La incorporación de las clasificaciones provisionales modifica de forma
marginal los agregados por gradiente, dado que la mayoría de estas
ocupaciones cayó en las categorías de menor exposición: la proporción de
mujeres ocupadas en los gradientes de exposición significativa y máxima se
mantiene en 7.7%.

---

## Herramientas técnicas y código (párrafo de reemplazo)

El procesamiento de los microdatos de la ENOE se realiza en R con las
librerías del tidyverse: el flujo lee las tablas SDEM y COE1 publicadas por
el INEGI, las fusiona con la llave estándar de persona, aplica los filtros
de entrevista completa y residencia habitual, y colapsa los indicadores por
sexo y código SINCO. Este flujo sustituyó en julio de 2026 al procesamiento
original en Stata y se validó contra él fila por fila con los datos del
cuarto trimestre de 2025, con resultados idénticos. Los scripts se adjuntan
en el repositorio del proyecto, dentro de la carpeta
`00_Códigos/Scripts_procesamiento_ENOE_R/`. Las visualizaciones y la
aplicación web se desarrollaron en R, utilizando las librerías Shiny y
Plotly.

---

## Referencias que se agregan

- Gmyrek, P., Berg, J., Kamiński, K., Konopczyński, F., Ładna, A.,
  Nafradi, B., Rosłaniec, K. y Troszyński, M. (2025). *Generative AI and
  jobs: A refined global index of occupational exposure* (ILO Working
  Paper 140). Organización Internacional del Trabajo.
  https://doi.org/10.54394/HETP0387
- Instituto Nacional de Estadística y Geografía (2025). *Encuesta Nacional
  de Ocupación y Empleo. Clasificaciones ENOE.*
  https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/doc/clasificaciones_enoe_123.pdf

---

## Fe de erratas sugerida para el cuerpo de la nota

La nota vigente atribuye el Working Paper 140 a "Gmyrek, Berg y Bescond
(2025)". Esa autoría corresponde al Working Paper 96 de 2023 (el índice
original). La cita oficial del WP140, tomada de la página legal del propio
documento, es: Gmyrek, P., Berg, J., Kamiński, K., Konopczyński, F.,
Ładna, A., Nafradi, B., Rosłaniec, K., Troszyński, M. (2025). *Generative
AI and Jobs: A Refined Global Index of Occupational Exposure*, ILO Working
Paper 140 (Ginebra, OIT). https://doi.org/10.54394/HETP0387. Se sugiere
corregir la mención en la sección "Metodología para estimar la exposición
a la inteligencia artificial" y en el README del repositorio.
