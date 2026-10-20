# Shaders — what a surface answers to

You are already inside Endless Museum. Walk the hall before reconstructing its selected operation. Some artifacts belong to the tutorial, some to the reflective text, some to both, and some remain encounters without either text. You do not have to rebuild the whole collection.

You bring the point and cube, coordinates and transforms, arrays and loops, functions and classes, colour, periodic motion and sampled noise. The shader sequence returns to those abilities in another place: the material attached to a surface. If one of those returns is unfamiliar, revisit its earlier lesson rather than treating this sequence as an introduction to programming.

The tutorial and reflection do different work. Build, predict and change through the tutorial. Read the reflection beside the encounter, including its wider collection. Neither text replaces the other, and every artwork does not need to become an exercise.

You continue a small program through six lessons. Each supplied launcher instantiates your current version beside the museum's exhibits. This is continuity of the code and the object's construction; the launchers do not automatically carry a held instance or save its state between halls. Keep a copy of each working lesson before continuing.

Each chapter prints its complete program once, including carried code. Start with its changed function or shader, then return to the construction when needed. Prepared player, camera, XR tools and any other supplied support are named. The figures are captures from Godot; some show the learner reconstruction beside a larger installed artifact with separate controls.

Required route: **mask → repeated lookup → normals and light → vertex height → composition → retained field**. Garden, saved-record and plural-body returns are collected after that route. They remain available without becoming prerequisites for the next shader lesson.

Run the program, predict a result, change a value, and explain what the comparison establishes. A passing program is evidence that its operation can be reconstructed. It cannot establish what you understood or whether the form you chose matters to you.


---

# Shaping — a rule on the cube

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

For your own saved copy, change the launcher's `LESSON` preload to its `shaping.gd`. It adds your script as a new Node3D at map-space `(14, 0, 5)` metres, unit scale, turned 180 degrees around Y toward the entrance. The hall node includes a four-metre vestibule, so the launcher's local position is `(14, 0, 9)`. These are local coordinates, not world coordinates. The supplied launcher opens this lesson independently of your saved museum position. Running an empty Node3D alone supplies no player or camera.

Pick up the point. Raise it to enlarge both circles; lower it to shrink them. Press its action trigger to switch hard/soft edges. The existing desktop pickup action can drive the same PointBody. Releasing it leaves it frozen where you put it. Return its centre to local height 1.2 metres for radius 0.30; press the trigger again to restore the hard edge.

### circle.gdshader — the new rule

<!-- student-code:circle.gdshader -->
```glsl
shader_type spatial;
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
}
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
extends Node3D

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
    readout.text = "Raise the point: radius %.2f\nTrigger: %s edge" % [
        radius, "soft" if soft else "hard"
    ]
```

There is one ShaderMaterial. Both receivers refer to it. Updating its radius changes both, without rebuilding either mesh. The cube's ordinary BoxMesh uses an atlas of UV regions; the small square on its front supplies a complete 0–1 domain so that atlas does not become a hidden lesson. The wall uses the same kind of square. Their solid box backings have separate collision shapes.

`to_local` keeps the control relative to this study even when the whole study turns or moves. Ten centimetres upwards adds 0.038 to the radius; `clampf` keeps it between 0.08 and 0.46. The trigger changes softness, not radius. Moving the point changes the input; it never moves the surface boundary as geometry.

### point_body.gd — the carried point, unchanged

Its earlier job remains: a visible sphere with matching collision, grabbable through the prepared XR Tools player, frozen when released. The inherited `action_pressed` signal is the connection this lesson uses. You are not rebuilding the pickup system.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
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


---

# Patterns — the same circle, another address

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

<!-- student-code:circle.gdshader -->
```glsl
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float radius = 0.30;
uniform float softness = 0.0;
uniform vec2 centre = vec2(0.5, 0.5);
uniform vec2 repeats = vec2(3.0, 3.0);
uniform float shift = 0.0;
uniform vec4 ground : source_color = vec4(0.032, 0.039, 0.046, 1.0);
uniform vec4 ink : source_color = vec4(0.93, 0.89, 0.82, 1.0);

void fragment() {
    vec2 tile_uv = fract(UV * repeats + vec2(shift, 0.0));
    float d = distance(tile_uv, centre);
    float mask = 1.0 - step(radius, d);
    if (softness > 0.0) {
        mask = 1.0 - smoothstep(radius - softness, radius + softness, d);
    }
    ALBEDO = mix(ground.rgb, ink.rgb, mask);
}
```

First multiply. On either axis, the square's 0–1 UV range becomes 0–3. Then add the horizontal shift. Finally `fract` returns the part after subtracting the floor: `fract(3.7)` is 0.7, and `fract(-0.2)` is 0.8. It works on both components of the vector.

The whole part identifies a tile: `floor(vec2(3.7, 1.2))` is `(3, 1)`. The fractional part locates a sample inside it: `(0.7, 0.2)`. This lesson needs only the fractional part because every tile uses the same circle. Later, keeping the whole address lets a rule choose a different orientation or colour for each tile.

The distance and edge operations are the ones you wrote in Shaping. They now receive `tile_uv` instead of `UV`. With three repeats on each axis, nine regions read the same rule. No loop creates nine meshes. A shader still runs over the visible fragments; repetition alone does not establish a performance measurement.

Radius is measured in tile coordinates. At radius 0.30 and three repeats, the circle's diameter spans 0.20 of the full square. That is 0.40 metres on the two-metre panel and 0.108 metres on the 0.54-metre cube receiver. The shared material gives them the same count, not the same size in metres.

## shaping.gd — keep the construction

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Circle = preload("circle.gdshader")
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var radius := 0.30
var shift := 0.0
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
    var local_point := to_local(control.global_position)
    var height := local_point.y
    shift = local_point.x - 0.65
    radius = clampf(0.30 + (height - 1.2) * 0.38, 0.08, 0.46)
    material.set_shader_parameter("radius", radius)
    material.set_shader_parameter("shift", shift)
    material.set_shader_parameter("softness", 0.045 if soft else 0.0)
    readout.text = "Raise: radius %.2f | Sideways: shift %.2f\nTrigger: %s edge" % [
        radius, shift, "soft" if soft else "hard"
    ]
