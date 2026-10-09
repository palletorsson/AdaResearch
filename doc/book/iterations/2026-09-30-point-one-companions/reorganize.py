from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[4]
if (ROOT / 'commons/maps/Point_One/README.md').exists():
    raise SystemExit('This one-time migration has already been applied. Edit canonical sources and run publish.py to refresh the review; do not replay the migration over later revisions.')
read = lambda p: (ROOT / p).read_text(encoding="utf-8-sig")
def write(p, text):
    (ROOT / p).write_text(text.strip() + "\n", encoding="utf-8")
def code(name):
    return '```gdscript\n' + read('doc/book/studies/point-one/' + name + '.gd').strip() + '\n```'

tutorial = '''# Point One — give the point a body

Point Zero gave us an instruction that runs when the scene is ready. Here we will use that moment to place a marker. The supplied scene already gives us a floor, a light and a view. We will keep those while changing what appears in front of us.

Open [the Point One study project](../../../doc/book/studies/point-one/README.md), then `study.tscn`. Its root is `PointStudy`. The three station nodes, `Position`, `Visible` and `Solid`, have `position.gd`, `visible.gd` and `solid.gd` attached. These are the three scripts we will change. Each station has its own “Point one” label.

Run the study. Above the first label there is nothing; above the next two are white spheres. Three small pink feelers move from left to right. Two cross their stations; the third stops at the solid sphere. The sweep repeats. Space pauses or resumes it; R starts the sweep again. `contact_probe.gd` supplies this contact test. Its movement is borrowed equipment, like the camera. We will change what it can cross.

## At the first label, nothing appears

Open `position.gd`. This is the whole script:

POSITION_CODE

We know `_ready()` from Point Zero; `-> void` says the function returns no value. Here we define a `Vector3`, a value containing three numbers, and name it `point_position`. For now, this is the supplied position at our station. Point Coordinates will make its three components the subject of a lesson.

Change `1.12` to `1.7` and run. Nothing appears at this station. We have changed a value without attaching a visible body to it. The editor's unused-variable warning describes that condition. The pink feeler still crosses the empty place. It belongs to the supplied test, not to the position we have just defined. Restore `1.12`.

## Give the position a surface

Open `visible.gd`. Its complete construction runs in the same familiar function:

VISIBLE_CODE

`point_position` is the location. `sphere` describes a spherical surface; `marker` is the node that displays it. `.new()` creates each part. Assigning `marker.mesh` gives that node its surface; assigning `marker.position` places it. `add_child(marker)` joins it to the station. A position and the object placed there are different things.

Change `1.12` to `1.7` in this script. Now the white sphere rises. Restore the height, then change `radius` from `0.14` to `0.3`. The sphere grows around the same centre. Its height follows because the script makes it twice the radius.

Watch the feeler cross the larger sphere. A visible surface has still given it nothing to collide with. We can change how much the sphere hides without changing what can pass through it. Restore the radius to `0.14`.

## Give the body a boundary

The third station looks the same. Its feeler stops. Open `solid.gd`:

SOLID_CODE

The first part constructs the same marker. The added `StaticBody3D` participates in collision. `SphereShape3D` describes its boundary, and `CollisionShape3D` attaches that shape to the physics body. The visible marker and this body are both placed at `point_position`.

Find `sphere_shape.radius = radius`. Change only that line to:

```gdscript
    sphere_shape.radius = 0.35
```

Run again. The white sphere stays small, but the feeler stops earlier, leaving a visible gap. The empty space resists it. **Debug → Visible Collision Shapes** can also reveal the larger boundary; the contact test works without that overlay.

We have chosen whether the surface we see and the boundary we encounter coincide. In the museum, it is your movement that meets this difference. The fixed-camera study supplies another moving body so we can test the same relation. Restore `sphere_shape.radius = radius`.

Try a different disagreement: in `solid.gd`, set the visible `radius` to `0.3` and `sphere_shape.radius` to `0.07`. The feeler enters the visible sphere before it stops. Pause with Space to look. Return both to the matching `0.14` when you finish.

## Remove the light, keep the body

In the museum, use the wall switch. The long shadows disappear while a dim fill leaves the spheres visible. The collision boundary stays where it was.

The decision in the switch is one line:

```gdscript
sun.visible = false
```

Here `sun` is the museum's directional light. This is a reading of that source, not a line to paste into `visible.gd`, which has no variable named `sun`. The portable study keeps its supplied light. Building the switch and its lighting rig is outside this lesson.

## What we can carry forward

We can now place a marker, change its surface around the same centre and give it a different physical boundary. The large sphere at the end of the museum corridor asks us to return to those choices: it still says “Point one”. Knowing its construction gives us another way to change the encounter.

[Point Coordinates](../Point_Coordinates/tutorial.md) begins with a supplied point we can hold, then reads its movement. It will prepare two positions for the line. The [construction reference](../../../doc/book/studies/point-one/CONSTRUCTION.md) keeps the roles of the supplied parts available without adding another required exercise.
'''
for name in ['position','visible','solid']:
    tutorial = tutorial.replace(name.upper() + '_CODE', code(name))
