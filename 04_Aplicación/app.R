# App Shiny: Treemap de exposición a la IA en el mercado laboral mexicano
# Clasificación SINCO 4 dígitos

library(shiny)
library(haven)
library(tidyverse)
library(plotly)

# --- Parámetros del trimestre ENOE ---
# Para actualizar la app a un nuevo trimestre solo se cambian estas dos
# líneas (el .dta se genera con
# 00_Códigos/Scripts_procesamiento_ENOE_R/01_procesar_enoe_sinco.R)
periodo_enoe <- "2026-T2"
archivo_enoe <- "zcalculos_Y2026T02_4d.dta"
# Formación STEM (salidas de 04_procesar_enoe_stem.R, mismo trimestre)
archivo_stem_campos <- "zcalculos_Y2026T02_stem_campos.dta"
archivo_stem_4d <- "zcalculos_Y2026T02_4d_stem.dta"

# --- Preparación de datos ---
cat_1 <- read_csv(
  "catalogos_sinco/sinco_con_exposicion_ia_es.csv",
  show_col_types = FALSE
) %>%
  mutate(
    subgrupo_3d = str_pad(
      subgrupo_3d, width = 3, side = "left", pad = "0"
    ) %>% as.character()
  ) %>%
  select(
    division_1d, division_titulo, subgrupo_3d,
    unitario_4d, unitario_titulo, potencial_ia_2025,
    score_minimo, score_maximo, score_imputado,
    clasificacion_provisional, descripcion_ia_es
  ) %>%
  unique()

bd <- read_dta(archivo_enoe) %>%
  mutate(
    sinco4d = str_pad(sinco4d, width = 3, side = "left", pad = "0")
  ) %>%
  left_join(cat_1, by = c("sinco4d" = "unitario_4d"))

# --- Función de flexión de género en títulos de ocupación ---
# Transforma palabras con género gramatical según el sexo
# seleccionado, conservando unitario_titulo como original.

# Palabras invariables (no se tocan)
palabras_invariables <- c(
  "de", "del", "en", "y", "e", "o", "la", "las", "el",
  "los", "al", "a", "por", "para", "con", "sin", "no",
  "que", "su", "sus", "otro", "otra", "así", "como",
  "excepto", "forma"
)

# Excepciones: masculino -> femenino (casos irregulares)
excepciones_fem <- c(
  "Sacerdotes"    = "Religiosas",
  "sacerdotes"    = "religiosas",
  "Monjas"        = "Monjas",
  "Mozos"         = "Mozas",
  "mozos"         = "mozas",
  "Choferes"      = "Choferes",
  "choferes"      = "choferes",
  "Edecanes"      = "Edecanes",
  "Modelos"       = "Modelos",
  "Agentes"       = "Agentes",
  "agentes"       = "agentes",
  "Cantineros"    = "Cantineras",
  "cantineros"    = "cantineras",
  "Parteras"      = "Parteras",
  "parteras"      = "parteras"
)

# Excepciones: masculino -> inclusivo
excepciones_inc <- c(
  "Sacerdotes"    = "Sacerdotes/Religiosas",
  "sacerdotes"    = "sacerdotes/religiosas",
  "Monjas"        = "Monjas/Religiosos",
  "Mozos"         = "Mozos/as",
  "mozos"         = "mozos/as",
  "Parteras"      = "Parteros/as",
  "parteras"      = "parteros/as"
)

# Función que transforma UNA palabra
flexionar_palabra <- function(palabra, modo) {
  # modo: "fem", "inc", "masc"
  if (modo == "masc") {
    if (palabra %in% names(flexion_especial_masc)) {
      return(flexion_especial_masc[palabra])
    }
    return(palabra)
  }

  # Revisar excepciones
  if (modo == "fem" && palabra %in% names(excepciones_fem)) {
    return(excepciones_fem[palabra])
  }
  if (modo == "inc" && palabra %in% names(excepciones_inc)) {
    return(excepciones_inc[palabra])
  }

  # Flexiones especiales
  if (modo == "fem" && palabra %in% names(flexion_especial_fem)) {
    return(flexion_especial_fem[palabra])
  }
  if (modo == "inc" && palabra %in% names(flexion_especial_inc)) {
    return(flexion_especial_inc[palabra])
  }

  # Invariables
  if (tolower(palabra) %in% palabras_invariables) return(palabra)

  # No transformar palabras cortas (<4 letras)
  if (nchar(palabra) < 4) return(palabra)

  # Reglas por sufijo (orden importa: más específico primero)
  if (modo == "fem") {
    # -dores -> -doras
    if (str_detect(palabra, "dores$")) {
      return(str_replace(palabra, "dores$", "doras"))
    }
    # -tores -> -toras
    if (str_detect(palabra, "tores$")) {
      return(str_replace(palabra, "tores$", "toras"))
    }
    # -sores -> -soras
    if (str_detect(palabra, "sores$")) {
      return(str_replace(palabra, "sores$", "soras"))
    }
    # -eros -> -eras
    if (str_detect(palabra, "eros$")) {
      return(str_replace(palabra, "eros$", "eras"))
    }
    # -ores -> -oras (genérico)
    if (str_detect(palabra, "ores$")) {
      return(str_replace(palabra, "ores$", "oras"))
    }
    # -arios -> -arias
    if (str_detect(palabra, "arios$")) {
      return(str_replace(palabra, "arios$", "arias"))
    }
    # -icos -> -icas (Técnicos, Médicos)
    if (str_detect(palabra, "icos$")) {
      return(str_replace(palabra, "icos$", "icas"))
    }
    # -logos -> -logas (Psicólogos, Nutriólogos)
    if (str_detect(palabra, "logos$")) {
      return(str_replace(palabra, "logos$", "logas"))
    }
    # -grafos -> -grafas
    if (str_detect(palabra, "grafos$")) {
      return(str_replace(palabra, "grafos$", "grafas"))
    }
    # -ños -> -ñas
    if (str_detect(palabra, "ños$")) {
      return(str_replace(palabra, "ños$", "ñas"))
    }
    # -ros -> -ras (Arquitectos excluido, pero Maestros, etc.)
    if (str_detect(palabra, "[^e]ros$")) {
      return(str_replace(palabra, "ros$", "ras"))
    }
    # -dos -> -das (Empleados, Ocupados, Clasificados)
    if (str_detect(palabra, "dos$")) {
      return(str_replace(palabra, "dos$", "das"))
    }
    # -tos -> -tas (Arquitectos, Pilotos)
    if (str_detect(palabra, "tos$")) {
      return(str_replace(palabra, "tos$", "tas"))
    }
    # -nos -> -nas (Veterinarios ya cubierto, Artesanos)
    if (str_detect(palabra, "nos$")) {
      return(str_replace(palabra, "nos$", "nas"))
    }
    # -os -> -as (genérico último recurso)
    if (str_detect(palabra, "os$")) {
      return(str_replace(palabra, "os$", "as"))
    }
    # -or -> -ora (singular: Director, Instructor)
    if (str_detect(palabra, "or$")) {
      return(str_replace(palabra, "or$", "ora"))
    }
    # -ero -> -era
    if (str_detect(palabra, "ero$")) {
      return(str_replace(palabra, "ero$", "era"))
    }
  }

  if (modo == "inc") {
    # -dores -> -dores/as
    if (str_detect(palabra, "dores$")) {
      return(paste0(palabra, "/as"))
    }
    # -tores -> -tores/as
    if (str_detect(palabra, "tores$")) {
      return(paste0(palabra, "/as"))
    }
    # -ores -> -ores/as
    if (str_detect(palabra, "ores$")) {
      return(paste0(palabra, "/as"))
    }
    # -eros -> -eros/as
    if (str_detect(palabra, "eros$")) {
      return(paste0(palabra, "/as"))
    }
    # -icos -> -icos/as
    if (str_detect(palabra, "icos$")) {
      return(paste0(palabra, "/as"))
    }
    # -logos -> -logos/as
    if (str_detect(palabra, "logos$")) {
      return(paste0(palabra, "/as"))
    }
    # -dos -> -dos/as
    if (str_detect(palabra, "dos$")) {
      return(paste0(palabra, "/as"))
    }
    # -tos -> -tos/as
    if (str_detect(palabra, "tos$")) {
      return(paste0(palabra, "/as"))
    }
    # -nos -> -nos/as
    if (str_detect(palabra, "nos$")) {
      return(paste0(palabra, "/as"))
    }
    # -os -> -os/as genérico
    if (str_detect(palabra, "os$")) {
      return(paste0(palabra, "/as"))
    }
    # -or -> -or/a
    if (str_detect(palabra, "or$")) {
      return(paste0(palabra, "/a"))
    }
  }

  # Sin transformación
  palabra
}

# Palabras que NO deben transformarse aunque terminen en -os
# (son sustantivos de cosa, no de persona)
sustantivos_cosa <- c(
  "aceites", "aglomerados", "alimentos", "alquiler",
  "animales", "antojitos", "aparatos", "artículos",
  "automóviles", "autobuses", "azulejos",
  "bebidas", "bienes", "bosques", "botes",
  "camiones", "camionetas", "casinos",
  "centros", "cereales", "cigarros",
  "cines", "datos", "deportivos",
  "diversos", "edificios", "equipos",
  "establecimientos", "estacionamientos",
  "eventos", "frutas",
  "gastos", "grupos", "hielos", "hogares",
  "hoteles", "huesos", "humanos",
  "instrumentos",
  "juegos", "jugos", "laboratorios",
  "llaves", "materiales", "medios", "metales",
  "minerales", "motor", "motores",
  "museos", "objetos", "oficios",
  "otros", "parques", "pasajeros",
  "periódicos", "plásticos", "pozos",
  "precios", "productos", "programas", "puestos",
  "recursos", "restaurantes",
  "servicios", "sistemas", "suelos",
  "talleres", "tantos", "textiles",
  "transportes", "vehículos", "videos", "vidrios",
  "desechos", "residuos", "neumáticos",
  "derechos", "seguros", "impuestos",
  "afines", "similares", "muebles",
  "procesos", "preciosos", "minerales",
  "industriales", "aeronáuticos", "náuticos",
  "electrónicos", "mecánicos", "eléctricos",
  "electrodomésticos",
  "computacionales", "informáticos",
  "farmacéuticos", "cosméticos",
  "alcohólicos", "pecuarios", "agrícolas",
  "pesqueros", "acuícolas", "forestales",
  "funerarios", "culturales", "musicales",
  "peligrosos", "portuarios", "ferroviarios",
  "terrestres", "marítimos", "aéreos",
  # Adjetivos de productos/cosas (no de personas)
  "lácteos", "metálicos", "textiles",
  "portátiles", "metalúrgicos",
  "clasificados", "especializados",
  "relacionados",
  "flores", "legumbres", "harinas",
  "verduras", "frutas", "especias",
  "pisos", "techos", "muros", "marcos",
  "deportivos", "deportivas",
  "generales", "familiares", "profesionales",
  "especiales", "personales", "elementales",
  "principales", "municipales",
  "gubernamentales", "jurisdiccionales",
  "comerciales", "financieros",
  "ambulantes",
  # Adjetivos terminados en -or/-ior/-ar (invariables en género)
  "exterior", "interior", "superior", "inferior",
  "anterior", "posterior", "mayor", "menor",
  "mejor", "peor", "particular", "regular",
  "similar", "escolar", "solar", "nuclear",
  "popular", "militar", "familiar",
  # Otros sustantivos de cosa
  "interiores", "exteriores", "llaveros",
  "jardines", "tazas", "etcétera",
  "computadora", "computadoras", "computador"
)

# Preposiciones que marcan fin de flexión del sujeto
preposiciones_corte <- c(
  "de", "del", "en", "para", "por", "con",
  "sin", "que", "a", "al", "sobre", "entre",
  "como", "según", "hasta", "desde", "excepto"
)

# Palabras con flexión especial (no siguen reglas regulares)
flexion_especial_fem <- c(
  "Otros"     = "Otras",
  "otros"     = "otras",
  "jefes"     = "jefas",
  "Jefes"     = "Jefas",
  "pastores"  = "pastoras",
  "Secretarias" = "Secretarias",
  "amas"      = "amas"
)

flexion_especial_inc <- c(
  "Otros"     = "Otros/as",
  "otros"     = "otros/as",
  "jefes"     = "jefes/as",
  "Jefes"     = "Jefes/as",
  "Secretarias" = "Secretarios/as",
  "amas"      = "amos/as"
)

# El SINCO nombra en femenino genérico algunas ocupaciones
# (Secretarias, Enfermeras, Parteras), lo que resulta confuso en la
# vista de hombres. Estas son las únicas palabras que se transforman
# cuando el modo es "masc"; el resto del título se deja intacto.
flexion_especial_masc <- c(
  "Secretarias" = "Secretarios",
  "secretarias" = "secretarios",
  "Enfermeras"  = "Enfermeros",
  "enfermeras"  = "enfermeros",
  "Parteras"    = "Parteros",
  "parteras"    = "parteros",
  "Amas"        = "Amos",
  "amas"        = "amos"
)

