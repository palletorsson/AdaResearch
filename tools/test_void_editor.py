"""Schema negatives plus the real encyclopedia save/reload API. Server: port 3003."""
from copy import deepcopy
from pathlib import Path
import hashlib
import json
import urllib.request
import urllib.error
import sys
from validate_void_rooms import validate, VOID, ROOT

checks = []
def check(name, ok):
    checks.append({'name': name, 'passed': bool(ok)})
    print(('PASS ' if ok else 'FAIL ') + name)

data = json.loads((VOID/'rooms.json').read_text())
check('current authored floors validate', not validate(data))
def reject(name, edit):
    copy = deepcopy(data); edit(copy)
    check(name, bool(validate(copy)))
reject('reject malformed part transform', lambda d: d['floors'][3]['artifacts'][0]['config']['parts']['MeasurementRoom'].update(position=[1,2]))
reject('reject unknown artifact part', lambda d: d['floors'][3]['artifacts'][0]['config']['parts'].update(MissingPart={'position':[0,0,0]}))
reject('reject fifth station', lambda d: d['floors'][0]['artifacts'][0].update(station='centre'))
reject('reject non-cardinal facing', lambda d: d['floors'][0]['artifacts'][0].update(facing=45))
reject('reject duplicate station occupancy', lambda d: d['floors'][0]['artifacts'].append(deepcopy(d['floors'][0]['artifacts'][0])))
reject('reject wall in shaft', lambda d: d['floors'][0]['walls'][0].update({'from':[-10,-2], 'to':[-10,2]}))
reject('reject wall on checkpoint', lambda d: d['floors'][0]['walls'][0].update({'from':[-6,4], 'to':[-6,5]}))
reject('reject diagonal wall', lambda d: d['floors'][0]['walls'][0].update({'to':[-2,2]}))
reject('reject catalyst cells at origin', lambda d: d['floors'][0]['impact_cells'].append([0,0]))
reject('reject catalyst cells in shafts', lambda d: d['floors'][1]['impact_cells'].append([-10,0]))
reject('reject missing map', lambda d: d['floors'][0].update(map='Does_Not_Exist_ABC'))
reject('reject missing artifact', lambda d: d['floors'][0]['artifacts'][0].update(artifact='does_not_exist_ABC'))
for facing in [0,90,180,270]:
    copy=deepcopy(data); copy['floors'][0]['artifacts'][0]['facing']=facing
    check(f'accept facing {facing}', not validate(copy))

reject('reject prop over shaft', lambda d: d['floors'][1]['props'][0].update(position=[10,0]))
reject('reject prop over checkpoint', lambda d: d['floors'][1]['props'][2].update(position=[-6,4.5]))
reject('reject prop covering an exhibit', lambda d: d['floors'][1]['props'][2].update(position=[0,2.5]))
reject('reject prop over catalyst panels', lambda d: d['floors'][1]['props'][2].update(position=[0,-1]))
reject('reject prop over balcony approach', lambda d: d['floors'][1]['props'][2].update(position=[0,8]))
reject('reject prop intersecting a pillar', lambda d: d['floors'][1]['props'][2].update(position=[14,7]))
reject('reject rescaling a standard shipping container', lambda d: d['floors'][1]['props'][0].update(scale=0.9))
reject('reject unknown prop kind', lambda d: d['floors'][1]['props'][0].update(kind='missing'))
reject('reject duplicate prop ID', lambda d: d['floors'][1]['props'].append(deepcopy(d['floors'][1]['props'][0])))
reject('reject exhibit over shaft', lambda d: d['floors'][1]['artifacts'][0].update(position=[10,0]))
reject('reject exhibit over another exhibit', lambda d: d['floors'][1]['artifacts'][0].update(position=[0,2.5]))
reject('reject solid wall across balcony approach', lambda d: d['floors'][1]['walls'].append({'id':'blocked-exit','from':[-2,8],'to':[2,8],'height':2}))
copy=deepcopy(data)
copy['floors'][2]['props']=[{'id':'rotation-fixture','kind':'container','position':[19,0],'facing':0,'scale':1}]
check('accept scenery in the expanded side bay',not validate(copy))
copy['floors'][2]['props'][0]['facing']=90
check('rotated footprint cannot extend beyond the slab',bool(validate(copy)))
copy=deepcopy(data)
copy['floors'][1]['walls'].append({'id':'clear-header','from':[-2,8],'to':[2,8],'base':2.5,'height':1})
check('allow an overhead lintel above a clear approach',not validate(copy))

