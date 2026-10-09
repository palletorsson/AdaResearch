from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='QFEP_F_Term'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,s):checks.append({'ok':bool(ok),'message':s})
def without(d,k):return {a:b for a,b in d.items() if a!=k}
aliases={'snap_cube_puzzle':'snap_octahedron_puzzle','snap_tetra_puzzle':'snap_tetrahedron_puzzle'}
def families(d):return {aliases.get(t,t) for row in d['layers']['interactables'] for c in row if c.strip() for t in [c.split(':')[0].split('#')[0]]}
seq=read(ROOT/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
oldseq=read(B/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
for key in ['maps','prerequisites','unlocks','deferred_maps','learning_objectives']:
 check(seq[key]==oldseq[key],key+' unchanged')
check([g for g in seq['artifact_groups'] if g['map']!=ROOM]==[g for g in oldseq['artifact_groups'] if g['map']!=ROOM],'Other hall groups preserved')
for room in seq['maps']:
 rel=Path('commons/maps')/room
 check(families(read(B/rel/'map_data.json'))==families(read(ROOT/rel/'map_data.json')),room+': artifact families retained with canonical aliases')
 if room!=ROOM:
  for name in ['map_data.json','final.md']:check((B/rel/name).read_bytes()==(ROOT/rel/name).read_bytes(),room+': '+name+' byte-preserved')
m=read(ROOT/'commons/maps'/ROOM/'map_data.json')
check(all(len(rows)==12 and all(len(r)==10 for r in rows) for rows in m['layers'].values()),'All layers 10 by 12')
check(len(families(m))==8,'Eight placed works retained')
registry=read(ROOT/'commons/artifacts/registry/qfep.json')['artifacts']
active=read(ROOT/'commons/artifacts/registry/primitives.json')['artifacts']
for old,new in aliases.items():check(registry[old]['scene']==active[new]['scene'] and active[new]['map_ready'],'Canonical '+new+' restores same scene as '+old)
check(without(registry,'shannon_workbench')==without(read(B/'commons/artifacts/registry/qfep.json')['artifacts'],'shannon_workbench'),'Other registry entries unchanged')
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
for k in ['roles','order']:check(without(roles[k],ROOM)==without(oldroles[k],ROOM),'Other '+k+' preserved')
check(set(roles['roles'][ROOM])==families(m) and roles['order'][ROOM]['primary']==['shannon_workbench'],'Roles, primary and placements agree')
check(roles['roles'][ROOM]['dark_sphere']=='decoration','Legacy dark sphere not promoted')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(without(core,ROOM)==without(oldcore,ROOM),'Other core encounters preserved')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[ROOM][k]==sha(ROOT/'commons/maps'/ROOM/n),'Current '+k)
check(core[ROOM]['learner_verified'] is False,'Learner verification pending')
text=(ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['shannon_workbench'],'Book anchor agrees with primary')
archive=(ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for n in ['technical.md','critical.md']:check((B/'commons/maps'/ROOM/n).read_text(encoding='utf-8-sig') in archive,'Original '+n+' retained as historical proposal')
auth=read(ROOT/'commons/data/map_authored.json');oldauth=read(B/'commons/data/map_authored.json')
check(without(auth,'qfeplaboratory')==without(oldauth,'qfeplaboratory'),'Other authored sequences retained')
expected=[r for r in seq['maps'] if r!='QFEP_Sandbox']
check(auth['qfeplaboratory']==expected,'F hall restored second; only Sandbox remains missing')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in now['plans'] if r.get('map')!=ROOM]==old['plans'],p+': all existing rows retained')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='qfeplaboratory']==expected,p+': seven authored halls in declared order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all eight artifacts in plan')
 a=next(a for a in row['artifacts'] if a['token']=='shannon_workbench')
 check(a['config']=={'prediction_study':'on','initial_p':'0.1'} and a['cell']==[4,4] and a['rotation']==180,p+': prediction configuration and placement agree')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Live/shipped plan files agree')
book=read(ROOT/'commons/data/book/qfeplaboratory.json')['pearls'];oldbook=read(B/'commons/data/book/qfeplaboratory.json')['pearls']
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
b=next(p for p in book if p['map']==ROOM)
for path in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/path),read(ROOT/path)
 check([n for n in old['trunk'] if n['node']!='qfeplaboratory']==[n for n in now['trunk'] if n['node']!='qfeplaboratory'],path+': unrelated chapters unchanged')
 o,n=[next(v for v in d['trunk'] if v['node']=='qfeplaboratory') for d in [old,now]]
 check([p for p in n['pearls'] if p['map']!=ROOM]==[p for p in o['pearls'] if p['map']!=ROOM],path+': other hall speech unchanged')
 p=next(p for p in n['pearls'] if p['map']==ROOM)
 check(p['hero']==b['hero']=='shannon_workbench' and p['says']=={ln['token']:ln['text'] for ln in b['lines']},path+': hero and speech aligned')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'],'Godot museum probe passes')
check(len(r['checks'])==26 and all(c['ok'] for c in r['checks']),'26 runtime assertions pass')
check(len(r['walks'])==5 and all(w['passed'] for w in r['walks']),'Five selected walking routes pass')
check(len(r['shots'])==4 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Four real Godot images retained')
a,b,c=[s['reading'] for s in r['captured_states'][:3]]
check(abs(a['source_h']-b['source_h'])<1e-7 and a['observed_errors']==27 and b['observed_errors']==230,'Equal-entropy pair has different measured misses')
check(b['p']==c['p'] and b['source_h']==c['source_h'] and c['observed_errors']==26,'Changing predictor improves fit at fixed source')
check(all(any(a['token']==t for a in r['artifacts']) for t in ['shannon_workbench','snap_octahedron_puzzle','snap_tetrahedron_puzzle','crystal_cluster']),'Primary and restored puzzles actually instantiate')
check('SCRIPT ERROR:' not in (HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace'),'No script errors in final run')
for name in ['final.md','technical.md','critical.md']:
 rel=Path('commons/maps')/ROOM/name
 (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'count':len(checks),'checks':checks,'passed':not failed,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