# Función que transforma un título completo
flexionar_titulo <- function(titulo, modo) {
  if (is.na(titulo)) return(NA_character_)

  palabras <- str_split(titulo, " ")[[1]]

  # En modo masculino solo se procesan los títulos que contienen alguna
  # de las palabras en femenino genérico del SINCO
  if (modo == "masc") {
    palabras_limpias <- str_remove_all(palabras, "[,()]")
    if (!any(palabras_limpias %in% names(flexion_especial_masc))) {
      return(titulo)
    }
  }

  # Solo flexionar palabras ANTES de la primera preposición.
  # Después de "de", "en", etc., se refiere a otros/cosas y
  # se deja en masculino genérico.
  zona_sujeto <- TRUE

  resultado <- lapply(palabras, function(p) {
    p_limpio <- str_remove_all(p, "[,()]")

    # Detectar preposición → dejar de flexionar
    if (tolower(p_limpio) %in% preposiciones_corte) {
      zona_sujeto <<- FALSE
      return(p)
    }

    # Conectores "y"/"e" no cortan la zona sujeto
    if (tolower(p_limpio) %in% c("y", "e")) return(p)

    # Fuera de zona sujeto: no flexionar
    if (!zona_sujeto) return(p)

    # Excepciones y flexiones especiales tienen prioridad
    if (p_limpio %in% names(excepciones_fem) ||
        p_limpio %in% names(excepciones_inc) ||
        p_limpio %in% names(flexion_especial_fem) ||
        p_limpio %in% names(flexion_especial_inc) ||
        p_limpio %in% names(flexion_especial_masc)) {
      p_flex <- flexionar_palabra(p_limpio, modo)
      sufijo <- str_extract(p, "[,()]+$")
      if (is.na(sufijo)) sufijo <- ""
      return(paste0(p_flex, sufijo))
    }
    if (tolower(p_limpio) %in% sustantivos_cosa) return(p)
    if (tolower(p_limpio) %in% palabras_invariables) return(p)
    if (nchar(p_limpio) < 4) return(p)

    # Flexionar sustantivo/adjetivo de persona
    p_flex <- flexionar_palabra(p_limpio, modo)
    # Restaurar puntuación
    if (p_flex != p_limpio) {
      sufijo <- str_extract(p, "[,()]+$")
      if (is.na(sufijo)) sufijo <- ""
      return(paste0(p_flex, sufijo))
    }
    p
  })

  paste(resultado, collapse = " ")
}

# Vectorizar la función
flexionar_titulos <- function(titulos, modo) {
  sapply(titulos, flexionar_titulo, modo = modo, USE.NAMES = FALSE)
}

# --- Traducción de categorías de exposición ---
traduccion_exposicion <- c(
  "Not Exposed"          = "No expuesto",
  "Minimal Exposure"     = "Exposición mínima",
  "Mixto"                = "Mixto",
  "Exposed: Gradient 1"  = "Exposición baja, alta variabilidad de tareas",
  "Exposed: Gradient 2"  = "Exposición moderada, variabilidad mixta de tareas",
  "Exposed: Gradient 3"  = "Exposición significativa, alta variabilidad de tareas",
  "Exposed: Gradient 4"  = "Exposición máxima, baja variabilidad de tareas"
)

# Crear columna traducida en bd
bd <- bd %>%
  mutate(
    exposicion_ia_es = ifelse(
      is.na(potencial_ia_2025),
      NA_character_,
      traduccion_exposicion[potencial_ia_2025]
    )
  )

# --- Constantes de color y niveles (en español) ---
niveles_exposicion_es <- c(
  "No expuesto",
  "Exposición mínima",
  "Mixto",
  "Exposición baja, alta variabilidad de tareas",
  "Exposición moderada, variabilidad mixta de tareas",
  "Exposición significativa, alta variabilidad de tareas",
  "Exposición máxima, baja variabilidad de tareas"
)

colores_exposicion <- c(
  "No expuesto"          = "#1a9641",
  "Exposición mínima"    = "#7bc96a",
  "Mixto"                = "#ffffbf",
  "Exposición baja, alta variabilidad de tareas"          = "#fee08b",
  "Exposición moderada, variabilidad mixta de tareas"     = "#fdae61",
  "Exposición significativa, alta variabilidad de tareas" = "#f46d43",
  "Exposición máxima, baja variabilidad de tareas"        = "#d73027"
)

color_na <- "#cccccc"

opciones_sexo <- c(
  "Total" = 0,
  "Hombres" = 1,
  "Mujeres" = 2
)

opciones_sector <- c(
  "Todo el mercado laboral" = "all",
  "Funcionarios, directores y jefes" = "1",
  "Profesionistas y técnicos" = "2",
  "Trabajadores auxiliares en actividades administrativas" = "3",
  "Comerciantes, empleados en ventas y agentes de ventas" = "4",
  "Trabajadores en servicios personales y de vigilancia" = "5",
  "Trabajadores en actividades agrícolas, ganaderas, forestales, caza y pesca" = "6",
  "Trabajadores artesanales, en la construcción y otros oficios" = "7",
  "Operadores de maquinaria industrial, ensambladores, choferes y conductores de transporte" = "8",
  "Trabajadores en actividades elementales y de apoyo" = "9"
)

# --- Datos agregados por sexo y exposición (para gráficas comparativas) ---
# Solo hombres y mujeres (excluir total para evitar doble conteo)
etiquetas_sexo <- c("1" = "Hombres", "2" = "Mujeres")
colores_sexo <- c("Hombres" = "#00b783", "Mujeres" = "#6950d8")

# --- Datos ENDUTIH 2024: uso de apps en celular por sexo ---
datos_apps <- tibble::tribble(
  ~uso,                                    ~mujeres, ~hombres, ~total,
  "Mensajería instantánea",                 91.0,     90.2,     90.6,
  "Acceder a redes sociales",               77.7,     78.0,     77.9,
  "Acceder a contenidos de audio y video",  76.7,     79.4,     78.0,
  "Tránsito y navegación asistida",         44.3,     55.2,     49.5,
  "Adquirir bienes o servicios",            33.0,     39.0,     35.8,
  "Acceder a Banca móvil",                  31.1,     36.0,     33.4,
  "Editar fotos o videos",                  29.2,     25.4,     27.4,
  "Jugar",                                  26.9,     37.9,     32.1
) %>%
  arrange(total) %>%
  mutate(uso = factor(uso, levels = uso))

# --- Datos ENDUTIH 2024: acceso a internet y celular ---
datos_endutih <- tibble::tribble(
  ~indicador, ~sexo, ~valor, ~anio, ~fuente,
  "Usuarios de internet", "Hombres", 76.5, 2021L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Mujeres", 74.8, 2021L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Hombres", 79.3, 2022L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Mujeres", 78.1, 2022L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Mujeres", 81.4, 2023L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Hombres", 81.0, 2023L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Hombres", 84.1, 2024L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de internet", "Mujeres", 82.3, 2024L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Hombres", 79.0, 2021L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Mujeres", 77.7, 2021L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Hombres", 80.1, 2022L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Mujeres", 78.5, 2022L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Mujeres", 81.8, 2023L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Hombres", 80.9, 2023L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Hombres", 82.5, 2024L,
    "INEGI, ENDUTIH 2024",
  "Usuarios de teléfono celular", "Mujeres", 81.1, 2024L,
    "INEGI, ENDUTIH 2024"
)

# Calcular brechas 2024
brecha_internet <- datos_endutih %>%
  filter(indicador == "Usuarios de internet", anio == 2024) %>%
  pivot_wider(names_from = sexo, values_from = valor) %>%
  mutate(brecha = Hombres - Mujeres) %>%
  pull(brecha)

brecha_celular <- datos_endutih %>%
  filter(
    indicador == "Usuarios de teléfono celular", anio == 2024
  ) %>%
  pivot_wider(names_from = sexo, values_from = valor) %>%
  mutate(brecha = Hombres - Mujeres) %>%
  pull(brecha)

bd_por_sexo_exp <- bd %>%
  filter(sex %in% c(1, 2), ocup > 0, !is.na(exposicion_ia_es)) %>%
  mutate(
    sexo_label = etiquetas_sexo[as.character(sex)],
    exposicion_ia_es = factor(
      exposicion_ia_es, levels = niveles_exposicion_es
    )
  ) %>%
  group_by(sexo_label, exposicion_ia_es) %>%
  summarise(
    total_ocup = sum(ocup, na.rm = TRUE),
    ingreso_ponderado = weighted.mean(
      ingreso, ocup, na.rm = TRUE
    ),
    til_ponderada = weighted.mean(til, ocup, na.rm = TRUE),
    escol_ponderada = weighted.mean(
      escol2d, ocup, na.rm = TRUE
    ),
    .groups = "drop"
  )

# Porcentajes por sexo
bd_por_sexo_exp <- bd_por_sexo_exp %>%
  group_by(sexo_label) %>%
  mutate(pct_ocup = total_ocup / sum(total_ocup) * 100) %>%
  ungroup()

# Top 10 ocupaciones en exposición significativa/máxima por sexo
niveles_alta_exp <- c(
  "Exposición significativa, alta variabilidad de tareas",
  "Exposición máxima, baja variabilidad de tareas"
)

bd_top10 <- bd %>%
  filter(
    sex %in% c(1, 2), ocup > 0,
    exposicion_ia_es %in% niveles_alta_exp
  ) %>%
  mutate(sexo_label = etiquetas_sexo[as.character(sex)]) %>%
  group_by(sexo_label) %>%
  slice_max(order_by = ocup, n = 10) %>%
  ungroup() %>%
  mutate(
    unitario_titulo_corto = ifelse(
      nchar(unitario_titulo) > 45,
      paste0(substr(unitario_titulo, 1, 42), "..."),
      unitario_titulo
    )
  )

# Totales del top 10 por sexo: se citan en los textos que acompañan a
# las dos gráficas del resumen ejecutivo
totales_top10 <- bd_top10 %>%
  group_by(sexo_label) %>%
  summarise(total = sum(ocup, na.rm = TRUE), .groups = "drop")

total_top10_h <- format(
  round(totales_top10$total[totales_top10$sexo_label == "Hombres"]),
  big.mark = ",", scientific = FALSE
)
total_top10_m <- format(
  round(totales_top10$total[totales_top10$sexo_label == "Mujeres"]),
  big.mark = ",", scientific = FALSE
)

# --- Composición del empleo por división SINCO (ocupaciones de escritorio) ---
# Las divisiones 1 a 3 del SINCO (funcionarios y directivos, profesionistas
# y técnicos, oficinistas) agrupan las ocupaciones "de escritorio", que es
# donde se concentra la exposición directa a la IA generativa. Aquí se
# calcula qué proporción de la población ocupada trabaja en ellas, para el
# total y por sexo. La división se toma del primer dígito del código a
# 4 dígitos para no perder a quienes no tienen división en el catálogo.
etiquetas_division <- c(
  "1" = "Funcionarios y directivos",
  "2" = "Profesionistas y técnicos",
  "3" = "Oficinistas (auxiliares administrativos)",
  "4" = "Comerciantes y ventas",
  "5" = "Servicios personales y vigilancia",
  "6" = "Agropecuarios",
  "7" = "Artesanales y construcción",
  "8" = "Operadores de maquinaria y transporte",
  "9" = "Actividades elementales y de apoyo"
)
divisiones_escritorio <- c("1", "2", "3")

# Azules para las divisiones de escritorio, grises para el resto
colores_division <- c(
  "Funcionarios y directivos"                = "#4f3bb5",
  "Profesionistas y técnicos"                = "#6950d8",
  "Oficinistas (auxiliares administrativos)" = "#a99be9",
  "Comerciantes y ventas"                    = "#c4c4c4",
  "Servicios personales y vigilancia"        = "#d6d6d6",
  "Agropecuarios"                            = "#bdbdbd",
  "Artesanales y construcción"               = "#cfcfcf",
  "Operadores de maquinaria y transporte"    = "#b3b3b3",
  "Actividades elementales y de apoyo"       = "#dedede"
)

etiquetas_poblacion <- c("0" = "Total", "1" = "Hombres", "2" = "Mujeres")

bd_divisiones <- bd %>%
  filter(sex %in% c(0, 1, 2), ocup > 0) %>%
  mutate(
    division = str_sub(sinco4d, 1, 1),
    poblacion = etiquetas_poblacion[as.character(sex)]
  ) %>%
  filter(division %in% names(etiquetas_division)) %>%
  group_by(poblacion, division) %>%
  summarise(total_ocup = sum(ocup, na.rm = TRUE), .groups = "drop") %>%
  group_by(poblacion) %>%
  mutate(pct_ocup = total_ocup / sum(total_ocup) * 100) %>%
  ungroup() %>%
  mutate(
    division_label = factor(
      etiquetas_division[division],
      levels = etiquetas_division
    ),
    escritorio = division %in% divisiones_escritorio,
    # Orden de las barras de arriba hacia abajo: Total, Hombres, Mujeres
    poblacion = factor(poblacion, levels = c("Mujeres", "Hombres", "Total"))
  )

# Participación de las ocupaciones de escritorio por población; se cita
# en el texto y se anota sobre la gráfica
pct_escritorio <- bd_divisiones %>%
  filter(escritorio) %>%
  group_by(poblacion) %>%
  summarise(
    total_ocup = sum(total_ocup),
    pct = sum(pct_ocup),
    .groups = "drop"
  )

formato_pct <- function(x) paste0(format(round(x, 1), nsmall = 1), "%")

pct_escritorio_total <- formato_pct(
  pct_escritorio$pct[pct_escritorio$poblacion == "Total"]
)
pct_escritorio_h <- formato_pct(
  pct_escritorio$pct[pct_escritorio$poblacion == "Hombres"]
)
pct_escritorio_m <- formato_pct(
  pct_escritorio$pct[pct_escritorio$poblacion == "Mujeres"]
)
personas_escritorio_total <- format(
  round(pct_escritorio$total_ocup[pct_escritorio$poblacion == "Total"]),
  big.mark = ",", scientific = FALSE
)

# --- Formación STEM (campo de formación de la carrera en la ENOE) ---
# Personas ocupadas con formación profesional en ciencias, tecnología,
# ingeniería o matemáticas, según el campo de formación reportado en la
# ENOE (cs_p14_c). La definición vive en 04_procesar_enoe_stem.R y replica
# el do-file original: incluye economía y finanzas en ciencias y excluye a
# las ciencias de la salud.
etiquetas_stem <- c(
  "1_S" = "Ciencias",
  "2_T" = "Tecnología (TIC)",
  "3_E" = "Ingeniería",
  "4_M" = "Matemáticas"
)

