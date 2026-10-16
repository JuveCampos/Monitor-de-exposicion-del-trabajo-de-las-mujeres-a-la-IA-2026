# ------------------------------------------------------------------------------
# Paso 10:    Verificación del flujo contra los archivos que hoy usa la app.
#
#             a) Los archivos de la ENOE (pasos 7 y 9) deben ser idénticos a
#                los de 01_Datos/03_enoe_procesada (mismo código, mismos
#                microdatos).
#             b) El catálogo nuevo (paso 8) se compara con el vigente
#                (04_Aplicación/catalogos_sinco/sinco_con_exposicion_ia_es.csv):
#                ocupaciones que cambian de categoría y cuánta población
#                ocupada mueven, y las cifras de cabecera del Monitor con uno
#                y otro catálogo (porcentaje de mujeres y hombres en exposición
#                significativa o máxima, porcentaje en "Mixto", etc.).
#
# Salida:     salidas/10_verificacion.md
#
# Uso:        Rscript 10_verificacion.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(haven)

periodo <- paste0(anio_enoe, "-T", trim_enoe)
lineas <- c(paste0("# Verificación del flujo 05_Reproduccion_R (ENOE ", periodo, ")"),
            "", paste0("Generado el ", format(Sys.Date(), "%d de %B de %Y"), "."), "")

# 1. Archivos de la ENOE ------------------------------------------------------------

lineas <- c(lineas, "## 1. Archivos de la ENOE", "")
for (g in c("1d", "2d", "3d", "4d", "stem_campos", "4d_stem")) {
  nombre <- paste0("zcalculos_Y", anio_enoe, "T0", trim_enoe, "_", g, ".dta")
  nuevo <- file.path(dir_enoe_salidas, nombre)
  vigente <- file.path(dir_repo, "01_Datos", "03_enoe_procesada", nombre)
  if (!file.exists(vigente)) {
    lineas <- c(lineas, paste0("- ", nombre, ": no hay archivo vigente para comparar."))
    next
  }
  a <- as.data.frame(read_dta(nuevo))
  b <- as.data.frame(read_dta(vigente))
  iguales <- isTRUE(all.equal(a, b, check.attributes = FALSE))
  lineas <- c(lineas, paste0("- ", nombre, ": ", nrow(a), " filas; ",
                             ifelse(iguales, "idéntico al vigente.",
                                    "DIFIERE del vigente.")))
}

# 2. Catálogos ----------------------------------------------------------------------

nuevo <- read_csv(archivo_catalogo_app, col_types = cols(.default = "c"))
vigente <- read_csv(
  file.path(dir_repo, "04_Aplicación", "catalogos_sinco", "sinco_con_exposicion_ia_es.csv"),
  col_types = cols(.default = "c")
) %>%
  mutate(unitario_4d = str_pad(unitario_4d, 4, "left", "0"))

poblacion <- read_dta(file.path(
  dir_enoe_salidas, paste0("zcalculos_Y", anio_enoe, "T0", trim_enoe, "_4d.dta")
)) %>%
  mutate(unitario_4d = str_pad(as.character(sinco4d), 4, "left", "0")) %>%
  select(unitario_4d, sex, ocup)

# Cifras de cabecera con cada catálogo
cifras <- function(catalogo, nombre) {
  poblacion %>%
    left_join(catalogo %>% select(unitario_4d, potencial_ia_2025), by = "unitario_4d") %>%
    group_by(sex) %>%
    summarise(
      ocupados = sum(ocup),
      pct_alta = 100 * sum(ocup[potencial_ia_2025 %in%
                                  c("Exposed: Gradient 3", "Exposed: Gradient 4")]) / ocupados,
      pct_gradientes = 100 * sum(ocup[str_detect(coalesce(potencial_ia_2025, ""),
                                                 "Gradient")]) / ocupados,
      pct_mixto = 100 * sum(ocup[potencial_ia_2025 %in% "Mixto"]) / ocupados,
      pct_sin_categoria = 100 * sum(ocup[is.na(potencial_ia_2025)]) / ocupados,
      .groups = "drop"
    ) %>%
    mutate(catalogo = nombre, sexo = c("Total", "Hombres", "Mujeres")[sex + 1]) %>%
    select(catalogo, sexo, ocupados, pct_alta, pct_gradientes, pct_mixto,
           pct_sin_categoria)
}

