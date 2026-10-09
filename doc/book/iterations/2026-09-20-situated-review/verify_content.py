from pathlib import Path
import json, hashlib, difflib, re
from collections import Counter

H = Path(__file__).resolve().parent
R = H.parents[3]
B = H / 'before'
M = 'SpeculativeComputation_Situated_Computation'
S = 'postfoundationscrisis'
A = 'situated_readout'
checks = []

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok, message): checks.append(dict(ok=bool(ok), message=message))
def omit(d, *keys): return {k:v for k,v in d.items() if k not in keys}
def placements(d):
    return [(x,z,c.strip()) for z,row in enumerate(d['layers']['interactables']) for x,c in enumerate(row) if c.strip()]
def families(d): return {c.split(':')[0].split('#')[0] for x,z,c in placements(d)}

p = f'commons/maps/sequences/{S}.json'
check((R/p).read_bytes() == (B/p).read_bytes(), 'Sequence and learning order preserved')
for room in read(R/p)['sequences'][S]['maps']:
    rel = Path('commons/maps') / room
    check(families(read(R/rel/'map_data.json')) == families(read(B/rel/'map_data.json')), room+': every artifact family retained')
    if room != M:
        for name in ['map_data.json', 'final.md']:
            check((R/rel/name).read_bytes() == (B/rel/name).read_bytes(), room+': '+name+' byte-preserved')
m = read(R/'commons/maps'/M/'map_data.json')
old = read(B/'commons/maps'/M/'map_data.json')
check(all(len(rows)==10 and all(len(row)==10 for row in rows) for rows in m['layers'].values()), 'All layers agree at 10 by 10')
check(len(placements(m)) == 5 and families(m) == {A, 'head_crab'}, 'All five authored placements and both families remain')
check([p for p in placements(m) if not p[2].startswith(A)] == [p for p in placements(old) if not p[2].startswith(A)], 'Creature token, detection and cell retained exactly')
for layer, cells in [('structure', [(4,9)]), ('utilities', [(5,1)])]:
    changed = [(x,z) for z,row in enumerate(m['layers'][layer]) for x,c in enumerate(row) if c != old['layers'][layer][z][x]]
    check(changed == cells, 'Only intended cells changed in '+layer)
check(str(m['layers']['structure'][9][4]) == '1', 'Exit has continuous support')
check(m['layers']['utilities'][1][5] == 's', 'Explicit arrival spawn')
for x,z,rotation,key in [(2,2,45,'NW'),(7,2,315,'NE'),(2,7,135,'SW'),(7,7,225,'SE')]:
    check(m['layers']['interactables'][z][x] == f'{A}:{rotation}:0:1#verdict:{key}#interactive:true#address:footnote', key+': original cell and verdict, inward view, full scale and controls')
for p in ['commons/data/artifact_roles.json','commons/data/map_authored.json']:
    check((R/p).read_bytes() == (B/p).read_bytes(), p+': retained')
check(read(R/'commons/data/artifact_roles.json')['order'][M]['primary'] == [A], 'Primary agrees with manuscript')
text = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
oldtext = (B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->', text) == [A], 'Primary anchor preserved')
for para in oldtext.split('\n\n'):
    if para.strip() and not para.startswith('# ') and not para.startswith('Read the subject'):
        check(para in text, 'Preserved manuscript passage: '+para[:65].replace('\n',' '))
check(all(t in text for t in ['FOOTNOTE','COVER','WITNESS','This eye has no sensor']), 'New actions and symbolic eye described')
core = read(R/'commons/data/museum_core_encounters.json')['rooms']
ocore = read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,M) == omit(ocore,M), 'Other core encounters retained')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
    check(core[M][k] == sha(R/'commons/maps'/M/n), 'Current '+k)
