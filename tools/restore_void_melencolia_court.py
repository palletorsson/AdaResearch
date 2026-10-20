"""One-time restoration through the same revision-checked API as the editor."""
from pathlib import Path
import hashlib, json, urllib.request, urllib.error

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-primitives-restored-relations'
ENDPOINT = 'http://localhost:3003/api/void-layout'
OUT.mkdir(parents=True, exist_ok=True)
receipt_path = OUT / 'layout-change.json'
assert not receipt_path.exists(), 'Already applied; do not overwrite subsequent curation.'
payload = json.load(urllib.request.urlopen(ENDPOINT))
rooms = payload['rooms']
before = json.dumps(rooms['floors'][:13], sort_keys=True)
floor = rooms['floors'][13]
assert floor['map'] == 'Primitives_Melencolia'
(OUT / 'floor13-before.json').write_text(json.dumps(floor, indent=2), encoding='utf-8')
poses = {
    '3-3': [-2,-4,1], '3-7': [2,-4,1],
    '7-3': [-2,0,1], '7-7': [2,0,1],
    '4-5': [0,-3,1.4], '5-4': [-1,-2,1.4],
    '5-6': [1,-2,1.4], '6-5': [0,-1,1.4],
    '5-5': [0,-2,1],
}
for suffix, (x,z,height) in poses.items():
    item = next(a for a in floor['artifacts'] if a['id']=='museum-primitives_melencolia-'+suffix)
    item['position']=[x,z]
    item['height']=height
# Keep the route on the slab around the arrival shaft, then approach the wp.
route=[[11,4],[7,4],[7,2.7],[0,2.7],[0,0],[-1,0],[-1,-.9],
       [0,0],[0,3],[-6,4],[-13,4],[-6,4],[0,3.8]]
floor['route']=[{'label': 'Arrival' if i==0 else 'End of Primitives' if i==len(route)-1 else f'Walk / {i}',
                 'position':p} for i,p in enumerate(route)]
assert json.dumps(rooms['floors'][:13], sort_keys=True) == before
request = urllib.request.Request(ENDPOINT,
    data=json.dumps({'rooms':rooms,'revision':payload['revision']}).encode(),
    headers={'Content-Type':'application/json'}, method='POST')
try:
    receipt = json.load(urllib.request.urlopen(request))
except urllib.error.HTTPError as error:
    raise RuntimeError(error.read().decode()) from error
receipt_path.write_text(json.dumps({'receipt':receipt,'moved_ids':list(poses),
    'preserved_text_sha256':{name:hashlib.sha256((ROOT/'commons/maps/Primitives_Melencolia'/name).read_bytes()).hexdigest()
    for name in ['final.md','tutorial.md']}}, indent=2), encoding='utf-8')
print('Restored nine existing court solids; preserved floors 0–12 and source texts.')
