# ------------------------------------------------------------------------------
# Paso 3:     Correspondencia SINCO a CIUO-08.
#
#             a) Se lee la hoja "SINCO-CIUO" de las tablas comparativas del
#                INEGI (SINCO 2011, actualización de noviembre de 2012). La
#                tabla tiene una convención implícita: cuando varios grupos
#                unitarios consecutivos de un mismo subgrupo comparten CIUO,
#                el INEGI solo llena la primera fila; los siguientes heredan
#                esa CIUO hasta que cambia el subgrupo. Las filas sin SINCO
#                pero con CIUO son correspondencias adicionales (1 a N) del
#                último grupo unitario. "No tiene correspondencia" marca un
#                huérfano explícito.
#             b) Con la tabla de equivalencia del paso 2 la correspondencia se
#                lleva a los códigos SINCO 2019 que usa la ENOE. Los códigos
#                renumerados reciben la CIUO de su equivalente 2011; los
#                grupos nuevos en 2019 quedan sin correspondencia oficial.
#
# Entradas:   01_Datos/01_catalogos/sinco_tablas_comparativas.xlsx
#             salidas/02_equivalencia_sinco_2019_2011.csv
#             salidas/02_sinco_2019_estructura.csv
# Salidas:    salidas/03_crosswalk_sinco2011_ciuo08.csv
#             salidas/03_crosswalk_sinco2019_ciuo08.csv
#
# Uso:        Rscript 03_crosswalk_sinco_ciuo.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(readxl)

# 1. Lectura de la tabla del INEGI ---------------------------------------------

# Las seis primeras filas son encabezados. Columnas D a G: código SINCO,
# título SINCO, código CIUO, título CIUO (se lee ese rango exacto para que
# readxl no recorra las columnas vacías de la izquierda)
tabla <- read_excel(
  archivo_tablas_inegi, sheet = "SINCO-CIUO", col_names = FALSE,
  range = cell_limits(c(7, 4), c(NA, 7)), col_types = "text"
) %>%
  transmute(
    sinco = as.character(...1),
    sinco_titulo = str_squish(as.character(...2)),
    ciuo = as.character(...3),
    ciuo_titulo = str_squish(as.character(...4))
  ) %>%
  mutate(
    # Los códigos numéricos pierden el cero inicial al leerse; se restaura
    # para la CIUO (p. ej. 0110 militares). El SINCO no empieza con cero
    sinco = ifelse(is.na(sinco), NA, as.character(as.integer(as.numeric(sinco)))),
    ciuo = ifelse(is.na(ciuo), NA,
                  str_pad(as.character(as.integer(as.numeric(ciuo))), 4, "left", "0")),
    sin_correspondencia = str_detect(
      coalesce(ciuo_titulo, ""), "No tiene correspondencia"
    )
  )

# 2. Reconstrucción de pares con la regla de herencia ---------------------------

# Se recorre la tabla fila por fila (como lo haría una lectura humana de la
# hoja), llevando el contexto del grupo unitario y del subgrupo activos
pares <- list()
sinco_4d_activo <- NA_character_
titulo_4d_activo <- NA_character_
ciuo_heredable <- NA_character_
ciuo_heredable_titulo <- NA_character_

agregar <- function(sinco, titulo, ciuo, ciuo_titulo, origen) {
  pares[[length(pares) + 1]] <<- tibble(
    sinco_2011 = sinco, sinco_2011_titulo = titulo,
    ciuo_4d = ciuo, ciuo_titulo = ciuo_titulo, origen = origen
  )
}

for (i in seq_len(nrow(tabla))) {
  fila <- tabla[i, ]
  if (!is.na(fila$sinco)) {
    nivel <- nchar(fila$sinco)
    if (nivel < 4) {
      # Cambio de división, grupo o subgrupo: se reinicia la herencia
      sinco_4d_activo <- NA_character_
      ciuo_heredable <- NA_character_
      ciuo_heredable_titulo <- NA_character_
      next
    }
    sinco_4d_activo <- fila$sinco
    titulo_4d_activo <- fila$sinco_titulo
    if (!is.na(fila$ciuo)) {
      agregar(fila$sinco, fila$sinco_titulo, fila$ciuo, fila$ciuo_titulo,
              "directo")
      ciuo_heredable <- fila$ciuo
      ciuo_heredable_titulo <- fila$ciuo_titulo
    } else if (fila$sin_correspondencia) {
      agregar(fila$sinco, fila$sinco_titulo, NA, "No tiene correspondencia",
              "sin_correspondencia_explicita")
      ciuo_heredable <- NA_character_
    } else if (!is.na(ciuo_heredable)) {
      agregar(fila$sinco, fila$sinco_titulo, ciuo_heredable,
              ciuo_heredable_titulo, "heredado_3d")
    } else {
      agregar(fila$sinco, fila$sinco_titulo, NA, NA, "sin_ciuo_en_tabla")
    }
  } else if (!is.na(fila$ciuo) && !is.na(sinco_4d_activo)) {
    # Fila sin SINCO con CIUO: correspondencia adicional del grupo activo.
    # No cambia la CIUO heredable (la herencia usa la primera correspondencia)
    agregar(sinco_4d_activo, titulo_4d_activo, fila$ciuo, fila$ciuo_titulo,
            "adicional_1n")
  }
}

