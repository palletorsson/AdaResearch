from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
read=lambda p:(ROOT/p).read_text(encoding='utf-8-sig')
load=lambda p:json.loads(read(p))
def write(p,s):
    dest=ROOT/p;before=OUT/'before'/p
    if dest.exists() and not before.exists():before.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,before)
    dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(s.encode('utf-8'))
def js(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
sha=lambda p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()

write('commons/maps/Point_One/intent.md','''# A body in the light

Point Zero supplies readiness and processing. Point One asks what must be attached to a position before it can appear or resist us. The corridor separates absence, a white surface, and an identical surface with collision. The wall switch then makes the directional light removable while keeping the body and its boundary. The large pedestal sphere closes this hall.

The main text follows those encounters. It keeps one position line but leaves component-by-component coordinates to the next hall. Its critical question is how apparently natural solidity and visibility are constructed separately.

The tutorial changes the visible radius and the collision radius in the supplied three-condition study. It reads the sun switch as one decision, without teaching a shadow renderer. Students leave able to change appearance and resistance independently. Point_Coordinates then begins with pickup, names the frame, and prepares two positions for Point_Lines.

The coordinate frame, cards, target and retained secondary comparisons have moved together to Point_Coordinates. Their removal from this hall is a pedagogical split, not a rejection of their work. The actual origin marker and its Point zero label remain in Point_Zero.
''')
write('commons/maps/Point_One/technical.md','''# Point One — implementation reference

The active corridor contains point_absent, point_visible, point_solid and point_pedestal, built by commons/primitives/point/point_condition.gd. The absent condition creates no sphere. Visible and solid have radius 0.14 m; only solid adds a fixed collision sphere. The final sphere has radius 0.65 m, centre height 1.40 m and a pedestal whose top is 0.75 m.

point_sun_switch.gd adds a directional light for the study spheres and their shadow receivers. These use visual layer 18, distinct from collision layers. Its caster mask excludes architecture so the lesson is not accidentally shadowed by a streamed roof. A low, unshadowed local fill keeps the bodies readable when the sun is hidden. Other lights exclude only this dedicated surface layer; their previous masks are restored when the study unloads. The receiver plates do not cast shadows themselves.

The wall lever uses the production XRTools area button with pointer support: near-hand entry or pointer press toggles sun.visible. Its 1.28 m control height is a design value, not a headset comfort certification. The plate sits on the inside face of the corridor's right wall. The entry door remains.

The portable Point One study retains its three reduced scripts: position.gd, visible.gd and solid.gd. Its code changes distinguish position, appearance and collision. The sun switch is inspected in the museum; its full lighting rig is not part of that portable kit.

Pickup, WORLD/LOCAL cards, frame, L-shaped basin and target now belong to Point_Coordinates. See its technical.md for the maintained point_one_main channel and all moved placements. Distance is first calculated in the Point_Lines tutorial.
''')
write('commons/maps/Point_One/summary.md','''# Point One

A label names an absent point. A white sphere gives it a surface; the next sphere adds resistance. Turn a wall switch and remove the light that made their crooked shadows. The bodies remain. A large sphere repeats the name before we enter Coordinates and take a point in hand.
''')
write('commons/maps/Point_One/blurb.md','A point is given a surface, a boundary and light. Turn the switch. Which of its powers have you removed?\n')
critical=read('commons/maps/Point_One/critical.md')
write('commons/maps/Point_One/critical.md','''> Current placement, 29 September 2026: Point One now holds absence, visibility, collision, a removable directional light and the pedestal sphere. Holding, WORLD/LOCAL, the frame and target have moved to Point_Coordinates. The older research below remains as material, not a claim that every referenced artifact still stands in this hall.

'''+critical)
for m in ['Point_One','Point_Coordinates']:
    d=load(f'commons/maps/{m}/map_data.json');rows=[]
    for z,row in enumerate(d['layers']['interactables']):
        for x,t in enumerate(row):
            if t.strip():rows.append(f'| `{t.split(":")[0].split("#")[0]}` | ({x}, {z}) | `{t}` |')
    write(f'commons/maps/{m}/artifacts.md',f'# {m.replace("_"," ")} — current encounters\n\n29 September 2026. Source cells below are not runtime world positions.\n\n| Artifact | Cell (x,z) | Configuration |\n|---|---|---|\n'+'\n'.join(rows)+'\n')
    write(f'commons/maps/{m}/encounter-reference.md',read(f'commons/maps/{m}/intent.md')+'\nSee artifacts.md for current cells and technical.md for implementation.\n')

# A dedicated desktop coordinate kit; old filenames remain available in the
# Point One kit for compatibility but are no longer presented as its lesson.
study='doc/book/studies/point-coordinates/'
for name in ['base.tscn','coordinates.tscn','points.gd']:
    write(study+name,read('doc/book/studies/point-one/'+name))
points=read(study+'points.gd')
points+='\n    print("local ", $A.position)\n    print("world ", $A.global_position)\n'
write(study+'points.gd',points)
write(study+'project.godot',read('doc/book/studies/point-one/project.godot').replace('Point One — building a point','Point Coordinates — two addresses').replace('res://study.tscn','res://coordinates.tscn'))
write(study+'TUTORIAL.md',read('commons/maps/Point_Coordinates/tutorial.md').replace('../../../doc/book/studies/point-coordinates/README.md','README.md'))
write(study+'README.md','''# Point Coordinates — two addresses

This standalone Godot 4.6 desktop study inherits the supplied Day Zero base. Open project.godot; coordinates.tscn is the main scene. points.gd places A and B and prints A's local and world positions. No plugins or external assets are required.

Follow TUTORIAL.md: change one component, move the root reference, and keep a second position. The base's camera moves with the root, so the image can stay the same while the printed world address changes.

The black point can be held in the full Ada museum using its existing XR player. This download supplies the coordinate portion, not an XR player or a simulated hand. The standalone pickup starter remains separate work.
''')
write('doc/book/studies/point-one/README.md','''# Point One — give the point a body

The current tutorial follows absence, visibility and resistance, then encounters removable light and the pedestal sphere in the museum. study.tscn is the portable three-condition comparison. position.gd, visible.gd and solid.gd are its supplied scripts; TUTORIAL.md selects the actual lines to change.

Point_Coordinates now owns the black held point and the component-by-component coordinate lesson. Its dedicated portable kit is ../point-coordinates/. The older coordinates.tscn and points.gd remain here for compatibility, but no longer define the first Point One lesson.

Neither desktop kit includes an XR player. The museum supplies pickup. CONSTRUCTION.md preserves the earlier fuller construction notes; current selection and order come from TUTORIAL.md. DAY_ZERO.md and POINT_ZERO.md contain the preceding preparation and game-loop material.
''')
write('doc/book/studies/point-one/TUTORIAL.md',read('commons/maps/Point_One/tutorial.md').replace('../../../doc/book/studies/point-one/README.md','README.md').replace('../Point_Coordinates/tutorial.md','../point-coordinates/TUTORIAL.md'))

p='doc/book/TUTORIAL_LINEAGE.md';s=read(p)
s=s.replace('In that scene, a point becomes visible, resists contact, and can be carried.','In that scene, a point becomes visible and resists contact; a switch makes its light removable. The next hall begins by carrying the point and naming its reference.')
start=s.index('| Point One |');end=s.index('| Point Lines |',start)
s=s[:start]+'''| Point One | A script that begins and prepared surroundings | Separate a position, its visible surface, collision and illumination | Change the surface and physical boundary independently |
| Point Coordinates | A point with a visible and physical body; a supplied XR route when used | Use pickup; read and set X/Y/Z; distinguish local and world positions | Two independently positioned markers ready to become endpoints |
'''+s[end:]
s=s.replace("Point One's reusable held point","Point Coordinates' reusable held point")
s=s.replace('Point One should introduce use of the supplied XR pickable','Point Coordinates should introduce use of the supplied XR pickable')
s=s.replace('in Point One','in Point Coordinates')
write(p,s)
p='doc/book/STUDENT_TOOLBOX.md';s=read(p).replace('pickup component in Point One','pickup component in Point Coordinates')
start=s.index('| Point_One |');end=s.index('| Point_Lines |',start)
s=s[:start]+'''| Point_One | Encounter appearance, resistance and light | Change the visible and collision radii independently. Inspect the removable sun without teaching its renderer. |
| Point_Coordinates | Hold a point; name its reference | Use the supplied pickup in Ada; change X/Y/Z in the desktop study; distinguish local and world position and prepare A and B. Portable XR starter pending. |
'''+s[end:]
write(p,s)
p='doc/book/tutorial-lineage/atlas.html';s=read(p).replace('../2026-09-29-point-zero-hello-world/point-one.html#making','/compose/sources?map=Point_One&amp;doc=tutorial')
write(p,s)

p='commons/data/museum_core_encounters.json';d=load(p)
for m,tokens,reason in [
('Point_One',['point_absent','point_visible','point_solid','point_sun_switch','point_pedestal'],'Separate appearance, collision and light. Pickup and references continue in their own hall.'),
('Point_Coordinates',['point_held','coordinate_readout','CoordinateSystem3M','drag_point_target'],'Begin with the held point; follow its addresses and let different arrivals meet one target.')]:
    d['rooms'].setdefault(m,{}).update(sequence='primitives',primary_tokens=tokens,reason=reason,status='revised_native_desktop_checked',text_path=f'commons/maps/{m}/final.md',text_sha256=sha(f'commons/maps/{m}/final.md'),map_sha256=sha(f'commons/maps/{m}/map_data.json'),learner_verified=False,local_review='doc/book/iterations/2026-09-29-point-and-coordinates/index.html')
js(p,d)
print('Tutorials, study, intent, artifact references and teaching agreement aligned.')
