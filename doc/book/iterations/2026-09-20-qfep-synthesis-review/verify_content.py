from pathlib import Path
import json, hashlib, difflib, re

HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='QFEP_Synthesis'
checks=[]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,s): checks.append({'ok':bool(ok),'message':s})
def omit(d,*keys): return {k:v for k,v in d.items() if k not in keys}
def families(d): return {c.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for c in row if c.strip()}

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
check(all(len(rows)==14 and all(len(r)==14 for r in rows) for rows in m['layers'].values()),'All layers 14 by 14')
check(len(families(m))==10,'Ten placement families retained')
oldm=read(B/'commons/maps'/ROOM/'map_data.json')
check(m['layers']['utilities']==oldm['layers']['utilities'],'Spawn and utilities retained')
changes=[(x,z) for z,row in enumerate(m['layers']['structure']) for x,c in enumerate(row) if c!=oldm['layers']['structure'][z][x]]
check(set(changes)=={(2,3),(3,3)},'Only two support cells changed')
def placements(d):
 return [(x,z,c) for z,row in enumerate(d['layers']['interactables']) for x,c in enumerate(row) if c and not c.startswith('queer_morphology_specimen')]
check(placements(m)==placements(oldm),'All surrounding placements retained')
check(m['layers']['interactables'][3][3]=='queer_morphology_specimen:180:0.105:1','Full-size specimen faces entry on support')
p='commons/artifacts/registry/commons_artifacts.json'
registry=read(ROOT/p);oldregistry=read(B/p)
check(omit(registry['artifacts'],'queer_morphology_specimen')==omit(oldregistry['artifacts'],'queer_morphology_specimen'),'Other registry entries unchanged')
check(omit(registry,'artifacts')==omit(oldregistry,'artifacts'),'Registry top-level metadata retained')
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
check(roles==oldroles,'All roles and secondary order retained')
primary=['queer_morphology_specimen']
check(roles['order'][ROOM]['primary']==primary,'Primary order retained')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,ROOM)==omit(oldcore,ROOM),'Unrelated core encounters preserved')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]: check(core[ROOM][k]==sha(ROOT/'commons/maps'/ROOM/n),'Current '+k)
check(core[ROOM]['learner_verified'] is False,'Learner verification pending')
text=(ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==primary,'Book anchors agree with primary encounters')
archive=(ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for n in ['technical.md','tutorial.md','critical.md']: check((B/'commons/maps'/ROOM/n).read_text(encoding='utf-8-sig') in archive,'Original '+n+' retained as historical proposal')
original=(B/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8-sig')
for opening in ['Which kind of stability','Use the specimen','LAMBDA changes','Watch a change','Compare two combinations','The laboratory has','A responsive specimen','Post-crisis begins']:
 paragraph=next(t for t in original.split('\n\n') if t.startswith(opening))
 check(paragraph in text,'Preserved paragraph: '+opening)
check('PULSE / STEADY' in text and 'Self-Q' in text and 'The name above the glass stays' in text,'New actions and critical question belong to the same specimen')
check(m['map_info']['museum']['artifact_placement']=='map','Reviewed placements outrank older stamped necklace')
authored=read(ROOT/'commons/data/map_authored.json');oldauthored=read(B/'commons/data/map_authored.json')
check(omit(authored,'qfeplaboratory')==omit(oldauthored,'qfeplaboratory'),'Other authored chapters unchanged')
check(authored['qfeplaboratory']==seq['maps'],'All eight laboratory halls authored in declared order')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 def other_rows(d):
  return [omit(r,'pearl_index','pearls_total') if r.get('sequence')=='qfeplaboratory' else r for r in d['plans'] if r.get('map')!=ROOM]
 check(other_rows(old)==other_rows(now),p+': other geometry and artifact rows retained; only chapter order fields may differ')
 check(omit(old,'plans')==omit(now,'plans'),p+': top-level metadata preserved')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='qfeplaboratory']==seq['maps'],p+': eight authored halls in declared order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all six placement families in plan')
 a=next(a for a in row['artifacts'] if a['token']=='queer_morphology_specimen')
 check(a['rotation']==180 and a['cell']==[3,3],p+': specimen faces its approach')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Live/shipped plan files agree')
book=read(ROOT/'commons/data/book/qfeplaboratory.json')['pearls'];oldbook=read(B/'commons/data/book/qfeplaboratory.json')['pearls']
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
b=next(p for p in book if p['map']==ROOM)
for path in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/path),read(ROOT/path)
 check([n for n in old['trunk'] if n['node']!='qfeplaboratory']==[n for n in now['trunk'] if n['node']!='qfeplaboratory'],path+': unrelated chapters unchanged')
 o,n=[next(v for v in d['trunk'] if v['node']=='qfeplaboratory') for d in [old,now]]
 check([omit(p,'index') for p in n['pearls'] if p['map']!=ROOM]==[omit(p,'index') for p in o['pearls'] if p['map']!=ROOM],path+': other hall speech unchanged; indices follow restored order')
 check([p['map'] for p in n['pearls']]==seq['maps'],path+': all eight pearls in declared order')
 check(not next(e for e in now['hand_pearls']['qfeplaboratory'] if e.get('map')==ROOM).get('drop'),path+': hand override retains Synthesis')
 p=next(p for p in n['pearls'] if p['map']==ROOM)
 check(p['hero']==b['hero']=='queer_morphology_specimen' and p['says']=={ln['token']:ln['text'] for ln in b['lines']},path+': hero and speech aligned')
check(not b.get('drop'),'Book retains Synthesis')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'],'Godot museum probe passes')
check(len(r['checks'])==35 and all(c['ok'] for c in r['checks']),'All interaction/state checks pass')
check(len(r['walks'])==6 and all(w['passed'] for w in r['walks']),'Six selected walking routes pass')
check(len(r['shots'])==6 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Six real Godot images retained')
a,b,c,d=r['captured_states'][:4]
check(c['lambda']==d['lambda']==.5 and c['phi']==d['phi']==0,'Pulse/steady pair retains slider settings')
check(abs(c['pressure']-1.59)<1e-5 and abs(d['pressure']-1.5)<1e-5,'Pulse/steady pair records imposed modulation separately from baseline')
check(r['legacy_pressure']['after_lambda']==1.5 and abs(r['legacy_pressure']['after_process']-1)<.061,'Frozen source reproduces lost baseline')
check(r['point_sample']['displacement']>0,'Actual mesh point moves under physics')
check({a['token'] for a in r['artifacts']} & families(m)==families(m)-{'tt'},'Nine authored works instantiate; legacy tt has no living scene')
log=(HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,'No script or shader compilation errors in final run')
check(read(HERE/'process-result.json')['exit']==0,'Rendered Godot exits cleanly')
for name in ['final.md','technical.md','tutorial.md','critical.md']:
 rel=Path('commons/maps')/ROOM/name
 (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
rel=Path('commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd')
(HERE/'queer_morphology_specimen.diff').write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
inputs={f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()}
for rel in ['commons/maps/QFEP_Synthesis/design-proposals.md']:
 inputs[rel]={'before':None,'current':sha(ROOT/rel)}
(HERE/'current-inputs.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'count':len(checks),'checks':checks,'passed':not failed,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
