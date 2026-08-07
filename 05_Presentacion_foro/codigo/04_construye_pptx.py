#!/usr/bin/env python3
# ==============================================================================
# Presentación para el foro sobre informalidad e inteligencia artificial
#
# Formato 4:3 (10 x 7.5 pulgadas), identidad de México, ¿Cómo vamos?
# Las figuras se generan antes con los scripts de R de esta misma carpeta.
#
# Uso (desde la raíz del repositorio):
#   python3 05_Presentacion_foro/codigo/04_construye_pptx.py
# ==============================================================================

from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

# --- Rutas --------------------------------------------------------------------
RAIZ = Path(__file__).resolve().parents[2]
FIGURAS = RAIZ / "05_Presentacion_foro" / "figuras"
SALIDA = RAIZ / "05_Presentacion_foro" / "informalidad_e_IA_foro.pptx"
LOGO_MCV = RAIZ / "04_Aplicación" / "www" / "logo_mcv.svg"

PERIODO = "1T2026"

# --- Paleta México, ¿Cómo vamos? ---------------------------------------------
MORADO = RGBColor(0x69, 0x50, 0xD8)
MORADO_OSC = RGBColor(0x4A, 0x35, 0xA8)
LILA = RGBColor(0xA9, 0x9B, 0xE9)
LILA_CLARO = RGBColor(0xF0, 0xED, 0xFB)
CORAL = RGBColor(0xFF, 0x62, 0x60)
VERDE = RGBColor(0x00, 0xB7, 0x83)
AMARILLO = RGBColor(0xFF, 0xBD, 0x41)
GRIS = RGBColor(0x77, 0x77, 0x77)
GRIS_CLARO = RGBColor(0xD2, 0xD0, 0xCD)
NEGRO = RGBColor(0x2C, 0x2C, 0x2C)
BLANCO = RGBColor(0xFF, 0xFF, 0xFF)

FUENTE = "Helvetica Neue"

ANCHO = Inches(10)
ALTO = Inches(7.5)
MARGEN = Inches(0.55)


# --- Utilidades ---------------------------------------------------------------
def nueva_presentacion():
    prs = Presentation()
    prs.slide_width = ANCHO
    prs.slide_height = ALTO
    return prs


def slide_en_blanco(prs, fondo=BLANCO):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    fondo_shape = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, 0, 0, ANCHO, ALTO
    )
    fondo_shape.fill.solid()
    fondo_shape.fill.fore_color.rgb = fondo
    fondo_shape.line.fill.background()
    fondo_shape.shadow.inherit = False
    # El rectángulo de fondo se manda al final del orden de dibujo
    spTree = slide.shapes._spTree
    spTree.remove(fondo_shape._element)
    spTree.insert(2, fondo_shape._element)
    return slide


def agregar_texto(slide, texto, x, y, ancho, alto, tam=14, color=NEGRO,
                  negrita=False, italica=False, alineacion=PP_ALIGN.LEFT,
                  interlineado=1.25, anclaje=MSO_ANCHOR.TOP, espacio_post=6):
    """Cada salto de línea se convierte en párrafo para que el interlineado
    y el espaciado funcionen."""
    caja = slide.shapes.add_textbox(x, y, ancho, alto)
    tf = caja.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anclaje
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = 0

    lineas = texto.split("\n")
    for i, linea in enumerate(lineas):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = alineacion
        p.line_spacing = interlineado
        p.space_after = Pt(espacio_post)
        run = p.add_run()
        run.text = linea
        run.font.size = Pt(tam)
        run.font.name = FUENTE
        run.font.bold = negrita
        run.font.italic = italica
        run.font.color.rgb = color
    return caja


def titulo_lamina(slide, texto, subtitulo=None):
    agregar_texto(slide, texto, MARGEN, Inches(0.42), ANCHO - 2 * MARGEN,
                  Inches(0.95), tam=25, color=NEGRO, negrita=True,
                  interlineado=1.05, espacio_post=0)
    if subtitulo:
        agregar_texto(slide, subtitulo, MARGEN, Inches(1.32),
                      ANCHO - 2 * MARGEN, Inches(0.5), tam=13, color=GRIS,
                      interlineado=1.2, espacio_post=0)


