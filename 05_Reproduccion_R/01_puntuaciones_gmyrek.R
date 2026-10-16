# ------------------------------------------------------------------------------
# Paso 1:     Puntuaciones de exposición a la IA generativa por ocupación
#             CIUO-08 (4 dígitos), a partir del archivo a nivel tarea de
#             Gmyrek, Berg y Kucera (2025), OIT, Working Paper 140.
#
# Entrada:    Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx (hoja Sheet1, una
#             fila por tarea; las columnas por ocupación vienen repetidas en
#             cada tarea).
# Salida:     salidas/01_gmyrek_2025_ciuo4d.csv (una fila por CIUO-08 4d)
#
# Uso:        Rscript 01_puntuaciones_gmyrek.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(readxl)

# 1. Lectura del archivo a nivel tarea ------------------------------------------

tareas <- read_excel(archivo_gmyrek, sheet = "Sheet1") %>%
  mutate(ISCO_08 = str_pad(as.character(ISCO_08), 4, "left", "0"))

print(paste0("Tareas leídas: ", nrow(tareas)))

# 2. Colapso a una fila por ocupación --------------------------------------------

# Las columnas de ocupación (mean_score_2025, SD_2025, potential25 y sus
# equivalentes de 2023) se repiten en cada tarea. Se verifica que no haya
# valores contradictorios dentro de una misma ocupación antes de colapsar
contradicciones <- tareas %>%
  group_by(ISCO_08) %>%
  summarise(
    n_mean = n_distinct(mean_score_2025),
    n_sd = n_distinct(SD_2025),
    n_pot = n_distinct(potential25),
    .groups = "drop"
  ) %>%
  filter(n_mean > 1 | n_sd > 1 | n_pot > 1)

stopifnot(nrow(contradicciones) == 0)

gmyrek_ciuo <- tareas %>%
  group_by(ISCO_08) %>%
  summarise(
    Title = first(Title),
    mean_score_2023 = first(mean_score_2023),
    mean_score_2025 = first(mean_score_2025),
    SD_2023 = first(SD_2023),
    SD_2025 = first(SD_2025),
    potential25 = first(potential25),
    potential23 = first(potential23),
    n_tareas = n(),
    .groups = "drop"
  ) %>%
  arrange(ISCO_08)

# 3. Validaciones y guardado -------------------------------------------------------

stopifnot(!any(duplicated(gmyrek_ciuo$ISCO_08)))
stopifnot(all(gmyrek_ciuo$potential25[!is.na(gmyrek_ciuo$potential25)] %in%
                orden_categorias))

write_csv(gmyrek_ciuo, archivo_gmyrek_ciuo, na = "")

print(paste0("Ocupaciones CIUO-08: ", nrow(gmyrek_ciuo),
             " (con categoría 2025: ", sum(!is.na(gmyrek_ciuo$potential25)),
             ")"))
print(gmyrek_ciuo %>% count(potential25))
print(paste0("Escrito: ", archivo_gmyrek_ciuo))