bd_stem_todos <- read_dta(archivo_stem_campos) %>%
  filter(sex %in% c(1, 2)) %>%
  mutate(sexo_label = etiquetas_sexo[as.character(sex)])

# Proporción de la población ocupada de cada sexo con formación STEM
stem_tasa <- bd_stem_todos %>%
  group_by(sexo_label) %>%
  summarise(
    pct_stem = 100 * sum(ocup[campo_stem != "0_NoSTEM"]) / sum(ocup),
    .groups = "drop"
  )
pct_ocupados_stem_h <- formato_pct(
  stem_tasa$pct_stem[stem_tasa$sexo_label == "Hombres"]
)
pct_ocupados_stem_m <- formato_pct(
  stem_tasa$pct_stem[stem_tasa$sexo_label == "Mujeres"]
)

bd_stem_campos <- bd_stem_todos %>%
  filter(campo_stem != "0_NoSTEM") %>%
  mutate(
    campo_label = factor(etiquetas_stem[campo_stem], levels = etiquetas_stem)
  )

# Participación de las mujeres en cada campo STEM; se usa como etiqueta
# del eje y en el texto
stem_pct_mujeres <- bd_stem_campos %>%
  group_by(campo_label) %>%
  summarise(
    total = sum(ocup),
    mujeres = sum(ocup[sexo_label == "Mujeres"]),
    .groups = "drop"
  ) %>%
  mutate(pct_mujeres = mujeres / total * 100)

total_stem <- sum(bd_stem_campos$ocup)
total_stem_m <- sum(bd_stem_campos$ocup[bd_stem_campos$sexo_label == "Mujeres"])
personas_stem_total <- format(round(total_stem), big.mark = ",")
personas_stem_m <- format(round(total_stem_m), big.mark = ",")
pct_stem_mujeres <- formato_pct(total_stem_m / total_stem * 100)
pct_mujeres_ingenieria <- formato_pct(
  stem_pct_mujeres$pct_mujeres[stem_pct_mujeres$campo_label == "Ingeniería"]
)
pct_mujeres_ciencias <- formato_pct(
  stem_pct_mujeres$pct_mujeres[stem_pct_mujeres$campo_label == "Ciencias"]
)

# Exposición a la IA de las personas con formación STEM, por sexo: se cruza
# la ocupación que desempeñan con el gradiente ya calculado en `bd`
bd_stem_exp <- read_dta(archivo_stem_4d) %>%
  mutate(
    sinco4d = str_pad(sinco4d, width = 3, side = "left", pad = "0")
  ) %>%
  left_join(
    bd %>% distinct(sinco4d, exposicion_ia_es),
    by = "sinco4d"
  ) %>%
  filter(sex %in% c(1, 2), ocup > 0, !is.na(exposicion_ia_es)) %>%
  mutate(
    sexo_label = etiquetas_sexo[as.character(sex)],
    exposicion_ia_es = factor(
      exposicion_ia_es, levels = niveles_exposicion_es
    )
  ) %>%
  group_by(sexo_label, exposicion_ia_es) %>%
  summarise(total_ocup = sum(ocup), .groups = "drop") %>%
  group_by(sexo_label) %>%
  mutate(pct_ocup = total_ocup / sum(total_ocup) * 100) %>%
  ungroup()

stem_alta_exp <- bd_stem_exp %>%
  filter(exposicion_ia_es %in% niveles_alta_exp) %>%
  group_by(sexo_label) %>%
  summarise(pct = sum(pct_ocup), .groups = "drop")
pct_stem_alta_h <- formato_pct(
  stem_alta_exp$pct[stem_alta_exp$sexo_label == "Hombres"]
)
pct_stem_alta_m <- formato_pct(
  stem_alta_exp$pct[stem_alta_exp$sexo_label == "Mujeres"]
)

# --- Función para mapear escolaridad promedio a categoría ---
clasificar_escolaridad <- function(anios) {
  case_when(
    is.na(anios)    ~ "Sin información",
    anios < 1       ~ "Sin instrucción",
    anios < 9       ~ "Básico incompleto",
    anios < 10      ~ "Básico completo",
    anios < 12      ~ "Medio Superior incompleto",
    anios < 13      ~ "Medio Superior completo",
    anios < 17      ~ "Superior incompleto",
    anios < 18      ~ "Superior completo",
    TRUE            ~ "Posgrado"
  )
}

# --- Función para construir texto del hover ---
construir_hover <- function(df) {
  # Las categorías imputadas se señalan como provisionales en el hover;
  # la etiqueta no se altera en exposicion_ia_es porque los colores del
  # treemap se mapean con ese texto
  etiqueta_exposicion <- ifelse(
    df$clasificacion_provisional %in% TRUE &
      df$exposicion_ia_es != "Sin información",
    paste0(df$exposicion_ia_es, " (provisional)"),
    df$exposicion_ia_es
  )
  paste0(
    "<b>", df$titulo_display, "</b>",
    "<br><b>Exposición IA:</b> ", etiqueta_exposicion,
    "<br>──────────────────",
    "<br><b>Población ocupada:</b> ",
    format(round(df$ocup), big.mark = ","),
    "<br><b>Ocupación informal:</b> ",
    format(round(df$ocuptil), big.mark = ","),
    "<br><b>Tasa de informalidad:</b> ",
    format(round(df$til, 1), nsmall = 1), "%",
    "<br>──────────────────",
    "<br><b>Edad promedio:</b> ",
    format(round(df$edad2d, 1), nsmall = 1), " años",
    "<br><b>Escolaridad promedio:</b> ",
    format(round(df$escol2d, 1), nsmall = 1),
    " años (", df$nivel_escolaridad, ")",
    "<br><b>Ingreso mediano:</b> $",
    format(round(df$ingreso), big.mark = ",")
  )
}

# --- Función generadora de treemap ---
generar_treemap <- function(datos, sexo_val, titulo_sexo,
                            sector_val = "all") {

  # Determinar modo de género según sexo
  modo_genero <- case_when(
    sexo_val == 1 ~ "masc",
    sexo_val == 2 ~ "fem",
    TRUE          ~ "inc"
  )

  bd_filtrado <- datos %>%
    filter(sex == sexo_val, ocup > 0) %>%
    mutate(
      exposicion_ia_es = ifelse(
        is.na(exposicion_ia_es),
        "Sin información",
        exposicion_ia_es
      ),
      color_asignado = case_when(
        exposicion_ia_es == "Sin información" ~ color_na,
        TRUE ~ colores_exposicion[exposicion_ia_es]
      ),
      division_titulo = ifelse(
        is.na(division_titulo),
        paste("División", division_1d),
        division_titulo
      ),
      nivel_escolaridad = clasificar_escolaridad(escol2d),
      titulo_display = flexionar_titulos(unitario_titulo, modo_genero)
    )

  # Filtrar por sector si no es "all"
  if (sector_val != "all") {
    bd_filtrado <- bd_filtrado %>%
      filter(division_1d == as.numeric(sector_val))
  }

  divisiones <- bd_filtrado %>%
    distinct(division_1d, division_titulo) %>%
    arrange(division_1d)

  # Determinar subtítulo del sector
  subtitulo_sector <- if (sector_val == "all") {
    ""
  } else {
    nombre_sector <- names(opciones_sector)[
      opciones_sector == sector_val
    ]
    paste0(" | ", nombre_sector)
  }

  # Construir hover enriquecido para ocupaciones
  bd_filtrado <- bd_filtrado %>%
    mutate(texto_hover = construir_hover(.))

  # Si hay un solo sector, no necesitamos nivel padre
  if (sector_val != "all") {
    # Treemap plano: solo ocupaciones
    df_tree <- bd_filtrado %>%
      transmute(
        ids = paste0("ocu_", sinco4d),
        labels = titulo_display,
        parents = "",
        values = ocup,
        color = color_asignado,
        texto = texto_hover,
        customdata = sinco4d
      )
  } else {
    # Treemap jerárquico: divisiones -> ocupaciones
    # Flexionar también los títulos de división
    div_display <- flexionar_titulos(
      divisiones$division_titulo, modo_genero
    )

    df_padres <- tibble(
      ids = paste0("div_", divisiones$division_1d),
      labels = div_display,
      parents = "",
      values = 0,
      color = "#ffffff",
      texto = div_display,
      customdata = ""
    )

    df_hijos <- bd_filtrado %>%
      transmute(
        ids = paste0("div_", division_1d, "_", sinco4d),
        labels = titulo_display,
        parents = paste0("div_", division_1d),
        values = ocup,
        color = color_asignado,
        texto = texto_hover,
        customdata = sinco4d
      )

    df_tree <- bind_rows(df_padres, df_hijos)
  }

  plot_ly(
    type = "treemap",
    ids = df_tree$ids,
    labels = df_tree$labels,
    parents = df_tree$parents,
    values = df_tree$values,
    text = df_tree$texto,
    customdata = df_tree$customdata,
    hoverinfo = "text",
    textinfo = "label",
    marker = list(
      colors = df_tree$color,
      line = list(width = 0.5, color = "#ffffff")
    ),
    textfont = list(family = "Ubuntu"),
    pathbar = list(textfont = list(family = "Ubuntu")),
    hoverlabel = list(
      font = list(family = "Ubuntu", size = 13)
    ),
    source = "treemap_src"
  ) %>%
    layout(
      font = list(family = "Ubuntu"),
      hoverlabel = list(font = list(family = "Ubuntu")),
      margin = list(t = 10)
    ) %>%
    event_register("plotly_click")
}

# --- Banda ilustrada ---
# Imagen de apertura de cada sección, con una leyenda corta sobre una
# franja morada. Las imágenes viven en www/ilustraciones/; hoy son fotos
# de stock provisionales y se sustituirán por ilustraciones encargadas.
banda_ilustrada <- function(imagen, texto) {
  div(
    class = "banda-ilustrada",
    style = paste0("background-image: url('ilustraciones/", imagen, "');"),
    div(class = "banda-texto", texto)
  )
}

