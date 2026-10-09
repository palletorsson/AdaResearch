from pathlib import Path
import hashlib, json, re
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ROOM='SoftBodies_Playground_of_Joy'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def check(value,label):
 checks.append({'check':label,'passed':bool(value)})
 if not value:print('FAIL',label)
def diff(a,b,path=''):
 if type(a)!=type(b):return [path]
 if isinstance(a,dict):
  return [p for k in a.keys()|b.keys() for p in ([path+'/'+k] if k not in a or k not in b else diff(a[k],b[k],path+'/'+k))]
 if isinstance(a,list):
  if len(a)!=len(b):return [path+'(length)']
  return [p for i,(x,y) in enumerate(zip(a,b)) for p in diff(x,y,path+'/'+str(i))]
 return [] if a==b else [path]
seq=read(ROOT/'commons/maps/sequences/softbodies.json')['sequences']['softbodies']['maps']
for room in seq:
 for f in ['final.md','map_data.json']:
  if room==ROOM:continue
  path=Path('commons/maps')/room/f
  check((ROOT/path).read_bytes()==(HERE/'before'/path).read_bytes(),str(path)+' preserved')
path=Path('commons/maps')/ROOM/'map_data.json'
changes=diff(read(HERE/'before'/path),read(ROOT/path))
check(changes==['/layers/interactables/10/8'],'only map edit is the lesson configuration on the existing bench')
roles=read(ROOT/'commons/data/artifact_roles.json')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'][ROOM]
book=next(p for p in read(ROOT/'commons/data/book/softbodies.json')['pearls'] if p['map']==ROOM)
anchors=re.findall(r'<!-- @([^ ]+) -->',(ROOT/'commons/maps'/ROOM/'final.md').read_text())
expected=['rounded_softbody_test','frozen_glass_vessel']
check(anchors==expected and roles['order'][ROOM]['primary']==expected and core['primary_tokens']==expected and [p['token'] for p in book['lines']]==expected,'book, roles, core and chapter share two ordered primary encounters')
check('frozen_glass_vessel' not in roles['order'][ROOM]['secondary'],'primary vessel is not repeated as secondary')
for f,key in [('final.md','text_sha256'),('map_data.json','map_sha256')]:
 check(hashlib.sha256((ROOT/'commons/maps'/ROOM/f).read_bytes()).hexdigest()==core[key],'core hash matches '+f)
check(core['learner_verified'] is False,'learner verification is not inferred from runtime')
for name,prefix in [('artifact_roles','/order/'+ROOM+'/'),('museum_core_encounters','/rooms/'+ROOM+'/')]:
 path=Path('commons/data')/(name+'.json')
 check(all(c.startswith(prefix) for c in diff(read(HERE/'before'/path),read(ROOT/path))),name+' changes only this hall')
path=Path('commons/artifacts/registry/soft_bodies.json')
check(all(any(c.startswith('/artifacts/'+k+'/') for k in expected+['rounded_softbody']) for c in diff(read(HERE/'before'/path),read(ROOT/path))),'registry changes only the two specimen implementations and harness')
path=Path('commons/artifacts/timing_machines/soft_workshop.json')
a,b=read(HERE/'before'/path),read(ROOT/path)
changes=diff(a,b)
check(len(a)==len(b) and all(x==y for x,y in zip(a,b) if x['map']!=ROOM),'workshop definitions change only the sampling chapter')
for name in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 check(diff(read(HERE/'before'/name),read(ROOT/name))==['/plans/121/artifacts/1/config'],name+' changes only the lesson bench config')
check((ROOT/'ada_run/em_plan.json').read_bytes()==(ROOT/'commons/data/museum/em_plan.json').read_bytes(),'active museum plans agree')
run=read(HERE/'review-report.json')
check(run['passed'] and all(c['passed'] for c in run['review_checks']),'all 65 controlled runtime checks pass')
manifest=read(HERE/'runtime-inputs.json')
for name,sha in manifest.items():
 if name.endswith('.gd') and not name.startswith('doc/'):
  check(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==sha,name+' matches tested source')
(HERE/'content-checks.json').write_text(json.dumps({'passed':all(c['passed'] for c in checks),'checks':checks},indent=2))
print(sum(c['passed'] for c in checks),'/',len(checks),'content checks')
raise SystemExit(not all(c['passed'] for c in checks))
