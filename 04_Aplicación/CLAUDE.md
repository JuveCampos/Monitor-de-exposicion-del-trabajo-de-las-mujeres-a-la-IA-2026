# Exposicion IA - Mercado Laboral Mexicano (Shiny App)

## Que es este proyecto

App Shiny interactiva tipo narrativa/scrollytelling que visualiza la exposicion a la inteligencia artificial en el mercado laboral mexicano con perspectiva de genero. Usa datos de la ENOE (trimestre vigente: 2026-T2), ENDUTIH 2025 y la clasificacion SINCO a 4 digitos. Proyecto para el dataton "DataAccion: Dataton Regional para la Igualdad 2026".

IMPORTANTE: el periodo y los archivos de datos estan parametrizados al inicio de `app.R` (`periodo_enoe`, `archivo_enoe`, `archivo_stem_campos`, `archivo_stem_4d`). REGLA DEL PROYECTO: la app muestra SOLO el trimestre mas reciente. Para actualizar a un nuevo trimestre: (1) generar los .dta con `00_Códigos/Scripts_procesamiento_ENOE_R/01_procesar_enoe_sinco.R` y `04_procesar_enoe_stem.R` (ambos aceptan `<año> <trimestre>`; el 04 acepta un tercer argumento con la carpeta de DBF), (2) copiarlos a esta carpeta, (3) cambiar esas variables, (4) BORRAR los .dta del trimestre anterior (aqui y en `01_Datos/03_enoe_procesada/`; quedan recuperables en el historial de git).

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `app.R` | App Shiny completa (~2500 lineas). Contiene CSS, datos, funciones, UI narrativa y server |
| `zcalculos_Y2026T02_4d.dta` | Datos ENOE 2026-T2 (trimestre vigente). 1,416 filas (sexo x ocupacion SINCO) |
| `zcalculos_Y2026T02_4d_stem.dta` | Ocupados con formacion STEM por sexo y SINCO 4d (mismas columnas), de `04_procesar_enoe_stem.R` |
| `zcalculos_Y2026T02_stem_campos.dta` | Ocupados por sexo y campo de formacion (`campo_stem`: 0_NoSTEM, 1_S, 2_T, 3_E, 4_M) |
| `www/ilustraciones/*.jpg` | Imagenes del hero y de las bandas de seccion. Hoy fotos de stock provisionales (creditos en `www/ilustraciones/CREDITOS.md`); se sustituiran por ilustraciones encargadas |
| `catalogos_sinco/sinco_con_exposicion_ia.csv` | Copia sin uso directo (la app carga `sinco_con_exposicion_ia_es.csv`). 493 codigos (490 grupos unitarios SINCO 2019 + 3 operativos ENOE), generado por `05_Reproduccion_R/04_catalogo_exposicion.R`, scores de exposicion IA y columna `descripcion_ia_es` (410 con traducciones) |
| `www/andres-siimon-BBqVpTE4vw4-unsplash.jpg` | Imagen hero header (Unsplash) |
| `www/artboard_1.png.webp` | Logo DataAccion |
| `www/clave_logo.png` | Logo Clave Igualdad (footer) |
| `www/logo_mcv_blanco.svg` | Logo Mexico, Como vamos? en blanco (hero y franja de adscripcion del footer, activa desde el 15 de octubre de 2026) |
| `www/logo_mcv.svg` | Logo Mexico, Como vamos? a color (sin uso por ahora, disponible para fondos claros) |

## Variables clave del dataset

- `sex`: 0=Total, 1=Hombres, 2=Mujeres
- `sinco4d`: Codigo SINCO a 4 digitos (string con pad "0")
- `ocup`: Poblacion ocupada
- `ocuptil`: Ocupacion informal
- `til`: Tasa de informalidad (%)
- `edad2d`: Edad promedio
- `escol2d`: Escolaridad promedio (anios)
- `ingreso`: Ingreso mediano
- `potencial_ia_2025`: Categoria de exposicion IA en ingles (original)
- `exposicion_ia_es`: Categoria traducida al espanol (generada en app.R)
- `descripcion_ia_es`: Descripcion traducida de exposicion IA por ocupacion (del catalogo)

## Categorias de exposicion IA (menor a mayor)

