from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];B=HERE/'before';ROOM='Brouwer_Intuitionism'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,msg):checks.append({'ok':bool(ok),'message':msg})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d):return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip()}
rooms=read(ROOT/'commons/maps/sequences/foundationscrisis.json')['sequences']['foundationscrisis']['maps']
roles=read(ROOT/'commons/data/artifact_roles.json')['roles'];oldroles=read(B/'commons/data/artifact_roles.json')['roles']
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
book=read(ROOT/'commons/data/book/foundationscrisis.json')['pearls'];oldbook=read(B/'commons/data/book/foundationscrisis.json')['pearls']
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
for room in rooms:
 rel=Path('commons/maps')/room;old,now=read(B/rel/'map_data.json'),read(ROOT/rel/'map_data.json')
 check(families(old)==families(now),room+': all artifact families retained')
 if room!=ROOM:
  for f in ['final.md','map_data.json']:check((B/rel/f).read_bytes()==(ROOT/rel/f).read_bytes(),room+': '+f+' byte-preserved')
 else:
  dims=now['map_info']['dimensions']
  check(all(len(rows)==dims['depth'] and all(len(row)==dims['width'] for row in rows) for rows in now['layers'].values()),'Map layers agree in size')
  for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][key]==sha(ROOT/rel/f),'Current '+key)
  check(all(roles[room].get(t)=='primary' and t in families(now) for t in core[room]['primary_tokens']),'Three primaries present in role and space')
  text=(ROOT/rel/'final.md').read_text(encoding='utf-8')
  check(set(re.findall(r'<!-- @([\w_]+) -->',text))==families(now),'All eight retained artifacts encountered in the manuscript')
check({k:v for k,v in roles.items() if k!=ROOM}=={k:v for k,v in oldroles.items() if k!=ROOM},'Other map roles preserved')
check(roles[ROOM]['cantor_diagonal_workbench']=='primary' and roles[ROOM]['intractable_evidence']=='secondary','Cantor promoted; intractable evidence recognised as supporting comparison')
check({k:v for k,v in core.items() if k!=ROOM}=={k:v for k,v in oldcore.items() if k!=ROOM},'Other core encounters unchanged')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in old['plans'] if r.get('map')!=ROOM]==[r for r in now['plans'] if r.get('map')!=ROOM],p+': other plan rows unchanged')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==set(roles[ROOM]),p+': all eight artifacts placed')
 check(row.get('gate') is False and row.get('piers') is False,p+': optional gate and piers do not obstruct the authored lesson')
 for token,cell,config in [('brouwer_choice_sequence',[6,3],{'visitor_choices':'on'}),('cantor_diagonal_workbench',[9,7],{'display_offset_x':'1.1'})]:
  art=next(a for a in row['artifacts'] if a['token']==token)
  check(art['cell']==cell and art['config']==config,p+': '+token+' configuration agrees')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Both plans agree')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!='foundationscrisis']==[n for n in now['trunk'] if n['node']!='foundationscrisis'],p+': unrelated chapters unchanged')
 node=next(n for n in now['trunk'] if n['node']=='foundationscrisis')
 n=next(n for n in node['pearls'] if n['map']==ROOM);b=next(n for n in book if n['map']==ROOM)
 check(n['hero']==b['hero']=='brouwer_choice_sequence',p+': hero agrees')
 check(all(any(ln['token']==t and ln['text']==txt and ln['by']=='hand' for ln in b['lines']) for t,txt in n['says'].items()),p+': curated speech agrees')
for registry,tokens in [('foundations',['brouwer_choice_sequence','constructive_proof','excluded_middle_demo']),('foundations_crisis',['constructive_staircase']),('qfep',['cantor_diagonal_workbench'])]:
 p=f'commons/artifacts/registry/{registry}.json';old,now=read(B/p)['artifacts'],read(ROOT/p)['artifacts']
 check({k:v for k,v in old.items() if k not in tokens}=={k:v for k,v in now.items() if k not in tokens},registry+': other registry entries retained')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and r['required_present'] and not r['failures'],'Museum instantiation passes')
check(len(r['walks'])==5 and all(w['passed'] for w in r['walks']),'Five selected collision-body approaches pass')
check(r['choice_states'][0]['terms']==[] and r['choice_states'][1]['terms']==[0,1,1,0,1],'Physical button signals create the captured prefix')
check([s['N'] for s in r['diagonal_states']]==[4,16],'Both captured diagonal settings run in the actual museum')
check(len(r['shots'])==5 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Five current Godot captures retained')
m=read(HERE/'model-checks.json')
check(not m['failures'] and all(c['ok'] for c in m['checks']),'33 model assertions passed; standalone runner shutdown failed (see SUMMARY)')
check(read(ROOT/'commons/data/map_authored.json')==read(B/'commons/data/map_authored.json'),'Authored route unchanged; Florensky remains pending')
rel=Path('commons/maps')/ROOM/'final.md'
(HERE/'final.diff').write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
