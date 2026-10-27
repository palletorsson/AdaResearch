"""Apply Palle's simpler pyramid-rim choice, preserving prior arrangements."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/transformation-required-route-2026-10-26'
URL='http://localhost:3003/api/void-layout'
assert not (OUT/'pyramid-rims-change.json').exists(),'Already applied: preserve later edits.'
original=json.loads((OUT/'before-rooms.json').read_text(encoding='utf-8'))
p=json.load(urllib.request.urlopen(URL));rooms=p['rooms'];before=copy.deepcopy(rooms)
for index,cx in [(14,-10),(15,10)]:
    f=rooms['floors'][index]
    f['walls']=[w for w in f['walls'] if not w['id'].startswith('route-')]
    f['props']=[a for a in f.get('props',[]) if not a['id'].startswith('route-')]
    f['construction']=[c for c in f['construction'] if not c['id'].startswith('RouteBack-')]
    f['route']=copy.deepcopy(original['floors'][index]['route'])
    # A continuous metre-cube plinth carries the original Polyhedra pyramids.
    # The 0.75m side / 1m end strip INSIDE the plinth stays walkable: jumping from the raised
    # bridge lands here first, then the ordinary six-metre corner-pad drop.
    # No change to global fall damage, pads, shafts, mechanisms or floor sizes.
    x0,x1=cx-3.75,cx+3.75;z0,z1=-4.5,4.5
    for kind,nx,nz in [('plinth',8,9),('pyramid',5,6)]:
        points=[]
        for a,b,n in [((x0,z0),(x1,z0),nx),((x1,z0),(x1,z1),nz),
                      ((x1,z1),(x0,z1),nx),((x0,z1),(x0,z0),nz)]:
            for j in range(n):points.append([round(a[0]+(b[0]-a[0])*j/n,4),round(a[1]+(b[1]-a[1])*j/n,4)])
        for n,(x,z) in enumerate(points):
            if kind=='plinth':
                f['construction'].append({'id':f'ShaftRim-Plinth-{n:02}','kind':'cube','position':[x,0,z],'facing':0})
            else:
                f['artifacts'].append({'id':f'shaft-rim-pyramid-{n:02}','artifact':'pyramid_blocker',
                    'station':'NW' if cx<0 else 'NE','position':[x,z],'height':1,'facing':0,'scale':1,
                    'config':{'editor_label':'Polyhedra pyramid / shaft boundary'}})
    assert len(f['artifacts'])<=128
    if index==14:
        next(a for a in f['artifacts'] if a['id']=='sequence').setdefault('config',{})['exit_route']='pyramid_rim'
        f['route']=[a for a in f['route'] if 'Down ramp' not in a['label'] and 'DOWN' not in a['label']]
        f['route'] += [{'label':'OVER THE PYRAMIDS / LAND ON THE INNER RIM','position':[-14.8,0],'height':3},
                       {'label':'A SOUTH-WEST / DROP TO THE NEXT FLOOR','position':[-12.73,1.9],'height':0}]
        # Clear the pyramid bases while retaining the entire original AND.
        a=next(a for a in f['artifacts'] if a['id']=='logic-spring-and')
        assert a['position']==[-4.8,3.6]
        a['position']=[-4.1,3.6]
    else:
        f['route'] += [{'label':'JUMP OVER THE PYRAMIDS / LAND ON THE INNER RIM','position':[11.7,3.25],'height':0},
                       {'label':'B NORTH-EAST / DROP TO THE NEXT FLOOR','position':[12.73,-1.9],'height':0}]
for i in range(len(rooms['floors'])):
    if i not in [14,15]:assert rooms['floors'][i]==before['floors'][i]
for i in [14,15]:assert all(c in rooms['floors'][i]['construction'] for c in original['floors'][i]['construction'])
req=urllib.request.Request(URL,data=json.dumps({'rooms':rooms,'revision':p['revision']}).encode(),headers={'Content-Type':'application/json'},method='POST')
try:receipt=json.load(urllib.request.urlopen(req))
except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode()) from e
(OUT/'pyramid-rims-change.json').write_text(json.dumps({'receipt':receipt,
    'floors':{'14':'Exit shaft A','15':'Exit shaft B'},'per_floor':{'original_pyramids':22,'metre_cube_plinths':34},
    'inner_landing_rim_metres':{'sides':.75,'ends':1},'AND_clearance_shift_metres':.7,
    'preserved':'All original construction, artifacts, floor sizes and 207 other floors. Earlier partition/back-link experiment removed.'},indent=2),encoding='utf-8')
print('Saved original pyramid rims on cube plinths; bridge-to-rim jumps keep normal fall rules.')

