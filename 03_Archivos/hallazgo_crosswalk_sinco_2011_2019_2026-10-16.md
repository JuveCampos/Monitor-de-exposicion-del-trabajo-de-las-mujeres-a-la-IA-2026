# Hallazgo: el crosswalk aplicaba la tabla SINCO 2011 a códigos SINCO 2019

Fecha: 16 de octubre de 2026. Origen: revisión del catálogo de correspondencia
mientras se reconstruía el flujo en R (`05_Reproduccion_R/`). Resuelve el
pendiente "validar el bloque SINCO 2412-2428".

## Qué pasaba

La única tabla comparativa SINCO a CIUO-08 que el INEGI ha publicado es la
del SINCO 2011 (actualización de noviembre de 2012). La ENOE codifica las
ocupaciones con el SINCO 2019. Entre una versión y otra el INEGI renumeró
16 grupos unitarios y creó 19 nuevos (anexo "Tabla de equivalencia SINCO
2011 - 2019" del documento SINCO 2019, pp. 357 a 396). El flujo original
cruzaba el código 2019 contra la tabla 2011 como si fueran el mismo
clasificador, de modo que:

- Los 16 grupos renumerados recibían la CIUO de otra ocupación o ninguna.
- Siete grupos nuevos de 2019 (especialidades médicas 2422 a 2428) heredaban
  la CIUO del código 2011 que ocupaba ese número (optometristas, nutriólogos,
  enfermeras, etc.).

El caso más visible es el bloque de salud: los dentistas (2412 en 2019)
recibían la CIUO 2212 "Médicos especialistas" porque en 2011 el 2412 eran los
médicos especialistas; y las enfermeras profesionales (2436 en 2019, 2426 en
2011) quedaban "sin correspondencia" aunque la tabla 2011 las liga a la CIUO
2221 "Profesionales de enfermería". Las propuestas manuales que se habían
hecho para ese bloque coincidían con la correspondencia oficial, lo que
limita el daño en las cifras.

## Grupos renumerados (ENOE 2026-T2)

| SINCO 2019 | Ocupación | SINCO 2011 | CIUO que usaba el flujo | CIUO oficial vía 2011 | Ocupados | Mujeres |
|---|---|---|---|---|---:|---:|
| 2136 | Economistas, consultores e investigadores en polít | 2123 | (ninguna) | 2631 | 6,885 | 5,240 |
| 2399 | Otros profesores y especialistas en docencia, no c | 2391 | (ninguna) | (ninguna) | 5,051 | 4,627 |
| 2412 | Dentistas | 2413 | 2212 | 2261 | 135,493 | 77,126 |
| 2421 | Anestesiólogos | 2412 | (ninguna) | 2212 | 7,464 | 3,959 |
| 2429 | Otros médicos especialistas | 2412 | (ninguna) | 2212 | 50,429 | 27,038 |
| 2431 | Ingenieros biomédicos | 2421 | (ninguna) | (ninguna) | 5,322 | 854 |
| 2432 | Optometristas | 2422 | (ninguna) | 2267 | 10,828 | 5,914 |
| 2433 | Nutriólogos | 2423 | (ninguna) | 2265 | 33,296 | 23,539 |
| 2434 | Profesionistas en seguridad e higiene y salud públ | 2424 | (ninguna) | 2263 | 7,536 | 2,984 |
| 2435 | Profesionistas en medicina tradicional y alternati | 2425 | (ninguna) | 2230 | 1,817 | 930 |
| 2436 | Enfermeras y paramédicos profesionales | 2426 | (ninguna) | 2221 | 403,251 | 317,102 |
| 2437 | Fisioterapeutas y logopedas | 2427 | (ninguna) | 2264;2266 | 68,547 | 44,462 |
| 2438 | Farmacólogos | 2428 | (ninguna) | 2262 | 13,544 | 6,657 |
| 4301 | Supervisores en servicios de alquiler | 4201 | (ninguna) | 5222 | 1,854 | 0 |
| 7518 | Trabajadores en la elaboración de productos a base | 7515 | (ninguna) | 7512;7516 | 0 | 0 |
| 9664 | Recolección de otros materiales | 9663 | (ninguna) | 9622 | 4,700 | 2,927 |

TOTAL ocupados en renumerados: 756,017 | mujeres: 523,359 

## Grupos nuevos en 2019 que heredaban una CIUO ajena

| SINCO 2019 | Ocupación | CIUO que usaba el flujo | Qué era en 2011 | Ocupados | Mujeres |
|---|---|---|---|---:|---:|
| 2422 | Cirujanos | 2267 Optometristas | 2422 Optometristas | 15,884 | 4,734 |
| 2423 | Ginecólogos y obstetras | 2265 Dietistas y nutricionistas | 2423 Nutriólogos | 5,957 | 652 |
| 2424 | Médicos internos | 2263 Salud y seguridad ocupacional | 2424 Seguridad e higiene | 13,532 | 6,064 |
| 2425 | Patólogos | 2230 Medicina tradicional | 2425 Medicina tradicional | 1,003 | 197 |
| 2426 | Pediatras | 2221 Profesionales de enfermería | 2426 Enfermeras especialistas | 7,965 | 4,964 |
| 2427 | Psiquiatras | 2264;2266 Fisioterapeutas y audiólogos | 2427 Fisioterapeutas | 4,552 | 3,032 |
| 2428 | Radiólogos | 2262 Farmacéuticos | 2428 Farmacólogos | 10,434 | 4,748 |

Para estos siete grupos no hay correspondencia oficial. El flujo nuevo los
deja como propuesta manual con la CIUO 2212 (Médicos especialistas), que es
la correspondencia oficial del grupo 2011 del que se desprendieron, marcados
como clasificación provisional hasta que el equipo los apruebe.

## Cómo se corrigió

En `05_Reproduccion_R/02_estructura_sinco_2019.R` se lee la tabla de
equivalencia 2011-2019 del PDF del INEGI y en `03_crosswalk_sinco_ciuo.R` se
usa para asignar a cada código 2019 la CIUO de su equivalente 2011. Además
se tomó la estructura completa del SINCO 2019 (490 grupos unitarios) del
documento de clasificaciones de la ENOE; el jerárquico anterior tenía 480.

## Efecto en las cifras del Monitor (ENOE 2026-T2)

Las cifras de cabecera no cambian: 7.94% de las mujeres y 2.92% de los
hombres ocupados siguen en exposición significativa o máxima, porque el
bloque de salud cae en "No expuesto" o "Exposición mínima" con una u otra
CIUO. Cambian de categoría 14 ocupaciones con 142,785 personas ocupadas
(67,603 mujeres); el detalle está en
`05_Reproduccion_R/salidas/10_verificacion.md`. Lo que sí cambia es la
trazabilidad: 756,017 personas (523,359 mujeres) pasan de una CIUO equivocada
o inexistente a la correspondencia oficial, y de las 29 propuestas manuales
anteriores, nueve dejan de ser necesarias.

## Qué queda por decidir

1. Adoptar el catálogo nuevo en la app (implica actualizar la nota
   metodológica y el README).
2. Aprobar o cambiar la propuesta de CIUO 2212 para las especialidades
   médicas 2422 a 2428.
3. Mantener la regla actual para "Mixto" o adoptar la R2 del anexo de
   sensibilidad; la decisión es independiente de este hallazgo.

## Referencias

INEGI. (2012). *Sistema Nacional de Clasificación de Ocupaciones (SINCO),
2011. Tablas comparativas. Actualización noviembre de 2012* [archivo de
Excel]. Instituto Nacional de Estadística y Geografía.

INEGI. (2019). *Sistema Nacional de Clasificación de Ocupaciones 2019.
SINCO*. Instituto Nacional de Estadística y Geografía.
https://www.snieg.mx/Documentos/Normatividad/Vigente/SINCO_2019.pdf

INEGI. (2023). *Encuesta Nacional de Ocupación y Empleo. ENOE.
Clasificaciones*. Instituto Nacional de Estadística y Geografía.
https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/doc/clasificaciones_enoe_123.pdf