```

`to_local` still measures the point in the study's frame. Subtracting its starting X, 0.65, makes that position shift zero. At X = 1.15 the shift is 0.5; at X = 1.65 it is 1.0. The new uniform name must match `shift` in the shader. All mesh and collision construction is carried from Shaping.

Adding a positive shift reads farther to the right in the repeated field. Consequently the marks move left on the square. Moving an object and moving the coordinates that read an image are different operations. At shift 1.0, `fract` gives the same local addresses as shift zero; the image returns while the point remains in its new position.

## point_body.gd — carried unchanged

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

## Predict, change, explain

Begin with hard edges, the point at `(0.65, 1.2, 1.2)`, and three repeats. There are three circles across and three down. The centre of the full square lies inside one circle. Move the point half a metre in local X: that fixed surface address now lies between circles. Move it one metre from its start: the pattern returns. Try minus one metre too. Explain why the material returns even though the point does not.

Keep radius 0.30. In the shader change `vec2(3.0, 3.0)` to `vec2(4.0, 2.0)`. Predict the count and proportions before running. There are now four across and two down. Each cell is twice as tall as it is wide, so these circles in tile coordinates look like tall ellipses on the square. Their local radius has not changed. This complete variation is tested alongside the original.

Choose another positive whole-number pair yourself, then predict its count and aspect. Try a fractional repeat count and look at the cropped cells at the boundary. Very fine repeats can shimmer or disappear at a distance because the screen has finite samples; increasing the count does not create more screen pixels. Return to `(3, 3)` for the next hall. Restore the point's start and hard edge to reset the comparison.

## Return to the larger room

The installation's DENSITY control uses repeats per metre on its architecture; our two squares use repeats across each UV domain. Its chair comparison supplies a projection adapter. Move CHAIR with ATTACH off: the chair crosses a pattern held in the room. Turn ATTACH on: the chair carries its pattern. Our UV study already stays attached to its receivers. You do not need to reconstruct the architectural projection to explain this first repetition.

The other rack offers Truchet arcs, staggered rows and further patterns. They show what can happen when the whole tile address also affects the rule. Visit them as comparisons; the required construction is the small repeated mask above. The existing flower garden and saved-record instrument are optional returns below. Complete the repeated-circle study before choosing either. The saved-record exercise is a separate data-reading lesson; Materials does not depend on it.

Carry the same material, its coordinate convention and its parameters onward. In Materials, a change in surface orientation will alter how light reads a body; bump and normal mapping belong there. Nothing in this mask has yet moved a vertex or changed collision.

References: the coordinate-repetition exercise draws inspiration from [The Book of Shaders, Patterns](https://thebookofshaders.com/09/). Godot's [`floor` and `fract` reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shader_functions.html) gives their component-wise definitions. The museum adapter and code here use Godot spatial materials.


[Optional returns from this hall](appendices.html#Shader_05_Patterns). Continue to the next main chapter when ready.


---

# Materials — light without height

## Learning elements

- A lit material: base colour and roughness.
- Surface normals and the tangent frame.
- A height map stores values; neighbouring values give slopes.
- A normal map stores encoded directions.
- Change shading while retaining the mesh, silhouette and collision.

In the furnished room, choose STUDY. Move ROUGH and walk around the sphere and cube. The highlight changes, but the bodies keep their shapes. RIM adds another response, tied to the eye. The sofa, chair and vase show how the same material reads on different forms.

Our reconstruction asks a smaller question: can the circle from Patterns appear raised without raising any geometry? Keep the flat square as a witness. The same material will also cover the cube's front square and the point you hold.

## What we carry and what changes

Keep Patterns' `shaping.gd` and `point_body.gd`: the two receivers, cube, collider construction, shared material, local coordinates and hand action remain. The new `coat()` method gives the point's existing surface a material; it creates no replacement sphere. The `circle.gdshader` file is replaced by `relief.gdshader`. Add `relief_maps.gd` to make the data it reads. All four resulting files are printed below.

Hold the pattern fixed at three repeats, radius 0.30 and a gradual edge from 0.22 to 0.38. Its values now become height data. We also make a normal map from those values. The two maps are prepared once, not rebuilt each frame.

For this comparison, the hand controls change jobs. Trigger cycles **FLAT → HEIGHT MAP → NORMAL MAP**. Height controls the strength of the shading relief; sideways movement controls roughness. Neither gesture moves the surface's vertices. We add one fixed local lamp, printed in the host, to make the relief readable alongside the museum lighting.

Open `res://doc/book/studies/shaders-lineage/Materials.tscn` and Run Current Scene in the existing AdaResearch project. The supplied launcher adds the study to the furnished Materials hall. It points to the four sibling files in `res://doc/book/iterations/2026-10-10-materials-light-without-height/learner/printed/`. Edit those files, or change the launcher's `LESSON` preload to your saved `shaping.gd`. The museum supplies its player, camera, floor and bundled XR Tools. Every lesson-owned mesh, collider, label and lamp comes from the printed code.

## relief_maps.gd — prepare two readings

<!-- student-code:relief_maps.gd -->
```gdscript
extends RefCounted

const SIDE := 256
const GAIN := 0.03
const REPEATS := Vector2(3, 3)

static func build() -> Dictionary:
    var height := Image.create(SIDE, SIDE, false, Image.FORMAT_RF)
    for y in SIDE:
        for x in SIDE:
            var uv := Vector2(x + 0.5, y + 0.5) / SIDE
            var address := uv * REPEATS
            var tile := address - address.floor()
            var distance := tile.distance_to(Vector2(0.5, 0.5))
            var value := 1.0 - smoothstep(0.22, 0.38, distance)
            height.set_pixel(x, y, Color(value, 0, 0))

    var normal := Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
    var step := 1.0 / SIDE
    for y in SIDE:
        for x in SIDE:
            var left := height.get_pixel(posmod(x - 1, SIDE), y).r
            var right := height.get_pixel((x + 1) % SIDE, y).r
            var above := height.get_pixel(x, posmod(y - 1, SIDE)).r
            var below := height.get_pixel(x, (y + 1) % SIDE).r
            var du := (right - left) / (2.0 * step)
            var dv := (below - above) / (2.0 * step)
            var direction := Vector3(-du * GAIN, dv * GAIN, 1).normalized()
            var encoded := direction * 0.5 + Vector3.ONE * 0.5
            normal.set_pixel(x, y, Color(encoded.x, encoded.y, encoded.z))
    return {
        "height": ImageTexture.create_from_image(height),
        "normal": ImageTexture.create_from_image(normal)
    }
```

The first loop samples our repeated circle into a 256 × 256 image. It is the same multiply–fold–distance operation from Patterns. Red stores one floating-point value per sample; the other channels are unused. No metres have moved. `GAIN` chooses how strongly a slope in these normalized UV coordinates tilts the shading normal.

The second loop looks one texel left, right, above and below. Subtract opposite heights and divide by their two-texel separation: an estimate of the slope along each axis. `posmod` wraps a negative neighbour to the last column or row. The opposite edge supplies the other neighbour, matching the repeated texture.

A normal is a direction perpendicular to the surface. For a level patch its local direction is `(0, 0, 1)`. Where height rises toward the right, the normal leans left. Image rows increase downward, so this map uses `(-du, +dv, 1)` before normalization: the positive green axis points up the texture, as in Godot's OpenGL-style normal convention. The mesh supplies the tangent frame that turns those local directions into directions on the body. Our QuadMesh and SphereMesh supply UVs and tangents; arbitrary imported meshes need those too.

The RGB map encodes a direction from −1…1 into 0…1 by multiplying by 0.5 and adding 0.5. A flat direction becomes `(0.5, 0.5, 1)`, the familiar pale blue. Godot uses the red and green components and reconstructs the positive third component. RGB8 rounds these values; the encoded map is an approximation of the original slopes. The height image retains floating-point samples. Both textures are data, not display colours.

## relief.gdshader — choose what the surface reads

<!-- student-code:relief.gdshader -->
```glsl
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D height_map : repeat_enable, filter_linear;
uniform sampler2D normal_map : hint_normal, repeat_enable, filter_linear;
uniform vec2 texel = vec2(0.00390625);
uniform float height_gain = 0.03;
uniform float strength = 0.6;
uniform float roughness = 0.35;
uniform int mode = 0;
uniform vec4 colour : source_color = vec4(0.42, 0.18, 0.10, 1.0);

void fragment() {
    vec3 encoded = vec3(0.5, 0.5, 1.0);
    if (mode == 1) {
        float left = texture(height_map, UV - vec2(texel.x, 0.0)).r;
        float right = texture(height_map, UV + vec2(texel.x, 0.0)).r;
        float above = texture(height_map, UV - vec2(0.0, texel.y)).r;
        float below = texture(height_map, UV + vec2(0.0, texel.y)).r;
        float du = (right - left) / (2.0 * texel.x);
        float dv = (below - above) / (2.0 * texel.y);
        vec3 direction = normalize(vec3(-du * height_gain, dv * height_gain, 1.0));
        encoded = direction * 0.5 + 0.5;
    } else if (mode == 2) {
        encoded = texture(normal_map, UV).rgb;
    }
    NORMAL_MAP = encoded;
    NORMAL_MAP_DEPTH = strength;
    ALBEDO = colour.rgb;
    ROUGHNESS = roughness;
}
```

