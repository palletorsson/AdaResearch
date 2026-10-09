from pathlib import Path
import json, hashlib, difflib, re

H=Path(__file__).resolve().parent;R=H.parents[3];B=H/'before'
rooms=['AdvancedLaboratory_Lab_Equipment_Simulation','PostCrisis_Synthesis']
heroes=['MolecularDesigner','accountability_ledger'];checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,msg):checks.append({'ok':bool(ok),'message':msg})
def families(m):return {s.split(':')[0].split('#')[0] for row in m['layers']['interactables'] for s in row if s.strip()}
seq='commons/maps/sequences/postfoundationscrisis.json'
check((R/seq).read_bytes()==(B/seq).read_bytes(),'Sequence order preserved')
for m in read(R/seq)['sequences']['postfoundationscrisis']['maps']:
 rel=Path('commons/maps')/m
 check(families(read(R/rel/'map_data.json'))==families(read(B/rel/'map_data.json')),m+': every artifact family retained')
 if m not in rooms:
  for n in ['map_data.json','final.md']:check((R/rel/n).read_bytes()==(B/rel/n).read_bytes(),m+': '+n+' unchanged')
roles=read(R/'commons/data/artifact_roles.json')
core=read(R/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check({k:v for k,v in core.items() if k not in rooms}=={k:v for k,v in oldcore.items() if k not in rooms},'Other encounter records preserved')
check((R/'commons/data/artifact_roles.json').read_bytes()==(B/'commons/data/artifact_roles.json').read_bytes(),'Role declarations preserved')
book=read(R/'commons/data/book/postfoundationscrisis.json')['pearls'];oldbook=read(B/'commons/data/book/postfoundationscrisis.json')['pearls']
check([v for v in book if v['map'] not in rooms]==[v for v in oldbook if v['map'] not in rooms],'Other book pearls preserved')
for m,hero in zip(rooms,heroes):
 rel=Path('commons/maps')/m;data=read(R/rel/'map_data.json');dim=data['map_info']['dimensions'];text=(R/rel/'final.md').read_text(encoding='utf-8')
 check(all(len(rows)==dim['depth'] and all(len(row)==dim['width'] for row in rows) for rows in data['layers'].values()),m+': all layer dimensions agree')
 check(any('s' in row for row in data['layers']['utilities']),m+': explicit spawn')
 check(re.findall(r'<!-- @([\w_]+) -->',text)==[hero] and roles['order'][m]['primary']==[hero],m+': book anchor and primary agree')
 check(next(v for v in book if v['map']==m)['hero']==hero,m+': book hero agrees')
 for key,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[m][key]==sha(R/rel/n),m+': '+key+' current')
 check(core[m]['learner_verified'] is False,m+': learner verification not asserted')
 runtime=read(H/(m+'-runtime.json'))
 check(runtime['passed'] and not runtime['failures'] and all(v['ok'] for v in runtime['checks']),m+': runtime checks pass')
 check(len(runtime['walks'])==7 and all(v['passed'] for v in runtime['walks']),m+': seven selected walking segments pass')
 check(len(runtime['shots'])==3 and all((H/Path(v).name).exists() for v in runtime['shots']),m+': three captures retained')
 check(hero in {v['token'] for v in runtime['artifacts']},m+': primary instantiates')
 log=(H/(m+'-process.log')).read_text(encoding='utf-8',errors='replace')
 check('SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,m+': no script or shader errors')
 check(read(H/(m+'-exit.json'))['exit']==0,m+': Godot exits 0')
 for n in ['final.md','technical.md','critical.md','tutorial.md','summary.md','blurb.md','map_data.json']:
  out=H/m/(Path(n).stem+'.diff');out.parent.mkdir(exist_ok=True)
  out.write_text(''.join(difflib.unified_diff((B/rel/n).read_text(encoding='utf-8').splitlines(True),(R/rel/n).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+(rel/n).as_posix(),tofile=(rel/n).as_posix())),encoding='utf-8')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 now,old=[read(root/p) for root in [R,B]]
 check([v for v in now['plans'] if v.get('map') not in rooms]==[v for v in old['plans'] if v.get('map') not in rooms],p+': other plans preserved')
 for m,hero in zip(rooms,heroes):
  row=next(v for v in now['plans'] if v.get('map')==m)
  check(any(v['token']==hero for v in row['artifacts']),m+': planned primary retained')
check(read(R/'ada_run/em_plan.json')==read(R/'commons/data/museum/em_plan.json'),'Plan mirrors agree')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 now,old=[read(root/p) for root in [R,B]]
 check([v for v in now['trunk'] if v['node']!='postfoundationscrisis']==[v for v in old['trunk'] if v['node']!='postfoundationscrisis'],p+': other chapters preserved')
 for m,hero in zip(rooms,heroes):
  chap=next(v for v in now['trunk'] if v['node']=='postfoundationscrisis'); pearl=next(v for v in chap['pearls'] if v['map']==m)
  check(pearl['hero']==hero and pearl['says']=={v['token']:v['text'] for v in next(v for v in book if v['map']==m)['lines']},m+': trunk speech aligned')
sourcepaths=['algorithms/computationalbiology/molecular_framework/MolecularDesigner.gd','algorithms/computationalbiology/molecular_framework/Part.gd','commons/artifacts/accountability_ledger/accountability_ledger.gd']
for rel in sourcepaths:
 (H/(Path(rel).stem+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8').splitlines(True),(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
check('The clock is still running. There is something you wanted to make.' in (R/'commons/maps/PostCrisis_Synthesis/final.md').read_text(encoding='utf-8'),'Ending returns to clock and desire')
failures=[v['message'] for v in checks if not v['ok']]
(H/'content-checks.json').write_text(json.dumps({'count':len(checks),'passed':not failures,'checks':checks,'failures':failures},indent=2)+'\n',encoding='utf-8')
(H/'current-inputs.json').write_text(json.dumps({p.relative_to(B).as_posix():{'before':sha(p),'current':sha(R/p.relative_to(B))} for p in B.rglob('*') if p.is_file() and (R/p.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failures}));raise SystemExit(bool(failures))
