"""Stage bodily encounters, preserving all original exhibits and other floors."""
import copy, json, urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/transformation-walkability'; OUT.mkdir(parents=True,exist_ok=True)
URL='http://localhost:3003/api/void-layout'
def get(): return json.load(urllib.request.urlopen(URL))
def post(value):
    request=urllib.request.Request(URL,json.dumps(value).encode(),{'Content-Type':'application/json'},method='POST')
    try:
        with urllib.request.urlopen(request) as response: return json.load(response)
    except urllib.error.HTTPError as error: raise RuntimeError(error.read().decode())

current=get(); before=current['rooms']; rooms=copy.deepcopy(before)
snapshot=OUT/'before-rooms.json'
if snapshot.exists(): assert before==json.loads(snapshot.read_text()), 'Review current user changes before restaging again.'
else: snapshot.write_text(json.dumps(before,indent=2)+'\n',encoding='utf-8')

def cell(f,name,kind,x,y,z,facing=0):
    f.setdefault('construction',[]).append(dict(id=name.replace('.','p'),kind=kind,position=[x,y,z],facing=facing))
def wall(f,name,a,b,height=3):
    f.setdefault('walls',[]).append(dict(id=name,**{'from':a,'to':b},height=height,finish='unfinished'))
def route(f,points): f['route']=[dict(label=label,position=at,height=height) for label,at,height in points]

f=rooms['floors'][16]; by={a['id']:a for a in f['artifacts']}
a=by['angle-bands']; a.update(position=[0,0],facing=90)
a['config'].update(tower_walkways=True,tower_row=False,tower_bands=False,show_body_comparison=True,columns=1,editor_label='Walk the same cubes / X, Y, Z and XYZ / 0 to 90 degrees')
# The old single-row staging is the only construction removed. Preserve the
# existing blade, its docks and both shaft descents.
f['construction']=[c for c in f['construction'] if not c['id'].startswith('Row')]
for side,x in [('Start',-6.5),('Finish',6.5)]:
    for z in range(-7,8):
        for y in range(3): cell(f,f'Walk{side}-{z}-{y}','cube',x,y,z)
# Rise on the outer strips, away from the open elevator shafts.
for side,sign,z in [('Start',1,-7.5),('Finish',-1,7.5)]:
    for step in range(3):
        x=sign*(-9.5+step)
        for y in range(step): cell(f,f'WalkRampBase-{side}-{step}-{y}','cube',x,y,z)
        cell(f,f'WalkRamp-{side}-{step}','wedge',x,step,z,90 if sign==1 else 270)
# Put the smaller studies on the perimeter instead of in the four walking strips.
for key,at in [('carousel-cake',[-18,-6]),('carousel-column',[-14.5,-6.3]),('carousel-ziggurat',[-18,6.3]),('carousel-spindle',[-14,6.3]),('carousel-flare',[18,-6.3]),('composition',[15.5,6]),('hinge',[19,6]),('turn-order-film',[12.7,6]),('axial-sweep',[14,-6.3])]: by[key]['position']=at
for c in f['construction']:
    if c['id']=='YExitRamp': c['position'][0]=20.3
f['title']='Rotation / four walkable angle gradients'
route(f,[('Climb the common start bank',[-9.5,-7.5],0),('Choose X, Y, Z or combined turns',[-6.5,0],3),('Walk across the same six angles',[0,2],3),('Compare the two body widths',[0,0],0),('Descend the finish bank',[9.5,7.5],0),('Return through the wheel or hollow cubes',[10,0],0)])

f=rooms['floors'][18]; f['construction']=[]; f['walls']=[]
for a in f['artifacts']:
    if a['artifact']=='approach_wall':
        a.update(position=[-15,0],facing=90,scale=1)
        a['config'].update(width=12,height=4.4,slats=14,aperture=1.6,reach=2.8)
    elif a['artifact']=='carve_grid':
        a.update(position=[0,0],facing=90,scale=1)
        a['config'].update(cells_x=35,cells_y=7,cells_z=13,cell_m=.34)
    elif a['artifact']=='approach_scale':
        a.update(position=[17,0],facing=90,scale=1)
        a['config'].update(cols=5,rows=3,blocks=15,spacing=2.3,block=2.1,min_scale=.34,reach=2.7)
    elif a['artifact']=='dark_sphere': a.update(position=[0,-7.6],scale=1)
    elif a['artifact']=='film_body_aperture': a.update(position=[-18,-7],facing=0)
    elif a['artifact']=='film_foundation_state': a.update(position=[18,-7.8],facing=0)
# The thresholds occupy the route rather than standing as isolated models.
for side in [-1,1]:
    wall(f,f'BodyWallCollar-{side}',[-15,side*6.1],[-15,side*8.8],4.4)
    wall(f,f'CarveCheek-{side}',[-2.3,side*6.1],[2.3,side*6.1],3)
    wall(f,f'ScaleCheek-{side}',[13.5,side*5.9],[20.5,side*5.9],3)
    for x in [-3.5,3.5]:
        for y in range(3): cell(f,f'CarveFrame-{side}-{x}-{y}','cube',x,y,side*6.3)
