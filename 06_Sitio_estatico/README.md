# Versión estática del Monitor (sin servidor de Shiny)

Esta carpeta genera la misma página que sirve la app Shiny de
`04_Aplicación`, pero como HTML plano: se puede abrir desde el disco,
hospedar en GitHub Pages o incrustar en el sitio de México, ¿cómo vamos?
sin necesidad de R en el servidor ni de horas de shinyapps.io.

## Cómo se construye

Desde la raíz del repositorio:

```bash
Rscript 06_Sitio_estatico/construir_sitio.R
```

El script evalúa `04_Aplicación/app.R` completo, pero antes define en el
entorno global sustitutos de las funciones de Shiny (`renderPlotly`,
`renderUI`, `reactiveVal`, `observeEvent`, `plotlyOutput`, `uiOutput`,
`withSpinner`, `shinyApp`). Como R consulta el entorno global antes que
los paquetes, `app.R` usa esos sustitutos sin modificarse. Resultado: la
versión estática comparte con la app los datos, las funciones, el CSS,
el HTML y el código de las 15 gráficas. Hay una sola fuente de verdad, y
cualquier cambio en `app.R` se refleja al volver a correr el script.

Para actualizar el trimestre se sigue el procedimiento de siempre en
`04_Aplicación/CLAUDE.md` y después se vuelve a correr este script.

## Qué hay en `docs/`

| Ruta | Contenido |
|---|---|
| `index.html` | La página completa (hero, encabezado MCV, secciones, 15 gráficas plotly, normativa, pie) |
| `lib/` | plotly.js, jQuery y Bootstrap que htmlwidgets copia automáticamente |
| `monitor.js` | Selectores y clic del treemap (copia de `monitor.js` de esta carpeta) |
| `datos/treemap/<sexo>_<sector>.js` | Las 30 variantes del treemap (3 poblaciones por 10 sectores), ya calculadas en R con `generar_treemap()` |
| `datos/paneles/<sinco4d>.js` | El panel de descripción y tabla de tareas de cada ocupación, ya renderizado en R con el mismo bloque del server |
| logos e ilustraciones | Copia de `04_Aplicación/www/` |
| `.nojekyll` | Para que GitHub Pages sirva la carpeta tal cual |

`docs/` se borra y se regenera completa en cada corrida. No editar a mano.

## Cómo funciona la interacción sin servidor

Solo dos cosas dependían del server de Shiny, y las dos viven ahora en
`monitor.js`:

- Al cambiar población o sector, el navegador carga el archivo de la
  variante correspondiente (si no lo tiene ya) y redibuja el treemap con
  `Plotly.react()`. El subtítulo se actualiza con el texto precalculado.
- Al hacer clic en una ocupación, carga el archivo de su panel y lo
  inserta en `#panel_descripcion_ia`. Un clic en una división (sin
  código SINCO) no hace nada, igual que en la app.

Los archivos de datos se cargan con etiquetas `<script>` y no con
`fetch()`, para que la página funcione también abierta desde el disco
(`file://`). Las 13 gráficas restantes y el treemap de cuidados no
dependen de ninguna entrada del usuario, así que van embebidas en
`index.html` como cualquier htmlwidget.

## Diferencias con la app Shiny

- No hay velo de carga ni spinners: el cambio es inmediato.
- Los selectores son `<select>` nativos del navegador en lugar de
  selectize (que lo inicializaba shiny.js).
- Todo lo demás (textos, cifras, paleta, hover, flexión de género de los
  títulos, tabla de tareas) sale del mismo código.

## Para publicar

- **GitHub Pages**: solo acepta publicar desde `/` o `/docs` en la raíz
  del repositorio, así que hay dos opciones: cambiar `ruta_docs` en el
  script para que escriba en `docs/` de la raíz, o publicar con una
  acción de GitHub que copie esta carpeta a la rama `gh-pages`.
- **Sitio de MCV (WordPress)**: hospedar `docs/` en cualquier servidor
  estático e incrustarlo con un `<iframe>`, igual que se haría con la
  liga de shinyapps.io.
- **Prueba local**: `python3 -m http.server 8765` dentro de `docs/` y
  abrir `http://127.0.0.1:8765/`, o abrir `index.html` directamente.

## Rendimiento (medido el 22 de octubre de 2026)

Mediciones con Chrome sin cabeza en una Mac con Apple Silicon. "Primer
pintado" es cuando aparece el hero; "gráficas" es cuando las 15 gráficas
de plotly ya están dibujadas.

| Escenario | Primer pintado | Gráficas |
|---|---|---|
| Estático abierto desde el disco (`file://`) | 0.3 s | 0.7 s |
| Estático en servidor con gzip, red local | 0.3 s | 0.7 s |
| Estático en servidor con gzip, red de 10 Mbps | 0.4 s | 2.8 s |
| App Shiny corriendo en local | 3.4 s | 12.5 s |

Lo que ya se hace para que cargue rápido:

- Los scripts llevan `defer`, así el hero y el texto aparecen antes de
  que baje plotly.js (1.1 MB comprimido, 3.5 MB sin comprimir).
- El HTML no embebe la especificación duplicada que plotly guarda en cada
  widget (`x$attrs`); solo el treemap ahorraba 326 KB.
- Las variantes del treemap y los paneles se cargan al usarse, no al
  arrancar.
- La foto de la banda de normativa se recomprime en la copia (de 949 KB
  a 320 KB).

Lo que todavía pesa y cómo reducirlo si hace falta:

- `plotly-latest.min.js` es el paquete completo. Un paquete a la medida
  con solo `bar`, `scatter` y `treemap` pesaría alrededor de un tercio;
  se arma con npm (`plotly.js` incluye el script `custom-bundle`) y se
  copia encima de `lib/plotly-main-2.25.2/plotly-latest.min.js` tras
  construir.
- `logo_mcv_hall.svg` pesa 334 KB porque trae imágenes incrustadas
  (53 KB comprimido). Convendría pedir a MCV una versión vectorial
  limpia.
- Las fuentes de Google y Font Awesome vienen de CDN; sin internet la
  página usa la fuente de respaldo del sistema.
