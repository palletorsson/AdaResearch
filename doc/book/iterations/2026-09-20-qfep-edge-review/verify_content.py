from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='QFEP_Edge_Of_Chaos'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,s):checks.append({'ok':bool(ok),'message':s})
def omit(d,*keys):return {a:b for a,b in d.items() if a not in keys}
def families(d):return {c.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for c in row if c.strip()}

seq=read(ROOT/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
oldseq=read(B/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
for key in ['maps','prerequisites','unlocks','deferred_maps','learning_objectives']:
 check(seq[key]==oldseq[key],key+' unchanged')
check([g for g in seq['artifact_groups'] if g['map']!=ROOM]==[g for g in oldseq['artifact_groups'] if g['map']!=ROOM],'Other hall groups preserved')
for room in seq['maps']:
 rel=Path('commons/maps')/room
 check(families(read(B/rel/'map_data.json'))==families(read(ROOT/rel/'map_data.json')),room+': artifact families retained')
 if room!=ROOM:
  check((B/rel/'map_data.json').read_bytes()==(ROOT/rel/'map_data.json').read_bytes(),room+': map byte-preserved')
  check((B/rel/'final.md').read_bytes()==(ROOT/rel/'final.md').read_bytes(),room+': manuscript byte-preserved')
m=read(ROOT/'commons/maps'/ROOM/'map_data.json')
check(all(len(rows)==15 and all(len(r)==16 for r in rows) for rows in m['layers'].values()),'All layers 16 by 15')
check(len(families(m))==6,'Six placement families retained')
check(all(m['layers']['structure'][z][12]=='1' for z in range(1,14)),'Level east route through hall')
oldmap=read(B/'commons/maps'/ROOM/'map_data.json')
check(all(m['layers']['structure'][z][x]==oldmap['layers']['structure'][z][x] for z in range(15) for x in range(16) if not (3<=z<=12 and 11<=x<=14)), 'Only east bay floor changed; central structure retained')
check(m['layers']['utilities'][1][7]=='s','Explicit entry spawn on clear north floor')
registry=read(ROOT/'commons/artifacts/registry/qfep.json')['artifacts']
check(omit(registry,'edge_of_chaos_unlocked')==omit(read(B/'commons/artifacts/registry/qfep.json')['artifacts'],'edge_of_chaos_unlocked'),'Other registry entries unchanged')
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
check(roles==oldroles,'Existing primary and secondary roles retained')
check(set(roles['roles'][ROOM])==families(m) and roles['order'][ROOM]['primary']==['edge_of_chaos_unlocked'],'Roles and placements agree')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,ROOM)==omit(oldcore,ROOM),'Unrelated core encounters preserved')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[ROOM][k]==sha(ROOT/'commons/maps'/ROOM/n),'Current '+k)
check(core[ROOM]['learner_verified'] is False,'Learner verification pending')
text=(ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['edge_of_chaos_unlocked'],'Book anchor agrees with primary')
archive=(ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for n in ['technical.md','critical.md']:check((B/'commons/maps'/ROOM/n).read_text(encoding='utf-8-sig') in archive,'Original '+n+' retained as historical proposal')
check('HOLD / RUN' in text and 'same model time' in text and 'NEW SEED' in text,'Written operations present in the encounter')
original=(B/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8-sig')
for opening in ['Which changes','The display updates','Choose a visible','LAMBDA follows','The hall’s recommended','The sandbox extends']:
 paragraph=next(t for t in original.split('\n\n') if t.startswith(opening))
 check(paragraph in text,'Preserved paragraph: '+opening)
check(m['map_info']['museum']['artifact_placement']=='map','Reviewed placements outrank older stamped necklace')
expected=[r for r in seq['maps'] if r!='QFEP_Sandbox']
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in now['plans'] if r.get('map')!=ROOM]==[r for r in old['plans'] if r.get('map')!=ROOM],p+': all other rows retained')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='qfeplaboratory']==expected,p+': seven authored halls in declared order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all placed families in plan')
 a=next(a for a in row['artifacts'] if a['token']=='edge_of_chaos_unlocked')
 check(a['config']=={'comparison_study':'on'} and a['rotation']==270 and a['cell']==[13,6],p+': paired display faces into east bay')
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
 check(p['hero']==b['hero']=='edge_of_chaos_unlocked' and p['says']=={ln['token']:ln['text'] for ln in b['lines']},path+': hero and speech aligned')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'],'Godot museum probe passes')
check(len(r['checks'])==32 and all(c['ok'] for c in r['checks']),'32 interaction/state checks pass')
check(len(r['walks'])==7 and all(w['passed'] for w in r['walks']),'Seven selected walking routes pass')
check(len(r['shots'])==6 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Six real Godot images retained')
a,b,c=r['captured_states'][:3]
check(a['seed']==b['seed'] and a['seed']+1==c['seed'],'Same seed across timestep refinement; another seed shown separately')
check(all(abs(v['model_time']-60)<1e-8 and v['lambda']==.4 for v in [a,b,c]),'Images compare equal model time and coefficients')
check(a['dt']==.3 and b['dt']==c['dt']==.15 and b['difference']<a['difference'],'Recorded selected timestep refinement reduces difference')
solver=read(HERE/'solver-checks.json')
check(solver['passed'] and len(solver['checks'])==16 and all(c['ok'] for c in solver['checks']),'16 numerical checks pass')
check(read(HERE/'solver-process-result.json')['exit']==0,'Numerical Godot exits cleanly')
check({a['token'] for a in r['artifacts']} & families(m)==families(m)-{'tt'},'Five authored works instantiate; legacy tt has no living scene')
log=(HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,'No script or shader compilation errors in final run')
check(read(HERE/'process-result.json')['exit']==0,'Rendered Godot exits cleanly')
for name in ['final.md','technical.md','critical.md']:
 rel=Path('commons/maps')/ROOM/name
 (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
for rel in ['commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd','commons/interfaces/qfep/turing_pattern.gd']:
 (HERE/(Path(rel).stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'count':len(checks),'checks':checks,'passed':not failed,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
