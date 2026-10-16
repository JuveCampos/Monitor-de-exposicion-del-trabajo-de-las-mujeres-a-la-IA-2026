# Críticas a los estudios de exposición ocupacional a la IA y cómo abordarlas en el Monitor

Documento de trabajo. 16 de octubre de 2026.
Monitor de Exposición del Trabajo de las Mujeres a la IA 2026 (Clave Igualdad / México, ¿cómo vamos?).

## 1. Propósito

Este documento reúne las críticas más frecuentes que la literatura económica ha hecho a los estudios de exposición ocupacional a la inteligencia artificial, evalúa cuáles aplican al Monitor y propone cómo responderlas. Se escribió pensando en dos usos: preparar las preguntas que puede recibir la presentación del Monitor y definir mejoras metodológicas para las siguientes versiones.

El Monitor hereda la lógica de los índices de la Organización Internacional del Trabajo (OIT): toma las puntuaciones de exposición por tarea y ocupación de Gmyrek et al. (2025), las traslada a la clasificación mexicana de ocupaciones (SINCO 2019) y las cruza con la Encuesta Nacional de Ocupación y Empleo (ENOE) para describir cuántas personas, y sobre todo cuántas mujeres, trabajan en ocupaciones con distinto grado de exposición. Por eso casi todas las críticas que se hacen a la familia de estudios de exposición aplican también al Monitor, aunque algunas ya están atendidas.

## 2. De dónde vienen estos estudios

Conviene situar al Monitor en la genealogía de la literatura, porque buena parte de las críticas se dirigen a los primeros trabajos y no a los más recientes.

- **Primera generación, nivel ocupación.** Frey y Osborne (2017) clasificaron 702 ocupaciones de Estados Unidos según su "probabilidad de computarización" y concluyeron que 47% del empleo estaba en alto riesgo. La cifra se volvió titular y concentró la mayoría de las críticas posteriores.
- **Corrección por tareas.** Arntz, Gregory y Zierahn (2016) mostraron que, si se mira la variedad de tareas dentro de cada ocupación en lugar de la ocupación completa, el empleo en alto riesgo en la OCDE baja a cerca de 9%. Desde entonces el estándar es trabajar a nivel de tarea.
- **Medidas específicas de IA.** Webb (2020) midió exposición a partir del traslape entre el texto de patentes de IA y las descripciones de tareas; Felten, Raj y Seamans (2021) construyeron el índice AIOE a partir de capacidades de la IA y habilidades de O\*NET; Eloundou, Manning, Mishkin y Rock (2023) calificaron tareas de O\*NET con expertos y con GPT-4 y estimaron que cerca de 80% de la fuerza laboral estadounidense tiene al menos 10% de sus tareas expuestas a los modelos de lenguaje.
- **Índices globales de la OIT.** Gmyrek, Berg y Bescond (2023) trasladaron el enfoque a la clasificación internacional CIUO-08 para producir estimaciones globales; Gmyrek, Winkler y Garganta (2024) lo aplicaron a América Latina ajustando por acceso digital; Gmyrek et al. (2025) refinaron el índice con una encuesta a 1,640 personas ocupadas en Polonia, una revisión de expertos y los cuatro gradientes de exposición que usa el Monitor.
- **Medidas con uso observado.** Desde 2025, Anthropic publica un índice económico que compara la exposición teórica de las tareas con el uso real de su modelo, y encuentra que el uso efectivo cubre una fracción mucho menor de las tareas que la capacidad teórica (Anthropic, 2025).

## 3. Críticas principales y cómo abordarlas

Cada crítica se presenta con su origen, el grado en que aplica al Monitor y la respuesta propuesta. Las respuestas se clasifican en tres niveles: ya atendida, atendible con los datos actuales y fuera del alcance de esta edición.

### 3.1. Exposición no es desplazamiento

