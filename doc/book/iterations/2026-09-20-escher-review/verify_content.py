from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='Escher_Impossible'
checks=[]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,msg): checks.append({'ok':bool(ok),'message':msg})
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d): return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip()}

rooms=read(ROOT/'commons/maps/sequences/foundationscrisis.json')['sequences']['foundationscrisis']['maps']
roles=read(ROOT/'commons/data/artifact_roles.json')['roles']
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms']
book=read(ROOT/'commons/data/book/foundationscrisis.json')['pearls']
oldbook=read(B/'commons/data/book/foundationscrisis.json')['pearls']
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
for room in rooms:
 rel=Path('commons/maps')/room
 old,now=read(B/rel/'map_data.json'),read(ROOT/rel/'map_data.json')
 check(families(old)==families(now),room+': all existing artifact families retained')
 if room!=ROOM:
  for file in ['final.md','map_data.json']:
   check((B/rel/file).read_bytes()==(ROOT/rel/file).read_bytes(),room+': '+file+' byte-preserved')
 else:
  dims=now['map_info']['dimensions']
  check(all(len(rows)==dims['depth'] and all(len(row)==dims['width'] for row in rows) for rows in now['layers'].values()),'Escher map is rectangular')
  for k,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
   check(core[room][k]==sha(ROOT/rel/f),'Current '+k)
  check(all(roles[room].get(t)=='primary' and t in families(now) for t in core[room]['primary_tokens']),'Both primaries remain present')
  text=(ROOT/rel/'final.md').read_text(encoding='utf-8')
  check(set(re.findall(r'<!-- @([\w_]+) -->',text))==families(now),'All four retained artifacts are encountered in the manuscript')
  check('paradox_completed' not in text and 'no local inspection' not in text,'Manuscript no longer mistakes a marker circuit for a theorem')

check(roles==read(B/'commons/data/artifact_roles.json')['roles'],'Existing primary and secondary roles preserved')
oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check({k:v for k,v in core.items() if k!=ROOM}=={k:v for k,v in oldcore.items() if k!=ROOM},'Other core encounters unchanged')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in old['plans'] if r.get('map')!=ROOM]==[r for r in now['plans'] if r.get('map')!=ROOM],p+': other plan rows unchanged')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 for token,cell,config in [('escher_staircase',[6,3],{'lesson_controls':'on'}),('penrose_triangle',[3,7],{'track_viewer':'on'})]:
  art=next(a for a in row['artifacts'] if a['token']==token)
  check(art['cell']==cell and art['config']==config,p+': '+token+' placement and configuration agree')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Both plans agree')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!='foundationscrisis']==[n for n in now['trunk'] if n['node']!='foundationscrisis'],p+': unrelated chapters unchanged')
 node=next(n for n in now['trunk'] if n['node']=='foundationscrisis')
 n=next(n for n in node['pearls'] if n['map']==ROOM);b=next(n for n in book if n['map']==ROOM)
 check(n['hero']==b['hero'] and n['hero'] in core[ROOM]['primary_tokens'],p+': hero agrees')
 check(all(any(ln['token']==t and ln['text']==txt and ln['by']=='hand' for ln in b['lines']) for t,txt in n['says'].items()),p+': curated speech agrees')
p='commons/artifacts/registry/foundations.json';old,now=read(B/p)['artifacts'],read(ROOT/p)['artifacts'];tokens=['escher_staircase','penrose_triangle']
check({k:v for k,v in old.items() if k not in tokens}=={k:v for k,v in now.items() if k not in tokens},'Other registry entries retained')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and r['required_present'] and not r['failures'],'Museum instantiation passes')
check(len(r['walks'])==5 and all(w['passed'] for w in r['walks']),'Five selected collision-body approaches pass')
states=r['study_states']
check(all(abs(s['up']-s['down'])<0.00001 for s in states[:2]),'Closed museum models return equal measured ascent and descent')
check(states[2]['down']==0 and 'CUT END' in states[2]['display'],'Museum open run stops without a fabricated return')
check(len(r['shots'])==6 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Six actual Godot museum captures retained')
m=read(HERE/'model-checks.json')
check(not m['failures'] and all(c['ok'] for c in m['checks']),'Physical control, height, visible marker and camera-projection checks pass')
check(read(ROOT/'commons/data/map_authored.json')==read(B/'commons/data/map_authored.json'),'Authored route unchanged; Florensky still pending')
rel=Path('commons/maps')/ROOM/'final.md'
diff=difflib.unified_diff((B/rel).read_text(encoding='utf-8').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())
(HERE/'final.diff').write_text(''.join(diff),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed,'model_checks':len(m['checks'])}));raise SystemExit(bool(failed))
