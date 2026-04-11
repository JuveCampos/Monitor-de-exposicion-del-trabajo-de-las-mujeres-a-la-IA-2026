#!/usr/bin/env python3
"""
Parser con herencia correcta:
- Las filas contienen SINCO a distintos niveles (1d/2d/3d/4d) y CIUO 4d.
- Cuando un SINCO 4d aparece sin CIUO en su fila, HEREDA el último CIUO que vio
  dentro del mismo subgrupo 3d (convención INEGI: sólo llenan la primera fila).
- La herencia se resetea al cambiar de subgrupo 3d (o niveles superiores).
- Filas con texto "No tiene correspondencia" marcan huérfanos explícitos.
- Filas "huérfanas" (sin SINCO pero con CIUO) son correspondencias adicionales
  del último SINCO 4d vigente (1:N).
"""
import openpyxl
import csv
from collections import defaultdict

BASE = '/Users/jorgejuvenalcamposferreira/Documents/Claude Encargos/36-dataton-genero/05_Tareas/01_catalogos'

wb = openpyxl.load_workbook(f'{BASE}/sinco_tablas_comparativas.xlsx', read_only=True, data_only=True)
ws = wb['SINCO-CIUO']

def _as_code(x):
    if x is None: return None
    if isinstance(x, (int, float)): return str(int(x))
    s = str(x).strip()
    return s if s else None

crosswalk = []        # lista de pares sinco→ciuo
cur_sinco_4d = None   # (code, titulo) contexto 4d activo
cur_sinco_3d = None   # contexto 3d — resetea herencia
last_ciuo_in_3d = None  # último CIUO que vimos en este subgrupo 3d (para herencia)

for row in ws.iter_rows(min_row=7, values_only=True):
    sinco_code = _as_code(row[3])
    sinco_tit  = row[4].strip() if isinstance(row[4], str) else None
    ciuo_code  = _as_code(row[5])
    ciuo_tit   = row[6].strip() if isinstance(row[6], str) else None
    is_no_corr = isinstance(row[6], str) and 'No tiene correspondencia' in row[6]

    if sinco_code is not None:
        lvl = len(sinco_code)
        if lvl < 3:
            # cambio 1d/2d → reinicia todo
            cur_sinco_4d = None
            cur_sinco_3d = None
            last_ciuo_in_3d = None
        elif lvl == 3:
            # cambio de subgrupo → reinicia herencia
            cur_sinco_4d = None
            cur_sinco_3d = sinco_code
            last_ciuo_in_3d = None
        elif lvl == 4:
            # nuevo grupo unitario: activar contexto
            cur_sinco_4d = (sinco_code.zfill(4), sinco_tit or '')
            if ciuo_code is not None:
                # registrar par, guardar como CIUO heredable del 3d actual
                crosswalk.append({
                    'sinco_4d': cur_sinco_4d[0],
                    'sinco_titulo': cur_sinco_4d[1],
                    'ciuo_4d': ciuo_code.zfill(4),
                    'ciuo_titulo': ciuo_tit or '',
                })
                last_ciuo_in_3d = (ciuo_code.zfill(4), ciuo_tit or '')
            elif is_no_corr:
                # huérfano explícito — no hereda
                crosswalk.append({
                    'sinco_4d': cur_sinco_4d[0],
                    'sinco_titulo': cur_sinco_4d[1],
                    'ciuo_4d': '',
                    'ciuo_titulo': 'No tiene correspondencia',
                })
                last_ciuo_in_3d = None  # ese nodo no debe heredarse
            else:
                # sin CIUO en la fila → heredar del último CIUO del mismo 3d
                if last_ciuo_in_3d is not None:
                    crosswalk.append({
                        'sinco_4d': cur_sinco_4d[0],
                        'sinco_titulo': cur_sinco_4d[1],
                        'ciuo_4d': last_ciuo_in_3d[0],
                        'ciuo_titulo': last_ciuo_in_3d[1],
                    })
                else:
                    # no hay nada que heredar → sin correspondencia implícita
                    crosswalk.append({
                        'sinco_4d': cur_sinco_4d[0],
                        'sinco_titulo': cur_sinco_4d[1],
                        'ciuo_4d': '',
                        'ciuo_titulo': '',
                    })
    else:
        # fila sin SINCO: puede ser (a) huérfana con CIUO adicional del SINCO 4d vigente, o (b) vacía
        if ciuo_code is not None and cur_sinco_4d is not None:
            crosswalk.append({
                'sinco_4d': cur_sinco_4d[0],
                'sinco_titulo': cur_sinco_4d[1],
                'ciuo_4d': ciuo_code.zfill(4),
                'ciuo_titulo': ciuo_tit or '',
            })
            # NO actualizamos last_ciuo_in_3d: la herencia para 4ds siguientes
            # se basa en la "primera" correspondencia, no en la última adicional.