**La crítica.** Los índices miden la fracción de tareas que la tecnología podría realizar, no cuántos empleos desaparecerán. Que una tarea sea técnicamente automatizable no implica que sea rentable automatizarla: Svanberg, Li, Fleming, Goehring y Thompson (2024) estiman que, en visión por computadora, solo cerca de una cuarta parte de los salarios expuestos sería rentable de automatizar a los costos actuales. Acemoglu (2024) calcula que, incluso aceptando las estimaciones de exposición, la ganancia de productividad agregada en diez años sería menor a 0.7%, porque la mayoría de las tareas expuestas son una parte pequeña del valor que produce cada ocupación. Además, los estudios de exposición no modelan la demanda: la tecnología crea tareas nuevas (Autor, Chin, Salomons y Seegmiller, 2024, documentan que la mayoría del empleo actual está en ocupaciones que no existían en 1940) y las empresas que adoptan IA pueden crecer y contratar (Hampole, Papanikolaou, Schmidt y Seegmiller, 2025). El Fondo Monetario Internacional distingue por eso entre exposición y complementariedad: una ocupación muy expuesta puede salir beneficiada si la IA complementa el juicio humano en lugar de sustituirlo (Cazzaniga et al., 2024).

**Aplicación al Monitor.** Aplica por completo. Los propios autores del índice lo advierten: la exposición "no implica la automatización inmediata de una ocupación completa" (Gmyrek et al., 2025, p. 39). El Monitor ya usa el lenguaje de "exposición" y no de "pérdida de empleo", y la etiqueta de cada gradiente distingue entre alta y baja variabilidad de tareas, que es la forma en que el índice separa el riesgo de sustitución del potencial de complemento.

**Cómo abordarla.**

- Ya atendida: la nota metodológica y los textos de la app hablan de exposición potencial y no de empleos perdidos.
- Atendible ahora: añadir a la app y a la presentación una advertencia explícita y corta, del tipo "este Monitor mide qué tanto de las tareas de cada ocupación podría hacer la IA generativa hoy; no mide cuántos empleos desaparecerán ni cuándo". Conviene también explicar en una frase la diferencia entre el gradiente de exposición máxima con baja variabilidad de tareas (riesgo de sustitución) y los gradientes con alta variabilidad (más probable transformación que sustitución).
- Fuera de alcance: modelar la adopción y la rentabilidad por ocupación en México. Se puede dejar planteado como línea futura usando la Encuesta Mensual de Actividad Económica Regional (EMAER) de Banco de México, que desde 2026 pregunta a las empresas sobre uso de IA, como medida de adopción del lado de la demanda.

### 3.2. La evidencia empírica muestra efectos pequeños o concentrados

**La crítica.** Los estudios que siguen a trabajadores reales después de la llegada de los modelos de lenguaje no encuentran, por ahora, los efectos que las medidas de exposición sugerirían. Humlum y Vestergaard (2025) vinculan encuestas de adopción con registros administrativos de Dinamarca para 25,000 trabajadores en 11 ocupaciones expuestas y no encuentran efectos sobre ingresos ni horas, con ahorros de tiempo promedio de 3%. El Budget Lab de Yale (Gimbel, Kinder, Kendall y Lee, 2025) no detecta cambios en la composición ocupacional ni en el desempleo de las ocupaciones expuestas en Estados Unidos que se distingan de transiciones tecnológicas previas. La excepción es la contratación de jóvenes: Brynjolfsson, Chandar y Chen (2025) encuentran, con registros de nómina, que el empleo de personas de 22 a 25 años en las ocupaciones más expuestas cayó de forma relativa, sin un efecto comparable en trabajadores con experiencia. Sobre predicciones anteriores, Coelli y Borland (2019) mostraron que las de Frey y Osborne no ayudaron a predecir los cambios de empleo observados entre 2013 y 2018.

**Aplicación al Monitor.** Aplica, con un matiz: el Monitor no predice, describe una estructura ocupacional. Pero quien lo lea puede interpretar 7.9% de mujeres en exposición significativa o máxima como una proyección de desempleo.

**Cómo abordarla.**