write('commons/maps/Point_One/tutorial.md', tutorial)
portable = tutorial.replace('../../../doc/book/studies/point-one/README.md','README.md').replace('../../../doc/book/studies/point-one/CONSTRUCTION.md','CONSTRUCTION.md').replace('[Point Coordinates](../Point_Coordinates/tutorial.md)', 'Point Coordinates (the next study, supplied separately)')
write('doc/book/studies/point-one/TUTORIAL.md', portable)
write('doc/book/studies/point-one/README.md', '''# Point One — give the point a body

Current study, 30 September 2026. Open this folder's project.godot; the main scene is study.tscn. Day Zero setup and Point Zero's _ready(), _process() and named values are assumed.

Start with TUTORIAL.md. PointStudy inherits the supplied base.tscn and contains three stations: Position uses position.gd; Visible uses visible.gd; Solid uses solid.gd. These are complete learner scripts. point_position is a Vector3 value; marker is the node displaying a surface at that position.

The supplied contact_probe.gd moves three pink feelers through the stations using actual physics collision. The empty and visible-only stations let them cross; the solid station stops one. The sweep repeats. Space pauses/resumes; R repeats. Changing the collision radius moves the stopping place independently of the visible sphere. The probe stays at the supplied height of 1.12 m; restore the height after the first experiment before comparing boundaries.

CONSTRUCTION.md names the borrowed parts and their roles. The fixed-camera study needs no XR add-on or player. The museum's sun switch, pedestal sphere and bodily traversal remain encounters there. Point Coordinates owns pickup, X/Y/Z and local/world references; its desktop study is supplied separately.

The current download contains only this lesson's scripts, scene, base, project settings and documentation. Older coordinates.tscn, points.gd, DAY_ZERO.md and POINT_ZERO.md remain in the repository as historical copies; they are not this study's starting instructions or part of the new download.
''')
write('doc/book/studies/point-one/CONSTRUCTION.md', '''# Point One — construction reference

Read TUTORIAL.md for the lesson. The complete runnable scripts are position.gd, visible.gd and solid.gd; their code is also shown there. This reference names the parts we borrow and the distinction each part makes.

| Part | What it supplies | What the learner changes |
| --- | --- | --- |
| base.tscn | Floor, light, fixed camera and an inherited Welcome label, hidden by study.tscn | Nothing in this lesson |
| study.tscn | Three station nodes and their Point one labels | Each attached script is identified in the tutorial |
| point_position | A Vector3 location inside a station | The supplied height; detailed component reading follows in Coordinates |
| SphereMesh | A surface description with radius and height | Visible radius while keeping the centre |
| marker / MeshInstance3D | The node displaying that surface | Its position is assigned from point_position |
| StaticBody3D and CollisionShape3D | A fixed body participating in physics and its attached shape | Its sphere radius, independently of the visible radius |
| contact_probe.gd | Small moving CharacterBody3D feelers and contact reports | Borrowed comparison equipment; pause with Space and repeat with R |

The probe uses move_and_collide; a collision returned by the physics engine stops it. Its labels report that result. The helper does not decide whether a station is solid by its name or by the visible sphere's radius. Its fixed height is 1.12 m and its feeler has a small width, so the stopping position includes that width and the physics margin. It is a contact comparison, not a ruler for the sphere's radius.

The three stations are placed separately by study.tscn. The same point_position value is relative to each station, so the spheres appear side by side. The next chapter makes reference frames explicit.

The position in position.gd is a local value inside _ready(); with no constructed child it draws nothing. In the later scripts, _ready() constructs nodes and attaches them to the station; those nodes remain in the scene after the function ends.

Neither declaring a grabbable group nor connecting unexplained signals creates an XR pickup here. Point Coordinates identifies the supplied museum pickable and keeps the missing portable XR starter explicit. Distance thresholds belong to Lines; proximity is not object identity.
''')

