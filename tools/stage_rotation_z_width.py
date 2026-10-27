"""Add the approved Z-width comparison through the revision-checked live editor."""
import copy, hashlib, json, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/ports/2026-10-26-rotation-z-width'
OUT.mkdir(parents=True,exist_ok=True)
URL='http://localhost:3003/api/void-layout'
def post(payload):
    request=urllib.request.Request(URL,json.dumps(payload).encode(),{'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=120) as response:return json.load(response)
current=json.load(urllib.request.urlopen(URL,timeout=60))
before=current['rooms'];rooms=copy.deepcopy(before);floor=rooms['floors'][16]
assert floor['map']=='Trans_Rotation'
assert not any(a['id']=='z-wide' for a in floor['artifacts']), 'Already staged; preserve edits'
(OUT/'before-rooms.json').write_text(json.dumps(before,indent=2)+'\n',encoding='utf8')
(OUT/'before-layout.json').write_bytes((ROOT/'commons/void/layout.json').read_bytes())
array=next(a for a in floor['artifacts'] if a['id']=='angle-bands')
array['config']['tower_band_positions']={'X':[-7.8,3,-5.5],'Y':[-4.85,3,-5.5],'Z':[3.7,3,-5.5],'XYZ':[7.25,3,-5.5]}
floor['artifacts'].append(dict(id='z-wide',artifact='rotation_array_compare',station='SE',position=[0,.7],height=0,facing=90,scale=1,config=dict(single_axis='Z',columns=2,rows=6,band_spacing=7,row_angle_step=18,tower_walkways=True,show_body_comparison=True,editor_label='Z / WIDE / same six angles')))
validation=post(dict(rooms=rooms,revision=current['revision'],validateOnly=True))
assert validation['valid'],validation
receipt=post(dict(rooms=rooms,revision=current['revision']))
actual=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf8'))
assert actual==rooms
assert all(actual['floors'][i]==before['floors'][i] for i in range(len(before['floors'])) if i!=16)
assert actual['floors'][16]['construction']==before['floors'][16]['construction']
assert actual['floors'][16]['route']==before['floors'][16]['route']
for old,new in zip(before['floors'][16]['artifacts'],actual['floors'][16]['artifacts']):
    if old['id']=='angle-bands':
        expected=copy.deepcopy(old);expected['config']['tower_band_positions']=array['config']['tower_band_positions'];assert expected==new
    else:assert old==new
assert (OUT/'before-layout.json').read_bytes()==(ROOT/'commons/void/layout.json').read_bytes()
(OUT/'save-receipt.json').write_text(json.dumps(dict(passed=True,receipt=receipt,changed_floor=16,new_artifact='z-wide',preserved_other_artifacts=True,preserved_construction=True,preserved_other_floors=True,rooms_sha256=hashlib.sha256((ROOT/'commons/void/rooms.json').read_bytes()).hexdigest()),indent=2)+'\n',encoding='utf8')
print('Saved floor 16: original models/angles and banks preserved; independent two-column Z added.')
