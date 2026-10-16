# Sensibilidad de la categoría "Mixto" (ENOE 2026T2)

Generado con `00_Códigos/Scripts_procesamiento_ENOE_R/05_sensibilidad_mixto.R`.
Las reglas R1 y R2 se aplican a todas las ocupaciones con dos o más códigos
CIUO-08; las ocupaciones con un solo código y las clasificaciones
provisionales no cambian.

- R0 actual: promedio simple de las puntuaciones y etiqueta "Mixto" cuando
  las categorías de los CIUO difieren.
- R1 primer CIUO: categoría del primer código CIUO de la tabla del INEGI.
- R2 unión de tareas: media y desviación estándar de todas las tareas de los
  CIUO de la ocupación, clasificadas con la Tabla 5 del WP140.

Validación de la Tabla 5: la regla reproduce la categoría publicada por la OIT en 423 de 427 ocupaciones CIUO-08.

## Ocupaciones con dos o más CIUO

- Ocupaciones con dos o más CIUO: 136.
- De ellas, "Mixto": 53 (10,727,876 personas ocupadas).
- Cambian de categoría con R1: 53 ocupaciones; con R2: 53.

## Población en exposición significativa y máxima por sexo

| Regla | Sexo | Personas | Porcentaje del sexo |
|---|---|---|---|
| R0 actual | Hombres | 1,031,910 | 2.92% |
| R0 actual | Mujeres | 1,961,599 | 7.94% |
| R1 primer CIUO | Hombres | 1,772,551 | 5.02% |
| R1 primer CIUO | Mujeres | 3,062,786 | 12.40% |
| R2 unión de tareas | Hombres | 1,678,470 | 4.75% |
| R2 unión de tareas | Mujeres | 2,454,949 | 9.94% |

## Distribución por categoría y sexo

