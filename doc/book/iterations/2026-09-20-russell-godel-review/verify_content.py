from pathlib import Path
import json,hashlib,difflib
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];B=HERE/'before'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,msg):checks.append({'ok':bool(ok),'message':msg})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d):return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip()}
rooms=read(ROOT/'commons/maps/sequences/foundationscrisis.json')['sequences']['foundationscrisis']['maps']
focus=['Russell_Paradox','Godel_Incompleteness']
roles=read(ROOT/'commons/data/artifact_roles.json')['roles'];core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms']
book=read(ROOT/'commons/data/book/foundationscrisis.json')['pearls']
oldbook=read(B/'commons/data/book/foundationscrisis.json')['pearls']
check([x for x in book if x['map'] not in focus]==[x for x in oldbook if x['map'] not in focus],'Other book pearls retained')
diff=[]
for room in rooms:
 rel=Path('commons/maps')/room
 old,now=read(B/rel/'map_data.json'),read(ROOT/rel/'map_data.json')
 check(families(old)<=families(now),room+': all earlier artifact families retained')
 for file in ['final.md','map_data.json']:
  if room!='Russell_Paradox':check((B/rel/file).read_bytes()==(ROOT/rel/file).read_bytes(),room+': '+file+' byte-preserved')
 if room in focus:
  for key,file in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][key]==sha(ROOT/rel/file),room+': current '+key)
  check(all(roles[room].get(t)=='primary' and t in families(now) for t in core[room]['primary_tokens']),room+': primary roles are present in map')
  check(next(p['hero'] for p in book if p['map']==room) in core[room]['primary_tokens'],room+': book hero agrees')
  runtime=read(HERE/(room+'-runtime.json'))
  check(runtime['passed'] and runtime['required_present'],room+': museum instantiation and declared checks pass')
  dims=now['map_info']['dimensions'];check(all(len(rows)==dims['depth'] and all(len(row)==dims['width'] for row in rows) for rows in now['layers'].values()),room+': rectangular map')
  diff.extend(difflib.unified_diff((B/rel/'final.md').read_text(encoding='utf-8').splitlines(True),(ROOT/rel/'final.md').read_text(encoding='utf-8').splitlines(True),fromfile='before/'+(rel/'final.md').as_posix(),tofile=(rel/'final.md').as_posix()))
oldroles=read(B/'commons/data/artifact_roles.json')['roles'];oldroles['Russell_Paradox'].update(russell_paradox_workbench='primary',hilbert_hotel='primary')
check(roles==oldroles,'Only membership workbench and hotel added/promoted')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in old['plans'] if r.get('map')!='Russell_Paradox']==[r for r in now['plans'] if r.get('map')!='Russell_Paradox'],p+': all other plan rows unchanged')
 row=next(r for r in now['plans'] if r.get('map')=='Russell_Paradox');bench=next(a for a in row['artifacts'] if a['token']=='russell_paradox_workbench')
 check(bench['cell']==[6,3] and bench['config']=={'membership_controls':'on','initial_cell':'5'},p+': new primary placement and configuration current')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Both plans agree')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!='foundationscrisis']==[n for n in now['trunk'] if n['node']!='foundationscrisis'],p+': unrelated chapters unchanged')
 node=next(n for n in now['trunk'] if n['node']=='foundationscrisis')
 for room in focus:
  n=next(n for n in node['pearls'] if n['map']==room);b=next(n for n in book if n['map']==room)
  check(n['hero']==b['hero'],p+': '+room+' hero agrees')
  check(all(any(ln['token']==t and ln['text']==txt and ln['by']=='hand' for ln in b['lines']) for t,txt in n['says'].items()),p+': '+room+' curated speech agrees')
for reg,tokens in [('qfep',['russell_paradox_workbench']),('foundations_crisis',['godel_sentence_machine','provability_sorter'])]:
 p=f'commons/artifacts/registry/{reg}.json';old,now=read(B/p)['artifacts'],read(ROOT/p)['artifacts']
 check({k:v for k,v in old.items() if k not in tokens}=={k:v for k,v in now.items() if k not in tokens},reg+': unrelated registry entries retained')
runtime=read(HERE/'Russell_Paradox-runtime.json');check(len(runtime['walks'])==3 and all(w['passed'] for w in runtime['walks']),'Three selected collision-body approaches pass')
check([r['result']['agrees'] for r in runtime['membership_states']]==[False,True],'Actual museum repeats contradiction and restricted agreement')
m=read(HERE/'model-checks.json');check(not m['failures'] and all(c['ok'] for c in m['checks']),'Model and physical-control signal checks pass')
check(read(ROOT/'commons/data/map_authored.json')==read(B/'commons/data/map_authored.json'),'Authored route unchanged; Florensky still pending')
(HERE/'final.diff').write_text(''.join(diff),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and f.name!='.gdignore'},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