FLAT supplies the unperturbed tangent-space direction. HEIGHT MAP reads four heights and calculates the direction at each fragment. This is bump mapping from a height field. NORMAL MAP instead reads the direction prepared by the second loop. It saves those slope calculations at runtime, but that alone is not a measured performance result.

`texture` samples an image at UV coordinates. `texel` is the spacing of adjacent samples. Linear filtering blends nearby samples; repeat wrapping joins opposite image edges. The normal sampler has `hint_normal`, not `source_color`: its RGB numbers encode directions. `NORMAL_MAP` accepts that encoded tangent-space direction; `NORMAL_MAP_DEPTH` controls its influence. At zero strength both methods return to the mesh normal. At intermediate strengths this is a shading control, not a height in metres.

There is no `unshaded` flag now: lamps can affect the result. ALBEDO keeps one base colour, so the changing light response is visible. ROUGHNESS changes the spread of the specular highlight; it does not change friction or create microscopic geometry. No `vertex()` stage or collision update is present.

## shaping.gd — continue the same study

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Relief = preload("relief.gdshader")
const Maps = preload("relief_maps.gd")
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var strength := 0.6
var roughness := 0.35
var mode := 0
var maps: Dictionary
var receivers: Array[MeshInstance3D] = []

func _ready() -> void:
    material.shader = Relief
    maps = Maps.build()
    material.set_shader_parameter("height_map", maps.height)
    material.set_shader_parameter("normal_map", maps.normal)
    material.set_shader_parameter("texel", Vector2.ONE / Maps.SIDE)
    material.set_shader_parameter("height_gain", Maps.GAIN)
    make_box(Vector3(0, 1.6, -0.08), Vector3(2.2, 2.2, 0.1))
    make_receiver(Vector2(2, 2), Vector3(0, 1.6, 0))
    make_box(Vector3(0, 0.8, 1.0), Vector3(2.2, 0.1, 0.8))
    make_box(Vector3(-0.65, 1.15, 1.0), Vector3.ONE * 0.6)
    make_receiver(Vector2(0.54, 0.54), Vector3(-0.65, 1.15, 1.306))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(next_mode)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
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

func next_mode(_point) -> void:
    mode = (mode + 1) % 3
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    strength = clampf(0.6 + (local_point.y - 1.2) * 2.0, 0.0, 1.0)
    roughness = clampf(0.35 + (local_point.x - 0.65) * 0.5, 0.05, 0.95)
    material.set_shader_parameter("strength", strength)
    material.set_shader_parameter("roughness", roughness)
    material.set_shader_parameter("mode", mode)
    readout.text = "%s | Raise: relief %.2f | Sideways: roughness %.2f\nTrigger: next reading" % [
        ["FLAT", "HEIGHT MAP", "NORMAL MAP"][mode], strength, roughness
    ]
```

`maps.height` and `maps.normal` are the two textures created by the helper. The host connects them to the shader uniforms. It also passes their texel spacing and slope gain. `coat(material)` puts that same material on the held point, while the two square receivers retain their earlier connection.

The point starts at local `(0.65, 1.2, 1.2)`: strength 0.6, roughness 0.35. Raising it 0.2 metres reaches full strength; lowering it 0.3 metres reaches zero. Horizontal movement changes roughness within 0.05–0.95. The label declares the current reading. Mode cycling uses the remainder after division by three, returning to FLAT after NORMAL MAP.

## point_body.gd — expose the existing surface

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var surface := MeshInstance3D.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)

func coat(material: Material) -> void:
    surface.material_override = material
```

The mesh reference now lives on the class so `coat()` can reach it. Its radius, collision, pickup and frozen release behaviour are the ones already earned. The point's surface can answer to light while the same body answers to your hand.

## Predict, change, explain

Start at FLAT. Pick up the point and press the trigger for HEIGHT MAP. Watch the circle edges catch the fixed lamp. Change to NORMAL MAP without moving your hand. The relief should remain close, with small differences from interpolation and RGB8 rounding. Return to FLAT. The square's outer edge and the sphere's outline have not grown bumps.

Lower the point to local Y = 0.9. Both relief modes now return to the flat shading. Raise it to Y = 1.4. Keep that height while moving sideways: roughness changes, not the slope data. Look at a grazing angle; the apparent raised circles still stop at an unchanged edge. You cannot catch a hand on one.

For a guided variation, change `REPEATS` in `relief_maps.gd` from `(3, 3)` to `(4, 2)` and rerun. Both maps are rebuilt from that one edit. Predict the count, aspect and slope changes before comparing the two modes. Four repeats compress the horizontal change into less UV space, so its slope also becomes steeper at the same gain. This exact variation is tested. Then choose another count or gain yourself and explain what remains fixed.

The maps use normalized UV units. The same pattern therefore has different physical sizes on the large square, small square and sphere; it is not a calibrated common bump height in metres. On the sphere, UVs compress near the poles. Use the flat receiver to judge the method before interpreting the curved one.

## Back among the furniture

The installed rim study asks about surface direction and viewing direction. Its emission follows the eye; our normal maps alter how a lit surface is read. Return to STUDY and walk between the sphere and cube. Plastic, velvet and oil are named surface recipes here; the names do not establish fibres, liquid or a changed collision body.

Carry the distinction into Water: a surface may look raised because its shading normals changed, or its vertices may actually move. The next lesson makes that second operation visible and keeps its physical support separate.

References: Godot's [spatial shader interface](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) defines NORMAL_MAP and NORMAL_MAP_DEPTH; its [normal-map documentation](https://docs.godotengine.org/en/4.6/tutorials/3d/standard_material_3d.html#normal-map) describes the OpenGL convention and tangent-space use. The example above constructs its own data from the preceding circle rule.


---

# Water — a surface that moves

## Learning elements

- A normalized sum of noise at different scales.
- Vertex position, surface normal and fragment colour as separate operations.
- Subdivision: how many positions can the shader move?
- A held phase and a repeatable change.
- Visible displacement, rendering bounds and fixed collision.

Cross the glass bridge in the bathhouse. At the entrance console, check the phase readout. If it says Moving, press TIME once to hold it. Then choose COLOUR, NORMAL, and HEIGHT. The field stays the same; what it does to the surface changes. Look across the water at a low angle. Only HEIGHT changes the outline. The bridge keeps supporting you in all three readings.

We will make a small version on the dry side of the room. Keep the point from Materials, with its pickup, release and coat method. Keep the box-and-collider construction for a rigid cube, the tray and a narrow glass support. Replace the two vertical squares with one horizontal PlaneMesh. The old circle textures are put aside; the new shader calculates a layered field wherever it needs a value. The sphere controls the new surface; the cube remains rigid beside it.

