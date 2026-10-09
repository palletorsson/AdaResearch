"""One-time, author-directed split. Snapshot every edited source before writing."""
from pathlib import Path
import copy, hashlib, json, sys
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
read=lambda p:(ROOT/p).read_text(encoding='utf-8-sig')
load=lambda p:json.loads(read(p))
changed=[]
def write(p,s):
    dest=ROOT/p
    before=OUT/'before'/p
    if dest.exists() and not before.exists():
        before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes(dest.read_bytes())
    dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(s.encode('utf-8'));changed.append(p)
def js(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def token(t):return t.split(':')[0].split('#')[0]

assert not (ROOT/'commons/maps/Point_Coordinates/map_data.json').exists(),'Split already exists; do not replay.'
old=load('commons/maps/Point_One/map_data.json')
one=copy.deepcopy(old);coords=copy.deepcopy(old)
# A shorter first corridor opens around its final sphere. No coordinate props remain.
one['map_info']['name']='Point One — A body in the light'
one['map_info']['dimensions']['depth']=15
one['map_info']['museum'].pop('basin',None)
one['layers']={k:[[' ']*19 for _ in range(15)] for k in old['layers']}
for z in range(15):
    row=['0']*19
    left,right=(6,9) if z<9 else (4,12)
    for x in range(left,right+1):row[x]='1'
    row[left-1]=row[right+1]='w'
    one['layers']['structure'][z]=row
one['layers']['structure'][-1]=['0']*3+['w']*11+['0']*5
for x in range(7,10):one['layers']['structure'][-1][x]='1'
for z in range(9,14):
    # Enclose the expanded end without a false opening beside the corridor.
    if z==9:
        for x in [3,4,5,10,11,12,13]:one['layers']['structure'][z][x]='w'
for z,x,kind in [(1,7,'absent'),(4,7,'visible'),(7,7,'solid'),(12,8,'pedestal')]:
    one['layers']['interactables'][z][x]=f'point_{kind}:180#plinth:0#pin:1'
one['layers']['interactables'][0][8]=old['layers']['interactables'][0][8]
one['layers']['interactables'][5][9]='point_sun_switch:270#plinth:0#pin:1#offset:0.45,0,0'
one['layers']['utilities'][0][8]='s'
one['layers']['utilities'][14][8]='t:Point_Coordinates'
one['documentation']={
 'summary':'Absence, visible surface and collision, followed by removing the light that casts their shadows.',
 'layout':'19 × 15. Corridor: absent (7,1), visible (7,4), solid (7,7). Wall switch (9,5) faces the corridor. A 1.3 m sphere stands at (8,12) in the wider end. Exit to Point_Coordinates.',
 'objective':'Distinguish a position, its surface, its physical boundary and the light that makes the surface legible.',
 'light':'Dedicated directional sun and unshadowed fill illuminate the study spheres and receiver plates; the wall switch removes only that sun. Other halls retain their lighting.'}
one['map_info']['metadata']['n_artifacts']=6
js('commons/maps/Point_One/map_data.json',one)

# Keep the existing coordinate room intact in X; subtract eight from Z.
# The black point is now the first encounter, not the fourth condition in Point One.
coords['map_info'].update(name='Point Coordinates — Where is the point?',lookup_name='Point_Coordinates')
coords['map_info']['dimensions']['depth']=20
coords['layers']={k:copy.deepcopy(layer[8:]) for k,layer in old['layers'].items()}
for layer in ['interactables','utilities']:
    for row in coords['layers'][layer]:
        for x,t in enumerate(row):
            if token(t) in ['point_pedestal','s','sp','t']:row[x]=' '
coords['layers']['utilities'][0][8]='s'
coords['layers']['utilities'][19][8]='t:Point_Lines'
coords['layers']['interactables'][0][8]=old['layers']['interactables'][0][8]
coords['layers']['interactables'][2][7]='point_held:180#plinth:0#pin:1'
for rect in coords['map_info']['museum']['basin']['rects']:rect[1]-=8
coords['spawn_points']['default']['position']=[8.5,0.1,0.5]
coords['documentation']={
 'summary':'Take the black point; read one movement from world and local references.',
 'layout':'19 × 20. Held point at (7,2); corridor opens at z=4. Frame at (4,12), WORLD at (2,9), LOCAL at (2,11), target at (6,10). L-shaped glass basin follows x=4,z=7..12 and z=12,x=4..9; surface stays at floor level.',
 'objective':'Use a supplied pickup; distinguish one held body from the references used to describe its position.',
 'secondary':'Existing invisible point, screen, radio, force comparison, Fontana, floating field and snap point are retained. Distance code belongs to Point_Lines.',
 'identity':'The production held point keeps coordinate_id point_one_main for compatibility; both cards and the frame select that one identity.'}
coords['map_info']['metadata']['n_artifacts']=sum(bool(t.strip()) for row in coords['layers']['interactables'] for t in row)
js('commons/maps/Point_Coordinates/map_data.json',coords)

# Move whole existing passages before editing their joins.
text=read('commons/maps/Point_One/final.md')
opening=text[:text.index('<!-- @point_held -->')]
opening=opening.replace('# Point One — A body for a position','# Point One — A body in the light')
opening=opening.replace("The three numbers are X, Y and Z: here, 1.12 metres above this station's origin, with no shift along X or Z. We have given that position a name, `point_position`. The numbers locate a place. They draw nothing.","We have given that position a name, `point_position`. The numbers locate a place. They draw nothing. In the next hall, we will take them apart.")
light='''<!-- @point_sun_switch -->

## First there was light

First there was light, right? Look at the crooked shadows under the white spheres. Round bodies leave stretched marks on the floor. Something outside the shape has helped to draw them.

There is a switch on the wall. Turn it.

You have removed their sun.

The long shadows disappear. The spheres remain, faintly lit. Try approaching the solid one again. Its boundary has not gone with its shadow. What helped you see the body was never what stopped your body.

Here the sun is a direction from which light arrives. We did not have to build a burning star. A few instructions gave the room a familiar consequence, and familiarity let the source go unquestioned. The switch puts that borrowed certainty within reach.

Turn it back. A shadow returns to the same place. It makes the sphere easier to locate, but it is not another point beneath the first one. It belongs to a relation between a surface, a light and somewhere for the light to be interrupted.

'''
ped=text[text.index('<!-- @point_pedestal -->'):text.index('[^point-one-code]:')]
ped=ped.replace('The small sphere travelled in your hand. This one asks you to walk around it.','The small sphere let you approach its centre. This one asks you to walk around it.')
ped=ped.replace('Look from the sphere you carried to the sphere on the pedestal.','Look from the small white spheres to the sphere on the pedestal.')
ped=ped.replace('The next room brings two points into relation. A line begins.','In the next room, the point can leave its place with your hand. Now we can ask where it has gone.')
euclid=text[text.index('[^point-one-euclid]:'):text.index('[^point-one-haraway]:')]
write('commons/maps/Point_One/final.md',opening+light+ped+'''[^point-one-code]: The position is drawn from the station's construction in `point_condition.gd`. The absent station creates no hidden sphere. The separate tutorial keeps a position, adds a visible surface and compares it with a collision boundary. Reading the three components and using pickup belong to the next hall, Point Coordinates.

'''+euclid)
held='''# Point Coordinates — Where is the point?

<!-- @point_held -->

The first label says “Point one”. This time the sphere is black. Take hold of it. The place you were looking towards can now leave with your hand.

Its small size is familiar. While you hold it, its movement answers to yours. Put it down and look back at the label. “Point one” stays at the station; the point has gone elsewhere.

Which part did the name belong to? The position, the sphere, the possibility of taking hold?

We have already separated seeing a body from being stopped by it. Holding adds another relation. Someone has made this point available to a hand. A position could not have supplied that permission on its own.

Keep the black point. The corridor opens towards a coloured frame standing in an L-shaped basin. Its glass is level with the floor; the depth belongs below your feet. The point can travel over a hollow without falling into it.

'''
middle=text[text.index('<!-- @coordinate_readout -->'):text.index('<!-- @point_pedestal -->')]
middle=middle.replace('The corridor opens into the coordinate room. Its guides and the card follow the point you are already holding.','The guides and the card follow the point you are already holding.')
middle=middle.replace('point-one-haraway','coordinates-haraway')
note=text[text.index('[^point-one-haraway]:'):].replace('point-one-haraway','coordinates-haraway')
write('commons/maps/Point_Coordinates/final.md',held+middle+'''In the next hall, we keep two positions at once. The space between them will become a line, and a distance we can change.

'''+note)

# Split the making passage at the same encounter boundary, not at equal word counts.
tut=read('commons/maps/Point_One/tutorial.md')
first=tut[:tut.index('## At the fourth label')]
first=first.replace('# Point One — follow the point','# Point One — give the point a body')
first=first.replace('The black point and the wider room continue in the museum.','The held point and coordinate frame have their own next chapter, Point Coordinates.')
first=first.replace('Used as a position, these numbers are X, Y and Z coordinates relative to an origin.','For now, this is the supplied position at our station. Point Coordinates will make its three components the subject of a lesson.')
first=first.replace('For this station, they mean no shift along X, 1.12 metres up Y, and no shift along Z. We name that value `point_position`.','We name that value `point_position`. The middle number places it above the floor.')
first+='''## Remove the light, keep the body

Use the museum's wall switch. The long shadows disappear, while a dim fill leaves the spheres visible. The collision boundary stays where it was.

The decision in the switch is one line:

```gdscript
sun.visible = false
```

Here `sun` is the supplied directional light. This is a reading of the museum source, not a line to paste into `visible.gd`, which has no variable named `sun`. We borrow the switch and lighting rig for this encounter. Building shadows is not another task hidden inside learning the point.

In the supplied desktop study, select its light node in the scene tree and toggle visibility in the Inspector. That study has its own simpler lighting; use the museum to compare the long shadows at the switch.

## Before leaving

The large sphere repeats the same name. Return to the radius we changed: giving a position more surface did not require a new kind of position.

We can now change appearance and resistance separately. [Point Coordinates](../Point_Coordinates/tutorial.md) begins with a point we can hold, then reads its movement. It will prepare two positions for the line.
'''
# Do not promise a named editable light in a generated scene; the museum is the
# verified light study, while the download remains the existing three conditions.
first=first.replace("In the supplied desktop study, select its light node in the scene tree and toggle visibility in the Inspector. That study has its own simpler lighting; use the museum to compare the long shadows at the switch.\n\n",'')
write('commons/maps/Point_One/tutorial.md',first)

reg=load('commons/artifacts/registry/commons_artifacts.json')
reg['artifacts']['point_sun_switch']={'lookup_name':'point_sun_switch','name':'Remove the sun','scene':'res://commons/primitives/point/point_sun_switch.tscn','category':'primitives','complexity':'beginner','description':'A wall switch removes the directional light over the Point One spheres; appearance and collision remain.','map_ready':True,'include_in_map_data':True,'map_sequences':['primitives'],'footprint':[0.4,1.7,0.3],'tags':['point','light','shadow','visibility']}
js('commons/artifacts/registry/commons_artifacts.json',reg)
seq=load('commons/maps/sequences/primitives.json');s=seq['sequences']['primitives']
s['maps'].insert(s['maps'].index('Point_One')+1,'Point_Coordinates')
# Content lists are chapter labels, usually map IDs.
if 'Point_One' in s.get('content',[]):s['content'].insert(s['content'].index('Point_One')+1,'Point_Coordinates')
group=next(g for g in s['artifact_groups'] if g['map']=='Point_One')
group.update(artifacts=['point_absent','point_visible','point_solid','point_sun_switch','point_pedestal'],rationale='Appearance, collision and light are separable attachments to a position.')
new=copy.deepcopy(group);new.update(map='Point_Coordinates',artifacts=['point_held','coordinate_readout','CoordinateSystem3M','drag_point_target'],rationale='Start by holding the point; name the world and local references that describe its movement.')
s['artifact_groups'].insert(s['artifact_groups'].index(group)+1,new)
js('commons/maps/sequences/primitives.json',seq)
decl=load('commons/data/map_authored.json');decl['primitives'].insert(decl['primitives'].index('Point_One')+1,'Point_Coordinates');js('commons/data/map_authored.json',decl)
book=load('commons/data/book/primitives.json');pearl=next(p for p in book['pearls'] if p['map']=='Point_One')
newpearl=copy.deepcopy(pearl);newpearl.update(pearl='coordinates',map='Point_Coordinates',hero='CoordinateSystem3M',rooms=2)
keep={'point_absent','point_visible','point_solid','point_pedestal'}
newpearl['lines']=[l for l in pearl['lines'] if l.get('token') not in keep]
for l in newpearl['lines']:
    if l.get('token')=='CoordinateSystem3M':l['config']={'adopt_external_point':1,'external_point_id':'point_one_main','floating_point':0};l['note_src']={'file':'commons/maps/Point_Coordinates/final.md','quote':'A coordinate needs its reference.'}
pearl.update(lines=[l for l in pearl['lines'] if l.get('token') in keep],hero='point_solid',rooms=2)
pearl['lines'].insert(3,dict(token='point_sun_switch',text='First there was light. Turn the switch.',by='author-directed',placed_by='grid'))
book['pearls'].insert(book['pearls'].index(pearl)+1,newpearl)
js('commons/data/book/primitives.json',book)

# Update the explicit teaching graph; cross-subject returns stay intact.
curr=load('doc/book/tutorial-lineage/curriculum.json');nodes=curr['nodes'];p=next(n for n in nodes if n['id']=='point')
p.update(requires=['loop'],label='Give a position a body',learn='Separate a position, its visible surface, collision and illumination.',make='A point whose appearance and physical boundary can differ.',transfer='Change the sphere radius while keeping the boundary, or the reverse.',borrow='Sphere construction; supplied light and switch. Coordinate reading and pickup follow in their own hall.')
nodes.insert(nodes.index(p)+1,dict(id='coordinates',sequence='primitives',label='Hold a point, name its reference',requires=['point','xr'],kind='build',learn='Use the supplied pickup; read and set X, Y and Z; distinguish local and world positions.',make='Two independently positioned markers, ready to become endpoints.',transfer='Move one marker in a translated parent; explain why the world address changes.',borrow='Production XR pickable, guides and cards. Portable XR starter is still pending.',status='proposed',halls=['Point_Coordinates']))
line=next(n for n in nodes if n['id']=='line');line['requires']=['coordinates' if r=='point' else r for r in line['requires']]
for issue in curr.get('issues',[]):
    for k in ['finding','action','title']:
        if isinstance(issue.get(k),str) and ('pickup' in issue[k].lower() or 'held' in issue[k].lower()):issue[k]=issue[k].replace('Point One','Point Coordinates').replace('Point_One','Point_Coordinates')
    if any('pickup' in str(issue.get(k,'')) for k in ['finding','action']):issue['nodes']=['coordinates' if n=='point' else n for n in issue['nodes']]
js('doc/book/tutorial-lineage/curriculum.json',curr)

# Only the changed hall rows are regenerated, keeping the user's plan elsewhere.
sys.path.insert(0,str(ROOT/'tools'));from em_map_halls import derive_row,normalize_row
plan=load('ada_run/em_plan.json');oldrow=next(p for p in plan['plans'] if p.get('map')=='Point_One');i=plan['plans'].index(oldrow)
rows=[]
for m,title in [('Point_One','point'),('Point_Coordinates','coordinates')]:
    row=derive_row(title,m,oldrow['museum'],decl['primitives'].index(m),len(decl['primitives']),'primitives')
    normalize_row(row,False,True);rows.append(row)
plan['plans'][i:i+1]=rows
for row in plan['plans']:
    if row.get('sequence')=='primitives':row['pearl_index']=decl['primitives'].index(row['map']);row['pearls_total']=len(decl['primitives'])
js('ada_run/em_plan.json',plan)
js('doc/book/iterations/2026-09-29-point-and-coordinates/changed-files.json',changed)
print('Split created:',len(changed),'files; Point Zero geometry and artifacts untouched.')
