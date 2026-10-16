# ------------------------------------------------------------------------------
# Paso 9:     Población ocupada con formación STEM (ciencias, tecnología,
#             ingeniería y matemáticas) por sexo, a partir del campo de
#             formación de la carrera (cs_p14_c) de la ENOE. Genera:
#             - zcalculos_Y{año}T0{trim}_stem_campos.dta: ocupados por sexo y
#               campo de formación (S, T, E, M y no STEM).
#             - zcalculos_Y{año}T0{trim}_4d_stem.dta: ocupados con formación
#               STEM por sexo y SINCO 4d (para cruzar con el catálogo).
#
#             El cuerpo es el mismo de 00_Códigos/Scripts_procesamiento_ENOE_R/
#             04_procesar_enoe_stem.R. La definición de STEM (sección 3)
#             hereda las advertencias documentadas ahí y en
#             03_Archivos/sensibilidad_stem_2026T2.md: incluye economía y
#             finanzas en ciencias y excluye a las ciencias de la salud.
#
# Uso:        Rscript 09_procesar_stem.R [año] [trimestre]
#             Sin argumentos usa anio_enoe y trim_enoe de la configuración.
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(foreign)
library(haven)

# 0. Parámetros -----------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
year_sel <- ifelse(length(args) >= 1, as.numeric(args[1]), anio_enoe)
trim_sel <- ifelse(length(args) >= 2, as.numeric(args[2]), trim_enoe)
stopifnot(year_sel >= 2025, trim_sel %in% 1:4)

dir_salida <- dir_enoe_salidas
yy <- str_sub(as.character(year_sel), 3, 4)
carpeta_trim <- file.path(
  dir_dbf_enoe, paste0("enoe_", year_sel, "_trim", trim_sel, "_dbf")
)
archivo_sdem <- file.path(carpeta_trim, paste0("ENOE_SDEMT", trim_sel, yy, ".dbf"))
archivo_coe1 <- file.path(carpeta_trim, paste0("ENOE_COE1T", trim_sel, yy, ".dbf"))
stopifnot(file.exists(archivo_sdem), file.exists(archivo_coe1))
print(paste0("Procesando ENOE ", year_sel, " trimestre ", trim_sel, " (STEM)"))

# 1. Lectura y fusión de microdatos -----------------------------------------------

sdem <- read.dbf(archivo_sdem, as.is = TRUE) %>%
  as_tibble() %>%
  rename_all(tolower)

coe1 <- read.dbf(archivo_coe1, as.is = TRUE) %>%
  as_tibble() %>%
  rename_all(tolower)

if ("ent" %in% names(sdem) & !"cve_ent" %in% names(sdem)) {
  sdem <- sdem %>% rename(cve_ent = ent)
}
if ("ent" %in% names(coe1) & !"cve_ent" %in% names(coe1)) {
  coe1 <- coe1 %>% rename(cve_ent = ent)
}

vars_llave <- c(
  "cd_a", "cve_ent", "con", "v_sel", "tipo",
  "mes_cal", "n_hog", "h_mud", "n_ren"
)

bd <- sdem %>%
  filter(
    as.character(r_def) == "00",
    as.character(c_res) %in% c("1", "3")
  ) %>%
  mutate(llave = paste0(!!!syms(vars_llave))) %>%
  select(
    llave, sex, eda, anios_esc, clase1, clase2,
    emp_ppal, ingocup, fac_tri, cs_p14_c
  ) %>%
  left_join(
    coe1 %>%
      mutate(llave = paste0(!!!syms(vars_llave))) %>%
      select(llave, p3),
    by = "llave"
  )

stopifnot(nrow(bd) == nrow(distinct(bd, llave)))

# 2. Variables derivadas (idénticas a 01_procesar_enoe_sinco.R) -------------------

bd <- bd %>%
  mutate(
    across(c(sex, eda, clase1, clase2, emp_ppal, ingocup, fac_tri),
           as.numeric)
  ) %>%
  filter(eda >= 15, eda <= 98) %>%
  mutate(
    ocup = as.integer(clase1 %in% 1 & clase2 %in% 1),
    ocuptil = as.integer(ocup == 1 & emp_ppal %in% 1),
    ingocup_missing = ifelse(ingocup == 0, NA, ingocup),
    sinco4d = as.numeric(p3),
    escol2d = ifelse(as.numeric(anios_esc) == 99, NA,
                     as.numeric(anios_esc)),
    edad2d = ifelse(eda == 98, NA, eda)
  )

# 3. Clasificación STEM por campo de formación ------------------------------------

