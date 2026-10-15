# =====================================================================
# Versión estática (ggplot2) de la gráfica del resumen ejecutivo de la
# app sobre composición del empleo por división SINCO: qué proporción de
# la población ocupada trabaja en ocupaciones "de escritorio"
# (divisiones 1 a 3: funcionarios y directivos, profesionistas y
# técnicos, oficinistas), para el total y por sexo.
#
# Genera un PNG a 300 DPI listo para un artículo o presentación.
#
# Uso:
#   Rscript 00_Códigos/Scripts_graficas_presentacion/02_composicion_empleo_divisiones.R
#
# Salidas (en 03_Archivos/graficas_presentacion/):
#   composicion_empleo_divisiones.png
#   composicion_empleo_divisiones_desnuda.png  (sin título ni pie, para
#                                               diapositivas)
#   composicion_empleo_divisiones.csv          (datos de respaldo)
# =====================================================================

library(tidyverse)
library(haven)
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
# Se evalúa app.R solo hasta antes de la definición de la UI, para usar
# exactamente los mismos datos (bd_divisiones, pct_escritorio) y la misma
# paleta que la app sin duplicar código.
setwd(ruta_app)
lineas_app <- readLines("app.R", encoding = "UTF-8")
corte_ui <- grep("^# --- UI ---", lineas_app)[1]
stopifnot(!is.na(corte_ui))
eval(
  parse(text = paste(lineas_app[1:(corte_ui - 1)], collapse = "\n")),
  envir = globalenv()
)
setwd(ruta_raiz)

# --- Datos para la gráfica ---
# Posición del centro de cada segmento para colocar las etiquetas de las
# divisiones de escritorio; las demás divisiones no llevan etiqueta
df <- bd_divisiones %>%
  arrange(poblacion, division_label) %>%
  group_by(poblacion) %>%
  mutate(
    x_fin = cumsum(pct_ocup),
    x_centro = x_fin - pct_ocup / 2,
    etiqueta = ifelse(escritorio & pct_ocup >= 5, formato_pct(pct_ocup), "")
  ) %>%
  ungroup()

# Etiqueta con la suma de las tres divisiones al final del bloque azul
df_anota <- pct_escritorio %>%
  mutate(etiqueta = formato_pct(pct))

# --- Gráfica base ---
titulo <- paste0(
  "Las ocupaciones de escritorio concentran el ",
  pct_escritorio_total, " del empleo en México"
)
subtitulo <- paste0(
  "Distribución porcentual de la población ocupada por división ",
  "SINCO | ENOE ", periodo_enoe
)
pie <- paste0(
  "Escritorio = divisiones 1 a 3 del SINCO 2019 (funcionarios y ",
  "directivos, profesionistas y técnicos, oficinistas).\n",
  "Fuente: INEGI, ENOE ", periodo_enoe, ". Cálculos propios."
)

g <- ggplot(df, aes(x = pct_ocup, y = poblacion, fill = division_label)) +
  # position_stack(reverse = TRUE) apila la primera división pegada al
  # cero, igual que en la app; sin esto ggplot la pondría a la derecha
  geom_col(
    width = 0.7, color = "white", linewidth = 0.3,
    position = position_stack(reverse = TRUE)
  ) +
  geom_text(
    aes(x = x_centro, label = etiqueta),
    family = "Ubuntu", size = 3.4, color = "white"
  ) +
  geom_label(
    data = df_anota,
    aes(x = pct, y = poblacion, label = etiqueta),
    inherit.aes = FALSE,
    hjust = 0, nudge_x = 1.2,
    family = "Ubuntu", fontface = "bold", size = 3.9,
    color = "#2b2dd6", fill = "white", label.size = 0.4,
    label.padding = unit(0.2, "lines")
  ) +
  scale_fill_manual(values = colores_division, name = NULL) +
  scale_x_continuous(
    labels = function(x) paste0(x, "%"),
    breaks = seq(0, 100, 20),
    expand = expansion(mult = c(0, 0.02))
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(
    title = str_wrap(titulo, 70),
    subtitle = subtitulo,
    x = "Porcentaje de la población ocupada",
    y = NULL,
    caption = pie
  ) +
  theme_minimal(base_family = "Ubuntu", base_size = 12) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.text = element_text(size = 8.5, color = "#333333"),
    legend.key.size = unit(0.4, "cm"),
    plot.title = element_text(
      face = "bold", size = 14, color = "#2c3e50",
      margin = margin(b = 4)
    ),
    plot.subtitle = element_text(
      size = 10.5, color = "#6950d8", margin = margin(b = 6)
    ),
    plot.caption = element_text(
      size = 8, color = "#666666", hjust = 0, margin = margin(t = 10)
    ),
    plot.caption.position = "plot",
    plot.title.position = "plot",
    axis.title.x = element_text(size = 9, color = "#666666"),
    axis.text.y = element_text(size = 11, color = "#333333"),
    axis.text.x = element_text(size = 9, color = "#666666"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "#e5e5e5", linewidth = 0.3),
    plot.margin = margin(15, 20, 12, 12)
  )

# Versión sin título, subtítulo ni pie para diapositivas, donde el título
# lo pone la lámina y la fuente va al pie de la misma
g_desnuda <- g + labs(title = NULL, subtitle = NULL, caption = NULL)

# --- Exportación ---
ggsave(
  file.path(ruta_salida, "composicion_empleo_divisiones.png"),
  g, width = 9, height = 5.2, dpi = 300, device = agg_png, bg = "white"
)
ggsave(
  file.path(ruta_salida, "composicion_empleo_divisiones_desnuda.png"),
  g_desnuda, width = 9, height = 4.6, dpi = 300, device = agg_png,
  bg = "white"
)

# Datos de respaldo de la gráfica
df %>%
  select(poblacion, division, division_label, total_ocup, pct_ocup,
         escritorio) %>%
  arrange(desc(poblacion), division) %>%
  write_csv(file.path(ruta_salida, "composicion_empleo_divisiones.csv"))

print(paste0("Gráficas guardadas en ", ruta_salida))