The large pool also has six pickable balls and a bathing ring. Their buoyancy is a separate museum example, using forces and approximate depth samples. Try releasing one while TIME holds the water: the body still falls and settles. The shader does not provide that behaviour. This lesson builds the small surface study; it does not reconstruct the pool toys.

## One field, three readings

The noise operation returns from Noise: choose values at lattice corners, then smoothly blend between them. The new loop combines that operation at several scales. Frequency doubles and weight halves at each step. Divide by the weights used so that the signed result stays between −1 and 1. Three scales give detail within larger changes; they do not simulate fluid.

The point's height now controls relief in metres, from 0 to 0.25. Sideways movement controls phase around a circular sampling path. Trigger cycles **COLOUR → NORMAL → HEIGHT**. Release keeps the point, and therefore its chosen field, still. The small example has no automatic clock: you move its phase yourself. The room's TIME button is the larger exhibit's additional control.

In the prepared AdaResearch project, open `res://doc/book/studies/shaders-lineage/Water.tscn` and Run Current Scene. The supplied launcher mounts the study beside the existing basin. It uses the three files in `res://doc/book/iterations/2026-10-10-water-a-surface-that-moves/learner/printed/`; change its `LESSON` preload to use your own saved `shaping.gd`. The museum supplies its player, camera, floor and bundled XR Tools. All three lesson files follow. No production artifact fills in missing construction.

## water.gdshader — values, normals, vertices

<!-- student-code:water.gdshader -->
```glsl
shader_type spatial;
render_mode cull_disabled;

// A bounded, normalized sum of value-noise octaves. No fluid state or collision.
uniform int octaves : hint_range(1, 4) = 3;
uniform float relief : hint_range(0.0, 0.25) = 0.15;
uniform float phase = 0.0;
uniform int mode : hint_range(0, 2) = 0; // colour, normal, vertex height
varying vec2 position_xz;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), u.x),
        mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), u.x), u.y);
}
float field(vec2 p) {
    vec2 drift = 0.9 * vec2(cos(phase), sin(phase));
    vec2 q = p + drift;
    float sum = 0.0, weight = 0.5, weights = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= octaves) { break; }
        sum += weight * (2.0 * noise2(q) - 1.0);
        weights += weight;
        weight *= 0.5;
        q *= 2.0;
    }
    return sum / weights;
}
float height_at(vec2 p) { return relief * field(p); }
void vertex() {
    position_xz = VERTEX.xz;
    float h = height_at(position_xz);
    if (mode == 2) { VERTEX.y += h; }
    if (mode >= 1) {
        float e = 0.045;
        float dx = (height_at(position_xz + vec2(e, 0)) - height_at(position_xz - vec2(e, 0))) / (2.0 * e);
        float dz = (height_at(position_xz + vec2(0, e)) - height_at(position_xz - vec2(0, e))) / (2.0 * e);
        NORMAL = normalize(vec3(-dx, 1.0, -dz));
    }
}
void fragment() {
    float n = 0.5 + 0.5 * field(position_xz);
    vec3 pigment = mix(vec3(0.012, 0.07, 0.09), vec3(0.13, 0.52, 0.47), n);
    ALBEDO = pigment;
    ROUGHNESS = 0.15;
}
```

Read the shader in three parts. `hash21` supplies a deterministic corner value. `noise2` takes the four neighbouring values and blends them across a cell; the cubic weight eases the blend at its edges. This sine-based hash is a convenient visual source, not a guarantee of identical random values across GPU implementations.

`field` adds signed noise with weights 0.5, 0.25, 0.125 and, if requested, 0.0625. `weights` records how much weight was used. Because each noise value lies between 0 and 1, the signed terms lie between −1 and 1; their positive weighted average stays in that interval. `relief` turns this bounded value into a local height. Keep OCTAVES between 1 and 4 so the denominator is positive. This finite layered-noise construction is commonly called FBM in graphics; it is not a simulation of Brownian particles.

Phase shifts the place we sample along a circle. The pair `(cos(phase), sin(phase))` returns after one turn. The field therefore returns too, apart from numerical rounding. No previous field is stored. Repeating a chosen input and remembering a previous surface are different operations.

`vertex()` receives each mesh vertex in its local frame. The plane lies in XZ, so HEIGHT adds the field to Y. Before doing that, `position_xz` keeps its sampling address. This `varying` is interpolated across each triangle and delivered to `fragment()`, which reads the same field for colour. Changing the palette would not change the geometry.

NORMAL and HEIGHT also estimate two slopes, now in local X and Z metres. Opposite samples are 0.09 m apart; division by that separation gives change per metre. The upward normal is `(-dx, 1, -dz)`, normalized. This returns to Materials' slope calculation, but here it runs at vertices. Godot interpolates the resulting directions between them. A coarse mesh makes both this normal approximation and the displaced shape coarse. Materials' texture normal calculation ran per fragment and could show detail between the vertices.

COLOUR leaves the plane and its supplied upward normals untouched. NORMAL changes the directions used for lighting. HEIGHT does that and moves vertices. Neither operation adds a physics shape. The shader is opaque, with ordinary lighting and fixed roughness; refraction, reflection simulation and buoyancy are outside this example.

## shaping.gd — keep the point, change its receiver

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Water = preload("water.gdshader")
const SUBDIVISIONS := 48
const OCTAVES := 3
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var relief := 0.15
var phase := 0.0
var mode := 0
var surface := MeshInstance3D.new()
var bridge: StaticBody3D
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Water
    material.set_shader_parameter("octaves", OCTAVES)
    var plane := PlaneMesh.new()
    plane.size = Vector2(3, 3)
    plane.subdivide_width = SUBDIVISIONS
    plane.subdivide_depth = SUBDIVISIONS
    surface.mesh = plane
    surface.material_override = material
    surface.position.y = 0.70
    surface.custom_aabb = AABB(Vector3(-1.5, -0.25, -1.5), Vector3(3, 0.5, 3))
    add_child(surface)
    make_box(Vector3(0, 0.38, 0), Vector3(3.2, 0.08, 3.2))
    for side in [-1.0, 1.0]:
        make_box(Vector3(side * 1.55, 0.72, 0), Vector3(0.10, 0.60, 3.2))
        make_box(Vector3(0, 0.72, side * 1.55), Vector3(3, 0.60, 0.10))
    var glass := StandardMaterial3D.new()
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.albedo_color = Color(0.65, 0.90, 0.90, 0.18)
    glass.roughness = 0.12
    bridge = make_box(Vector3(0, 1.04, 0), Vector3(0.50, 0.06, 3.2), glass)
    cube = make_box(Vector3(-2, 0.72, 0), Vector3.ONE * 0.60)
    make_box(Vector3(-2, 0.21, 0), Vector3(0.8, 0.42, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.04, 0.04, 0.04)
    control.coat(black)
    control.action_pressed.connect(next_mode)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 2.15, -1.5)
    readout.font_size = 36
    readout.pixel_size = 0.002
    add_child(readout)
    update_rule()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func _process(_delta: float) -> void:
    update_rule()

func next_mode(_point) -> void:
    mode = (mode + 1) % 3
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    relief = clampf(0.15 + (local_point.y - 1.2) * 0.5, 0.0, 0.25)
    phase = fposmod((local_point.x - 0.65) * TAU, TAU)
    material.set_shader_parameter("relief", relief)
    material.set_shader_parameter("phase", phase)
    material.set_shader_parameter("mode", mode)
    readout.text = "%s | Raise: %.2f m | Sideways: phase %.2f\nTrigger: next reading" % [
        ["COLOUR", "NORMAL", "HEIGHT"][mode], relief, phase
    ]