def pie_fuente(slide, texto):
    agregar_texto(slide, texto, MARGEN, ALTO - Inches(0.62),
                  ANCHO - 2 * MARGEN - Inches(0.5), Inches(0.42), tam=9,
                  color=GRIS, italica=True, interlineado=1.15, espacio_post=0)


def numero_lamina(slide, numero):
    diam = Inches(0.3)
    circulo = slide.shapes.add_shape(
        MSO_SHAPE.OVAL, ANCHO - MARGEN - diam, ALTO - Inches(0.62), diam, diam
    )
    circulo.fill.solid()
    circulo.fill.fore_color.rgb = MORADO
    circulo.line.fill.background()
    circulo.shadow.inherit = False
    tf = circulo.text_frame
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    run = p.add_run()
    run.text = str(numero)
    run.font.size = Pt(10)
    run.font.name = FUENTE
    run.font.bold = True
    run.font.color.rgb = BLANCO


def tarjeta(slide, x, y, ancho, alto, titulo, cuerpo, color_titulo=MORADO,
            relleno=LILA_CLARO, tam_titulo=13.5, tam_cuerpo=11.5,
            salto=0.42, pad_v=0.2):
    caja = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, x, y, ancho,
                                  alto)
    caja.fill.solid()
    caja.fill.fore_color.rgb = relleno
    caja.line.fill.background()
    caja.shadow.inherit = False
    caja.adjustments[0] = 0.06
    caja.text_frame.text = ""

    pad = Inches(0.2)
    pv = Inches(pad_v)
    agregar_texto(slide, titulo, x + pad, y + pv, ancho - 2 * pad,
                  Inches(0.35), tam=tam_titulo, color=color_titulo,
                  negrita=True, interlineado=1.1, espacio_post=2)
    agregar_texto(slide, cuerpo, x + pad, y + pv + Inches(salto),
                  ancho - 2 * pad, alto - pv * 2 - Inches(salto),
                  tam=tam_cuerpo, color=NEGRO, interlineado=1.25,
                  espacio_post=4)


def figura(slide, archivo, y=Inches(1.85), alto_max=Inches(4.9)):
    """Inserta la figura centrada, ajustando por la proporción del archivo."""
    from PIL import Image

    ruta = FIGURAS / archivo
    with Image.open(ruta) as img:
        prop = img.height / img.width

    ancho_disp = ANCHO - 2 * MARGEN
    alto_calc = int(ancho_disp * prop)
    if alto_calc > alto_max:
        alto_calc = int(alto_max)
        ancho_disp = int(alto_calc / prop)
    x = int((ANCHO - ancho_disp) / 2)
    slide.shapes.add_picture(str(ruta), x, y, ancho_disp, alto_calc)


def notas(slide, texto):
    slide.notes_slide.notes_text_frame.text = texto


# ==============================================================================
# Construcción del deck
# ==============================================================================
prs = nueva_presentacion()

# --- 1. Portada ---------------------------------------------------------------
s = slide_en_blanco(prs, fondo=MORADO)
agregar_texto(
    s,
    "¿Y si la IA viene primero\npor los trabajos con IMSS\ny prestaciones?",
    MARGEN, Inches(1.9), ANCHO - 2 * MARGEN, Inches(2.6),
    tam=38, color=BLANCO, negrita=True, interlineado=1.05, espacio_post=0
)
agregar_texto(
    s,
    "Informalidad laboral y exposición a la inteligencia artificial "
    "en México",
    MARGEN, Inches(4.6), ANCHO - 2 * MARGEN, Inches(0.7),
    tam=16, color=BLANCO, italica=True, interlineado=1.2, espacio_post=0
)
agregar_texto(
    s,
    "Jorge Juvenal Campos Ferreira\nMéxico, ¿Cómo vamos?",
    MARGEN, Inches(5.7), ANCHO - 2 * MARGEN, Inches(1.0),
    tam=13, color=BLANCO, interlineado=1.35, espacio_post=0
)
notas(s, (
    "Minuto 0. Presentación.\n\n"
    "Gancho sugerido: acabamos de ver una fotografía muy completa de la "
    "informalidad mexicana. Quiero proponerles una pregunta sobre el futuro "
    "de esa fotografía.\n\n"
    "[PENDIENTE: confirmar el nombre exacto del foro, la fecha y si va "
    "coautoría en la portada.]"
))

