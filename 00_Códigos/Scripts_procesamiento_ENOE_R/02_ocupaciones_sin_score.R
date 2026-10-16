# ------------------------------------------------------------------------------
# Proyecto:   Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026
# Objetivo:   Generar el catálogo de ocupaciones que aparecen en gris en la app
#             ("Sin información": sin score de exposición de Gmyrek et al. 2025)
#             y proponer un score/categoría PROVISIONAL para las que sí se
#             pueden imputar.
#
# Métodos de propuesta provisional (columna metodo_provisional):
#   - mapeo_manual_propuesto: ya existe una propuesta revisable en
#     01_Datos/01_catalogos/mapeo_manual_propuesto.csv (CIUO análogo + score),
#     pendiente de aprobación del equipo.
#   - imputacion_modal_3d/2d/1d: categoría modal entre las ocupaciones
#     hermanas ya clasificadas del mismo subgrupo (3d), grupo (2d) o división
#     (1d); el score provisional es el promedio de las hermanas (o el score
#     ya imputado en el catálogo, si existe). En caso de empate se toma la
#     categoría de menor exposición (criterio conservador).
#   - no_imputable: fuera del universo del índice de la OIT (ocupaciones
#     militares, códigos operativos de la ENOE como "no trabaja" o
#     "trabajadores en otro país", y "no especificado").
#
# Salida:     01_Datos/ocupaciones_sin_score_ia_2026T1.csv
# Fecha:      31 de julio de 2026
# ------------------------------------------------------------------------------

library(tidyverse)
library(haven)

# 0. Parámetros -----------------------------------------------------------------

archivo_enoe <- "04_Aplicación/zcalculos_Y2026T01_4d.dta"
periodo <- "2026T1"
archivo_salida <- paste0("01_Datos/ocupaciones_sin_score_ia_", periodo, ".csv")

# Títulos de códigos de la actualización del SINCO usados por la ENOE que no
# existen en los catálogos locales (fuente: INEGI, Clasificaciones ENOE,
# clasificaciones_enoe_123.pdf)
titulos_enoe_extra <- tribble(
  ~unitario_4d, ~unitario_titulo,
  "2134", "Geógrafos",
  "2141", "Investigadores y profesionistas en filosofía y letras (filólogos)",
  "2649", paste0("Otros técnicos eléctricos, en electrónica y de equipos en ",
                 "telecomunicaciones y electromecánicos, no clasificados ",
                 "anteriormente"),
  "9332", "Cargadores por propina",
  "9732", "Recolectores de dinero"
)

# Orden de severidad de las categorías (para el criterio conservador)
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

# 1. Insumos ----------------------------------------------------------------------

cat_1 <- read_csv(
  "04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv",
  show_col_types = FALSE
) %>%
  mutate(
    unitario_4d = as.character(unitario_4d),
    subgrupo_3d = str_pad(subgrupo_3d, 3, "left", "0")
  )

mapeo <- read_csv(
  "01_Datos/01_catalogos/mapeo_manual_propuesto.csv",
  show_col_types = FALSE
) %>%
  mutate(sinco_4d = as.character(sinco_4d))

jerarquico <- read_csv(
  "01_Datos/01_catalogos/sinco_2019_jerarquico.csv",
  show_col_types = FALSE
) %>%
  mutate(subgrupo_3d = str_pad(subgrupo_3d, 3, "left", "0")) %>%
  select(division_1d, division_titulo, subgrupo_3d, subgrupo_titulo) %>%
  unique()

# Población ocupada del trimestre por sexo (formato ancho)
poblacion <- read_dta(archivo_enoe) %>%
  mutate(unitario_4d = as.character(sinco4d)) %>%
  select(unitario_4d, sex, ocup) %>%
  pivot_wider(
    names_from = sex, values_from = ocup,
    names_prefix = "ocup_sex"
  ) %>%
  rename(
    ocup_total = ocup_sex0,
    ocup_hombres = ocup_sex1,
    ocup_mujeres = ocup_sex2
  )

# 2. Universo de ocupaciones grises ------------------------------------------------