# --- UI ---
ui <- fluidPage(
  tags$head(
    tags$link(
      href = paste0(
        "https://fonts.googleapis.com/",
        "css2?family=Ubuntu:wght@300;400;500;700&display=swap"
      ),
      rel = "stylesheet"
    ),
    tags$style(HTML("
      body {
        font-family: 'Ubuntu', sans-serif;
        font-size: 19px;
        background-color: #F4F2FB;
      }
      .hero-header {
        max-width: 960px;
        margin: 30px auto 25px auto;
        background-color: #6950d8;
        border-radius: 12px;
        padding: 40px 40px 36px 40px;
        display: flex;
        align-items: center;
        gap: 30px;
        flex-wrap: wrap;
      }
      .hero-texto {
        flex: 1 1 420px;
        text-align: left;
      }
      .hero-logos {
        display: flex;
        align-items: center;
        gap: 14px;
        margin-bottom: 22px;
      }
      .hero-logos img {
        height: 34px;
        width: auto;
        display: block;
      }
      .hero-logos .logo-clave {
        background-color: white;
        border-radius: 6px;
        padding: 4px 8px;
        height: 42px;
      }
      .hero-ilustracion {
        flex: 0 1 300px;
        height: 240px;
        border-radius: 12px;
        overflow: hidden;
        background-size: cover;
        background-position: center;
        box-shadow: 0 4px 20px rgba(0,0,0,0.15);
      }
      /* Bandas ilustradas que abren cada sección (estilo MCV) */
      .banda-ilustrada {
        max-width: 960px;
        height: 210px;
        margin: 10px auto 0 auto;
        border-radius: 12px;
        background-size: cover;
        background-position: center;
        position: relative;
        overflow: hidden;
      }
      .banda-ilustrada .banda-texto {
        position: absolute;
        left: 0; right: 0; bottom: 0;
        padding: 12px 20px;
        background-color: rgba(105,80,216,0.88);
        color: white;
        font-size: 15px;
        line-height: 1.4;
      }
      .banda-mcv {
        max-width: 960px;
        margin: 25px auto 0 auto;
        background-color: #6950d8;
        color: white;
        border-radius: 6px;
        padding: 8px 16px;
        font-size: 12px;
        font-weight: 500;
        letter-spacing: 0.5px;
        text-transform: uppercase;
        text-align: center;
      }
      .hero-header h2 {
        color: #ffffff;
        font-size: 2.2em;
        font-weight: 700;
        margin: 0 0 10px 0;
      }
      .hero-header p {
        color: #ffffff;
        font-size: 1em;
        margin: 0;
        opacity: 0.9;
      }
      .card-section {
        background-color: white;
        border-radius: 8px;
        padding: 20px 25px;
        max-width: 960px;
        margin: 20px auto;
        box-shadow: 0 1px 4px rgba(0,0,0,0.08);
      }
      .leyenda-container {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        padding: 10px 0;
        justify-content: center;
      }
      .leyenda-item {
        display: flex;
        align-items: center;
        gap: 5px;
        font-size: 12px;
      }
      .leyenda-color {
        width: 16px;
        height: 16px;
        border-radius: 3px;
        border: 1px solid #ccc;
      }
      .chart-title {
        font-family: 'Ubuntu', sans-serif;
        font-size: 16px;
        font-weight: 500;
        color: #231f20;
        margin: 0 0 2px 0;
        text-align: center;
      }
      .chart-subtitle {
        font-family: 'Ubuntu', sans-serif;
        font-size: 12px;
        color: #888;
        margin: 0 0 8px 0;
        text-align: center;
      }
      .highlight {
        color: #000;
        font-weight: 700;
        text-decoration: underline;
        text-decoration-color: #6950D8;
        text-decoration-thickness: 3px;
        text-underline-offset: 3px;
      }
      .title-highlight {
        background-color: #6950D8;
        color: white;
        padding: 3px 10px;
        border-radius: 4px;
      }
      .chart-header {
        padding: 12px 15px 8px 15px;
        background-color: white;
        border-radius: 8px 8px 0 0;
        box-shadow: 0 1px 4px rgba(0,0,0,0.08);
      }
      .leyenda-sexo {
        display: flex;
        gap: 18px;
        justify-content: center;
        padding: 4px 0 6px 0;
      }
      .leyenda-sexo .leyenda-item {
        font-size: 12px;
      }
      /* Overlay de carga */
      #loading-overlay {
        display: none;
        position: fixed;
        top: 0; left: 0;
        width: 100%; height: 100%;
        background: rgba(255,255,255,0.85);
        z-index: 9999;
        justify-content: center;
        align-items: center;
        flex-direction: column;
      }
      #loading-overlay.active {
        display: flex;
      }
      .spinner {
        width: 48px; height: 48px;
        border: 5px solid #e0e0e0;
        border-top: 5px solid #231f20;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
      }
      @keyframes spin {
        to { transform: rotate(360deg); }
      }
      .spinner-text {
        margin-top: 14px;
        font-family: 'Ubuntu', sans-serif;
        font-size: 14px;
        color: #231f20;
      }
    ")),
    tags$script(HTML("
      $(document).on('change', '#sexo', function() {
        $('#loading-overlay').addClass('active');
      });
      $(document).on('shiny:value', function(e) {
        if (e.name === 'treemap') {
          $('#loading-overlay').removeClass('active');
        }
      });
    "))
  ),
  div(
    id = "loading-overlay",
    div(class = "spinner"),
    div(class = "spinner-text", "Actualizando visualizaciones...")
  ),
  # --- SILENCIADO: Sección metodológica original ---
  # Se conserva comentada por si se necesita reutilizar.
  # Contenía: "¿Cómo se mide la exposición a la IA?",
  # descripción del mapeo SINCO-CIUO08, fundamento empírico
  # (Gmyrek et al. 52K evaluaciones, método Delphi, LLMs),
  # gradientes de exposición, y bloque colapsable de
  # cobertura y fuentes con referencias a ILO WP140, WP96
  # y Tabla Comparativa SINCO-CIUO08 INEGI (2012).
  # Ver git history para el código completo.
  # --- FIN SILENCIADO ---

  # --- Título general del dashboard ---
  div(
    class = "hero-header",
    div(
      class = "hero-texto",
      div(
        class = "hero-logos",
        tags$img(
          src = "logo_mcv_blanco.svg",
          alt = "México, ¿Cómo Vamos?"
        ),
        tags$img(
          class = "logo-clave",
          src = "clave_logo.png",
          alt = "Clave Igualdad"
        )
      ),
      h2(paste0(
        "Monitor de exposición del trabajo ",
        "de las mujeres a la IA"
      )),
      p(paste0("ENOE ", periodo_enoe, " | Clasificación SINCO a 4 dígitos"))
    ),
    div(
      class = "hero-ilustracion",
      style = "background-image: url('ilustraciones/hero.jpg');"
    )
  ),

  # --- Texto introductorio ---
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "La inteligencia artificial (IA) ya está cambiando ",
        "tareas y ocupaciones, pero ",
        "<span class='highlight'>no lo hace en condiciones ",
        "de igualdad</span>. Este dashboard explora qué tan ",
        "expuestos están los trabajos de las mujeres a la IA ",
        "y cruza esa información con las ",
        "<span class='highlight'>brechas tecnológicas</span> ",
        "que pueden dificultar la adaptación a esa transición."
      ))
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "¿Qué entendemos por exposición a la IA? Se refiere ",
        "al <span class='highlight'>potencial de ",
        "transformación de las tareas</span> dentro ",
        "de una ocupación debido a las herramientas de ",
        "inteligencia artificial. Una ocupación con mayor ",
        "exposición está en ",
        "<span class='highlight'>mayor riesgo de ser ",
        "automatizada</span> por la IA."
      ))
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Esta herramienta busca mostrar a las personas ",
        "tomadoras de decisiones en qué casos este cambio ",
        "puede profundizar desigualdades ya existentes para ",
        "activar, desde ahora, ",
        "<span class='highlight'>estrategias que protejan el ",
        "trabajo digno de las mujeres</span>."
      ))
    )
  ),

  # --- Menú de navegación ---
  div(
    style = paste0(
      "padding: 15px 25px; max-width: 960px; ",
      "margin: 0 auto 15px auto; ",
      "background-color: #f5f5f5; border-radius: 8px; ",
      "text-align: center;"
    ),
    p(
      style = paste0(
        "font-family: 'Ubuntu'; margin-bottom: 4px; ",
        "font-size: 15px;"
      ),
      HTML("<span class='title-highlight'>Dimensiones</span>")
    ),
    p(
      style = paste0(
        "font-family: 'Ubuntu'; font-size: 12px; ",
        "color: #888; margin: 0 0 10px 0;"
      ),
      "Selecciona una sección para ir directamente a ella."
    ),
    HTML(paste0(
      "<div style='display:flex; flex-direction:column; ",
      "align-items:center; gap:6px;'>",
      "<a href='#sec-resumen' ",
      "style='color:#6950d8; font-family:Ubuntu; ",
      "font-size:14px;' ",
      "onclick=\"document.getElementById(",
      "'sec-resumen').scrollIntoView(",
      "{behavior:'smooth'}); return false;\">",
      "Resumen ejecutivo</a>",
      "<a href='#sec-exposicion' ",
      "style='color:#6950d8; font-family:Ubuntu; ",
      "font-size:14px;' ",
      "onclick=\"document.getElementById(",
      "'sec-exposicion').scrollIntoView(",
      "{behavior:'smooth'}); return false;\">",
      "Exposición a la IA</a>",
      "<a href='#sec-brecha' ",
      "style='color:#6950d8; font-family:Ubuntu; ",
      "font-size:14px;' ",
      "onclick=\"document.getElementById(",
      "'sec-brecha').scrollIntoView(",
      "{behavior:'smooth'}); return false;\">",
      "Brecha tecnológica</a>",
      "<a href='#sec-normativa' ",
      "style='color:#6950d8; font-family:Ubuntu; ",
      "font-size:14px;' ",
      "onclick=\"document.getElementById(",
      "'sec-normativa').scrollIntoView(",
      "{behavior:'smooth'}); return false;\">",
      "Normativa</a>",
      "<a href='#sec-conclusion' ",
      "style='color:#6950d8; font-family:Ubuntu; ",
      "font-size:14px;' ",
      "onclick=\"document.getElementById(",
      "'sec-conclusion').scrollIntoView(",
      "{behavior:'smooth'}); return false;\">",
      "Conclusión</a>",
      "</div>"
    ))
  ),

  # --- DataAcción branding ---
  div(
    style = paste0(
      "text-align: center; padding: 15px 25px; ",
      "max-width: 960px; margin: 0 auto;"
    ),
    p(
      style = paste0(
        "font-family: 'Ubuntu'; color: #231f20; ",
        "font-size: 14px; font-style: italic;"
      ),
      paste0(
        "Este producto se generó en el marco de ",
        "DataAcción: Datatón regional para la igualdad"
      )
    ),
    tags$img(
      src = "artboard_1.png.webp",
      style = "max-width: 400px; width: 100%; margin-top: 5px;"
    )
  ),

  # ==========================================================
  # SECCIÓN: Resumen ejecutivo
  # ==========================================================
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    h3(
      id = "sec-resumen",
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Resumen ejecutivo</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "El Monitor de Exposición a la IA permite identificar ",
        "dónde podrían aparecer tensiones antes de que se ",
        "vuelvan brechas más profundas. Los datos sugieren ",
        "poner atención en ",
        "<span class='highlight'>ocupaciones técnicas, ",
        "administrativas y de apoyo donde las mujeres tienen ",
        "una presencia importante</span>, especialmente cuando ",
        "se trata de tareas más estandarizables. Al mismo ",
        "tiempo, el análisis muestra algo importante: ",
        "<span class='highlight'>la exposición a la IA no se ",
        "concentra solo en los trabajos más precarios</span>, ",
        "sino también en ocupaciones con mejores ingresos y ",
        "mayor formalidad, es decir, en espacios clave para la ",
        "estabilidad laboral de muchas mujeres. Más que cerrar ",
        "la discusión, esta herramienta busca abrirla mejor: ",
        "dar insumos para seguir el cambio, orientar decisiones ",
        "y ayudar a que la ",
        "<span class='highlight'>transición tecnológica no ",
        "amplíe desigualdades</span>, sino que contribuya a ",
        "mejorar las condiciones laborales de las mujeres."
      ))
    )
  ),

  # Top 10 hombres y mujeres (dentro de Resumen ejecutivo)
  fluidRow(
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          paste0(
            "Top 10 ocupaciones masculinas en ",
            "exposición significativa y máxima"
          )),
        p(class = "chart-subtitle", paste0("Hombres | ENOE ", periodo_enoe))
      ),
      plotlyOutput("g6_top10_h", height = "450px")
    ),
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          paste0(
            "Top 10 ocupaciones femeninas en ",
            "exposición significativa y máxima"
          )),
        p(class = "chart-subtitle", paste0("Mujeres | ENOE ", periodo_enoe))
      ),
      plotlyOutput("g6_top10_m", height = "450px")
    )
  ),
  fluidRow(
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          HTML(paste0(
            "Las 10 ocupaciones con mayor población masculina ",
            "en las categorías de exposición significativa y ",
            "máxima concentran a ",
            "<span class='highlight'>", total_top10_h,
            " hombres ocupados</span>. Identificar estas ",
            "ocupaciones permite focalizar esfuerzos de ",
            "capacitación y reconversión laboral donde más se ",
            "necesitan."
          ))
        )
      )
    ),
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          HTML(paste0(
            "Las 10 ocupaciones con mayor población femenina ",
            "en las categorías de exposición significativa y ",
            "máxima concentran a ",
            "<span class='highlight'>", total_top10_m,
            " mujeres ocupadas</span>. Estas ocupaciones ponen ",
            "nombre y apellido a los empleos de mujeres más ",
            "expuestos a la transformación por inteligencia ",
            "artificial."
          ))
        )
      )
    )
  ),

  # Composición del empleo por división SINCO (dentro de Resumen ejecutivo)
  fluidRow(
    column(
      12,
      div(
        class = "chart-header",
        p(class = "chart-title",
          paste0(
            "Las ocupaciones de escritorio concentran el ",
            pct_escritorio_total, " del empleo en México"
          )),
        p(class = "chart-subtitle",
          paste0(
            "Distribución porcentual de la población ocupada por ",
            "división SINCO | ENOE ", periodo_enoe
          )),
        div(
          class = "leyenda-container",
          lapply(seq_along(colores_division), function(i) {
            div(class = "leyenda-item",
              div(class = "leyenda-color",
                style = paste0(
                  "background-color:",
                  colores_division[i], ";")),
              span(names(colores_division)[i]))
          })
        )
      ),
      plotlyOutput("g7_divisiones", height = "300px")
    )
  ),
  fluidRow(
    column(
      12,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          HTML(paste0(
            "El grupo expuesto de manera directa a la IA generativa ",
            "es más pequeño en México que en las economías de ",
            "ingresos altos. Las divisiones 1 a 3 del SINCO ",
            "(funcionarios y directivos, profesionistas y técnicos, ",
            "y oficinistas) reúnen a ",
            "<span class='highlight'>", personas_escritorio_total,
            " personas, el ", pct_escritorio_total,
            " de la población ocupada</span>. La proporción es ",
            "mayor entre las mujeres (", pct_escritorio_m,
            ") que entre los hombres (", pct_escritorio_h,
            "): el empleo femenino está más concentrado en los ",
            "escritorios donde la IA ya puede hacer parte de las ",
            "tareas."
          ))
        )
      )
    )
  ),

  # ==========================================================
  # SECCIÓN 1: Exposición a la IA
  # ==========================================================
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    banda_ilustrada(
      "exposicion.jpg",
      "La exposición a la IA no se reparte igual entre ocupaciones ni entre hombres y mujeres."
    ),
    h3(
      id = "sec-exposicion",
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Exposición a la IA</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Medir la exposición a la IA es importante porque ",
        "permite entender ",
        "<span class='highlight'>dónde el cambio tecnológico ",
        "podría transformar con mayor fuerza tareas, ",
        "ocupaciones y condiciones de trabajo</span>, en ",
        "lugar de quedarnos en discusiones abstractas sobre ",
        "si la IA \"va a quitar empleos\" o no. Esa medición ",
        "ayuda a identificar qué grupos, sectores o tipos de ",
        "trabajo podrían necesitar más apoyo, regulación, ",
        "formación o protección para adaptarse en mejores ",
        "condiciones. También vuelve la conversación más ",
        "útil: no se trata solo de saber dónde hay más ",
        "tecnología, sino de ",
        "<span class='highlight'>anticipar dónde pueden ",
        "abrirse oportunidades, dónde pueden profundizarse ",
        "las desigualdades</span> y dónde conviene intervenir ",
        "primero para que la transición no deje a las mujeres ",
        "y otros grupos en condiciones históricas de ",
        "discriminación."
      ))
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Conocer la variabilidad de las tareas permite ",
        "entender si la exposición a la IA afecta de manera ",
        "relativamente uniforme a una ocupación o si se ",
        "concentra en ciertas funciones específicas. Esto ",
        "ayuda a interpretar mejor el tipo de cambio que ",
        "podría implicar la IA: ",
        "<span class='highlight'>sustitución de algunas ",
        "tareas, transformación del puesto o necesidad de ",
        "reconversión profesional</span>."
      ))
    )
  ),

  # --- Treemap: controles y visualización ---
  fluidRow(
    column(
      2,
      selectInput(
        "sexo",
        "Población:",
        choices = opciones_sexo,
        selected = 2
      )
    ),
    column(
      4,
      selectInput(
        "sector",
        "Sector ocupacional:",
        choices = opciones_sector,
        selected = "all"
      )
    ),
    column(
      6,
      div(
        class = "leyenda-container",
        lapply(seq_along(colores_exposicion), function(i) {
          div(
            class = "leyenda-item",
            div(
              class = "leyenda-color",
              style = paste0(
                "background-color:", colores_exposicion[i], ";"
              )
            ),
            span(names(colores_exposicion)[i])
          )
        }),
        div(
          class = "leyenda-item",
          div(
            class = "leyenda-color",
            style = paste0("background-color:", color_na, ";")
          ),
          span("Sin información")
        )
      )
    )
  ),
  div(
    class = "chart-header",
    uiOutput("treemap_titulo")
  ),
  plotlyOutput("treemap", height = "700px"),

  # --- Panel de descripción al hacer click ---
  uiOutput("panel_descripcion_ia"),

  # --- Gráficas comparativas ---
