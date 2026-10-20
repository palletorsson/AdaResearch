"""Install the three-crossing trial using a revision-checked editor save."""
from pathlib import Path
import hashlib,json,urllib.request
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-introduction-three-crossings'
OUT.mkdir(parents=True,exist_ok=True)
URL='http://localhost:3003/api/void-layout?trial=transformation'
payload=json.load(urllib.request.urlopen(URL))
previous=json.loads((OUT/'before.json').read_text(encoding='utf-8')) if (OUT/'before.json').exists() else None
if previous and previous['rooms']!=payload['rooms']:
    raise SystemExit('Editor arrangement changed; do not replace it.')
protected=['commons/void/rooms.json','commons/void/layout.json','commons/void/cube_walkway.json',
 'commons/scenes/mapobjects/scale_cube.gd','commons/scenes/mapobjects/rotation_cube.gd',
 'commons/scenes/mapobjects/transport_cube.gd']
protected += [p.relative_to(ROOT).as_posix() for p in (ROOT/'commons/maps').glob('*/tutorial.md')]
protected += [p.relative_to(ROOT).as_posix() for p in (ROOT/'commons/maps').glob('*/final.md')]
protected += ['commons/maps/Trans_Introduction/map_data.json','commons/maps/Trans_Pre/map_data.json']
baseline={'rooms':payload['rooms'],'revision':payload['revision'],'layout':payload['frame'],
 'preserved_sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in protected}}
if not previous: (OUT/'before.json').write_text(json.dumps(baseline,indent=2)+'\n',encoding='utf-8')
members=[]
# Continuous banks, still built from the same one-metre bodies. The gaps are
# B: 5m translation; centre: 3m growth; A: 3m rotation with cantilevered banks.
for x in list(range(13,16))+list(range(2,8))+list(range(-8,-1))+list(range(-15,-11)):
    for z in [-1,0,1]:
        members.append({'id':f'Bank_{x}_{z}'.replace('-','m'),'kind':'cube','position':[x,0,z],'facing':0})
for side in [-1,1]:
    for z in [-1,0,1]:
        members.append({'id':f'Ramp_{side}_{z}'.replace('-','m'),'kind':'wedge','position':[side*16.5,0,z],'facing':270 if side==1 else 90})
signs=[]
for name,text,x in [('Start','SAME CUBES + WEDGES / THREE CROSSINGS',18),('Transport','01 / MOVE\nWAIT, BOARD, RIDE',14),('Grow','02 / GROW\nWAIT UNTIL THE TOP MEETS THE BANK',4),('Turn','03 / TURN\nCROSS WHEN THE PLANK ALIGNS',-6),('Done','THREE TRANSFORMS / ONE BODY\nDESCENT AT THE SOUTH-WEST CORNER',-18)]:
    signs.append({'id':name+'Caption','text':text,'position':[x,1.018 if abs(x)<16 else .025,0]})
recipe={'id':'introduction-three-crossings','members':members,'signs':signs}
(ROOT/'commons/void/trials/transformation/introduction_sequence.json').write_text(json.dumps(recipe,indent=2)+'\n',encoding='utf-8')
rooms=json.loads(json.dumps(payload['rooms']))
floor=rooms['floors'][2]
floor['title']='Introduction / Move, grow, turn'
floor['artifacts']=[{'id':'sequence','artifact':'void_trial_introduction_sequence','position':[0,0],'height':0,'facing':0,'scale':1,'station':'NW','config':{'museum_origin':'Trans_Introduction','editor_label':'Three crossings / B, centre, A'}}]
floor['walls']=[]
for x,name in [(10,'transport'),(0,'growth'),(-10,'rotation')]:
    for a,b,side in [(-8.9,-1.6,'north'),(1.6,8.9,'south')]:
        floor['walls'].append({'id':name+'-'+side,'from':[x,a],'to':[x,b],'height':4.2,'finish':'unfinished'})
floor['basin']={'depth':2.5,'glass':False,'rects':[[-1.5,-1.5,3,3]]}
floor['route']=[{'label':label,'position':p} for label,p in [
 ('B ARRIVAL / TAKE THE RAMP',[15,-4.2]),('01 MOVE',[14,2.3]),('02 GROW',[4,2.3]),('03 TURN',[-6,2.3]),('A / SOUTH-WEST SOFT LANDING',[-13.5,3.8])]]
# Retain the existing work-light instances, away from ramps and waiting banks.
for i,prop in enumerate(floor.get('props',[])):
    if prop['kind']=='work_light':prop['position']=[6 if i%2==0 else -6,5.5]
rooms['floors'][3]['route']=[{'label':'INTRODUCTION COMPLETE / R OR B TO REPEAT','position':[-14,4]}]
layout=payload['frame']
layout['status']='Transformation trial: Pre -> move over B -> grow at centre -> turn over A -> descent.'
layout['descent']['pad_x_sides']={'3':-1}
layout['route_note']='Introduction arrives on B north-east; three crossings run east to west. Leave via A south-west to its marked boards.'
(ROOT/'commons/void/trials/transformation/layout.json').write_text(json.dumps(layout,indent=2)+'\n',encoding='utf-8')
data=json.dumps({'rooms':rooms,'revision':payload['revision']}).encode()
req=urllib.request.Request(URL,data=data,headers={'Content-Type':'application/json'})
with urllib.request.urlopen(req) as response: receipt=json.load(response)
(OUT/'layout-change.json').write_text(json.dumps({'receipt':receipt,'rooms':rooms},indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))
