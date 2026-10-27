"""Curate only the four requested floors through the normal revisioned save API."""
import copy, json, math, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/transformation-workbench';OUT.mkdir(parents=True,exist_ok=True)
URL='http://localhost:3003/api/void-layout'
def get(): return json.load(urllib.request.urlopen(URL))
def post(value):
    req=urllib.request.Request(URL,json.dumps(value).encode(),{'Content-Type':'application/json'},method='POST')
    try:
        with urllib.request.urlopen(req) as r:return json.load(r)
    except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode())
current=get();original=current['rooms'];rooms=copy.deepcopy(original)
if (OUT/'before-rooms.json').exists():
    assert original==json.loads((OUT/'before-rooms.json').read_text(encoding='utf-8')), 'Layouts changed since preparation; review before applying again.'
else:(OUT/'before-rooms.json').write_text(json.dumps(original,indent=2)+'\n',encoding='utf-8')
def cell(f,id,kind,x,y,z,facing=0,**kw):f.setdefault('construction',[]).append(dict(id=id.replace('.','p'),kind=kind,position=[x,y,z],facing=facing,**kw))
def rotate(x,z):return z,-x

# Preserve all 146 authored Translation cells; add their true reflected counterpart.
f=rooms['floors'][15];assert f['map']=='Trans_Translation'
for old in copy.deepcopy(f['construction']):
    q=copy.deepcopy(old);q['id']='Mirror-'+q['id'];q['position'][0]*=-1;q['facing']=(-q['facing'])%360
    if 'travel'in q:q['travel'][0]*=-1
    f['construction'].append(q)
for x in [i+.5 for i in range(-7,7)]:
    for z in [5.5,6.5]:
        cell(f,f'LinkDeck-{x}-{z}','deck',x,2.88,z)
        cell(f,f'LinkTruss-{x}-{z}','truss',x,2.38,z)
f['title']='Translation / mirrored mezzanines and shared bridge'
f['route']=[dict(label=label,position=at,height=h) for label,at,h in [('Climb the original cube and wedge approach',[-18,6],0),('Ride across shaft A',[-10,0],3),('Walk the connecting deck',[0,6],3),('The same structure, reflected',[10,6],3),('Ride across shaft B',[10,0],3)]]

# Four axes, six angles each, one readable row; retain both shaft descents.
f=rooms['floors'][16];by={a['id']:a for a in f['artifacts']}
a=by['angle-bands'];a.update(position=[0,-5.1],facing=0);a['config'].update(tower_row=True,show_body_comparison=False,editor_label='One long row / X, Y, Z and XYZ / 0 to 90 degrees')
by['axis-z'].update(position=[-17,.5],facing=90)
old=f['construction'];keep=[]
for q in old:
    if q['id'].startswith(('ArrayStart','ArrayEnd','NorthArray','SouthArray')):continue
    q=copy.deepcopy(q)
    if q['id'].startswith(('YBank','YApproach','YExit','rotating_platform')):
        dx,dz=q['position'][0]-17,q['position'][2]-1;dx,dz=rotate(dx,dz);q['position'][0]=17+dx;q['position'][2]=1+dz;q['facing']=(q['facing']+90)%360
    if q['id'].startswith(('ZDock','ZUpper','ZLower')):
        dx,dz=rotate(q['position'][0]+16.5,q['position'][2]-4.5);q['position'][0]=-17+dx;q['position'][2]=.5+dz;q['facing']=(q['facing']+90)%360
    keep.append(q)
f['construction']=keep
for i in range(32):
    x=i-15.5
    for y in [0,1]:cell(f,f'RowNorth-{i}-{y}','cube',x,y,-7)
    cell(f,f'RowSouth-{i}','cube',x,0,-3.6)
