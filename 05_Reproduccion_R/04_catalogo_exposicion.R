# ------------------------------------------------------------------------------
# Paso 4:     Catálogo SINCO 2019 con exposición a la IA generativa.
#
#             Para cada grupo unitario del SINCO se reúnen las CIUO-08
#             correspondientes (paso 3) y sus puntuaciones (paso 1):
#             - mean_score_ia_2025: promedio simple de las puntuaciones medias
#               de las CIUO correspondientes; score_minimo y score_maximo.
#             - potencial_ia_2025: la categoría de la CIUO si todas coinciden;
#               "Mixto" si las CIUO correspondientes caen en categorías
#               distintas (ver 03_Archivos/sensibilidad_mixto_2026T2.md).
#             - estado_score: por qué una ocupación no tiene puntuación
#               (códigos operativos, militares, no especificado, CIUO sin
#               evaluar en Gmyrek et al., sin correspondencia).
#             - Capa de imputación: las categorías residuales ("Otros ... no
#               clasificados") y los supervisores sin puntuación reciben el
#               promedio del subgrupo 3d (o del grupo 2d, o de la división 1d)
#               con la marca score_imputado = TRUE y metodo_score.
#
# Entradas:   salidas/02_sinco_2019_estructura.csv
#             salidas/03_crosswalk_sinco2019_ciuo08.csv
#             salidas/01_gmyrek_2025_ciuo4d.csv
# Salida:     salidas/04_catalogo_exposicion_ia.csv
#
# Uso:        Rscript 04_catalogo_exposicion.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))

estructura <- read_csv(archivo_sinco_estructura, col_types = cols(.default = "c"))
crosswalk <- read_csv(archivo_crosswalk_2019, col_types = cols(.default = "c"))
gmyrek <- read_csv(archivo_gmyrek_ciuo, col_types = cols(.default = "c")) %>%
  transmute(
    ciuo_4d = ISCO_08,
    ciuo_titulo_gmyrek = Title,
    mean_score_2025 = as.numeric(mean_score_2025),
    potential25
  )

# 1. Puntuación por grupo unitario ---------------------------------------------

pares <- crosswalk %>%
  filter(!is.na(ciuo_4d)) %>%
  left_join(gmyrek, by = "ciuo_4d")

resumen_ciuo <- pares %>%
  group_by(sinco_2019) %>%
  summarise(
    sinco_2011 = first(sinco_2011),
    ciuo08_4d_correspondientes = paste(ciuo_4d, collapse = ";"),
    n_ciuo_correspondencias = n(),
    n_ciuo_con_score = sum(!is.na(mean_score_2025)),
    mean_score_ia_2025 = ifelse(
      n_ciuo_con_score > 0, round(mean(mean_score_2025, na.rm = TRUE), 4), NA
    ),
    score_minimo = ifelse(
      n_ciuo_con_score > 0, round(min(mean_score_2025, na.rm = TRUE), 4), NA
    ),
    score_maximo = ifelse(
      n_ciuo_con_score > 0, round(max(mean_score_2025, na.rm = TRUE), 4), NA
    ),
    n_categorias = n_distinct(potential25[!is.na(potential25)]),
    potencial_ia_2025 = case_when(
      n_categorias == 1 ~ first(potential25[!is.na(potential25)]),
      n_categorias > 1 ~ "Mixto",
      TRUE ~ NA_character_
    ),
    ciuo_heredado_3d = all(origen == "heredado_3d"),
    via_equivalencia_2011 = any(via_equivalencia == "TRUE"),
    alguna_ciuo_militar = any(ciuo_4d %in% ciuo_militares),
    .groups = "drop"
  ) %>%
  select(-n_categorias)

# Grupos sin ninguna CIUO (huérfanos explícitos, sin CIUO en la tabla o nuevos
# en 2019) conservan su origen para diagnosticar
origen_sin_ciuo <- crosswalk %>%
  filter(is.na(ciuo_4d)) %>%
  distinct(sinco_2019, sinco_2011, origen_sin_ciuo = origen)

catalogo <- estructura %>%
  left_join(resumen_ciuo, by = c("unitario_4d" = "sinco_2019")) %>%
  left_join(origen_sin_ciuo %>% select(-sinco_2011),
            by = c("unitario_4d" = "sinco_2019")) %>%
  left_join(origen_sin_ciuo %>% select(sinco_2019, sinco_2011_b = sinco_2011),
            by = c("unitario_4d" = "sinco_2019")) %>%
  mutate(
    sinco_2011 = coalesce(sinco_2011, sinco_2011_b),
    n_ciuo_correspondencias = replace_na(n_ciuo_correspondencias, 0L),
    n_ciuo_con_score = replace_na(n_ciuo_con_score, 0L),
    ciuo_heredado_3d = replace_na(ciuo_heredado_3d, FALSE),
    via_equivalencia_2011 = replace_na(via_equivalencia_2011, FALSE),
    alguna_ciuo_militar = replace_na(alguna_ciuo_militar, FALSE),
    score_imputado = FALSE,
    metodo_score = case_when(
      is.na(mean_score_ia_2025) ~ NA_character_,
      ciuo_heredado_3d ~ "directo_heredado_3d",
      TRUE ~ "directo"
    ),
    estado_score = case_when(
      !is.na(mean_score_ia_2025) ~ "disponible",
      unitario_4d %in% codigos_operativos_enoe ~ "no_aplica_enoe",
      unitario_4d == codigo_no_especificado ~ "no_aplica_no_especificado",
      alguna_ciuo_militar ~ "no_aplica_militar",
      n_ciuo_correspondencias > 0 & n_ciuo_con_score == 0 ~ "gmyrek_sin_evaluar",
      origen_sin_ciuo == "nuevo_en_2019_sin_tabla" ~ "sin_correspondencia_nuevo_2019",
      TRUE ~ "sin_correspondencia_ciuo"
    )
  ) %>%
  select(-sinco_2011_b, -alguna_ciuo_militar)