- Atendible ahora: incorporar una sección breve de "qué dice la evidencia hasta hoy" en la nota metodológica y en la presentación, con los tres hallazgos clave (efectos agregados pequeños, concentración en contratación de jóvenes, adopción desigual). Esto blinda al Monitor frente a la crítica de alarmismo y, al mismo tiempo, justifica su enfoque en una población específica.
- Atendible ahora: el hallazgo sobre jóvenes sugiere un corte adicional para el Monitor. La ENOE permite calcular la exposición de las mujeres de 20 a 29 años y compararla con el resto; el procesamiento ya guarda edad promedio por ocupación y se puede agregar un corte por grupo de edad en el script de procesamiento.
- Línea futura: cuando haya varios trimestres con la misma metodología, seguir en el tiempo la ocupación de mujeres jóvenes en las ocupaciones expuestas. Es la forma más directa de pasar de exposición a evidencia.

### 3.3. Validez de la medida: quién califica las tareas y con qué criterio

**La crítica.** Las puntuaciones de exposición dependen de juicios subjetivos: de expertos (Frey y Osborne; Lassébie y Quintini, 2022), de un modelo de lenguaje que evalúa su propia capacidad (Eloundou et al., 2023) o de encuestas a trabajadores (Gmyrek et al., 2025). Los índices construidos con criterios distintos no siempre coinciden entre sí, en especial los basados en patentes frente a los basados en capacidades. En el caso de la OIT, los autores reconocen que en 91.5% de las tareas las personas encuestadas no realizaban una tarea similar en su propio trabajo, que los gerentes y profesionistas conocen mejor la IA que los trabajadores elementales, y que las discrepancias entre encuestados y expertos se resolvieron manualmente (Gmyrek et al., 2025, pp. 18-19).

**Aplicación al Monitor.** Aplica de manera indirecta: el Monitor no genera puntuaciones, las toma del índice de la OIT. La decisión relevante es haber elegido ese índice y no otro.

**Cómo abordarla.**

- Ya atendida en parte: la nota metodológica explica el origen de las puntuaciones y la encuesta en que se basan.
- Atendible ahora: justificar explícitamente la elección del índice de la OIT frente a las alternativas: está construido sobre CIUO-08 y no sobre O\*NET, lo que reduce los supuestos de traslado a México; es el único con estimaciones regionales para América Latina; y distingue variabilidad de tareas. Esta justificación cabe en un párrafo de la nota metodológica.
- Línea futura: una prueba de robustez con un segundo índice (por ejemplo, el de Eloundou et al. trasladado vía O\*NET-CIUO) mostraría si el ordenamiento de las ocupaciones mexicanas cambia según la medida. Es un ejercicio laborioso por la doble correspondencia y se propone solo para la versión anual.

### 3.4. Agregación: ocupaciones, tareas y heterogeneidad interna

**La crítica.** Una ocupación agrupa tareas muy distintas y personas que las combinan de forma diferente. Arntz et al. (2016) mostraron que ignorar esa variedad infla las cifras de riesgo. El índice de la OIT asigna el mismo peso a todas las tareas de una ocupación porque CIUO-08 no registra la frecuencia ni la importancia de cada una (Gmyrek et al., 2025, p. 38, nota 18). En el Monitor el problema se agrava cuando una ocupación SINCO corresponde a varias CIUO: el promedio sin ponderar puede dar un valor intermedio que no describe a nadie.

**Aplicación al Monitor.** Aplica y es la crítica más específica a nuestro procedimiento. De las 488 ocupaciones del catálogo, 136 corresponden a varias CIUO y 56 quedan etiquetadas como "Mixto" (18% de las personas ocupadas). El anexo de sensibilidad muestra que la regla elegida para esos casos mueve el indicador principal: las mujeres en exposición significativa o máxima pasan de 7.9% con la regla actual a 9.9% con la unión de tareas y a 12.4% si se toma solo la primera CIUO de cada correspondencia.

**Cómo abordarla.**

- Ya atendida: el anexo `sensibilidad_mixto_2026T2.md` documenta el rango y la etiqueta "Mixto" se explica como marca de heterogeneidad y no como nivel de exposición.
- Atendible ahora: adoptar la regla de unión de tareas con los umbrales de la Tabla 5 del índice (la regla R2 del anexo), que reproduce 423 de las 427 categorías de la OIT y evita el promedio entre ocupaciones distintas. Reportar siempre el indicador principal con su rango de sensibilidad (7.9% a 12.4%), de modo que la cifra no se lea como exacta.
- Línea futura: ponderar las CIUO de cada correspondencia por su peso en el empleo mexicano, lo que requeriría una fuente externa de distribución de tareas; no existe para México.

