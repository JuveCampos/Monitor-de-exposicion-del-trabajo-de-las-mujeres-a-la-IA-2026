# =====================================================================
# Versión estática del Monitor de exposición del trabajo de las mujeres
# a la IA: la misma página que sirve la app Shiny, pero como HTML plano
# que no necesita servidor de R.
#
# Uso (desde la raíz del repositorio):
#   Rscript 06_Sitio_estatico/construir_sitio.R
#
# Salida: 06_Sitio_estatico/docs/
#   index.html                  página completa
#   lib/                        plotly.js, jquery y bootstrap (htmlwidgets)
#   datos/treemap/<sexo>_<sector>.js
#                               30 versiones del treemap (3 sexos x 10
#                               sectores) ya calculadas en R; se cargan al
#                               cambiar los selectores
#   datos/paneles/<sinco4d>.js  panel de descripción y tabla de tareas de
#                               cada ocupación, ya renderizado en R; se
#                               carga al hacer clic en el treemap
#   monitor.js                  selectores y clic del treemap en el navegador
#   logos e ilustraciones       copia de 04_Aplicación/www
#
# Cómo funciona: se evalúa app.R completo, pero antes se definen en el
# entorno global sustitutos de las funciones de Shiny (renderPlotly,
# renderUI, reactiveVal, observeEvent, plotlyOutput, uiOutput, withSpinner,
# shinyApp). Como el entorno global se consulta antes que los paquetes,
# app.R usa estos sustitutos sin modificarse. Así la versión estática
# comparte con la app los datos, las funciones, el CSS, el HTML y el código
# de las 15 gráficas: hay una sola fuente de verdad.
# =====================================================================

library(tidyverse)
library(haven)
library(plotly)
library(htmltools)
library(jsonlite)

# --- Rutas ---
ruta_raiz <- normalizePath(".")
ruta_app <- file.path(ruta_raiz, "04_Aplicación")
ruta_sitio <- file.path(ruta_raiz, "06_Sitio_estatico")
ruta_docs <- file.path(ruta_sitio, "docs")

stopifnot(
  "Correr desde la raíz del repositorio" = file.exists(
    file.path(ruta_app, "app.R")
  ),
  "Falta monitor.js" = file.exists(file.path(ruta_sitio, "monitor.js"))
)

# --- Sustitutos de las funciones de Shiny -----------------------------------

# renderPlotly() y renderUI() devuelven una función sin argumentos que, al
# llamarse, evalúa el bloque original en el entorno del server. Así el
# mismo bloque se puede evaluar varias veces (por ejemplo, el panel de
# descripción para cada ocupación).
renderPlotly <- function(expr, ...) {
  f <- function() NULL
  body(f) <- substitute(expr)
  environment(f) <- parent.frame()
  f
}
renderUI <- renderPlotly

# reactiveVal() se vuelve un simple contenedor con lectura y escritura.
reactiveVal <- function(value = NULL) {
  function(x) {
    if (missing(x)) value else value <<- x
  }
}

# Observadores y eventos de Shiny no aplican: sus argumentos nunca se
# evalúan.
observeEvent <- function(...) invisible(NULL)
event_data <- function(...) NULL
withSpinner <- function(ui_element, ...) ui_element
shinyApp <- function(ui, server, ...) invisible(NULL)

# En la primera evaluación de app.R la UI se arma con marcadores; en la
# segunda (más abajo) plotlyOutput() devuelve el widget ya calculado.
widgets_listos <- NULL
salidas_ui <- list()
plotlyOutput <- function(outputId, width = "100%", height = "400px", ...) {
  if (is.null(widgets_listos)) {
    return(div(id = outputId, class = "marcador-plotly"))
  }
  w <- widgets_listos[[outputId]]
  stopifnot(!is.null(w))
  # El widget de plotly embebe, además de los datos ya construidos
  # (x$data), la especificación original (x$attrs) con los mismos vectores:
  # en el treemap son 326 KB duplicados. El binding de JavaScript solo usa
  # x$data, x$layout, x$config, x$highlight y x$shinyEvents.
  w <- plotly_build(w)
  w$x$attrs <- NULL
  w$x$visdat <- NULL
  w$x$cur_data <- NULL
  w$elementId <- outputId
  w$width <- width
  w$height <- height
  w
}
uiOutput <- function(outputId, ...) {
  div(id = outputId, salidas_ui[[outputId]])
}