tabla_cifras <- bind_rows(cifras(vigente, "vigente"), cifras(nuevo, "nuevo")) %>%
  arrange(sexo, catalogo)

lineas <- c(lineas, "", "## 2. Cifras de cabecera con el catálogo vigente y el nuevo", "",
            "| Catálogo | Sexo | Ocupados | % en significativa o máxima | % en algún gradiente | % en Mixto | % sin categoría |",
            "|---|---|---:|---:|---:|---:|---:|")
for (i in seq_len(nrow(tabla_cifras))) {
  f <- tabla_cifras[i, ]
  lineas <- c(lineas, sprintf("| %s | %s | %s | %.2f | %.2f | %.2f | %.2f |",
                              f$catalogo, f$sexo, format(f$ocupados, big.mark = ","),
                              f$pct_alta, f$pct_gradientes, f$pct_mixto,
                              f$pct_sin_categoria))
}

# Ocupaciones cuya categoría cambia
cambios <- nuevo %>%
  select(unitario_4d, unitario_titulo, cat_nueva = potencial_ia_2025,
         ciuo_nueva = ciuo08_4d_correspondientes, estado_nuevo = estado_score) %>%
  full_join(vigente %>% select(unitario_4d, cat_vigente = potencial_ia_2025,
                               ciuo_vigente = ciuo08_4d_correspondientes,
                               estado_vigente = estado_score),
            by = "unitario_4d") %>%
  filter(coalesce(cat_nueva, "(sin categoría)") != coalesce(cat_vigente, "(sin categoría)")) %>%
  left_join(poblacion %>% filter(sex == 0) %>% select(unitario_4d, ocup_total = ocup),
            by = "unitario_4d") %>%
  left_join(poblacion %>% filter(sex == 2) %>% select(unitario_4d, ocup_mujeres = ocup),
            by = "unitario_4d") %>%
  mutate(across(c(ocup_total, ocup_mujeres), ~ replace_na(.x, 0))) %>%
  arrange(desc(ocup_total))

lineas <- c(lineas, "", paste0("## 3. Ocupaciones que cambian de categoría: ", nrow(cambios)), "",
            paste0("Población ocupada que cambia de categoría: ",
                   format(sum(cambios$ocup_total), big.mark = ","), " personas (",
                   format(sum(cambios$ocup_mujeres), big.mark = ","), " mujeres)."), "",
            "| SINCO | Ocupación | Ocupados | Mujeres | Vigente | Nueva | CIUO vigente | CIUO nueva |",
            "|---|---|---:|---:|---|---|---|---|")
for (i in seq_len(nrow(cambios))) {
  f <- cambios[i, ]
  lineas <- c(lineas, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |",
                              f$unitario_4d, str_sub(coalesce(f$unitario_titulo, ""), 1, 60),
                              format(f$ocup_total, big.mark = ","),
                              format(f$ocup_mujeres, big.mark = ","),
                              coalesce(f$cat_vigente, "(sin categoría)"),
                              coalesce(f$cat_nueva, "(sin categoría)"),
                              coalesce(f$ciuo_vigente, ""), coalesce(f$ciuo_nueva, "")))
}

writeLines(lineas, file.path(dir_salidas, "10_verificacion.md"))
print(tabla_cifras)
print(paste0("Ocupaciones que cambian de categoría: ", nrow(cambios), " (",
             format(sum(cambios$ocup_total), big.mark = ","), " personas)"))
print(paste0("Escrito: ", file.path(dir_salidas, "10_verificacion.md")))