### 3.5. Sesgo de contexto: las tareas se definieron en otros países

**La crítica.** La mayoría de los índices se construyen sobre O\*NET, que describe las ocupaciones de Estados Unidos, y luego se trasladan a otros países bajo el supuesto de que la misma ocupación hace las mismas tareas con la misma tecnología. Los autores de la OIT advierten que ese traslado "implica supuestos endebles sobre la similitud de ocupaciones detalladas en el contexto tecnológicamente avanzado de Estados Unidos con otros países" (Gmyrek et al., 2025, p. 39) y que, en su propio método, "la misma ocupación en distintos países usa la misma puntuación", de modo que toda la variación entre países proviene de la estructura ocupacional (Gmyrek, Winkler y Garganta, 2024, p. 15). En América Latina la brecha digital y la informalidad reducen tanto el riesgo de sustitución como el potencial de complemento: cerca de la mitad de los empleos que podrían beneficiarse de la IA no tienen acceso a las herramientas digitales necesarias.

**Aplicación al Monitor.** Aplica en dos sentidos. Primero, las puntuaciones de la OIT se construyeron con una encuesta en Polonia y la revisión de expertos de la OIT, no con tareas mexicanas. Segundo, el Monitor no ajusta las puntuaciones por acceso digital, informalidad o uso de computadora en el trabajo.

**Cómo abordarla.**

- Ya atendida en parte: la sección de brecha tecnológica usa la ENDUTIH para mostrar que la brecha de acceso entre hombres y mujeres es pequeña en internet (1.0 pp) y celular (0.3 pp) pero que el tipo de uso difiere, y la app reporta la tasa de informalidad por gradiente de exposición.
- Atendible ahora: replicar el ajuste de Gmyrek, Winkler y Garganta (2024) con datos mexicanos. La ENDUTIH pregunta si la persona usa computadora e internet en el trabajo; la ENOE registra informalidad por ocupación. Con ambas se puede construir una versión "ajustada por acceso" del indicador principal, al menos para las ocupaciones de exposición alta, y presentarla junto a la versión sin ajuste. Es el ejercicio con mejor relación entre esfuerzo y credibilidad que queda pendiente.
- Atendible ahora: incorporar en la lectura de resultados que la informalidad actúa como amortiguador y como trampa a la vez. Gmyrek, Winkler y Garganta (2024) señalan que los trabajadores formales están más expuestos y que, si la automatización erosiona el empleo formal, el resultado sería más informalidad y no desempleo. Esa lectura es directamente relevante para México y para las mujeres.

### 3.6. Correspondencias entre clasificaciones

**La crítica.** Cada traslado entre clasificaciones (O\*NET a CIUO, CIUO a SINCO) introduce error. Las tablas comparativas oficiales no son uno a uno, y las ocupaciones sin correspondencia obligan a decisiones manuales.

**Aplicación al Monitor.** Aplica. La correspondencia SINCO-CIUO que usamos es la tabla del INEGI para SINCO 2011 aplicada a SINCO 2019; 35 ocupaciones heredan la puntuación del grupo de tres dígitos, 68 son provisionales (28 por asignación manual y 40 por imputación modal), 10 quedan sin clasificar y el bloque 2412-2428 está en revisión.

**Cómo abordarla.**

- Ya atendida: la nota metodológica declara cada regla y el catálogo lleva una columna con el método de asignación de cada ocupación; la cadena de construcción es reproducible desde los scripts.
- Atendible ahora: reportar el indicador principal con y sin las ocupaciones provisionales, para mostrar que no dependen de las decisiones manuales. Es un cálculo que ya hacen los scripts de sensibilidad y solo falta exponerlo.
- Pendiente de decisión: validar la reasignación del bloque 2412-2428 con la tabla de equivalencias SINCO 2011-2019 del INEGI.

