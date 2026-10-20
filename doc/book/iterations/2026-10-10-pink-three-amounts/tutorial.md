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

---

## Optional return — the body in the plural

This existing edit is a separate observation exercise with supplied geometry. It is not part of the three-file reconstruction or its test result.

<!-- study-spine:reference_plural_body -->

## Return: A body in the plural

Change the unfolding parameter; retain six limbs and three heads. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses transform, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`body`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_plural_body -->

### One source change: A body in the plural

This existing expression controls one lateral control point of the limb curve. Change 2.3 to 1.8. Keep the outer loops and compare all six limbs at the same unfolding setting.

```gdscript
lerpf(1.0, 2.3, amount)
```

Source: `commons/artifacts/reference_studies/plural_body.gd`. Use the prepared scene to run and compare.
