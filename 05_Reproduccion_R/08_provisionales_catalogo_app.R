# ------------------------------------------------------------------------------
# Paso 8:     Clasificaciones provisionales y catálogo final para la app.
#
#             Las ocupaciones que quedan sin categoría tras el paso 4 se
#             resuelven en este orden:
#             1. Fuera del índice (militares, códigos operativos de la ENOE,
#                no especificado): se quedan en gris con una explicación.
#             2. Propuesta del equipo en insumos/mapeo_manual_ciuo.csv (CIUO-08
#                análoga): categoría y puntuación de esa CIUO, marcada como
#                provisional (la columna `aprobado` del archivo registra si el
#                equipo ya la validó).
#             3. Imputación modal jerárquica: la categoría más frecuente entre
#                las ocupaciones hermanas ya clasificadas del subgrupo 3d
#                (o grupo 2d o división 1d), con al menos dos hermanas; en
#                empate se toma la de menor exposición. La puntuación es la ya
#                imputada en el paso 4 o el promedio de las hermanas.
#
#             Después se arma el catálogo que consume la aplicación, con la
#             descripción en español (paso 6) y la tabla de tareas por
#             ocupación para mostrarlas como lista o tabla.
#
# Entradas:   salidas/04_catalogo_exposicion_ia.csv
#             salidas/01_gmyrek_2025_ciuo4d.csv
#             salidas/enoe/zcalculos_Y{año}T0{trim}_4d.dta (población)
#             insumos/mapeo_manual_ciuo.csv
#             salidas/06_descripciones_es.csv y 06_tareas_por_ocupacion_es.csv
#             (si no existen, se usa el inglés del paso 5 y se avisa)
# Salidas:    salidas/08_ocupaciones_provisionales.csv (reporte revisable)
#             salidas/08_catalogo_app.csv (catálogo para la app)
#             salidas/08_tareas_app.csv (tareas por ocupación, en español)
#
# Uso:        Rscript 08_provisionales_catalogo_app.R
# ------------------------------------------------------------------------------

source(file.path(
  dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
  "00_configuracion.R"
))
library(haven)

# 1. Insumos ----------------------------------------------------------------------

catalogo <- read_csv(archivo_catalogo, col_types = cols(.default = "c")) %>%
  mutate(across(c(mean_score_ia_2025, score_minimo, score_maximo), as.numeric),
         across(c(via_equivalencia_2011, ciuo_heredado_3d, score_imputado),
                as.logical))

gmyrek <- read_csv(archivo_gmyrek_ciuo, col_types = cols(.default = "c")) %>%
  transmute(ciuo08_propuesto = ISCO_08, ciuo_titulo_gmyrek = Title,
            score_gmyrek = as.numeric(mean_score_2025), categoria_gmyrek = potential25)

mapeo <- read_csv(archivo_mapeo_manual, col_types = cols(.default = "c")) %>%
  mutate(sinco_4d = as.character(sinco_4d)) %>%
  # La puntuación y la categoría se toman siempre del catálogo de Gmyrek del
  # paso 1, no de lo que traiga el archivo
  select(-any_of(c("mean_score_2025_propuesto", "potential25_propuesto",
                   "ciuo08_titulo_propuesto"))) %>%
  left_join(gmyrek, by = "ciuo08_propuesto")

archivo_poblacion <- file.path(
  dir_enoe_salidas, paste0("zcalculos_Y", anio_enoe, "T0", trim_enoe, "_4d.dta")
)
stopifnot(file.exists(archivo_poblacion))
poblacion <- read_dta(archivo_poblacion) %>%
  mutate(unitario_4d = str_pad(as.character(sinco4d), 4, "left", "0")) %>%
  select(unitario_4d, sex, ocup) %>%
  pivot_wider(names_from = sex, values_from = ocup, names_prefix = "ocup_sex") %>%
  rename(ocup_total = ocup_sex0, ocup_hombres = ocup_sex1, ocup_mujeres = ocup_sex2)

# Códigos que la ENOE reporta y que no están en el catálogo (no debería haber:
# la estructura del paso 2 viene del documento de clasificaciones de la ENOE)
fuera <- setdiff(poblacion$unitario_4d, catalogo$unitario_4d)
print(paste0("Códigos de la ENOE fuera del catálogo: ", length(fuera), " ",
             paste(fuera, collapse = " ")))