### 3.7. Lectura de género: expuesto no es lo mismo que perjudicado, y no expuesto no es lo mismo que protegido

**La crítica.** Un Monitor centrado en mujeres puede leerse como "las mujeres van a perder el empleo", cuando la mayor exposición femenina proviene de la segregación ocupacional (el peso del trabajo de oficina y administrativo) y buena parte de esa exposición es de complemento, no de sustitución. Gmyrek, Berg y Bescond (2023) muestran que el potencial de complemento es varias veces mayor que el de automatización incluso en las ocupaciones feminizadas. Del otro lado, las ocupaciones "no expuestas" en que se concentran muchas mujeres (cuidados, limpieza, comercio informal) no están protegidas: son empleos de bajo ingreso y alta informalidad donde la IA no llega, y la falta de exposición puede significar quedar fuera de las ganancias de productividad (Gmyrek, Winkler y Garganta, 2024).

**Aplicación al Monitor.** Aplica y es la crítica que más conviene anticipar en la presentación, porque toca el mensaje central.

**Cómo abordarla.**

- Ya atendida en parte: la subsección de cuidados muestra que esas ocupaciones tienen exposición baja o mixta y que eso no las hace deseables; la app reporta ingreso, informalidad y escolaridad por gradiente, lo que permite ver que las ocupaciones expuestas son, en promedio, las de mejor calidad.
- Atendible ahora: formular el mensaje principal en dos partes que vayan siempre juntas: "las mujeres están sobrerrepresentadas en las ocupaciones más expuestas, que son también las de mayor ingreso y formalidad, y subrepresentadas en los puestos que diseñan la tecnología". La segunda parte ya tiene sustento en el bloque STEM (25.8% de mujeres entre quienes tienen formación STEM, y 18.4% de ellas en ocupaciones de exposición alta frente a 5.2% de los hombres).
- Atendible ahora: separar en la app el gradiente de "exposición máxima, baja variabilidad" del resto al presentar la cifra de mujeres, porque es el único que el índice asocia con sustitución. Para 2026-T2 eso cambia la cifra de 7.9% a la fracción que corresponde solo a ese gradiente, y evita que toda la exposición se lea como riesgo.
- Fuera de alcance: medir el efecto de la IA sobre la carga de trabajo no remunerado y los cuidados, que es donde la literatura reciente sitúa la pregunta de género más importante.

### 3.8. Temporalidad: la medida describe la tecnología de un momento

**La crítica.** Las puntuaciones reflejan lo que los modelos podían hacer cuando se levantó la encuesta (2024-2025). Las capacidades cambian rápido y los índices envejecen; además, la capacidad de frontera no es la capacidad desplegada en los lugares de trabajo. Anthropic (2025) estima que el uso real cubre una fracción mucho menor de las tareas que la capacidad teórica, y Bick, Blandin y Deming (2024) documentan que, aun con adopción rápida en Estados Unidos, cerca de uno de cada cuatro trabajadores usaba IA generativa para su trabajo en una semana típica.

**Aplicación al Monitor.** Aplica. El Monitor actualiza la ENOE cada trimestre, pero las puntuaciones de exposición son fijas (las de 2025).

**Cómo abordarla.**

- Atendible ahora: fechar las puntuaciones en la app ("índice de exposición: OIT 2025; empleo: ENOE 2026-T2") y explicar que los cambios trimestrales reflejan cambios en la estructura del empleo, no en la tecnología.
- Línea futura: cuando la OIT publique una nueva versión del índice, recalcular la serie completa con ambas versiones para separar los dos efectos.

### 3.9. Comunicación: las cifras globales se leen mal

**La crítica.** Los titulares de esta literatura (47% de los empleos, 40% de los trabajadores, 80% de la fuerza laboral) se interpretan como proporciones de empleos que desaparecerán, y cada estudio mide algo distinto. Esto ha desgastado la credibilidad del campo entero.

**Aplicación al Monitor.** Aplica porque el Monitor produce su propio titular (7.9% de las mujeres frente a 2.9% de los hombres).

