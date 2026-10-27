"""Replace only floor 16's obsolete approach guide after its raised-course change."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'doc/ports/2026-10-26-rotation-z-width/electric'
URL='http://localhost:3003/api/void-layout'
state=json.load(urllib.request.urlopen(URL,timeout=60));before=state['rooms'];rooms=copy.deepcopy(before);floor=rooms['floors'][16]
assert floor['map']=='Trans_Rotation'
assert next(a for a in floor['artifacts'] if a['id']=='z-wide')['config']['cube_edge']==1
assert any(a['id']=='gantry-tc' for a in floor['artifacts'])
(OUT/'before-route.json').write_text(json.dumps(dict(title=floor['title'],route=floor['route']),indent=2)+'\n',encoding='utf8')
def point(label,x,z,height=3.5):return dict(label=label,position=[x,z],height=height)
floor['title']='Rotation / one-metre cubes and Z widths'
floor['route']=[point('TC / BOARD THE GANTRY LIFT',-8,4.5,0),point('GANTRY / SAFE UPPER LANDING',-6.4,4.5),point('SINGLE Z / START FROM THE WEST',-3.5,-3),point('SINGLE Z / EAST BANK',3.5,-3),point('RETURN VIA THE SAFE GANTRY',4,-8),point('WEST RETURN / SAME START DIRECTION',-4,-8),point('WIDE Z / SAME CUBES AND ANGLES',-3.5,0),point('WIDE Z / EAST BANK',3.5,0),point('SAFE BANK / RETURN RAMP',4,7.95),point('DOWN THE ORIGINAL RAMP',7,7.95),point('SHAFT / ON TO SCALE',10,0,0)]
assert all(rooms['floors'][i]==before['floors'][i] for i in range(len(before['floors'])) if i!=16)
assert floor['artifacts']==before['floors'][16]['artifacts'] and floor['construction']==before['floors'][16]['construction']
def post(payload):
    with urllib.request.urlopen(urllib.request.Request(URL,json.dumps(payload).encode(),{'Content-Type':'application/json'}),timeout=120) as response:return json.load(response)
assert post(dict(rooms=rooms,revision=state['revision'],validateOnly=True))['valid']
receipt=post(dict(rooms=rooms,revision=state['revision']))
after=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf8'));assert after==rooms
(OUT/'route-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print('Updated only floor 16 title/route; both Z trials use the same west-to-east approach.')
