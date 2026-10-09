from pathlib import Path
import json, hashlib, difflib, re
from collections import Counter

H=Path(__file__).resolve().parent
R=H.parents[3]
B=H/'before'
M='SpeculativeComputation_Rhizome_Network'
A='rhizome_grower'
S='postfoundationscrisis'
checks=[]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,msg): checks.append(dict(ok=bool(ok),message=msg))
def omit(d,*keys): return {k:v for k,v in d.items() if k not in keys}
def placements(d):
 return [(x,z,c.strip()) for z,row in enumerate(d['layers']['interactables']) for x,c in enumerate(row) if c.strip()]
def families(d): return {c.split(':')[0].split('#')[0] for x,z,c in placements(d)}

p=f'commons/maps/sequences/{S}.json'
check((R/p).read_bytes()==(B/p).read_bytes(),'Sequence and learning order retained')
for room in read(R/p)['sequences'][S]['maps']:
 rel=Path('commons/maps')/room
 check(families(read(R/rel/'map_data.json'))==families(read(B/rel/'map_data.json')),room+': every family retained')
 if room!=M:
  for n in ['map_data.json','final.md']:
   check((R/rel/n).read_bytes()==(B/rel/n).read_bytes(),room+': '+n+' byte-preserved')
m,old=[read(p/'commons/maps'/M/'map_data.json') for p in [R,B]]
check(all(len(rows)==12 and all(len(row)==13 for row in rows) for rows in m['layers'].values()),'All layers agree at 13 by 12')
check(len(placements(m))==2 and families(m)=={A,'rhizome_cave_demo'},'Both placements and families retained')
check([p for p in placements(m) if not p[2].startswith(A)]==[p for p in placements(old) if not p[2].startswith(A)],'Cave retains its exact cell and token')
for layer,cells in [('structure',[(5,5),(6,5),(5,6),(6,6)]),('utilities',[(1,1),(6,1)])]:
 changed=[(x,z) for z,row in enumerate(m['layers'][layer]) for x,c in enumerate(row) if c!=old['layers'][layer][z][x]]
 check(changed==cells,'Only intended cells change in '+layer)
check(all(m['layers']['structure'][z][x]=='1' for x,z in [(5,5),(6,5),(5,6),(6,6)]),'Central platform becomes floor for full-size exhibit')
check(m['layers']['utilities'][1][6]=='s','Arrival spawn declared')
check(m['map_info']['museum']['sculpture_clear_rects']==[[3,3,7,10]],'Dressing exclusion covers the encounter and exit approach')
check(m['layers']['interactables'][5][5]==A+':180:0:1#interactive:true#spread:0.85#grow_period:0.8#sample_seed:47','Primary cell retained with arrival-facing controls')
for p in ['commons/data/artifact_roles.json','commons/data/map_authored.json']:
 check((R/p).read_bytes()==(B/p).read_bytes(),p+': retained')
check(read(R/'commons/data/artifact_roles.json')['order'][M]['primary']==[A],'Primary role agrees with manuscript')
text=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
oldtext=(B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==[A],'Primary anchor retained')
for start in ['# Growing','Can local','Watch for','The neighbour search','No vertex','The rule still','The peer-production','The assembly laboratory']:
 para=next(p for p in oldtext.split('\n\n') if p.startswith(start))
 check(para in text,'Retained passage: '+start)
code=re.search(r'```gdscript\n(.*?)```',oldtext,re.S).group(1)
check(code in text,'Existing code excerpt retained')
script=(R/'commons/artifacts'/A/(A+'.gd')).read_text(encoding='utf-8').replace('\t','    ')
check(code.rstrip() in '\n'.join(line[4:] if line.startswith('    ') else line for line in script.splitlines()),'Book excerpt occurs in implementation')
check(all(s in text for s in ['GROW','STEP','LINKS','NODE','CUT','REPLAY']),'Book names actual controls')
check('A future variant' in text and 'Repair still needs a rule.' in text,'Distant links and repair are not claimed as implemented')
p='commons/data/museum_core_encounters.json'
now,prev=[read(root/p)['rooms'] for root in [R,B]]
check(omit(now,M)==omit(prev,M),'Other core encounters retained')
for key,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
 check(now[M][key]==sha(R/'commons/maps'/M/n),'Current '+key)