# --- Evaluación de app.R ----------------------------------------------------
setwd(ruta_app)
expresiones_app <- parse("app.R", encoding = "UTF-8", keep.source = FALSE)
for (expresion in expresiones_app) {
  eval(expresion, envir = globalenv())
}

# Posición de la expresión `ui <- fluidPage(...)` para volver a evaluarla
# cuando los widgets estén listos
es_asignacion_ui <- vapply(
  expresiones_app,
  function(e) {
    is.call(e) && identical(e[[1]], as.name("<-")) &&
      identical(e[[2]], as.name("ui"))
  },
  logical(1)
)
stopifnot(sum(es_asignacion_ui) == 1)
expresion_ui <- expresiones_app[[which(es_asignacion_ui)]]

# --- Ejecución del server con la selección por defecto ----------------------
# La app arranca con Mujeres y "Todo el mercado laboral".
input <- list(sexo = "2", sector = "all")
output <- new.env()
server(input, output, session = NULL)

nombres_salidas <- ls(output)
print(paste("Salidas del server:", length(nombres_salidas)))

# Cada salida se evalúa una vez. Las de plotly se guardan como widgets; las
# de UI (título del treemap y panel) como HTML.
widgets <- list()
for (nombre in nombres_salidas) {
  valor <- output[[nombre]]()
  if (inherits(valor, "plotly")) {
    widgets[[nombre]] <- valor
  } else {
    salidas_ui[[nombre]] <- valor
  }
}
print(paste("Gráficas plotly:", length(widgets)))

# --- Variantes del treemap (3 sexos x 10 sectores) --------------------------
# generar_treemap() es la misma función que usa el server. De cada variante
# se guardan data, layout y config con el mismo serializador que usa el
# htmlwidget de plotly (plotly:::to_JSON; el de htmlwidgets convierte los
# vectores con nombre, como los colores, en objetos y rompe el treemap), más
# el subtítulo que mostraba renderUI("treemap_titulo").
# Cada variante es un archivo datos/treemap/<sexo>_<sector>.js que define
# window.TREEMAP_VARIANTES["<sexo>|<sector>"]; monitor.js lo carga cuando
# el usuario cambia los selectores.
variantes <- list()
for (sexo_val in opciones_sexo) {
  titulo_sexo <- names(opciones_sexo)[opciones_sexo == sexo_val]
  for (sector_val in opciones_sector) {
    p <- generar_treemap(bd, sexo_val, titulo_sexo, sector_val)
    x <- plotly_build(p)$x[c("data", "layout", "config")]
    subtitulo_sector <- if (sector_val == "all") {
      ""
    } else {
      paste0(" | ", names(opciones_sector)[opciones_sector == sector_val])
    }
    clave <- paste0(sexo_val, "|", sector_val)
    variantes[[clave]] <- paste0(
      'window.TREEMAP_VARIANTES["', clave, '"] = {"x": ',
      plotly:::to_JSON(x),
      ', "subtitulo": ',
      toJSON(
        paste0(
          titulo_sexo, " | ENOE ", periodo_enoe,
          " | Clasificación SINCO 4 dígitos", subtitulo_sector
        ),
        auto_unbox = TRUE
      ),
      "};"
    )
  }
}
print(paste("Variantes del treemap:", length(variantes)))

# --- Paneles de descripción por ocupación -----------------------------------
# Se reutiliza el bloque renderUI("panel_descripcion_ia") del server: se fija
# la ocupación en sinco_seleccionado() y se evalúa el bloque. El contenido
# no depende del sexo, pero el bloque busca la fila del sexo seleccionado,
# así que se prueba con Total, Hombres y Mujeres hasta encontrarla.
# Cada panel es un archivo datos/paneles/<sinco4d>.js que define
# window.PANELES["<sinco4d>"]; monitor.js lo carga al hacer clic.
entorno_server <- environment(output$panel_descripcion_ia)
codigos <- bd %>%
  filter(ocup > 0) %>%
  distinct(sinco4d) %>%
  pull(sinco4d)