# a) En el catálogo pero sin categoría de exposición
gris_catalogo <- cat_1 %>%
  filter(is.na(potencial_ia_2025)) %>%
  select(
    unitario_4d, unitario_titulo, division_1d, division_titulo,
    subgrupo_3d, mean_score_ia_2025, estado_score, metodo_score
  )

# b) Códigos reportados por la ENOE que no existen en el catálogo
gris_fuera <- titulos_enoe_extra %>%
  mutate(
    division_1d = as.numeric(str_sub(unitario_4d, 1, 1)),
    subgrupo_3d = str_sub(unitario_4d, 1, 3),
    mean_score_ia_2025 = NA_real_,
    estado_score = "fuera_de_catalogo",
    metodo_score = NA_character_
  ) %>%
  left_join(
    jerarquico %>% select(division_1d, division_titulo) %>% unique(),
    by = "division_1d"
  )

grises <- bind_rows(gris_catalogo, gris_fuera)

# 3. Propuesta provisional ----------------------------------------------------------

# Ocupaciones ya clasificadas (base para la imputación modal jerárquica)
clasificadas <- cat_1 %>%
  filter(!is.na(potencial_ia_2025)) %>%
  mutate(
    grupo_2d = str_sub(unitario_4d, 1, 2),
    division_chr = str_sub(unitario_4d, 1, 1)
  )

# Categoría modal entre hermanas; empate -> menor exposición (conservador)
categoria_modal <- function(categorias) {
  conteo <- table(categorias)
  ganadoras <- names(conteo)[conteo == max(conteo)]
  ganadoras[which.min(match(ganadoras, orden_categorias))]
}

# Imputación jerárquica: subgrupo 3d -> grupo 2d -> división 1d; se exige un
# mínimo de 2 hermanas clasificadas por nivel para usarlo
imputar_nivel <- function(codigo) {
  hermanas_3d <- clasificadas %>%
    filter(str_sub(unitario_4d, 1, 3) == str_sub(codigo, 1, 3))
  if (nrow(hermanas_3d) >= 2) {
    return(list(nivel = "imputacion_modal_3d", base = hermanas_3d))
  }
  hermanas_2d <- clasificadas %>%
    filter(grupo_2d == str_sub(codigo, 1, 2))
  if (nrow(hermanas_2d) >= 2) {
    return(list(nivel = "imputacion_modal_2d", base = hermanas_2d))
  }
  hermanas_1d <- clasificadas %>%
    filter(division_chr == str_sub(codigo, 1, 1))
  if (nrow(hermanas_1d) >= 2) {
    return(list(nivel = "imputacion_modal_1d", base = hermanas_1d))
  }
  list(nivel = NA_character_, base = clasificadas[0, ])
}