# --- 2. La pregunta -----------------------------------------------------------
s = slide_en_blanco(prs)
agregar_texto(
    s, "¿Cuál fue tu primer\nempleo formal?",
    MARGEN, Inches(1.5), ANCHO - 2 * MARGEN, Inches(2.0),
    tam=40, color=MORADO, negrita=True, interlineado=1.05, espacio_post=0
)
agregar_texto(
    s,
    "Para la mayoría fue un puesto de oficina: capturar datos, facturar, "
    "atender clientes por teléfono, asistir a una gerencia.",
    MARGEN, Inches(3.7), Inches(8.0), Inches(1.0),
    tam=17, color=NEGRO, interlineado=1.3, espacio_post=0
)
agregar_texto(
    s,
    "No pagaba bien, pero traía IMSS, comprobante de ingresos y la "
    "posibilidad de pedir un crédito.\nEs la puerta principal de entrada a "
    "la formalidad, y la cruzan sobre todo mujeres.",
    MARGEN, Inches(4.9), Inches(8.4), Inches(1.2),
    tam=14, color=GRIS, interlineado=1.35, espacio_post=6
)
numero_lamina(s, 2)
notas(s, (
    "Minuto 0 a 1.\n\n"
    "Preguntarlo en voz alta y dejar tres segundos de silencio. La idea es "
    "que cada persona del público piense en su propio caso antes de ver "
    "cualquier cifra.\n\n"
    "Cierre del bloque: ese puesto es justo el que la inteligencia "
    "artificial toca primero."
))

# --- 3. La informalidad hoy ---------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(
    s,
    "Más de la mitad del país trabaja sin seguridad social",
    "54.8 % de la población ocupada, 32.6 millones de personas, "
    f"ENOE {PERIODO}."
)
figura(s, "deck_01_composicion_informalidad.png", y=Inches(1.95),
       alto_max=Inches(4.5))
pie_fuente(s, "Fuente: México, ¿Cómo vamos? con INEGI, ENOE 1T2026.")
numero_lamina(s, 3)
notas(s, (
    "Minuto 1 a 2.\n\n"
    "El dato que casi nadie tiene presente está en la barra morada: la "
    "informalidad también ocurre dentro de la economía formal. Trece de "
    "cada cien personas ocupadas van todos los días a una empresa que "
    "existe, factura y paga impuestos, y salen de ahí sin cotizar.\n\n"
    "Esa categoría es la que puede crecer sin que nadie pierda el empleo de "
    "forma visible. Guardarla en la memoria: al final de la intervención "
    "regresamos a ella como el indicador a vigilar."
))

# --- 4. El hueco de medición --------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(
    s,
    "Nadie está midiendo la adopción de IA en México",
    "Discutimos el efecto laboral de una tecnología cuya penetración no "
    "medimos."
)
ancho_t = Inches(4.35)
alto_t = Inches(2.15)
x1, x2 = MARGEN, MARGEN + ancho_t + Inches(0.2)
y1, y2 = Inches(1.95), Inches(4.32)

tarjeta(s, x1, y1, ancho_t, alto_t,
        "Lo que México sí tiene",
        "Los Censos Económicos 2024 preguntan por tecnología, pero la IA "
        "viaja dentro de un rubro de «otras tecnologías» que suma 5.5 % de "
        "las unidades económicas y mezcla impresión 3D y robótica. Datos "
        "de 2023, levantados cada cinco años.")
tarjeta(s, x2, y1, ancho_t, alto_t,
        "Lo que Estados Unidos hace",
        "Su oficina del censo pregunta por uso de IA cada dos semanas. La "
        "Reserva Federal integra tres encuestas: 41 % de adopción "
        "declarada por personas trabajadoras y cerca de 18 % de empresas "
        "al cierre de 2025.",
        color_titulo=MORADO)
