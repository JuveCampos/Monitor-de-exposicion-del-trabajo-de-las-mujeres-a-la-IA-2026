# ------------------------------------------------------------------------------
# Proyecto:   Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026
# Objetivo:   Medir cuánto cambian los agregados por sexo si la etiqueta
#             "Mixto" (ocupaciones SINCO cuyos códigos CIUO-08 caen en
#             categorías de exposición distintas) se resuelve con una regla
#             explícita. Se comparan tres reglas:
#               R0 actual:  promedio simple de scores y etiqueta "Mixto".
#               R1 primer CIUO: la categoría del primer código CIUO de la
#                   tabla comparativa del INEGI (el "principal").
#               R2 unión de tareas: se juntan las tareas de todos los CIUO
#                   de la ocupación y se aplica la Tabla 5 del WP140
#                   (Gmyrek et al., 2025) sobre la media y la desviación
#                   estándar de esas tareas.
#             R1 y R2 se aplican a todas las ocupaciones con dos o más CIUO,
#             no sólo a las "Mixto", para que la regla sea uniforme.
#
# Uso:        Rscript 00_Códigos/Scripts_procesamiento_ENOE_R/05_sensibilidad_mixto.R
#             (desde la raíz del repositorio)
# Salida:     03_Archivos/sensibilidad_mixto_<periodo>.md
# Fecha:      15 de octubre de 2026
# ------------------------------------------------------------------------------

library(tidyverse)
library(haven)
library(readxl)

periodo <- "2026T2"
archivo_enoe <- "04_Aplicación/zcalculos_Y2026T02_4d.dta"
archivo_catalogo <- "04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv"
archivo_gmyrek <- "01_Datos/01_catalogos/datasets/gmyrek_2025_ciuo4d_unique.csv"
archivo_tareas <- "01_Datos/01_catalogos/datasets/Gmyrek_et_al_2025_Final_Scores_ISCO08.xlsx"
archivo_salida <- paste0("03_Archivos/sensibilidad_mixto_", periodo, ".md")

etiquetas_es <- c(
  "Not Exposed"          = "No expuesto",
  "Minimal Exposure"     = "Exposición mínima",
  "Mixto"                = "Mixto",
  "Exposed: Gradient 1"  = "Exposición baja, alta variabilidad de tareas",
  "Exposed: Gradient 2"  = "Exposición moderada, alta variabilidad de tareas",
  "Exposed: Gradient 3"  = "Exposición significativa, alta variabilidad de tareas",
  "Exposed: Gradient 4"  = "Exposición máxima, baja variabilidad de tareas"
)
orden_cat <- names(etiquetas_es)
alta <- c("Exposed: Gradient 3", "Exposed: Gradient 4")

# 1. Insumos ------------------------------------------------------------------

catalogo <- read_csv(archivo_catalogo, col_types = cols(.default = "c")) %>%
  mutate(n_ciuo = as.integer(replace_na(n_ciuo_correspondencias, "0")))

gmyrek <- read_csv(archivo_gmyrek, col_types = cols(.default = "c")) %>%
  transmute(
    ciuo = ISCO_08,
    media = as.numeric(mean_score_2025),
    sd = as.numeric(SD_2025),
    categoria = potential25
  )

tareas <- read_excel(archivo_tareas, sheet = "Sheet1") %>%
  transmute(
    ciuo = str_pad(as.character(ISCO_08), 4, pad = "0"),
    score = as.numeric(score_2025)
  ) %>%
  filter(!is.na(score))

enoe <- read_dta(archivo_enoe) %>%
  mutate(sinco4d = str_pad(as.character(as.integer(sinco4d)), 4, pad = "0")) %>%
  select(sex, sinco4d, ocup)

# 2. Tabla 5 del WP140 ----------------------------------------------------------

# Clasifica una ocupación a partir de la media (mu) y la desviación estándar
# (sigma) de las puntuaciones de sus tareas. Se evalúa en orden, de mayor a
# menor exposición, igual que en el documento.
clasificar_tabla5 <- function(mu, sigma) {
  case_when(
    is.na(mu) ~ NA_character_,
    mu >= 0.6 & (mu - sigma) >= 0.5 ~ "Exposed: Gradient 4",
    mu >= 0.5 & mu < 0.6 & (mu + sigma) >= 0.5 ~ "Exposed: Gradient 3",
    mu >= 0.6 ~ "Exposed: Gradient 3",
    mu >= 0.4 & mu < 0.5 & (mu + sigma) >= 0.5 ~ "Exposed: Gradient 2",
    mu < 0.4 & (mu + sigma) >= 0.5 ~ "Exposed: Gradient 1",
    mu < 0.5 & (mu + sigma) > 0.4 ~ "Minimal Exposure",
    TRUE ~ "Not Exposed"
  )
}

# Validación: la regla debe reproducir las categorías publicadas por la OIT
validacion <- gmyrek %>%
  mutate(categoria_regla = clasificar_tabla5(media, sd)) %>%
  count(coincide = categoria == categoria_regla)
