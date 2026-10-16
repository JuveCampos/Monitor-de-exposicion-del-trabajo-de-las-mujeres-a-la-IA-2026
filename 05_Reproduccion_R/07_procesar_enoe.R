# ------------------------------------------------------------------------------
# Paso 7:     Procesamiento de los microdatos de la ENOE (INEGI): fusión de la
#             tabla sociodemográfica (SDEM) con el cuestionario de ocupación y
#             empleo (COE1), filtros de entrevista completa y residencia
#             habitual, y colapso por sexo y código SINCO a 1, 2, 3 y 4
#             dígitos. Genera los archivos zcalculos_Y{año}T0{trim}_{grupo}.dta
#             que consume la aplicación (ocupados, informales, edad y
#             escolaridad promedio, ingreso mediano y tasa de informalidad).
#
#             El cuerpo es el mismo de 00_Códigos/Scripts_procesamiento_ENOE_R/
#             01_procesar_enoe_sinco.R (validado fila por fila contra el
#             do-file original de Stata); aquí solo cambian rutas y parámetros,
#             que vienen de 00_configuracion.R.
#
# Uso:        Rscript 07_procesar_enoe.R [año] [trimestre]
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
print(paste0("Procesando ENOE ", year_sel, " trimestre ", trim_sel))

# 1. Lectura de microdatos --------------------------------------------------------

# Tabla sociodemográfica (SDEM): contiene sexo, edad, escolaridad, los
# precodificados de condición de ocupación (clase1, clase2), informalidad
# (emp_ppal), ingreso (ingocup) y el factor de expansión trimestral (fac_tri)
sdem <- read.dbf(archivo_sdem, as.is = TRUE) %>%
  as_tibble() %>%
  rename_all(tolower)

# Tabla del cuestionario de ocupación y empleo I (COE1): contiene p3, el
# código SINCO a 4 dígitos de la ocupación principal
coe1 <- read.dbf(archivo_coe1, as.is = TRUE) %>%
  as_tibble() %>%
  rename_all(tolower)

# El INEGI ha alternado los nombres `ent` y `cve_ent` entre ediciones;
# se normaliza a `cve_ent` en ambas tablas
if ("ent" %in% names(sdem) & !"cve_ent" %in% names(sdem)) {
  sdem <- sdem %>% rename(cve_ent = ent)
}
if ("ent" %in% names(coe1) & !"cve_ent" %in% names(coe1)) {
  coe1 <- coe1 %>% rename(cve_ent = ent)
}

# 2. Fusión SDEM + COE1 -----------------------------------------------------------

# Llave de persona: vivienda + hogar + número de renglón (procedimiento
# estándar del INEGI para unir las tablas de la ENOE)
vars_llave <- c(
  "cd_a", "cve_ent", "con", "v_sel", "tipo",
  "mes_cal", "n_hog", "h_mud", "n_ren"
)

# Filtro de entrevista completa y residencia habitual:
# r_def == "00" (entrevista completa) y c_res 1 o 3 (residente habitual
# o nuevo residente)
bd <- sdem %>%
  filter(
    as.character(r_def) == "00",
    as.character(c_res) %in% c("1", "3")
  ) %>%
  mutate(llave = paste0(!!!syms(vars_llave))) %>%
  select(
    llave, sex, eda, anios_esc, clase1, clase2,
    emp_ppal, ingocup, fac_tri
  ) %>%
  left_join(
    coe1 %>%
      mutate(llave = paste0(!!!syms(vars_llave))) %>%
      select(llave, p3),
    by = "llave"
  )

stopifnot(nrow(bd) == nrow(distinct(bd, llave)))

# 3. Variables derivadas (réplica del do-file de Stata) ---------------------------

bd <- bd %>%
  mutate(
    across(c(sex, eda, clase1, clase2, emp_ppal, ingocup, fac_tri),
           as.numeric)
  ) %>%
  # Población de 15 a 98 años (98 = "98 años y más"; 99 = no especificado)
  filter(eda >= 15, eda <= 98) %>%
  mutate(
    # Ocupación: clase1 == 1 (PEA) y clase2 == 1 (ocupada)
    ocup = as.integer(clase1 %in% 1 & clase2 %in% 1),
    # Ocupación informal (tasa de informalidad laboral 1)
    ocuptil = as.integer(ocup == 1 & emp_ppal %in% 1),
    # Ingreso mensual: 0 se trata como no reportado
    ingocup_missing = ifelse(ingocup == 0, NA, ingocup),
    # Códigos SINCO a distintos niveles de agregación
    sinco4d = as.numeric(p3),
    sinco3d = as.numeric(str_sub(p3, 1, 3)),
    sinco2d = as.numeric(str_sub(p3, 1, 2)),
    sinco1d = as.numeric(str_sub(p3, 1, 1)),
    # Escolaridad en años (99 = no especificado)
    escol2d = ifelse(as.numeric(anios_esc) == 99, NA,
                     as.numeric(anios_esc)),
    # Edad (98 = "98 y más" se excluye de los promedios)
    edad2d = ifelse(eda == 98, NA, eda)
  )

# 4. Colapso por sexo y código SINCO ----------------------------------------------

# mediana_ponderada() viene de 00_configuracion.R
# La base se duplica con sex = 0 para obtener el total (equivalente al
# preserve/collapse/append del do-file original)
bd_total_y_sexo <- bind_rows(
  bd %>% mutate(sex = 0),
  bd
)

# Se genera un archivo por nivel de agregación (1, 2, 3 y 4 dígitos)
for (grupo in c("1d", "2d", "3d", "4d")) {

  var_grupo <- paste0("sinco", grupo)

  resumen <- bd_total_y_sexo %>%
    filter(!is.na(.data[[var_grupo]])) %>%
    group_by(sex, sinco = .data[[var_grupo]]) %>%
    summarise(
      ocup    = sum(ocup * fac_tri),
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
      # NaN (grupos sin observaciones válidas) se convierte en NA
      across(c(edad2d, escol2d), ~ ifelse(is.nan(.x), NA, .x))
    ) %>%
    arrange(sex, sinco) %>%
    select(year, qtr, sex, sinco, ocup, ocuptil,
           edad2d, escol2d, ingreso, til) %>%
    rename(!!var_grupo := sinco)

  archivo_out <- file.path(
    dir_salida,
    paste0("zcalculos_Y", year_sel, "T0", trim_sel, "_", grupo, ".dta")
  )
  write_dta(resumen, archivo_out)
  print(paste0(
    "Guardado: ", archivo_out, " (", nrow(resumen), " filas)"
  ))
}

# 5. Validación rápida contra totales publicados ----------------------------------

# Total de personas ocupadas con código SINCO válido (sex == 0, 1 dígito);
# debe aproximarse a la población ocupada del boletín trimestral del INEGI
# (la diferencia son ocupados sin código de ocupación especificado)
total_ocupados <- bd %>%
  filter(!is.na(sinco1d)) %>%
  summarise(ocup = sum(ocup * fac_tri)) %>%
  pull(ocup)

print(paste0(
  "Personas ocupadas (15-98 años, con SINCO): ",
  format(total_ocupados, big.mark = ",")
))