# Se recorre cada ocupación gris y se arma la propuesta según su estado.
# lapply + bind_rows en lugar de map porque cada elemento devuelve varios
# campos heterogéneos y así el flujo queda explícito
propuestas <- lapply(seq_len(nrow(grises)), function(i) {

  fila <- grises[i, ]
  codigo <- fila$unitario_4d

  # Caso 1: fuera del universo del índice (no imputable)
  if (fila$estado_score %in% c("no_aplica_militar", "no_aplica_enoe",
                               "no_aplica_no_especificado")) {
    nota <- case_when(
      fila$estado_score == "no_aplica_militar" ~
        paste0("Ocupación de las fuerzas armadas: el índice de Gmyrek et ",
               "al. (2025) excluye al gran grupo 0 de la CIUO-08."),
      fila$estado_score == "no_aplica_enoe" ~
        paste0("Código operativo de la ENOE (no es una ocupación de ",
               "mercado evaluable)."),
      TRUE ~ "Ocupación no especificada."
    )
    descripcion <- case_when(
      fila$estado_score == "no_aplica_militar" ~ paste0(
        "Esta ocupación pertenece a las fuerzas armadas. El índice de ",
        "Gmyrek et al. (2025) excluye al gran grupo 0 de la CIUO-08 ",
        "porque el corpus de tareas de la OIT no cubre las ocupaciones ",
        "militares, por lo que no es posible asignarle una puntuación ",
        "de exposición a la IA, ni siquiera de forma provisional."
      ),
      fila$estado_score == "no_aplica_enoe" ~ paste0(
        "Este código es operativo de la ENOE y no corresponde a una ",
        "ocupación de mercado con tareas evaluables, por lo que no se ",
        "le asigna puntuación de exposición a la IA."
      ),
      TRUE ~ paste0(
        "La ENOE no especifica la ocupación de estas personas, por lo ",
        "que no es posible asignarles una puntuación de exposición a ",
        "la IA."
      )
    )
    return(tibble(
      unitario_4d = codigo,
      score_provisional = NA_real_,
      categoria_provisional_en = NA_character_,
      metodo_provisional = "no_imputable",
      nota = nota,
      descripcion_propuesta = descripcion
    ))
  }

  # Caso 2: existe propuesta en el mapeo manual con score (pendiente de
  # aprobación). Si la propuesta no trae score (p. ej. 4312, cuyo CIUO
  # análogo tampoco fue evaluado por Gmyrek), se cae al Caso 3
  prop <- mapeo %>%
    filter(sinco_4d == codigo, !is.na(mean_score_2025_propuesto))
  if (nrow(prop) > 0) {
    prop <- prop %>% slice(1)
    categoria_es <- traduccion_exposicion[prop$potential25_propuesto]
    return(tibble(
      unitario_4d = codigo,
      score_provisional = prop$mean_score_2025_propuesto,
      categoria_provisional_en = prop$potential25_propuesto,
      metodo_provisional = "mapeo_manual_propuesto",
      nota = paste0("CIUO-08 análogo propuesto: ", prop$ciuo08_propuesto,
                    " (", prop$ciuo08_titulo_propuesto, "). ",
                    prop$justificacion),
      descripcion_propuesta = paste0(
        "Clasificación provisional. Esta ocupación del SINCO no tiene ",
        "una correspondencia directa en la tabla comparativa ",
        "SINCO-CIUO-08 del INEGI, por lo que el equipo le asignó como ",
        "análoga la ocupación ", prop$ciuo08_propuesto, " de la CIUO-08 ",
        "(", prop$ciuo08_titulo_propuesto, "), evaluada por Gmyrek et ",
        "al. (2025) con una puntuación media de ",
        format(prop$mean_score_2025_propuesto, nsmall = 2), " (\"",
        categoria_es, "\"). ",
        "La puntuación proviene de las tareas de esa ocupación análoga ",
        "y no de una evaluación directa de las tareas de esta ",
        "ocupación en México, por lo que debe leerse como una ",
        "aproximación."
      )
    ))
  }

  # Caso 3: imputación modal jerárquica (incluye las que ya tienen score
  # imputado pero sin categoría, las gmyrek_sin_evaluar y las fuera de
  # catálogo)
  imp <- imputar_nivel(codigo)
  if (is.na(imp$nivel)) {
    return(tibble(
      unitario_4d = codigo,
      score_provisional = NA_real_,
      categoria_provisional_en = NA_character_,
      metodo_provisional = "sin_hermanas_clasificadas",
      nota = "No hay ocupaciones hermanas clasificadas para imputar.",
      descripcion_propuesta = NA_character_
    ))
  }
  score_prov <- ifelse(
    !is.na(fila$mean_score_ia_2025),
    fila$mean_score_ia_2025,
    mean(imp$base$mean_score_ia_2025, na.rm = TRUE)
  )
  categoria_en <- categoria_modal(imp$base$potencial_ia_2025)
  nombre_nivel <- case_when(
    imp$nivel == "imputacion_modal_3d" ~ paste0(
      "su mismo subgrupo ocupacional (SINCO ", str_sub(codigo, 1, 3), ")"
    ),
    imp$nivel == "imputacion_modal_2d" ~ paste0(
      "su mismo grupo principal (SINCO ", str_sub(codigo, 1, 2), ")"
    ),
    TRUE ~ "su misma división ocupacional"
  )
  tibble(
    unitario_4d = codigo,
    score_provisional = round(score_prov, 3),
    categoria_provisional_en = categoria_en,
    metodo_provisional = imp$nivel,
    nota = paste0(
      "Categoría modal de ", nrow(imp$base),
      " ocupaciones hermanas clasificadas (nivel ",
      str_sub(imp$nivel, -2), "). ",
      ifelse(!is.na(fila$mean_score_ia_2025),
             "Score: ya imputado jerárquicamente en el catálogo.",
             "Score: promedio de las hermanas.")
    ),
    descripcion_propuesta = paste0(
      "Clasificación provisional. El índice de Gmyrek et al. (2025) no ",
      "evalúa de forma directa las tareas de esta ocupación, ya sea ",
      "porque no tiene correspondencia con puntuación disponible en la ",
      "CIUO-08 o porque la ocupación análoga quedó fuera del índice. ",
      "Su categoría se estimó con la más frecuente entre las ",
      nrow(imp$base), " ocupaciones ya clasificadas de ", nombre_nivel,
      ", que comparten un perfil de tareas similar, y la puntuación ",
      "provisional (", format(round(score_prov, 2), nsmall = 2), ") ",
      ifelse(!is.na(fila$mean_score_ia_2025),
             paste0("proviene de la imputación jerárquica documentada ",
                    "en la nota metodológica. "),
             "corresponde al promedio de ese conjunto. "),
      "Debe leerse como una aproximación al perfil del grupo ",
      "ocupacional, no como una evaluación de las tareas específicas ",
      "de esta ocupación."
    )
  )
}) %>%
  bind_rows()

