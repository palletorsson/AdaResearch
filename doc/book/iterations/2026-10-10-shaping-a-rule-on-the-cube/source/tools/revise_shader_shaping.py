"""Write the focused first shader lesson; preserve the earlier reflection."""
from pathlib import Path
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube'
MAP=ROOT/'commons/maps/Shader_01_Shaping'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'before').mkdir(exist_ok=True)
for name in ['final.md','map_data.json']:
    if not (OUT/'before'/name).exists():shutil.copy2(MAP/name,OUT/'before'/name)
POINT=ROOT/'doc/book/studies/tiling-lineage/point_body.gd'
point=POINT.read_text(encoding='utf-8').rstrip()
assert point==(ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry/learner/printed/point_body.gd').read_text().rstrip()
shader='''shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float radius = 0.30;
uniform float softness = 0.0;
uniform vec2 centre = vec2(0.5, 0.5);
uniform vec4 ground : source_color = vec4(0.032, 0.039, 0.046, 1.0);
uniform vec4 ink : source_color = vec4(0.93, 0.89, 0.82, 1.0);

void fragment() {
    float d = distance(UV, centre);
    float mask = 1.0 - step(radius, d);
    if (softness > 0.0) {
        mask = 1.0 - smoothstep(radius - softness, radius + softness, d);
    }
    ALBEDO = mix(ground.rgb, ink.rgb, mask);
}'''
host='''extends Node3D

const PointBody = preload("point_body.gd")
const Circle = preload("circle.gdshader")
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var radius := 0.30
var soft := false
var receivers: Array[MeshInstance3D] = []

func _ready() -> void:
    material.shader = Circle
    make_box(Vector3(0, 1.6, -0.08), Vector3(2.2, 2.2, 0.1))
    make_receiver(Vector2(2, 2), Vector3(0, 1.6, 0))
    make_box(Vector3(0, 0.8, 1.0), Vector3(2.2, 0.1, 0.8))
    make_box(Vector3(-0.65, 1.15, 1.0), Vector3.ONE * 0.6)
    make_receiver(Vector2(0.54, 0.54), Vector3(-0.65, 1.15, 1.306))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.action_pressed.connect(toggle_edge)
    readout.position = Vector3(0, 2.85, 0)
    readout.font_size = 36
    readout.pixel_size = 0.002
    add_child(readout)
    update_rule()

func make_receiver(size: Vector2, at: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var square := QuadMesh.new()
    square.size = size
    surface.mesh = square
    surface.material_override = material
    surface.position = at
    add_child(surface)
    receivers.append(surface)

func make_box(at: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)

func _process(_delta: float) -> void:
    update_rule()

func toggle_edge(_point) -> void:
    soft = not soft
    update_rule()

func update_rule() -> void:
    var height := to_local(control.global_position).y
    radius = clampf(0.30 + (height - 1.2) * 0.38, 0.08, 0.46)
    material.set_shader_parameter("radius", radius)
    material.set_shader_parameter("softness", 0.045 if soft else 0.0)
    readout.text = "Raise the point: radius %.2f\\nTrigger: %s edge" % [
        radius, "soft" if soft else "hard"
    ]'''
text='''# Shaping — a rule on the cube

## Learning elements

- A spatial shader and `fragment()`.
- UV coordinates on a square receiver.
- A distance field and a circle mask.
- Uniforms connecting an existing hand control to a material.
- Hard and gradual boundaries: `step` and `smoothstep`.
- One material shared by two receivers.

At the large wall in Shaping, move RADIUS and press EDGE. Watch the mark on the small cube change with the wall. The cube stays where it is. The circle is a rule for its visible colour.

## Keep the body; change its reading

You bring the cube from Transformation, the grabbable PointBody, functions, distance, colour mixing and Tiling's separation of source from receiver. Earlier shader encounters supplied their material rules. Here you write one of those rules yourself.

Build a small version inside the prepared museum. The same point becomes its radius control. The wall and a square on the cube share one material; you write the function that material evaluates. No stored trace or new mesh topology is needed.

The museum supplies its floor, player, camera, lighting and XR Tools. The complete program below creates every lesson-owned mesh, collider and label. `point_body.gd` is unchanged from the Tiling learner code, printed once here to keep the dependency available. No prebuilt mesh child is required.

## Run it in the museum

Save all three files together. The supplied in-project launch scene is `res://doc/book/studies/shaders-lineage/Shaping.tscn`. Open it and use Run Current Scene. It opens the actual museum at Shader_01_Shaping and mounts the printed files from `res://doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube/learner/printed/`. Edit those three files for the experiment. The room launcher is supplied support; it creates no lesson geometry and reads no production shader to fill gaps in your program.

For your own saved copy, change the launcher's `LESSON` preload to its `shaping.gd`. The launcher attaches it to an empty Node3D at map-space `(14, 0, 5)` metres, unit scale, turned 180 degrees around Y toward the entrance. A translated hall has its own origin: these are map coordinates, not world coordinates. Running an empty Node3D alone supplies no player or camera.

Pick up the point. Raise it to enlarge both circles; lower it to shrink them. Press its action trigger to switch hard/soft edges. The existing desktop pickup action can drive the same PointBody. Releasing it leaves it frozen where you put it. Return its centre to local height 1.2 metres for radius 0.30; press the trigger again to restore the hard edge.

### circle.gdshader — the new rule

<!-- student-code:circle.gdshader -->
```glsl
SHADER
```

`shader_type spatial` makes this a material for a 3D surface. `fragment()` computes a material value at a visible sample of that surface. `unshaded` isolates the colour rule from the lamps; `cull_disabled` allows the square to draw from either side. These switches do not make an opening in its backing.

`UV` is the coordinate supplied by the mesh. Each square runs from 0 to 1 in each direction, with `(0.5, 0.5)` at its centre. These are surface addresses, not metres. The two square receivers have different physical sizes but the same coordinate range. A rectangular receiver would stretch this circle unless you corrected its aspect ratio.

`distance` returns a number at every address. `step(radius, d)` returns 0 when `d` is below the radius and 1 at or beyond it. Subtracting from 1 makes the inside 1. `mix` then chooses ground at 0, ink at 1, and intermediate colours between. The mask does not change opacity: both colours are opaque.

For a soft edge, `smoothstep` rises gradually between `radius - softness` and `radius + softness`. Subtraction reverses that rise. A softness of 0.045 makes the whole transition 0.09 UV units wide. The `if` keeps the hard case separate, so `smoothstep` never receives equal edges.

A `uniform` is an input shared by all samples using this material. GDScript writes radius and softness below. The GPU uses their current values whenever it draws the surface; this shader stores no earlier image. `vec2` has two components; `vec4` holds the four colour components. `source_color` declares colour inputs, and `.rgb` selects the three components assigned to `ALBEDO`. [Godot spatial shader reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html).

### shaping.gd — give the rule a body and a control

Read `update_rule()` first. The earlier local-coordinate operation turns hand height into a bounded radius. `set_shader_parameter` sends that number under the exact uniform name. The rest constructs familiar receivers and connects the point's existing action.

<!-- student-code:shaping.gd -->
```gdscript
HOST
```

There is one ShaderMaterial. Both receivers refer to it. Updating its radius changes both, without rebuilding either mesh. The cube's ordinary BoxMesh uses an atlas of UV regions; the small square on its front supplies a complete 0–1 domain so that atlas does not become a hidden lesson. The wall uses the same kind of square. Their solid box backings have separate collision shapes.

`to_local` keeps the control relative to this study even when the whole study turns or moves. Ten centimetres upwards adds 0.038 to the radius; `clampf` keeps it between 0.08 and 0.46. The trigger changes softness, not radius. Moving the point changes the input; it never moves the surface boundary as geometry.

### point_body.gd — the carried point, unchanged

Its earlier job remains: a visible sphere with matching collision, grabbable through the prepared XR Tools player, frozen when released. The inherited `action_pressed` signal is the connection this lesson uses. You are not rebuilding the pickup system.

<!-- student-code:point_body.gd -->
```gdscript
POINT
```

## Predict, change, explain

1. With a hard edge and radius 0.30, predict the result at UV `(0.5, 0.5)`, `(0.9, 0.5)` and `(0.1, 0.1)`. They are inside, outside and outside. Raise the point until the radius reaches 0.46. The second address enters; the corner stays outside.
2. Keep that radius. Switch to a soft edge. The centre remains ink and the distant corner remains ground; only a band near the boundary mixes them. The cube's silhouette and collision remain unchanged.
3. Change the shader's centre declaration to `uniform vec2 centre = vec2(0.35, 0.65);`. Restart with radius 0.30. Both marks move to the same new UV centre, but the wall's movement covers more metres. The point still changes radius. Restore `(0.5, 0.5)` afterwards. The complete variation is included in the review download.

Explain why one uniform changes two images, why their physical diameters differ, and why the visible circle does not let you reach through the backing. Then choose another centre that keeps the hard circle inside the square: each centre component must stay at least the radius from its nearest edge. Check your prediction before running it.

## Return to the room

The five graphs show other ways to turn an input into a value. Compare STEP and SMOOTHSTEP with your edge switch. The sine graph also uses the museum clock; it does not use your held point's radius or remember a previous image. Those supporting encounters need not become five additional programs.

Keep these three files. Patterns will reuse the circle function and change the coordinates used to read it. Later, Queer Materials introduces how normals affect light; FBM Water separates a bump made through normals from displacement made through vertices. The vertex program and collision remain different systems. We will teach those distinctions there, after this first colour rule.

The approach draws on the distance-field examples in [The Book of Shaders: Shapes](https://thebookofshaders.com/07/), adapted here to the museum's cube, square receivers and carried PointBody.
'''.replace('SHADER',shader).replace('HOST',host).replace('POINT',point)
(MAP/'tutorial.md').write_text(text,encoding='utf-8')
(OUT/'carried-files.json').write_text(json.dumps({'point_body.gd':str(POINT.relative_to(ROOT)).replace('\\','/')},indent=2)+'\n',encoding='utf-8')

# Retain the reflective sequence's detailed observation; align changed places and
# remove implementation listings now owned by the tutorial.
final=(OUT/'before/final.md').read_text(encoding='utf-8')
final=final.replace('Your question can wait at the door. Five dark squares hang in a row along the wall, pictures two metres on a side, each with a desk in front of it, and one of the five is already moving with nobody at its desk. Begin with one that holds still.',
'''A pale circle holds its place on the dark wall. A smaller one sits on the cube in front of it. Move RADIUS and both expand. Press EDGE and both soften. They share a rule, but they do not occupy the same amount of the room.

<!-- @shader_shaping_wall -->

The soft edge offers an interval where the hard edge offered a cut. That difference matters to what you see. It grants no passage through either backing. A boundary can become gentle in its appearance while remaining just as firm to the body.

Across the room, five dark squares hang in a row, each with a desk in front of it. One is already moving with nobody at its desk. Begin with one that holds still.''')
final=final.replace('They were computed in the same instant, by the same rule, from different positions.','They are evaluated by the same rule at different positions; neither waits for a message from its neighbour.')
start=final.index("The desk's line names the rule:")
end=final.index("The picture of a discontinuity",start)
final=final[:start]+'''The desk names it STEP. Below the threshold its answer is zero; at or above the threshold it is one. The lighter band and the white stroke show that answer in different ways. Yet the stroke has a width, and its own edges fade.

'''+final[end:]
final=final.replace('Here is the line:\n\n```glsl\nfloat func_val = 0.5 + amplitude * sin(frequency * uv.x * 6.28318 + TIME * phase_speed);\n```\n\n','')
final=final.replace("You came from halls where noise was made and then kept: a column of values, a voxel field, a wall. Nothing in this hall is kept. The graphs are asked, every frame, from nothing, and all they are asked with is a position, a few numbers from the desks, and the clock.",
"You came from halls where noise was made and then kept: a column of values, a voxel field, a wall. These materials retain their parameters, but neither the new circle nor the graphs receives its previous image. Each is asked again from coordinates and current inputs. The moving graph also asks the clock.")
final=final.replace('Everything in this hall is also flat, and hangs on a wall. The sequence begins with pictures. Two halls on it moves to bodies, and after that to rooms.',
'The circle on the cube already crosses from picture to body. For now it occupies a flat receiver on one face; it does not reshape the cube. In the rooms ahead the surface will repeat, take light differently, and move. Each change asks us to locate what changed.')
(MAP/'final.md').write_text(final,encoding='utf-8')
(OUT/'BRIEF.md').write_text('''# Shaping reconstruction contract

MAKE: one circle mask, shared by wall/cube; hand height changes radius; trigger changes edge.
BRING: Tiling PointBody unchanged; cube/mesh/material/collision construction, local frames, distance, functions and colour mixing.
GIVEN: existing museum/player/camera/lights/XR Tools. No production artifact supplies lesson-owned initialization.
BUILD: complete shaping.gd + circle.gdshader; print carried point_body.gd once. Host creates both square receivers, backings and control. One ShaderMaterial; exact uniform-name connection.
CHECK: GPU inside/outside, enlargement, soft band; local-frame invariance; shared material, fixed mesh/collision; real action signal; off-centre variation; omitted uniform/inverted mask/wrong frame must fail ordinary assertions.
LATER: repetition, lit normals, per-pixel bump/normal map, vertex displacement, retained state. No automatic cross-hall node transport claimed.

Placement: optional learner study at map(14,0,5), yaw180. Production room/map and installed artifact unchanged. Museum probe adds extracted learner source temporarily. Native tests establish execution/behaviour; no learner understanding or headset claim. Review includes tutorial left, reflection right, actual museum screenshot, before/after prose and exact extracted files.
''',encoding='utf-8')
print('Wrote Shaping tutorial and aligned reflection; map and installed artifacts unchanged.')

