# ==============================================================================
# Cifras del cruce exposición a la IA x informalidad, ENOE 1T2026
#
# Actualiza al trimestre vigente el cruce que se había hecho con ENOE 4T2025
# para el foro. Escribe un CSV de respaldo con todas las cifras que se citan
# en la presentación, de modo que cada número del deck sea rastreable.
#
# Uso (desde la raíz del repositorio):
#   Rscript 05_Presentacion_foro/codigo/01_calcula_cifras.R
# ==============================================================================

library(haven)
library(tidyverse)

ruta_raiz <- normalizePath(".")
ruta_app <- file.path(ruta_raiz, "04_Aplicación")
ruta_salida <- file.path(ruta_raiz, "05_Presentacion_foro", "figuras")

periodo <- "1T2026"

# --- Datos --------------------------------------------------------------------
# Se usa el catálogo vigente del Monitor (488 ocupaciones, incluye las 68
# clasificaciones provisionales integradas en julio de 2026)
catalogo <- read_csv(
  file.path(ruta_app, "catalogos_sinco", "sinco_con_exposicion_ia_es.csv"),
  show_col_types = FALSE
) %>%
  select(unitario_4d, unitario_titulo, mean_score_ia_2025,
         potencial_ia_2025, clasificacion_provisional) %>%
  unique()

enoe <- read_dta(file.path(ruta_app, "zcalculos_Y2026T01_4d.dta")) %>%
  mutate(sinco4d = str_pad(sinco4d, width = 3, side = "left", pad = "0"))

niveles_gradiente <- c(
  "No expuesto", "Exposición mínima", "Mixto",
  "Gradiente 1", "Gradiente 2", "Gradiente 3", "Gradiente 4"
)

base <- enoe %>%
  left_join(catalogo, by = c("sinco4d" = "unitario_4d")) %>%
  mutate(
    sexo = factor(sex, levels = c(0, 1, 2),
                  labels = c("Total", "Hombres", "Mujeres")),
    ocup_formal = ocup - ocuptil,
    gradiente = case_when(
      potencial_ia_2025 == "Not Exposed"         ~ "No expuesto",
      potencial_ia_2025 == "Minimal Exposure"    ~ "Exposición mínima",
      potencial_ia_2025 == "Mixto"               ~ "Mixto",
      potencial_ia_2025 == "Exposed: Gradient 1" ~ "Gradiente 1",
      potencial_ia_2025 == "Exposed: Gradient 2" ~ "Gradiente 2",
      potencial_ia_2025 == "Exposed: Gradient 3" ~ "Gradiente 3",
      potencial_ia_2025 == "Exposed: Gradient 4" ~ "Gradiente 4",
      TRUE                                       ~ NA_character_
    ),
    gradiente = factor(gradiente, levels = niveles_gradiente)
  )