**Cómo abordarla.**

- Atendible ahora: acompañar siempre la cifra de tres elementos: qué mide (fracción de tareas que la IA podría hacer), con qué rango (7.9% a 12.4% según la regla de agregación) y qué no dice (no es una proyección de desempleo). Añadir a la app una tarjeta fija de "lo que este Monitor no mide".
- Atendible ahora: usar valores absolutos junto a porcentajes (1.96 millones de mujeres) para que la magnitud se entienda sin inflarla.

## 4. Resumen

| Crítica | ¿Aplica al Monitor? | Estado | Acción propuesta | Esfuerzo |
|---|---|---|---|---|
| 3.1 Exposición no es desplazamiento | Sí | Parcial | Advertencia explícita en app y presentación; explicar gradientes | Bajo |
| 3.2 Evidencia empírica de efectos pequeños | Sí | No | Sección "qué dice la evidencia"; corte por edad (mujeres jóvenes) | Bajo / Medio |
| 3.3 Validez de las puntuaciones | Indirecta | Parcial | Justificar la elección del índice OIT; robustez con segundo índice (futuro) | Bajo / Alto |
| 3.4 Agregación y "Mixto" | Sí | Documentada | Adoptar regla R2; reportar rango 7.9%-12.4% | Bajo (decisión) |
| 3.5 Sesgo de contexto y brecha digital | Sí | Parcial | Indicador ajustado por acceso digital e informalidad (ENDUTIH + ENOE) | Medio |
| 3.6 Correspondencias | Sí | Documentada | Indicador con y sin provisionales; validar bloque 2412-2428 | Bajo |
| 3.7 Lectura de género | Sí | Parcial | Mensaje en dos partes; separar gradiente de sustitución; cuidados como no protegidos | Bajo |
| 3.8 Temporalidad | Sí | No | Fechar el índice en la app | Bajo |
| 3.9 Comunicación de cifras | Sí | No | Tarjeta "lo que este Monitor no mide"; cifra con rango y absolutos | Bajo |

## 5. Orden sugerido

Antes de la presentación conviene tener lista la respuesta verbal a 3.1, 3.2 y 3.7, que son las preguntas más probables del público: qué mide la exposición, qué muestra la evidencia hasta hoy y por qué estar expuesta no es lo mismo que estar en riesgo. No requieren cambios en la app.

Para la siguiente versión, en orden de esfuerzo: fechar el índice y añadir la tarjeta de "lo que no mide" (3.8 y 3.9); adoptar la regla R2 y reportar el rango (3.4); exponer el indicador con y sin provisionales (3.6); añadir el corte por edad (3.2); y construir el indicador ajustado por acceso digital (3.5), que es el que más acercaría al Monitor a la metodología regional de la OIT y el Banco Mundial.

## Referencias

Acemoglu, D. (2024). *The simple macroeconomics of AI* (NBER Working Paper No. 32487). National Bureau of Economic Research. https://www.nber.org/papers/w32487

Anthropic. (2025). *The Anthropic Economic Index: Insights from Claude 3.7 Sonnet*. https://www.anthropic.com/news/anthropic-economic-index-insights-from-claude-sonnet-3-7

Arntz, M., Gregory, T., & Zierahn, U. (2016). *The risk of automation for jobs in OECD countries: A comparative analysis* (OECD Social, Employment and Migration Working Papers No. 189). OECD Publishing. https://doi.org/10.1787/5jlz9h56dvq7-en

Autor, D., Chin, C., Salomons, A., & Seegmiller, B. (2024). New frontiers: The origins and content of new work, 1940-2018. *The Quarterly Journal of Economics, 139*(3), 1399-1465.

Bick, A., Blandin, A., & Deming, D. J. (2024). *The rapid adoption of generative AI* (NBER Working Paper No. 32966). National Bureau of Economic Research. https://www.nber.org/papers/w32966

Brynjolfsson, E., Chandar, B., & Chen, R. (2025). *Canaries in the coal mine? Six facts about the recent employment effects of artificial intelligence*. Stanford Digital Economy Lab. https://digitaleconomy.stanford.edu/publication/canaries-in-the-coal-mine-six-facts-about-the-recen