# cs_p14_c trae el código de la carrera a seis dígitos (campo amplio de dos
# dígitos con cero a la izquierda + campo específico + programa). El do-file
# original toma el campo específico (tres dígitos) con substr(2, 3) cuando el
# código empieza con "0"; los códigos del campo amplio 10 (servicios) y el
# 999999 (no especificado) nunca caen en STEM.
codigos_stem <- list(
  # S: ciencias (incluye economía y finanzas; excluye salud, como el do-file)
  "1_S" = c("314", "413",                     # economía y finanzas
            "510", "511", "512", "513",       # ciencias ambientales y biológicas
            "520", "521", "522", "523"),      # ciencias físicas y químicas
  # T: tecnologías de la información y la comunicación
  "2_T" = c("610", "611", "612", "613",       # TIC, innovación
            "620", "621", "622", "623"),      # TIC, implementación
  # E: ingenierías
  "3_E" = c("710", "711", "712", "713", "714", "715", "716", "717",
            "720", "721", "722", "723", "724"),
  # M: matemáticas y estadística
  "4_M" = c("531", "532")
)

tabla_stem <- tibble(
  campo_stem = rep(names(codigos_stem), lengths(codigos_stem)),
  campo_especifico = unlist(codigos_stem, use.names = FALSE)
)

bd <- bd %>%
  mutate(
    cs_p14_c = str_trim(as.character(cs_p14_c)),
    campo_especifico = ifelse(
      !is.na(cs_p14_c) & str_sub(cs_p14_c, 1, 1) == "0",
      str_sub(cs_p14_c, 2, 4),
      NA_character_
    )
  ) %>%
  left_join(tabla_stem, by = "campo_especifico") %>%
  mutate(campo_stem = replace_na(campo_stem, "0_NoSTEM"))

# Comprobación de la clasificación: campos específicos que cayeron en STEM
print(
  bd %>%
    filter(ocup == 1, campo_stem != "0_NoSTEM") %>%
    count(campo_stem, campo_especifico, wt = fac_tri) %>%
    arrange(campo_stem, desc(n)),
  n = 50
)

# 4. Colapsos -------------------------------------------------------------------

# Solo población ocupada; se duplica con sex = 0 para el total
bd_ocup <- bd %>% filter(ocup == 1)
bd_total_y_sexo <- bind_rows(
  bd_ocup %>% mutate(sex = 0),
  bd_ocup
)

# 4a. Por sexo y campo de formación (toda la población ocupada)
resumen_campos <- bd_total_y_sexo %>%
  group_by(sex, campo_stem) %>%
  summarise(
    ocup    = sum(fac_tri),
    ocuptil = sum(ocuptil * fac_tri),
    edad2d  = weighted.mean(edad2d, fac_tri, na.rm = TRUE),
    escol2d = weighted.mean(escol2d, fac_tri, na.rm = TRUE),
    ingreso = mediana_ponderada(ingocup_missing, fac_tri),
    .groups = "drop"
  ) %>%
  mutate(
    year = as.character(year_sel),
    qtr  = as.character(trim_sel),
    til  = 100 * (ocuptil / ocup)
  ) %>%
  arrange(sex, campo_stem) %>%
  select(year, qtr, sex, campo_stem, ocup, ocuptil,
         edad2d, escol2d, ingreso, til)

archivo_campos <- file.path(
  dir_salida,
  paste0("zcalculos_Y", year_sel, "T0", trim_sel, "_stem_campos.dta")
)
write_dta(resumen_campos, archivo_campos)
print(paste0("Guardado: ", archivo_campos, " (", nrow(resumen_campos),
             " filas)"))

# 4b. Población ocupada con formación STEM por sexo y SINCO a 4 dígitos
resumen_4d <- bd_total_y_sexo %>%
  filter(campo_stem != "0_NoSTEM", !is.na(sinco4d)) %>%
  group_by(sex, sinco4d) %>%
  summarise(
    ocup    = sum(fac_tri),
    ocuptil = sum(ocuptil * fac_tri),
    edad2d  = weighted.mean(edad2d, fac_tri, na.rm = TRUE),
    escol2d = weighted.mean(escol2d, fac_tri, na.rm = TRUE),
    ingreso = mediana_ponderada(ingocup_missing, fac_tri),
    .groups = "drop"
  ) %>%
  mutate(
    year = as.character(year_sel),
    qtr  = as.character(trim_sel),
    til  = 100 * (ocuptil / ocup),
    across(c(edad2d, escol2d), ~ ifelse(is.nan(.x), NA, .x))
  ) %>%
  arrange(sex, sinco4d) %>%
  select(year, qtr, sex, sinco4d, ocup, ocuptil,
         edad2d, escol2d, ingreso, til)

archivo_4d <- file.path(
  dir_salida,
  paste0("zcalculos_Y", year_sel, "T0", trim_sel, "_4d_stem.dta")
)
write_dta(resumen_4d, archivo_4d)
print(paste0("Guardado: ", archivo_4d, " (", nrow(resumen_4d), " filas)"))

# 5. Resumen rápido ---------------------------------------------------------------

print(
  resumen_campos %>%
    select(sex, campo_stem, ocup) %>%
    pivot_wider(names_from = sex, values_from = ocup,
                names_prefix = "sex_") %>%
    mutate(pct_mujeres = 100 * sex_2 / sex_0)
)
