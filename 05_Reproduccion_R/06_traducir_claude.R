# ------------------------------------------------------------------------------
# Paso 6:     Traducción al español con Claude de los textos que ve la persona
#             usuaria: títulos de las ocupaciones CIUO-08, nombres de las
#             tareas evaluadas y justificación de la tarea más expuesta de
#             cada grupo unitario.
#
#             Se usa la interfaz de línea de comandos de Claude Code
#             (`claude -p`), en lotes, con una caché en CSV que permite
#             interrumpir y reanudar sin repetir llamadas. Cada lote se manda
#             como JSON y se exige JSON de vuelta; si la respuesta no se puede
#             leer o faltan identificadores, el lote se reintenta.
#
# Entradas:   salidas/01_gmyrek_2025_ciuo4d.csv
#             salidas/05_tareas_por_ocupacion.csv
#             salidas/05_descripciones_en.csv
# Salidas:    salidas/06_traducciones_claude_cache.csv (caché, se conserva)
#             salidas/06_tareas_por_ocupacion_es.csv
#             salidas/06_descripciones_es.csv
#
# Uso:        Rscript 06_traducir_claude.R
#             (MODELO_CLAUDE=opus Rscript 06_traducir_claude.R para otro modelo)
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(jsonlite)
library(processx)

stopifnot(nzchar(Sys.which("claude")))

# La CLI usa la sesión iniciada de Claude Code. Si el entorno de R trae una
# ANTHROPIC_API_KEY (en este equipo la hay en ~/.Renviron) la CLI la usaría
# en lugar de la sesión y, si la clave está vencida, falla; por eso se quita
# del entorno del subproceso, junto con las variables de una sesión anidada
entorno_claude <- Sys.getenv()
entorno_claude <- entorno_claude[!names(entorno_claude) %in% c(
  "ANTHROPIC_API_KEY", "CLAUDECODE", "CLAUDE_CODE_ENTRYPOINT",
  "CLAUDE_CODE_CHILD_SESSION", "CLAUDE_CODE_MESSAGING_SOCKET",
  "CLAUDE_CODE_MESSAGING_TOKEN"
)]
entorno_claude <- setNames(as.character(entorno_claude), names(entorno_claude))

# 1. Textos a traducir -------------------------------------------------------------

gmyrek <- read_csv(archivo_gmyrek_ciuo, col_types = cols(.default = "c"))
tareas <- read_csv(file.path(dir_salidas, "05_tareas_por_ocupacion.csv"),
                   col_types = cols(.default = "c"))
descripciones <- read_csv(archivo_descripciones_en, col_types = cols(.default = "c"))

pendientes_todo <- bind_rows(
  gmyrek %>% transmute(tipo = "titulo_ciuo", clave = ISCO_08, texto_en = Title),
  tareas %>% distinct(tarea_id, tarea_en) %>%
    transmute(tipo = "tarea", clave = tarea_id, texto_en = tarea_en),
  descripciones %>% filter(!is.na(justificacion_top_en), justificacion_top_en != "") %>%
    transmute(tipo = "justificacion", clave = unitario_4d,
              texto_en = justificacion_top_en)
) %>%
  distinct(tipo, clave, .keep_all = TRUE)

# 2. Caché -------------------------------------------------------------------------

if (file.exists(archivo_traducciones_cache)) {
  cache <- read_csv(archivo_traducciones_cache, col_types = cols(.default = "c"))
} else {
  cache <- tibble(tipo = character(), clave = character(), texto_en = character(),
                  texto_es = character(), modelo = character(), fecha = character())
}

pendientes <- pendientes_todo %>%
  anti_join(cache, by = c("tipo", "clave"))

print(paste0("Textos totales: ", nrow(pendientes_todo), " | ya en caché: ",
             nrow(pendientes_todo) - nrow(pendientes), " | pendientes: ",
             nrow(pendientes)))
print(pendientes %>% count(tipo))

# 3. Llamada a Claude por lotes ------------------------------------------------------

instrucciones <- paste0(
  "Eres traductor profesional de textos sobre ocupaciones y mercado laboral. ",
  "Traduce al español de México cada campo \"text\" del arreglo JSON de entrada. ",
  "Reglas: usa terminología ocupacional estándar (como la del SINCO del INEGI ",
  "y la CIUO de la OIT); los nombres de tareas se traducen como oraciones ",
  "breves con verbo, en tercera persona del plural si el original la usa o ",
  "en infinitivo si el original empieza con verbo; conserva números, ",
  "siglas y nombres propios; no agregues comentarios ni explicaciones; no ",
  "uses guiones largos. Responde ÚNICAMENTE con un arreglo JSON válido de ",
  "objetos {\"id\": ..., \"text_es\": ...}, con los mismos id de entrada y ",
  "en el mismo orden, sin bloques de código ni texto adicional."
)

traducir_lote <- function(lote, intentos = 3) {
  entrada <- toJSON(
    lote %>% transmute(id = paste(tipo, clave, sep = "|"), text = texto_en),
    auto_unbox = TRUE
  )
  archivo_entrada <- tempfile(fileext = ".json")
  writeLines(entrada, archivo_entrada, useBytes = TRUE)
  for (intento in seq_len(intentos)) {
    res <- tryCatch(
      run("claude",
          c("-p", "--model", modelo_claude, "--output-format", "text",
            instrucciones),
          stdin = archivo_entrada, timeout = 600, error_on_status = FALSE,
          env = entorno_claude),
      error = function(e) NULL
    )
    if (is.null(res) || res$status != 0) next
    texto <- str_trim(res$stdout)
    # Se tolera que el modelo envuelva la respuesta en un bloque de código
    texto <- str_remove_all(texto, "^```(json)?|```$")
    salida <- tryCatch(fromJSON(texto), error = function(e) NULL)
    if (is.null(salida) || !all(c("id", "text_es") %in% names(salida))) next
    salida <- as_tibble(salida) %>%
      mutate(id = as.character(id), text_es = str_squish(as.character(text_es)))
    ids_esperados <- paste(lote$tipo, lote$clave, sep = "|")
    if (!setequal(salida$id, ids_esperados) ||
        any(is.na(salida$text_es) | salida$text_es == "")) next
    return(salida)
  }
  NULL
}