```

The receiver is now a 3 × 3 m PlaneMesh. With 48 subdivisions on each axis, it has 50 × 50 vertices: the two endpoints plus the added positions on each row. The shader can move those positions; the triangles between them remain flat. More vertices can describe finer geometry, at more rendering cost. They do not make a fluid solver.

The bounding box declares where those vertices may go: ±0.25 m around the undeformed plane. The renderer needs that bound when deciding whether the object is visible. It is not a collider. The actual mesh resource still contains its original flat positions; the vertex shader changes the rendered copy.

The plane's mean height is 0.70 m, so its visible height stays within 0.45–0.95 m. The glass underside is 1.01 m. Even the maximum permitted crest stays 6 cm below it. The tray floor's top is 0.42 m. These bounds also hold for triangles interpolated between the vertices. The small glass has a collider made by `make_box`; the water has none.

`make_box` is the earned construction with two additions: an optional material and a returned body reference. When no material is supplied, it keeps its grey surface. The glass changes that surface, while keeping its box collider. The point's existing `coat()` gives it a dark material; its spherical mesh and collision stay unchanged. The cube and glass are not assigned the water shader.

At the starting point position, relief is 0.15 m and phase is zero. Raise it 0.2 m to reach the 0.25 m limit; lower it 0.3 m to reach zero. One metre sideways makes a full phase turn. The host updates uniforms; it does not rebuild the mesh each frame.

## point_body.gd — unchanged from Materials

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var surface := MeshInstance3D.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)

func coat(material: Material) -> void:
    surface.material_override = material
```

## Predict, change, explain

Start at COLOUR. Hold the point still and cycle to NORMAL. The light response changes while the edge remains flat. Cycle to HEIGHT and lower your eye: the edge now rises and falls. The glass and cube stay fixed. Lower the point to local Y = 0.9; both normal change and displacement disappear, while the colour field remains.

Return to Y = 1.4. Move sideways by half a metre, then by a full metre from the start. Predict which position returns the field. Stop and release: waiting alone should change nothing. Walk onto the large bridge and compare the same distinction at the scale of your body.

For the tested variation, set `SUBDIVISIONS` to `0` and rerun. Only four corner vertices remain. The colour field can still show fine marks, but HEIGHT can only move those four corners and interpolate two triangles. NORMAL also becomes coarse in this vertex-based implementation. Restore 48 and compare at the same phase. This is why a detailed colour image does not prove detailed geometry.

Then compare OCTAVES = 1 and 4 while retaining the mesh resolution. The relief bound stays the same because the sum is normalized; the distribution within it changes. More scales are not automatically better water. Choose a scale count and a mesh density that preserve the feature you want the viewer to see, and explain the choice. The automated checks exercise the one/four-scale parameter change; your aesthetic judgment remains yours.

## Return to the bathhouse

The room's 11 × 11 m water study uses the same layered-field operation at a broader spatial scale, with additional pigment and view-dependent emission. Its own TIME control advances or holds phase. Its relief is bounded by 0.25 m around a mean of −0.40 m, beneath a separate 1.8 m wide bridge. It has no water collider or fluid history. The four graphs beyond it offer raw FBM sums, ridges, turbulence and domain warp as further encounters; their controls do not drive the pool.

Next, Pink Extravaganza returns to the rigid cube and point. Its required study combines repeated colour, a view-dependent rim and emission while keeping geometry fixed. The displaced water remains a supporting encounter in the room. Keep asking which body receives a rule and which construction supports the player.