tarjeta(s, x1, y2, ancho_t, alto_t,
        "Lo que falta en la ENOE",
        "La mejor encuesta laboral del país no pregunta si la persona usa "
        "computadora, internet o IA en su puesto de trabajo. La brecha "
        "digital hay que imputarla desde una encuesta de hogares.",
        color_titulo=CORAL, relleno=RGBColor(0xFF, 0xEE, 0xED))
tarjeta(s, x2, y2, ancho_t, alto_t,
        "El Plan Nacional de IA",
        "Presentado por la Agencia de Transformación Digital en abril de "
        "2026, se organiza en marco ético y legal, capacidades e "
        "infraestructura. Impulsa la oferta de talento y cómputo; no mide "
        "la adopción en las empresas.")
pie_fuente(s, (
    "Fuentes: INEGI, Censos Económicos 2024; U.S. Census Bureau, BTOS; "
    "Reserva Federal (abril de 2026); ATDT, Plan Nacional de IA."
))
numero_lamina(s, 4)
notas(s, (
    "Minuto 2 a 3.\n\n"
    "Mensaje único: la ausencia del dato es en sí misma un hallazgo. No "
    "presentar cifras de adopción de consultoras: circulan sin metodología "
    "pública.\n\n"
    "Si alguien pregunta por el dato de 70 % de empresas mexicanas que ya "
    "automatizan, responder que no tiene fuente verificable."
))

# --- 5. Qué es la exposición --------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "¿Qué significa que un trabajo esté «expuesto» a la IA?")
agregar_texto(
    s,
    "Es una medida técnica que se calcula ocupación por ocupación. Se "
    "descompone cada oficio en sus tareas concretas (redactar un reporte, "
    "conciliar una cuenta, atender una llamada) y se pregunta cuántas de "
    "ellas podría ejecutar o facilitar la IA generativa con sus "
    "capacidades actuales.",
    MARGEN, Inches(1.55), ANCHO - 2 * MARGEN, Inches(1.3),
    tam=15, color=NEGRO, interlineado=1.3, espacio_post=0
)
tarjeta(s, MARGEN, Inches(3.0), Inches(4.35), Inches(1.75),
        "El puntaje describe tareas, no personas",
        "Dentro de lo «expuesto» caben dos destinos: que la tecnología "
        "sustituya la mayor parte del trabajo, o que solo absorba la parte "
        "tediosa y libere tiempo.")
tarjeta(s, MARGEN + Inches(4.55), Inches(3.0), Inches(4.35), Inches(1.75),
        "Exposición no es impacto",
        "Entre que una tarea pueda hacerse con IA y que alguien pierda su "
        "empleo median la adopción, los costos, la infraestructura y las "
        "decisiones de cada empleador.",
        color_titulo=CORAL, relleno=RGBColor(0xFF, 0xEE, 0xED))
agregar_texto(
    s,
    "«El lenguaje de programación más popular ahora es el inglés»",
    MARGEN, Inches(5.15), ANCHO - 2 * MARGEN, Inches(0.45),
    tam=16, color=MORADO, negrita=True, italica=True, interlineado=1.1,
    espacio_post=0
)
agregar_texto(
    s,
    "Andrej Karpathy lo planteó así en 2025: si ahora se programa "
    "escribiendo en lenguaje natural, las primeras ocupaciones alcanzadas "
    "son aquellas cuyo insumo y cuyo producto son texto.",
    MARGEN, Inches(5.68), ANCHO - 2 * MARGEN, Inches(0.9),
    tam=12.5, color=GRIS, interlineado=1.3, espacio_post=0
)
pie_fuente(s, (
    "Fuentes: Gmyrek et al. (2025), OIT WP140; Karpathy, «Software Is "
    "Changing (Again)», Y Combinator, junio de 2025."
))
numero_lamina(s, 5)
notas(s, (
    "Minuto 3 a 4. Es la lámina conceptual, conviene leerla despacio.\n\n"
    "La honestidad epistemológica fortalece la intervención: el índice dice "
    "dónde la tecnología ya puede hacer el trabajo, no cuántos empleos se "
    "van a perder. Lo que pase depende de decisiones humanas.\n\n"
    "La cita de Karpathy sirve para explicar por qué el trabajo "
    "administrativo aparece primero, sin necesidad de hipótesis sobre "
    "sesgos de los modelos."
))