check(now[M]['learner_verified'] is False,'Learner verification not asserted')
p='commons/artifacts/registry/postfoundations_crisis.json'
now,prev=[read(root/p) for root in [R,B]]
check(omit(now['artifacts'],A)==omit(prev['artifacts'],A),'Other registry entries retained')
check(omit(now,'artifacts')==omit(prev,'artifacts'),'Registry metadata retained')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 now,prev=[read(root/p) for root in [R,B]]
 check([v for v in now['plans'] if v.get('map')!=M]==[v for v in prev['plans'] if v.get('map')!=M],p+': other rooms retained')
 row=next(v for v in now['plans'] if v.get('map')==M)
 check(Counter(v['token'] for v in row['artifacts'])==Counter({A:1,'rhizome_cave_demo':1}),p+': both artifacts retained')
 e=next(v for v in row['artifacts'] if v['token']==A)
 check(e['cell']==[5,5] and e['rotation']==180 and e['config']['interactive']=='true',p+': primary agrees with map')
check(read(R/'ada_run/em_plan.json')==read(R/'commons/data/museum/em_plan.json'),'Plan mirrors agree')
p=f'commons/data/book/{S}.json'
now,prev=[read(root/p)['pearls'] for root in [R,B]]
check([v for v in now if v['map']!=M]==[v for v in prev if v['map']!=M],'Other book pearls retained')
pearl=next(v for v in now if v['map']==M)
check(pearl['hero']==A,'Book hero agrees with primary')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 now,prev=[read(root/p) for root in [R,B]]
 check([v for v in now['trunk'] if v['node']!=S]==[v for v in prev['trunk'] if v['node']!=S],p+': other chapters retained')
 a,b=[next(v for v in d['trunk'] if v['node']==S) for d in [now,prev]]
 check([v for v in a['pearls'] if v['map']!=M]==[v for v in b['pearls'] if v['map']!=M],p+': other halls retained')
 check([v for v in now['hand_pearls'][S] if v['map']!=M]==[v for v in prev['hand_pearls'][S] if v['map']!=M],p+': other hand overrides retained')
 e=next(v for v in a['pearls'] if v['map']==M)
 check(e['hero']==A and e['says']=={v['token']:v['text'] for v in pearl['lines']},p+': book speech aligned')
r=read(H/(M+'-runtime.json'))
check(r['passed'] and not r['failures'],'Museum probe passes')
check(len(r['checks'])==36 and all(v['ok'] for v in r['checks']),'36 interaction and gate checks pass')
check(len(r['walks'])==7 and all(v['passed'] for v in r['walks']),'Seven selected walking segments pass')
check(len(r['shots'])==6 and all((H/Path(p).name).exists() for p in r['shots']),'Six captures retained')
check(families(m)<={v['token'] for v in r['artifacts']},'Both authored artifacts instantiate in museum')
states=r['captured_states']
check(all(v['positions']==states[0]['positions'] for v in states[:5]),'Same positions across all four graph comparisons and side view')
check([v['counts'] for v in states]==[[24,24,22,2,1],[24,23,19,4,1],[24,24,65,1,3],[24,23,57,1,3],[24,24,65,1,3],[2,2,0,2,3]],'Captured graph and removal counts match reported comparison')
check(all(v['selected']==2 for v in states[:5]),'Same selected node across comparison')
log=(H/(M+'-engine.log')).read_text(encoding='utf-8',errors='replace')
check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,'No script or shader compilation errors')
check(read(H/'process-result.json')['exit']==0,'Godot exits 0')
rels=[Path('commons/maps')/M/n for n in ['final.md','technical.md','critical.md','tutorial.md','summary.md','blurb.md','map_data.json']]+[Path('commons/artifacts')/A/(A+'.gd')]
for rel in rels:
 (H/(rel.stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(R/rel).read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
inputs={f.relative_to(B).as_posix():{'before':sha(f),'current':sha(R/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (R/f.relative_to(B)).is_file()}
(H/'current-inputs.json').write_text(json.dumps(inputs,indent=2)+'\n',encoding='utf-8')
failed=[v['message'] for v in checks if not v['ok']]
(H/'content-checks.json').write_text(json.dumps(dict(count=len(checks),passed=not failed,checks=checks,failures=failed),indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(checks=len(checks),failures=failed)))
raise SystemExit(bool(failed))