print(validacion)

# 3. Reglas alternativas para las ocupaciones con varios CIUO ------------------

pares <- catalogo %>%
  filter(n_ciuo >= 1) %>%
  select(unitario_4d, unitario_titulo, potencial_ia_2025, n_ciuo,
         ciuo08_4d_correspondientes) %>%
  separate_rows(ciuo08_4d_correspondientes, sep = ";") %>%
  rename(ciuo = ciuo08_4d_correspondientes) %>%
  group_by(unitario_4d) %>%
  mutate(orden_ciuo = row_number()) %>%
  ungroup()

# R1: categoría del primer CIUO
regla_1 <- pares %>%
  filter(orden_ciuo == 1) %>%
  left_join(gmyrek, by = "ciuo") %>%
  transmute(unitario_4d, cat_r1 = categoria)

# R2: unión de tareas y Tabla 5
regla_2 <- pares %>%
  inner_join(tareas, by = "ciuo", relationship = "many-to-many") %>%
  group_by(unitario_4d) %>%
  summarise(
    mu = mean(score),
    sigma = sd(score),
    n_tareas = n(),
    .groups = "drop"
  ) %>%
  mutate(cat_r2 = clasificar_tabla5(mu, sigma))

reglas <- catalogo %>%
  select(unitario_4d, unitario_titulo, n_ciuo, cat_r0 = potencial_ia_2025,
         mean_score_ia_2025, score_minimo, score_maximo,
         clasificacion_provisional) %>%
  left_join(regla_1, by = "unitario_4d") %>%
  left_join(regla_2, by = "unitario_4d") %>%
  mutate(
    # Sólo se tocan las ocupaciones con dos o más CIUO; el resto conserva
    # la categoría actual (incluidas las provisionales).
    cat_r1 = ifelse(n_ciuo >= 2 & !is.na(cat_r1), cat_r1, cat_r0),
    cat_r2 = ifelse(n_ciuo >= 2 & !is.na(cat_r2), cat_r2, cat_r0)
  )

# 4. Agregados por sexo bajo cada regla -----------------------------------------

base <- enoe %>%
  filter(sex %in% c(1, 2)) %>%
  left_join(reglas, by = c("sinco4d" = "unitario_4d")) %>%
  mutate(sexo = ifelse(sex == 1, "Hombres", "Mujeres"))

agregados <- bind_rows(
  base %>% transmute(regla = "R0 actual", sexo, ocup, cat = cat_r0),
  base %>% transmute(regla = "R1 primer CIUO", sexo, ocup, cat = cat_r1),
  base %>% transmute(regla = "R2 unión de tareas", sexo, ocup, cat = cat_r2)
) %>%
  group_by(regla, sexo) %>%
  mutate(total_sexo = sum(ocup)) %>%
  group_by(regla, sexo, cat) %>%
  summarise(ocup = sum(ocup), pct = 100 * ocup / first(total_sexo),
            .groups = "drop") %>%
  mutate(cat = factor(cat, levels = orden_cat)) %>%
  arrange(regla, sexo, cat)

alta_exp <- agregados %>%
  filter(cat %in% alta) %>%
  group_by(regla, sexo) %>%
  summarise(ocup = sum(ocup), pct = sum(pct), .groups = "drop")

# Cambios en las ocupaciones con dos o más CIUO
cambios <- reglas %>%
  filter(n_ciuo >= 2) %>%
  left_join(
    base %>%
      group_by(sinco4d, sexo) %>%
      summarise(ocup = sum(ocup), .groups = "drop") %>%
      pivot_wider(names_from = sexo, values_from = ocup, values_fill = 0),
    by = c("unitario_4d" = "sinco4d")
  ) %>%
  mutate(across(c(Hombres, Mujeres), ~ replace_na(.x, 0)),
         total = Hombres + Mujeres)

mixtos <- cambios %>%
  filter(cat_r0 == "Mixto") %>%
  arrange(desc(total))

# Top 10 de mujeres y hombres en exposición significativa y máxima por regla
top10 <- bind_rows(
  base %>% transmute(regla = "R0 actual", sexo, sinco4d, unitario_titulo,
                     ocup, cat = cat_r0),
  base %>% transmute(regla = "R1 primer CIUO", sexo, sinco4d,
                     unitario_titulo, ocup, cat = cat_r1),
  base %>% transmute(regla = "R2 unión de tareas", sexo, sinco4d,
                     unitario_titulo, ocup, cat = cat_r2)
) %>%
  filter(cat %in% alta) %>%
  group_by(regla, sexo) %>%
  slice_max(ocup, n = 10) %>%
  ungroup()

# 5. Informe en markdown ----------------------------------------------------------

fmt_n <- function(x) format(round(x), big.mark = ",")
fmt_p <- function(x) sprintf("%.2f%%", x)

