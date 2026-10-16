# ------------------------------------------------------------------------------
# Paso 5:     Tareas evaluadas y descripción en inglés por grupo unitario.
#
#             Del archivo a nivel tarea de Gmyrek et al. (2025) se toman, para
#             cada grupo unitario SINCO, las tareas de sus CIUO-08
#             correspondientes con su puntuación 2025 y la justificación del
#             modelo. Se guardan en formato largo (una fila por tarea) para
#             que la aplicación pueda mostrarlas como tabla o lista, y además
#             se arma un resumen en inglés por ocupación.
#
# Entradas:   Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx
#             salidas/04_catalogo_exposicion_ia.csv
# Salidas:    salidas/05_tareas_por_ocupacion.csv (formato largo)
#             salidas/05_descripciones_en.csv (resumen por ocupación)
#
# Uso:        Rscript 05_descripciones_en.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(readxl)

# 1. Tareas por CIUO-08 -----------------------------------------------------------

tareas_ciuo <- read_excel(archivo_gmyrek, sheet = "Sheet1") %>%
  transmute(
    ciuo_4d = str_pad(as.character(ISCO_08), 4, "left", "0"),
    ciuo_titulo_en = str_squish(Title),
    # El taskID del archivo se numera dentro de cada ocupación; la llave única
    # de una tarea es CIUO + taskID
    tarea_id = paste0(str_pad(as.character(ISCO_08), 4, "left", "0"), "_",
                      as.character(taskID)),
    tarea_en = str_remove(str_squish(Task_ISCO), ";$"),
    score_tarea_2025 = as.numeric(score_2025),
    justificacion_en = str_squish(coalesce(prediction_justification_gpt4o, ""))
  ) %>%
  filter(!is.na(score_tarea_2025))

print(paste0("Tareas con puntuación: ", nrow(tareas_ciuo), " en ",
             n_distinct(tareas_ciuo$ciuo_4d), " CIUO-08"))

# 2. Tareas por grupo unitario SINCO ---------------------------------------------

catalogo <- read_csv(archivo_catalogo, col_types = cols(.default = "c"))

tareas_sinco <- catalogo %>%
  filter(!is.na(ciuo08_4d_correspondientes)) %>%
  select(unitario_4d, unitario_titulo, ciuo08_4d_correspondientes) %>%
  separate_longer_delim(ciuo08_4d_correspondientes, delim = ";") %>%
  rename(ciuo_4d = ciuo08_4d_correspondientes) %>%
  inner_join(tareas_ciuo, by = "ciuo_4d", relationship = "many-to-many") %>%
  arrange(unitario_4d, desc(score_tarea_2025)) %>%
  group_by(unitario_4d) %>%
  mutate(orden_tarea = row_number()) %>%
  ungroup()

write_csv(tareas_sinco, file.path(dir_salidas, "05_tareas_por_ocupacion.csv"),
          na = "")

# 3. Resumen en inglés por ocupación ---------------------------------------------

# El texto replica el formato que la app ha mostrado hasta ahora (ocupaciones
# CIUO, número de tareas, tarea más expuesta con su justificación y lista de
# tareas con puntuación), para poder comparar con el catálogo vigente
descripciones <- tareas_sinco %>%
  group_by(unitario_4d, unitario_titulo) %>%
  summarise(
    ciuo_titulos_en = paste(unique(ciuo_titulo_en), collapse = "; "),
    n_tareas = n(),
    tarea_top_en = first(tarea_en),
    score_top = first(score_tarea_2025),
    justificacion_top_en = first(justificacion_en),
    lista_tareas_en = paste0(
      str_sub(tarea_en, 1, 80), " (", sprintf("%.2f", score_tarea_2025), ")",
      collapse = "; "
    ),
    .groups = "drop"
  ) %>%
  mutate(
    descripcion_en = paste0(
      "ISCO-08 occupation(s): ", ciuo_titulos_en, ". ",
      "This occupation has ", n_tareas, " evaluated tasks. ",
      "Most exposed task: \"", tarea_top_en, "\" (score ",
      sprintf("%.2f", score_top), "). ", justificacion_top_en, " ",
      "All tasks with scores: ", lista_tareas_en, "."
    )
  )

descripciones <- catalogo %>%
  select(unitario_4d, unitario_titulo) %>%
  left_join(descripciones %>% select(-unitario_titulo), by = "unitario_4d") %>%
  mutate(n_tareas = replace_na(n_tareas, 0L))

print(paste0("Ocupaciones con descripción: ", sum(descripciones$n_tareas > 0),
             " de ", nrow(descripciones)))
write_csv(descripciones, archivo_descripciones_en, na = "")
print(paste0("Escrito: ", archivo_descripciones_en))
