from pathlib import Path
import json, hashlib, difflib, re
from collections import Counter

H = Path(__file__).resolve().parent
R = H.parents[3]
B = H / 'before'
M = 'SpeculativeComputation_Collective_Knowledge'
S = 'postfoundationscrisis'
A = 'peer_production_tool'
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
check(all(len(rows)==13 and all(len(row)==13 for row in rows) for rows in m['layers'].values()), 'All layers agree at 13 by 13')
check(len(placements(m)) == 4 and len(families(m)) == 4, 'All four authored placements and families retained')
check([p for p in placements(m) if not p[2].startswith(A)] == [p for p in placements(old) if not p[2].startswith(A)], 'Three supporting works retain exact cells and tokens')
for layer,cells in [('structure',[(6,3),(6,7)]),('utilities',[(6,1)])]:
    changed=[(x,z) for z,row in enumerate(m['layers'][layer]) for x,c in enumerate(row) if c!=old['layers'][layer][z][x]]
    check(changed==cells,'Only intended cells change in '+layer)
check(m['layers']['structure'][3][6]=='1' and m['layers']['structure'][7][6]=='1','Two central pier cells become floor')
check(m['layers']['utilities'][1][6]=='s','Arrival spawn declared')
check(m['layers']['interactables'][5][6]==A+':180:0:1#interactive:true#add_period:0.7','Original cell with arrival-facing full-size slower workbench')
for p in ['commons/data/artifact_roles.json','commons/data/map_authored.json']:
    check((R/p).read_bytes() == (B/p).read_bytes(), p+': retained')
check(read(R/'commons/data/artifact_roles.json')['order'][M]['primary'] == [A], 'Primary agrees with manuscript')
text = (R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
oldtext = (B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->', text) == [A], 'Primary anchor preserved')
for start in ['# More','When many','_placed +=', 'That is a simulation','Collective knowledge needs','The rhizome will']:
    if start=='_placed +=':
        para=re.search(r'```gdscript\n(.*?)```',oldtext,re.S).group(1)
    else:para=next(p for p in oldtext.split('\n\n') if p.startswith(start))
    check(para in text,'Preserved passage: '+start)
check('In the earlier display, a number labelled CONTRIBUTORS' in text,'Historic count discrepancy stays in the argument')
check(all(word in text for word in ['FLOW','COLOUR','PIECE','DISPUTE','REVISE','VERSION']),'Book describes actual controls')
check('A change has happened, but who agreed that the dispute was settled?' in text,'Revision is not equated with agreement')
check('The device keeps only the previous version in memory.' in text,'History limitation explicit')
core = read(R/'commons/data/museum_core_encounters.json')['rooms']
ocore = read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,M) == omit(ocore,M), 'Other core encounters retained')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
    check(core[M][k] == sha(R/'commons/maps'/M/n), 'Current '+k)
check(core[M]['learner_verified'] is False, 'Learner verification not asserted')
p = 'commons/artifacts/registry/postfoundations_crisis.json'
reg, oreg = read(R/p), read(B/p)
check(omit(reg['artifacts'],A) == omit(oreg['artifacts'],A), 'Unrelated registry entries preserved')
check(omit(reg,'artifacts') == omit(oreg,'artifacts'), 'Registry metadata preserved')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    now, prev = read(R/p), read(B/p)
    check([v for v in now['plans'] if v.get('map')!=M] == [v for v in prev['plans'] if v.get('map')!=M], p+': unrelated plan rows retained')
    row = next(v for v in now['plans'] if v.get('map')==M)
    check(Counter(v['token'] for v in row['artifacts']) == Counter({token:1 for token in families(m)}), p+': four placements retained')
    a=next(v for v in row['artifacts'] if v['token']==A)
    check(a['cell']==[6,5] and a['rotation']==180 and a['config']['interactive']=='true',p+': primary agrees with authored map')
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
check(len(r['checks'])==39 and all(v['ok'] for v in r['checks']), '39 interaction, state and gate checks pass')
check(len(r['walks'])==7 and all(v['passed'] for v in r['walks']), 'Seven selected walking segments pass')
check(len(r['shots'])==6 and all((H/Path(p).name).exists() for p in r['shots']), 'Six rendered captures retained')
check({v['token'] for v in r['artifacts']} & families(m) == {A,'wiki_fragment'}, 'Two living museum placements; two retained tokens rejected by lookup')
for token in ['the_fourth_limit','the_commons_table']:
    check((R/'commons/artifacts'/token/(token+'.tscn')).exists(),token+': source scene exists, lookup restoration remains')
states=r['captured_states']
check(states[0]['counts']==states[1]['counts']==states[2]['counts']==[40,40,6,6,6,0,1],'Colour and dispute do not increase the pile')
check(states[3]['counts']==[40,40,6,6,6,1,1],'Revision changes only its own counter')
check(states[5]['counts']==[3,43,2,6,8,1,2],'New version separates participation from lifetime distinct sources')
check('DISPUTED | REVISION 1' in states[3]['detail'],'Revision retains dispute and source label')
log = (H/(M+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log, 'No script or shader compilation error')
check(read(H/'process-result.json')['exit']==0, 'Godot exits 0')
rels = [Path('commons/maps')/M/n for n in ['final.md','technical.md','critical.md','tutorial.md','summary.md','blurb.md','map_data.json']]
rels += [Path('commons/artifacts/peer_production_tool/peer_production_tool.gd')]
for rel in rels:
    (H/(rel.stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(R/rel).read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
inputs = {f.relative_to(B).as_posix():{'before':sha(f),'current':sha(R/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (R/f.relative_to(B)).is_file()}
(H/'current-inputs.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8')
failed = [v['message'] for v in checks if not v['ok']]
(H/'content-checks.json').write_text(json.dumps(dict(count=len(checks),passed=not failed,checks=checks,failures=failed),indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(checks=len(checks),failures=failed)))
raise SystemExit(bool(failed))