tabla_md <- function(df) {
  encabezado <- paste0("| ", paste(names(df), collapse = " | "), " |")
  separador <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  filas <- apply(df, 1, function(f) paste0("| ", paste(f, collapse = " | "), " |"))
  c(encabezado, separador, filas)
}

lineas <- c(
  paste0("# Sensibilidad de la categoría \"Mixto\" (ENOE ", periodo, ")"),
  "",
  "Generado con `00_Códigos/Scripts_procesamiento_ENOE_R/05_sensibilidad_mixto.R`.",
  "Las reglas R1 y R2 se aplican a todas las ocupaciones con dos o más códigos",
  "CIUO-08; las ocupaciones con un solo código y las clasificaciones",
  "provisionales no cambian.",
  "",
  "- R0 actual: promedio simple de las puntuaciones y etiqueta \"Mixto\" cuando",
  "  las categorías de los CIUO difieren.",
  "- R1 primer CIUO: categoría del primer código CIUO de la tabla del INEGI.",
  "- R2 unión de tareas: media y desviación estándar de todas las tareas de los",
  "  CIUO de la ocupación, clasificadas con la Tabla 5 del WP140.",
  "",
  paste0("Validación de la Tabla 5: la regla reproduce la categoría publicada por",
         " la OIT en ", validacion$n[validacion$coincide],
         " de ", sum(validacion$n), " ocupaciones CIUO-08."),
  "",
  "## Ocupaciones con dos o más CIUO",
  "",
  paste0("- Ocupaciones con dos o más CIUO: ", nrow(cambios), "."),
  paste0("- De ellas, \"Mixto\": ", nrow(mixtos), " (",
         fmt_n(sum(mixtos$total)), " personas ocupadas)."),
  paste0("- Cambian de categoría con R1: ",
         sum(cambios$cat_r1 != cambios$cat_r0), " ocupaciones; con R2: ",
         sum(cambios$cat_r2 != cambios$cat_r0), "."),
  "",
  "## Población en exposición significativa y máxima por sexo",
  "",
  tabla_md(
    alta_exp %>%
      transmute(Regla = regla, Sexo = sexo, Personas = fmt_n(ocup),
                `Porcentaje del sexo` = fmt_p(pct))
  ),
  "",
  "## Distribución por categoría y sexo",
  "",
  tabla_md(
    agregados %>%
      mutate(cat = etiquetas_es[as.character(cat)]) %>%
      transmute(Regla = regla, Sexo = sexo, Categoría = cat,
                Personas = fmt_n(ocup), Porcentaje = fmt_p(pct))
  ),
  "",
  "## Qué pasa con cada ocupación \"Mixto\"",
  "",
  "Ordenadas por población ocupada total. Las columnas R1 y R2 muestran la",
  "categoría que recibiría la ocupación bajo cada regla.",
  "",
  tabla_md(
    mixtos %>%
      transmute(
        SINCO = unitario_4d,
        Ocupación = str_trunc(unitario_titulo, 60),
        `N CIUO` = n_ciuo,
        `Score medio` = mean_score_ia_2025,
        Rango = paste0(score_minimo, " a ", score_maximo),
        `R1` = etiquetas_es[cat_r1],
        `R2 (mu, sigma)` = paste0(etiquetas_es[cat_r2], " (",
                                  sprintf("%.2f", mu), ", ",
                                  sprintf("%.2f", sigma), ")"),
        Mujeres = fmt_n(Mujeres),
        Hombres = fmt_n(Hombres)
      )
  ),
  "",
  "## Otras ocupaciones con varios CIUO que cambiarían de categoría",
  "",
  tabla_md(
    cambios %>%
      filter(cat_r0 != "Mixto", cat_r1 != cat_r0 | cat_r2 != cat_r0) %>%
      arrange(desc(total)) %>%
      transmute(
        SINCO = unitario_4d,
        Ocupación = str_trunc(unitario_titulo, 60),
        `R0 actual` = etiquetas_es[cat_r0],
        R1 = etiquetas_es[cat_r1],
        R2 = etiquetas_es[cat_r2],
        Mujeres = fmt_n(Mujeres),
        Hombres = fmt_n(Hombres)
      )
  ),
  "",
  "## Top 10 en exposición significativa y máxima por regla",
  ""
)

for (r in unique(top10$regla)) {
  for (s in c("Mujeres", "Hombres")) {
    lineas <- c(
      lineas,
      paste0("### ", r, ": ", s),
      "",
      tabla_md(
        top10 %>%
          filter(regla == r, sexo == s) %>%
          arrange(desc(ocup)) %>%
          transmute(SINCO = sinco4d,
                    Ocupación = str_trunc(unitario_titulo, 60),
                    Categoría = etiquetas_es[cat],
                    Personas = fmt_n(ocup))
      ),
      ""
    )
  }
}

writeLines(lineas, archivo_salida)
print(paste0("Escrito: ", archivo_salida))
print(alta_exp)
