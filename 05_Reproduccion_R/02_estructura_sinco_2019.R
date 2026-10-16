# ------------------------------------------------------------------------------
# Paso 2:     Estructura oficial del SINCO 2019 tal como la codifica la ENOE y
#             tabla de equivalencia SINCO 2019 a SINCO 2011.
#
#             a) Del documento "ENOE. Clasificaciones" (INEGI, 2023) se extraen
#                las 9 divisiones, 62 grupos principales, 163 subgrupos y 490
#                grupos unitarios del SINCO 2019 con sus títulos.
#             b) Del anexo del documento SINCO 2019 (INEGI) se extrae la tabla
#                de equivalencia entre los códigos 2019 y 2011. Esta tabla es
#                la que permite usar la correspondencia oficial SINCO 2011 a
#                CIUO-08 (la única que el INEGI ha publicado) con los códigos
#                2019 que reporta la ENOE.
#
# Entradas:   insumos/INEGI_ENOE_clasificaciones_2023.pdf
#             01_Datos/02_sinco/SINCO_2019.pdf
# Salidas:    salidas/02_sinco_2019_estructura.csv
#             salidas/02_equivalencia_sinco_2019_2011.csv
#
# Uso:        Rscript 02_estructura_sinco_2019.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(pdftools)

# 1. Estructura del SINCO 2019 (documento de clasificaciones de la ENOE) ---------

paginas_enoe <- pdf_text(archivo_enoe_clasificaciones_pdf)

# El SINCO ocupa las páginas entre el encabezado "Sistema Nacional de
# Clasificación de Ocupaciones (SINCO) 2019" y la sección siguiente
# (Clasificación Mexicana de Programas de Estudio)
es_pagina_sinco <- str_detect(
  paginas_enoe, "Sistema Nacional de Clasificación de Ocupaciones \\(SINCO\\) 2019"
) & !str_detect(paginas_enoe, "Clasificación Mexicana de Programas de Estudio")

lineas <- paginas_enoe[es_pagina_sinco] %>%
  str_split("\n") %>%
  unlist() %>%
  str_trim()

# Se descartan encabezados, pies de página y líneas vacías
# El número de página es la última línea no vacía de cada página; se quita
# antes de unir las páginas para que no se confunda con un código
quitar_numero_pagina <- function(pagina) {
  l <- str_trim(str_split(pagina, "\n")[[1]])
  l <- l[l != ""]
  if (str_detect(l[length(l)], "^\\d{1,3}$")) l <- l[-length(l)]
  l
}
lineas <- unlist(lapply(paginas_enoe[es_pagina_sinco], quitar_numero_pagina))
lineas <- lineas[!str_detect(
  lineas,
  "^(Clave\\s|\\(Continúa\\)|INEGI\\. Encuesta|Sistema Nacional de Clasificación de Ocupaciones)"
)]

# Clasificación de cada línea: código con título, código solo, o texto suelto
tipo_linea <- case_when(
  str_detect(lineas, "^\\d{1,4}\\s{2,}\\S") ~ "codigo_titulo",
  str_detect(lineas, "^\\d{1,4}$") ~ "codigo_solo",
  TRUE ~ "texto"
)

# Un número solo puede ser número de página o un código con título partido.
# Es código si la línea anterior y la siguiente son texto suelto (las dos
# mitades del título); de lo contrario es número de página y se descarta
es_codigo_partido <- tipo_linea == "codigo_solo" &
  lag(tipo_linea, default = "texto") == "texto" &
  lead(tipo_linea, default = "texto") == "texto"
es_pagina <- tipo_linea == "codigo_solo" & !es_codigo_partido

# Reconstrucción: se recorre la lista y se arma cada entrada. Un texto suelto
# que sigue inmediatamente a una entrada con código se considera continuación
# de su título (título que se partió después del código)
entradas <- list()
i <- 1
n <- length(lineas)
while (i <= n) {
  if (es_pagina[i]) {
    i <- i + 1
    next
  }
  if (tipo_linea[i] == "codigo_titulo") {
    partes <- str_match(lineas[i], "^(\\d{1,4})\\s{2,}(.*)$")
    codigo <- partes[2]
    titulo <- partes[3]
    j <- i + 1
    # Continuaciones: texto suelto que no sea la primera mitad de un código
    # partido (es decir, que no vaya seguido de un código solo)
    while (j <= n && tipo_linea[j] == "texto" &&
           !(j < n && es_codigo_partido[j + 1])) {
      titulo <- paste(titulo, lineas[j])
      j <- j + 1
    }
    entradas[[length(entradas) + 1]] <- tibble(codigo = codigo, titulo = titulo)
    i <- j
    next
  }
  if (es_codigo_partido[i]) {
    codigo <- lineas[i]
    titulo <- paste(lineas[i - 1], lineas[i + 1])
    j <- i + 2
    while (j <= n && tipo_linea[j] == "texto" &&
           !(j < n && es_codigo_partido[j + 1])) {
      titulo <- paste(titulo, lineas[j])
      j <- j + 1
    }
    entradas[[length(entradas) + 1]] <- tibble(codigo = codigo, titulo = titulo)
    i <- j
    next
  }
  # Texto suelto que es la primera mitad de un código partido: se procesa
  # cuando llegue el código
  i <- i + 1
}

