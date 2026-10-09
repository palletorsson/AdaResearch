from pathlib import Path
import json, hashlib, difflib, re

H=Path(__file__).resolve().parent; R=H.parents[3]; B=H/'before'
M='CriticalAlgorithms_Algorithmic_Bias_Visualization'; S='postfoundationscrisis'; checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,message):checks.append({'ok':bool(ok),'message':message})
def omit(d,*keys):return {k:v for k,v in d.items() if k not in keys}
def families(d):return {c.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for c in row if c}
seq=read(R/f'commons/maps/sequences/{S}.json')['sequences'][S]
check((R/f'commons/maps/sequences/{S}.json').read_bytes()==(B/f'commons/maps/sequences/{S}.json').read_bytes(),'Sequence order and learning arc retained')
for room in seq['maps']:
 rel=Path('commons/maps')/room
 check(families(read(R/rel/'map_data.json'))==families(read(B/rel/'map_data.json')),room+': every artifact family retained')
 if room!=M:
  for name in ['map_data.json','final.md']:
   check((R/rel/name).read_bytes()==(B/rel/name).read_bytes(),room+': '+name+' byte-preserved')
m=read(R/'commons/maps'/M/'map_data.json'); old=read(B/'commons/maps'/M/'map_data.json')
check(all(len(rows)==11 and all(len(row)==13 for row in rows) for rows in m['layers'].values()),'All layers agree at 13 by 11')
check(len(families(m))==4,'All four artifact families remain')
def other_placements(d):return [(x,z,c) for z,row in enumerate(d['layers']['interactables']) for x,c in enumerate(row) if c and not c.startswith('bias_from_inside')]
check(other_placements(m)==other_placements(old),'Three secondary works retain exact tokens and cells')
check([(x,z) for z,row in enumerate(m['layers']['structure']) for x,c in enumerate(row) if c!=old['layers']['structure'][z][x]]==[(6,6)],'Only the lower divider cell is opened')
check([(x,z) for z,row in enumerate(m['layers']['utilities']) for x,c in enumerate(row) if c!=old['layers']['utilities'][z][x]]==[(6,6)],'Only the obsolete ramp is removed; spawn retained')
check(m['layers']['interactables'][6][4]=='bias_from_inside:180:1.085:1','Study has deliberate full-size position and control height')
for p in ['commons/data/artifact_roles.json','commons/data/map_authored.json']:
 check((R/p).read_bytes()==(B/p).read_bytes(),p+': retained')
roles=read(R/'commons/data/artifact_roles.json')
check(roles['order'][M]['primary']==['bias_from_inside'],'Primary role agrees with book encounter')
text=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8');oldtext=(B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['bias_from_inside'],'Primary anchor retained')
for start in ['# Less room','Which differences','An embedding','That limitation','Choose one distinction','The applied-ethics']:
 para=next(t for t in oldtext.split('\n\n') if t.startswith(start))
 check(para in text,'Preserved passage: '+start)
check('do not name interchangeable experiences' in text,'Critique of the two-colour grouping retained')
check('while moving COMPRESSION' in text and 'Press READ' in text,'Book names real visitor operations')
core=read(R/'commons/data/museum_core_encounters.json')['rooms'];ocore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,M)==omit(ocore,M),'Other core encounters retained')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[M][k]==sha(R/'commons/maps'/M/n),'Current '+k)
check(core[M]['learner_verified'] is False,'Learner verification not asserted')
p='commons/artifacts/registry/algorithms_misc.json';reg=read(R/p);oreg=read(B/p)
check(omit(reg['artifacts'],'bias_from_inside')==omit(oreg['artifacts'],'bias_from_inside'),'Unrelated registry entries retained')
check(omit(reg,'artifacts')==omit(oreg,'artifacts'),'Registry top-level metadata retained')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 now,old=read(R/p),read(B/p)
 check([x for x in now['plans'] if x.get('map')!=M]==[x for x in old['plans'] if x.get('map')!=M],p+': unrelated plan rows retained')
 row=next(x for x in now['plans'] if x.get('map')==M)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all four works retained')
 a=next(a for a in row['artifacts'] if a['token']=='bias_from_inside')
 check(a['cell']==[4,6] and a['rotation']==180 and a['offset'][1]==1.085,p+': placement agrees with map')
check(read(R/'ada_run/em_plan.json')==read(R/'commons/data/museum/em_plan.json'),'Plan mirrors agree')
book=read(R/f'commons/data/book/{S}.json')['pearls'];oldbook=read(B/f'commons/data/book/{S}.json')['pearls']
check([e for e in book if e['map']!=M]==[e for e in oldbook if e['map']!=M],'Other book pearls preserved')
pearl=next(e for e in book if e['map']==M)
check(pearl['hero']=='bias_from_inside','Book hero corrected to primary encounter')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 now,old=read(R/p),read(B/p)
 check([x for x in now['trunk'] if x['node']!=S]==[x for x in old['trunk'] if x['node']!=S],p+': other chapters preserved')
 a,b=[next(x for x in d['trunk'] if x['node']==S) for d in [now,old]]
 check([x for x in a['pearls'] if x['map']!=M]==[x for x in b['pearls'] if x['map']!=M],p+': other hall speech retained')
 e=next(x for x in a['pearls'] if x['map']==M)
 check(e['hero']==pearl['hero'] and e['says']=={l['token']:l['text'] for l in pearl['lines']},p+': primary speech aligned')
r=read(H/(M+'-runtime.json'))
check(r['passed'] and not r['failures'],'Museum probe passes')
check(len(r['checks'])==28 and all(x['ok'] for x in r['checks']),'28 interaction, state and gate checks pass')
check(len(r['walks'])==7 and all(x['passed'] for x in r['walks']),'Seven selected walks pass')
check(len(r['shots'])==6 and all((H/Path(p).name).exists() for p in r['shots']),'Six actual museum captures retained')
check({a['token'] for a in r['artifacts']} & families(m)==families(m),'All four authored works instantiate')
check(r['legacy_endpoint']['handle']>.99 and r['legacy_endpoint']['blend']<.2,'Frozen source reproduces physical/normalized slider mismatch')
a,b=r['captured_states'][:2]
check(a['blend']==0 and b['blend']==1 and b['warm_distance']<a['warm_distance'] and b['grey_distance']>a['grey_distance'],'Image pair records the intended spatial comparison')
log=(H/(M+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,'No script or shader compilation error')
check(read(H/'process-result.json')['exit']==0,'Godot exits 0')
for name in ['final.md','technical.md','critical.md','tutorial.md','map_data.json']:
 rel=Path('commons/maps')/M/name
 (H/(Path(name).stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
rel=Path('commons/artifacts/bias_from_inside/bias_from_inside.gd')
(H/'bias_from_inside.diff').write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8').splitlines(True),(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
inputs={f.relative_to(B).as_posix():{'before':sha(f),'current':sha(R/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (R/f.relative_to(B)).is_file()}
(H/'current-inputs.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8')
failed=[x['message'] for x in checks if not x['ok']]
(H/'content-checks.json').write_text(json.dumps({'count':len(checks),'passed':not failed,'checks':checks,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
