# Exposicion IA - Mercado Laboral Mexicano (Shiny App)

## Que es este proyecto

App Shiny interactiva tipo narrativa/scrollytelling que visualiza la exposicion a la inteligencia artificial en el mercado laboral mexicano con perspectiva de genero. Usa datos de la ENOE (trimestre vigente: 2026-T1), ENDUTIH 2024 y la clasificacion SINCO a 4 digitos. Proyecto para el dataton "DataAccion: Dataton Regional para la Igualdad 2026".

IMPORTANTE: el periodo y el archivo de datos estan parametrizados al inicio de `app.R` (`periodo_enoe` y `archivo_enoe`). REGLA DEL PROYECTO: la app muestra SOLO el trimestre mas reciente. Para actualizar a un nuevo trimestre: (1) generar el .dta con `00_Códigos/Scripts_procesamiento_ENOE_R/01_procesar_enoe_sinco.R`, (2) copiarlo a esta carpeta, (3) cambiar esas dos variables, (4) BORRAR los .dta del trimestre anterior (aqui y en `01_Datos/03_enoe_procesada/`; quedan recuperables en el historial de git).

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `app.R` | App Shiny completa (~2500 lineas). Contiene CSS, datos, funciones, UI narrativa y server |
| `zcalculos_Y2026T01_4d.dta` | Datos ENOE 2026-T1 (trimestre vigente). 1,405 filas (484 ocupaciones x 3 sexos) |
| `catalogos_sinco/sinco_con_exposicion_ia.csv` | Catalogo SINCO con 483 ocupaciones, scores de exposicion IA y columna `descripcion_ia_es` (410 con traducciones) |
| `www/andres-siimon-BBqVpTE4vw4-unsplash.jpg` | Imagen hero header (Unsplash) |
| `www/artboard_1.png.webp` | Logo DataAccion |
| `www/clave_logo.png` | Logo Clave Igualdad (footer) |
| `www/logo_mcv_blanco.svg` | Logo Mexico, Como vamos? en blanco (franja de adscripcion del footer) |
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
7. **Seccion 2: Brecha tecnologica** — Series de tiempo internet/celular (ENDUTIH), cards de brecha, grafica uso de apps, placeholder STEM
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
- Version estatica en ggplot2 para presentaciones: `00_Códigos/Scripts_graficas_presentacion/01_top10_ocupaciones_expuestas.R`, que reevalua app.R hasta antes de `# --- UI ---` para reutilizar datos, flexion y paleta. Salidas PNG a 300 DPI en `03_Archivos/graficas_presentacion/`. Si se renombra el marcador `# --- UI ---` hay que ajustar ese script.

## Estilos CSS clave

- **Fondo app**: #D6D6FD
- **Fuente**: Ubuntu (Google Fonts), font-size base 19px
- **span.highlight**: background #3A3CF9, color white, bold, padding 2px 6px, border-radius 3px
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