Cazzaniga, M., Jaumotte, F., Li, L., Melina, G., Panton, A. J., Pizzinelli, C., Rockall, E., & Tavares, M. M. (2024). *Gen-AI: Artificial intelligence and the future of work* (IMF Staff Discussion Note SDN/2024/001). International Monetary Fund.

Coelli, M., & Borland, J. (2019). *Behind the headline number: Why not to rely on Frey and Osborne's predictions of potential job loss from automation* (Melbourne Institute Working Paper No. 10/19). University of Melbourne. https://melbourneinstitute.unimelb.edu.au/__data/assets/pdf_file/0005/3197111/wp2019n10.pdf

Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2023). *GPTs are GPTs: An early look at the labor market impact potential of large language models* (arXiv:2303.10130). https://arxiv.org/abs/2303.10130

Felten, E., Raj, M., & Seamans, R. (2021). Occupational, industry, and geographic exposure to artificial intelligence: A novel dataset and its potential uses. *Strategic Management Journal, 42*(12), 2195-2217. https://doi.org/10.1002/smj.3286

Frey, C. B., & Osborne, M. A. (2017). The future of employment: How susceptible are jobs to computerisation? *Technological Forecasting and Social Change, 114*, 254-280.

Gimbel, M., Kinder, M., Kendall, J., & Lee, M. (2025). *Evaluating the impact of AI on the labor market: Current state of affairs*. The Budget Lab at Yale.

Gmyrek, P., Berg, J., & Bescond, D. (2023). *Generative AI and jobs: A global analysis of potential effects on job quantity and quality* (ILO Working Paper No. 96). International Labour Organization. https://doi.org/10.54394/FHEM8239

Gmyrek, P., Winkler, H., & Garganta, S. (2024). *Buffer or bottleneck? Employment exposure to generative AI and the digital divide in Latin America* (ILO Working Paper No. 121; World Bank Policy Research Working Paper No. 10863). International Labour Organization and World Bank.

Gmyrek, P., Berg, J., Kamiński, K., Konopczyński, F., Ładna, A., Nafradi, B., Rosłaniec, K., & Troszyński, M. (2025). *Generative AI and jobs: A refined global index of occupational exposure* (ILO Working Paper No. 140). International Labour Organization.

Hampole, M., Papanikolaou, D., Schmidt, L., & Seegmiller, B. (2025). *Artificial intelligence and the labor market* (NBER Working Paper No. 33509). National Bureau of Economic Research. https://doi.org/10.3386/w33509

Humlum, A., & Vestergaard, E. (2025). *Large language models, small labor market effects* (NBER Working Paper No. 33777; BFI Working Paper No. 2025-56). National Bureau of Economic Research.

Lassébie, J., & Quintini, G. (2022). *What skills and abilities can automation technologies replicate and what does it mean for workers? New evidence* (OECD Social, Employment and Migration Working Papers No. 282). OECD Publishing. https://doi.org/10.1787/646aad77-en

Svanberg, M., Li, W., Fleming, M., Goehring, B., & Thompson, N. (2024). *Beyond AI exposure: Which tasks are cost-effective to automate with computer vision?* SSRN. MIT FutureTech.

Webb, M. (2020). *The impact of artificial intelligence on the labor market*. SSRN. https://papers.ssrn.com/abstract=3482150

## Nota sobre las fuentes

Todas las referencias se verificaron en línea el 16 de octubre de 2026 contra el repositorio del autor o de la institución que las publica. Dos precisiones: el artículo de Eloundou et al. se cita en su versión de arXiv (2023), que es la verificada, aunque existe una versión posterior en *Science* (2024); y las cifras de Brynjolfsson et al. cambian entre versiones del documento (13% en agosto de 2025, 16% en noviembre de 2025 y 19% en agosto de 2026), por lo que el texto evita citar un número y describe el hallazgo. La página de los autores del índice de la OIT que se cita en 3.1 y 3.5 corresponde al PDF del documento de trabajo 140 guardado en `01_Datos/01_catalogos/papers/`.