br(), br(), 
  # Fila 1: Gráficas 1 y 2
  fluidRow(
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          "Población en exposición significativa y máxima"),
        p(class = "chart-subtitle",
          paste0("Personal ocupado, por sexo | ENOE ", periodo_enoe)),
        div(
          class = "leyenda-sexo",
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#00b783;"),
            span("Hombres")),
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#6950d8;"),
            span("Mujeres"))
        )
      ),
      plotlyOutput("g1_total_alta_exp", height = "380px")
    ),
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          "Distribución porcentual por grado de exposición"),
        p(class = "chart-subtitle",
          paste0("Personal ocupado, por sexo | ENOE ", periodo_enoe)),
        div(
          class = "leyenda-container",
          lapply(seq_along(colores_exposicion), function(i) {
            div(class = "leyenda-item",
              div(class = "leyenda-color",
                style = paste0(
                  "background-color:",
                  colores_exposicion[i], ";")),
              span(names(colores_exposicion)[i]))
          })
        )
      ),
      plotlyOutput("g2_pct_exposicion", height = "380px")
    )
  ),
  fluidRow(
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          paste0(
            "Esta gráfica muestra el total de personas ocupadas ",
            "en las dos categorías de mayor exposición a la IA: ",
            "exposición significativa y exposición máxima. ",
            "Permite dimensionar cuántos trabajadores y ",
            "trabajadoras se encuentran en las ocupaciones más ",
            "susceptibles de ser transformadas por la ",
            "inteligencia artificial."
          )
        )
      )
    ),
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          paste0(
            "La distribución porcentual permite comparar la ",
            "estructura de exposición entre hombres y mujeres ",
            "independientemente del tamaño de cada grupo. Cada ",
            "barra suma 100% y muestra qué proporción de cada ",
            "sexo se encuentra en cada nivel de exposición a ",
            "la IA."
          )
        )
      )
    )
  ),

  # Fila 2: Gráficas 3 y 4
  fluidRow(
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          "Ingreso mediano ponderado por gradiente"),
        p(class = "chart-subtitle",
          paste0("Personal ocupado, por sexo | ENOE ", periodo_enoe)),
        div(
          class = "leyenda-sexo",
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#00b783;"),
            span("Hombres")),
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#6950d8;"),
            span("Mujeres"))
        )
      ),
      plotlyOutput("g3_ingreso_grad", height = "380px")
    ),
    column(
      6,
      div(
        class = "chart-header",
        p(class = "chart-title",
          "Tasa de informalidad ponderada por gradiente"),
        p(class = "chart-subtitle",
          paste0("Personal ocupado, por sexo | ENOE ", periodo_enoe)),
        div(
          class = "leyenda-sexo",
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#00b783;"),
            span("Hombres")),
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#6950d8;"),
            span("Mujeres"))
        )
      ),
      plotlyOutput("g4_informalidad", height = "380px")
    )
  ),
  fluidRow(
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          paste0(
            "El ingreso mediano ponderado por gradiente de ",
            "exposición revela cómo se relacionan los ingresos ",
            "con el nivel de exposición a la IA. ",
            "Ocupaciones con mayor exposición tienden a ",
            "concentrar trabajadores de mayores ingresos, lo ",
            "cual tiene implicaciones sobre qué segmentos ",
            "salariales podrían verse más afectados."
          )
        )
      )
    ),
    column(
      6,
      div(
        style = "padding: 10px 15px 30px 15px;",
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          paste0(
            "La tasa de informalidad laboral ponderada por ",
            "gradiente de exposición muestra si las ocupaciones ",
            "más expuestas a la IA se encuentran ",
            "predominantemente en el sector formal o informal. ",
            "Esta relación es clave para anticipar el alcance ",
            "de las políticas de protección social ante la ",
            "transformación tecnológica."
          )
        )
      )
    )
  ),

  # Fila 3: Escolaridad (ancho completo)
  fluidRow(
    column(
      12,
      div(
        class = "chart-header",
        p(class = "chart-title",
          "Escolaridad promedio ponderada por gradiente"),
        p(class = "chart-subtitle",
          paste0("Personal ocupado, por sexo | ENOE ", periodo_enoe)),
        div(
          class = "leyenda-sexo",
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#00b783;"),
            span("Hombres")),
          div(class = "leyenda-item",
            div(class = "leyenda-color",
              style = "background-color:#6950d8;"),
            span("Mujeres"))
        )
      ),
      plotlyOutput("g5_escolaridad", height = "380px")
    )
  ),
  fluidRow(
    column(
      12,
      div(
        style = paste0(
          "padding: 10px 25px 30px 25px; ",
          "max-width: 960px; margin: 0 auto;"
        ),
        p(
          style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
          HTML(paste0(
            "La escolaridad promedio ponderada por gradiente ",
            "permite observar si la exposición a la IA está ",
            "asociada con niveles educativos más altos. ",
            "Un patrón donde ",
            "<span class='highlight'>mayor exposición coincide ",
            "con mayor escolaridad</span> sugiere que la IA ",
            "impacta principalmente a ocupaciones que requieren ",
            "formación especializada."
          ))
        )
      )
    )
  ),

  # --- Subsección: Cuidados ---
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    banda_ilustrada(
      "cuidados.jpg",
      "Los cuidados son el trabajo que la IA no va a hacer, y sigue recayendo sobre las mujeres."
    ),
    h3(
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Cuidados</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Si bien los cuidados son un tema que merece ",
        "tratarse en su propia dimensión, es importante ",
        "tomar en cuenta este contexto. Como se observa ",
        "en el treemap, ",
        "<span class='highlight'>las ocupaciones de cuidados ",
        "presentan niveles bajos de exposición a la IA</span>, ",
        "lo que sugiere que estas labores —predominantemente ",
        "realizadas por mujeres— no serán fácilmente ",
        "automatizadas. Sin embargo, ",
        "<span class='highlight'>la distribución desigual ",
        "de los cuidados sigue siendo una de las principales ",
        "causas del trabajo precarizado de las mujeres</span>, ",
        "concentrándolas en empleos de menor ingreso y ",
        "limitando su acceso a ocupaciones de mayor ",
        "calificación donde la IA podría ser una herramienta ",
        "de productividad."
      ))
    ),
    # Título del treemap de cuidados (card blanca)
    div(
      class = "chart-header",
      p(
        class = "chart-title",
        style = "font-size: 20px;",
        "Ocupaciones de cuidados y su exposición a la IA"
      ),
      p(
        class = "chart-subtitle",
        style = "font-size: 13px;",
        paste0("Mujeres | ENOE ", periodo_enoe,
               " | Clasificación SINCO 4 dígitos")
      )
    ),
    plotlyOutput("treemap_cuidados", height = "500px")
  ),

  # ==========================================================
  # SECCIÓN 2: Brecha tecnológica
  # ==========================================================
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    banda_ilustrada(
      "brecha.jpg",
      "Sin conectividad ni formación, la misma exposición se vive desde puntos de partida distintos."
    ),
    h3(
      id = "sec-brecha",
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Brecha tecnológica</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "<span class='highlight'>No todas las trabajadoras ",
        "enfrentan la exposición a la IA desde el mismo ",
        "punto de partida</span>. Aunque dos grupos tengan ",
        "niveles similares de exposición ocupacional, ",
        "factores como la conectividad, el acceso a ",
        "herramientas digitales, la formación y el tiempo ",
        "disponible pueden hacer que sea mucho más difícil ",
        "adaptarse."
      ))
    ),
    # --- Gráficas: Acceso a internet y celular por sexo ---
    fluidRow(
      column(
        6,
        div(
          class = "chart-header",
          p(class = "chart-title", "Usuarios de internet"),
          p(
            class = "chart-subtitle",
            "Porcentaje por sexo | ENDUTIH 2024"
          ),
          div(
            class = "leyenda-sexo",
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#00b783;"
              ),
              span("Hombres")
            ),
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#6950d8;"
              ),
              span("Mujeres")
            )
          )
        ),
        plotlyOutput("g_internet", height = "300px"),
        div(
          style = paste0(
            "background-color: #ff6260; color: white; ",
            "border-radius: 6px; padding: 12px 16px; ",
            "margin: 20px 15px 0 15px; ",
            "font-family: 'Ubuntu'; text-align: center;"
          ),
          p(
            style = "margin: 0; font-size: 14px; font-weight: 500;",
            HTML(paste0(
              "Brecha 2024: ",
              format(abs(brecha_internet), nsmall = 1),
              " pp (Hombres > Mujeres)"
            ))
          )
        )
      ),
      column(
        6,
        div(
          class = "chart-header",
          p(
            class = "chart-title",
            "Usuarios de teléfono celular"
          ),
          p(
            class = "chart-subtitle",
            "Porcentaje por sexo | ENDUTIH 2024"
          ),
          div(
            class = "leyenda-sexo",
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#00b783;"
              ),
              span("Hombres")
            ),
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#6950d8;"
              ),
              span("Mujeres")
            )
          )
        ),
        plotlyOutput("g_celular", height = "300px"),
        div(
          style = paste0(
            "background-color: #ff6260; color: white; ",
            "border-radius: 6px; padding: 12px 16px; ",
            "margin: 20px 15px 0 15px; ",
            "font-family: 'Ubuntu'; text-align: center;"
          ),
          p(
            style = "margin: 0; font-size: 14px; font-weight: 500;",
            HTML(paste0(
              "Brecha 2024: ",
              format(abs(brecha_celular), nsmall = 1),
              " pp (Hombres > Mujeres)"
            ))
          )
        )
      )
    ),
    br(), br(), 
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Otro punto a tener en cuenta es que, de acuerdo ",
        "con distintos estudios, ",
        "<span class='highlight'>las mujeres usan la ",
        "tecnología para cumplir necesidades prácticas de ",
        "género</span>: ayudar en las tareas, buscar ",
        "recetas, mientras que los hombres dedican más de ",
        "su uso al ámbito laboral."
      ))
    ),
    # --- Gráfica: Uso de apps en celular por sexo ---
    div(
      style = "margin: 20px 0;",
      div(
        class = "chart-header",
        p(
          class = "chart-title",
          paste0(
            "Porcentaje del tipo de aplicación utilizada ",
            "por las personas usuarias de celular ",
            "inteligente según sexo"
          )
        ),
        p(
          class = "chart-subtitle",
          "ENDUTIH 2024 | INEGI"
        ),
        div(
          class = "leyenda-sexo",
          div(
            class = "leyenda-item",
            div(
              class = "leyenda-color",
              style = "background-color:#00b783;"
            ),
            span("Hombres")
          ),
          div(
            class = "leyenda-item",
            div(
              class = "leyenda-color",
              style = "background-color:#6950d8;"
            ),
            span("Mujeres")
          )
        )
      ),
      plotlyOutput("g_apps_usos", height = "420px")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Hablar de mujeres en STEM, en este contexto, ",
        "<span class='highlight'>no es un tema aparte: es ",
        "parte del mismo problema</span>. Si las tecnologías ",
        "que transforman el trabajo se diseñan y despliegan ",
        "desde espacios donde las mujeres siguen ",
        "subrepresentadas, la transición difícilmente será ",
        "justa. No se trata solo de que más mujeres entren ",
        "a estos campos, sino de que también puedan ",
        "<span class='highlight'>incidir en las decisiones ",
        "que están moldeando el futuro del trabajo</span>."
      ))
    ),
    # --- Gráficas: formación STEM por sexo (ENOE) ---
    fluidRow(
      column(
        6,
        div(
          class = "chart-header",
          p(
            class = "chart-title",
            "Personas ocupadas con formación STEM"
          ),
          p(
            class = "chart-subtitle",
            paste0(
              "Por campo de formación y sexo | ENOE ", periodo_enoe
            )
          ),
          div(
            class = "leyenda-sexo",
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#00b783;"
              ),
              span("Hombres")
            ),
            div(
              class = "leyenda-item",
              div(
                class = "leyenda-color",
                style = "background-color:#6950d8;"
              ),
              span("Mujeres")
            )
          )
        ),
        plotlyOutput("g_stem_campos", height = "360px")
      ),
      column(
        6,
        div(
          class = "chart-header",
          p(
            class = "chart-title",
            "Exposición a la IA de quienes tienen formación STEM"
          ),
          p(
            class = "chart-subtitle",
            paste0(
              "Distribución porcentual por gradiente y sexo | ENOE ",
              periodo_enoe
            )
          ),
          div(
            class = "leyenda-container",
            lapply(seq_along(colores_exposicion), function(i) {
              div(class = "leyenda-item",
                div(class = "leyenda-color",
                  style = paste0(
                    "background-color:",
                    colores_exposicion[i], ";")),
                span(names(colores_exposicion)[i]))
            })
          )
        ),
        plotlyOutput("g_stem_exposicion", height = "360px")
      )
    ),
    br(),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "La ENOE permite identificar a las personas ocupadas que ",
        "estudiaron una carrera en ciencias, tecnología, ingeniería ",
        "o matemáticas. En el trimestre ", periodo_enoe, " son ",
        personas_stem_total, " personas, y ",
        "<span class='highlight'>las mujeres son apenas el ",
        pct_stem_mujeres, " de ellas</span> (", personas_stem_m,
        "). La brecha es más amplia en ingeniería, donde las ",
        "mujeres representan el ", pct_mujeres_ingenieria,
        ", y más estrecha en ciencias (", pct_mujeres_ciencias,
        "). Visto desde cada sexo, el ", pct_ocupados_stem_m,
        " de las mujeres ocupadas tiene formación STEM, frente al ",
        pct_ocupados_stem_h, " de los hombres. Además, ",
        "<span class='highlight'>las mujeres con formación STEM ",
        "trabajan con más frecuencia en ocupaciones de exposición ",
        "significativa o máxima a la IA</span> (", pct_stem_alta_m,
        " contra ", pct_stem_alta_h, " de los hombres), lo que ",
        "sugiere que su formación técnica se canaliza hacia puestos ",
        "administrativos y de oficina más que hacia los puestos que ",
        "diseñan la tecnología."
      ))
    )
  ),

  # ==========================================================
  # SECCIÓN 3: Normativa
  # ==========================================================
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    banda_ilustrada(
      "normativa.jpg",
      "Las normas que ya existen marcan el terreno para que la transición no amplíe las brechas."
    ),
    h3(
      id = "sec-normativa",
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Normativa</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Tener esta información a la mano importa porque ",
        "muestra que la exposición del trabajo de las ",
        "mujeres a la IA ",
        "<span class='highlight'>no ocurre en el vacío, ",
        "sino dentro de un marco de normas, compromisos y ",
        "vacíos institucionales</span> que ya moldean esta ",
        "transición. Esta tabla ayuda a interpretar mejor ",
        "los datos del dashboard y también ofrece pistas ",
        "sobre dónde habría que ",
        "<span class='highlight'>fortalecer las leyes y ",
        "políticas</span> para que el cambio tecnológico no ",
        "amplíe las desigualdades, sino que contribuya a ",
        "mejorar las condiciones laborales de las mujeres."
      ))
    ),
    # --- Tabla 1: Marco jurídico de protección internacional ---
    h4(
      style = paste0(
        "font-family: 'Ubuntu'; ",
        "margin: 25px 0 10px 0;"
      ),
      HTML(paste0(
        "<span class='title-highlight'>Marco jurídico de ",
        "protección internacional</span>"
      ))
    ),
    HTML("
    <table style='width:100%; border-collapse:collapse;
      font-family:Ubuntu; font-size:14px; margin-bottom:10px;'>
      <thead>
        <tr style='background-color:#6950d8; color:white;'>
          <th style='padding:10px 12px; text-align:left;'>País</th>
          <th style='padding:10px 12px; text-align:left;'>Subregión</th>
          <th colspan='3' style='padding:10px 12px;
            text-align:center; border-left:2px solid #fff;'>
            Laboral</th>
          <th colspan='4' style='padding:10px 12px;
            text-align:center; border-left:2px solid #fff;'>
            Igualdad</th>
          <th colspan='2' style='padding:10px 12px;
            text-align:center; border-left:2px solid #fff;'>
            IA</th>
        </tr>
        <tr style='background-color:#8c7ae6; color:white;
          font-size:12px;'>
          <th style='padding:8px 12px;'></th>
          <th style='padding:8px 12px;'></th>
          <th style='padding:8px 12px; text-align:center;
            border-left:2px solid rgba(255,255,255,0.3);'>
            Convenio 190</th>
          <th style='padding:8px 12px; text-align:center;'>
            Convenio 156</th>
          <th style='padding:8px 12px; text-align:center;'>
            Convenio 142</th>
          <th style='padding:8px 12px; text-align:center;
            border-left:2px solid rgba(255,255,255,0.3);'>
            CEDAW</th>
          <th style='padding:8px 12px; text-align:center;'>
            Belém do Pará</th>
          <th style='padding:8px 12px; text-align:center;'>
            Beijing</th>
          <th style='padding:8px 12px; text-align:center;'>
            Tlatelolco</th>
          <th style='padding:8px 12px; text-align:center;
            border-left:2px solid rgba(255,255,255,0.3);'>
            OECD AI Principles</th>
          <th style='padding:8px 12px; text-align:center;'>
            UNESCO</th>
        </tr>
      </thead>
      <tbody>
        <tr style='background-color:#f8f9fa;'>
          <td style='padding:10px 12px; font-weight:500;'>
            México</td>
          <td style='padding:10px 12px;'>América del Norte</td>
          <td style='padding:10px 12px; text-align:center;
            border-left:2px solid #e9ecef;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            No</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;
            border-left:2px solid #e9ecef;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;
            border-left:2px solid #e9ecef;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
        </tr>
      </tbody>
    </table>
    "),
    p(
      style = paste0(
        "font-family: 'Ubuntu'; font-size: 11px; ",
        "color: #888; margin-top: 2px;"
      ),
      paste0(
        "Fuente: Elaboración propia con información de ",
        "Normlex de la OIT, ONUDH, OAS, CEPAL y OCDE."
      )
    ),

    # --- Tabla 2: Marco de protección nacional ---
    h4(
      style = paste0(
        "font-family: 'Ubuntu'; ",
        "margin: 30px 0 10px 0;"
      ),
      HTML(paste0(
        "<span class='title-highlight'>Marco de ",
        "protección nacional</span>"
      ))
    ),
    HTML("
    <table style='width:100%; border-collapse:collapse;
      font-family:Ubuntu; font-size:14px; margin-bottom:10px;'>
      <thead>
        <tr style='background-color:#6950d8; color:white;'>
          <th style='padding:10px 12px; text-align:left;'>País</th>
          <th style='padding:10px 12px; text-align:left;'>
            Subregión</th>
          <th style='padding:10px 12px; text-align:center;'>
            La ley laboral contempla medidas para
            evitar discriminación</th>
          <th style='padding:10px 12px; text-align:center;'>
            La capacitación está contemplada
            en la ley laboral</th>
          <th style='padding:10px 12px; text-align:center;'>
            Existe ley de igualdad</th>
          <th style='padding:10px 12px; text-align:center;'>
            Existe ley de IA</th>
        </tr>
      </thead>
      <tbody>
        <tr style='background-color:#f8f9fa;'>
          <td style='padding:10px 12px; font-weight:500;'>
            México</td>
          <td style='padding:10px 12px;'>América del Norte</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            Sí</td>
          <td style='padding:10px 12px; text-align:center;'>
            No</td>
        </tr>
      </tbody>
    </table>
    "),
    p(
      style = paste0(
        "font-family: 'Ubuntu'; font-size: 11px; ",
        "color: #888; margin-top: 2px;"
      ),
      paste0(
        "Fuente: elaboración propia a partir de la revisión ",
        "de la legislación vigente, consultada en el sitio ",
        "de la Cámara de Diputados."
      )
    )
  ),

  # ==========================================================
  # SECCIÓN 4: Conclusión
  # ==========================================================
  div(
    style = paste0(
      "padding: 20px 25px; max-width: 960px; ",
      "margin: 20px auto;"
    ),
    h3(
      id = "sec-conclusion",
      style = "font-family: 'Ubuntu';",
      HTML("<span class='title-highlight'>Conclusión</span>")
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Es indudable que la inteligencia artificial va a ",
        "transformar el mundo del trabajo, y ",
        "<span class='highlight'>si no intervenimos ahora, ",
        "esa transformación va a ampliar las brechas</span> ",
        "que llevamos décadas intentando cerrar."
      ))
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "De la misma manera, estamos convencidas de que ",
        "el camino puede ser otro: uno en el que ",
        "<span class='highlight'>la tecnología sea la ",
        "herramienta para avanzar hacia la igualdad de ",
        "género</span> en el mundo del trabajo, siempre y ",
        "cuando aprovechemos esta ventana de oportunidad."
      ))
    ),
    p(
      style = "font-family: 'Ubuntu'; color: #333; line-height: 1.6;",
      HTML(paste0(
        "Al crear esta herramienta, quisimos pensar la ",
        "conversación en ",
        "<span class='highlight'>clave de oportunidad para ",
        "las mujeres</span>. La imaginamos como un insumo ",
        "útil para personas que toman decisiones en empleo ",
        "y educación, y también para el sector privado, de ",
        "cara a diseñar estrategias que no solo reaccionen ",
        "al cambio tecnológico, sino que también ayuden a ",
        "cerrar brechas y abrir mejores posibilidades. A ",
        "la vez, creemos que puede servir a otros públicos ",
        "como la sociedad civil, academia, sindicatos, ",
        "medios de comunicación que necesitan evidencia ",
        "para entender lo que está en juego y empujar ",
        "<span class='highlight'>una transición más ",
        "justa</span>."
      ))
    )
  ),

  # ==========================================================
  # Footer
  # ==========================================================
  div(
    style = paste0(
      "width: 100vw; margin-left: calc(-50vw + 50%); ",
      "margin-top: 40px; padding: 30px 0; ",
      "background-color: #6950d8; color: white; ",
      "font-family: 'Ubuntu';"
    ),
    div(
      style = paste0(
        "max-width: 960px; margin: 0 auto; ",
        "display: flex; align-items: center; ",
        "gap: 25px; padding: 0 25px;"
      ),
      # Logo Clave Igualdad (20% izquierdo)
      div(
        style = paste0(
          "flex: 0 0 20%; text-align: center; ",
          "display: flex; align-items: center; ",
          "justify-content: center;"
        ),
        div(
          style = paste0(
            "background-color: white; ",
            "border-radius: 8px; padding: 10px 14px; ",
            "display: inline-block;"
          ),
          tags$img(
            src = "clave_logo.png",
            style = "max-width: 100%; height: auto;"
          )
        )
      ),
      # Texto (centro)
      div(
        style = "flex: 1 1 60%;",
        p(
          style = paste0(
            "color: white; line-height: 1.6; ",
            "font-size: 14px; margin: 0 0 10px 0;"
          ),
          paste0(
            "Dashboard realizado por James Alexis Rodas ",
            "Milian, Jorge Juvenal Campos Ferreira, ",
            "Natalia Trujillo Espinosa y Sandra Patricia ",
            "Carmona Hernández en el marco de ",
            "DataAcción: Datatón regional para la ",
            "igualdad."
          )
        ),
        p(
          style = paste0(
            "color: rgba(255,255,255,0.8); ",
            "font-size: 13px; margin: 0;"
          ),
          HTML(paste0(
            "Puedes descargar la nota metodológica en ",
            "<a href='https://github.com/JuveCampos/",
            "Monitor-de-exposicion-del-trabajo-de-las-mujeres",
            "-a-la-IA-2026/blob/main/notametodologica.pdf' ",
            "target='_blank' style='color: #ffbd41;'>",
            "esta liga</a>. Para mayor información, ",
            "escribe a ",
            "<a href='mailto:patricia@claveigualdad.org' ",
            "style='color: #ffbd41;'>",
            "patricia@claveigualdad.org</a>"
          ))
        )
      ),
      # Logo DataAcción (20% derecho)
      div(
        style = paste0(
          "flex: 0 0 20%; text-align: center; ",
          "display: flex; align-items: center; ",
          "justify-content: center;"
        ),
        tags$img(
          src = "artboard_1.png.webp",
          style = "max-width: 100%; height: auto;"
        )
      )
    )
    ,
    # --- Franja de adscripción a México, ¿Cómo vamos? ---
    div(
      style = paste0(
        "max-width: 960px; margin: 25px auto 0 auto; ",
        "padding: 20px 25px 0 25px; ",
        "border-top: 1px solid rgba(255,255,255,0.3); ",
        "display: flex; align-items: center; ",
        "justify-content: center; gap: 18px; ",
        "flex-wrap: wrap;"
      ),
      p(
        style = paste0(
          "color: rgba(255,255,255,0.9); font-size: 13px; ",
          "margin: 0; text-align: right;"
        ),
        "Este monitor forma parte de la cartera de proyectos de"
      ),
      tags$a(
        href = "https://mexicocomovamos.mx/",
        target = "_blank",
        tags$img(
          src = "logo_mcv_blanco.svg",
          style = "width: 150px; height: auto; display: block;"
        )
      )
    )
  )
)

