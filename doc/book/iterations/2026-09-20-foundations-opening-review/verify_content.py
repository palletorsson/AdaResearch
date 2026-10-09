from pathlib import Path
import hashlib,json,difflib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BEFORE=HERE/'before'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,message):checks.append({'passed':bool(ok),'check':message})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def families(d):return {c.split('#')[0].split(':')[0] for r in d['layers']['interactables'] for c in r if c.strip()}
name='foundationscrisis'
rooms=read(ROOT/f'commons/maps/sequences/{name}.json')['sequences'][name]['maps']
focus=rooms[:2]
active=[r for r in rooms if r!='Florensky_Paraconsistent']
check(read(ROOT/'commons/data/map_authored.json')[name]==active,'Euclid restored before NonEuclidean; Florensky remains explicitly pending')
check((ROOT/f'commons/maps/sequences/{name}.json').read_bytes()==(BEFORE/f'commons/maps/sequences/{name}.json').read_bytes(),'Declared eight-hall order preserved')
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(BEFORE/p),read(ROOT/p)
 rows=[r for r in now['plans'] if r.get('sequence')==name]
 check([r['map'] for r in rows]==active,p+': current authored order')
 check([r['pearl_index'] for r in rows]==[0,1,2,3,4,5,7],p+': declared indices, with missing hall visible')
 check([r for r in old['plans'] if r.get('sequence')!=name]==[r for r in now['plans'] if r.get('sequence')!=name],p+': unrelated plans preserved')
 strip=lambda r:{k:v for k,v in r.items() if k not in ('pearl_index','pearls_total')}
 check([strip(r) for r in old['plans'] if r.get('sequence')==name and r['map'] not in focus]==[strip(r) for r in rows if r['map'] not in focus],p+': other geometry and placements preserved')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Local and shipped plans agree')
for p,key in [('commons/data/long_museum.json','segments'),('commons/data/museum_order_effective.json','halls')]:
 got=[r['name'] for r in read(ROOT/p)[key] if r.get('sequence')==name and r.get('kind','hall')=='hall']
 check(got==active,p+': derived authored route current')
roles=read(ROOT/'commons/data/artifact_roles.json')['roles']
oldroles=read(BEFORE/'commons/data/artifact_roles.json')['roles']
expected=json.loads(json.dumps(oldroles));expected['Euclid_Parallel']['angle_sum_triangle']='primary'
check(roles==expected,'Only triangle foil promoted; all other roles retained')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms']
book=read(ROOT/f'commons/data/book/{name}.json')['pearls']
oldbook=read(BEFORE/f'commons/data/book/{name}.json')['pearls']
check([p for p in book if p['map'] not in focus]==[p for p in oldbook if p['map'] not in focus],'Other book records retained')
diff=[]
for room in rooms:
 rel=Path('commons/maps')/room
 for f in ['map_data.json','final.md']:
  if room not in focus:check((ROOT/rel/f).read_bytes()==(BEFORE/rel/f).read_bytes(),room+': '+f+' byte-preserved')
 old,now=read(BEFORE/rel/'map_data.json'),read(ROOT/rel/'map_data.json')
 check(families(old)==families(now),room+': every artifact family retained')
 if room in focus:
  for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][key]==sha(ROOT/rel/f),room+': current '+key)
  primary=core[room]['primary_tokens']
  check(all(roles[room].get(t)=='primary' and t in families(now) for t in primary),room+': placed primary encounters agree')
  hero=next(p['hero'] for p in book if p['map']==room)
  check(hero in primary,room+': book hero matches primary encounter')
  size=now['map_info']['dimensions'];check(all(len(rows)==size['depth'] and all(len(row)==size['width'] for row in rows) for rows in now['layers'].values()),room+': rectangular map layers')
  oldtext=(BEFORE/rel/'final.md').read_text(encoding='utf-8');newtext=(ROOT/rel/'final.md').read_text(encoding='utf-8')
  check('\ufffd' not in newtext,room+': no encoding replacement')
  diff.extend(difflib.unified_diff(oldtext.splitlines(True),newtext.splitlines(True),fromfile='before/'+str(rel/'final.md'),tofile=str(rel/'final.md')))
  runtime=read(HERE/(room+'-runtime.json'))
  check(runtime['passed'] and runtime['required_present'] and not runtime['failures'],room+': primary instantiated and selected walks pass')
check([r['display'] for r in read(HERE/'NonEuclidean_Spaces-runtime.json')['model_states']]==['α+β+γ = 180.0°\nPLANE · straight segments','α+β+γ = 202.1°\nSPHERE · excess +22.1°','α+β+γ = 103.1°\nDISK · deficit 76.9°'],'Actual museum repeats all three measured states')
for p,key in [('alternative_geometries','triangle_curvature_workbench'),('foundations','euclid_postulates_plaque')]:
 rel=f'commons/artifacts/registry/{p}.json';old,now=read(BEFORE/rel),read(ROOT/rel)
 check({k:v for k,v in old['artifacts'].items() if k!=key}=={k:v for k,v in now['artifacts'].items() if k!=key},p+': unrelated registry entries retained')
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(BEFORE/p),read(ROOT/p)
 check([n for n in old['trunk'] if n['node']!=name]==[n for n in now['trunk'] if n['node']!=name],p+': other sequences untouched')
 oldnode=next(n for n in old['trunk'] if n['node']==name);node=next(n for n in now['trunk'] if n['node']==name)
 check([r for r in oldnode['pearls'] if r.get('map') not in focus]==[r for r in node['pearls'] if r.get('map') not in focus],p+': other pearls untouched')
 for room in focus:
  b=next(r for r in book if r['map']==room);n=next(r for r in node['pearls'] if r['map']==room)
  check(n['says']=={r['token']:r['text'] for r in b['lines']},p+': wall speech agrees for '+room)
for file in ['model-checks.json','navigation.json']:
 d=read(HERE/file);check(not d['failures'] and all(c['ok'] for c in d['checks']),file+': checks pass')
frozen=read(HERE/'before-sha256.json')
check(all(sha(BEFORE/p)==digest for p,digest in frozen.items()),'Frozen before-files preserved')
(HERE/'current-inputs.json').write_text(json.dumps({p:{'before':h,'current':sha(ROOT/p)} for p,h in frozen.items()},indent=2)+'\n',encoding='utf-8')
(HERE/'final.diff').write_text(''.join(diff),encoding='utf-8')
failed=[c['check'] for c in checks if not c['passed']]
(HERE/'content-checks.json').write_text(json.dumps({'checks':checks,'count':len(checks),'failures':failed,'passed':not failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}))
raise SystemExit(bool(failed))
