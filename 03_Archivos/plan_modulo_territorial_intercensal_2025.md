# Plan: módulo territorial con la Encuesta Intercensal 2025

Fecha: 16 de octubre de 2026. Estado: plan sin ejecutar. Se decide después de
la presentación del Monitor si se construye y con qué profundidad.

## 1. Qué se quiere responder

La ENOE permite estimar la exposición a la IA por sexo a nivel nacional y
estatal. La Encuesta Intercensal (EIC) 2025 permitiría dos cosas que hoy el
Monitor no tiene:

1. Un mapa estatal y municipal de la proporción de mujeres y hombres ocupados
   en subgrupos de exposición significativa o máxima.
2. Un indicador de exposición condicionada al acceso digital: personas en
   subgrupos de exposición alta que viven en viviendas sin internet o sin
   computadora, por sexo y territorio. Responde a la crítica 3.5 del documento
   de críticas (misma puntuación para todos los contextos).

## 2. Insumos ya disponibles

Todo está en `/Volumes/Extreme SSD/DATASETS/INEGI - ENCUESTA INTERCENSAL/2025/`:

- `microdatos/zip/eic2025_micro_NN_csv.zip` (32 entidades; `personasNN.csv`,
  `viviendasNN.csv`, ligadas por `ID_VIV`).
- `microdatos/documentacion/eic2025_micro_fd.xlsx` (descriptor) y
  `889463931966.xlsx` (clasificadores; la ocupación es el SINCO 2019 a
  subgrupo de tres dígitos).
- `visualizaciones/` con el flujo de mapas municipales en estilo MCV
  (`R/00_estilo_mcv.R`, `datos/geo_municipios.rds`, `datos/geo_estados.rds`).
- Del repositorio: el catálogo de exposición a cuatro dígitos
  (`05_Reproduccion_R/salidas/08_catalogo_app.csv` cuando se adopte, o el
  vigente en `04_Aplicación/catalogos_sinco/`) y la población ocupada por
  SINCO 4d de la ENOE para ponderar.

Variables que se usarían de `personas`: `SEXO`, `EDAD`, `CONACT`,
`OCUPACION_C` (3 dígitos), `SITTRA`, `INGTRMEN`, `SM`, `HORTRA`,
`ACTIVIDADES_C`, prestaciones (`AGUINALDO`, `VACACIONES`, `SERVICIO_MEDICO`,
`UTILIDADES`, `INCAP_SUELDO`, `SAR_AFORE`, `CREDITO_VIVIENDA`), `MUN_TRAB`,
`TIE_TRASLADO_TRAB`, `NIVACAD`, `ESCOACUM`, `CVE_ENT`, `CVE_MUN`, `LOC50K`,
`COBERTURA`, `ESTRATO`, `UPM`, `FACTOR`. De `viviendas`: `INTERNET`,
`COMPUTADORA`, `CELULAR`, `TELEFONO`, `TAMLOC`.

La EIC no capta carrera ni campo de formación: el bloque STEM no se replica.

## 3. Pasos

1. **Colapsar el catálogo a tres dígitos.** Para cada subgrupo SINCO 2019,
   obtener la categoría de exposición a partir de sus grupos unitarios,
   ponderando por la población ocupada de la ENOE 2026-T2. Guardar también
   el rango (mínimo y máximo de puntuación) y marcar "Mixto" cuando los
   grupos unitarios caen en categorías distintas. Decidir la regla antes de
   calcular nada (es la misma discusión que la regla para "Mixto" a 4d).
2. **Leer y unir los microdatos.** Un script en R que recorra los 32 zip,
   una `personas` con `viviendas` por `ID_VIV`, filtre población ocupada
   (`CONACT` en los códigos de ocupados) de 15 años y más, y pegue el
   catálogo por `OCUPACION_C`. Usar `srvyr` con `ESTRATO`, `UPM` y `FACTOR`.
3. **Estimar** por sexo, a nivel nacional, entidad y municipio: proporción
   en cada categoría de exposición; proporción en exposición alta sin
   internet y sin computadora en la vivienda; ingreso mediano y prestaciones
   dentro de la exposición alta. Guardar estimaciones con coeficiente de
   variación.
4. **Filtrar lo publicable.** Reportar municipios solo con `COBERTURA` 1 o 2
   y coeficiente de variación menor a 25% (criterio del INEGI para
   estimaciones de calidad moderada); el resto se agrega a entidad.
5. **Mapas** con el flujo de `visualizaciones/R`: una lámina por indicador y
   sexo, estilo MCV. Opcionalmente, una sección nueva en la app.
6. **Validar** la estimación nacional por sexo de la EIC contra la ENOE
   2026-T2 colapsada a tres dígitos, para dimensionar la diferencia entre
   fuentes (momento de referencia, instrumento, informante indirecto).

## 4. Decisiones pendientes del equipo

- Regla de colapso a tres dígitos (paso 1).
- Si el módulo entra al Monitor como sección o se presenta como anexo
  territorial fechado "EIC 2025".
- Umbral de precisión para publicar municipios.
- Qué indicador digital usar como referencia principal: internet en la
  vivienda (75.7% nacional) o computadora (39.3%), que discrimina más.

## 5. Riesgos

- La exposición se mide a subgrupo, no a grupo unitario: pierde resolución y
  obliga a documentar la regla de colapso.
- Grupos pequeños por municipio y sexo; muchos municipios no alcanzarán
  precisión suficiente.
- La tecnología se mide como disponibilidad en la vivienda, no como uso de
  la persona; la brecha de uso por sexo sigue viniendo de la ENDUTIH.
- Momento de referencia distinto (15 de octubre de 2025) al de la ENOE.

## 6. Esfuerzo estimado

Prueba de viabilidad con dos o tres entidades: medio día. Módulo completo
con las 32 entidades, mapas y nota metodológica: dos a tres días de trabajo.

## Referencias

INEGI. (2026). *Encuesta Intercensal 2025. Comunicado de prensa 54/26*
(22 de septiembre de 2026).
https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2026/ei/EIC2025-def_CP.pdf

INEGI. (2026). *Encuesta Intercensal 2025. Reporte de resultados 37/26*.
https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2026/ei/EIC2025-def_RR.pdf

INEGI. (2026). *Encuesta Intercensal 2025. Microdatos y descriptor de archivos*.
https://www.inegi.org.mx/programas/eic/2025/