crosswalk_2011 <- bind_rows(pares) %>%
  distinct(sinco_2011, ciuo_4d, .keep_all = TRUE) %>%
  # Si un SINCO tiene alguna CIUO real, se eliminan sus filas vacías
  group_by(sinco_2011) %>%
  filter(!is.na(ciuo_4d) | all(is.na(ciuo_4d))) %>%
  ungroup()

print(paste0("Crosswalk SINCO 2011 a CIUO-08: ", nrow(crosswalk_2011),
             " pares; ", n_distinct(crosswalk_2011$sinco_2011),
             " grupos unitarios 2011"))
print(crosswalk_2011 %>% count(origen))

write_csv(crosswalk_2011, archivo_crosswalk_2011, na = "")

# 3. Traslado a los códigos SINCO 2019 ------------------------------------------

equivalencia <- read_csv(archivo_equivalencia, col_types = cols(.default = "c"))
estructura <- read_csv(archivo_sinco_estructura, col_types = cols(.default = "c"))

# Verificación: todo código 2011 de la equivalencia debe existir en la tabla
no_en_tabla <- setdiff(na.omit(equivalencia$sinco_2011), crosswalk_2011$sinco_2011)
print(paste0("Códigos 2011 de la equivalencia ausentes en la tabla INEGI: ",
             length(no_en_tabla), " ", paste(no_en_tabla, collapse = " ")))
no_en_equiv <- setdiff(crosswalk_2011$sinco_2011, na.omit(equivalencia$sinco_2011))
print(paste0("Códigos 2011 de la tabla INEGI sin uso en 2019 (fusionados o ",
             "eliminados): ", length(no_en_equiv), " ",
             paste(no_en_equiv, collapse = " ")))

crosswalk_2019 <- estructura %>%
  filter(!unitario_4d %in% codigos_operativos_enoe) %>%
  select(sinco_2019 = unitario_4d, sinco_2019_titulo = unitario_titulo) %>%
  left_join(equivalencia %>% select(sinco_2019, sinco_2011, tipo),
            by = "sinco_2019") %>%
  left_join(crosswalk_2011, by = "sinco_2011",
            relationship = "many-to-many") %>%
  mutate(
    origen = case_when(
      tipo == "nuevo_en_2019" ~ "nuevo_en_2019_sin_tabla",
      TRUE ~ origen
    ),
    via_equivalencia = tipo == "renumerado"
  ) %>%
  select(sinco_2019, sinco_2019_titulo, sinco_2011, sinco_2011_titulo,
         ciuo_4d, ciuo_titulo, origen, via_equivalencia) %>%
  arrange(sinco_2019, ciuo_4d)

stopifnot(all(estructura$unitario_4d[!estructura$unitario_4d %in%
                                       codigos_operativos_enoe] %in%
                crosswalk_2019$sinco_2019))

print(paste0("Crosswalk SINCO 2019 a CIUO-08: ", nrow(crosswalk_2019),
             " pares; grupos unitarios con alguna CIUO: ",
             n_distinct(crosswalk_2019$sinco_2019[!is.na(crosswalk_2019$ciuo_4d)]),
             " de ", n_distinct(crosswalk_2019$sinco_2019)))
print(crosswalk_2019 %>% distinct(sinco_2019, origen) %>% count(origen))
print("Grupos que reciben su CIUO por la equivalencia 2019-2011 (renumerados):")
print(crosswalk_2019 %>% filter(via_equivalencia) %>%
        select(sinco_2019, sinco_2019_titulo, sinco_2011, ciuo_4d, ciuo_titulo) %>%
        mutate(across(ends_with("titulo"), ~ str_sub(.x, 1, 38))), n = 30)

write_csv(crosswalk_2019, archivo_crosswalk_2019, na = "")
print(paste0("Escrito: ", archivo_crosswalk_2019))
