# ------------------------------------------------------------------------------
# Proyecto:   Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026
# Objetivo:   Integrar al catálogo que consume la app
#             (04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv)
#             los scores y categorías PROVISIONALES propuestos en
#             01_Datos/ocupaciones_sin_score_ia_2026T1.csv:
#               - 68 ocupaciones reciben categoría, score y descripción
#                 (mapeo manual aprobado + imputación modal jerárquica),
#                 marcadas con la nueva columna clasificacion_provisional.
#               - 10 ocupaciones no imputables conservan su gris, pero
#                 reciben una descripción que explica el porqué.
#               - Se agregan 5 códigos de la actualización del SINCO que
#                 la ENOE reporta y que no existían en el catálogo.
#
#             El catálogo original queda recuperable en el historial de git.
#
# Fecha:      31 de julio de 2026
# ------------------------------------------------------------------------------

library(tidyverse)

archivo_catalogo <- "04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv"
archivo_grises <- "01_Datos/ocupaciones_sin_score_ia_2026T1.csv"

# 1. Insumos ----------------------------------------------------------------------

cat_1 <- read_csv(archivo_catalogo, show_col_types = FALSE) %>%
  mutate(unitario_4d = as.character(unitario_4d))

stopifnot(!"clasificacion_provisional" %in% names(cat_1))

grises <- read_csv(archivo_grises, show_col_types = FALSE) %>%
  mutate(sinco_4d = as.character(sinco_4d))

n_na_antes <- sum(is.na(cat_1$potencial_ia_2025))

# 2. Actualizar las ocupaciones que ya existen en el catálogo ----------------------

imputables <- grises %>%
  filter(metodo_provisional != "no_imputable",
         motivo_sin_score != "Código de la actualización del SINCO ausente del catálogo")

no_imputables <- grises %>%
  filter(metodo_provisional == "no_imputable")

cat_2 <- cat_1 %>%
  mutate(clasificacion_provisional = FALSE) %>%
  # Ocupaciones imputables: categoría, score, estado y descripción
  left_join(
    imputables %>%
      select(sinco_4d, categoria_provisional_en, score_provisional,
             metodo_provisional, descripcion_propuesta),
    by = c("unitario_4d" = "sinco_4d")
  ) %>%
  mutate(
    potencial_ia_2025 = coalesce(potencial_ia_2025,
                                 categoria_provisional_en),
    mean_score_ia_2025 = coalesce(mean_score_ia_2025, score_provisional),
    score_imputado = ifelse(!is.na(categoria_provisional_en),
                            TRUE, score_imputado),
    estado_score = ifelse(!is.na(categoria_provisional_en),
                          paste0("provisional_", metodo_provisional),
                          estado_score),
    descripcion_ia_es = ifelse(!is.na(categoria_provisional_en),
                               descripcion_propuesta, descripcion_ia_es),
    clasificacion_provisional = !is.na(categoria_provisional_en)
  ) %>%
  select(-categoria_provisional_en, -score_provisional,
         -metodo_provisional, -descripcion_propuesta) %>%
  # Ocupaciones no imputables: solo la descripción explicativa
  left_join(
    no_imputables %>% select(sinco_4d, descripcion_propuesta),
    by = c("unitario_4d" = "sinco_4d")
  ) %>%
  mutate(
    descripcion_ia_es = coalesce(descripcion_ia_es, descripcion_propuesta)
  ) %>%
  select(-descripcion_propuesta)

# 3. Agregar los códigos de la actualización del SINCO -----------------------------

nuevos <- grises %>%
  filter(motivo_sin_score ==
           "Código de la actualización del SINCO ausente del catálogo")

# La jerarquía (títulos de división, grupo y subgrupo) se toma de las filas
# ya existentes en el catálogo que comparten prefijo
jerarquia_2d <- cat_1 %>%
  mutate(prefijo_2d = str_sub(unitario_4d, 1, 2)) %>%
  distinct(prefijo_2d, grupo_principal_2d, grupo_principal_titulo)

jerarquia_3d <- cat_1 %>%
  mutate(prefijo_3d = str_sub(unitario_4d, 1, 3)) %>%
  distinct(prefijo_3d, subgrupo_3d, subgrupo_titulo)

jerarquia_1d <- cat_1 %>%
  distinct(division_1d, division_titulo)

filas_nuevas <- nuevos %>%
  transmute(
    unitario_4d = sinco_4d,
    unitario_titulo = titulo,
    division_1d,
    prefijo_2d = str_sub(sinco_4d, 1, 2),
    prefijo_3d = str_sub(sinco_4d, 1, 3),
    mean_score_ia_2025 = score_provisional,
    potencial_ia_2025 = categoria_provisional_en,
    score_imputado = TRUE,
    metodo_score = metodo_provisional,
    estado_score = paste0("provisional_", metodo_provisional),
    descripcion_ia_es = descripcion_propuesta,
    clasificacion_provisional = TRUE
  ) %>%
  left_join(jerarquia_1d, by = "division_1d") %>%
  left_join(jerarquia_2d, by = "prefijo_2d") %>%
  left_join(jerarquia_3d, by = "prefijo_3d") %>%
  select(-prefijo_2d, -prefijo_3d)

cat_final <- bind_rows(cat_2, filas_nuevas) %>%
  arrange(unitario_4d)

# 4. Validaciones y guardado --------------------------------------------------------

stopifnot(nrow(cat_final) == nrow(cat_1) + nrow(nuevos))
stopifnot(!any(duplicated(cat_final$unitario_4d)))

# Los títulos de la jerarquía de las filas nuevas deben haberse resuelto
stopifnot(
  !any(is.na(cat_final$subgrupo_3d[cat_final$unitario_4d %in%
                                     nuevos$sinco_4d]))
)

write_csv(cat_final, archivo_catalogo)

print(paste0("Catálogo actualizado: ", archivo_catalogo))
print(paste0("Filas: ", nrow(cat_1), " -> ", nrow(cat_final)))
print(paste0("Sin categoría (grises): ", n_na_antes, " -> ",
             sum(is.na(cat_final$potencial_ia_2025))))
print(paste0("Marcadas como provisionales: ",
             sum(cat_final$clasificacion_provisional)))
