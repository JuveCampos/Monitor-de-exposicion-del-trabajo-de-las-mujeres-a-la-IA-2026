# =====================================================================
# Versión estática (ggplot2) de las dos gráficas del resumen ejecutivo
# de la app: top 10 de ocupaciones masculinas y femeninas en exposición
# significativa y máxima a la IA.
#
# Genera PNG a 300 DPI listos para insertarse en una presentación.
#
# Uso:
#   Rscript 00_Códigos/Scripts_graficas_presentacion/01_top10_ocupaciones_expuestas.R
#
# Salidas (en 03_Archivos/graficas_presentacion/):
#   top10_ocupaciones_hombres.png
#   top10_ocupaciones_mujeres.png
#   top10_ocupaciones_comparativo.png  (las dos en una sola lámina)
# =====================================================================

library(tidyverse)
library(haven)
library(patchwork)
library(ragg)

# --- Rutas ---
# El script se ejecuta desde la raíz del repositorio
ruta_raiz <- normalizePath(".")
ruta_app <- file.path(ruta_raiz, "04_Aplicación")
ruta_salida <- file.path(ruta_raiz, "03_Archivos", "graficas_presentacion")

stopifnot(dir.exists(ruta_app))
if (!dir.exists(ruta_salida)) {
  dir.create(ruta_salida, recursive = TRUE)
}

# --- Reutilización del bloque de datos de la app ---
# Se evalúa app.R solo hasta antes de la definición de la UI. Así las
# gráficas estáticas usan exactamente los mismos datos, la misma
# flexión de género y la misma paleta que la app, sin duplicar código
# ni arrancar el servidor de Shiny.
setwd(ruta_app)
lineas_app <- readLines("app.R", encoding = "UTF-8")
corte_ui <- grep("^# --- UI ---", lineas_app)[1]
stopifnot(!is.na(corte_ui))
eval(
  parse(text = paste(lineas_app[1:(corte_ui - 1)], collapse = "\n")),
  envir = globalenv()
)
setwd(ruta_raiz)

# --- Preparación de los dos data frames (igual que en el server) ---
preparar_top10 <- function(sexo, modo_genero) {
  bd_top10 %>%
    filter(sexo_label == sexo) %>%
    mutate(
      titulo_display = flexionar_titulos(unitario_titulo, modo_genero),
      titulo_corto = ifelse(
        nchar(titulo_display) > 50,
        paste0(substr(titulo_display, 1, 47), "..."),
        titulo_display
      )
    ) %>%
    arrange(ocup) %>%
    mutate(titulo_corto = factor(titulo_corto, levels = titulo_corto))
}

df_h <- preparar_top10("Hombres", "masc")
df_m <- preparar_top10("Mujeres", "fem")

# --- Función generadora de la gráfica estática ---
graficar_top10 <- function(datos, color_barra, alpha_barra,
                           titulo, subtitulo, etiqueta_total) {
  ggplot(datos, aes(x = ocup, y = titulo_corto)) +
    geom_col(fill = color_barra, alpha = alpha_barra, width = 0.75) +
    geom_text(
      aes(label = format(round(ocup), big.mark = ",", scientific = FALSE)),
      hjust = -0.15,
      size = 3.4,
      family = "Ubuntu",
      color = "#333333"
    ) +
    scale_x_continuous(
      labels = function(x) format(x, big.mark = ",", scientific = FALSE),
      expand = expansion(mult = c(0, 0.22))
    ) +
    labs(
      title = titulo,
      subtitle = subtitulo,
      x = "Población ocupada",
      y = NULL,
      caption = paste0(
        etiqueta_total, "\n",
        "Fuente: INEGI, ENOE ", periodo_enoe,
        ". Clasificación SINCO a 4 dígitos y scores de exposición a la ",
        "IA de la OIT (WP140). Cálculos propios."
      )
    ) +
    theme_minimal(base_family = "Ubuntu", base_size = 12) +
    theme(
      plot.title = element_text(
        face = "bold", size = 14, color = "#2c3e50",
        margin = margin(b = 4)
      ),
      plot.subtitle = element_text(
        size = 11, color = "#6950d8", margin = margin(b = 12)
      ),
      plot.caption = element_text(
        size = 8, color = "#666666", hjust = 0,
        margin = margin(t = 12)
      ),
      plot.caption.position = "plot",
      plot.title.position = "plot",
      axis.title.x = element_text(size = 9, color = "#666666"),
      axis.text.y = element_text(size = 9.5, color = "#333333"),
      axis.text.x = element_text(size = 9, color = "#666666"),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(color = "#e5e5e5", linewidth = 0.3),
      plot.margin = margin(15, 20, 12, 12)
    )
}

texto_total_h <- paste0(
  "Las diez ocupaciones concentran a ",
  total_top10_h, " hombres ocupados."
)
texto_total_m <- paste0(
  "Las diez ocupaciones concentran a ",
  total_top10_m, " mujeres ocupadas."
)

g_h <- graficar_top10(
  df_h,
  color_barra = colores_sexo[["Hombres"]],
  alpha_barra = 0.5,
  titulo = paste0(
    "Top 10 ocupaciones masculinas en exposición ",
    "significativa y máxima"
  ),
  subtitulo = paste0("Hombres | ENOE ", periodo_enoe),
  etiqueta_total = texto_total_h
)

g_m <- graficar_top10(
  df_m,
  color_barra = colores_sexo[["Mujeres"]],
  alpha_barra = 1,
  titulo = paste0(
    "Top 10 ocupaciones femeninas en exposición ",
    "significativa y máxima"
  ),
  subtitulo = paste0("Mujeres | ENOE ", periodo_enoe),
  etiqueta_total = texto_total_m
)

# --- Exportación a PNG (300 DPI) ---
ggsave(
  file.path(ruta_salida, "top10_ocupaciones_hombres.png"),
  g_h, width = 10, height = 5.5, dpi = 300, device = ragg::agg_png,
  bg = "white"
)
ggsave(
  file.path(ruta_salida, "top10_ocupaciones_mujeres.png"),
  g_m, width = 10, height = 5.5, dpi = 300, device = ragg::agg_png,
  bg = "white"
)

# Lámina comparativa: las dos gráficas lado a lado, con una sola
# escala horizontal para que los tamaños sean comparables entre sexos
limite_comun <- max(c(df_h$ocup, df_m$ocup)) * 1.22

escala_comun <- scale_x_continuous(
  labels = function(x) format(x, big.mark = ",", scientific = FALSE),
  limits = c(0, limite_comun),
  expand = expansion(mult = c(0, 0))
)

# La escala nueva reemplaza a la del theme base; el mensaje de ggplot2
# al respecto no aporta información aquí
g_h_comun <- suppressMessages(g_h + escala_comun)
g_m_comun <- suppressMessages(g_m + escala_comun)

g_comparativo <- (g_h_comun + g_m_comun) +
  plot_annotation(
    title = paste0(
      "Las ocupaciones femeninas más expuestas a la IA concentran ",
      "casi el doble de personas que las masculinas"
    ),
    theme = theme(
      plot.title = element_text(
        family = "Ubuntu", face = "bold", size = 16,
        color = "#6950d8", margin = margin(b = 10)
      )
    )
  )

ggsave(
  file.path(ruta_salida, "top10_ocupaciones_comparativo.png"),
  g_comparativo, width = 17, height = 6, dpi = 300,
  device = ragg::agg_png, bg = "white"
)

print(paste0("Gráficas guardadas en: ", ruta_salida))
