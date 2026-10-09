from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='QFEP_Lambda_Spectrum'
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
check(all(len(rows)==24 and all(len(r)==17 for r in rows) for rows in m['layers'].values()),'All layers 17 by 24')
check(len(families(m))==10,'All ten placed works retained')
check(all(m['layers']['structure'][z][8]=='1' for z in range(24)),'Level central floor through hall')
registry=read(ROOT/'commons/artifacts/registry/concept_architecture.json')['artifacts']
check(omit(registry,'lambda_hall')==omit(read(B/'commons/artifacts/registry/concept_architecture.json')['artifacts'],'lambda_hall'),'Other registry entries unchanged')
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
check(roles==oldroles,'Existing primary and secondary roles retained')
check(set(roles['roles'][ROOM])==families(m) and roles['order'][ROOM]['primary']==['lambda_hall'],'Roles and placements agree')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,ROOM)==omit(oldcore,ROOM),'Unrelated core encounters preserved')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[ROOM][k]==sha(ROOT/'commons/maps'/ROOM/n),'Current '+k)
check(core[ROOM]['learner_verified'] is False,'Learner verification pending')
text=(ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['lambda_hall'],'Book anchor agrees with primary')
archive=(ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for n in ['technical.md','critical.md']:check((B/'commons/maps'/ROOM/n).read_text(encoding='utf-8-sig') in archive,'Original '+n+' retained as historical proposal')
check('For a future comparison' not in text and 'Move LIT STRIP' in text,'Proposed experiment is now an implemented action')
original=(B/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8-sig')
check(text.split('Return to the small console')[0]==original.split('For a future comparison')[0],'Mature opening and argument preserved exactly')
check(m['map_info']['museum']['artifact_placement']=='map','Reviewed placements outrank older stamped necklace')
auth=read(ROOT/'commons/data/map_authored.json');oldauth=read(B/'commons/data/map_authored.json')
check(auth==oldauth,'Authored halls unchanged')
expected=[r for r in seq['maps'] if r!='QFEP_Sandbox']
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in now['plans'] if r.get('map')!=ROOM]==[r for r in old['plans'] if r.get('map')!=ROOM],p+': all other rows retained')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='qfeplaboratory']==expected,p+': seven authored halls in declared order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all ten works in plan')
 a=next(a for a in row['artifacts'] if a['token']=='lambda_hall')
 check(a['config']=={'recommendation_control':'on','recommendation_position':'0.35'} and a['rotation']==180,p+': visitor control enabled facing entrance')
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
 check(p['hero']==b['hero']=='lambda_hall' and p['says']=={ln['token']:ln['text'] for ln in b['lines']},path+': hero and speech aligned')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'],'Godot museum probe passes')
check(len(r['checks'])==28 and all(c['ok'] for c in r['checks']),'28 interaction/state checks pass')
check(len(r['walks'])==6 and all(w['passed'] for w in r['walks']),'Six selected walking routes pass')
check(len(r['shots'])==5 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Five real Godot images retained')
a,b,c=r['captured_states'][:3]
check(a['recommendation']==.2 and b['recommendation']==.8 and c['recommendation']==.35,'Captured recommendations cover both rail ends and return')
check(a['structure_lambda']==b['structure_lambda']==c['structure_lambda']==.35 and a['time']==b['time']==c['time'],'Paired captures preserve structure setting and animation time')
log=(HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,'No script or shader compilation errors in final run')
headless=read(HERE/(ROOM+'-headless-runtime.json'))
check(headless['passed'] and all(c['ok'] for c in headless['checks']) and all(w['passed'] for w in headless['walks']),'Independent headless checks and walks pass on final source')
check(read(HERE/'headless-process-result.json')['exit']==0,'Independent headless Godot exits cleanly; rendered shutdown issue recorded separately')
check('SCRIPT ERROR:' not in (HERE/(ROOM+'-headless-engine.log')).read_text(encoding='utf-8',errors='replace'),'Final headless source has no script errors')
for name in ['final.md','technical.md','critical.md']:
 rel=Path('commons/maps')/ROOM/name
 (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'count':len(checks),'checks':checks,'passed':not failed,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
