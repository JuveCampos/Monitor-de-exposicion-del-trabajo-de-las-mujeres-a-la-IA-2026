# ------------------------------------------------------------------------------
# Proyecto:   Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026
# Carpeta:    05_Reproduccion_R (flujo completo desde cero, todo en R)
# Objetivo:   Centralizar rutas, parámetros y catálogos de etiquetas que usan
#             todos los scripts del flujo. Cada script empieza con
#             source("00_configuracion.R"), así que este es el único lugar
#             donde hay que cambiar el trimestre o la ruta del disco externo.
#
# Autor:      Jorge Juvenal Campos Ferreira
# Fecha:      16 de octubre de 2026
# ------------------------------------------------------------------------------

library(tidyverse)

# 0. Ubicación de la carpeta del flujo ------------------------------------------

# Se localiza la carpeta de este archivo sin importar desde dónde se corra
# Rscript (raíz del repositorio o la propia carpeta 05_Reproduccion_R)
localizar_dir_flujo <- function() {
  arg_file <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arg_file) > 0) {
    return(normalizePath(dirname(sub("^--file=", "", arg_file[1]))))
  }
  if (file.exists("00_configuracion.R")) return(normalizePath(getwd()))
  if (file.exists("05_Reproduccion_R/00_configuracion.R")) {
    return(normalizePath("05_Reproduccion_R"))
  }
  stop("No se encontró la carpeta 05_Reproduccion_R")
}

dir_flujo <- localizar_dir_flujo()
dir_repo <- dirname(dir_flujo)
dir_insumos <- file.path(dir_flujo, "insumos")
dir_salidas <- file.path(dir_flujo, "salidas")
dir.create(dir_salidas, showWarnings = FALSE)

# 1. Parámetros del trimestre -----------------------------------------------------

# Trimestre que alimenta la aplicación. Los scripts 07 y 09 aceptan año y
# trimestre como argumentos de línea de comandos; si no se pasan, usan estos
anio_enoe <- 2026
trim_enoe <- 2

# Carpeta con los microdatos DBF de la ENOE (descarga del INEGI). Dentro debe
# existir una subcarpeta por trimestre: enoe_{año}_trim{trim}_dbf/
dir_dbf_enoe <- Sys.getenv(
  "DIR_DBF_ENOE",
  unset = "/Volumes/Extreme SSD/DATASETS/INEGI - ENOE/dbf"
)

# Modelo de Claude para las traducciones (paso 6). Se llama con la interfaz de
# línea de comandos de Claude Code (`claude -p`), que usa la suscripción del
# usuario; no hace falta clave de API. "sonnet" es rápido y suficiente para
# traducir; "opus" da traducciones más cuidadas a mayor costo
modelo_claude <- Sys.getenv("MODELO_CLAUDE", unset = "sonnet")

# 2. Insumos externos (ya están en el repositorio) --------------------------------

# Puntuaciones de exposición por tarea de Gmyrek, Berg y Kucera (2025), OIT
archivo_gmyrek <- file.path(
  dir_repo, "01_Datos", "01_catalogos", "datasets",
  "Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx"
)

# Tablas comparativas del INEGI (SINCO 2011 a CIUO-08, actualización de
# noviembre de 2012). Hoja "SINCO-CIUO"
archivo_tablas_inegi <- file.path(
  dir_repo, "01_Datos", "01_catalogos", "sinco_tablas_comparativas.xlsx"
)

# Documento del SINCO 2019 (INEGI). Su anexo trae la tabla de equivalencia
# SINCO 2011 a 2019, que permite llevar la correspondencia CIUO-08 de 2011 a
# los códigos que usa la ENOE
archivo_sinco_2019_pdf <- file.path(
  dir_repo, "01_Datos", "02_sinco", "SINCO_2019.pdf"
)