# Descripciones: español si ya corrió el paso 6; si no, inglés del paso 5
if (file.exists(archivo_descripciones_es)) {
  descripciones_es <- read_csv(archivo_descripciones_es, col_types = cols(.default = "c"))
  descripciones <- descripciones_es %>%
    select(unitario_4d, descripcion = descripcion_es)
  tareas <- read_csv(file.path(dir_salidas, "06_tareas_por_ocupacion_es.csv"),
                     col_types = cols(.default = "c")) %>%
    transmute(unitario_4d, orden_tarea = as.integer(orden_tarea),
              ciuo_4d, ciuo_titulo = coalesce(ciuo_titulo_es, ciuo_titulo_en),
              tarea = str_remove(coalesce(tarea_es, tarea_en), "[;.]$"),
              score_tarea_2025 = as.numeric(score_tarea_2025),
              traducida = !is.na(tarea_es)) %>%
    # La justificación traducida acompaña solo a la tarea más expuesta
    left_join(descripciones_es %>% select(unitario_4d, justificacion_es = justificacion_top_es),
              by = "unitario_4d") %>%
    mutate(justificacion_es = ifelse(orden_tarea == 1, justificacion_es, NA_character_))
  idioma <- "es"
} else {
  warning("No existe la salida del paso 6; se usan las descripciones en inglés")
  descripciones <- read_csv(archivo_descripciones_en, col_types = cols(.default = "c")) %>%
    select(unitario_4d, descripcion = descripcion_en)
  tareas <- read_csv(file.path(dir_salidas, "05_tareas_por_ocupacion.csv"),
                     col_types = cols(.default = "c")) %>%
    transmute(unitario_4d, orden_tarea = as.integer(orden_tarea),
              ciuo_4d, ciuo_titulo = ciuo_titulo_en, tarea = str_remove(tarea_en, "[;.]$"),
              score_tarea_2025 = as.numeric(score_tarea_2025),
              traducida = FALSE, justificacion_es = NA_character_)
  idioma <- "en"
}

# 2. Universo de ocupaciones grises -----------------------------------------------

grises <- catalogo %>%
  filter(is.na(potencial_ia_2025))

clasificadas <- catalogo %>%
  filter(!is.na(potencial_ia_2025))

print(paste0("Ocupaciones sin categoría: ", nrow(grises)))
print(grises %>% count(estado_score))

# 3. Propuesta provisional -----------------------------------------------------------

# Categoría modal entre hermanas; en empate, la de menor exposición
categoria_modal <- function(categorias) {
  conteo <- table(categorias)
  ganadoras <- names(conteo)[conteo == max(conteo)]
  ganadoras[which.min(match(ganadoras, orden_categorias))]
}

# Hermanas clasificadas del nivel más cercano con al menos dos ocupaciones
hermanas_de <- function(codigo) {
  for (nivel in c(3, 2, 1)) {
    base <- clasificadas %>%
      filter(str_sub(unitario_4d, 1, nivel) == str_sub(codigo, 1, nivel))
    if (nrow(base) >= 2) {
      return(list(nivel = paste0("imputacion_modal_", nivel, "d"), base = base))
    }
  }
  list(nivel = NA_character_, base = clasificadas[0, ])
}