p='commons/maps/Point_One/intent.md'
text=read(p).replace('The tutorial changes the visible radius and the collision radius in the supplied three-condition study.', 'The tutorial names the supplied scene and shows three complete scripts. It changes the visible radius and the collision radius independently. A supplied moving feeler makes their disagreement observable in the fixed-camera study through actual physics contact.')
write(p,text)
write('commons/maps/Point_One/encounter-reference.md',text+'\n\nSee artifacts.md for the current placed inventory and technical.md for implementation. The encounter manuscript is final.md; tutorial.md is its making companion. Earlier research drafts do not override that division.')
p='commons/maps/Point_One/technical.md'
text=read(p).replace('Its code changes distinguish position, appearance and collision.', 'Its complete code examples distinguish point_position (a Vector3) from marker (a MeshInstance3D). The supplied contact_probe.gd creates three small CharacterBody3D feelers. Actual move_and_collide results stop a feeler; the other two cross. Space pauses and R repeats. Changing the authored collision radius changes where contact occurs without changing the rendered radius. The helper stays at height 1.12 m, so the height experiment must be restored before the radius comparison.')
write(p,text)

p='commons/maps/Point_Coordinates/tutorial.md'
text=read(p).replace('The study opens with two prepared sphere markers and the familiar coloured guides.', 'The desktop study opens with two prepared sphere markers and red, green and blue guides for X, Y and Z. The museum uses pink, grey and black; the letters and directions identify the references in either palette.')
text=text.replace('The target in this room already uses a distance threshold, but we can enjoy its falling response without bringing that calculation into this lesson yet.', 'The target in this room already uses a distance threshold. It asks whether a position is close enough, not whether two objects have the same identity. We can enjoy its falling response before calculating distance in Lines.')
write(p,text)
write('doc/book/studies/point-coordinates/TUTORIAL.md',text.replace('../../../doc/book/studies/point-coordinates/README.md','README.md'))
p='commons/maps/Point_Coordinates/technical.md'
text=read(p).replace('Its layout preserves the old wider room, shifting all retained coordinates eight source cells towards the entrance.', 'Its layout develops the old wider room; artifacts.md records the current placed cells.').replace('The separate force point retains its different identity.', 'The Fontana recess contains a secondary force comparison; the two cards explicitly select the original held point.')
write(p,text)

for name in ['Point_One','Point_Coordinates']:
    p=f'commons/maps/{name}/map_data.json'
    data=json.loads(read(p))
    placed=[(x,z,t) for z,row in enumerate(data['layers']['interactables']) for x,t in enumerate(row) if t.strip()]
    title='Point One' if name=='Point_One' else 'Point Coordinates'
    lines=[f'# {title} — current encounters','', '30 September 2026. Generated from the current map_data.json placements. Source cells are not runtime world coordinates.','', '| Artifact | Cell (x,z) | Configuration |','| --- | --- | --- |']
    for x,z,t in placed:
        token=t.split('#')[0].split(':')[0]
        lines.append(f'| `{token}` | ({x}, {z}) | `{t.strip()}` |')
    lines += ['', 'final.md follows the primary encounter; tutorial.md selects the operations to make. This inventory includes secondary works and practical equipment without making every object a required lesson.']
    write(f'commons/maps/{name}/artifacts.md','\n'.join(lines))
    data['map_info']['metadata']['n_artifacts']=len(placed)
    if name=='Point_One':
        width=max(map(len,data['layers']['structure']));depth=len(data['layers']['structure'])
        data['documentation']['layout']=f'{width} × {depth}. Corridor: absent (7,2), visible (7,5), solid (7,8). Wall switch (10,6) faces the corridor. A 1.3 m sphere stands at (8,12). Exit to Point_Coordinates.'
    else:
        data['documentation']['secondary']='The invisible point, code screen, radio, Fontana recess with embedded force comparison, floating field and comment box remain beside the primary route. Distance code belongs to Point_Lines.'
    write(p,json.dumps(data,ensure_ascii=False,indent=2))

p='doc/book/STUDENT_TOOLBOX.md'
write(p,read(p).replace('Change the visible and collision radii independently. Inspect the removable sun without teaching its renderer.', 'Change the visible and collision radii independently; observe actual contact with a supplied moving feeler. Inspect the removable sun without teaching its renderer.'))
p='doc/book/PRIMITIVES_LINEAGE.md'
write(p,read(p).replace('Working agreement, 29 September 2026.', 'Working agreement, updated 30 September 2026.')+'\n\n## Current opening sources\n\nPoint Zero/final.md carries arrival; its tutorial supplies once and again. Point One/final.md is “A body in the light”; its tutorial and the point-one study distinguish position, appearance and collision, with a supplied moving contact test. Point Coordinates owns pickup and references. Use the canonical map folders and current study downloads together. Earlier combined Point One captures remain historical readings, not instructions for the reorganized opening.')
print('Updated Point One lesson, study documentation, companion references and placed inventories; map layers preserved.')