| Regla | Sexo | Categoría | Personas | Porcentaje |
|---|---|---|---|---|
| R0 actual | Hombres | No expuesto | 21,292,192 | 60.25% |
| R0 actual | Hombres | Exposición mínima |  4,542,201 | 12.85% |
| R0 actual | Hombres | Mixto |  5,953,642 | 16.85% |
| R0 actual | Hombres | Exposición baja, alta variabilidad de tareas |  1,941,992 | 5.50% |
| R0 actual | Hombres | Exposición moderada, alta variabilidad de tareas |    476,451 | 1.35% |
| R0 actual | Hombres | Exposición significativa, alta variabilidad de tareas |    433,048 | 1.23% |
| R0 actual | Hombres | Exposición máxima, baja variabilidad de tareas |    598,862 | 1.69% |
| R0 actual | Hombres | NA |     99,928 | 0.28% |
| R0 actual | Mujeres | No expuesto | 12,149,446 | 49.18% |
| R0 actual | Mujeres | Exposición mínima |  2,415,653 | 9.78% |
| R0 actual | Mujeres | Mixto |  4,824,969 | 19.53% |
| R0 actual | Mujeres | Exposición baja, alta variabilidad de tareas |  2,666,494 | 10.79% |
| R0 actual | Mujeres | Exposición moderada, alta variabilidad de tareas |    659,037 | 2.67% |
| R0 actual | Mujeres | Exposición significativa, alta variabilidad de tareas |  1,053,109 | 4.26% |
| R0 actual | Mujeres | Exposición máxima, baja variabilidad de tareas |    908,490 | 3.68% |
| R0 actual | Mujeres | NA |     24,580 | 0.10% |
| R1 primer CIUO | Hombres | No expuesto | 22,956,554 | 64.96% |
| R1 primer CIUO | Hombres | Exposición mínima |  5,673,488 | 16.05% |
| R1 primer CIUO | Hombres | Mixto |     36,497 | 0.10% |
| R1 primer CIUO | Hombres | Exposición baja, alta variabilidad de tareas |  2,188,569 | 6.19% |
| R1 primer CIUO | Hombres | Exposición moderada, alta variabilidad de tareas |  2,610,729 | 7.39% |
| R1 primer CIUO | Hombres | Exposición significativa, alta variabilidad de tareas |  1,017,668 | 2.88% |
| R1 primer CIUO | Hombres | Exposición máxima, baja variabilidad de tareas |    754,883 | 2.14% |
| R1 primer CIUO | Hombres | NA |     99,928 | 0.28% |
| R1 primer CIUO | Mujeres | No expuesto | 12,461,248 | 50.45% |
| R1 primer CIUO | Mujeres | Exposición mínima |  3,204,708 | 12.97% |
| R1 primer CIUO | Mujeres | Mixto |     14,238 | 0.06% |
| R1 primer CIUO | Mujeres | Exposición baja, alta variabilidad de tareas |  2,836,602 | 11.48% |
| R1 primer CIUO | Mujeres | Exposición moderada, alta variabilidad de tareas |  3,097,616 | 12.54% |
| R1 primer CIUO | Mujeres | Exposición significativa, alta variabilidad de tareas |  1,898,521 | 7.69% |
| R1 primer CIUO | Mujeres | Exposición máxima, baja variabilidad de tareas |  1,164,265 | 4.71% |
| R1 primer CIUO | Mujeres | NA |     24,580 | 0.10% |
| R2 unión de tareas | Hombres | No expuesto | 21,537,694 | 60.95% |
| R2 unión de tareas | Hombres | Exposición mínima |  6,932,061 | 19.62% |
| R2 unión de tareas | Hombres | Mixto |     36,497 | 0.10% |
| R2 unión de tareas | Hombres | Exposición baja, alta variabilidad de tareas |  3,617,049 | 10.24% |
| R2 unión de tareas | Hombres | Exposición moderada, alta variabilidad de tareas |  1,436,617 | 4.07% |
| R2 unión de tareas | Hombres | Exposición significativa, alta variabilidad de tareas |  1,040,946 | 2.95% |
| R2 unión de tareas | Hombres | Exposición máxima, baja variabilidad de tareas |    637,524 | 1.80% |
| R2 unión de tareas | Hombres | NA |     99,928 | 0.28% |
| R2 unión de tareas | Mujeres | No expuesto | 12,369,240 | 50.07% |
| R2 unión de tareas | Mujeres | Exposición mínima |  2,887,690 | 11.69% |
| R2 unión de tareas | Mujeres | Mixto |     14,238 | 0.06% |
| R2 unión de tareas | Mujeres | Exposición baja, alta variabilidad de tareas |  5,091,823 | 20.61% |
| R2 unión de tareas | Mujeres | Exposición moderada, alta variabilidad de tareas |  1,859,258 | 7.53% |
| R2 unión de tareas | Mujeres | Exposición significativa, alta variabilidad de tareas |  1,516,485 | 6.14% |
| R2 unión de tareas | Mujeres | Exposición máxima, baja variabilidad de tareas |    938,464 | 3.80% |
| R2 unión de tareas | Mujeres | NA |     24,580 | 0.10% |

## Qué pasa con cada ocupación "Mixto"

Ordenadas por población ocupada total. Las columnas R1 y R2 muestran la
categoría que recibiría la ocupación bajo cada regla.