check(core[M]['learner_verified'] is False, 'Learner verification not asserted')
p = 'commons/artifacts/registry/algorithms_misc.json'
reg, oreg = read(R/p), read(B/p)
check(omit(reg['artifacts'],A) == omit(oreg['artifacts'],A), 'Unrelated registry entries preserved')
check(omit(reg,'artifacts') == omit(oreg,'artifacts'), 'Registry metadata preserved')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    now, prev = read(R/p), read(B/p)
    check([v for v in now['plans'] if v.get('map')!=M] == [v for v in prev['plans'] if v.get('map')!=M], p+': unrelated plan rows retained')
    row = next(v for v in now['plans'] if v.get('map')==M)
    check(Counter(v['token'] for v in row['artifacts']) == Counter({A:4,'head_crab':1}), p+': all five placements retained')
    check({(tuple(v['ruled']['cell']),v['rotation'],v['config']['verdict']) for v in row['artifacts'] if v['token']==A} == {((2,2),45,'NW'),((7,2),315,'NE'),((2,7),135,'SW'),((7,7),225,'SE')}, p+': original cells and inward views aligned')
check(read(R/'ada_run/em_plan.json') == read(R/'commons/data/museum/em_plan.json'), 'Plan mirrors agree')
book = read(R/f'commons/data/book/{S}.json')['pearls']
ob = read(B/f'commons/data/book/{S}.json')['pearls']
check([v for v in book if v['map']!=M] == [v for v in ob if v['map']!=M], 'Other book pearls retained')
pearl = next(v for v in book if v['map']==M)
check(pearl['hero']==A, 'Book hero matches encounter')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
    now, prev = read(R/p), read(B/p)
    check([v for v in now['trunk'] if v['node']!=S] == [v for v in prev['trunk'] if v['node']!=S], p+': other chapters retained')
    a,b = [next(v for v in d['trunk'] if v['node']==S) for d in [now,prev]]
    check([v for v in a['pearls'] if v['map']!=M] == [v for v in b['pearls'] if v['map']!=M], p+': other hall speech retained')
    e = next(v for v in a['pearls'] if v['map']==M)
    check(e['hero']==A and e['says']=={v['token']:v['text'] for v in pearl['lines']}, p+': book speech aligned')
r = read(H/(M+'-runtime.json'))
check(r['passed'] and not r['failures'], 'Museum probe passes')
check(len(r['checks'])==63 and all(v['ok'] for v in r['checks']), '63 interaction, state and gate checks pass')
check(len(r['walks'])==10 and all(v['passed'] for v in r['walks']), 'Ten selected walking segments pass')
check(len(r['shots'])==6 and all((H/Path(p).name).exists() for p in r['shots']), 'Six rendered captures retained')
check(Counter(v['token'] for v in r['artifacts'] if v['token'] in families(m)) == Counter({A:4,'head_crab':1}), 'All five authored scenes instantiate')
states = r['captured_states']
check([v['fields'][1] for v in states[:4]] == ['ORDERLY','CREATIVE','DANGEROUS','IRRELEVANT'], 'Four authored verdicts captured')
check(states[2]['fields']==states[4]['fields']==states[5]['fields'], 'SW fields unchanged through cover and witness')
check([v['address'] for v in states[4:]] == ['erasure','witness'], 'Alternate frames captured')
log = (H/(M+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log, 'No script or shader compilation error')
check(read(H/'process-result.json')['exit']==0, 'Godot exits 0')
rels = [Path('commons/maps')/M/n for n in ['final.md','technical.md','critical.md','tutorial.md','summary.md','blurb.md','map_data.json']]
rels += [Path('commons/artifacts/situated_readout/situated_readout.gd')]
for rel in rels:
    (H/(rel.stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(R/rel).read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
inputs = {f.relative_to(B).as_posix():{'before':sha(f),'current':sha(R/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (R/f.relative_to(B)).is_file()}
(H/'current-inputs.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8')
failed = [v['message'] for v in checks if not v['ok']]
(H/'content-checks.json').write_text(json.dumps(dict(count=len(checks),passed=not failed,checks=checks,failures=failed),indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(checks=len(checks),failures=failed)))
raise SystemExit(bool(failed))