print("Estado antes de la imputación:")
print(catalogo %>% count(estado_score))

# 2. Imputación por promedio del nivel superior ---------------------------------

es_residual <- function(titulo) {
  t <- str_to_lower(titulo)
  str_detect(t, "no clasificad") | str_starts(t, "otros ") | str_starts(t, "otras ")
}
es_supervisor <- function(titulo) {
  str_starts(str_to_lower(titulo), "supervisores")
}

# Promedios con las puntuaciones directas (antes de imputar) por nivel
pool_por <- function(nivel) {
  catalogo %>%
    filter(!is.na(mean_score_ia_2025)) %>%
    group_by(clave = .data[[nivel]]) %>%
    summarise(
      pool_media = round(mean(mean_score_ia_2025), 4),
      pool_min = round(min(mean_score_ia_2025), 4),
      pool_max = round(max(mean_score_ia_2025), 4),
      pool_n = n(),
      .groups = "drop"
    )
}
pool_3d <- pool_por("subgrupo_3d")
pool_2d <- pool_por("grupo_principal_2d")
pool_1d <- pool_por("division_1d")

candidatas <- catalogo %>%
  filter(
    is.na(mean_score_ia_2025),
    !estado_score %in% c("no_aplica_enoe", "no_aplica_no_especificado",
                         "no_aplica_militar"),
    es_residual(unitario_titulo) | es_supervisor(unitario_titulo)
  ) %>%
  select(unitario_4d, division_1d, grupo_principal_2d, subgrupo_3d) %>%
  left_join(pool_3d %>% rename_with(~ paste0(.x, "_3d"), -clave),
            by = c("subgrupo_3d" = "clave")) %>%
  left_join(pool_2d %>% rename_with(~ paste0(.x, "_2d"), -clave),
            by = c("grupo_principal_2d" = "clave")) %>%
  left_join(pool_1d %>% rename_with(~ paste0(.x, "_1d"), -clave),
            by = c("division_1d" = "clave")) %>%
  mutate(
    nivel_imp = case_when(
      !is.na(pool_media_3d) ~ "3d",
      !is.na(pool_media_2d) ~ "2d",
      !is.na(pool_media_1d) ~ "1d",
      TRUE ~ NA_character_
    ),
    imp_media = case_when(nivel_imp == "3d" ~ pool_media_3d,
                          nivel_imp == "2d" ~ pool_media_2d,
                          nivel_imp == "1d" ~ pool_media_1d),
    imp_min = case_when(nivel_imp == "3d" ~ pool_min_3d,
                        nivel_imp == "2d" ~ pool_min_2d,
                        nivel_imp == "1d" ~ pool_min_1d),
    imp_max = case_when(nivel_imp == "3d" ~ pool_max_3d,
                        nivel_imp == "2d" ~ pool_max_2d,
                        nivel_imp == "1d" ~ pool_max_1d),
    imp_n = case_when(nivel_imp == "3d" ~ pool_n_3d,
                      nivel_imp == "2d" ~ pool_n_2d,
                      nivel_imp == "1d" ~ pool_n_1d)
  ) %>%
  filter(!is.na(nivel_imp)) %>%
  select(unitario_4d, nivel_imp, imp_media, imp_min, imp_max, imp_n)

catalogo <- catalogo %>%
  left_join(candidatas, by = "unitario_4d") %>%
  mutate(
    mean_score_ia_2025 = coalesce(mean_score_ia_2025, imp_media),
    score_minimo = coalesce(score_minimo, imp_min),
    score_maximo = coalesce(score_maximo, imp_max),
    score_imputado = !is.na(nivel_imp),
    metodo_score = ifelse(
      score_imputado, paste0("imputacion_", nivel_imp, " (n=", imp_n, ")"),
      metodo_score
    ),
    estado_score = ifelse(score_imputado, paste0("imputado_", nivel_imp),
                          estado_score)
  ) %>%
  select(-nivel_imp, -imp_media, -imp_min, -imp_max, -imp_n) %>%
  select(division_1d, division_titulo, grupo_principal_2d,
         grupo_principal_titulo, subgrupo_3d, subgrupo_titulo, unitario_4d,
         unitario_titulo, sinco_2011, via_equivalencia_2011,
         ciuo08_4d_correspondientes, n_ciuo_correspondencias,
         mean_score_ia_2025, potencial_ia_2025, score_minimo, score_maximo,
         ciuo_heredado_3d, score_imputado, metodo_score, estado_score) %>%
  arrange(unitario_4d)

print("Estado después de la imputación:")
print(catalogo %>% count(estado_score))
print(catalogo %>% count(potencial_ia_2025))

stopifnot(nrow(catalogo) == nrow(estructura), !any(duplicated(catalogo$unitario_4d)))
write_csv(catalogo, archivo_catalogo, na = "")
print(paste0("Escrito: ", archivo_catalogo))
