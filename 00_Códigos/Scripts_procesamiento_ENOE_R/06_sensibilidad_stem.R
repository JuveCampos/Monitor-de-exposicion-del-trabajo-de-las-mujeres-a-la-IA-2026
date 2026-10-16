# ------------------------------------------------------------------------------
# Proyecto:   Monitor de Exposición del Trabajo de las Mujeres a la IA · 2026
# Objetivo:   Medir cuánto cambian las cifras STEM si se modifica la
#             definición heredada del do-file original. Variantes:
#               V0 actual:      campos del bloque codigos_stem de
#                               04_procesar_enoe_stem.R (incluye economía y
#                               finanzas; todos los niveles con carrera).
#               V1 sin economía: se quitan los campos 314 y 413.
#               V2 licenciatura o más: se exige nivel de instrucción
#                               07 licenciatura, 08 maestría o 09 doctorado
#                               (cs_p13_1), excluyendo normal y carrera técnica.
#               V3 ambas:        V1 y V2 a la vez.
#
# Uso:        Rscript 00_Códigos/Scripts_procesamiento_ENOE_R/06_sensibilidad_stem.R [año] [trim] [carpeta_dbf]
#             (desde la raíz del repositorio; sin argumentos usa 2026 T2)
# Salida:     03_Archivos/sensibilidad_stem_<periodo>.md
# Fecha:      15 de octubre de 2026
# ------------------------------------------------------------------------------

library(tidyverse)
library(foreign)

args <- commandArgs(trailingOnly = TRUE)
year_sel <- ifelse(length(args) >= 1, as.numeric(args[1]), 2026)
trim_sel <- ifelse(length(args) >= 2, as.numeric(args[2]), 2)
dir_dbf_base <- ifelse(
  length(args) >= 3, args[3],
  "/Volumes/Extreme SSD/DATASETS/INEGI - ENOE/dbf"
)
periodo <- paste0(year_sel, "T", trim_sel)
archivo_catalogo <- "04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv"
archivo_salida <- paste0("03_Archivos/sensibilidad_stem_", periodo, ".md")

yy <- str_sub(as.character(year_sel), 3, 4)
carpeta_trim <- file.path(
  dir_dbf_base, paste0("enoe_", year_sel, "_trim", trim_sel, "_dbf")
)
archivo_sdem <- file.path(carpeta_trim, paste0("ENOE_SDEMT", trim_sel, yy, ".dbf"))
archivo_coe1 <- file.path(carpeta_trim, paste0("ENOE_COE1T", trim_sel, yy, ".dbf"))
stopifnot(file.exists(archivo_sdem), file.exists(archivo_coe1))

# 1. Lectura y fusión (misma lógica que 04_procesar_enoe_stem.R) -------------------

sdem <- read.dbf(archivo_sdem, as.is = TRUE) %>% as_tibble() %>% rename_all(tolower)
coe1 <- read.dbf(archivo_coe1, as.is = TRUE) %>% as_tibble() %>% rename_all(tolower)
if ("ent" %in% names(sdem) & !"cve_ent" %in% names(sdem)) sdem <- rename(sdem, cve_ent = ent)
if ("ent" %in% names(coe1) & !"cve_ent" %in% names(coe1)) coe1 <- rename(coe1, cve_ent = ent)

vars_llave <- c("cd_a", "cve_ent", "con", "v_sel", "tipo", "mes_cal",
                "n_hog", "h_mud", "n_ren")

bd <- sdem %>%
  filter(as.character(r_def) == "00", as.character(c_res) %in% c("1", "3")) %>%
  mutate(llave = paste0(!!!syms(vars_llave))) %>%
  select(llave, sex, eda, clase1, clase2, fac_tri, cs_p13_1, cs_p14_c) %>%
  left_join(
    coe1 %>% mutate(llave = paste0(!!!syms(vars_llave))) %>% select(llave, p3),
    by = "llave"
  ) %>%
  mutate(across(c(sex, eda, clase1, clase2, fac_tri), as.numeric)) %>%
  filter(eda >= 15, eda <= 98) %>%
  mutate(
    ocup = as.integer(clase1 %in% 1 & clase2 %in% 1),
    sinco4d = str_pad(as.character(as.integer(p3)), 4, pad = "0"),
    nivel = str_pad(str_trim(as.character(cs_p13_1)), 2, pad = "0"),
    cs_p14_c = str_trim(as.character(cs_p14_c)),
    campo_especifico = ifelse(
      !is.na(cs_p14_c) & str_sub(cs_p14_c, 1, 1) == "0",
      str_sub(cs_p14_c, 2, 4), NA_character_
    )
  ) %>%
  filter(ocup == 1)

# 2. Definiciones ----------------------------------------------------------------

codigos_stem <- list(
  "1_S" = c("314", "413", "510", "511", "512", "513", "520", "521", "522", "523"),
  "2_T" = c("610", "611", "612", "613", "620", "621", "622", "623"),
  "3_E" = c("710", "711", "712", "713", "714", "715", "716", "717",
            "720", "721", "722", "723", "724"),
  "4_M" = c("531", "532")
)
tabla_stem <- tibble(
  campo_stem = rep(names(codigos_stem), lengths(codigos_stem)),
  campo_especifico = unlist(codigos_stem, use.names = FALSE)
)
economia <- c("314", "413")
licenciatura_o_mas <- c("07", "08", "09")