| SINCO | Ocupación | N CIUO | Score medio | Rango | R1 | R2 (mu, sigma) | Mujeres | Hombres |
|---|---|---|---|---|---|---|---|---|
| 4111 | Comerciantes en establecimientos | 2 | 0.39 | 0.35 a 0.43 | Exposición moderada, alta variabilidad de tareas | Exposición baja, alta variabilidad de tareas (0.39, 0.14) | 1,815,864 | 1,245,114 |
| 8342 | Conductores de autobuses, camiones, camionetas, taxis y a... | 2 | 0.23 | 0.18 a 0.28 | No expuesto | Exposición mínima (0.23, 0.18) |    50,892 | 1,354,707 |
| 3132 | Trabajadores en control de almacén y bodega | 2 | 0.405 | 0.37 a 0.44 | Exposición mínima | Exposición mínima (0.40, 0.07) |   156,072 |   522,171 |
| 3121 | Cajeros, taquilleros, receptores de apuestas y similares | 3 | 0.4733 | 0.39 a 0.58 | Exposición significativa, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.47, 0.16) |   489,024 |   151,444 |
| 9512 | Vendedores ambulantes de artículos diversos (excluyendo l... | 2 | 0.33 | 0.2 a 0.46 | Exposición moderada, alta variabilidad de tareas | Exposición baja, alta variabilidad de tareas (0.35, 0.20) |   365,844 |   274,415 |
| 2511 | Auxiliares en administración, mercadotecnia, comercializa... | 2 | 0.465 | 0.39 a 0.54 | Exposición mínima | Exposición moderada, alta variabilidad de tareas (0.46, 0.13) |   310,171 |   227,882 |
| 2512 | Auxiliares en contabilidad, finanzas y agentes de bolsa | 5 | 0.596 | 0.49 a 0.64 | Exposición máxima, baja variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.59, 0.09) |   250,812 |   155,077 |
| 2271 | Desarrolladores y analistas de software y multimedia | 5 | 0.548 | 0.49 a 0.6 | Exposición moderada, alta variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.54, 0.09) |    59,573 |   311,008 |
| 4221 | Agentes y representantes de ventas y consignatarios | 4 | 0.485 | 0.44 a 0.51 | Exposición significativa, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.49, 0.09) |   122,267 |   193,847 |
| 1511 | Coordinadores y jefes de área en administración, recursos... | 2 | 0.36 | 0.36 a 0.36 | Exposición mínima | Exposición mínima (0.36, 0.04) |    99,380 |   149,063 |
| 4222 | Agentes de seguros y servicios financieros (ejecutivos de... | 3 | 0.6 | 0.53 a 0.64 | Exposición significativa, alta variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.59, 0.09) |   110,462 |    93,819 |
| 2821 | Auxiliares en enfermería y paramédicos | 7 | 0.32 | 0.14 a 0.53 | No expuesto | Exposición baja, alta variabilidad de tareas (0.32, 0.19) |   118,157 |    45,419 |
| 2111 | Administradores y profesionistas en recursos humanos y si... | 4 | 0.435 | 0.41 a 0.46 | Exposición moderada, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.43, 0.08) |    86,221 |    77,271 |
| 4212 | Anaqueleros, acomodadores y seleccionadores de mercancías... | 3 | 0.3233 | 0.24 a 0.38 | Exposición baja, alta variabilidad de tareas | Exposición mínima (0.31, 0.17) |    75,372 |    87,185 |
| 2651 | Técnicos en la instalación y reparación de redes, equipos... | 4 | 0.465 | 0.43 a 0.53 | Exposición moderada, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.46, 0.14) |    28,178 |   123,069 |
| 5101 | Supervisores en la preparación y servicio de alimentos y ... | 5 | 0.242 | 0.18 a 0.28 | No expuesto | No expuesto (0.24, 0.11) |    49,983 |    95,161 |
| 3122 | Cobradores, pagadores y prestamistas | 3 | 0.3867 | 0.25 a 0.48 | Exposición moderada, alta variabilidad de tareas | Exposición baja, alta variabilidad de tareas (0.35, 0.16) |    52,638 |    70,180 |
| 2112 | Profesionistas y consultores en mercadotecnia, publicidad... | 2 | 0.49 | 0.43 a 0.55 | Exposición significativa, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.50, 0.11) |    55,917 |    57,287 |
| 1412 | Directores y gerentes de restaurantes y hoteles | 2 | 0.365 | 0.36 a 0.37 | Exposición baja, alta variabilidad de tareas | Exposición mínima (0.37, 0.12) |    41,785 |    67,767 |
| 2811 | Enfermeras (técnicas) | 2 | 0.22 | 0.22 a 0.22 | Exposición mínima | No expuesto (0.22, 0.15) |    83,117 |    22,183 |
| 2531 | Auxiliares en ciencias sociales y humanistas | 3 | 0.3867 | 0.33 a 0.46 | Exposición mínima | Exposición baja, alta variabilidad de tareas (0.38, 0.17) |    61,434 |    25,152 |
| 1212 | Directores y gerentes en servicios contables, financieros... | 5 | 0.406 | 0.36 a 0.47 | No expuesto | Exposición moderada, alta variabilidad de tareas (0.41, 0.09) |    38,967 |    46,632 |
| 7322 | Impresores, linotipistas, fotograbadores y encuadernadores | 3 | 0.2833 | 0.22 a 0.38 | Exposición baja, alta variabilidad de tareas | Exposición mínima (0.28, 0.15) |    21,686 |    55,048 |
| 3213 | Telefonistas y telegrafistas | 2 | 0.595 | 0.54 a 0.65 | Exposición significativa, alta variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.60, 0.11) |    33,120 |    35,137 |
| 2715 | Instructores y capacitadores en oficios y para el trabajo | 2 | 0.265 | 0.2 a 0.33 | Exposición mínima | No expuesto (0.29, 0.10) |    36,792 |    30,417 |
| 2122 | Asesores y analistas en finanzas | 2 | 0.595 | 0.57 a 0.62 | Exposición significativa, alta variabilidad de tareas | Exposición máxima, baja variabilidad de tareas (0.60, 0.08) |    25,818 |    38,251 |
| 2641 | Técnicos eléctricos | 2 | 0.325 | 0.27 a 0.38 | No expuesto | Exposición mínima (0.33, 0.10) |       680 |    57,049 |
| 2812 | Técnicos en aparatos de diagnóstico, tratamiento médico, ... | 4 | 0.2325 | 0.17 a 0.3 | No expuesto | No expuesto (0.23, 0.10) |    26,120 |    25,015 |
| 2532 | Auxiliares en servicios jurídicos | 2 | 0.47 | 0.39 a 0.55 | Exposición baja, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.46, 0.15) |    23,258 |    24,608 |
| 9311 | Ayudantes de conductores de transporte terrestre con moto... | 3 | 0.2333 | 0.18 a 0.28 | Exposición mínima | Exposición mínima (0.23, 0.19) |     3,035 |    42,127 |
| 1711 | Coordinadores y jefes de área de ventas, comercialización... | 3 | 0.4133 | 0.39 a 0.44 | Exposición moderada, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.41, 0.10) |    20,634 |    23,547 |
| 1512 | Coordinadores y jefes de área en servicios contables, fin... | 2 | 0.42 | 0.37 a 0.47 | Exposición mínima | Exposición moderada, alta variabilidad de tareas (0.43, 0.11) |    13,354 |    21,278 |
| 8121 | Operadores de hornos metalúrgicos, coladores y laminadore... | 2 | 0.285 | 0.26 a 0.31 | Exposición mínima | No expuesto (0.28, 0.11) |     7,083 |    23,304 |
| 2612 | Auxiliares y técnicos en ciencias biológicas, químicas y ... | 2 | 0.32 | 0.26 a 0.38 | No expuesto | Exposición baja, alta variabilidad de tareas (0.34, 0.17) |    11,392 |    14,777 |
| 1524 | Coordinadores y jefes de área en servicios legales, juece... | 2 | 0.345 | 0.31 a 0.38 | No expuesto | Exposición mínima (0.35, 0.08) |     9,209 |    13,987 |
| 2625 | Dibujantes técnicos | 2 | 0.265 | 0.18 a 0.35 | Exposición mínima | No expuesto (0.24, 0.12) |     4,893 |    17,293 |
| 8143 | Operadores de máquinas en la elaboración de celulosa, pap... | 2 | 0.25 | 0.22 a 0.28 | Exposición mínima | No expuesto (0.26, 0.12) |     2,354 |    17,885 |
| 1712 | Coordinadores y jefes de área de restaurantes y hoteles | 2 | 0.365 | 0.36 a 0.37 | Exposición baja, alta variabilidad de tareas | Exposición mínima (0.37, 0.12) |     8,007 |    11,969 |
| 2262 | Ingenieros en topografía, hidrología, geología y geodesia | 3 | 0.3667 | 0.3 a 0.44 | Exposición mínima | Exposición mínima (0.37, 0.11) |       547 |    15,093 |
| 1224 | Jueces de juzgado, directores y gerentes en servicios leg... | 2 | 0.345 | 0.31 a 0.38 | No expuesto | Exposición mínima (0.35, 0.08) |     4,001 |    10,438 |
| 2223 | Ecólogos y profesionistas en ciencias atmosféricas | 2 | 0.46 | 0.38 a 0.54 | Exposición significativa, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.47, 0.12) |     6,029 |     6,442 |
| 1311 | Directores y gerentes en producción agropecuaria, silvíco... | 2 | 0.245 | 0.22 a 0.27 | Exposición mínima | No expuesto (0.24, 0.11) |     2,906 |     8,649 |
| 2272 | Administradores de bases de datos y redes de computadora | 4 | 0.5375 | 0.49 a 0.57 | Exposición significativa, alta variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.53, 0.07) |     2,775 |     8,393 |
| 2144 | Profesionistas en archivonomía, biblioteconomía y museogr... | 2 | 0.51 | 0.47 a 0.55 | Exposición moderada, alta variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.51, 0.09) |     5,827 |     3,931 |
| 1611 | Coordinadores y jefes de área en producción agropecuaria,... | 2 | 0.245 | 0.22 a 0.27 | Exposición mínima | No expuesto (0.24, 0.11) |     3,514 |     4,075 |
| 2524 | Inspectores en seguridad social, de precios y otros inspe... | 2 | 0.405 | 0.36 a 0.45 | Exposición moderada, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.41, 0.09) |     1,227 |     4,267 |
| 3112 | Taquígrafos, mecanógrafos y similares | 2 | 0.615 | 0.58 a 0.65 | Exposición máxima, baja variabilidad de tareas | Exposición máxima, baja variabilidad de tareas (0.63, 0.07) |     4,156 |       411 |
| 2713 | Instructores en estudios y capacitación comercial y admin... | 2 | 0.4 | 0.33 a 0.47 | Exposición mínima | Exposición mínima (0.37, 0.12) |     1,371 |     3,195 |
| 2427 | Psiquiatras | 2 | 0.26 | 0.24 a 0.28 | Exposición mínima | No expuesto (0.26, 0.10) |     3,032 |     1,520 |
| 2132 | Investigadores y profesionistas en sociología y desarroll... | 2 | 0.445 | 0.41 a 0.48 | Exposición moderada, alta variabilidad de tareas | Exposición moderada, alta variabilidad de tareas (0.45, 0.10) |     2,573 |     1,415 |
| 2611 | Auxiliares y técnicos en física, astronomía, matemáticas,... | 3 | 0.49 | 0.26 a 0.64 | No expuesto | Exposición moderada, alta variabilidad de tareas (0.49, 0.18) |     2,401 |     1,177 |
| 3999 | Otros trabajadores auxiliares en actividades administrati... | 3 | 0.55 | 0.42 a 0.63 | Exposición máxima, baja variabilidad de tareas | Exposición significativa, alta variabilidad de tareas (0.54, 0.13) |       807 |       533 |
| 2234 | Profesionistas en pesca y en acuacultura | 2 | 0.39 | 0.38 a 0.4 | Exposición moderada, alta variabilidad de tareas | Exposición mínima (0.39, 0.08) |         0 |        61 |

