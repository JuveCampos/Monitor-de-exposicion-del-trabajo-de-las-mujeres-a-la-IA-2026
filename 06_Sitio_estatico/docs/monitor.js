// Interacción del treemap en la versión estática del Monitor.
//
// Sustituye al server de Shiny en lo único que dependía de él:
//   - los selectores de población y sector cambian el treemap con
//     Plotly.react() usando las variantes precalculadas en R
//     (datos/treemap/<sexo>_<sector>.js);
//   - el clic en una ocupación muestra el panel con su descripción y la
//     tabla de tareas, ya renderizados en R (datos/paneles/<sinco4d>.js).
// Los archivos de datos se cargan con etiquetas <script> al momento de
// usarse, así la página arranca ligera y funciona también abierta desde
// el disco (file://), donde fetch() no está disponible.
(function () {
  var grafica = document.getElementById('treemap');
  var selectorSexo = document.getElementById('sexo');
  var selectorSector = document.getElementById('sector');
  var panel = document.getElementById('panel_descripcion_ia');
  var subtitulo = document.querySelector('#treemap_titulo .chart-subtitle');

  if (!grafica || !selectorSexo || !selectorSector || !panel) {
    return;
  }

  window.TREEMAP_VARIANTES = window.TREEMAP_VARIANTES || {};
  window.PANELES = window.PANELES || {};

  // Carga un archivo de datos una sola vez y llama a listo() al terminar.
  var cargados = {};
  function cargarScript(url, listo) {
    if (cargados[url] === 'listo') {
      listo();
      return;
    }
    if (cargados[url] === 'cargando') {
      return;
    }
    cargados[url] = 'cargando';
    var etiqueta = document.createElement('script');
    etiqueta.src = url;
    etiqueta.onload = function () {
      cargados[url] = 'listo';
      listo();
    };
    etiqueta.onerror = function () {
      delete cargados[url];
    };
    document.head.appendChild(etiqueta);
  }

  function limpiarPanel() {
    panel.innerHTML = '';
  }

  function mostrarPanel(codigo) {
    var pintar = function () {
      panel.innerHTML = window.PANELES[codigo] || '';
    };
    if (window.PANELES[codigo]) {
      pintar();
    } else {
      cargarScript('datos/paneles/' + codigo + '.js', pintar);
    }
  }

  // Evita que una respuesta tardía pise una selección más reciente.
  var claveActual = selectorSexo.value + '|' + selectorSector.value;

  function pintarTreemap(clave) {
    var variante = window.TREEMAP_VARIANTES[clave];
    if (!variante || clave !== claveActual) {
      return;
    }
    if (subtitulo) {
      subtitulo.textContent = variante.subtitulo;
    }
    Plotly.react(grafica, variante.x.data, variante.x.layout,
      variante.x.config);
  }

  function actualizarTreemap() {
    var clave = selectorSexo.value + '|' + selectorSector.value;
    claveActual = clave;
    limpiarPanel();
    if (window.TREEMAP_VARIANTES[clave]) {
      pintarTreemap(clave);
    } else {
      cargarScript(
        'datos/treemap/' + clave.replace('|', '_') + '.js',
        function () { pintarTreemap(clave); }
      );
    }
  }

  function conectarClic() {
    grafica.on('plotly_click', function (evento) {
      var punto = evento.points && evento.points[0];
      var codigo = punto ? punto.customdata : null;
      if (codigo !== null && codigo !== undefined && codigo !== '') {
        mostrarPanel(String(codigo));
      }
    });
  }

  // htmlwidgets dibuja las gráficas al cargar la página; el manejador de
  // clic se conecta cuando el treemap ya existe.
  function esperarTreemap() {
    if (typeof grafica.on === 'function' && grafica._fullLayout) {
      conectarClic();
    } else {
      setTimeout(esperarTreemap, 100);
    }
  }

  selectorSexo.addEventListener('change', actualizarTreemap);
  selectorSector.addEventListener('change', actualizarTreemap);
  esperarTreemap();
})();