# Se recorre cada ocupación gris con lapply (cada caso devuelve una fila con
# campos heterogéneos y así el flujo queda explícito)
propuestas <- lapply(seq_len(nrow(grises)), function(i) {
  fila <- grises[i, ]
  codigo <- fila$unitario_4d

  # Caso 1: fuera del universo del índice
  if (fila$estado_score %in% c("no_aplica_militar", "no_aplica_enoe",
                               "no_aplica_no_especificado")) {
    descripcion <- switch(
      fila$estado_score,
      no_aplica_militar = paste0(
        "Esta ocupación pertenece a las fuerzas armadas. El índice de ",
        "Gmyrek et al. (2025) excluye al gran grupo 0 de la CIUO-08 ",
        "porque el corpus de tareas de la OIT no cubre las ocupaciones ",
        "militares, por lo que no es posible asignarle una puntuación ",
        "de exposición a la IA, ni siquiera de forma provisional."
      ),
      no_aplica_enoe = paste0(
        "Este código es operativo de la ENOE y no corresponde a una ",
        "ocupación de mercado con tareas evaluables, por lo que no se ",
        "le asigna puntuación de exposición a la IA."
      ),
      paste0(
        "La ENOE no especifica la ocupación de estas personas, por lo ",
        "que no es posible asignarles una puntuación de exposición a la IA."
      )
    )
    return(tibble(
      unitario_4d = codigo, score_provisional = NA_real_,
      categoria_provisional_en = NA_character_,
      metodo_provisional = "no_imputable", ciuo_propuesta = NA_character_,
      aprobado = NA_character_,
      nota = "Fuera del universo del índice de la OIT.",
      descripcion_propuesta = descripcion
    ))
  }

  # Caso 2: propuesta del equipo con CIUO evaluada por Gmyrek
  prop <- mapeo %>% filter(sinco_4d == codigo, !is.na(score_gmyrek))
  if (nrow(prop) > 0) {
    prop <- prop %>% slice(1)
    categoria_es <- traduccion_exposicion[[prop$categoria_gmyrek]]
    return(tibble(
      unitario_4d = codigo, score_provisional = prop$score_gmyrek,
      categoria_provisional_en = prop$categoria_gmyrek,
      metodo_provisional = "mapeo_manual_propuesto",
      ciuo_propuesta = prop$ciuo08_propuesto, aprobado = prop$aprobado,
      nota = paste0("CIUO-08 análoga propuesta: ", prop$ciuo08_propuesto, " (",
                    prop$ciuo_titulo_gmyrek, "). ", prop$justificacion),
      descripcion_propuesta = paste0(
        "Clasificación provisional. Esta ocupación del SINCO no tiene ",
        "una correspondencia directa en la tabla comparativa SINCO-CIUO-08 ",
        "del INEGI, por lo que el equipo le asignó como análoga la ",
        "ocupación ", prop$ciuo08_propuesto, " de la CIUO-08 (",
        prop$ciuo_titulo_gmyrek, "), evaluada por Gmyrek et al. (2025) con ",
        "una puntuación media de ", sprintf("%.2f", prop$score_gmyrek),
        " (\"", categoria_es, "\"). La puntuación proviene de las tareas de ",
        "esa ocupación análoga y no de una evaluación directa de las tareas ",
        "de esta ocupación en México, por lo que debe leerse como una ",
        "aproximación."
      )
    ))
  }

  # Caso 3: imputación modal jerárquica
  imp <- hermanas_de(codigo)
  if (is.na(imp$nivel)) {
    return(tibble(
      unitario_4d = codigo, score_provisional = NA_real_,
      categoria_provisional_en = NA_character_,
      metodo_provisional = "sin_hermanas_clasificadas",
      ciuo_propuesta = NA_character_, aprobado = NA_character_,
      nota = "No hay ocupaciones hermanas clasificadas para imputar.",
      descripcion_propuesta = NA_character_
    ))
  }
  score_prov <- ifelse(!is.na(fila$mean_score_ia_2025), fila$mean_score_ia_2025,
                       mean(imp$base$mean_score_ia_2025, na.rm = TRUE))
  nivel_txt <- switch(
    imp$nivel,
    imputacion_modal_3d = paste0("su mismo subgrupo ocupacional (SINCO ",
                                 str_sub(codigo, 1, 3), ")"),
    imputacion_modal_2d = paste0("su mismo grupo principal (SINCO ",
                                 str_sub(codigo, 1, 2), ")"),
    "su misma división ocupacional"
  )
  tibble(
    unitario_4d = codigo, score_provisional = round(score_prov, 3),
    categoria_provisional_en = categoria_modal(imp$base$potencial_ia_2025),
    metodo_provisional = imp$nivel, ciuo_propuesta = NA_character_,
    aprobado = NA_character_,
    nota = paste0("Categoría modal de ", nrow(imp$base),
                  " ocupaciones hermanas clasificadas. ",
                  ifelse(!is.na(fila$mean_score_ia_2025),
                         "Puntuación: ya imputada en el paso 4.",
                         "Puntuación: promedio de las hermanas.")),
    descripcion_propuesta = paste0(
      "Clasificación provisional. El índice de Gmyrek et al. (2025) no ",
      "evalúa de forma directa las tareas de esta ocupación, ya sea porque ",
      "no tiene correspondencia con puntuación disponible en la CIUO-08 o ",
      "porque la ocupación análoga quedó fuera del índice. Su categoría se ",
      "estimó con la más frecuente entre las ", nrow(imp$base),
      " ocupaciones ya clasificadas de ", nivel_txt, ", que comparten un ",
      "perfil de tareas similar, y la puntuación provisional (",
      sprintf("%.2f", score_prov), ") ",
      ifelse(!is.na(fila$mean_score_ia_2025),
             "proviene de la imputación jerárquica documentada en la nota metodológica. ",
             "corresponde al promedio de ese conjunto. "),
      "Debe leerse como una aproximación al perfil del grupo ocupacional, ",
      "no como una evaluación de las tareas específicas de esta ocupación."
    )
  )
}) %>%
  bind_rows()

