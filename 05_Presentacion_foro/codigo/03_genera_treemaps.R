# ==============================================================================
# Treemaps estáticos del mercado laboral mexicano por exposición a la IA
#
# Versión en ggplot2 del treemap interactivo del Monitor, para proyectar en
# la presentación. Cada rectángulo es una ocupación SINCO a 4 dígitos y su
# tamaño es la población ocupada.
#
# Uso (desde la raíz del repositorio):
#   Rscript 05_Presentacion_foro/codigo/03_genera_treemaps.R
# ==============================================================================

library(haven)
library(tidyverse)
library(treemapify)

ruta_raiz <- normalizePath(".")
ruta_app <- file.path(ruta_raiz, "04_Aplicación")
ruta_salida <- file.path(ruta_raiz, "05_Presentacion_foro", "figuras")

periodo <- "1T2026"
tipografia <- "Helvetica Neue"

colores_gradiente <- c(
  "No expuesto"       = "#1A9641",
  "Exposición mínima" = "#7BC96A",
  "Mixto"             = "#D9D97F",
  "Gradiente 1"       = "#FEE08B",
  "Gradiente 2"       = "#FDAE61",
  "Gradiente 3"       = "#F46D43",
  "Gradiente 4"       = "#D73027",
  "Sin información"   = "#CCCCCC"
)

# Se reutiliza la flexión de género de la app para que los títulos del mapa
# femenino aparezcan en femenino, igual que en el Monitor. Se evalúa app.R
# solo hasta antes de la UI, sin arrancar el servidor de Shiny.
lineas_app <- readLines(file.path(ruta_app, "app.R"), encoding = "UTF-8")
corte_ui <- grep("^# --- UI ---", lineas_app)[1]
stopifnot(!is.na(corte_ui))
local({
  setwd(ruta_app)
  eval(parse(text = paste(lineas_app[1:(corte_ui - 1)], collapse = "\n")),
       envir = globalenv())
  setwd(ruta_raiz)
})

catalogo <- read_csv(
  file.path(ruta_app, "catalogos_sinco", "sinco_con_exposicion_ia_es.csv"),
  show_col_types = FALSE
) %>%
  select(unitario_4d, unitario_titulo, potencial_ia_2025) %>%
  unique()

base <- read_dta(file.path(ruta_app, "zcalculos_Y2026T01_4d.dta")) %>%
  mutate(sinco4d = str_pad(sinco4d, width = 3, side = "left", pad = "0")) %>%
  left_join(catalogo, by = c("sinco4d" = "unitario_4d")) %>%
  mutate(
    gradiente = case_when(
      potencial_ia_2025 == "Not Exposed"         ~ "No expuesto",
      potencial_ia_2025 == "Minimal Exposure"    ~ "Exposición mínima",
      potencial_ia_2025 == "Mixto"               ~ "Mixto",
      potencial_ia_2025 == "Exposed: Gradient 1" ~ "Gradiente 1",
      potencial_ia_2025 == "Exposed: Gradient 2" ~ "Gradiente 2",
      potencial_ia_2025 == "Exposed: Gradient 3" ~ "Gradiente 3",
      potencial_ia_2025 == "Exposed: Gradient 4" ~ "Gradiente 4",
      TRUE                                       ~ "Sin información"
    ),
    gradiente = factor(gradiente, levels = names(colores_gradiente))
  )

# Solo se etiquetan las ocupaciones grandes: en un treemap de 480 rectángulos
# el resto de los nombres no se alcanza a leer al proyectar
dibujar_treemap <- function(sexo_valor, titulo, subtitulo, umbral) {
  # En el mapa del total se conservan los títulos oficiales del SINCO: la
  # forma inclusiva con barras satura un mapa de casi 500 rectángulos. En
  # el mapa femenino sí se flexiona, que es donde el género es el mensaje.
  datos <- base %>%
    filter(sex == sexo_valor, ocup > 0) %>%
    mutate(
      titulo_display = if (sexo_valor == 2) {
        flexionar_titulos(unitario_titulo, "fem")
      } else {
        unitario_titulo
      },
      etiqueta = ifelse(ocup >= umbral, str_wrap(titulo_display, 22), "")
    )

  ggplot(datos, aes(area = ocup, fill = gradiente, label = etiqueta)) +
    geom_treemap(colour = "white", size = 0.8) +
    geom_treemap_text(colour = "#1A1A1A", place = "centre", reflow = TRUE,
                      family = tipografia, min.size = 4, size = 9,
                      grow = FALSE) +
    scale_fill_manual(values = colores_gradiente, drop = FALSE,
                      name = NULL) +
    guides(fill = guide_legend(nrow = 2, byrow = TRUE,
                               keywidth = unit(0.9, "lines"),
                               keyheight = unit(0.6, "lines"))) +
    labs(
      title = titulo,
      subtitle = str_wrap(subtitulo, 108),
      caption = paste0(
        "Cada rectángulo es una de las 483 ocupaciones del catálogo SINCO; su tamaño es la población ocupada.\n",
        "Fuente: cálculos propios con INEGI, ENOE ", periodo,
        ", e índice OIT-NASK (Gmyrek et al., 2025, OIT WP140)."
      )
    ) +
    theme_minimal(base_family = tipografia, base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 19, colour = "#2C2C2C",
                                margin = margin(b = 4)),
      plot.subtitle = element_text(size = 12.5, colour = "#777777",
                                   margin = margin(b = 12)),
      plot.caption = element_text(size = 9, colour = "#777777", hjust = 0,
                                  lineheight = 1.25, margin = margin(t = 10)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      legend.position = "top",
      legend.text = element_text(size = 10.5, colour = "#2C2C2C"),
      legend.margin = margin(b = 6),
      plot.margin = margin(16, 18, 12, 16),
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

tm_total <- dibujar_treemap(
  0,
  "El mercado laboral mexicano, coloreado por exposición a la IA",
  paste0("Población ocupada total, ", periodo,
         ". El verde marca el trabajo que la IA todavía no toca; el rojo, donde ya puede hacer la mayoría de las tareas."),
  umbral = 320000
)

tm_mujeres <- dibujar_treemap(
  2,
  "El mismo mapa, solo con el empleo de las mujeres",
  paste0("Población ocupada femenina, ", periodo,
         ". Crecen los rectángulos naranjas y rojos del trabajo administrativo."),
  umbral = 210000
)

ggsave(file.path(ruta_salida, "fig06_treemap_total.png"), tm_total,
       width = 10.4, height = 6.4, dpi = 300, bg = "white",
       device = ragg::agg_png)
ggsave(file.path(ruta_salida, "fig07_treemap_mujeres.png"), tm_mujeres,
       width = 10.4, height = 6.4, dpi = 300, bg = "white",
       device = ragg::agg_png)

print("Treemaps guardados.")

# --- Versiones para la presentación (sin título ni pie, ver script 02) --------
desnudar <- function(grafica) {
  grafica + labs(title = NULL, subtitle = NULL, caption = NULL)
}

ggsave(file.path(ruta_salida, "deck_06_treemap_total.png"),
       desnudar(tm_total), width = 9.4, height = 5.0, dpi = 300,
       bg = "white", device = ragg::agg_png)
ggsave(file.path(ruta_salida, "deck_07_treemap_mujeres.png"),
       desnudar(tm_mujeres), width = 9.4, height = 5.0, dpi = 300,
       bg = "white", device = ragg::agg_png)

print("Treemaps para el deck generados.")