# Clasificaciones de la ENOE (INEGI, edición 2023). Trae la estructura
# completa del SINCO 2019 tal como la codifica la encuesta (490 grupos
# unitarios). Copiado a insumos/ desde
# https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/doc/clasificaciones_enoe_123.pdf
archivo_enoe_clasificaciones_pdf <- file.path(
  dir_insumos, "INEGI_ENOE_clasificaciones_2023.pdf"
)

# Propuestas de CIUO-08 análogo para ocupaciones que no tienen correspondencia
# ni por la tabla 2011 ni por la equivalencia 2019. Es el único insumo que
# depende de un criterio del equipo; la columna `aprobado` se llena a mano
archivo_mapeo_manual <- file.path(dir_insumos, "mapeo_manual_ciuo.csv")

# 3. Salidas intermedias (nombres fijos para encadenar los scripts) --------------

archivo_gmyrek_ciuo <- file.path(dir_salidas, "01_gmyrek_2025_ciuo4d.csv")
archivo_sinco_estructura <- file.path(dir_salidas, "02_sinco_2019_estructura.csv")
archivo_equivalencia <- file.path(dir_salidas, "02_equivalencia_sinco_2019_2011.csv")
archivo_crosswalk_2011 <- file.path(dir_salidas, "03_crosswalk_sinco2011_ciuo08.csv")
archivo_crosswalk_2019 <- file.path(dir_salidas, "03_crosswalk_sinco2019_ciuo08.csv")
archivo_catalogo <- file.path(dir_salidas, "04_catalogo_exposicion_ia.csv")
archivo_descripciones_en <- file.path(dir_salidas, "05_descripciones_en.csv")
archivo_traducciones_cache <- file.path(dir_salidas, "06_traducciones_claude_cache.csv")
archivo_descripciones_es <- file.path(dir_salidas, "06_descripciones_es.csv")
archivo_catalogo_app <- file.path(dir_salidas, "08_catalogo_app.csv")
dir_enoe_salidas <- file.path(dir_salidas, "enoe")
dir.create(dir_enoe_salidas, showWarnings = FALSE)

# 4. Etiquetas compartidas -------------------------------------------------------

# Categorías de exposición de Gmyrek et al. (2025), de menor a mayor
orden_categorias <- c(
  "Not Exposed", "Minimal Exposure", "Mixto",
  "Exposed: Gradient 1", "Exposed: Gradient 2",
  "Exposed: Gradient 3", "Exposed: Gradient 4"
)

traduccion_exposicion <- c(
  "Not Exposed"          = "No expuesto",
  "Minimal Exposure"     = "Exposición mínima",
  "Mixto"                = "Mixto",
  "Exposed: Gradient 1"  = "Exposición baja, alta variabilidad de tareas",
  "Exposed: Gradient 2"  = "Exposición moderada, alta variabilidad de tareas",
  "Exposed: Gradient 3"  = "Exposición significativa, alta variabilidad de tareas",
  "Exposed: Gradient 4"  = "Exposición máxima, baja variabilidad de tareas"
)

# Códigos que la ENOE usa pero que no son ocupaciones evaluables
codigos_operativos_enoe <- c("0980", "1006", "1008")
codigo_no_especificado <- "9999"

# Grandes grupos militares de la CIUO-08 (fuera del índice de la OIT)
ciuo_militares <- c("0110", "0210", "0310")

# 5. Utilidades -------------------------------------------------------------------

# Mediana ponderada con pesos de frecuencia (equivale a collapse (median)
# [fw=] de Stata): se ordena x, se acumulan los pesos y se toma el valor donde
# la suma acumulada cruza la mitad del total
mediana_ponderada <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]
  w <- w[ok]
  if (length(x) == 0) return(NA_real_)
  orden <- order(x)
  x <- x[orden]
  w <- w[orden]
  acumulado <- cumsum(w)
  mitad <- sum(w) / 2
  i <- which(acumulado >= mitad)[1]
  if (isTRUE(all.equal(acumulado[i], mitad)) && i < length(x)) {
    (x[i] + x[i + 1]) / 2
  } else {
    x[i]
  }
}

print(paste0("Flujo en: ", dir_flujo))