bd <- bd %>%
  left_join(tabla_stem, by = "campo_especifico") %>%
  mutate(
    v0 = !is.na(campo_stem),
    v1 = v0 & !campo_especifico %in% economia,
    v2 = v0 & nivel %in% licenciatura_o_mas,
    v3 = v1 & v2
  )

# Distribución del nivel de instrucción entre quienes reportan campo STEM
niveles <- bd %>%
  filter(v0) %>%
  count(nivel, wt = fac_tri) %>%
  mutate(pct = 100 * n / sum(n))
print(niveles)

# 3. Cifras por variante y sexo ------------------------------------------------------

catalogo <- read_csv(archivo_catalogo, col_types = cols(.default = "c")) %>%
  select(unitario_4d, potencial_ia_2025)
alta <- c("Exposed: Gradient 3", "Exposed: Gradient 4")

bd <- bd %>%
  left_join(catalogo, by = c("sinco4d" = "unitario_4d")) %>%
  mutate(sexo = ifelse(sex == 1, "Hombres", "Mujeres"),
         alta_exp = potencial_ia_2025 %in% alta)

totales_sexo <- bd %>% group_by(sexo) %>% summarise(ocup = sum(fac_tri), .groups = "drop")

resumen <- bind_rows(
  bd %>% filter(v0) %>% mutate(variante = "V0 actual"),
  bd %>% filter(v1) %>% mutate(variante = "V1 sin economía y finanzas"),
  bd %>% filter(v2) %>% mutate(variante = "V2 licenciatura o más"),
  bd %>% filter(v3) %>% mutate(variante = "V3 ambas")
) %>%
  group_by(variante, sexo) %>%
  summarise(
    stem = sum(fac_tri),
    stem_alta = sum(fac_tri * alta_exp),
    .groups = "drop"
  ) %>%
  left_join(totales_sexo, by = "sexo") %>%
  group_by(variante) %>%
  mutate(pct_del_total_stem = 100 * stem / sum(stem)) %>%
  ungroup() %>%
  mutate(
    pct_ocupados_con_stem = 100 * stem / ocup,
    pct_stem_en_alta = 100 * stem_alta / stem
  )

por_campo <- bind_rows(
  bd %>% filter(v0) %>% mutate(variante = "V0 actual"),
  bd %>% filter(v1) %>% mutate(variante = "V1 sin economía y finanzas"),
  bd %>% filter(v2) %>% mutate(variante = "V2 licenciatura o más"),
  bd %>% filter(v3) %>% mutate(variante = "V3 ambas")
) %>%
  group_by(variante, campo_stem, sexo) %>%
  summarise(n = sum(fac_tri), .groups = "drop") %>%
  group_by(variante, campo_stem) %>%
  mutate(pct_mujeres = 100 * n / sum(n)) %>%
  ungroup() %>%
  filter(sexo == "Mujeres")

# 4. Informe ----------------------------------------------------------------------

fmt_n <- function(x) format(round(x), big.mark = ",")
fmt_p <- function(x) sprintf("%.1f%%", x)
tabla_md <- function(df) {
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(f) paste0("| ", paste(f, collapse = " | "), " |")))
}
etiquetas_campo <- c("1_S" = "Ciencias", "2_T" = "TIC", "3_E" = "Ingeniería",
                     "4_M" = "Matemáticas")
etiquetas_nivel <- c("05" = "Normal", "06" = "Carrera técnica",
                     "07" = "Licenciatura", "08" = "Maestría", "09" = "Doctorado")

lineas <- c(
  paste0("# Sensibilidad de la definición STEM (ENOE ", periodo, ")"),
  "",
  "Generado con `00_Códigos/Scripts_procesamiento_ENOE_R/06_sensibilidad_stem.R`.",
  "Población ocupada de 15 a 98 años con campo de formación reportado.",
  "",
  "- V0 actual: definición vigente (incluye economía y finanzas, 314 y 413;",
  "  cualquier nivel con carrera).",
  "- V1: sin economía y finanzas.",
  "- V2: sólo licenciatura, maestría o doctorado (excluye normal y carrera técnica).",
  "- V3: V1 y V2 a la vez.",
  "",
  "## Nivel de instrucción de quienes reportan campo STEM (V0)",
  "",
  tabla_md(niveles %>% transmute(Nivel = coalesce(etiquetas_nivel[nivel], nivel),
                                 Personas = fmt_n(n), Porcentaje = fmt_p(pct))),
  "",
  "## Cifras por variante y sexo",
  "",
  tabla_md(
    resumen %>%
      transmute(Variante = variante, Sexo = sexo,
                `Personas STEM` = fmt_n(stem),
                `% del total STEM` = fmt_p(pct_del_total_stem),
                `% de ocupados del sexo con STEM` = fmt_p(pct_ocupados_con_stem),
                `% de STEM en exposición significativa o máxima` = fmt_p(pct_stem_en_alta))
  ),
  "",
  "## Porcentaje de mujeres por campo y variante",
  "",
  tabla_md(
    por_campo %>%
      transmute(Variante = variante, Campo = etiquetas_campo[campo_stem],
                Mujeres = fmt_n(n), `% mujeres` = fmt_p(pct_mujeres))
  )
)
writeLines(lineas, archivo_salida)
print(paste0("Escrito: ", archivo_salida))
print(resumen %>% select(variante, sexo, stem, pct_ocupados_con_stem, pct_stem_en_alta))
