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

For an independent variation, change `REPEATS` in `relief_maps.gd` from `(3, 3)` to `(4, 2)` and rerun. Both maps are rebuilt from that one edit. Predict the count, aspect and slope changes before comparing the two modes. Four repeats compress the horizontal change into less UV space, so its slope also becomes steeper at the same gain. This exact variation is tested. Then choose another count or gain and explain what remains fixed.

The maps use normalized UV units. The same pattern therefore has different physical sizes on the large square, small square and sphere; it is not a calibrated common bump height in metres. On the sphere, UVs compress near the poles. Use the flat receiver to judge the method before interpreting the curved one.

## Back among the furniture

The installed rim study asks about surface direction and viewing direction. Its emission follows the eye; our normal maps alter how a lit surface is read. Return to STUDY and walk between the sphere and cube. Plastic, velvet and oil are named surface recipes here; the names do not establish fibres, liquid or a changed collision body.

Carry the distinction into Water: a surface may look raised because its shading normals changed, or its vertices may actually move. The next lesson makes that second operation visible and keeps its physical support separate.

References: Godot's [spatial shader interface](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) defines NORMAL_MAP and NORMAL_MAP_DEPTH; its [normal-map documentation](https://docs.godotengine.org/en/4.6/tutorials/3d/standard_material_3d.html#normal-map) describes the OpenGL convention and tangent-space use. The example above constructs its own data from the preceding circle rule.
