# ==============================================================================
# Figuras para la presentación del foro sobre informalidad e IA
#
# Paleta: identidad de México, ¿Cómo vamos? (morado #6950D8) para los cortes
# por sexo y por tipo de informalidad; escala verde-rojo del Monitor para los
# gradientes de exposición, de modo que las gráficas se lean junto al treemap.
#
# Uso (desde la raíz del repositorio):
#   Rscript 05_Presentacion_foro/codigo/02_genera_figuras.R
# ==============================================================================

library(haven)
library(tidyverse)
library(scales)

ruta_raiz <- normalizePath(".")
ruta_app <- file.path(ruta_raiz, "04_Aplicación")
ruta_salida <- file.path(ruta_raiz, "05_Presentacion_foro", "figuras")

periodo <- "1T2026"
tipografia <- "Helvetica Neue"

# --- Paleta -------------------------------------------------------------------
mcv_morado  <- "#6950D8"
mcv_lila    <- "#A99BE9"
mcv_coral   <- "#FF6260"
mcv_verde   <- "#00B783"
mcv_amarillo <- "#FFBD41"
mcv_gris    <- "#777777"
mcv_gris_cl <- "#D2D0CD"
col_texto   <- "#2C2C2C"

# Escala del Monitor para los gradientes de exposición
colores_gradiente <- c(
  "No expuesto"       = "#1A9641",
  "Exposición mínima" = "#7BC96A",
  "Mixto"             = "#D9D97F",
  "Gradiente 1"       = "#FEE08B",
  "Gradiente 2"       = "#FDAE61",
  "Gradiente 3"       = "#F46D43",
  "Gradiente 4"       = "#D73027"
)