1. No expuesto (verde #1a9641)
2. Exposicion minima (#7bc96a)
3. Mixto (#ffffbf)
4. Exposicion baja, alta variabilidad de tareas (#fee08b)
5. Exposicion moderada, alta variabilidad de tareas (#fdae61)
6. Exposicion significativa, alta variabilidad de tareas (#f46d43)
7. Exposicion maxima, baja variabilidad de tareas (rojo #d73027)
8. Sin informacion (gris #cccccc) - para NAs

## Estructura narrativa de la app (secciones en orden)

1. **Hero header** — Imagen fullwidth con titulo "Monitor de exposicion del trabajo de las mujeres a la IA"
2. **Introduccion** — 3 parrafos contextuales con frases resaltadas (span.highlight)
3. **Menu de navegacion** — Links verticales centrados con smooth-scroll a cada seccion
4. **Branding DataAccion** — Logo y descripcion del dataton
5. **Seccion 1: Exposicion a la IA** — Treemap interactivo general (selector sexo/sector), panel click-to-show descripcion, 7 graficas comparativas por sexo
6. **Subseccion: Cuidados** — Parrafo + treemap de 8 ocupaciones de cuidados (solo mujeres, SINCO: 2335, 2436, 2811, 2821, 5201, 5221, 5222, 9611)
7. **Seccion 2: Brecha tecnologica** — Series de tiempo internet/celular (ENDUTIH), cards de brecha, grafica uso de apps, bloque STEM (dos graficas + parrafo con cifras)
8. **Seccion 3: Normativa** — Tablas HTML de marco juridico internacional y nacional
9. **Seccion 4: Conclusion**
10. **Footer** — Logo Clave Igualdad, creditos, nota metodologica

## Funcionalidades de la app

### Treemap general (plotly)
- Selector de poblacion: Total, Hombres, Mujeres (con emojis)
- Selector de sector ocupacional: 9 divisiones SINCO + "Todo el mercado laboral"
- Vista jerarquica (division > ocupacion) o plana (solo sector)
- Hover con: nombre, exposicion IA, poblacion, informalidad, edad, escolaridad, ingreso
- Click en ocupacion muestra panel con descripcion traducida de exposicion IA
- Source: "treemap_src", usa customdata = sinco4d + event_register("plotly_click")
- Spinner de carga al cambiar sexo

### Treemap de cuidados (plotly)
- Fijo a mujeres (sex == 2), 8 ocupaciones SINCO de cuidados
- Treemap plano (sin jerarquia de divisiones)
- Misma escala de colores y hover que el treemap general
- Source: "treemap_cuidados_src"
- IMPORTANTE: construir_hover() debe llamarse en un mutate SEPARADO despues de crear titulo_display

### Flexion de genero en titulos de ocupacion
- Funcion `flexionar_titulos()` con 3 modos: masc, fem, inc (inclusivo con /as)
- Solo flexiona palabras ANTES de la primera preposicion (de, en, para, etc.)
- Lista de ~100 sustantivos de cosa que no se flexionan
- Excepciones: jefes>jefas, Otros>Otras, Secretarias>Secretarios/as, etc.
- El modo masc NO es identidad: el SINCO nombra algunas ocupaciones en femenino generico (Secretarias, Enfermeras, Parteras, Amas) y esas se masculinizan con `flexion_especial_masc`. Todo titulo que no contenga una de esas palabras se devuelve intacto en modo masc.

### 7 graficas comparativas por sexo (Seccion Exposicion)
1. Total en exposicion significativa y maxima (barras agrupadas)
2. Distribucion porcentual por grado de exposicion (barras apiladas 100%)
3. Ingreso mediano ponderado por gradiente (barras agrupadas)
4. Tasa de informalidad ponderada por gradiente (barras agrupadas)
5. Escolaridad promedio ponderada por gradiente (barras agrupadas)
6. Top 10 ocupaciones hombres en exposicion alta (barras horizontales, opacity 0.5)
7. Top 10 ocupaciones mujeres en exposicion alta (barras horizontales)

### Graficas ENDUTIH (Seccion Brecha tecnologica)
- Series de tiempo: acceso a internet y celular por sexo (2021-2025; fuente ENDUTIH 2025, reporte de resultados 19/26, graficas 3 y 13; el dato 2021 viene de la presentacion ENDUTIH 2024)
- Cards de brecha: diferencia H-M en el anio mas reciente (`anio_endutih`, hoy 2025; color coral #ff6260)
- Barras horizontales: uso de apps en celular inteligente por sexo con anotaciones "Total" (ENDUTIH 2025, grafica 16)

### Titulos y leyendas
- Estan fuera de plotly, como HTML en la UI (div.chart-header con fondo blanco)
- Barras de hombres tienen opacity 0.5, mujeres opacity 1 (excepto G2 apilada)

### Graficas del Resumen ejecutivo (g6_top10_h / g6_top10_m)
- Viven en la seccion Resumen ejecutivo, antes de la seccion Exposicion
- Sin barra de herramientas de plotly: `config(displayModeBar = FALSE)`
- `xaxis$range` fijado a `max(ocup) * 1.22` mas `margin r = 60` y `cliponaxis = FALSE` para que la cifra de la barra mas larga se lea completa sin zoom
- Los textos que las acompanan citan `total_top10_h` y `total_top10_m`, calculados junto a `bd_top10`
### Grafica de composicion del empleo por division SINCO (g7_divisiones)
- Tambien en el Resumen ejecutivo, debajo de los top 10. Barras apiladas al 100 % (Total, Hombres, Mujeres) con las 9 divisiones SINCO: las divisiones 1 a 3 ("de escritorio": funcionarios y directivos, profesionistas y tecnicos, oficinistas) en morados MCV y el resto en grises. Al final del bloque morado se anota la suma (27.7 % total, 25.1 % hombres, 31.3 % mujeres en 2026-T2).
- Datos en `bd_divisiones` y `pct_escritorio` (division = primer digito de `sinco4d`, para no perder codigos sin division en el catalogo). El titulo de la grafica y el parrafo citan `pct_escritorio_total`, `pct_escritorio_h`, `pct_escritorio_m` y `personas_escritorio_total`, asi que se actualizan solos al cambiar de trimestre.
- Version estatica: `00_Códigos/Scripts_graficas_presentacion/02_composicion_empleo_divisiones.R` (PNG 300 DPI con y sin titulo, mas CSV de respaldo, en `03_Archivos/graficas_presentacion/`). Usa `position_stack(reverse = TRUE)` para apilar igual que plotly.

- Version estatica en ggplot2 para presentaciones: `00_Códigos/Scripts_graficas_presentacion/01_top10_ocupaciones_expuestas.R`, que reevalua app.R hasta antes de `# --- UI ---` para reutilizar datos, flexion y paleta. Salidas PNG a 300 DPI en `03_Archivos/graficas_presentacion/`. Si se renombra el marcador `# --- UI ---` hay que ajustar ese script.

### Bloque STEM (g_stem_campos / g_stem_exposicion)
- Al final de la seccion Brecha tecnologica. `g_stem_campos`: barras agrupadas hombres/mujeres por campo de formacion (Ciencias, Tecnologia (TIC), Ingenieria, Matematicas); la etiqueta del eje x lleva debajo el % de mujeres del campo. `g_stem_exposicion`: barras apiladas 100 % por gradiente de exposicion para hombres y mujeres con formacion STEM (cruce de `zcalculos_*_4d_stem.dta` con el gradiente de `bd`).
- Cifras del parrafo: `personas_stem_total`, `personas_stem_m`, `pct_stem_mujeres`, `pct_mujeres_ingenieria`, `pct_mujeres_ciencias`, `pct_ocupados_stem_h/m`, `pct_stem_alta_h/m`. En 2026-T2: 4.29 millones con formacion STEM, 25.8 % mujeres; 18.4 % de las mujeres STEM estan en exposicion significativa o maxima contra 5.2 % de los hombres.
- La definicion STEM (campo de formacion `cs_p14_c`) vive en `04_procesar_enoe_stem.R` y replica el do-file original: economia y finanzas cuentan como ciencias y las ciencias de la salud quedan fuera.

### Estilo visual MCV (desde el 15 de octubre de 2026)
- El sitio se publicara en el sitio de Mexico, ¿Como vamos?, asi que la app sigue su identidad: Ubuntu, morado #6950d8 dominante, lila #a99be9, verde #00b783, coral #ff6260, amarillo #ffbd41, texto oscuro #231f20, fondo #F4F2FB y tarjetas blancas redondeadas.
- Hero: flex con logos (MCV blanco + Clave Igualdad en caja blanca), titulo a la izquierda e ilustracion a la derecha (`.hero-ilustracion`, `ilustraciones/hero.jpg`).
- `banda_ilustrada(imagen, texto, posicion = "center", alto = 220)`: banda de 220 px por defecto (`posicion` es el `background-position` para recortar la foto y `alto` la altura en px; Cuidados usa `center 35%` y 380 px para que se entienda la escena) con imagen de fondo y leyenda sobre franja morada; abre las secciones Exposicion, Cuidados, Brecha tecnologica y Normativa. Las imagenes estan en `www/ilustraciones/`.
- Hombres = verde #00b783 (opacity 0.5), Mujeres = morado #6950d8 en todas las graficas y leyendas. Tablas normativas con encabezados morados. Footer morado con ligas amarillas y la franja de adscripcion a MCV activa.

### Encabezado del sitio de MCV (16 de octubre de 2026)
- `encabezado_mcv()` en `app.R` reproduce el encabezado de mexicocomovamos.mx: barra morada con redes, liga "Mexico, how are we doing?" y buscador (formulario GET a mexicocomovamos.mx/?s=), cintilla decorativa (`www/mcv_cintilla.png`, imagen de temporada del sitio; hoy Día de Muertos, sustituir el PNG cuando cambie) y menú principal con las mismas secciones y ligas del sitio (lista `menu_mcv`; submenús por hover en CSS puro; sin el tercer nivel de los semaforos sectoriales). Logo central `www/logo_mcv_hall.svg`. Iconos con Font Awesome 6 desde cdnjs. Todas las ligas abren en pestana nueva.
- En el hero ya solo va el logo de Clave Igualdad (el de MCV queda en el encabezado y en el footer).

### Sistema de diseno (16 de octubre de 2026)
- Variables CSS en `:root` de `app.R`: `--ancho-texto` (920 px) para prosa, `--ancho-graficas` (1120 px) y `--ancho-relativo` (88 %) para gráficas; ninguna gráfica ocupa el 100 % del ancho. La regla `.container-fluid > .row, > .chart-header, > .plotly` aplica ese ancho a todo lo que cuelga directo de `fluidPage`.
- Clases en lugar de estilos en línea: `.bloque-texto` (prosa centrada), `.parrafo` (18 px, interlineado 1.75, 20 px abajo), `.nota-grafica` (texto de apoyo bajo una gráfica, 16 px), `.titulo-seccion` (h3 con `scroll-margin-top` para el menú fijo).
- Fondo de plotly transparente por CSS (`.main-svg`, `.bglayer .bg`, `.legend .bg` con `!important`), asi el fondo de las gráficas es el de la página (#F4F2FB). Los `chart-header` (título, subtítulo y leyenda) y las `.nota-grafica` (texto de apoyo bajo cada gráfica) son tarjetas blancas con sombra suave sobre el fondo lila; el `chart-header` conserva la regla morada a la izquierda.
- Hero `.hero` a todo lo ancho (truco `100vw` + `margin-left: calc(-50vw + 50%)`): logos, eyebrow amarilla, h1 con `<span class='acento'>` amarillo, subtítulo, tres tarjetas `.cifra` (personas ocupadas, % de mujeres y de hombres en exposición significativa o máxima; variables `personas_ocupadas_hero`, `pct_alta_hero_m`, `pct_alta_hero_h`), imagen con crédito y semicírculos decorativos (`.hero::after`, radial-gradient repetido, guiño a los semicirculos de MCV).
- Menú `.nav-secciones` fijo (`position: sticky`) bajo el hero, sustituye al recuadro "Dimensiones". Los ids de sección siguen siendo `sec-resumen`, `sec-exposicion`, `sec-brecha`, `sec-normativa`, `sec-conclusion`.

## Estilos CSS clave

- **Fondo app**: #F4F2FB
- **Fuente**: Ubuntu (Google Fonts), font-size base 19px
- **span.highlight**: subrayado grueso #6950D8 (texto negro bold); **.title-highlight**: fondo #6950D8 con texto blanco
- **span.title-highlight**: igual pero padding 4px 10px (para h3 de secciones)
- **div.chart-header**: fondo blanco, border-radius top 12px, box-shadow, padding 15px 20px
- **Hero header**: caja de 960px con fondo morado MCV #6950d8 y texto blanco
- **Footer**: fondo #3a3a3a, flexbox 30% logo (fondo blanco) + 70% texto blanco

## Imagen institucional Mexico, Como vamos?

Se esta proponiendo que el monitor entre a la cartera de proyectos de MCV, pero NO esta concretado. Lo unico visible hoy es el hero header en morado MCV #6950d8 con texto blanco. La franja del footer con el logo y la leyenda "Este monitor forma parte de la cartera de proyectos de" quedo SILENCIADA (comentada al final del footer en app.R); se reactiva descomentandola y agregando una coma al cierre del div anterior. Los logos ya estan en `www/logo_mcv_blanco.svg` y `www/logo_mcv.svg`.

Paleta MCV completa por si se amplia: morado #6950D8, coral #ff6260, verde #00b783, amarillo #ffbd41, amarillo fuerte #E8D92E, cian #3CEAFA, lila #A99BE9, gris #777777, gris claro #D2D0CD.

## Colores por sexo

- Hombres: verde #01b665 (opacity 0.5 en barras)
- Mujeres: azul #3a39ff (opacity 1)

## Dependencias R

- shiny
- haven (lectura .dta)
- tidyverse
- plotly

## Despliegue

App ligera (~266KB datos). Compatible con plan Free o Starter de shinyapps.io (1GB RAM sobra).

Se despliega con `Rscript deploy.R` desde esta carpeta (cuenta `juvecamposf`, app `dataton_genero_2026_exposicion_ia_trabajos`). El script trae una lista explicita de `appFiles` (7 archivos, ~1.4 MB) y deja fuera `assets/`, la imagen de Unsplash y el catalogo `sinco_con_exposicion_ia.csv` sin flexion, que no se usan. Antes de subir verifica que existan los archivos, que `app.R` parsee, que la cuenta este configurada y que `periodo_enoe` coincida con el trimestre del nombre del `.dta`.

Al cambiar de trimestre hay que actualizar las dos variables del inicio de `app.R` (`periodo_enoe` y `archivo_enoe`) y el nombre del `.dta` en `archivos_app` de `deploy.R`.

## Origen de los datos de exposicion

Los scores de exposicion IA provienen de Gmyrek et al. (2025) ILO WP140, mapeados via SINCO → CIUO-08. Las descripciones por ocupacion (`descripcion_ia_es`) se arman en `05_Reproduccion_R/05_descripciones_en.R` y `06_traducir_claude.R` (traduccion con Claude via `claude -p`, cache en `salidas/06_traducciones_claude_cache.csv`). Hasta octubre de 2026 se generaban con scripts de Python y traduccion con Ollama/Gemma4 (legado en `01_Datos/01_catalogos/scripts/`).

Desde el 16 de octubre de 2026 el catalogo viene de `05_Reproduccion_R/salidas/08_catalogo_app.csv` (crosswalk SINCO 2019 corregido con la equivalencia 2011-2019 del INEGI; traducciones con Claude). Incluye 62 clasificaciones PROVISIONALES (columna `clasificacion_provisional`): 25 por mapeo manual a ocupacion CIUO analoga (`05_Reproduccion_R/insumos/mapeo_manual_ciuo.csv`) y 37 por imputacion modal jerarquica (categoria modal de las hermanas del subgrupo/grupo/division). Se generan con `05_Reproduccion_R/08_provisionales_catalogo_app.R`; los scripts 02 y 03 de `00_Códigos/Scripts_procesamiento_ENOE_R/` quedan como legado del catalogo anterior.

## Placeholders pendientes

- "Visualizacion mujeres en STEM" (seccion Brecha tecnologica)
- Liga a la nota metodologica en el footer: silenciada (comentada) desde el 16 de octubre de 2026 hasta resolver la ficha metodologica; el pie solo deja el correo de contacto

### Tabla de tareas al seleccionar una ocupacion (16 de octubre de 2026)

- `catalogos_sinco/tareas_por_ocupacion.csv`: una fila por tarea evaluada por
  Gmyrek et al. (2025) para las CIUO-08 de cada grupo unitario del catalogo
  vigente, en espanol (traducidas con Claude; columna `traducida`), con
  `score_tarea_2025`, `nivel_tarea` (Alta >= 0.6, Media >= 0.4, Baja) y la
  justificacion de la tarea mas expuesta. Lo genera
  `00_Códigos/Scripts_procesamiento_ENOE_R/07_tareas_por_ocupacion_app.R` a
  partir del Excel de Gmyrek y de la cache de traducciones de
  `05_Reproduccion_R/salidas/06_traducciones_claude_cache.csv`.
- `construir_tabla_tareas(tareas_sel, desc)` (definida al inicio de app.R)
  arma la tabla (tarea, barra y puntuacion, con scroll a 330px) mas la
  justificacion y un `<details>` con la descripcion completa. El panel
  `output$panel_descripcion_ia` la usa cuando hay tareas para la ocupacion;
  si no (provisionales, grises, o sin archivo) muestra el parrafo de siempre.
- Carpeta `05_Reproduccion_R/` (raiz del repo): flujo completo en R desde
  cero, con la correspondencia SINCO 2019 a CIUO-08 corregida por la tabla
  de equivalencia 2011-2019 del INEGI. No alimenta la app todavia; ver su
  README y `salidas/10_verificacion.md`.

### Indicadores de carga en las graficas (16 de octubre de 2026)

Las 15 salidas `plotlyOutput()` van envueltas en `shinycssloaders::withSpinner()`.
La configuracion es global al inicio de `app.R` (`options(spinner.color = "#6950d8",
spinner.type = 8, spinner.size = 0.8)`), asi que una grafica nueva solo necesita
el envoltorio. rsconnect detecta el paquete por la llamada a `library()`; no hay
que tocar `deploy.R`.