reporte <- grises %>%
  select(unitario_4d, unitario_titulo, division_1d, division_titulo,
         estado_score, score_catalogo = mean_score_ia_2025) %>%
  left_join(propuestas, by = "unitario_4d") %>%
  left_join(poblacion, by = "unitario_4d") %>%
  mutate(
    across(c(ocup_total, ocup_hombres, ocup_mujeres), ~ replace_na(.x, 0)),
    categoria_provisional_es = ifelse(
      is.na(categoria_provisional_en), NA_character_,
      traduccion_exposicion[categoria_provisional_en]
    )
  ) %>%
  arrange(desc(ocup_total))

write_excel_csv(reporte, file.path(dir_salidas, "08_ocupaciones_provisionales.csv"),
                na = "")
print(reporte %>% count(metodo_provisional))
print(paste0("Población ocupada en gris antes de provisionales: ",
             format(sum(reporte$ocup_total), big.mark = ","), " (mujeres: ",
             format(sum(reporte$ocup_mujeres), big.mark = ","), ")"))

# Propuestas del mapeo manual que ya no hacen falta (la equivalencia 2019-2011
# les dio correspondencia oficial)
ya_resueltas <- mapeo %>%
  filter(!sinco_4d %in% grises$unitario_4d) %>%
  left_join(catalogo %>% select(unitario_4d, ciuo08_4d_correspondientes, estado_score),
            by = c("sinco_4d" = "unitario_4d"))
print("Propuestas manuales que ya se resuelven con la correspondencia oficial:")
print(ya_resueltas %>% select(sinco_4d, sinco_titulo, ciuo08_propuesto,
                              ciuo08_4d_correspondientes, estado_score) %>%
        mutate(sinco_titulo = str_sub(sinco_titulo, 1, 40)), n = 40)

# 4. Catálogo para la app ------------------------------------------------------------

imputables <- propuestas %>% filter(!is.na(categoria_provisional_en))
no_imputables <- propuestas %>% filter(metodo_provisional == "no_imputable")

catalogo_app <- catalogo %>%
  left_join(descripciones, by = "unitario_4d") %>%
  left_join(imputables %>%
              select(unitario_4d, categoria_provisional_en, score_provisional,
                     metodo_provisional, descripcion_propuesta),
            by = "unitario_4d") %>%
  mutate(
    clasificacion_provisional = !is.na(categoria_provisional_en),
    potencial_ia_2025 = coalesce(potencial_ia_2025, categoria_provisional_en),
    mean_score_ia_2025 = coalesce(mean_score_ia_2025, score_provisional),
    score_imputado = ifelse(clasificacion_provisional, TRUE, score_imputado),
    metodo_score = ifelse(clasificacion_provisional, metodo_provisional, metodo_score),
    estado_score = ifelse(clasificacion_provisional,
                          paste0("provisional_", metodo_provisional), estado_score),
    descripcion_ia_es = ifelse(clasificacion_provisional, descripcion_propuesta,
                               descripcion)
  ) %>%
  select(-categoria_provisional_en, -score_provisional, -metodo_provisional,
         -descripcion_propuesta, -descripcion) %>%
  left_join(no_imputables %>% select(unitario_4d, descripcion_propuesta),
            by = "unitario_4d") %>%
  mutate(
    descripcion_ia_es = coalesce(descripcion_ia_es, descripcion_propuesta),
    exposicion_ia_es = ifelse(is.na(potencial_ia_2025), NA_character_,
                              traduccion_exposicion[potencial_ia_2025])
  ) %>%
  select(-descripcion_propuesta) %>%
  arrange(unitario_4d)

stopifnot(nrow(catalogo_app) == nrow(catalogo),
          !any(duplicated(catalogo_app$unitario_4d)))

write_csv(catalogo_app, archivo_catalogo_app, na = "")
print(paste0("Catálogo para la app (", idioma, "): ", nrow(catalogo_app),
             " ocupaciones; sin categoría: ",
             sum(is.na(catalogo_app$potencial_ia_2025)), "; provisionales: ",
             sum(catalogo_app$clasificacion_provisional)))
print(catalogo_app %>% count(potencial_ia_2025))

# 5. Tareas por ocupación para la app ------------------------------------------------

tareas_app <- tareas %>%
  mutate(
    nivel_tarea = case_when(
      score_tarea_2025 >= 0.6 ~ "Alta",
      score_tarea_2025 >= 0.4 ~ "Media",
      TRUE ~ "Baja"
    )
  ) %>%
  arrange(unitario_4d, orden_tarea)
write_csv(tareas_app, file.path(dir_salidas, "08_tareas_app.csv"), na = "")
print(paste0("Tareas para la app: ", nrow(tareas_app), " filas, ",
             n_distinct(tareas_app$unitario_4d), " ocupaciones"))