print(f'Crosswalk SINCO→CIUO-08: {len(crosswalk)} pares')
sincos_mapeados = {r['sinco_4d'] for r in crosswalk if r['ciuo_4d']}
sincos_totales  = {r['sinco_4d'] for r in crosswalk}
print(f'  SINCO 4d con algún CIUO: {len(sincos_mapeados)}')
print(f'  SINCO 4d total en el crosswalk: {len(sincos_totales)}')

# Dedup: algunos SINCO pueden haberse duplicado si aparecen con correspondencia vacía + real
seen = set()
dedup = []
for r in crosswalk:
    key = (r['sinco_4d'], r['ciuo_4d'])
    if key in seen: continue
    # si para el mismo sinco ya existe una correspondencia con ciuo, quitar la vacía
    seen.add(key)
    dedup.append(r)
crosswalk = dedup
# eliminar filas "vacía" para sincos que sí tienen ciuo real
has_real = defaultdict(bool)
for r in crosswalk:
    if r['ciuo_4d']: has_real[r['sinco_4d']] = True
crosswalk = [r for r in crosswalk if r['ciuo_4d'] or not has_real[r['sinco_4d']]]
print(f'  tras dedup: {len(crosswalk)} pares')

out1 = f'{BASE}/crosswalk_sinco_ciuo08_long.csv'
with open(out1, 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=['sinco_4d','sinco_titulo','ciuo_4d','ciuo_titulo'])
    w.writeheader(); w.writerows(crosswalk)
print('Escrito:', out1)

# ---------- Join con scores Gmyrek ----------
scores = {}
with open('/tmp/gmyrek_2025_ciuo4d_unique.csv', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        scores[r['ISCO_08']] = r

sinco_jer = {}
with open(f'{BASE}/sinco_2019_jerarquico.csv', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        sinco_jer[r['unitario_4d']] = r

sinco_pairs = defaultdict(list)
for pair in crosswalk:
    sinco_pairs[pair['sinco_4d']].append(pair)

final_rows = []
for s4, base in sinco_jer.items():
    pairs = sinco_pairs.get(s4, [])
    ciuos = [p['ciuo_4d'] for p in pairs if p['ciuo_4d']]
    scs = []
    for c in ciuos:
        if c in scores:
            sc = scores[c]
            try:
                ms = float(sc['mean_score_2025']) if sc['mean_score_2025'] not in (None,'','NA') else None
            except:
                ms = None
            scs.append({'ciuo_4d': c, 'mean_score_2025': ms, 'potential25': sc['potential25']})

    vals = [x['mean_score_2025'] for x in scs if x['mean_score_2025'] is not None]
    mean_score = round(sum(vals)/len(vals), 4) if vals else None
    pots = sorted({x['potential25'] for x in scs if x['potential25']})
    potencial = pots[0] if len(pots) == 1 else ('Mixto' if len(pots) > 1 else '')
    final_rows.append({
        **base,
        'ciuo08_4d_correspondientes': ';'.join(ciuos),
        'n_ciuo_correspondencias': len(ciuos),
        'mean_score_ia_2025': mean_score if mean_score is not None else '',
        'potencial_ia_2025': potencial,
        'score_minimo': round(min(vals),4) if vals else '',
        'score_maximo': round(max(vals),4) if vals else '',
    })

n_total = len(final_rows)
n_con_ciuo  = sum(1 for r in final_rows if r['n_ciuo_correspondencias'] > 0)
n_con_score = sum(1 for r in final_rows if r['mean_score_ia_2025'] != '')
print(f'\nCatálogo final: {n_total} ocupaciones SINCO')
print(f'  Con correspondencia CIUO-08: {n_con_ciuo} ({100*n_con_ciuo/n_total:.1f}%)')
print(f'  Con score de IA generativa 2025: {n_con_score} ({100*n_con_score/n_total:.1f}%)')

# muestra de sin score
sin = [r for r in final_rows if r['mean_score_ia_2025'] == ''][:10]
print('\nSin score (muestra):')
for r in sin:
    print(f"  {r['unitario_4d']} {r['unitario_titulo'][:55]:55s} → CIUOs=[{r['ciuo08_4d_correspondientes']}]")

out2 = f'{BASE}/sinco_con_exposicion_ia.csv'
fields = list(final_rows[0].keys())
with open(out2, 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader(); w.writerows(final_rows)
print('\nEscrito:', out2)

# distribución de scores
import statistics
vals_all = [float(r['mean_score_ia_2025']) for r in final_rows if r['mean_score_ia_2025'] != '']
if vals_all:
    print(f'\nDistribución score medio de IA 2025 (n={len(vals_all)}):')
    print(f'  min={min(vals_all):.3f}  p25={statistics.quantiles(vals_all,n=4)[0]:.3f}  '
          f'mediana={statistics.median(vals_all):.3f}  '
          f'p75={statistics.quantiles(vals_all,n=4)[2]:.3f}  max={max(vals_all):.3f}')
    from collections import Counter
    print('  potencial25:', dict(Counter(r['potencial_ia_2025'] for r in final_rows if r['potencial_ia_2025'])))