# --- 1. Informalidad y % del empleo por gradiente (población total) -----------
tabla_gradientes <- base %>%
  filter(sexo == "Total", !is.na(gradiente)) %>%
  group_by(gradiente) %>%
  summarise(
    ocupados = sum(ocup, na.rm = TRUE),
    informales = sum(ocuptil, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct_empleo = 100 * ocupados / sum(ocupados),
    til = 100 * informales / ocupados
  )

# --- 2. Exposición promedio ponderada, formal vs informal ---------------------
# El puntaje continuo de exposición (0 a 1) se pondera por el número de
# personas ocupadas de cada condición
exposicion_condicion <- base %>%
  filter(sexo %in% c("Hombres", "Mujeres"),
         !is.na(mean_score_ia_2025), ocup > 0) %>%
  group_by(sexo) %>%
  summarise(
    formal = weighted.mean(mean_score_ia_2025, ocup_formal, na.rm = TRUE),
    informal = weighted.mean(mean_score_ia_2025, ocuptil, na.rm = TRUE),
    total = weighted.mean(mean_score_ia_2025, ocup, na.rm = TRUE),
    .groups = "drop"
  )

exposicion_total <- base %>%
  filter(sexo == "Total", !is.na(mean_score_ia_2025), ocup > 0) %>%
  summarise(
    sexo = "Total",
    formal = weighted.mean(mean_score_ia_2025, ocup_formal, na.rm = TRUE),
    informal = weighted.mean(mean_score_ia_2025, ocuptil, na.rm = TRUE),
    total = weighted.mean(mean_score_ia_2025, ocup, na.rm = TRUE)
  )

exposicion_condicion <- bind_rows(exposicion_condicion, exposicion_total)

# --- 3. Empleo en gradientes altos (3 y 4) por sexo ---------------------------
altos <- base %>%
  filter(sexo %in% c("Hombres", "Mujeres")) %>%
  group_by(sexo) %>%
  summarise(
    ocupados_total = sum(ocup, na.rm = TRUE),
    ocupados_altos = sum(ocup[gradiente %in% c("Gradiente 3", "Gradiente 4")],
                         na.rm = TRUE),
    informales_altos = sum(
      ocuptil[gradiente %in% c("Gradiente 3", "Gradiente 4")], na.rm = TRUE
    ),
    ocupados_g4 = sum(ocup[gradiente == "Gradiente 4"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct_altos = 100 * ocupados_altos / ocupados_total,
    pct_g4 = 100 * ocupados_g4 / ocupados_total,
    til_altos = 100 * informales_altos / ocupados_altos,
    pct_formal_altos = 100 - til_altos
  )

feminizacion_altos <- 100 * altos$ocupados_altos[altos$sexo == "Mujeres"] /
  sum(altos$ocupados_altos)
feminizacion_total <- 100 * altos$ocupados_total[altos$sexo == "Mujeres"] /
  sum(altos$ocupados_total)

# --- 4. Ocupaciones concretas de los gradientes altos ------------------------
ocupaciones_altas <- base %>%
  filter(gradiente %in% c("Gradiente 3", "Gradiente 4")) %>%
  select(sinco4d, unitario_titulo, gradiente, sexo, ocup, ocuptil) %>%
  pivot_wider(names_from = sexo, values_from = c(ocup, ocuptil)) %>%
  mutate(
    pct_mujeres = 100 * ocup_Mujeres / ocup_Total,
    til = 100 * ocuptil_Total / ocup_Total
  ) %>%
  arrange(desc(ocup_Total)) %>%
  select(sinco4d, unitario_titulo, gradiente, ocupados = ocup_Total,
         mujeres = ocup_Mujeres, pct_mujeres, til) %>%
  slice_head(n = 10)

# --- Impresión de resultados --------------------------------------------------
print("=== 1. Gradientes: % del empleo y tasa de informalidad ===")
print(tabla_gradientes, n = 20)

print("=== 2. Exposición promedio (0 a 1) por condición y sexo ===")
print(exposicion_condicion)

print("=== 3. Empleo en gradientes 3 y 4 por sexo ===")
print(altos)
print(paste0("Feminización de los gradientes altos: ",
             round(feminizacion_altos, 1), " %"))
print(paste0("Feminización del empleo total: ",
             round(feminizacion_total, 1), " %"))

print("=== 4. Ocupaciones de los gradientes altos ===")
print(ocupaciones_altas, n = 10, width = 200)

# --- Respaldo -----------------------------------------------------------------
write_csv(tabla_gradientes,
          file.path(ruta_salida, "respaldo_01_gradientes.csv"))
write_csv(exposicion_condicion,
          file.path(ruta_salida, "respaldo_02_exposicion_condicion.csv"))
write_csv(altos, file.path(ruta_salida, "respaldo_03_gradientes_altos.csv"))
write_csv(ocupaciones_altas,
          file.path(ruta_salida, "respaldo_04_ocupaciones.csv"))

print(paste0("Respaldos escritos en ", ruta_salida))