tamanos <- c(titulo_ciuo = 40, tarea = 25, justificacion = 8)
fallidos <- 0
t0 <- Sys.time()

for (tipo_sel in names(tamanos)) {
  pend_tipo <- pendientes %>% filter(tipo == tipo_sel)
  if (nrow(pend_tipo) == 0) next
  lotes <- split(pend_tipo, ceiling(seq_len(nrow(pend_tipo)) / tamanos[[tipo_sel]]))
  for (k in seq_along(lotes)) {
    lote <- lotes[[k]]
    salida <- traducir_lote(lote)
    if (is.null(salida)) {
      fallidos <- fallidos + nrow(lote)
      print(paste0("  Lote fallido (", tipo_sel, " ", k, "/", length(lotes), ")"))
      next
    }
    nuevas <- lote %>%
      mutate(id = paste(tipo, clave, sep = "|")) %>%
      inner_join(salida, by = "id") %>%
      transmute(tipo, clave, texto_en, texto_es = text_es,
                modelo = modelo_claude,
                fecha = format(Sys.time(), "%Y-%m-%d %H:%M"))
    cache <- bind_rows(cache, nuevas)
    write_csv(cache, archivo_traducciones_cache)
    transcurrido <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
    print(paste0("  ", tipo_sel, " lote ", k, "/", length(lotes), " (",
                 nrow(cache), " en caché, ", round(transcurrido, 1), " min)"))
  }
}

print(paste0("Traducciones en caché: ", nrow(cache), " | fallidas: ", fallidos))

# 4. Armado de las salidas en español ----------------------------------------------

buscar <- function(tipo_sel) {
  cache %>% filter(tipo == tipo_sel) %>% select(clave, texto_es)
}

tareas_es <- tareas %>%
  left_join(buscar("tarea") %>% rename(tarea_id = clave, tarea_es = texto_es),
            by = "tarea_id") %>%
  left_join(buscar("titulo_ciuo") %>%
              rename(ciuo_4d = clave, ciuo_titulo_es = texto_es),
            by = "ciuo_4d") %>%
  mutate(score_tarea_2025 = as.numeric(score_tarea_2025),
         orden_tarea = as.integer(orden_tarea)) %>%
  select(unitario_4d, unitario_titulo, ciuo_4d, ciuo_titulo_en, ciuo_titulo_es,
         tarea_id, tarea_en, tarea_es, score_tarea_2025, orden_tarea,
         justificacion_en)

write_csv(tareas_es, file.path(dir_salidas, "06_tareas_por_ocupacion_es.csv"),
          na = "")

# Descripción en español por ocupación: se arma de forma determinista con las
# piezas traducidas (títulos CIUO, tarea más expuesta, justificación y lista
# de tareas), con el mismo contenido del resumen en inglés del paso 5
resumen_es <- tareas_es %>%
  arrange(unitario_4d, orden_tarea) %>%
  group_by(unitario_4d) %>%
  summarise(
    ciuo_titulos_es = paste(unique(coalesce(ciuo_titulo_es, ciuo_titulo_en)),
                            collapse = "; "),
    n_tareas = n(),
    tarea_top_es = first(coalesce(tarea_es, tarea_en)),
    score_top = first(score_tarea_2025),
    lista_tareas_es = paste0(
      str_sub(coalesce(tarea_es, tarea_en), 1, 90), " (",
      sprintf("%.2f", score_tarea_2025), ")", collapse = "; "
    ),
    sin_traducir = sum(is.na(tarea_es)),
    .groups = "drop"
  ) %>%
  left_join(buscar("justificacion") %>%
              rename(unitario_4d = clave, justificacion_top_es = texto_es),
            by = "unitario_4d")

descripciones_es <- descripciones %>%
  select(unitario_4d, unitario_titulo, justificacion_top_en) %>%
  left_join(resumen_es, by = "unitario_4d") %>%
  mutate(
    n_tareas = replace_na(n_tareas, 0L),
    descripcion_es = ifelse(
      n_tareas == 0, NA_character_,
      paste0(
        "Ocupaciones CIUO-08 correspondientes: ", ciuo_titulos_es, ". ",
        "Esta ocupación tiene ", n_tareas, " tareas evaluadas. ",
        "Tarea más expuesta: \"", tarea_top_es, "\" (puntuación ",
        sprintf("%.2f", score_top), "). ",
        coalesce(justificacion_top_es, justificacion_top_en), " ",
        "Todas las tareas con su puntuación: ", lista_tareas_es, "."
      )
    )
  ) %>%
  select(unitario_4d, unitario_titulo, ciuo_titulos_es, n_tareas, tarea_top_es,
         score_top, justificacion_top_es, descripcion_es, sin_traducir)

write_csv(descripciones_es, archivo_descripciones_es, na = "")
print(paste0("Ocupaciones con descripción en español: ",
             sum(!is.na(descripciones_es$descripcion_es)), " | tareas sin traducir: ",
             sum(descripciones_es$sin_traducir, na.rm = TRUE)))
print(paste0("Escrito: ", archivo_descripciones_es))
