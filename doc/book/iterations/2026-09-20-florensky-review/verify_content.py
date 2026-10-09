from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];B=HERE/'before';ROOM='Florensky_Paraconsistent'
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
  check(all(len(rows)==dims['depth'] and all(len(row)==dims['width'] for row in rows) for rows in now['layers'].values()),'All map layers agree at 13 by 16')
  for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][key]==sha(ROOT/rel/f),'Current '+key)
  check(core[room]['primary_tokens']==['both_true_gate','florensky_sphere'] and all(roles[room].get(t)=='primary' and t in families(now) for t in core[room]['primary_tokens']),'Both primaries agree in role, order and space')
  check(set(re.findall(r'<!-- @([\w_]+) -->',(ROOT/rel/'final.md').read_text(encoding='utf-8')))==families(now),'All four retained artifacts encountered in manuscript')
  check(now['map_info']['museum']['props_deny']==['dream_bodies'],'Automatic sculpture excluded only in this hall to keep exit approach clear')
check({k:v for k,v in roles.items() if k!=ROOM}=={k:v for k,v in oldroles.items() if k!=ROOM},'Other map roles preserved')
check({k:v for k,v in core.items() if k!=ROOM}=={k:v for k,v in oldcore.items() if k!=ROOM},'Other core encounters unchanged')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in old['plans'] if r.get('map')!=ROOM]==[r for r in now['plans'] if r.get('map')!=ROOM],p+': other plan rows unchanged')
 ordered=[r['map'] for r in now['plans'] if r.get('sequence')=='foundationscrisis']
 check(ordered==rooms,p+': all eight halls in declared order, one each')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==set(roles[ROOM]),p+': all four artifacts placed')
 check(row.get('gate') is False and row.get('piers') is False,p+': optional template obstacles omitted')
 for token,cell,config in [('both_true_gate',[6,4],{'report_controls':'on'}),('florensky_sphere',[6,8],{'hold_both':'on'})]:
  art=next(a for a in row['artifacts'] if a['token']==token)
  check(art['cell']==cell and art['config']==config,p+': '+token+' configuration agrees')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Both plans agree')
old,now=read(B/'commons/data/map_authored.json'),read(ROOT/'commons/data/map_authored.json')
check(now['foundationscrisis']==rooms,'All eight halls authored in sequence order')
check({k:v for k,v in old.items() if k!='foundationscrisis'}=={k:v for k,v in now.items() if k!='foundationscrisis'},'Other authored sequences preserved')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!='foundationscrisis']==[n for n in now['trunk'] if n['node']!='foundationscrisis'],p+': unrelated chapters unchanged')
 node=next(n for n in now['trunk'] if n['node']=='foundationscrisis')
 n=next(n for n in node['pearls'] if n['map']==ROOM);b=next(n for n in book if n['map']==ROOM)
 check(n['hero']==b['hero']=='both_true_gate',p+': hero agrees')
 check(all(any(ln['token']==t and ln['text']==txt and ln['by']=='hand' for ln in b['lines']) for t,txt in n['says'].items()),p+': curated speech agrees')
for registry,tokens in [('foundations',['florensky_sphere','schrodinger_box']),('foundations_crisis',['both_true_gate']),('quantumalgorithms',['superposition_display'])]:
 p=f'commons/artifacts/registry/{registry}.json';old,now=read(B/p)['artifacts'],read(ROOT/p)['artifacts']
 check({k:v for k,v in old.items() if k not in tokens}=={k:v for k,v in now.items() if k not in tokens},registry+': other registry entries retained')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and r['required_present'] and not r['failures'],'Actual museum instantiation passes')
check(len(r['walks'])==6 and all(w['passed'] for w in r['walks']),'Six selected collision-body walks pass')
check(len(r['checks'])==24 and all(c['ok'] for c in r['checks']),'24 behavior and geometry assertions pass in actual museum process')
check(r['captured_states'][0]['reports']=={'P':True,'not_P':True,'Q':False} and r['captured_states'][1]['reports']=={'P':True,'not_P':False,'Q':False},'Paired images show both and single report states')
check(len(r['shots'])==5 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Five current Godot captures retained')
check(not any(a['token']=='dream_bodies' for a in r['artifacts']),'Runtime does not auto-place the sculpture that obstructed the exit approach')
check('BOTH REPORTS' in r['captured_states'][2]['caption'],'Console carries current report state')
rel=Path('commons/maps')/ROOM/'final.md'
(HERE/'final.diff').write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
