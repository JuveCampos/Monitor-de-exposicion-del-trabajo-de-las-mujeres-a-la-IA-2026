# Exposicion IA - Mercado Laboral Mexicano (Shiny App)

## Que es este proyecto

App Shiny interactiva tipo narrativa/scrollytelling que visualiza la exposicion a la inteligencia artificial en el mercado laboral mexicano con perspectiva de genero. Usa datos de la ENOE (trimestre vigente: 2026-T2), ENDUTIH 2024 y la clasificacion SINCO a 4 digitos. Proyecto para el dataton "DataAccion: Dataton Regional para la Igualdad 2026".

IMPORTANTE: el periodo y los archivos de datos estan parametrizados al inicio de `app.R` (`periodo_enoe`, `archivo_enoe`, `archivo_stem_campos`, `archivo_stem_4d`). REGLA DEL PROYECTO: la app muestra SOLO el trimestre mas reciente. Para actualizar a un nuevo trimestre: (1) generar los .dta con `00_Códigos/Scripts_procesamiento_ENOE_R/01_procesar_enoe_sinco.R` y `04_procesar_enoe_stem.R` (ambos aceptan `<año> <trimestre>`; el 04 acepta un tercer argumento con la carpeta de DBF), (2) copiarlos a esta carpeta, (3) cambiar esas variables, (4) BORRAR los .dta del trimestre anterior (aqui y en `01_Datos/03_enoe_procesada/`; quedan recuperables en el historial de git).

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `app.R` | App Shiny completa (~2500 lineas). Contiene CSS, datos, funciones, UI narrativa y server |
| `zcalculos_Y2026T02_4d.dta` | Datos ENOE 2026-T2 (trimestre vigente). 1,416 filas (sexo x ocupacion SINCO) |
| `zcalculos_Y2026T02_4d_stem.dta` | Ocupados con formacion STEM por sexo y SINCO 4d (mismas columnas), de `04_procesar_enoe_stem.R` |
| `zcalculos_Y2026T02_stem_campos.dta` | Ocupados por sexo y campo de formacion (`campo_stem`: 0_NoSTEM, 1_S, 2_T, 3_E, 4_M) |
| `www/ilustraciones/*.jpg` | Imagenes del hero y de las bandas de seccion. Hoy fotos de stock provisionales (creditos en `www/ilustraciones/CREDITOS.md`); se sustituiran por ilustraciones encargadas |
| `catalogos_sinco/sinco_con_exposicion_ia.csv` | Catalogo SINCO con 483 ocupaciones, scores de exposicion IA y columna `descripcion_ia_es` (410 con traducciones) |
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
5. Exposicion moderada, variabilidad mixta de tareas (#fdae61)
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
- Series de tiempo: acceso a internet y celular por sexo (2021-2024)
- Cards de brecha: diferencia H-M en 2024 (color rojo #d64f4f, emojis wifi/telefono)
- Barras horizontales: uso de apps en celular por sexo con anotaciones "Total"

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
- `banda_ilustrada(imagen, texto)`: banda de 210 px con imagen de fondo y leyenda sobre franja morada; abre las secciones Exposicion, Cuidados, Brecha tecnologica y Normativa. Las imagenes estan en `www/ilustraciones/`.
- Hombres = verde #00b783 (opacity 0.5), Mujeres = morado #6950d8 en todas las graficas y leyendas. Tablas normativas con encabezados morados. Footer morado con ligas amarillas y la franja de adscripcion a MCV activa.

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

Los scores de exposicion IA provienen de Gmyrek et al. (2025) ILO WP140, mapeados via SINCO → CIUO-08. Las descripciones por ocupacion (`descripcion_ia_es`) fueron generadas con scripts en `05_Tareas/01_catalogos/scripts/` (agregacion + traduccion via Ollama/Gemma4).

Desde julio de 2026 el catalogo (488 ocupaciones) incluye 68 clasificaciones PROVISIONALES (columna `clasificacion_provisional`): 28 por mapeo manual a ocupacion CIUO analoga (`mapeo_manual_propuesto.csv`) y 40 por imputacion modal jerarquica (categoria modal de las hermanas del subgrupo/grupo/division). Se generan con `00_Códigos/Scripts_procesamiento_ENOE_R/02_ocupaciones_sin_score.R` (catalogo de grises + textos) y se integran con `03_integrar_provisionales.R`. El hover agrega "(provisional)" y el panel "(clasificacion provisional)" a esas ocupaciones; sus descripciones explican el metodo. Quedan 10 sin clasificar (7 visibles en datos 2026-T1: 6 militares + ocupaciones no especificadas 9999), en gris, con descripcion que explica por que no son imputables.

## Placeholders pendientes

- "Visualizacion mujeres en STEM" (seccion Brecha tecnologica)
- Link "esta liga" en footer (nota metodologica, sin URL aun)