# --- 6. La cadena metodológica ------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(
    s,
    "De dónde sale el dato",
    "Cuatro pasos entre la investigación internacional y el mercado "
    "laboral mexicano."
)
pasos = [
    ("1. El índice de la OIT",
     "Gmyrek et al. (2025) construyen el índice OIT-NASK de exposición "
     "ocupacional a la IA generativa, con más de 52 mil validaciones "
     "humanas y una correlación de 0.92 entre modelo y personas expertas."),
    ("2. Los gradientes",
     "Cada ocupación recibe un puntaje de 0 a 1 y cae en una de siete "
     "categorías, desde «no expuesto» hasta el gradiente 4, donde la IA "
     "puede ejecutar la mayoría de las tareas."),
    ("3. El puente al catálogo mexicano",
     "Se traduce de la clasificación internacional CIUO-08 al SINCO 2019 "
     "que usa la ENOE. El Monitor cubre 488 ocupaciones; 68 tienen "
     "clasificación provisional y se marcan como tal."),
    ("4. El cruce con la ENOE",
     f"Con los microdatos del {PERIODO} se calcula cuánta gente trabaja en "
     "cada ocupación, qué proporción es informal y cómo se reparte entre "
     "mujeres y hombres."),
]
y = Inches(1.95)
for i, (t, c) in enumerate(pasos):
    tarjeta(s, MARGEN, y, ANCHO - 2 * MARGEN, Inches(1.12), t, c,
            tam_titulo=12.5, tam_cuerpo=10.5, salto=0.34, pad_v=0.16,
            relleno=LILA_CLARO if i % 2 == 0 else RGBColor(0xF7, 0xF6, 0xFD))
    y += Inches(1.2)
pie_fuente(s, (
    "Fuentes: Gmyrek et al. (2025), OIT WP140; INEGI, ENOE 1T2026 y "
    "clasificación SINCO 2019."
))
numero_lamina(s, 6)
notas(s, (
    "Minuto 4 a 5. Lámina de respaldo metodológico: se puede pasar rápido "
    "y volver a ella si alguien pregunta por el método.\n\n"
    "Si hay poco tiempo, resumir en una frase: tomamos prestada una "
    "clasificación internacional, la tradujimos al catálogo mexicano y la "
    "cruzamos con la ENOE.\n\n"
    "Advertencia honesta si preguntan: las cifras usan el factor de "
    "expansión como ponderador, sin declarar el diseño muestral complejo. "
    "Los puntos estimados son válidos; los intervalos de confianza están "
    "pendientes."
))

# --- 7. El mapa general -------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "Así se ve el mercado laboral mexicano",
              "El verde marca el trabajo que la IA todavía no toca; el rojo, "
              "donde ya puede hacer la mayoría de las tareas.")
figura(s, "deck_06_treemap_total.png", y=Inches(1.88), alto_max=Inches(4.4))
pie_fuente(s, (
    "Cada rectángulo es una de las 483 ocupaciones del catálogo SINCO y su "
    "tamaño es la población ocupada. Fuente: cálculos propios con INEGI, "
    "ENOE 1T2026, e índice OIT-NASK."
))
numero_lamina(s, 7)
notas(s, (
    "Minuto 5.\n\n"
    "Dejar que la imagen hable dos segundos antes de explicar. Verde: "
    "trabajo manual y físico, construcción, campo, cocina, volante. Rojo: "
    "capturistas, auxiliares contables, secretariado, apoyo "
    "administrativo.\n\n"
    "El tamaño de cada rectángulo es la cantidad de personas que viven de "
    "esa ocupación. La versión interactiva está en el Monitor y permite "
    "explorar ocupación por ocupación."
))

# --- 8. El mapa femenino ------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "El mismo mapa, solo con el empleo de las mujeres",
              "Población ocupada femenina, 1T2026.")