## Otras ocupaciones con varios CIUO que cambiarían de categoría

| SINCO | Ocupación | R0 actual | R1 | R2 | Mujeres | Hombres |
|---|---|---|---|---|---|---|

## Top 10 en exposición significativa y máxima por regla

### R0 actual: Mujeres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 766,556 |
| 3111 | Secretarias | Exposición significativa, alta variabilidad de tareas | 425,172 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 249,776 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas | 241,935 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas | 109,050 |
| 3212 | Trabajadores que brindan información por teléfono (centro... | Exposición significativa, alta variabilidad de tareas |  47,579 |
| 4213 | Vendedores por teléfono | Exposición máxima, baja variabilidad de tareas |  27,926 |
| 2152 | Periodistas y redactores | Exposición significativa, alta variabilidad de tareas |  16,547 |
| 3221 | Trabajadores en agencias de viajes | Exposición significativa, alta variabilidad de tareas |  16,212 |
| 3231 | Encuestadores | Exposición significativa, alta variabilidad de tareas |  12,367 |

### R0 actual: Hombres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 498,690 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 218,814 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas |  75,322 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas |  53,334 |
| 3212 | Trabajadores que brindan información por teléfono (centro... | Exposición significativa, alta variabilidad de tareas |  41,959 |
| 4213 | Vendedores por teléfono | Exposición máxima, baja variabilidad de tareas |  21,189 |
| 3221 | Trabajadores en agencias de viajes | Exposición significativa, alta variabilidad de tareas |  20,137 |
| 2152 | Periodistas y redactores | Exposición significativa, alta variabilidad de tareas |  19,726 |
| 3111 | Secretarias | Exposición significativa, alta variabilidad de tareas |  18,362 |
| 2513 | Tramitadores aduanales | Exposición significativa, alta variabilidad de tareas |  16,579 |

### R1 primer CIUO: Mujeres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 766,556 |
| 3121 | Cajeros, taquilleros, receptores de apuestas y similares | Exposición significativa, alta variabilidad de tareas | 489,024 |
| 3111 | Secretarias | Exposición significativa, alta variabilidad de tareas | 425,172 |
| 2512 | Auxiliares en contabilidad, finanzas y agentes de bolsa | Exposición máxima, baja variabilidad de tareas | 250,812 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 249,776 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas | 241,935 |
| 4221 | Agentes y representantes de ventas y consignatarios | Exposición significativa, alta variabilidad de tareas | 122,267 |
| 4222 | Agentes de seguros y servicios financieros (ejecutivos de... | Exposición significativa, alta variabilidad de tareas | 110,462 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas | 109,050 |
| 2112 | Profesionistas y consultores en mercadotecnia, publicidad... | Exposición significativa, alta variabilidad de tareas |  55,917 |

### R1 primer CIUO: Hombres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 498,690 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 218,814 |
| 4221 | Agentes y representantes de ventas y consignatarios | Exposición significativa, alta variabilidad de tareas | 193,847 |
| 2512 | Auxiliares en contabilidad, finanzas y agentes de bolsa | Exposición máxima, baja variabilidad de tareas | 155,077 |
| 3121 | Cajeros, taquilleros, receptores de apuestas y similares | Exposición significativa, alta variabilidad de tareas | 151,444 |
| 4222 | Agentes de seguros y servicios financieros (ejecutivos de... | Exposición significativa, alta variabilidad de tareas |  93,819 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas |  75,322 |
| 2112 | Profesionistas y consultores en mercadotecnia, publicidad... | Exposición significativa, alta variabilidad de tareas |  57,287 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas |  53,334 |
| 3212 | Trabajadores que brindan información por teléfono (centro... | Exposición significativa, alta variabilidad de tareas |  41,959 |

### R2 unión de tareas: Mujeres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 766,556 |
| 3111 | Secretarias | Exposición significativa, alta variabilidad de tareas | 425,172 |
| 2512 | Auxiliares en contabilidad, finanzas y agentes de bolsa | Exposición significativa, alta variabilidad de tareas | 250,812 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 249,776 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas | 241,935 |
| 4222 | Agentes de seguros y servicios financieros (ejecutivos de... | Exposición significativa, alta variabilidad de tareas | 110,462 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas | 109,050 |
| 2271 | Desarrolladores y analistas de software y multimedia | Exposición significativa, alta variabilidad de tareas |  59,573 |
| 3212 | Trabajadores que brindan información por teléfono (centro... | Exposición significativa, alta variabilidad de tareas |  47,579 |
| 3213 | Telefonistas y telegrafistas | Exposición significativa, alta variabilidad de tareas |  33,120 |

### R2 unión de tareas: Hombres

| SINCO | Ocupación | Categoría | Personas |
|---|---|---|---|
| 3115 | Trabajadores de apoyo en actividades administrativas dive... | Exposición máxima, baja variabilidad de tareas | 498,690 |
| 2271 | Desarrolladores y analistas de software y multimedia | Exposición significativa, alta variabilidad de tareas | 311,008 |
| 2121 | Contadores y auditores | Exposición significativa, alta variabilidad de tareas | 218,814 |
| 2512 | Auxiliares en contabilidad, finanzas y agentes de bolsa | Exposición significativa, alta variabilidad de tareas | 155,077 |
| 4222 | Agentes de seguros y servicios financieros (ejecutivos de... | Exposición significativa, alta variabilidad de tareas |  93,819 |
| 3113 | Capturistas de datos | Exposición máxima, baja variabilidad de tareas |  75,322 |
| 3211 | Recepcionistas y trabajadores que brindan información (de... | Exposición significativa, alta variabilidad de tareas |  53,334 |
| 3212 | Trabajadores que brindan información por teléfono (centro... | Exposición significativa, alta variabilidad de tareas |  41,959 |
| 2122 | Asesores y analistas en finanzas | Exposición máxima, baja variabilidad de tareas |  38,251 |
| 3213 | Telefonistas y telegrafistas | Exposición significativa, alta variabilidad de tareas |  35,137 |