f['title']='The Body / the room opens, remembers, and returns'
route(f,[('Walk into the closed slats',[-18,0],0),('The opening follows your body',[-14,0],0),('Approach the lattice around shaft A',[-8,5],0),('Cut your own passage through the field',[-3,0],0),('Look back: the cut remains',[3,0],0),('Cross the blocks that shrink near you',[14,0],0),('Leave and watch the room return',[20,0],0)])

f=rooms['floors'][19]; f['construction']=[]; f['walls']=[]
pushers=[a for a in f['artifacts'] if a['artifact']=='pusher_block']
for a,z in zip(pushers,[-2,0,2]):
    a.update(position=[-15.3,z],facing=90,height=.49)
    a['config'].update(axis='z',distance='2.3')
for a in f['artifacts']:
    if a['artifact']=='rc':
        a.update(position=[-2 if '_4_' in a['id'] else 2.5,5],facing=90,height=1.1)
    elif a['artifact']=='transformation_airlock':a.update(position=[18,0],facing=90,height=0)
growers=[a for a in f['artifacts'] if a['artifact']=='grower_block']
for a,z in zip(growers,[-4.5,0,4.5]):a.update(position=[15.2,z],facing=0,height=0)
launchers=[a for a in f['artifacts'] if a['artifact']=='free_ball_launcher']
for a,(x,z) in zip(launchers,[(-4,3.3),(4,3.3),(-4,6.7),(4,6.7)]):a.update(position=[x,z],height=1,facing=180 if z<5 else 0)
# Timing lanes are made from the existing one-metre kit. The launchers
# rest on one-metre cubes in the side walls and fire across the turning lane.
for z in [3.3,6.7]:
    for x in range(-5,6):
        for y in range(1 if abs(x)==4 else 2):cell(f,f'TurnLane-{x}-{z}-{y}','cube',x,y,z)
for z in [-3,-1,1,3]:
    for x in [-17,-16]:cell(f,f'WaitBay-{x}-{z}','deck',x,0,z)
for z in range(-4,5):
    if z in [-2,0,2]: continue # the translating blocks emerge through these slots
    for y in range(2):cell(f,f'PushRecess-{z}-{y}','cube',-16.3,y,z)
for z in [-7,-6,6,7]:
    cell(f,f'GrowApproach-{z}','deck',14,0,z)
wall(f,'PusherBack',[-17,-4],[-17,4],2.4)
wall(f,'ScaleOuterPocket',[17.4,-6.5],[17.4,-2.5],2.4)
wall(f,'ScaleOuterPocketSouth',[17.4,2.5],[17.4,6.5],2.4)
for side in [-1,1]:wall(f,f'ExitCollar-{side}',[18,side*4.6],[18,side*8.8],3.8)
f['title']='The Moving Boundary / wait, cross, turn, squeeze, pass'
route(f,[('Read the pushers from the waiting bay',[-16,-4],0),('Time the crossing beside shaft A',[-13.7,-3],0),('Follow the south bank to rotation',[-6,5],0),('Pass the two turning walls',[0,5],0),('Wait between the growing cubes',[14,6.8],0),('Cross while the east bank opens',[14,0],0),('Combine the operations at the final door',[16.5,0],0),('Pass into the still exit bay',[20,0],0)])

changed={16,18,19}
assert all(rooms['floors'][i]==before['floors'][i] for i in range(len(rooms['floors'])) if i not in changed)
for i in changed: assert {a['id'] for a in rooms['floors'][i]['artifacts']}=={a['id'] for a in before['floors'][i]['artifacts']}
valid=post(dict(rooms=rooms,validateOnly=True)); assert valid['valid'],valid
receipt=post(dict(rooms=rooms,revision=current['revision']))
assert get()['rooms']==rooms
(OUT/'save-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
catalogue_path=ROOT/'commons/void/primitive-prefabs.json'
catalogue=json.loads(catalogue_path.read_text(encoding='utf-8'))
(OUT/'before-catalogue.json').write_text(json.dumps(catalogue,indent=2)+'\n',encoding='utf-8')
for p in catalogue['prefabs']:
    placement=p.get('placement',{}); n=placement.get('source_floor')
    if n not in changed:continue
    entry=next((a for a in rooms['floors'][n]['artifacts'] if a['id']==placement.get('source_id')),None)
    if not entry: continue
    placement.update(height=entry['height'],scale=entry['scale'],config=copy.deepcopy(entry['config']))
    if entry['id']=='angle-bands':
        p.update(title='Walkable rotation gradients / four bodily trials',learn='Walk the same full-size cubes at 0, 18, 36, 54, 72 and 90 degrees. Compare slopes, ridges, gaps and the two body widths.')
catalogue_path.write_text(json.dumps(catalogue,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(changed_floors=sorted(changed),unchanged_translation=True,revision=receipt['revision'],construction={i:len(rooms['floors'][i]['construction']) for i in changed})))