figura(s, "deck_07_treemap_mujeres.png", y=Inches(1.88), alto_max=Inches(4.4))
pie_fuente(s, (
    "Fuente: cálculos propios con INEGI, ENOE 1T2026, e índice OIT-NASK "
    "(Gmyrek et al., 2025, OIT WP140)."
))
numero_lamina(s, 8)
notas(s, (
    "Minuto 5 a 6.\n\n"
    "Comparar visualmente con la lámina anterior: crecen los rectángulos "
    "naranjas y rojos. El secretariado y la recepción, que en el mapa "
    "general casi no se ven, aquí ocupan superficie.\n\n"
    "La razón no requiere hipótesis sobre sesgos: las mujeres están "
    "sobrerrepresentadas en el trabajo administrativo, y el trabajo "
    "administrativo se deja describir con texto."
))

# --- 9. El giro ---------------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "El dato que rompe la intuición",
              "Tasa de informalidad de la población ocupada, por gradiente "
              "de exposición a la IA generativa, 1T2026.")
figura(s, "deck_02_informalidad_por_gradiente.png", y=Inches(1.88),
       alto_max=Inches(4.45))
pie_fuente(s, (
    "Fuente: cálculos propios con INEGI, ENOE 1T2026, e índice OIT-NASK "
    "(Gmyrek et al., 2025, OIT WP140)."
))
numero_lamina(s, 9)
notas(s, (
    "Minuto 6 a 7. Es la lámina central de la intervención.\n\n"
    "La intuición dice que la IA vendrá por los trabajos más precarios. "
    "Los datos dicen lo contrario: entre más expuesta a la IA está una "
    "ocupación mexicana, más formal es. En el gradiente 4 apenas 16.5 % "
    "del empleo es informal, contra 66 % entre las ocupaciones no "
    "expuestas.\n\n"
    "Mencionar la excepción del gradiente 1 antes de que alguien la "
    "señale: la explica una sola ocupación, empleados de ventas y "
    "dependientes en comercios."
))

# --- 10. Respaldo: formal frente a informal -----------------------------------
s = slide_en_blanco(prs)
titulo_lamina(
    s,
    "Y en el empleo formal, ellas son las más expuestas",
    "Exposición promedio a la IA generativa, por condición laboral y sexo."
)
figura(s, "deck_03_exposicion_formal_informal.png", y=Inches(1.88),
       alto_max=Inches(4.45))
pie_fuente(s, (
    "Fuente: cálculos propios con INEGI, ENOE 1T2026, e índice OIT-NASK. "
    "Puntaje de exposición de 0 a 1, ponderado por población ocupada."
))
numero_lamina(s, 10)
notas(s, (
    "LÁMINA DE RESPALDO. Saltarla si el tiempo va justo; sirve sobre todo "
    "para responder preguntas sobre el método.\n\n"
    "Replica para México el hallazgo central del estudio conjunto de la "
    "OIT y el Banco Mundial para América Latina (Gmyrek, Winkler y "
    "Garganta, 2024): el empleo formal está más expuesto que el informal. "
    "Las mujeres con empleo formal son el grupo más expuesto de los "
    "cuatro."
))

# --- 11. La tesis -------------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "La tesis: el escalón se estrecha",
              "Porcentaje del empleo de cada sexo en los gradientes 3 y 4, "
              "1T2026.")
figura(s, "deck_04_empleo_gradientes_altos.png", y=Inches(1.85),
       alto_max=Inches(4.0))
agregar_texto(
    s,
    "1.87 millones de mujeres trabajan en las ocupaciones más expuestas. "
    "Ocho de cada diez tienen empleo formal.",
    MARGEN, Inches(5.95), ANCHO - 2 * MARGEN, Inches(0.6),
    tam=14.5, color=MORADO, negrita=True, interlineado=1.2, espacio_post=0
)
pie_fuente(s, (
    "Fuente: cálculos propios con INEGI, ENOE 1T2026, e índice OIT-NASK."
))
numero_lamina(s, 11)
notas(s, (
    "Minuto 7 a 8.\n\n"
    "Enunciado de la tesis: en México la IA generativa no amenaza "
    "principalmente al trabajo informal. Amenaza al empleo formal "
    "administrativo, urbano y feminizado, que es el principal escalón por "
    "el cual una mujer sale de la informalidad. Si ese escalón se "
    "estrecha, la consecuencia no será desempleo. Será más informalidad, y "
    "será femenina.\n\n"
    "Las mujeres son 41 de cada 100 personas ocupadas del país y 64 de "
    "cada 100 en estas ocupaciones."
))

