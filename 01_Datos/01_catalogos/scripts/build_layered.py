#!/usr/bin/env python3
"""
Construye la versión final de sinco_con_exposicion_ia.csv aplicando:
- Capa 1: etiqueta `estado_score` para casos no imputables (militares, ENOE,
  no especificadas, CIUO sin score Gmyrek).
- Capa 2: imputación por promedio del subgrupo 3d para residuales y
  supervisores SINCO. Marca columnas `score_imputado` y `metodo_score`.

Por separado, escribe `mapeo_manual_propuesto.csv` con propuestas de CIUO-08
para los grupos unitarios específicos sin correspondencia en el crosswalk
INEGI 2012, para que el usuario las audite antes de incorporarlas.
"""
import csv
from collections import defaultdict
from statistics import mean

BASE = '/Users/jorgejuvenalcamposferreira/Documents/Claude Encargos/36-dataton-genero/05_Tareas/01_catalogos'

# ---------- Cargar tabla maestra actual y scores Gmyrek ----------
rows = list(csv.DictReader(open(f'{BASE}/sinco_con_exposicion_ia.csv', encoding='utf-8')))
print(f'Filas iniciales: {len(rows)}')

scores_gmyrek = {}
with open('/tmp/gmyrek_2025_ciuo4d_unique.csv', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        if r['mean_score_2025'] not in ('','NA'):
            scores_gmyrek[r['ISCO_08']] = r

# ---------- Capa 1: clasificar estado_score ----------
ENOE_CODES = {'0980','1006','1008'}
MILITAR_CIUOS = {'0110','0210','0310'}

def es_residual(titulo: str) -> bool:
    """Categorías 'Otros... no clasificados anteriormente'."""
    t = titulo.lower()
    return ('no clasificad' in t) or t.startswith('otros ') or t.startswith('otras ')

def es_supervisor(titulo: str) -> bool:
    return titulo.lower().startswith('supervisores')

for r in rows:
    c4 = r['unitario_4d']
    ciuos = [c for c in r['ciuo08_4d_correspondientes'].split(';') if c]
    # Idempotencia: si la fila ya viene marcada como imputada de una corrida
    # previa, hay que volver a partir de cero (vaciar score y dejar que la
    # capa 2 lo recalcule). Si no, build_layered acumula estados y es no-id.
    if r.get('score_imputado','FALSE') == 'TRUE':
        r['mean_score_ia_2025'] = ''
        r['score_minimo'] = ''
        r['score_maximo'] = ''
        r['score_imputado'] = 'FALSE'
        r['metodo_score'] = ''
    tiene_score = r['mean_score_ia_2025'] != ''
    r.setdefault('score_imputado','FALSE')
    r['metodo_score'] = 'directo' if tiene_score else ''

    if tiene_score:
        r['estado_score'] = 'disponible'
        continue

    # No tiene score → diagnosticar
    if c4 in ENOE_CODES:
        r['estado_score'] = 'no_aplica_enoe'
    elif c4 == '9999':
        r['estado_score'] = 'no_aplica_no_especificado'
    elif any(c in MILITAR_CIUOS for c in ciuos):
        r['estado_score'] = 'no_aplica_militar'
    elif ciuos and not any(c in scores_gmyrek for c in ciuos):
        r['estado_score'] = 'gmyrek_sin_evaluar'
    else:
        r['estado_score'] = 'sin_correspondencia_ciuo'

# ---------- Capa 2: imputación por promedio del subgrupo 3d ----------
# Sólo para residuales y supervisores que no tienen score y caen en
# 'sin_correspondencia_ciuo' o 'gmyrek_sin_evaluar'.
scores_por_3d = defaultdict(list)
for r in rows:
    if r['mean_score_ia_2025'] != '':
        try:
            scores_por_3d[r['subgrupo_3d']].append(float(r['mean_score_ia_2025']))
        except ValueError:
            pass

# También fallback al grupo principal 2d si el subgrupo 3d no tiene ningún score real.
scores_por_2d = defaultdict(list)
for r in rows:
    if r['mean_score_ia_2025'] != '':
        try:
            scores_por_2d[r['grupo_principal_2d']].append(float(r['mean_score_ia_2025']))
        except ValueError:
            pass

scores_por_1d = defaultdict(list)
for r in rows:
    if r['mean_score_ia_2025'] != '':
        try:
            scores_por_1d[r['division_1d']].append(float(r['mean_score_ia_2025']))
        except ValueError:
            pass

n_imp = {'3d':0, '2d':0, '1d':0}
for r in rows:
    if r['mean_score_ia_2025'] != '':
        continue
    if r['estado_score'] in ('no_aplica_enoe','no_aplica_no_especificado','no_aplica_militar'):
        continue
    titulo = r['unitario_titulo']
    if not (es_residual(titulo) or es_supervisor(titulo)):
        continue

    for nivel, pool_dict, key in [
        ('3d', scores_por_3d, r['subgrupo_3d']),
        ('2d', scores_por_2d, r['grupo_principal_2d']),
        ('1d', scores_por_1d, r['division_1d']),
    ]:
        pool = pool_dict.get(key, [])
        if pool:
            m = round(mean(pool), 4)
            r['mean_score_ia_2025'] = m
            r['score_imputado'] = 'TRUE'
            r['metodo_score'] = f'imputacion_{nivel} (n={len(pool)})'
            r['score_minimo'] = round(min(pool), 4)
            r['score_maximo'] = round(max(pool), 4)
            r['estado_score'] = f'imputado_{nivel}'
            n_imp[nivel] += 1
            break

print(f'Capa 2: {n_imp["3d"]} imputados 3d, {n_imp["2d"]} imputados 2d, {n_imp["1d"]} imputados 1d')

# ---------- Reporte cobertura ----------
from collections import Counter
estados = Counter(r['estado_score'] for r in rows)
print('\nDistribución estado_score:')
for k, v in estados.most_common():
    print(f'  {v:4d}  {k}')

# ---------- Escribir tabla maestra actualizada ----------
fields = list(rows[0].keys())
out = f'{BASE}/sinco_con_exposicion_ia.csv'
with open(out, 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader(); w.writerows(rows)
print(f'\nEscrito: {out}')

# ---------- Capa 3: archivo separado de propuestas de mapeo manual ----------
# Catálogo curado a mano por similitud semántica + nivel de competencia.
# Sólo para casos C (ocupaciones específicas sin correspondencia).
PROPUESTAS = [
    # (sinco_4d, ciuo_propuesto, justificacion)
    ('1313','1321','Directores de industrias manufactureras — CIUO-08 no tiene código específico para "energía"; 1321 es la categoría usada internacionalmente para utilities y manufactureras.'),
    ('1613','1321','Coordinadores y jefes de área en generación y provisión de energía — análogo a 1313 un nivel jerárquico más bajo; mismo CIUO 1321 (CIUO-08 no distingue niveles de coordinador/director para utilities).'),
    ('2136','2631','Economistas — sinónimo directo en CIUO-08.'),
    ('2164','2659','Escenógrafos — Artistas creativos no clasificados bajo otros epígrafes (CIUO-08 no tiene código propio).'),
    ('2333','2341','Alfabetizadores — Maestros de enseñanza primaria; en CIUO-08 la enseñanza para adultos básicos cae aquí.'),
    ('2334','2341','Profesores de enseñanza bilingüe (indígena) — Maestros de enseñanza primaria.'),
    ('2421','2212','Anestesiólogos — Médicos especialistas (CIUO-08 no desagrega por especialidad médica).'),
    ('2431','2149','Ingenieros biomédicos — Ingenieros no clasificados bajo otros epígrafes.'),
    ('2432','2267','Optometristas — sinónimo directo en CIUO-08.'),
    ('2433','2265','Nutriólogos — Dietistas y nutricionistas, sinónimo directo.'),
    ('2434','2263','Profesionistas en seguridad e higiene y salud pública — Profesionales de salud y seguridad ocupacional.'),
    ('2435','2230','Profesionistas en medicina tradicional y alternativa — código CIUO-08 directo.'),
    ('2436','2221','Enfermeras y paramédicos profesionales — Profesionales de enfermería.'),
    ('2437','2264','Fisioterapeutas y logopedas — Fisioterapeutas (logopedas pertenecen a 2266 pero el código predominante en SINCO es fisioterapia).'),
    ('2438','2262','Farmacólogos — Farmacéuticos. Nota: si se quiere distinguir investigación, alternativa es 2131 Biólogos.'),
    ('2711','2359','Auxiliares y técnicos en pedagogía y educación — Especialistas en educación n.c.p.'),
    ('4312','5249','Trabajadores en servicios de alquiler de bienes muebles — Vendedores n.c.p. Nota: 5249 NO tiene score en Gmyrek; alternativa fallback al subgrupo 3d.'),
    ('6116','6111','Trabajadores en otros cultivos agrícolas — Agricultores y trabajadores calificados de cultivos extensivos.'),
    ('6117','7514','Trabajadores en beneficio de productos agrícolas — Conserveros de frutas, hortalizas y productos relacionados.'),
    ('6128','7511','Trabajadores en beneficio de productos pecuarios — Carniceros, pescaderos y afines.'),
    ('6213','7511','Trabajadores en beneficio de productos pesqueros — mismo CIUO 7511.'),
    ('9213','9311','Ayudantes de dinamiteros y de buzos en perforación — Peones de minería y canteras.'),
    ('9634','9629','Cuidadores de autos en vía pública — Trabajadores de servicios elementales n.c.p.'),
    ('9664','9612','Recolectores de otros materiales — Clasificadores de desechos.'),
    # Casos con CIUO ya asignado pero Gmyrek sin score (1439, 7319) — proponer alternativa
    ('1226','1349','Directores en servicios de vigilancia y seguridad — INEGI los mapea a CIUO 1439 (Directores de servicios n.c.p.) que NO tiene score Gmyrek. Alternativa: 1349 Directores de servicios profesionales n.c.p., que sí tiene score y es la categoría más cercana.'),
    ('1526','1349','Coordinadores y jefes de área en servicios de vigilancia — mismo razonamiento que 1226: 1439 sin score, alternativa 1349.'),
    ('1723','1349','Coordinadores y jefes de área en servicios funerarios — mismo razonamiento: 1439 sin score, alternativa 1349.'),
    ('7321','8141','Artesanos en productos de plástico — INEGI los mapea a CIUO 7319 (Artesanos n.c.p.) sin score Gmyrek. Alternativa: 8141 Operadores de máquinas para productos de plástico (mismo dominio, sí tiene score).'),
    ('7614','7314','Trabajadores en hueso, concha, etc. — 7319 sin score Gmyrek. Alternativa: 7314 Alfareros y afines (artesanía manual de materiales similares).'),
]

# Construir filas de propuesta enriquecidas
sinco_idx = {r['unitario_4d']: r for r in rows}
propuesta_rows = []
for sinco_4d, ciuo_p, just in PROPUESTAS:
    if sinco_4d not in sinco_idx:
        continue
    r = sinco_idx[sinco_4d]
    sc = scores_gmyrek.get(ciuo_p)
    propuesta_rows.append({
        'sinco_4d': sinco_4d,
        'sinco_titulo': r['unitario_titulo'],
        'subgrupo_3d': r['subgrupo_3d'],
        'subgrupo_titulo': r['subgrupo_titulo'],
        'ciuo08_propuesto': ciuo_p,
        'ciuo08_titulo_propuesto': sc['Title'] if sc else '(sin entrada en Gmyrek 2025)',
        'mean_score_2025_propuesto': sc['mean_score_2025'] if sc else '',
        'potential25_propuesto': sc['potential25'] if sc else '',
        'justificacion': just,
        'aprobado': '',  # columna para que el usuario marque TRUE/FALSE en revisión
    })

out_prop = f'{BASE}/mapeo_manual_propuesto.csv'
fields_p = ['sinco_4d','sinco_titulo','subgrupo_3d','subgrupo_titulo',
            'ciuo08_propuesto','ciuo08_titulo_propuesto',
            'mean_score_2025_propuesto','potential25_propuesto',
            'justificacion','aprobado']
with open(out_prop, 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields_p)
    w.writeheader(); w.writerows(propuesta_rows)
print(f'Escrito: {out_prop} ({len(propuesta_rows)} propuestas)')
print(f'  De ellas con score Gmyrek listo: {sum(1 for p in propuesta_rows if p["mean_score_2025_propuesto"])}')
print(f'  Sin score Gmyrek (fallback necesario): {sum(1 for p in propuesta_rows if not p["mean_score_2025_propuesto"])}')
