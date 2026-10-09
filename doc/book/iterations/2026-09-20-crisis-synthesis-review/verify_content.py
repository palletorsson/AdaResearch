from pathlib import Path
import json,difflib,hashlib,re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];B=HERE/'before';ROOM='Crisis_Synthesis'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,msg):checks.append({'ok':bool(ok),'message':msg})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d):return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip()}
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
book=read(ROOT/'commons/data/book/foundationscrisis.json')['pearls'];oldbook=read(B/'commons/data/book/foundationscrisis.json')['pearls']
seq=read(ROOT/'commons/maps/sequences/foundationscrisis.json')['sequences']['foundationscrisis']
oldseq=read(B/'commons/maps/sequences/foundationscrisis.json')['sequences']['foundationscrisis']
rooms=seq['maps'];primary=['qfep_formula_3d','lambda_slider','phi_slider','bifurcation_diagram','goedel_atrium','russell_paradox_workbench']
check(rooms==oldseq['maps'],'Declared hall order unchanged')
for key in ['prerequisites','unlocks','deferred_maps','completion_rewards']:check(seq[key]==oldseq[key],key+' preserved')
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
for room in rooms:
 rel=Path('commons/maps')/room;old,now=read(B/rel/'map_data.json'),read(ROOT/rel/'map_data.json')
 check(families(old)==families(now),room+': all artifact families retained')
 if room!=ROOM:
  for f in ['final.md','map_data.json']:check((B/rel/f).read_bytes()==(ROOT/rel/f).read_bytes(),room+': '+f+' byte-preserved')
 else:
  check(len(families(now))==10,'All ten synthesis families retained')
  check(all(len(rows)==24 and all(len(row)==19 for row in rows) for rows in now['layers'].values()),'Map layers agree at 19 by 24')
  for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][key]==sha(ROOT/rel/f),'Current '+key)
  check(core[room]['primary_tokens']==primary and roles['order'][ROOM]['primary']==primary and all(roles['roles'][room].get(t)=='primary' and t in families(now) for t in primary),'Primary roles, order and space agree')
  check(set(re.findall(r'<!-- @([\w_]+) -->',(ROOT/rel/'final.md').read_text(encoding='utf-8')))==families(now),'All ten works noticed in manuscript')
  check(core[room]['learner_verified'] is False,'Learner verification remains pending')
for k in ['roles','order']:check({m:v for m,v in roles[k].items() if m!=ROOM}=={m:v for m,v in oldroles[k].items() if m!=ROOM},'Other '+k+' preserved')
check({k:v for k,v in core.items() if k!=ROOM}=={k:v for k,v in oldcore.items() if k!=ROOM},'Other core encounters retained')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in old['plans'] if r.get('map')!=ROOM]==[r for r in now['plans'] if r.get('map')!=ROOM],p+': other plan rows unchanged')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='foundationscrisis']==rooms,p+': all eight halls in order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==set(roles['roles'][ROOM]),p+': all ten artifacts placed')
 for token,config in [('qfep_formula_3d',{'reading_study':'on'}),('bifurcation_diagram',{'visitor_control':'on','current_r':'3.2'}),('goedel_atrium',{'room_size':'6'})]:
  check(next(a for a in row['artifacts'] if a['token']==token)['config']==config,p+': '+token+' config agrees')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Both plans agree')
check(read(ROOT/'commons/data/map_authored.json')==read(B/'commons/data/map_authored.json'),'Authored membership unchanged; all eight halls already present')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!='foundationscrisis']==[n for n in now['trunk'] if n['node']!='foundationscrisis'],p+': unrelated chapters retained')
 node=next(n for n in now['trunk'] if n['node']=='foundationscrisis')
 n=next(n for n in node['pearls'] if n['map']==ROOM);b=next(n for n in book if n['map']==ROOM)
 check(n['hero']==b['hero']=='qfep_formula_3d',p+': hero agrees')
 check(all(any(ln['token']==t and ln['text']==txt and ln['by']=='hand' for ln in b['lines']) for t,txt in n['says'].items()),p+': hand-authored speech agrees')
for registry,tokens in [('qfep',['qfep_formula_3d','lambda_slider','phi_slider']),('foundations',['bifurcation_diagram']),('concept_architecture',['goedel_atrium'])]:
 p=f'commons/artifacts/registry/{registry}.json';old,now=read(B/p)['artifacts'],read(ROOT/p)['artifacts']
 check({k:v for k,v in old.items() if k not in tokens}=={k:v for k,v in now.items() if k not in tokens},registry+': unrelated entries preserved')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and r['required_present'] and not r['failures'],'Actual museum instantiation passes')
check(len(r['walks'])==6 and all(w['passed'] for w in r['walks']),'Six selected collision-body walks pass')
check(len(r['checks'])==25 and all(c['ok'] for c in r['checks']),'25 interaction and numerical assertions pass')
check(len(r['shots'])==6 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Six actual Godot images retained')
check('every 2' in r['captured_states'][2]['logistic'] and 'every 3' in r['captured_states'][3]['logistic'],'Paired recurrence images match selected sample periods')
check('lambda 0.15' in r['captured_states'][0]['formula'] and 'phi +0.80' in r['captured_states'][1]['formula'],'Formula image pair matches input values')
check(not any(a['token']=='dream_bodies' for a in r['artifacts']),'Automatic sculpture excluded from this hall')
for name in ['final.md','technical.md','critical.md']:
 rel=Path('commons/maps')/ROOM/name
 (HERE/(name.replace('.md','')+'.diff')).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))

