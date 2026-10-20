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

Next, Pink Extravaganza combines operations you can now distinguish: colour, sampling coordinates, light response and visible displacement. Keep asking which body receives a rule and which construction supports the player.

References: [The Book of Shaders, chapter 13](https://thebookofshaders.com/13/) offers the layered-noise lineage; Godot's [PlaneMesh](https://docs.godotengine.org/en/4.6/classes/class_planemesh.html) and [spatial shader stages](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html). The field is a reduced version of this museum's `layered_water.gdshader`, printed above in full.