# 4. Catálogo final -----------------------------------------------------------------

catalogo_gris <- grises %>%
  left_join(propuestas, by = "unitario_4d") %>%
  left_join(poblacion, by = "unitario_4d") %>%
  mutate(
    en_datos_2026T1 = !is.na(ocup_total),
    across(c(ocup_total, ocup_hombres, ocup_mujeres),
           ~ replace_na(.x, 0)),
    categoria_provisional_es = ifelse(
      is.na(categoria_provisional_en), NA_character_,
      traduccion_exposicion[categoria_provisional_en]
    ),
    motivo_sin_score = case_when(
      estado_score == "fuera_de_catalogo" ~
        "Código de la actualización del SINCO ausente del catálogo",
      estado_score == "sin_correspondencia_ciuo" ~
        "Sin correspondencia directa SINCO-CIUO-08",
      estado_score == "gmyrek_sin_evaluar" ~
        "CIUO correspondiente sin evaluar en Gmyrek et al. (2025)",
      str_detect(estado_score, "imputado") ~
        "Score imputado jerárquicamente, sin gradiente asignado",
      estado_score == "no_aplica_militar" ~ "Ocupación militar",
      estado_score == "no_aplica_enoe" ~ "Código operativo ENOE",
      estado_score == "no_aplica_no_especificado" ~ "No especificado",
      TRUE ~ estado_score
    )
  ) %>%
  select(
    sinco_4d = unitario_4d, titulo = unitario_titulo,
    division_1d, division_titulo,
    motivo_sin_score,
    en_datos_2026T1, ocup_total, ocup_mujeres, ocup_hombres,
    score_actual_catalogo = mean_score_ia_2025,
    score_provisional, categoria_provisional_en, categoria_provisional_es,
    metodo_provisional, nota, descripcion_propuesta
  ) %>%
  arrange(desc(ocup_total))

write_excel_csv(catalogo_gris, archivo_salida)

print(paste0("Guardado: ", archivo_salida, " (", nrow(catalogo_gris),
             " ocupaciones)"))
print(catalogo_gris %>% count(metodo_provisional))
print(paste0(
  "Población ocupada total en gris (", periodo, "): ",
  format(sum(catalogo_gris$ocup_total), big.mark = ","),
  " | Mujeres: ",
  format(sum(catalogo_gris$ocup_mujeres), big.mark = ",")
))