# --- 12. Los oficios ----------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "Con nombre y apellido",
              "Porcentaje de mujeres en las siete ocupaciones más grandes "
              "de los gradientes 3 y 4, 1T2026.")
figura(s, "deck_05_ocupaciones_concretas.png", y=Inches(1.88),
       alto_max=Inches(4.45))
pie_fuente(s, (
    "Fuente: cálculos propios con INEGI, ENOE 1T2026, e índice OIT-NASK. "
    "Entre paréntesis, personas ocupadas en cada ocupación."
))
numero_lamina(s, 12)
notas(s, (
    "Minuto 8.\n\n"
    "Las abstracciones no se recuerdan, los oficios sí. En el secretariado "
    "hay 95 mujeres por cada 100 personas; en recepción, 80.\n\n"
    "Todas estas ocupaciones comparten algo: son la puerta de entrada al "
    "empleo formal urbano para mujeres con educación media superior o "
    "técnica. Ofrecen contrato, horario e IMSS."
))

# --- 13. Por qué en México pega distinto --------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(
    s,
    "En México el efecto no se verá en el desempleo",
    "Se verá en la composición del empleo."
)
tarjeta(s, MARGEN, Inches(2.0), Inches(4.35), Inches(2.3),
        "Lo que ya se observa en Estados Unidos",
        "Brynjolfsson, Chandar y Chen (2025) documentan una caída relativa "
        "de 13 % en el empleo de las personas de 22 a 25 años en las "
        "ocupaciones más expuestas, sin caída equivalente entre quienes "
        "tienen más experiencia. No hay despidos masivos: hay vacantes de "
        "entrada que dejan de publicarse.")
tarjeta(s, MARGEN + Inches(4.55), Inches(2.0), Inches(4.35), Inches(2.3),
        "Por qué aquí se traduce distinto",
        "Quien pierde el empleo formal en México pierde el IMSS y no tiene "
        "seguro de desempleo, así que no puede permitirse buscar. Se "
        "reincorpora por la vía informal: consigue algo por honorarios, "
        "ayuda en el negocio familiar, factura sin cotizar.",
        color_titulo=CORAL, relleno=RGBColor(0xFF, 0xEE, 0xED))
agregar_texto(
    s,
    "La señal temprana no está en la tasa de desocupación, que ronda el "
    "2.6 %, sino en el 12.9 % de personas ocupadas que trabajan sin "
    "seguridad social dentro de empresas formales.",
    MARGEN, Inches(4.75), ANCHO - 2 * MARGEN, Inches(1.1),
    tam=14.5, color=NEGRO, interlineado=1.35, espacio_post=0
)
agregar_texto(
    s,
    "Ese indicador ya se mide cada trimestre. No hay que inventarlo ni "
    "comprarlo.",
    MARGEN, Inches(5.85), ANCHO - 2 * MARGEN, Inches(0.5),
    tam=14.5, color=MORADO, negrita=True, interlineado=1.2, espacio_post=0
)
pie_fuente(s, (
    "Fuentes: Brynjolfsson, Chandar y Chen (2025), Stanford Digital "
    "Economy Lab; INEGI, ENOE 1T2026."
))
numero_lamina(s, 13)
notas(s, (
    "Minuto 8 a 9.\n\n"
    "Aclarar el estatus de la afirmación: que la IA produzca ese "
    "desplazamiento concreto en México es un supuesto de trabajo, no un "
    "hallazgo medido. Nadie lo ha estimado porque la serie de adopción "
    "apenas empieza. Presentarlo como hipótesis fortalece la "
    "intervención.\n\n"
    "El estudio de Stanford usa datos de nómina, es decir, empleo "
    "registrado. En México ese universo abarca menos de la mitad de la "
    "población ocupada: cualquier estudio así es ciego a la otra mitad."
))

