"""Continue the tested Shaping code; retain optional museum encounters."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-patterns-the-same-circle'
MAP=ROOT/'commons/maps/Shader_05_Patterns'
PRIOR=ROOT/'doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube/learner/printed'
OUT.mkdir(parents=True,exist_ok=True);(OUT/'before').mkdir(exist_ok=True)
for name in ['tutorial.md','final.md','map_data.json']:
    if not (OUT/'before'/name).exists():shutil.copy2(MAP/name,OUT/'before'/name)
edits={
 'circle.gdshader':[
  ('uniform vec2 centre = vec2(0.5, 0.5);','uniform vec2 centre = vec2(0.5, 0.5);\nuniform vec2 repeats = vec2(3.0, 3.0);\nuniform float shift = 0.0;'),
  ('    float d = distance(UV, centre);','    vec2 tile_uv = fract(UV * repeats + vec2(shift, 0.0));\n    float d = distance(tile_uv, centre);')],
 'shaping.gd':[
  ('var radius := 0.30','var radius := 0.30\nvar shift := 0.0'),
  ('    var height := to_local(control.global_position).y','    var local_point := to_local(control.global_position)\n    var height := local_point.y\n    shift = local_point.x - 0.65'),
  ('    material.set_shader_parameter("radius", radius)','    material.set_shader_parameter("radius", radius)\n    material.set_shader_parameter("shift", shift)'),
  ('    readout.text = "Raise the point: radius %.2f\\nTrigger: %s edge" % [\n        radius, "soft" if soft else "hard"\n    ]','    readout.text = "Raise: radius %.2f | Sideways: shift %.2f\\nTrigger: %s edge" % [\n        radius, shift, "soft" if soft else "hard"\n    ]')],
 'point_body.gd':[]}
blocks={};sources={}
for name,changes in edits.items():
    p=PRIOR/name;sources[name]={'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    code=p.read_text(encoding='utf-8').rstrip()
    for old,new in changes:
        assert code.count(old)==1,(name,old)
        code=code.replace(old,new)
    blocks[name]=code
(OUT/'continuation.json').write_text(json.dumps({'incoming':sources,'edits':edits},indent=2)+'\n',encoding='utf-8')
def listing(name,lang):return f'<!-- student-code:{name} -->\n```{lang}\n{blocks[name]}\n```'
text='''# Patterns — the same circle, another address

## Learning elements

- Reuse the circle mask and shared material from Shaping.
- Multiply UV coordinates to set the repeat count.
- Separate a tile address from its local coordinates: `floor` and `fract`.
- Translate the lookup while keeping the mesh still.
- Recognize a period and predict which way the image moves.

Enter the patterned passage. The circle from the previous hall crosses its floor, walls, cube and chair. Move SHIFT while watching the chair's outline. The marks move; the chair stays. The room gives us a large version of the operation we will build.

## Continue your Shaping study

Keep its cube, two square receivers, material, PointBody and edge action. Keep raising the point to change radius. Add one gesture: moving it sideways changes the pattern's address. One metre of local movement adds one tile of shift. This is our chosen control scale, not a property of UV coordinates.

Copy the three files from Shaping into your Patterns lesson folder. Keep their names: `shaping.gd`, `circle.gdshader` and `point_body.gd`. Below is the complete resulting program. The host gains a shift value, its uniform connection and a revised label. The shader gains a repeat count and folds its lookup before calculating distance. PointBody is unchanged; its construction needs no new explanation.

The existing museum supplies the player, floor, camera, lights and bundled XR Tools. Open `res://doc/book/studies/shaders-lineage/Patterns.tscn` and Run Current Scene. This supplied launcher opens the actual Patterns hall and adds the learner study in the back-right bank of the patterned passage. Its `LESSON` preload points to `res://doc/book/iterations/2026-10-10-patterns-the-same-circle/learner/printed/shaping.gd`; change that path to use your saved copy. No production artifact fills gaps in the printed program. The launcher positions the study; it does not rebuild its lesson objects.

Pick up the point. Keep it at its starting height while moving sideways; then keep its horizontal position while raising it. These gestures change different parameters. Trigger still switches the edge. Release still freezes the point where you leave it.

## circle.gdshader

'''+listing('circle.gdshader','glsl')+'''

First multiply. On either axis, the square's 0–1 UV range becomes 0–3. Then add the horizontal shift. Finally `fract` returns the part after subtracting the floor: `fract(3.7)` is 0.7, and `fract(-0.2)` is 0.8. It works on both components of the vector.

The whole part identifies a tile: `floor(vec2(3.7, 1.2))` is `(3, 1)`. The fractional part locates a sample inside it: `(0.7, 0.2)`. This lesson needs only the fractional part because every tile uses the same circle. Later, keeping the whole address lets a rule choose a different orientation or colour for each tile.

The distance and edge operations are the ones you wrote in Shaping. They now receive `tile_uv` instead of `UV`. With three repeats on each axis, nine regions read the same rule. No loop creates nine meshes. A shader still runs over the visible fragments; repetition alone does not establish a performance measurement.

Radius is measured in tile coordinates. At radius 0.30 and three repeats, the circle's diameter spans 0.20 of the full square. That is 0.40 metres on the two-metre panel and 0.108 metres on the 0.54-metre cube receiver. The shared material gives them the same count, not the same size in metres.

## shaping.gd — keep the construction

'''+listing('shaping.gd','gdscript')+'''

`to_local` still measures the point in the study's frame. Subtracting its starting X, 0.65, makes that position shift zero. At X = 1.15 the shift is 0.5; at X = 1.65 it is 1.0. The new uniform name must match `shift` in the shader. All mesh and collision construction is carried from Shaping.

Adding a positive shift reads farther to the right in the repeated field. Consequently the marks move left on the square. Moving an object and moving the coordinates that read an image are different operations. At shift 1.0, `fract` gives the same local addresses as shift zero; the image returns while the point remains in its new position.

## point_body.gd — carried unchanged

'''+listing('point_body.gd','gdscript')+'''

## Predict, change, explain

Begin with hard edges, the point at `(0.65, 1.2, 1.2)`, and three repeats. There are three circles across and three down. The centre of the full square lies inside one circle. Move the point half a metre in local X: that fixed surface address now lies between circles. Move it one metre from its start: the pattern returns. Try minus one metre too. Explain why the material returns even though the point does not.

Keep radius 0.30. In the shader change `vec2(3.0, 3.0)` to `vec2(4.0, 2.0)`. Predict the count and proportions before running. There are now four across and two down. Each cell is twice as tall as it is wide, so these circles in tile coordinates look like tall ellipses on the square. Their local radius has not changed. This complete variation is tested alongside the original.

Choose another positive whole-number pair yourself, then predict its count and aspect. Try a fractional repeat count and look at the cropped cells at the boundary. Very fine repeats can shimmer or disappear at a distance because the screen has finite samples; increasing the count does not create more screen pixels. Return to `(3, 3)` for the next hall. Restore the point's start and hard edge to reset the comparison.

## Return to the larger room

The installation's DENSITY control uses repeats per metre on its architecture; our two squares use repeats across each UV domain. Its chair comparison supplies a projection adapter. Move CHAIR with ATTACH off: the chair crosses a pattern held in the room. Turn ATTACH on: the chair carries its pattern. Our UV study already stays attached to its receivers. You do not need to reconstruct the architectural projection to explain this first repetition.

The other rack offers Truchet arcs, staggered rows and further patterns. They show what can happen when the whole tile address also affects the rule. Visit them as comparisons; the required construction is the small repeated mask above. The existing flower garden and saved-record instrument are optional returns below.

Carry the same material, its coordinate convention and its parameters onward. In Materials, a change in surface orientation will alter how light reads a body; bump and normal mapping belong there. Nothing in this mask has yet moved a vertex or changed collision.

References: the coordinate-repetition exercise draws inspiration from [The Book of Shaders, Patterns](https://thebookofshaders.com/09/). Godot's [`floor` and `fract` reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shader_functions.html) gives their component-wise definitions. The museum adapter and code here use Godot spatial materials.

---

## Optional return: the pattern crosses a flower

The installed flower garden offers another receiver for the same question. Change phase while watching one petal. Its position stays fixed. In `commons/artifacts/reference_studies/pattern_garden.gd`, the supplied `surface()` recipe sets phase from the control amount; halve its original 0.5 multiplier to 0.25 and predict the reduced movement. This is a source-edit encounter using its supplied meshes and controls, not an additional required reconstruction.

'''
old=(OUT/'before/tutorial.md').read_text(encoding='utf-8')
optional=old[old.index('<!-- uncertainty:p4-record -->'):]
(MAP/'tutorial.md').write_text(text+optional,encoding='utf-8')
reflection=(OUT/'before/final.md').read_text(encoding='utf-8')
old_open=reflection[reflection.index('The long crossing'):reflection.index('<!-- @shader_05_patterns -->')]
new_open='''The circle has left its frame. It crosses the floor, a cube, a column and a chair. Slide the pattern and watch the chair's outline: something moves without carrying the chair with it. Move the chair instead. With the pattern held in the room, another part of it falls across the seat. Attach it to the chair and the marks travel with their support.

You have met tilings before, including the loom's crossing threads and the cloth that can be opened into layers. There, a pattern depended on how parts met. Here the repeated mark needs no new thread or tile. That difference becomes visible when the image can pass across a chair without moving it.

The smaller rack along the wall keeps four dark squares in its first mode, each with a desk, and MODE and RESET at the left. Go to the first square.

'''
reflection=reflection.replace(old_open,new_open)
a=reflection.index('Where are they? Not drawn.');b=reflection.index('The tiles are not quite identical',a)
reflection=reflection[:a]+'''There is a faint border drawn around each cell.[^border] But the border marks a division that already exists in the coordinates. Each sample multiplies its address by the grid size and keeps the fractional part. An address at 3.7 becomes 0.7, and so does one at 12.7. The same local position can now occur in many cells.

The seam is where that local coordinate begins again. It need not become a visible line. In the large circle installation, both sides of a cell boundary read the same background. In this smaller square, an extra border makes the division legible. We can draw attention to a boundary, or leave it unmarked, without changing where it falls.

'''+reflection[b:]
reflection=re.sub(r'```glsl\n.*?```\n\n','',reflection,flags=re.S)
reflection=reflection.replace('`uv.x += mod(row, 2.0) * 0.5;`: every second row is slid half a tile before the fold,','Every second row is slid half a tile before the fold,')
reflection=reflection.replace('So the floor returned, and it has no parts. There are seams at every whole number of every square in this hall. Some are shown, as the tile\'s step in brightness and the brick\'s mortar.','So the pattern returned. Its repetitions did not require separate pieces of floor. In the tiled studies, whole-number boundaries divide the coordinates. Some are shown, as the tile\'s border and the brick\'s mortar.')
reflection=reflection.replace('None is a join between two things, because there are no two things: there is one rule, asked at every pixel, and a coordinate that was folded before the rule saw it.','These seams are not joins between separately placed tiles. They belong to the way a rule reads a surface. The surface still has geometry; its repeated marks need not have separate bodies.')
reflection=reflection.replace('The dark sphere stands in front of the squares. It has no seams because it is one mesh. Everything behind it has seams because it is one function.','The dark sphere stands in front of the squares. No painted seam announces itself on its surface. Being one mesh would not guarantee that: its texture coordinates can still contain a join. A body\'s divisions and an image\'s divisions need not coincide.')
reflection=reflection.replace('The two Voronoi squares have no tiles to fold.','The two Voronoi squares divide their images by proximity.')
noise_start=reflection.index('Press MODE again. Noise synthesis:')
noise_end=reflection.index('\n\nSo the pattern returned.',noise_start)
reflection=reflection[:noise_start]+'''Press MODE again. Noise synthesis: a layered simplex field, a cellular distance field, a warped lookup. Their visible boundaries no longer follow the same repeated square. In the first, weighted contributions from a triangular lattice meet smoothly. In the second, the nearest point can change as you cross an edge. The third bends the coordinates before reading them. A surface can look continuous without those three operations being the same.[^smooth]'''+reflection[noise_end:]
reflection=reflection.replace("Some are smoothed, as the noise's zero slopes.","Some disappear into smooth contributions; others emerge when a different point becomes nearest.")
foot_start=reflection.index('[^smooth]:')
foot_end=len(reflection)
reflection=reflection[:foot_start]+'''[^smooth]: This rack uses `patterns_noise.gdshader`, not the basin's `fbm_basic.gdshader`. Its three modes use `simplex2d`, `worley`, and a domain-warped simplex lookup respectively. A square-lattice value-noise helper is also present but unused by these modes; its interpolation must not stand in for their different calculations. The separate Voronoi study searches nearby cell points for its two distances.'''+reflection[foot_end:]
reflection=reflection.replace('Press RESET if you have lost the defaults. The next hall has no desks at all, and nothing on its walls: the pictures end here, and bodies begin. Take the painted seam with you, the one that agreed only because both sides averaged.','Press RESET if you have lost the defaults. The next hall furnishes another room with familiar bodies under different surface responses. The pictures have already reached the chair. Next, light will make another claim about what that chair might be made of. Take the painted seam with you, the one that agreed only because both sides averaged.')
reflection+='\n[^border]: `patterns_tile.gdshader` adds a narrow, low-intensity band near each cell edge. Its tile tint and optional animation are separate operations. The larger passage\'s `repeated_mask.gdshader` has no added cell border.\n'
(MAP/'final.md').write_text(reflection,encoding='utf-8')
(OUT/'BRIEF.md').write_text('''# Patterns reconstruction contract

MAKE: repeat Shaping's circle; move its lookup with the same point; keep mesh/collision.
BRING: exact tested Shaping three-file output, shared material, UV square, local frame, radius/edge action.
GIVEN: museum/XR Tools and source-visible mount; architectural chair projection remains a supporting encounter.
BUILD: repeats + shift uniforms; fract before distance; point local X → shift. Y/radius and action/edge retained.
CHECK: counts, centres, boundary background; half shift changes, integer shift returns; positive shift moves marks left; negative shift; unequal repeats deform apparent aspect. Existing geometry retained. Deliberate missing fract/shift/frame defects rejected.
LATER: per-cell choices, full projection adapter, normals/bump, displacement. Keep existing optional saved-record text intact.

Printed full output must equal anchored edits in continuation.json applied to hashed Shaping predecessor. Test exact listings and vec2(4,2) variation. Mounted study is temporary learner space in the actual passage. No automatic cross-hall transport, headset or human-learning claim.
''',encoding='utf-8')
print('Wrote Patterns tutorial, reflection, anchored continuation and brief.')
