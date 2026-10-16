# Redespliegue del Monitor a shinyapps.io
#
# Se corre desde la carpeta 04_Aplicación con:
#   Rscript deploy.R
# o, desde RStudio, abriendo proyecto_dashboard.Rproj y ejecutando el script
# completo.
#
# El script verifica primero que todo esté en su lugar y luego sube la
# aplicación. Si alguna verificación falla, se detiene antes de desplegar.

library(rsconnect)

# --- Parámetros del despliegue ------------------------------------------------

cuenta <- "juvecamposf"
nombre_app <- "dataton_genero_2026_exposicion_ia_trabajos"

# Lista explícita de archivos que suben. Todo lo que no esté aquí se queda
# fuera: assets/ (no se usa en la app), la foto suelta de Unsplash, el
# catálogo sinco_con_exposicion_ia.csv (copia sin uso directo), CLAUDE.md,
# el .Rproj y los archivos ocultos. Actualizar esta lista cuando app.R lea
# un archivo nuevo.
archivos_app <- c(
  "app.R",
  # Datos de la ENOE del trimestre vigente (general y bloque STEM)
  "zcalculos_Y2026T02_4d.dta",
  "zcalculos_Y2026T02_4d_stem.dta",
  "zcalculos_Y2026T02_stem_campos.dta",
  # Catálogo de exposición y tareas por ocupación (05_Reproduccion_R)
  "catalogos_sinco/sinco_con_exposicion_ia_es.csv",
  "catalogos_sinco/tareas_por_ocupacion.csv",
  # Logos y encabezado del sitio de MCV
  "www/artboard_1.png.webp",
  "www/clave_logo.png",
  "www/logo_mcv.svg",
  "www/logo_mcv_blanco.svg",
  "www/logo_mcv_hall.svg",
  "www/mcv_cintilla.png",
  # Fotos de las bandas de sección (ver www/ilustraciones/CREDITOS.md)
  "www/ilustraciones/hero.jpg",
  "www/ilustraciones/exposicion.jpg",
  "www/ilustraciones/cuidados.jpg",
  "www/ilustraciones/brecha.jpg",
  "www/ilustraciones/normativa.jpg"
)

# --- Verificaciones previas ---------------------------------------------------

# La ruta de trabajo debe ser la carpeta de la aplicación.
stopifnot(
  "Hay que correr el script desde 04_Aplicación" = file.exists("app.R")
)

# Todos los archivos de la lista deben existir.
faltantes <- archivos_app[!file.exists(archivos_app)]
if (length(faltantes) > 0) {
  stop("Faltan archivos del despliegue: ", paste(faltantes, collapse = ", "))
}

# app.R debe parsear. Esto no garantiza que la app corra, pero atrapa el error
# más común después de editar el archivo a mano.
parse("app.R")

# La cuenta de shinyapps.io debe estar configurada en esta máquina.
cuentas_registradas <- rsconnect::accounts()$name
if (!cuenta %in% cuentas_registradas) {
  stop("La cuenta ", cuenta, " no está configurada. Corre primero ",
       "rsconnect::setAccountInfo() con el token de shinyapps.io.")
}

# Aviso del trimestre que quedará publicado, para detectar a tiempo un .dta
# equivocado. Se leen las dos variables que app.R define al inicio y se
# verifica que apunten al mismo trimestre.
lineas_app <- readLines("app.R", encoding = "UTF-8")
periodo_declarado <- sub('.*"(.*)".*', "\\1",
                         grep("^periodo_enoe <-", lineas_app, value = TRUE)[1])
archivo_declarado <- sub('.*"(.*)".*', "\\1",
                         grep("^archivo_enoe <-", lineas_app, value = TRUE)[1])

# "2026-T2" debe corresponder con "Y2026T02" del nombre del archivo.
periodo_esperado <- sub("^.*Y(\\d{4})T0?(\\d).*$", "\\1-T\\2",
                        archivo_declarado)
if (!identical(periodo_declarado, periodo_esperado)) {
  stop("La etiqueta del periodo (", periodo_declarado, ") no coincide con el ",
       "archivo de datos (", archivo_declarado, ").")
}

print(paste0("Trimestre que se publicará: ENOE ", periodo_declarado,
             " (", archivo_declarado, ")"))

peso_mb <- round(sum(file.size(archivos_app)) / 1024^2, 2)
print(paste0("Archivos: ", length(archivos_app), " | Peso total: ",
             peso_mb, " MB"))

# --- Despliegue ---------------------------------------------------------------

rsconnect::deployApp(
  appDir = ".",
  appFiles = archivos_app,
  appName = nombre_app,
  account = cuenta,
  server = "shinyapps.io",
  # Se conserva el nombre visible que ya tiene la aplicación en línea.
  appTitle = nombre_app,
  forceUpdate = TRUE,
  launch.browser = FALSE
)

# --- Comprobación posterior ---------------------------------------------------

# Después de que termine, conviene abrir la liga y confirmar que el encabezado
# se ve morado (#6950d8) con letras blancas. Si sigue en lila claro, el
# navegador está sirviendo la versión anterior desde caché: recargar con
# Cmd + Shift + R.
print(paste0("Listo. Revisa https://", cuenta, ".shinyapps.io/",
             nombre_app, "/"))