# --- Server ---
server <- function(input, output, session) {

  output$treemap_titulo <- renderUI({
    sexo_val <- as.numeric(input$sexo)
    titulo_sexo <- names(opciones_sexo)[opciones_sexo == sexo_val]
    sector_val <- input$sector

    subtitulo_sector <- if (sector_val == "all") {
      ""
    } else {
      nombre_sector <- names(opciones_sector)[
        opciones_sector == sector_val
      ]
      paste0(" | ", nombre_sector)
    }

    tagList(
      p(
        class = "chart-title",
        style = "font-size: 20px;",
        "Exposición a la IA en el mercado laboral mexicano"
      ),
      p(
        class = "chart-subtitle",
        style = "font-size: 13px;",
        paste0(
          titulo_sexo,
          " | ENOE ", periodo_enoe, " | Clasificación SINCO 4 dígitos",
          subtitulo_sector
        )
      )
    )
  })

  output$treemap <- renderPlotly({
    sexo_val <- as.numeric(input$sexo)
    titulo <- names(opciones_sexo)[opciones_sexo == sexo_val]
    generar_treemap(bd, sexo_val, titulo, input$sector)
  })

  # --- Panel de descripción al hacer click en treemap ---
  sinco_seleccionado <- reactiveVal(NULL)

  observeEvent(
    event_data("plotly_click", source = "treemap_src"),
    {
      ev <- event_data("plotly_click", source = "treemap_src")
      if (!is.null(ev) && !is.null(ev$customdata)) {
        codigo <- as.character(ev$customdata)
        if (codigo != "") {
          sinco_seleccionado(codigo)
        }
      }
    }
  )

  # Limpiar al cambiar sexo o sector
  observeEvent(input$sexo, { sinco_seleccionado(NULL) })
  observeEvent(input$sector, { sinco_seleccionado(NULL) })

  output$panel_descripcion_ia <- renderUI({
    codigo <- sinco_seleccionado()
    if (is.null(codigo)) return(NULL)

    sexo_val <- as.numeric(input$sexo)
    fila <- bd %>%
      filter(sex == sexo_val, sinco4d == codigo) %>%
      slice(1)

    if (nrow(fila) == 0) return(NULL)

    desc <- fila$descripcion_ia_es[1]
    nombre <- fila$unitario_titulo[1]
    exposicion <- fila$exposicion_ia_es[1]
    if (is.na(exposicion)) exposicion <- "Sin información"
    if (isTRUE(fila$clasificacion_provisional[1]) &&
        exposicion != "Sin información") {
      exposicion <- paste0(exposicion, " (clasificación provisional)")
    }

    if (is.na(desc) || desc == "") {
      return(
        div(
          style = paste0(
            "max-width: 960px; margin: 15px auto; ",
            "padding: 15px 20px; ",
            "background-color: #f8f9fa; ",
            "border-left: 4px solid #ccc; ",
            "border-radius: 4px; ",
            "font-family: 'Ubuntu';"
          ),
          p(
            style = paste0(
              "color: #666; font-size: 12px; ",
              "font-style: italic; margin: 0 0 10px 0;"
            ),
            paste0(
              "Seleccione otra ocupación del treemap para ver ",
              "el desglose de sus actividades."
            )
          ),
          p(
            style = paste0(
              "color: #888; font-style: italic; ",
              "margin: 0;"
            ),
            paste0(
              "No hay descripción de exposición ",
              "disponible para \"", nombre, "\"."
            )
          )
        )
      )
    }

    div(
      style = paste0(
        "max-width: 960px; margin: 15px auto; ",
        "padding: 15px 20px; ",
        "background-color: #f8f9fa; ",
        "border-left: 4px solid #6950d8; ",
        "border-radius: 4px; ",
        "font-family: 'Ubuntu';"
      ),
      p(
        style = paste0(
          "color: #666; font-size: 12px; font-style: italic; ",
          "margin: 0 0 10px 0;"
        ),
        paste0(
          "Seleccione otra ocupación del treemap para ver ",
          "el desglose de sus actividades."
        )
      ),
      div(
        style = paste0(
          "display: flex; ",
          "justify-content: space-between; ",
          "align-items: center;"
        ),
        h4(
          nombre,
          style = paste0(
            "color: #231f20; margin: 0 0 3px 0; ",
            "font-size: 15px;"
          )
        ),
        tags$span(
          exposicion,
          style = paste0(
            "font-size: 12px; color: #666; ",
            "font-weight: 500;"
          )
        )
      ),
      p(
        style = paste0(
          "color: #444; font-size: 13px; ",
          "line-height: 1.5; margin: 8px 0 0 0;"
        ),
        desc
      )
    )
  })

  # --- Treemap: Ocupaciones de cuidados (solo mujeres) ---
  sinco_cuidados <- c(
    "2335", "2436", "2811", "2821",
    "5201", "5221", "5222", "9611"
  )

  output$treemap_cuidados <- renderPlotly({
    bd_cuid <- bd %>%
      filter(sex == 2, ocup > 0, sinco4d %in% sinco_cuidados) %>%
      mutate(
        exposicion_ia_es = ifelse(
          is.na(exposicion_ia_es),
          "Sin información",
          exposicion_ia_es
        ),
        color_asignado = case_when(
          exposicion_ia_es == "Sin información" ~ color_na,
          TRUE ~ colores_exposicion[exposicion_ia_es]
        ),
        nivel_escolaridad = clasificar_escolaridad(escol2d),
        titulo_display = flexionar_titulos(
          unitario_titulo, "fem"
        )
      ) %>%
      mutate(texto_hover = construir_hover(.))

    df_tree <- bd_cuid %>%
      transmute(
        ids = paste0("ocu_", sinco4d),
        labels = titulo_display,
        parents = "",
        values = ocup,
        color = color_asignado,
        texto = texto_hover,
        customdata = sinco4d
      )

    plot_ly(
      type = "treemap",
      ids = df_tree$ids,
      labels = df_tree$labels,
      parents = df_tree$parents,
      values = df_tree$values,
      text = df_tree$texto,
      customdata = df_tree$customdata,
      hoverinfo = "text",
      textinfo = "label",
      marker = list(
        colors = df_tree$color,
        line = list(width = 0.5, color = "#ffffff")
      ),
      textfont = list(family = "Ubuntu"),
      pathbar = list(textfont = list(family = "Ubuntu")),
      hoverlabel = list(
        font = list(family = "Ubuntu", size = 13)
      ),
      source = "treemap_cuidados_src"
    ) %>%
      layout(
        font = list(family = "Ubuntu"),
        hoverlabel = list(font = list(family = "Ubuntu")),
        margin = list(t = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- Gráficas: Series de tiempo acceso (ENDUTIH) ---
  output$g_internet <- renderPlotly({
    df <- datos_endutih %>%
      filter(indicador == "Usuarios de internet")
    df_h <- df %>% filter(sexo == "Hombres")
    df_m <- df %>% filter(sexo == "Mujeres")

    plot_ly() %>%
      add_trace(
        data = df_h,
        x = ~anio, y = ~valor,
        name = "Hombres",
        type = "scatter", mode = "lines+markers+text",
        line = list(
          color = colores_sexo["Hombres"], width = 2.5
        ),
        marker = list(
          color = colores_sexo["Hombres"],
          size = 8, opacity = 0.5
        ),
        opacity = 0.5,
        text = ~paste0(format(valor, nsmall = 1), "%"),
        textposition = "top center",
        textfont = list(
          family = "Ubuntu", size = 11,
          color = colores_sexo["Hombres"]
        ),
        hovertext = ~paste0(
          "Hombres ", anio, ": ",
          format(valor, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      add_trace(
        data = df_m,
        x = ~anio, y = ~valor,
        name = "Mujeres",
        type = "scatter", mode = "lines+markers+text",
        line = list(
          color = colores_sexo["Mujeres"], width = 2.5
        ),
        marker = list(
          color = colores_sexo["Mujeres"], size = 8
        ),
        text = ~paste0(format(valor, nsmall = 1), "%"),
        textposition = "bottom center",
        textfont = list(
          family = "Ubuntu", size = 11,
          color = colores_sexo["Mujeres"]
        ),
        hovertext = ~paste0(
          "Mujeres ", anio, ": ",
          format(valor, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 11),
          tickvals = c(2021, 2022, 2023, 2024),
          showgrid = FALSE,
          fixedrange = TRUE
        ),
        yaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 11),
          ticksuffix = "%",
          range = c(70, 90),
          showgrid = TRUE,
          gridcolor = "#f0f0f0",
          fixedrange = TRUE
        ),
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(l = 50, r = 10, t = 10, b = 30),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$g_celular <- renderPlotly({
    df <- datos_endutih %>%
      filter(indicador == "Usuarios de teléfono celular")
    df_h <- df %>% filter(sexo == "Hombres")
    df_m <- df %>% filter(sexo == "Mujeres")

    plot_ly() %>%
      add_trace(
        data = df_h,
        x = ~anio, y = ~valor,
        name = "Hombres",
        type = "scatter", mode = "lines+markers+text",
        line = list(
          color = colores_sexo["Hombres"], width = 2.5
        ),
        marker = list(
          color = colores_sexo["Hombres"],
          size = 8, opacity = 0.5
        ),
        opacity = 0.5,
        text = ~paste0(format(valor, nsmall = 1), "%"),
        textposition = "top center",
        textfont = list(
          family = "Ubuntu", size = 11,
          color = colores_sexo["Hombres"]
        ),
        hovertext = ~paste0(
          "Hombres ", anio, ": ",
          format(valor, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      add_trace(
        data = df_m,
        x = ~anio, y = ~valor,
        name = "Mujeres",
        type = "scatter", mode = "lines+markers+text",
        line = list(
          color = colores_sexo["Mujeres"], width = 2.5
        ),
        marker = list(
          color = colores_sexo["Mujeres"], size = 8
        ),
        text = ~paste0(format(valor, nsmall = 1), "%"),
        textposition = "bottom center",
        textfont = list(
          family = "Ubuntu", size = 11,
          color = colores_sexo["Mujeres"]
        ),
        hovertext = ~paste0(
          "Mujeres ", anio, ": ",
          format(valor, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 11),
          tickvals = c(2021, 2022, 2023, 2024),
          showgrid = FALSE,
          fixedrange = TRUE
        ),
        yaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 11),
          ticksuffix = "%",
          range = c(73, 88),
          showgrid = TRUE,
          gridcolor = "#f0f0f0",
          fixedrange = TRUE
        ),
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(l = 50, r = 10, t = 10, b = 30),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- Gráfica: Uso de apps en celular por sexo (ENDUTIH) ---
  output$g_apps_usos <- renderPlotly({
    # Annotations para columna "Total" a la derecha
    total_annotations <- lapply(seq_len(nrow(datos_apps)), function(i) {
      list(
        x = max(datos_apps$hombres, datos_apps$mujeres) + 18,
        y = i - 1,
        text = paste0(
          "<b>", format(datos_apps$total[i], nsmall = 1), "</b>"
        ),
        showarrow = FALSE,
        font = list(
          family = "Ubuntu", size = 12, color = "#231f20"
        ),
        xanchor = "center",
        xref = "x",
        yref = "y"
      )
    })

    # Annotation del encabezado "Total"
    total_annotations <- c(
      total_annotations,
      list(list(
        x = max(datos_apps$hombres, datos_apps$mujeres) + 18,
        y = nrow(datos_apps),
        text = "<b>Total</b>",
        showarrow = FALSE,
        font = list(
          family = "Ubuntu", size = 12, color = "#888"
        ),
        xanchor = "center",
        xref = "x",
        yref = "y"
      ))
    )

    plot_ly() %>%
      add_bars(
        data = datos_apps,
        y = ~uso,
        x = ~hombres,
        name = "Hombres",
        orientation = "h",
        marker = list(
          color = colores_sexo["Hombres"],
          opacity = 0.5
        ),
        text = ~paste0(format(hombres, nsmall = 1), "%"),
        textposition = "outside",
        textfont = list(size = 11, family = "Ubuntu"),
        hovertext = ~paste0(
          uso, "<br>Hombres: ",
          format(hombres, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = datos_apps,
        y = ~uso,
        x = ~mujeres,
        name = "Mujeres",
        orientation = "h",
        marker = list(
          color = colores_sexo["Mujeres"],
          opacity = 1
        ),
        text = ~paste0(format(mujeres, nsmall = 1), "%"),
        textposition = "outside",
        textfont = list(size = 11, family = "Ubuntu"),
        hovertext = ~paste0(
          uso, "<br>Mujeres: ",
          format(mujeres, nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          showgrid = FALSE,
          showticklabels = FALSE,
          range = c(
            0,
            max(datos_apps$hombres, datos_apps$mujeres) + 26
          ),
          fixedrange = TRUE
        ),
        yaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 12),
          automargin = TRUE,
          fixedrange = TRUE
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(l = 10, r = 50, t = 10, b = 10),
        annotations = total_annotations,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        bargap = 0.15,
        bargroupgap = 0.05
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- Gráficas STEM: campos de formación por sexo (ENOE) ---
  output$g_stem_campos <- renderPlotly({
    # La etiqueta del eje incluye la participación de las mujeres
    etiquetas_eje <- stem_pct_mujeres %>%
      mutate(
        etiqueta = paste0(
          campo_label, "<br><span style='font-size:10px;color:#6950d8'>",
          formato_pct(pct_mujeres), " mujeres</span>"
        )
      )

    df <- bd_stem_campos %>%
      left_join(etiquetas_eje %>% select(campo_label, etiqueta),
                by = "campo_label") %>%
      mutate(etiqueta = factor(etiqueta, levels = etiquetas_eje$etiqueta))

    df_h <- df %>% filter(sexo_label == "Hombres")
    df_m <- df %>% filter(sexo_label == "Mujeres")

    plot_ly() %>%
      add_bars(
        data = df_h,
        x = ~etiqueta,
        y = ~ocup,
        name = "Hombres",
        marker = list(
          color = colores_sexo["Hombres"], opacity = 0.5
        ),
        text = ~format(round(ocup), big.mark = ","),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          campo_label, "<br>Hombres: ",
          format(round(ocup), big.mark = ","), " personas"
        ),
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = df_m,
        x = ~etiqueta,
        y = ~ocup,
        name = "Mujeres",
        marker = list(
          color = colores_sexo["Mujeres"], opacity = 1
        ),
        text = ~format(round(ocup), big.mark = ","),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          campo_label, "<br>Mujeres: ",
          format(round(ocup), big.mark = ","), " personas"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 11)
        ),
        yaxis = list(
          title = "Población ocupada",
          titlefont = list(family = "Ubuntu"),
          tickformat = ",",
          range = c(0, max(df$ocup) * 1.18)
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(b = 70, t = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- Exposición a la IA de las personas con formación STEM, por sexo ---
  output$g_stem_exposicion <- renderPlotly({
    df <- bd_stem_exp %>%
      mutate(
        texto = ifelse(
          pct_ocup >= 4,
          paste0(format(round(pct_ocup, 1), nsmall = 1), "%"), ""
        )
      )

    plot_ly(
      df,
      x = ~sexo_label,
      y = ~pct_ocup,
      color = ~exposicion_ia_es,
      colors = colores_exposicion,
      type = "bar",
      text = ~texto,
      textposition = "inside",
      textfont = list(size = 10),
      hovertext = ~paste0(
        exposicion_ia_es, "<br>",
        sexo_label, "<br>",
        format(round(pct_ocup, 1), nsmall = 1), "%<br>",
        format(round(total_ocup), big.mark = ","),
        " personas"
      ),
      hoverinfo = "text"
    ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu")
        ),
        yaxis = list(
          title = "Porcentaje (%)",
          titlefont = list(family = "Ubuntu"),
          range = c(0, 105)
        ),
        barmode = "stack",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(t = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- G1: Total en exposición significativa y máxima por sexo ---
  output$g1_total_alta_exp <- renderPlotly({
    df <- bd_por_sexo_exp %>%
      filter(exposicion_ia_es %in% niveles_alta_exp)

    df_h <- df %>% filter(sexo_label == "Hombres")
    df_m <- df %>% filter(sexo_label == "Mujeres")

    plot_ly() %>%
      add_bars(
        data = df_h,
        x = ~exposicion_ia_es,
        y = ~total_ocup,
        name = "Hombres",
        marker = list(
          color = colores_sexo["Hombres"], opacity = 0.5
        ),
        text = ~paste0(
          format(round(total_ocup), big.mark = ","),
          " personas"
        ),
        textposition = "outside",
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = df_m,
        x = ~exposicion_ia_es,
        y = ~total_ocup,
        name = "Mujeres",
        marker = list(
          color = colores_sexo["Mujeres"], opacity = 1
        ),
        text = ~paste0(
          format(round(total_ocup), big.mark = ","),
          " personas"
        ),
        textposition = "outside",
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 10)
        ),
        yaxis = list(
          title = "Población ocupada",
          titlefont = list(family = "Ubuntu"),
          tickformat = ","
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(b = 80, t = 10)
      )
  })

  # --- G2: % por grado de exposición y sexo ---
  output$g2_pct_exposicion <- renderPlotly({
    df <- bd_por_sexo_exp

    plot_ly(
      df,
      x = ~sexo_label,
      y = ~pct_ocup,
      color = ~exposicion_ia_es,
      colors = colores_exposicion,
      type = "bar",
      text = ~paste0(
        format(round(pct_ocup, 1), nsmall = 1), "%"
      ),
      textposition = "inside",
      textfont = list(size = 10),
      hovertext = ~paste0(
        exposicion_ia_es, "<br>",
        sexo_label, "<br>",
        format(round(pct_ocup, 1), nsmall = 1), "%<br>",
        format(round(total_ocup), big.mark = ","),
        " personas"
      ),
      hoverinfo = "text"
    ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu")
        ),
        yaxis = list(
          title = "Porcentaje (%)",
          titlefont = list(family = "Ubuntu"),
          range = c(0, 105)
        ),
        barmode = "stack",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(t = 10)
      )
  })

  # --- G3: Ingreso mediano por gradiente y sexo ---
  output$g3_ingreso_grad <- renderPlotly({
    df <- bd_por_sexo_exp

    df_h <- df %>% filter(sexo_label == "Hombres")
    df_m <- df %>% filter(sexo_label == "Mujeres")

    plot_ly() %>%
      add_bars(
        data = df_h,
        x = ~exposicion_ia_es,
        y = ~ingreso_ponderado,
        name = "Hombres",
        marker = list(
          color = colores_sexo["Hombres"], opacity = 0.5
        ),
        text = ~paste0(
          "$", format(round(ingreso_ponderado), big.mark = ",")
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Hombres<br>",
          "Ingreso: $",
          format(round(ingreso_ponderado), big.mark = ",")
        ),
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = df_m,
        x = ~exposicion_ia_es,
        y = ~ingreso_ponderado,
        name = "Mujeres",
        marker = list(
          color = colores_sexo["Mujeres"], opacity = 1
        ),
        text = ~paste0(
          "$", format(round(ingreso_ponderado), big.mark = ",")
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Mujeres<br>",
          "Ingreso: $",
          format(round(ingreso_ponderado), big.mark = ",")
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 9)
        ),
        yaxis = list(
          title = "Ingreso mediano ($)",
          titlefont = list(family = "Ubuntu"),
          tickformat = ","
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(b = 100, t = 10)
      )
  })

  # --- G4: Tasa de informalidad por gradiente y sexo ---
  output$g4_informalidad <- renderPlotly({
    df <- bd_por_sexo_exp

    df_h <- df %>% filter(sexo_label == "Hombres")
    df_m <- df %>% filter(sexo_label == "Mujeres")

    plot_ly() %>%
      add_bars(
        data = df_h,
        x = ~exposicion_ia_es,
        y = ~til_ponderada,
        name = "Hombres",
        marker = list(
          color = colores_sexo["Hombres"], opacity = 0.5
        ),
        text = ~paste0(
          format(round(til_ponderada, 1), nsmall = 1), "%"
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Hombres<br>",
          "Informalidad: ",
          format(round(til_ponderada, 1), nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = df_m,
        x = ~exposicion_ia_es,
        y = ~til_ponderada,
        name = "Mujeres",
        marker = list(
          color = colores_sexo["Mujeres"], opacity = 1
        ),
        text = ~paste0(
          format(round(til_ponderada, 1), nsmall = 1), "%"
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Mujeres<br>",
          "Informalidad: ",
          format(round(til_ponderada, 1), nsmall = 1), "%"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 9)
        ),
        yaxis = list(
          title = "Tasa de informalidad (%)",
          titlefont = list(family = "Ubuntu")
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(b = 100, t = 10)
      )
  })

  # --- G5: Escolaridad promedio por gradiente y sexo ---
  output$g5_escolaridad <- renderPlotly({
    df <- bd_por_sexo_exp

    df_h <- df %>% filter(sexo_label == "Hombres")
    df_m <- df %>% filter(sexo_label == "Mujeres")

    plot_ly() %>%
      add_bars(
        data = df_h,
        x = ~exposicion_ia_es,
        y = ~escol_ponderada,
        name = "Hombres",
        marker = list(
          color = colores_sexo["Hombres"], opacity = 0.5
        ),
        text = ~paste0(
          format(round(escol_ponderada, 1), nsmall = 1),
          " años"
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Hombres<br>",
          "Escolaridad: ",
          format(round(escol_ponderada, 1), nsmall = 1),
          " años (",
          clasificar_escolaridad(escol_ponderada), ")"
        ),
        hoverinfo = "text"
      ) %>%
      add_bars(
        data = df_m,
        x = ~exposicion_ia_es,
        y = ~escol_ponderada,
        name = "Mujeres",
        marker = list(
          color = colores_sexo["Mujeres"], opacity = 1
        ),
        text = ~paste0(
          format(round(escol_ponderada, 1), nsmall = 1),
          " años"
        ),
        textposition = "outside",
        textfont = list(size = 10),
        hovertext = ~paste0(
          exposicion_ia_es, "<br>",
          "Mujeres<br>",
          "Escolaridad: ",
          format(round(escol_ponderada, 1), nsmall = 1),
          " años (",
          clasificar_escolaridad(escol_ponderada), ")"
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 9)
        ),
        yaxis = list(
          title = "Años de escolaridad",
          titlefont = list(family = "Ubuntu")
        ),
        barmode = "group",
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(b = 100, t = 10)
      )
  })

  # --- G6a: Top 10 hombres en exposición alta ---
  output$g6_top10_h <- renderPlotly({
    df_h <- bd_top10 %>%
      filter(sexo_label == "Hombres") %>%
      mutate(
        titulo_display = flexionar_titulos(
          unitario_titulo, "masc"
        ),
        titulo_corto = ifelse(
          nchar(titulo_display) > 50,
          paste0(substr(titulo_display, 1, 47), "..."),
          titulo_display
        )
      ) %>%
      arrange(ocup) %>%
      mutate(
        titulo_corto = factor(titulo_corto, levels = titulo_corto)
      )

    plot_ly(
      df_h,
      y = ~titulo_corto,
      x = ~ocup,
      type = "bar",
      orientation = "h",
      marker = list(color = colores_sexo["Hombres"], opacity = 0.5),
      text = ~format(round(ocup), big.mark = ","),
      textposition = "outside",
      textfont = list(size = 10),
      hovertext = ~paste0(
        titulo_display, "<br>",
        exposicion_ia_es, "<br>",
        "Ocupados: ",
        format(round(ocup), big.mark = ",")
      ),
      hoverinfo = "text",
      cliponaxis = FALSE
    ) %>%
      layout(
        xaxis = list(
          title = "Población ocupada",
          tickformat = ",",
          titlefont = list(family = "Ubuntu", size = 11),
          # Holgura a la derecha para que la cifra de la barra más
          # larga se lea completa sin necesidad de hacer zoom
          range = c(0, max(df_h$ocup) * 1.22)
        ),
        yaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 10)
        ),
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(l = 250, r = 60, t = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- G6b: Top 10 mujeres en exposición alta ---
  output$g6_top10_m <- renderPlotly({
    df_m <- bd_top10 %>%
      filter(sexo_label == "Mujeres") %>%
      mutate(
        titulo_display = flexionar_titulos(
          unitario_titulo, "fem"
        ),
        titulo_corto = ifelse(
          nchar(titulo_display) > 50,
          paste0(substr(titulo_display, 1, 47), "..."),
          titulo_display
        )
      ) %>%
      arrange(ocup) %>%
      mutate(
        titulo_corto = factor(titulo_corto, levels = titulo_corto)
      )

    plot_ly(
      df_m,
      y = ~titulo_corto,
      x = ~ocup,
      type = "bar",
      orientation = "h",
      marker = list(color = colores_sexo["Mujeres"]),
      text = ~format(round(ocup), big.mark = ","),
      textposition = "outside",
      textfont = list(size = 10),
      hovertext = ~paste0(
        titulo_display, "<br>",
        exposicion_ia_es, "<br>",
        "Ocupadas: ",
        format(round(ocup), big.mark = ",")
      ),
      hoverinfo = "text",
      cliponaxis = FALSE
    ) %>%
      layout(
        xaxis = list(
          title = "Población ocupada",
          tickformat = ",",
          titlefont = list(family = "Ubuntu", size = 11),
          # Holgura a la derecha para que la cifra de la barra más
          # larga se lea completa sin necesidad de hacer zoom
          range = c(0, max(df_m$ocup) * 1.22)
        ),
        yaxis = list(
          title = "",
          tickfont = list(family = "Ubuntu", size = 10)
        ),
        showlegend = FALSE,
        font = list(family = "Ubuntu"),
        margin = list(l = 250, r = 60, t = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # --- G7: Composición del empleo por división SINCO ---
  # Barras apiladas al 100 % para Total, Hombres y Mujeres. Las divisiones
  # de escritorio (1 a 3) van en azul y el resto en gris; al final del
  # bloque azul se anota la participación conjunta de esas tres divisiones.
  output$g7_divisiones <- renderPlotly({
    df <- bd_divisiones %>%
      mutate(
        texto_segmento = ifelse(
          escritorio & pct_ocup >= 5, formato_pct(pct_ocup), ""
        )
      )

    anotaciones <- lapply(seq_len(nrow(pct_escritorio)), function(i) {
      list(
        x = pct_escritorio$pct[i],
        y = as.character(pct_escritorio$poblacion[i]),
        text = paste0("<b>", formato_pct(pct_escritorio$pct[i]), "</b>"),
        xanchor = "left",
        xshift = 6,
        showarrow = FALSE,
        font = list(family = "Ubuntu", size = 13, color = "#4f3bb5"),
        bgcolor = "white",
        bordercolor = "#4f3bb5",
        borderwidth = 1,
        borderpad = 3
      )
    })

    plot_ly(
      df,
      x = ~pct_ocup,
      y = ~poblacion,
      color = ~division_label,
      colors = colores_division,
      type = "bar",
      orientation = "h",
      text = ~texto_segmento,
      textposition = "inside",
      insidetextanchor = "middle",
      textfont = list(family = "Ubuntu", size = 11, color = "white"),
      hovertext = ~paste0(
        division_label, "<br>",
        poblacion, ": ", formato_pct(pct_ocup), "<br>",
        format(round(total_ocup), big.mark = ","), " personas"
      ),
      hoverinfo = "text"
    ) %>%
      layout(
        xaxis = list(
          title = "Porcentaje de la población ocupada",
          titlefont = list(family = "Ubuntu", size = 11),
          range = c(0, 100),
          ticksuffix = "%"
        ),
        yaxis = list(
          title = "",
          categoryorder = "array",
          categoryarray = c("Mujeres", "Hombres", "Total"),
          tickfont = list(family = "Ubuntu", size = 12)
        ),
        barmode = "stack",
        showlegend = FALSE,
        annotations = anotaciones,
        font = list(family = "Ubuntu"),
        margin = list(l = 70, r = 20, t = 10, b = 50)
      ) %>%
      config(displayModeBar = FALSE)
  })
}

shinyApp(ui, server)