cell(f,'RowEntryLow','wedge',-18.5,0,-7,90)
cell(f,'RowEntryHigh','wedge',-16.5,1,-7,90)
for x in [-17,-16]:cell(f,f'RowEntryBase{x}','cube',x,0,-7)
for key,x in [('carousel-cake',-17),('carousel-column',-8.2),('carousel-ziggurat',0),('carousel-spindle',8.2),('carousel-flare',17)]:by[key]['position']=[x,6.5]
by['composition']['position']=[-5.5,2.4]
by['axial-sweep']['position']=[-1.8,3.5]
by['hinge']['position']=[2.2,2.1]
by['turn-order-film']['position']=[5.7,3.5];by['turn-order-film']['facing']=180
f['title']='Rotation / one row, four axes, two shaft descents'
f['route']=[dict(label=label,position=at,height=h) for label,at,h in [('Climb to the comparison row',[-18.5,-7],0),('X then Y then Z',[0,-5.1],2),('Same turn, different profiles',[0,5],0),('Wheel down shaft A',[-10,0],0),('Turn the hollow cubes down shaft B',[10,0],0)]]

# Use the 42 m length rather than staging a museum strip across 18 m depth.
f=rooms['floors'][18]
for a in f['artifacts']:
    x,z=rotate(*a['position']);a['position']=[x,z];a['facing']=(a['facing']+90)%360
    if a['artifact']=='approach_wall':a.update(position=[-15,0],facing=90,scale=1.65)
    elif a['artifact']=='carve_grid':a.update(position=[0,0],facing=90,scale=1.8)
    elif a['artifact']=='approach_scale':a.update(position=[16.5,0],facing=90,scale=1.4)
    elif a['artifact']=='dark_sphere':a.update(position=[-5.5,5.3],scale=2)
    elif a['artifact']=='film_body_aperture':a.update(position=[-18,5],facing=180)
    elif a['artifact']=='film_foundation_state':a.update(position=[18,5],facing=180)
f['title']='The Body / approach, carve, make room'
f['route']=[dict(label=label,position=at) for label,at in [('The wall makes room for your body',[-17,0]),('Use the south aisle around shaft A',[-10,4.4]),('Carve the central field',[-3,0]),('Walk to the changing block field',[13.1,0]),('The same body changes the room',[18,4])]]

f=rooms['floors'][19]
for a in f['artifacts']:
    a['position']=list(rotate(*a['position']));a['facing']=(a['facing']+90)%360
    if a['artifact']=='pusher_block':
        # Put the moving cubes just behind the existing shaft edge. Their
        # source-trial adapter turns the real travel vector with their mount.
        a['position']=[13.3,a['position'][1]*1.1]
        a['config']['axis']='z';a['config']['distance']='1.3'
    elif a['artifact']=='grower_block':a['position']=[-16,a['position'][1]*1.4]
    elif a['artifact']=='transformation_airlock':a.update(position=[-4,5.8],facing=0)
    elif a['artifact']=='rc':a.update(height=1.1)
    elif a['artifact']=='free_ball_launcher':a.update(height=0)
f['title']='The Moving Boundary / translation, rotation, scale across the floor'
f['route']=[dict(label=label,position=at) for label,at in [('See the changing blocks on the west bank',[-18,0]),('Keep the shaft open',[-10,4.5]),('The leaves translate, turn and shrink',[-4,4]),('Rotating cubes and crossing trajectories',[1,0]),('The moving boundary meets shaft B',[14.8,0])]]

allowed={15,16,18,19}
assert all(rooms['floors'][i]==original['floors'][i] for i in range(len(rooms['floors'])) if i not in allowed)
validation=post(dict(rooms=rooms,validateOnly=True));assert validation['valid']
receipt=post(dict(rooms=rooms,revision=current['revision']))
after=get()['rooms'];assert after==rooms
(OUT/'save-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
(OUT/'curated-floors.json').write_text(json.dumps({i:rooms['floors'][i] for i in sorted(allowed)},indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(changed_floors=sorted(allowed),construction15=len(rooms['floors'][15]['construction']),revision=receipt['revision'],warnings=len(receipt.get('warnings',[])))))