# Basins remain supported by the schema, but Coordinates now has a solid slab.
# Give these negative cases their own fixture instead of requiring a live recess.
def reject_basin(name, edit):
    copy=deepcopy(data)
    copy['floors'][2]['basin']={'depth':1,'rects':[[-3.5,-2.5,1,6],[-2.5,2.5,5,1]]}
    edit(copy)
    check(name,bool(validate(copy)))

reject_basin('reject basin crossing shaft', lambda d: d['floors'][2]['basin'].update(rects=[[-11,-2,2,3]]))
reject_basin('reject basin cutting column', lambda d: d['floors'][2]['basin'].update(rects=[[-5.5,6.5,1,1]]))
reject_basin('reject basin outside slab', lambda d: d['floors'][2]['basin'].update(rects=[[20,0,2,1]]))
reject_basin('reject basin over catalyst panels', lambda d: d['floors'][1].update(basin={'depth':1,'rects':[[-2,-2,2,2]]}))
reject_basin('reject wall filling basin', lambda d: d['floors'][2]['walls'].append({'id':'well-wall','from':[-3.5,0],'to':[-2.5,0],'height':2}))
reject_basin('reject crate filling basin', lambda d: d['floors'][2].update(props=[{'id':'well-crate','kind':'crate','position':[-3,0],'facing':0,'scale':1}]))

url='http://localhost:3003/api/void-layout'
def get():
    return json.load(urllib.request.urlopen(url))
def post(value):
    req=urllib.request.Request(url, json.dumps(value).encode(), {'Content-Type':'application/json'}, method='POST')
    try:
        with urllib.request.urlopen(req) as r:return r.status,json.load(r)
    except urllib.error.HTTPError as e:return e.code,json.load(e)

source_hash=hashlib.sha256((ROOT/'commons/maps/Point_Zero/map_data.json').read_bytes()).hexdigest()
state=get()
check('editor reads exact Godot floor file', state['rooms']==data)
before=(VOID/'rooms.json').read_bytes()
code,_=post({'rooms':data,'revision':'stale'})
check('stale saves rejected without data loss', code==409 and before==(VOID/'rooms.json').read_bytes())
bad=deepcopy(data);bad['floors'][0]['artifacts'][0]['facing']=23
code,_=post({'rooms':bad,'revision':state['revision']})
check('invalid saves rejected without data loss', code==422 and before==(VOID/'rooms.json').read_bytes())
code,result=post({'rooms':data,'revision':state['revision']})
check('valid file round-trips through editor', code==200 and get()['rooms']==data)

# Exercise the new fields through the real API, then restore the authored room.
edited=deepcopy(data)
edited['floors'][1]['props'][0].update(position=[6.2,0],facing=180,color='#52626f',scale=1)
edited['floors'][1]['artifacts'][1]['position']=[0,3]
code,saved=post({'rooms':edited,'revision':result['revision']})
try:
    check('editor saves moved and rotated scenery plus an artifact position',code==200 and get()['rooms']==edited)
finally:
    if code==200:
        restore_code,_=post({'rooms':data,'revision':saved['revision']})
        check('authored Point One arrangement restored after API test',restore_code==200 and get()['rooms']==data)
check('round-trip retains museum source map unchanged', source_hash==hashlib.sha256((ROOT/'commons/maps/Point_Zero/map_data.json').read_bytes()).hexdigest())
check('backup is written before save', any((ROOT/'ada_run/void-editor-backups').glob('rooms-*.json')))
out=Path(next((a.split('=',1)[1] for a in sys.argv if a.startswith('--out=')),str(ROOT/'doc/book/iterations/2026-10-18-void-point-zero-editor')))
out.mkdir(parents=True,exist_ok=True)
(out/'editor-checks.json').write_text(json.dumps({'passed':all(c['passed'] for c in checks),'checks':checks},indent=2))
raise SystemExit(0 if all(c['passed'] for c in checks) else 1)