# --- Tema común ---------------------------------------------------------------
tema_foro <- function(base_size = 15) {
  theme_minimal(base_size = base_size, base_family = tipografia) +
    theme(
      plot.title = element_text(size = base_size * 1.25, face = "bold",
                                colour = col_texto, lineheight = 1.15,
                                margin = margin(b = 6), hjust = 0),
      plot.subtitle = element_text(size = base_size * 0.88, colour = mcv_gris,
                                   lineheight = 1.3, margin = margin(b = 16),
                                   hjust = 0),
      plot.caption = element_text(size = base_size * 0.62, colour = mcv_gris,
                                  hjust = 0, lineheight = 1.25,
                                  margin = margin(t = 14)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.title = element_text(size = base_size * 0.8, colour = mcv_gris),
      axis.text = element_text(colour = col_texto, size = base_size * 0.85),
      panel.grid.minor = element_blank(),
      legend.position = "top",
      legend.title = element_blank(),
      legend.text = element_text(colour = col_texto, size = base_size * 0.85),
      plot.margin = margin(16, 20, 12, 16),
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

fuente_propia <- paste0(
  "Fuente: cálculos propios con INEGI, ENOE ", periodo,
  ", y el catálogo SINCO de exposición a la IA generativa\n",
  "del Monitor (índice OIT-NASK; Gmyrek et al., 2025, OIT WP140)."
)

# Los títulos no se envuelven solos, así que se ajustan a mano
tit <- function(x, n = 58) str_wrap(x, n)
sub <- function(x, n = 88) str_wrap(x, n)

guardar <- function(grafica, archivo, ancho = 9.6, alto = 5.9) {
  ggsave(file.path(ruta_salida, archivo), grafica,
         width = ancho, height = alto, dpi = 300, bg = "white",
         device = ragg::agg_png)
  print(paste("Guardada:", archivo))
}

# --- Datos --------------------------------------------------------------------
catalogo <- read_csv(
  file.path(ruta_app, "catalogos_sinco", "sinco_con_exposicion_ia_es.csv"),
  show_col_types = FALSE
) %>%
  select(unitario_4d, unitario_titulo, mean_score_ia_2025,
         potencial_ia_2025) %>%
  unique()

niveles_gradiente <- names(colores_gradiente)

base <- read_dta(file.path(ruta_app, "zcalculos_Y2026T01_4d.dta")) %>%
  mutate(sinco4d = str_pad(sinco4d, width = 3, side = "left", pad = "0")) %>%
  left_join(catalogo, by = c("sinco4d" = "unitario_4d")) %>%
  mutate(
    sexo = factor(sex, levels = c(0, 1, 2),
                  labels = c("Total", "Hombres", "Mujeres")),
    ocup_formal = ocup - ocuptil,
    gradiente = case_when(
      potencial_ia_2025 == "Not Exposed"         ~ "No expuesto",
      potencial_ia_2025 == "Minimal Exposure"    ~ "Exposición mínima",
      potencial_ia_2025 == "Mixto"               ~ "Mixto",
      potencial_ia_2025 == "Exposed: Gradient 1" ~ "Gradiente 1",
      potencial_ia_2025 == "Exposed: Gradient 2" ~ "Gradiente 2",
      potencial_ia_2025 == "Exposed: Gradient 3" ~ "Gradiente 3",
      potencial_ia_2025 == "Exposed: Gradient 4" ~ "Gradiente 4",
      TRUE                                       ~ NA_character_
    ),
    gradiente = factor(gradiente, levels = niveles_gradiente)
  )

# ==============================================================================
# Figura 1. Composición de la informalidad
# Los cuatro componentes de la tasa de informalidad laboral. El mensaje está
# en el segundo bloque: informalidad dentro de la economía formal.
# ==============================================================================
# Cifras publicadas por México, ¿Cómo vamos? con ENOE 1T2026
tipos_informalidad <- tibble(
  tipo = c("Sector informal", "Empresas, gobierno\ne instituciones",
           "Ámbito agropecuario", "Trabajo doméstico\nremunerado"),
  valor = c(29.5, 12.9, 8.7, 3.7),
  destaca = c(FALSE, TRUE, FALSE, FALSE)
) %>%
  mutate(tipo = factor(tipo, levels = rev(tipo)))

fig1 <- ggplot(tipos_informalidad,
               aes(x = valor, y = tipo, fill = destaca)) +
  geom_col(width = 0.66) +
  geom_text(aes(label = paste0(number(valor, accuracy = 0.1), " %")),
            hjust = -0.18, size = 5.4, fontface = "bold",
            colour = col_texto, family = tipografia) +
  scale_fill_manual(values = c("TRUE" = mcv_morado, "FALSE" = mcv_gris_cl),
                    guide = "none") +
  scale_x_continuous(limits = c(0, 36), expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = tit("La informalidad también ocurre dentro de la economía formal"),
    subtitle = sub(paste0(
      "Componentes de la tasa de informalidad laboral, ", periodo,
      ". Total: 54.8 % de la población ocupada, 32.6 millones de personas."
    )),
    x = "Porcentaje de la población ocupada", y = NULL,
    caption = paste0(
      "Fuente: México, ¿Cómo vamos? con INEGI, ENOE ", periodo, "."
    )
  ) +
  annotate("segment", x = 16.2, xend = 13.6, y = 2.5, yend = 2.86,
           colour = mcv_morado, linewidth = 0.4) +
  annotate("text", x = 15.2, y = 2.1,
           label = "13 de cada 100 personas ocupadas\ntrabajan en una empresa formal\ny salen de ahí sin seguridad social",
           hjust = 0, size = 4.1, colour = mcv_morado, fontface = "bold",
           family = tipografia, lineheight = 1.25) +
  tema_foro() +
  theme(panel.grid.major.y = element_blank())

guardar(fig1, "fig01_composicion_informalidad.png")

# ==============================================================================
# Figura 2. Informalidad por gradiente de exposición
# Es la lámina del giro argumental: a mayor exposición, menor informalidad.
# ==============================================================================
fig2_datos <- base %>%
  filter(sexo == "Total", !is.na(gradiente), gradiente != "Mixto") %>%
  group_by(gradiente) %>%
  summarise(ocupados = sum(ocup, na.rm = TRUE),
            informales = sum(ocuptil, na.rm = TRUE), .groups = "drop") %>%
  mutate(til = 100 * informales / ocupados)

fig2 <- ggplot(fig2_datos, aes(x = gradiente, y = til, fill = gradiente)) +
  geom_col(width = 0.68) +
  geom_text(aes(label = paste0(number(til, accuracy = 0.1), " %")),
            vjust = -0.6, size = 5, fontface = "bold", colour = col_texto,
            family = tipografia) +
  scale_fill_manual(values = colores_gradiente, guide = "none") +
  scale_y_continuous(limits = c(0, 88), expand = expansion(mult = c(0, 0.02)),
                     labels = function(x) paste0(x, " %")) +
  annotate("segment", x = 1.3, xend = 5.7, y = 80, yend = 80,
           colour = mcv_morado, linewidth = 0.6,
           arrow = arrow(length = unit(0.18, "cm"), ends = "last")) +
  annotate("text", x = 3.5, y = 84,
           label = "A mayor exposición a la IA, menor informalidad",
           size = 4.6, fontface = "bold", colour = mcv_morado,
           family = tipografia) +
  annotate("segment", x = 4.35, xend = 3.2, y = 62, yend = 60,
           colour = mcv_gris, linewidth = 0.35) +
  annotate("text", x = 4.45, y = 64.5,
           label = "La excepción: una sola ocupación,\nempleados de ventas y dependientes\nen comercios, explica este dato",
           size = 3.5, colour = mcv_gris, family = tipografia,
           lineheight = 1.15, hjust = 0) +
  labs(
    title = tit("Entre más expuesta a la IA está una ocupación mexicana, más formal es", 66),
    subtitle = sub(paste0(
      "Tasa de informalidad laboral de la población ocupada, por gradiente de exposición a la IA generativa, ",
      periodo, "."
    )),
    x = NULL, y = "Tasa de informalidad",
    caption = fuente_propia
  ) +
  tema_foro() +
  theme(panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 11.5))

guardar(fig2, "fig02_informalidad_por_gradiente.png")

# ==============================================================================
# Figura 3. Exposición promedio, empleo formal frente a informal
# Lámina de respaldo: replica para México el hallazgo del WP121.
# ==============================================================================
fig3_datos <- base %>%
  filter(sexo %in% c("Hombres", "Mujeres"),
         !is.na(mean_score_ia_2025), ocup > 0) %>%
  group_by(sexo) %>%
  summarise(
    Formal = weighted.mean(mean_score_ia_2025, ocup_formal, na.rm = TRUE),
    Informal = weighted.mean(mean_score_ia_2025, ocuptil, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(c(Formal, Informal), names_to = "condicion",
               values_to = "exposicion")

fig3 <- ggplot(fig3_datos,
               aes(x = condicion, y = exposicion, fill = sexo)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.62) +
  geom_text(aes(label = number(exposicion, accuracy = 0.001)),
            position = position_dodge(width = 0.72), vjust = -0.6,
            size = 4.8, fontface = "bold", colour = col_texto,
            family = tipografia) +
  scale_fill_manual(values = c("Hombres" = mcv_verde, "Mujeres" = mcv_morado)) +
  scale_y_continuous(limits = c(0, 0.42), expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = tit("Las mujeres con empleo formal son el grupo más expuesto"),
    subtitle = sub(paste0(
      "Exposición promedio a la IA generativa (puntaje de 0 a 1), ponderada por población ocupada, ",
      periodo, "."
    )),
    x = NULL, y = "Exposición promedio",
    caption = fuente_propia
  ) +
  tema_foro() +
  theme(panel.grid.major.x = element_blank())

guardar(fig3, "fig03_exposicion_formal_informal.png", alto = 5.6)

# ==============================================================================
# Figura 4. Empleo en los gradientes altos por sexo
# Lámina de la tesis.
# ==============================================================================
fig4_datos <- base %>%
  filter(sexo %in% c("Hombres", "Mujeres")) %>%
  group_by(sexo) %>%
  summarise(
    total = sum(ocup, na.rm = TRUE),
    altos = sum(ocup[gradiente %in% c("Gradiente 3", "Gradiente 4")],
                na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct = 100 * altos / total,
    etiqueta = paste0(number(pct, accuracy = 0.1), " %"),
    sub_etiqueta = paste0(number(altos, big.mark = ",", accuracy = 1),
                          "\npersonas")
  )

fig4 <- ggplot(fig4_datos, aes(x = sexo, y = pct, fill = sexo)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = etiqueta), vjust = -0.55, size = 8,
            fontface = "bold", colour = col_texto, family = tipografia) +
  geom_text(aes(label = sub_etiqueta, y = pct / 2), colour = "white",
            size = 4.6, family = tipografia, lineheight = 1.1) +
  scale_fill_manual(values = c("Hombres" = mcv_verde, "Mujeres" = mcv_morado),
                    guide = "none") +
  scale_y_continuous(limits = c(0, 9.6), expand = expansion(mult = c(0, 0.02)),
                     labels = function(x) paste0(x, " %")) +
  annotate("text", x = 1, y = 6.2,
           label = "Las mujeres duplican\ncon creces a los hombres:\n2.6 veces más",
           size = 4.4, fontface = "bold", colour = mcv_morado,
           family = tipografia, lineheight = 1.25) +
  labs(
    title = tit("El empleo femenino se concentra en las ocupaciones más expuestas", 44),
    subtitle = sub(paste0(
      "Porcentaje del empleo de cada sexo en los gradientes 3 y 4, los de mayor exposición a la IA, ",
      periodo, "."
    ), 62),
    x = NULL, y = "Porcentaje del empleo de cada sexo",
    caption = fuente_propia
  ) +
  tema_foro() +
  theme(panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 14, face = "bold"))

guardar(fig4, "fig04_empleo_gradientes_altos.png", ancho = 8.4, alto = 5.9)

# ==============================================================================
# Figura 5. Las ocupaciones concretas
# Lámina que aterriza la abstracción en oficios con nombre.
# ==============================================================================
fig5_datos <- base %>%
  filter(gradiente %in% c("Gradiente 3", "Gradiente 4")) %>%
  select(sinco4d, unitario_titulo, sexo, ocup) %>%
  pivot_wider(names_from = sexo, values_from = ocup) %>%
  mutate(pct_mujeres = 100 * Mujeres / Total) %>%
  arrange(desc(Total)) %>%
  slice_head(n = 7) %>%
  mutate(
    titulo_corto = case_when(
      sinco4d == "3115" ~ "Apoyo administrativo",
      sinco4d == "2121" ~ "Contadores y auditores",
      sinco4d == "3111" ~ "Secretariado",
      sinco4d == "3211" ~ "Recepción e información",
      sinco4d == "3113" ~ "Capturistas de datos",
      sinco4d == "3212" ~ "Centros de llamadas",
      sinco4d == "4213" ~ "Ventas por teléfono",
      TRUE ~ str_trunc(unitario_titulo, 34)
    ),
    titulo_corto = paste0(
      titulo_corto, "  (",
      number(Total / 1000, accuracy = 1, big.mark = ","), " mil)"
    )
  ) %>%
  arrange(pct_mujeres) %>%
  mutate(titulo_corto = factor(titulo_corto, levels = titulo_corto))

fig5 <- ggplot(fig5_datos, aes(x = pct_mujeres, y = titulo_corto)) +
  geom_col(fill = mcv_morado, width = 0.62) +
  geom_vline(xintercept = 40.8, colour = mcv_coral, linewidth = 0.7,
             linetype = "22") +
  geom_text(aes(label = paste0(number(pct_mujeres, accuracy = 0.1), " %")),
            hjust = -0.16, size = 4.8, fontface = "bold", colour = col_texto,
            family = tipografia) +
  annotate("text", x = 43, y = 7.75,
           label = "Mujeres en el empleo total: 40.8 %",
           hjust = 0, size = 3.9, colour = mcv_coral, fontface = "bold",
           family = tipografia) +
  scale_x_continuous(limits = c(0, 112), expand = expansion(mult = c(0, 0)),
                     breaks = seq(0, 100, 25),
                     labels = function(x) paste0(x, " %")) +
  scale_y_discrete(expand = expansion(add = c(0.6, 1.1))) +
  labs(
    title = tit("Los oficios más expuestos son oficios de mujeres"),
    subtitle = sub(paste0(
      "Porcentaje de mujeres en las siete ocupaciones más grandes de los gradientes 3 y 4, ",
      periodo, ". Entre paréntesis, el total de personas ocupadas en cada una."
    )),
    x = "Porcentaje de mujeres en la ocupación", y = NULL,
    caption = fuente_propia
  ) +
  tema_foro() +
  theme(panel.grid.major.y = element_blank())

guardar(fig5, "fig05_ocupaciones_concretas.png", alto = 5.9)

print("Figuras generadas.")

# ==============================================================================
# Versiones para la presentación
# En el deck el título va como título de la diapositiva y la fuente como pie,
# así que aquí se retiran de la figura para no duplicarlos ni desperdiciar
# espacio de proyección. Las anotaciones sobre el gráfico se conservan.
# ==============================================================================
desnudar <- function(grafica) {
  grafica + labs(title = NULL, subtitle = NULL, caption = NULL)
}

guardar(desnudar(fig1), "deck_01_composicion_informalidad.png",
        ancho = 9.4, alto = 4.7)
guardar(desnudar(fig2), "deck_02_informalidad_por_gradiente.png",
        ancho = 9.4, alto = 4.9)
guardar(desnudar(fig3), "deck_03_exposicion_formal_informal.png",
        ancho = 9.4, alto = 4.9)
guardar(desnudar(fig4), "deck_04_empleo_gradientes_altos.png",
        ancho = 9.4, alto = 4.5)
guardar(desnudar(fig5), "deck_05_ocupaciones_concretas.png",
        ancho = 9.4, alto = 4.9)

print("Versiones para el deck generadas.")
