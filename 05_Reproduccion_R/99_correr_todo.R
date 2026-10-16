# ------------------------------------------------------------------------------
# Corre el flujo completo en orden. Cada paso es un script independiente que
# se puede correr por separado; este archivo solo los encadena y se detiene
# si alguno falla.
#
# Uso:        Rscript 99_correr_todo.R
#             Rscript 99_correr_todo.R --sin-traduccion   (omite el paso 6 y
#             usa la caché de traducciones que ya exista)
# ------------------------------------------------------------------------------

dir_flujo <- dirname(sub("^--file=", "",
                         grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
omitir_traduccion <- "--sin-traduccion" %in% commandArgs(trailingOnly = TRUE)

pasos <- c(
  "01_puntuaciones_gmyrek.R",
  "02_estructura_sinco_2019.R",
  "03_crosswalk_sinco_ciuo.R",
  "04_catalogo_exposicion.R",
  "05_descripciones_en.R",
  "06_traducir_claude.R",
  "07_procesar_enoe.R",
  "08_provisionales_catalogo_app.R",
  "09_procesar_stem.R",
  "10_verificacion.R"
)
if (omitir_traduccion) pasos <- setdiff(pasos, "06_traducir_claude.R")

for (paso in pasos) {
  print(paste0("==== ", paso, " ===="))
  estado <- system2("Rscript", file.path(dir_flujo, paso))
  if (estado != 0) stop(paste0("Falló el paso ", paso))
}
print("Flujo completo.")