estructura_larga <- bind_rows(entradas) %>%
  mutate(
    titulo = str_squish(titulo),
    nivel = nchar(codigo)
  )

print(estructura_larga %>% count(nivel))
# Validación: 9 divisiones, 163 subgrupos y 490 grupos unitarios (INEGI,
# ENOE Clasificaciones 2023, p. 29) y consistencia interna de los niveles
# (cada prefijo de un grupo unitario debe existir como código del nivel
# superior y viceversa). El documento del INEGI dice "62 grupos principales",
# pero su propio listado contiene 52; se valida contra el listado.
prefijos <- function(nivel_sel) {
  unique(str_sub(estructura_larga$codigo[estructura_larga$nivel == 4], 1, nivel_sel))
}
stopifnot(
  sum(estructura_larga$nivel == 1) == 9,
  sum(estructura_larga$nivel == 3) == 163,
  sum(estructura_larga$nivel == 4) == 490,
  !any(duplicated(estructura_larga$codigo)),
  setequal(estructura_larga$codigo[estructura_larga$nivel == 1], prefijos(1)),
  setequal(estructura_larga$codigo[estructura_larga$nivel == 2], prefijos(2)),
  setequal(estructura_larga$codigo[estructura_larga$nivel == 3], prefijos(3))
)

# Tabla jerárquica: una fila por grupo unitario con los títulos de los
# niveles superiores
titulos <- function(nivel_sel) {
  estructura_larga %>%
    filter(nivel == nivel_sel) %>%
    select(codigo, titulo)
}

sinco_estructura <- estructura_larga %>%
  filter(nivel == 4) %>%
  transmute(
    division_1d = str_sub(codigo, 1, 1),
    grupo_principal_2d = str_sub(codigo, 1, 2),
    subgrupo_3d = str_sub(codigo, 1, 3),
    unitario_4d = codigo,
    unitario_titulo = titulo
  ) %>%
  left_join(titulos(1) %>% rename(division_titulo = titulo),
            by = c("division_1d" = "codigo")) %>%
  left_join(titulos(2) %>% rename(grupo_principal_titulo = titulo),
            by = c("grupo_principal_2d" = "codigo")) %>%
  left_join(titulos(3) %>% rename(subgrupo_titulo = titulo),
            by = c("subgrupo_3d" = "codigo")) %>%
  select(division_1d, division_titulo, grupo_principal_2d,
         grupo_principal_titulo, subgrupo_3d, subgrupo_titulo,
         unitario_4d, unitario_titulo) %>%
  arrange(unitario_4d)

stopifnot(!any(is.na(sinco_estructura$subgrupo_titulo)))

# Códigos operativos de la ENOE (no son grupos unitarios del SINCO, pero la
# encuesta los reporta en p3) se agregan para que el catálogo los reconozca
operativos <- tibble(
  division_1d = c("0", "1", "1"),
  division_titulo = c("Código operativo ENOE", "Código operativo ENOE",
                      "Código operativo ENOE"),
  grupo_principal_2d = c("09", "10", "10"),
  grupo_principal_titulo = "Código operativo ENOE",
  subgrupo_3d = c("098", "100", "100"),
  subgrupo_titulo = "Código operativo ENOE",
  unitario_4d = c("0980", "1006", "1008"),
  unitario_titulo = c("Trabajadores en otro país", "Limosneros",
                      "No trabaja (otros inactivos)")
)

sinco_estructura <- bind_rows(sinco_estructura, operativos) %>%
  arrange(unitario_4d)

write_csv(sinco_estructura, archivo_sinco_estructura)
print(paste0("Estructura SINCO 2019: ", nrow(sinco_estructura),
             " códigos (490 grupos unitarios + 3 operativos). Escrito: ",
             archivo_sinco_estructura))

# 2. Tabla de equivalencia SINCO 2019 a 2011 (anexo del documento SINCO 2019) ----

paginas_sinco <- pdf_text(archivo_sinco_2019_pdf)
es_pagina_equiv <- str_detect(paginas_sinco, "SINCO 2019\\s+SINCO 2011") |
  str_detect(paginas_sinco, "Tabla de equivalencia SINCO 2011 - 2019")