# --- 14. Qué hacer ------------------------------------------------------------
s = slide_en_blanco(prs)
titulo_lamina(s, "Cuatro cosas que sí se pueden hacer")
acciones = [
    ("Medir",
     "Incorporar a la ENOE un módulo corto sobre uso de tecnología e IA en "
     "el puesto de trabajo. Estados Unidos lo hace cada dos semanas; aquí "
     "bastaría cada trimestre."),
    ("Focalizar la capacitación",
     "La oferta pública existe y es gratuita, pero apunta a estudiantes de "
     "ingeniería y tecnologías de la información. Las mujeres del "
     "secretariado y la recepción no son ese público."),
    ("Pagar el tiempo, no solo el curso",
     "Singapur acompaña la capacitación con una asignación que sustituye "
     "el ingreso. Suecia financia consejos de transición con 0.3 % de la "
     "nómina y entra antes del despido, no después."),
    ("Vigilar el indicador correcto",
     "La proporción de empleo informal dentro del sector formal se mueve "
     "antes que la tasa de desempleo. La ENOE ya la publica cada "
     "trimestre."),
]
y = Inches(1.7)
colores_num = [MORADO, MORADO, MORADO, CORAL]
for i, (t, c) in enumerate(acciones):
    tarjeta(s, MARGEN, y, ANCHO - 2 * MARGEN, Inches(1.18),
            f"{i + 1}.  {t}", c, color_titulo=colores_num[i],
            tam_titulo=13, tam_cuerpo=11, salto=0.36, pad_v=0.17,
            relleno=LILA_CLARO if i < 3 else RGBColor(0xFF, 0xEE, 0xED))
    y += Inches(1.28)
pie_fuente(s, (
    "Fuentes: ATDT y STPS (oferta de formación); Ministerio de Educación "
    "de Singapur (2025); consejos de transición suecos (TUAC, OCDE)."
))
numero_lamina(s, 14)
notas(s, (
    "Minuto 9 a 10.\n\n"
    "Tono descriptivo, no prescriptivo. No se trata de decirle al foro qué "
    "hacer, sino de señalar dónde están las palancas.\n\n"
    "Dato de apoyo por si hay preguntas: la Ley Federal del Trabajo ya "
    "obliga a capacitar y ordena constituir comisiones mixtas de "
    "capacitación y adiestramiento en cada empresa. Existen en papel en "
    "miles de centros de trabajo y hoy no discuten automatización."
))

# --- 15. Cierre ---------------------------------------------------------------
s = slide_en_blanco(prs, fondo=MORADO)
agregar_texto(
    s,
    "La pregunta no es si la IA\nva a llegar al mercado\nlaboral mexicano.",
    MARGEN, Inches(1.7), ANCHO - 2 * MARGEN, Inches(2.2),
    tam=30, color=BLANCO, negrita=True, interlineado=1.15, espacio_post=0
)
agregar_texto(
    s,
    "Es si vamos a estar mirando el indicador\ncorrecto cuando llegue.",
    MARGEN, Inches(4.0), ANCHO - 2 * MARGEN, Inches(1.4),
    tam=26, color=RGBColor(0xE8, 0xE3, 0xFA), italica=True,
    interlineado=1.2, espacio_post=0
)
agregar_texto(
    s,
    "Monitor de exposición del trabajo de las mujeres a la IA\n"
    "juvenal@mexicocomovamos.mx",
    MARGEN, Inches(6.0), ANCHO - 2 * MARGEN, Inches(1.0),
    tam=12, color=BLANCO, interlineado=1.35, espacio_post=0
)
notas(s, (
    "Minuto 10. Cierre.\n\n"
    "Dejar la lámina puesta durante las preguntas.\n\n"
    "[PENDIENTE: confirmar si conviene incluir la liga pública del Monitor "
    "y el correo de contacto que prefieras.]"
))

# --- Guardado -----------------------------------------------------------------
SALIDA.parent.mkdir(parents=True, exist_ok=True)
prs.save(str(SALIDA))
print(f"Presentación guardada: {SALIDA}")
print(f"Diapositivas: {len(prs.slides.__iter__.__self__._sldIdLst)}")