paneles <- list()
for (codigo in codigos) {
  entorno_server$sinco_seleccionado(codigo)
  for (sexo_val in c("0", "1", "2")) {
    entorno_server$input <- list(sexo = sexo_val, sector = "all")
    panel <- output$panel_descripcion_ia()
    if (!is.null(panel)) break
  }
  if (!is.null(panel)) {
    paneles[[codigo]] <- as.character(panel)
  }
}
entorno_server$sinco_seleccionado(NULL)
entorno_server$input <- input
print(paste("Paneles de ocupación:", length(paneles)))

# --- Armado de la página ----------------------------------------------------
widgets_listos <- widgets
ui <- eval(expresion_ui, envir = globalenv())

# El velo de carga ("Actualizando visualizaciones...") existía por la
# latencia de Shiny; en la versión estática el cambio es inmediato.
ui <- tagQuery(ui)$find("#loading-overlay")$remove()$allTags()
# ...y su script de jQuery, que además impediría diferir la carga de las
# librerías (ver más abajo).
ui <- tagQuery(ui)$
  find("script")$
  filter(function(x, i) grepl("loading-overlay", as.character(x))) $
  remove()$
  allTags()

pagina <- tagList(
  tags$head(
    tags$title("Monitor de exposición del trabajo de las mujeres a la IA"),
    # Las fuentes y Font Awesome vienen de CDN; abrir la conexión desde el
    # inicio ahorra una ida y vuelta.
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "preconnect", href = "https://fonts.gstatic.com",
      crossorigin = NA
    ),
    tags$link(rel = "preconnect", href = "https://cdnjs.cloudflare.com"),
    tags$meta(
      name = "description",
      content = paste(
        "Exposición a la inteligencia artificial en el mercado laboral",
        "mexicano con perspectiva de género (ENOE, ENDUTIH y SINCO)."
      )
    ),
    # Los selectores de Shiny llevaban selectize; aquí son <select> normales
    tags$style(HTML("
      select.form-control {
        font-family: 'Ubuntu', sans-serif;
        font-size: 15px;
        height: 40px;
        border-radius: 8px;
        border: 1px solid #d2d0cd;
        background-color: #ffffff;
        color: #231f20;
      }
      .shiny-input-container label {
        font-weight: 500;
        color: #231f20;
      }
    "))
  ),
  ui,
  tags$script(src = "monitor.js"),
  # selectize lo inicializaba shiny.js; aquí los selectores son nativos
  suppressDependencies("selectize")
)

# --- Escritura de la salida -------------------------------------------------
setwd(ruta_raiz)
if (dir.exists(ruta_docs)) {
  unlink(ruta_docs, recursive = TRUE)
}
dir.create(file.path(ruta_docs, "datos", "treemap"), recursive = TRUE)
dir.create(file.path(ruta_docs, "datos", "paneles"), recursive = TRUE)

save_html(
  pagina,
  file = file.path(ruta_docs, "index.html"),
  libdir = "lib",
  background = "#F4F2FB",
  lang = "es"
)

# Las librerías (plotly.js pesa 3.5 MB, 1.1 MB comprimido) van en el <head>
# y, sin defer, el navegador no pinta nada hasta descargarlas y ejecutarlas.
# Con defer el hero y el texto aparecen de inmediato y las gráficas se
# dibujan en cuanto llega plotly. El orden de ejecución se conserva.
# htmlwidgets dibuja al DOMContentLoaded, que ocurre después de los scripts
# diferidos, así que nada cambia en el flujo de dibujo.
html_index <- readLines(file.path(ruta_docs, "index.html"), encoding = "UTF-8")
html_index <- sub('^<script src="', '<script defer src="', html_index)
# plotly.js es lo que más tarda en llegar y es lo que dibuja las gráficas;
# con fetchpriority el navegador lo baja antes que las fotos de las bandas,
# que están fuera de la pantalla inicial.
html_index <- sub(
  '^<script defer src="(lib/plotly-main[^"]+)"',
  '<script defer fetchpriority="high" src="\\1"',
  html_index
)
writeLines(
  html_index, file.path(ruta_docs, "index.html"), useBytes = TRUE
)

aviso_generado <- paste(
  "// Generado por 06_Sitio_estatico/construir_sitio.R.",
  "No editar a mano."
)

for (clave in names(variantes)) {
  nombre_archivo <- paste0(sub("|", "_", clave, fixed = TRUE), ".js")
  writeLines(
    c(
      aviso_generado,
      "window.TREEMAP_VARIANTES = window.TREEMAP_VARIANTES || {};",
      variantes[[clave]]
    ),
    file.path(ruta_docs, "datos", "treemap", nombre_archivo),
    useBytes = TRUE
  )
}

for (codigo in names(paneles)) {
  writeLines(
    c(
      aviso_generado,
      "window.PANELES = window.PANELES || {};",
      paste0(
        'window.PANELES["', codigo, '"] = ',
        toJSON(paneles[[codigo]], auto_unbox = TRUE), ";"
      )
    ),
    file.path(ruta_docs, "datos", "paneles", paste0(codigo, ".js")),
    useBytes = TRUE
  )
}

invisible(
  file.copy(file.path(ruta_sitio, "monitor.js"), ruta_docs, overwrite = TRUE)
)

# Logos e ilustraciones: todo www/ menos la foto de Unsplash sin uso
archivos_www <- list.files(file.path(ruta_app, "www"), full.names = TRUE)
archivos_www <- archivos_www[
  !grepl("unsplash", archivos_www, ignore.case = TRUE)
]
invisible(
  file.copy(archivos_www, ruta_docs, recursive = TRUE, overwrite = TRUE)
)

# Las fotos de las bandas son fondos de 220 px de alto; una de más de 300 KB
# (hoy normativa.jpg, 949 KB) se recomprime en la copia. El original de
# 04_Aplicación/www no se toca.
fotos_pesadas <- list.files(
  file.path(ruta_docs, "ilustraciones"), pattern = "\\.jpe?g$",
  full.names = TRUE
)
fotos_pesadas <- fotos_pesadas[file.info(fotos_pesadas)$size > 300 * 1024]
if (length(fotos_pesadas) > 0 && requireNamespace("magick", quietly = TRUE)) {
  for (foto in fotos_pesadas) {
    magick::image_read(foto) %>%
      magick::image_resize("1600x1600>") %>%
      magick::image_write(foto, format = "jpeg", quality = 72)
  }
  print(paste("Fotos recomprimidas:", length(fotos_pesadas)))
}

# .nojekyll evita que GitHub Pages ignore carpetas que empiezan con guion bajo
invisible(file.create(file.path(ruta_docs, ".nojekyll")))

# --- Resumen ----------------------------------------------------------------
tamanos <- file.info(
  list.files(ruta_docs, recursive = TRUE, full.names = TRUE)
)$size
print(paste0(
  "Sitio escrito en ", ruta_docs, ": ",
  length(tamanos), " archivos, ",
  round(sum(tamanos) / 1024^2, 1), " MB"
))
tamano_carpeta <- function(ruta) {
  archivos <- list.files(ruta, recursive = TRUE, full.names = TRUE)
  round(sum(file.info(archivos)$size) / 1024)
}
print(paste0(
  "index.html: ",
  round(file.info(file.path(ruta_docs, "index.html"))$size / 1024), " KB; ",
  "lib/: ", tamano_carpeta(file.path(ruta_docs, "lib")), " KB; ",
  "datos/treemap/: ",
  tamano_carpeta(file.path(ruta_docs, "datos", "treemap")), " KB en ",
  length(variantes), " archivos; ",
  "datos/paneles/: ",
  tamano_carpeta(file.path(ruta_docs, "datos", "paneles")), " KB en ",
  length(paneles), " archivos"
))