# La primera coincidencia es el índice; se conserva solo el bloque del anexo
indices <- which(es_pagina_equiv)
indices <- indices[indices > 300]
print(paste0("Páginas del anexo de equivalencia: ", min(indices), " a ",
             max(indices)))

pares <- list()
for (p in indices) {
  lineas_p <- str_split(paginas_sinco[p], "\n")[[1]]
  # Posición donde empieza la columna de 2011 en esta página: la mediana de la
  # posición del segundo código en las líneas que traen los dos códigos
  pos_segundo <- str_locate(
    lineas_p, "^\\s*\\d{4}\\s+.*?\\s{2,}(\\d{4})\\b"
  )[, "end"] - 3
  pos_segundo <- pos_segundo[!is.na(pos_segundo)]
  if (length(pos_segundo) == 0) next
  corte <- round(median(pos_segundo)) - 2
  for (k in seq_along(lineas_p)) {
    l <- lineas_p[k]
    # Caso 1: los dos códigos vienen en la misma línea
    m_doble <- str_match(
      l, "^\\s*(\\d{4})\\s+(.*?)\\s+(\\d{4})(?:\\s{2,}(.*)|\\s*)$"
    )
    if (!is.na(m_doble[1])) {
      pares[[length(pares) + 1]] <- tibble(
        sinco_2019 = m_doble[2],
        titulo_2019 = str_squish(m_doble[3]),
        sinco_2011 = m_doble[4],
        titulo_2011 = str_squish(coalesce(m_doble[5], ""))
      )
      next
    }
    # Caso 2: solo hay código 2019 en la columna izquierda; el código 2011
    # puede estar en la línea anterior o en las dos siguientes (títulos que
    # ocupan más de un renglón), o no existir (grupo nuevo en 2019)
    izq <- str_trim(str_sub(l, 1, corte))
    m_izq <- str_match(izq, "^(\\d{4})(?:\\s+(.*))?$")
    if (is.na(m_izq[1])) next
    cod_2011 <- NA_character_
    tit_2011 <- ""
    candidatos <- c(k - 1, k + 1, k + 2)
    candidatos <- candidatos[candidatos >= 1 & candidatos <= length(lineas_p)]
    for (k2 in candidatos) {
      izq2 <- str_trim(str_sub(lineas_p[k2], 1, corte))
      der2 <- str_trim(str_sub(lineas_p[k2], corte + 1))
      # Si la línea vecina tiene su propio código, ahí termina la búsqueda
      # hacia adelante (y hacia atrás solo se mira la línea inmediata)
      if (str_detect(izq2, "^\\d{1,4}(\\s|$)")) {
        if (k2 > k) break else next
      }
      m2 <- str_match(der2, "^(\\d{4})\\b")[2]
      if (!is.na(m2)) {
        cod_2011 <- m2
        tit_2011 <- str_trim(str_remove(der2, "^\\d{4}"))
        break
      }
    }
    m_izq[3] <- coalesce(m_izq[3], "")
    pares[[length(pares) + 1]] <- tibble(
      sinco_2019 = m_izq[2],
      titulo_2019 = str_squish(m_izq[3]),
      sinco_2011 = cod_2011,
      titulo_2011 = str_squish(tit_2011)
    )
  }
}

equivalencia <- bind_rows(pares) %>%
  distinct(sinco_2019, .keep_all = TRUE) %>%
  mutate(
    tipo = case_when(
      is.na(sinco_2011) ~ "nuevo_en_2019",
      sinco_2019 == sinco_2011 ~ "mismo_codigo",
      TRUE ~ "renumerado"
    )
  ) %>%
  arrange(sinco_2019)

print(equivalencia %>% count(tipo))

# Verificación contra la estructura: todos los grupos unitarios 2019 deben
# aparecer en la tabla de equivalencia
faltantes <- setdiff(sinco_estructura$unitario_4d[!sinco_estructura$unitario_4d %in%
                                                     codigos_operativos_enoe],
                     equivalencia$sinco_2019)
print(paste0("Grupos unitarios 2019 sin fila en la equivalencia: ",
             length(faltantes), " ", paste(faltantes, collapse = " ")))

print("Códigos renumerados entre 2011 y 2019:")
print(equivalencia %>% filter(tipo == "renumerado") %>%
        select(sinco_2019, titulo_2019, sinco_2011, titulo_2011), n = 50)
print("Códigos nuevos en 2019 (sin equivalente 2011):")
print(equivalencia %>% filter(tipo == "nuevo_en_2019") %>%
        select(sinco_2019, titulo_2019), n = 50)

write_csv(equivalencia, archivo_equivalencia, na = "")
print(paste0("Escrito: ", archivo_equivalencia))