References: [The Book of Shaders, chapter 13](https://thebookofshaders.com/13/) offers the layered-noise lineage; Godot's [PlaneMesh](https://docs.godotengine.org/en/4.6/classes/class_planemesh.html) and [spatial shader stages](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html). The field is a reduced version of this museum's `layered_water.gdshader`, printed above in full.


---

# Pink Extravaganza — three amounts

## Learning elements

- Compose a material from operations you can separate.
- Use the surface normal and viewing direction to find a rim.
- Distinguish reflected light, emission and a lamp.
- Control three amounts with the point's local coordinates.
- Compare one recipe on different bodies and in different surroundings.

Find the composition bay: a sphere, cube and sofa face a bench marked DOTS, RIM and GLOW. Move one slider at a time. Then press SETTING. The chairs in rings and the water ceiling disappear; the main bodies, their material and the stage lamps stay. The room has changed the encounter without changing the recipe.

Continue from Water's complete program. Keep PointBody unchanged, keep its coat method, keep the cube and its box collider, and keep the small lamp. Set the tray, bridge and displaced plane aside. Give the point and cube one new material. The circle and repetition return from Patterns. Materials taught us to inspect normals; here their relation to the viewing direction gives a rim. Water showed emission in the large pool; now we control that contribution explicitly. This example holds the geometry still so those amounts can be compared.

Open `res://doc/book/studies/shaders-lineage/Pink.tscn` in the prepared AdaResearch project and Run Current Scene. The supplied launcher mounts your small study beside the existing composition stage. Its LESSON preload names `res://doc/book/iterations/2026-10-10-pink-three-amounts/learner/printed/shaping.gd`; point it at your saved copy to work on your own files. The museum supplies the room, player, camera and XR Tools. All learner construction follows; the production stage does not fill missing code.

## recipe.gdshader — give each part an amount

<!-- student-code:recipe.gdshader -->
```glsl
shader_type spatial;

uniform vec4 ground : source_color = vec4(0.08, 0.02, 0.045, 1.0);
uniform vec4 ink : source_color = vec4(1.0, 0.05, 0.42, 1.0);
uniform vec4 edge_colour : source_color = vec4(0.18, 0.84, 0.80, 1.0);
uniform vec2 repeats = vec2(3.0);
uniform vec3 amounts = vec3(1.0, 0.6, 0.3);

void fragment() {
    vec2 cell = fract(UV * repeats);
    float mask = 1.0 - step(0.30, distance(cell, vec2(0.5)));
    vec3 colour = mix(ground.rgb, ink.rgb, mask * amounts.x);
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float edge = pow(1.0 - facing, 3.0);
    ALBEDO = colour;
    ROUGHNESS = 0.25;
    EMISSION = colour * (0.8 * amounts.z)
        + edge_colour.rgb * edge * (1.5 * amounts.y);
}
```

The first two lines of `fragment()` are the circle from Patterns. Scale UV, keep its fractional part, then test the distance from each cell's centre. `amounts.x` controls how much pink ink replaces the ground inside the circle. At zero the pattern disappears; at one the circle has the ink colour. Its radius and repetition stay fixed.

For the rim, compare two directions. NORMAL points outward from the surface; VIEW points toward the eye. Their normalized dot product is near one on a face looking toward you and near zero at a grazing angle. Subtract from one and cube the result to concentrate the contribution near the edge. This uses the existing normal; it does not write a bump map or move a vertex. A sphere gives a curved band. A cube can give a whole bright face when that face turns nearly away from you.

The recipe puts the mixed pigment in ALBEDO. EMISSION adds two contributions: that pigment multiplied by GLOW, and a mint rim multiplied by RIM. Both can be visible without an incident lamp. They do not create an OmniLight3D or guarantee illumination of a neighbour. Bloom and indirect lighting depend on renderer settings; neither is required for this example. The shader uses no clock and no previous image.

Notice the order: DOTS mixes the pigment first; GLOW brightens that result. The controls are separate, but their visible contributions can combine. Raising GLOW therefore brightens the dots too. We keep ground, ink and roughness fixed during the base/composed comparison.

The shader uses mesh UVs, as the first square examples did. The sphere's UVs narrow near the poles; the cube's UV layout distributes its faces within its texture coordinates. A repeat count belongs to that layout, not to metres or a guarantee of three circles on every face. The larger stage uses a separate projection adapter for the sofa, which has no UV data. That adapter is outside this small reconstruction.

## shaping.gd — the point becomes three controls

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Recipe = preload("recipe.gdshader")
const REPEATS := Vector2(3, 3)
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var amounts := Vector3(1.0, 0.6, 0.3)
var mode := 1
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Recipe
    material.set_shader_parameter("repeats", REPEATS)
    cube = make_box(Vector3(-0.6, 0.9, 0), Vector3.ONE * 0.60, material)
    make_box(Vector3(-0.6, 0.30, 0), Vector3(0.8, 0.60, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(next_mode)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 1.9, -0.5)
    readout.font_size = 28
    readout.pixel_size = 0.002
    add_child(readout)
    update_rule()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func _process(_delta: float) -> void:
    update_rule()

func next_mode(_point) -> void:
    mode = (mode + 1) % 2
    update_rule()

func update_rule() -> void:
    var local_point := to_local(control.global_position)
    amounts = Vector3(
        clampf(1.0 + local_point.x - 0.65, 0.0, 1.0),
        clampf(0.6 + local_point.y - 1.2, 0.0, 1.0),
        clampf(0.3 + local_point.z - 1.2, 0.0, 1.0)
    )
    material.set_shader_parameter("amounts", amounts if mode == 1 else Vector3.ZERO)
    readout.text = "%s | X dots %.2f / Y rim %.2f / Z glow %.2f\nTrigger: compare base and composition" % [
        ["BASE", "COMPOSED"][mode], amounts.x, amounts.y, amounts.z
    ]
```

`make_box()` and PointBody are the earned construction. The cube is still 0.6 m across, now on a 0.6 m plinth. The point keeps its 0.14 m radius, pickup and frozen release. Both receive the same ShaderMaterial; the plinth keeps its grey material. Changing a uniform changes both receivers without rebuilding either mesh or collider.

Read the point in the study's local frame. X controls DOTS, Y controls RIM and Z controls GLOW. One metre along an axis changes its amount by one; every amount is clamped to [0, 1]. At the starting position the amounts are (1, 0.6, 0.3). The shader scales the rim by 1.5 and pigment emission by 0.8. These are chosen limits, not universal material units.

To isolate a channel, move along one local axis and watch the three numbers. From the starting pose, move one metre left to remove DOTS; move 0.6 m down to remove RIM; move 0.3 m away from you to remove GLOW. Return the point to (0.65, 1.2, 1.2) to restore the opening recipe. The readout reports the chosen amounts, including when you temporarily inspect BASE.

Trigger alternates BASE and COMPOSED. BASE sends three zeros to the shader; it keeps the chosen amounts in the host. Trigger again to see the composition at the point's current position. Release freezes that position. Waiting alone then changes nothing, though walking around the body changes the rim you see.

## point_body.gd — unchanged from Water

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var surface := MeshInstance3D.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)

func coat(material: Material) -> void:
    surface.material_override = material
```

## Predict, change, explain

Start with the opening recipe. Trigger to BASE and back without moving the point. The pattern and emission return; the geometry does not change. Then remove only RIM. Walk around the cube and point: predict which bright part should disappear and which pigment should remain.

Set DOTS and RIM to zero, then raise GLOW by moving the point toward you. Does the surface becoming brighter prove it lights the grey plinth? Turn the small lamp off by setting its `light_energy` to `0.0` and rerun. The museum's other lights still exist, so this is not a darkness test. The automated check uses an explicitly dark diagnostic viewport to separate emission from incident light; it also checks an adjacent grey receiver. Do not infer a light source from a bright pixel alone.

For the tested variation, change `REPEATS := Vector2(3, 3)` to `REPEATS := Vector2(4, 2)` and rerun. Predict the change on a flat UV square before looking at the sphere and cube. The mask's layout changes; the rim still depends on viewing angle, and the bodies still have the same boundaries. The complete variant is included with the review files.

Finally make one composition you want to keep. Record the point's local position and the three amounts, then reconstruct that choice after a restart. This program does not save a file for you. Explain which contribution you would remove first, and why. Automated tests check the operations and the supplied variation; they cannot choose the composition for you.

## Return to the room

Compare your two bodies with the stage's sphere, cube and sofa. Its PALE preset changes ground colour and roughness as well as removing dots, rim and glow, so it is a broader change than your BASE comparison. SETTING changes the surround while retaining the stage recipe and lamps. Use the individual sliders when you want to isolate one operation.

The old five-material collection and the unfolding body are further encounters, not extra shader code you must rebuild here. The optional plural-body edit below keeps its own supplied construction. In the next hall, retaining a recipe will give way to retaining a field: the next image will depend on what was left in the previous one.

Shader output and direction conventions: [Godot spatial shaders](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html). Pattern repetition reference: [The Book of Shaders — Patterns](https://thebookofshaders.com/09/).


[Optional returns from this hall](appendices.html#Shader_12_PinkExtravaganza). Continue to the next main chapter when ready.


---

# A field kept

## Learning elements

- Previous state and next state
- Reading neighbouring cells in a texture
- Reaction, diffusion, feed and loss
- A starting difference and a repeated update
- Data, display and receiver as separate things

<!-- @shader_state_chamber -->

Touch the large wall, then let go. The mark stays. STEP changes it once. RUN lets the field continue; HOLD stops after the current batch. INK changes how you see the record. It does not replace the record.

In Pink, the point chose three amounts for a material. Here the same point plants a difference into a field. Keep its class, the cube, plinth and box helper. Replace the composition shader with a display of saved data, and add the update shader and its runner. Your small study stands beside the installed wall; it has its own field and controls.

## What must survive a frame?

Every address stores two numbers, U and V, between zero and one. Start with U = 1, V = 0, except three small discs containing U = 0.5, V = 1. The update reads the **old** U and V, and their neighbours, then writes a **new** pair. Every cell in that step reads the same completed old field. Writing into the field while reading it would make update order part of the rule.

The Gray–Scott rule combines neighbour exchange with three local terms. `U * V * V` consumes U and produces V. Feed replenishes U toward one; feed plus loss removes V. This is a discretized model, not a measurement of chemicals in the museum.[^t6-model]

Keep the distinction from Water: TIME can make a surface move without retaining its previous surface. Here a completed output becomes the next input. The data texture is separate from the colours you see.

## Two passes through the same study

First run the complete program and compare CLEAR, a planted mark, STEP, RUN/HOLD and INK. Explain which actions change the stored values. Trace `previous_state` through the update and the completed texture back into the next input. That is the central new capability.

Then open the numerical rule: predict one cell, change FEED and compare equal step counts. The chemistry coefficients are a supplied model to investigate. The render-target scheduling and byte packing below keep it executable; understanding every transport detail is not an additional entry requirement. Both passes use the same program and field.

## Read the update rule

In `field_step.gdshader`, `read_state` retrieves one pair. `lap` compares it with eight neighbours: centre −1, side neighbours 0.2 each, diagonals 0.05 each. The weights sum to zero, so a uniform field has no exchange. Opposite edges wrap; this is a periodic square field even when displayed on a sphere.

The coefficients are Du = 1, Dv = 0.5, F = 0.055, K = 0.062, with one numerical step of dt = 1. One step is not one second. Clamping bounds concentrations; it does not make arbitrary rates or timesteps accurate.

`integrate` distinguishes advancing the model from planting a mark. The brush overwrites a small disc after the update, or on its own while held. Planting is an intervention, not a chemical reaction.

The short packing functions are supplied transport code: two 12-bit numbers share an RGB8 pixel. They introduce quantization of 1/4095. There is no `source_color` hint on this data sampler. Colour conversion would corrupt the numbers. Focus on the reads, update and final write; the full support is visible here.

<!-- student-code:field_step.gdshader -->
```glsl
shader_type canvas_item;
render_mode unshaded, blend_disabled;
// Data, not colour: two 12-bit concentrations packed in RGB8. No source_color hint.
// The spare low nibbles share blue; alpha stays opaque on every renderer.
uniform sampler2D previous_state : filter_nearest, repeat_enable;
uniform float feed = 0.055;
uniform float kill = 0.062;
uniform bool integrate = true;
uniform vec2 brush = vec2(-10.0);
uniform float brush_radius = 0.04;
vec2 read_state(vec2 uv) {
    vec3 bytes = floor(texture(previous_state, uv).rgb * 255.0 + 0.5);
    return (bytes.rg * 16.0 + vec2(floor(bytes.b / 16.0), mod(bytes.b, 16.0))) / 4095.0;
}
vec4 pack_state(vec2 value) {
    vec2 bits = floor(clamp(value, vec2(0.0), vec2(1.0)) * 4095.0 + 0.5);
    return vec4(floor(bits / 16.0), mod(bits.x, 16.0) * 16.0 + mod(bits.y, 16.0), 255.0) / 255.0;
}
void fragment() {
    vec2 c = read_state(UV);
    if (integrate) {
        vec2 p = 1.0 / vec2(textureSize(previous_state, 0));
        vec2 lap = -c;
        lap += 0.2 * (read_state(UV + vec2(p.x, 0.0)) + read_state(UV - vec2(p.x, 0.0))
            + read_state(UV + vec2(0.0, p.y)) + read_state(UV - vec2(0.0, p.y)));
        lap += 0.05 * (read_state(UV + p) + read_state(UV - p)
            + read_state(UV + vec2(p.x, -p.y)) + read_state(UV + vec2(-p.x, p.y)));
        float reaction = c.x * c.y * c.y;
        // Gray–Scott: dt=1, Du=1, Dv=.5 with this weighted nine-cell stencil.
        c += vec2(lap.x - reaction + feed * (1.0 - c.x),
            0.5 * lap.y + reaction - (feed + kill) * c.y);
    }
    if (distance(UV, brush) < brush_radius) c = vec2(0.5, 1.0);
    COLOR = pack_state(c);
}
```

At the centre of a seeded disc, all neighbours initially agree. The first update gives U ≈ **0.0275**, V = **1** after clamping. Away from the discs, U = 1, V = 0 stays unchanged. Predict both before pressing STEP.

## Keep the output before using it again

`field.gd` is the supplied GPU runner, printed in full. `_schedule` binds `state_texture` as the first input, then chains up to eight separate render targets. `_completed` publishes only the finished last texture, and switches groups. Two groups prevent the next batch from overwriting the texture it still reads. Old dependencies are disconnected before a group is reused.

Each SubViewport renders once, then holds its pixels.[^t6-viewport] RUN requests up to eight steps per rendered frame toward 240 model steps per second; slower rendering slows the model. HOLD finishes the current batch. RESET cancels queued work and restores the three discs after any in-flight batch. CLEAR restores the uniform background. Neither changes F or K. A mark queue holds at most 32 requests. There is no CPU chemistry or GPU readback in this live path.

<!-- student-code:field.gd -->
```gdscript
extends Node
## Each pass reads an immutable previous texture. The next group is scheduled
## only after frame_post_draw. No readback or CPU chemistry in the live path.
signal changed
const SIZE := 96
const PASSES := 8
const STEP = preload("./field_step.gdshader")
var views: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []
var state_texture: Texture2D
var initial_texture: ImageTexture
var running := false
var busy := false
var iterations := 0
var feed := .055
var kill := .062
var pending_steps := 0
var pending_reset := -1
var brush_queue: Array[Vector2] = []
var _group := 0
var _last := 0
var _count := 0
var _integrating := false
var _budget := 0.0

func _ready()->void:
    for i in range(PASSES*2):
        var view:=SubViewport.new();view.name="State_%02d"%i
        view.size=Vector2i(SIZE,SIZE);view.disable_3d=true;view.use_hdr_2d=false
        view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
        var rect:=ColorRect.new();rect.size=Vector2(SIZE,SIZE)
        var mat:=ShaderMaterial.new();mat.shader=STEP;rect.material=mat;view.add_child(rect)
        views.append(view);materials.append(mat)
    RenderingServer.frame_post_draw.connect(_completed)
    _reset_now(true)

static func encode(a:float,b:float)->Color:
    var u:=roundi(clampf(a,0,1)*4095);var v:=roundi(clampf(b,0,1)*4095)
    return Color(float(u/16)/255.0,float(v/16)/255.0,float((u%16)*16+v%16)/255.0,1)

static func decode(c:Color)->Vector2:
    var packed:=roundi(c.b*255)
    return Vector2(roundi(c.r*255)*16+packed/16,roundi(c.g*255)*16+packed%16)/4095.0

func reset(seeded:bool=true)->void:
    running=false;pending_steps=0;brush_queue.clear();_budget=0
    if busy:pending_reset=int(seeded)
    else:_reset_now(seeded)

func _reset_now(seeded:bool)->void:
    var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGB8);image.fill(encode(1,0))
    if seeded:
        for at in [Vector2(.32,.35),Vector2(.52,.49),Vector2(.67,.66)]:
            for y in range(SIZE):
                for x in range(SIZE):
                    if Vector2((x+.5)/SIZE,(y+.5)/SIZE).distance_to(at)<.055:image.set_pixel(x,y,encode(.5,1))
    initial_texture=ImageTexture.create_from_image(image);state_texture=initial_texture
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    iterations=0;pending_reset=-1;changed.emit()

func mark(uv:Vector2)->void:
    if uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return
    if brush_queue.size()<32:brush_queue.append(uv)

func step(count:int=1)->void:
    running=false;pending_steps+=clampi(count,1,20000)

func _process(delta:float)->void:
    if busy:return
    if pending_reset>=0:_reset_now(pending_reset==1)
    var count:=0
    if pending_steps>0:count=mini(PASSES,pending_steps);pending_steps-=count
    elif running:
        _budget=minf(_budget+delta*240.0,PASSES)
        count=int(_budget);_budget-=count
    if count==0 and brush_queue.is_empty():return
    _schedule(maxi(1,count),count>0)

func _schedule(count:int,integrating:bool)->void:
    busy=true;_count=count;_integrating=integrating
    # Break old dependencies: disabled targets keep their completed pixels.
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    var source:Texture2D=state_texture
    for i in range(count):
        var slot:=_group*PASSES+i;var mat:=materials[slot]
        mat.set_shader_parameter("previous_state",source)
        mat.set_shader_parameter("feed",feed);mat.set_shader_parameter("kill",kill)
        mat.set_shader_parameter("integrate",integrating)
        mat.set_shader_parameter("brush",brush_queue.pop_front() if not brush_queue.is_empty() else Vector2(-10,-10))
        views[slot].render_target_update_mode=SubViewport.UPDATE_ONCE
        source=views[slot].get_texture();_last=slot

func _completed()->void:
    if not busy:return
    state_texture=views[_last].get_texture()
    if _integrating:iterations+=_count
    _group=1-_group;busy=false;changed.emit()

func _exit_tree()->void:
    if RenderingServer.frame_post_draw.is_connected(_completed):RenderingServer.frame_post_draw.disconnect(_completed)
```

## Colour is a reading of the field

`recipe.gdshader` reads V and maps it into ink. The transition from paper to ink spans V = 0.05 to 0.30, so fully dark ink does not mean V = 1. This displayed colour never feeds the update. The same texture coats the point, cube and square: three views of one flat record, not three simulations or diffusion across their physical surfaces.

<!-- student-code:recipe.gdshader -->
```glsl
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_texture : filter_nearest, repeat_enable;
uniform vec4 paper : source_color = vec4(0.88,0.85,0.76,1.0);
uniform vec4 ink : source_color = vec4(0.025,0.08,0.085,1.0);
void fragment() {
    vec3 bytes = floor(texture(state_texture, UV).rgb * 255.0 + 0.5);
    float b = (bytes.g * 16.0 + mod(bytes.b,16.0)) / 4095.0;
    // Display mapping only; never fed into the solver.
    vec3 colour = mix(paper.rgb, ink.rgb, smoothstep(0.05,0.30,b));
    ALBEDO = colour;
    ROUGHNESS = 0.55;
    EMISSION = colour * 0.14;
}
```

## Continue the point and cube in the museum

Keep the five files together. The prepared AdaResearch project supplies XRTools, player, camera, lighting and the push-button prefab at `res://commons/interactables/push_button.tscn`. That prefab creates the named `InteractableAreaButton` receiver used below. It supplies a physical press and pointer event; our code decides what the press does. No museum artifact constructs the learner's field or geometry.

Open `res://doc/book/studies/shaders-lineage/State.tscn` and Run Current Scene. The supplied launcher places this small study beside the existing State chamber; set its LESSON preload to your saved `shaping.gd`. Alternatively attach the script to a Node3D at floor level, unit scale, with a clear 3 × 3 metre area in the prepared museum.

Hold the point. Its local X from −1 to 1 selects left to right; Y from 0.5 to 2.5 selects bottom to top. Trigger plants a disc. Z does not select an address: this is an XY selector, not a contact detector. Outside that rectangle it plants nothing. Moving without triggering plants nothing. Release keeps the point and, while HELD, the field still. The installed large wall additionally accepts direct touch; that input adapter is outside this reconstruction.

The five nearby buttons operate your field: RUN/HOLD, STEP, RESET, CLEAR and INK. The large wall's own desk controls its separate field. The board here is a visual display; the inherited cube and plinth retain their colliders.

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Recipe = preload("recipe.gdshader")
const Field = preload("field.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const FEED := 0.055
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var field: Node
var alternate_ink := false
var buttons: Dictionary = {}
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Recipe
    cube = make_box(Vector3(-0.6, 0.9, 0), Vector3.ONE * 0.60, material)
    make_box(Vector3(-0.6, 0.30, 0), Vector3(0.8, 0.60, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(plant)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 2.72, -0.5)
    readout.font_size = 28
    readout.pixel_size = 0.002
    add_child(readout)
    var board := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(2, 2)
    board.mesh = quad
    board.position = Vector3(0, 1.5, -0.5)
    board.material_override = material
    add_child(board)
    make_box(Vector3(0, 0.93, 1.8), Vector3(2.4, 0.10, 0.5))
    for i in range(5):
        var key: String = ["RUN/HOLD", "STEP", "RESET", "CLEAR", "INK"][i]
        var button = PushButton.instantiate()
        button.position = Vector3(-0.96 + i * 0.48, 0.99, 1.8)
        add_child(button)
        buttons[key] = button
        # This declared prefab creates its named press receiver.
        button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): act(key))
        var label := Label3D.new()
        label.text = key
        label.font_size = 24
        label.pixel_size = 0.0015
        label.position = button.position + Vector3(0, 0.015, 0.19)
        label.rotation_degrees.x = -60
        add_child(label)
    field = Field.new()
    field.feed = FEED
    add_child(field)
    field.changed.connect(show_state)
    show_state()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func plant(_point) -> void:
    if not control.is_picked_up():
        return
    var p := to_local(control.global_position)
    field.mark(Vector2(p.x / 2.0 + 0.5, 1.0 - (p.y - 0.5) / 2.0))

func act(key: String) -> void:
    match key:
        "RUN/HOLD": field.running = not field.running
        "STEP": field.step()
        "RESET": field.reset(true)
        "CLEAR": field.reset(false)
        "INK":
            alternate_ink = not alternate_ink
            material.set_shader_parameter("ink", Color("822547") if alternate_ink else Color("143436"))
    show_state()

func show_state() -> void:
    material.set_shader_parameter("state_texture", field.state_texture)
    readout.text = "%s / %d steps / F %.3f\nHold point; trigger plants at its X/Y address" % [
        "RUNNING" if field.running else "HELD", field.iterations, field.feed
    ]
```

## Carried point_body.gd — unchanged

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var surface := MeshInstance3D.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)

func coat(material: Material) -> void:
    surface.material_override = material
```

## Build, predict, change

1. CLEAR, then STEP. Explain why a uniform U = 1, V = 0 field stays uniform.
2. Hold the point at local (−0.3, 1.8, 1.2); trigger, then release. The mark should appear left of centre and above it. Compare HELD, STEP and RUN. HOLD, then change INK: the shape and step count should stay fixed.
3. RESET and STEP. Read the first-step prediction above. Change only `const FEED := 0.055` to `const FEED := 0.065` in `shaping.gd`, rerun, reset and step. The same interior address now has U ≈ **0.0325**; V still clamps to one. Both local terms contain feed, even though this saturated V masks one difference on the first step. Compare later fields only at equal update counts.
4. Make two marks with a relation you can describe. Let them evolve, then hold a result. Explain which decisions came from your input, the rule and the display. The test can check those operations; it cannot decide whether your composition matters to you.

The record survives between steps while this study is loaded. It is not saved to disk or carried across halls. Carry the programming distinction onward: **read old, write next, then exchange their roles**. Cellular Automata will make another rule from it.

<!-- @ -->

## Other encounters

The older green square asks for previous input without receiving its own output. The frost panel and Memory Skin construct appearances without retaining your touch. Keep them as comparisons. The dark sphere also carries CPU state; it is not a second version of this field. None needs another implementation in this lesson.

[^t6-model]: [MIT's Gray–Scott model notes](https://groups.csail.mit.edu/mac/projects/amorphous/GrayScott/) describe the reaction, supply, removal and neighbour exchange. This lesson uses the room's specific discretization and coefficients.
[^t6-viewport]: [Godot's SubViewport documentation](https://docs.godotengine.org/en/stable/classes/class_subviewport.html) specifies UPDATE_ONCE and UPDATE_DISABLED. The runner explicitly uses these modes and waits for completed rendering.


# Optional returns

See appendices.md for the preserved garden, saved-record and plural-body encounters.
