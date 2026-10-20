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

The other rack offers Truchet arcs, staggered rows and further patterns. They show what can happen when the whole tile address also affects the rule. Visit them as comparisons; the required construction is the small repeated mask above. The existing flower garden and saved-record instrument are optional returns below.

Carry the same material, its coordinate convention and its parameters onward. In Materials, a change in surface orientation will alter how light reads a body; bump and normal mapping belong there. Nothing in this mask has yet moved a vertex or changed collision.

References: the coordinate-repetition exercise draws inspiration from [The Book of Shaders, Patterns](https://thebookofshaders.com/09/). Godot's [`floor` and `fract` reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shader_functions.html) gives their component-wise definitions. The museum adapter and code here use Godot spatial materials.

---

## Optional return: the pattern crosses a flower

The installed flower garden offers another receiver for the same question. Change phase while watching one petal. Its position stays fixed. In `commons/artifacts/reference_studies/pattern_garden.gd`, the supplied `surface()` recipe sets phase from the control amount; halve its original 0.5 multiplier to 0.25 and predict the reduced movement. This is a source-edit encounter using its supplied meshes and controls, not an additional required reconstruction.

<!-- uncertainty:p4-record -->

## Optional return: one record, different readings

**Learning elements:** RGB8 records; row-major addresses; channel permutation; a colour-to-height mapping; unsigned and signed integers; layout validation; source identity.

The pattern lesson stays first. Then go to the existing camera instrument and press **READ RECORD**. Its left screen retains an 8 × 8 colour record. EFFECT now selects five readings on the right. The original FORM and PIXELS effects remain available through the bank button, or by leaving READ RECORD.

Press **SAVE 8 × 8** to sample the current camera view. The instrument takes one pixel at the centre of each of 64 regions; it does not average the region or recover depth. Each sample contributes red, green and blue bytes, giving 192 bytes in row-major RGB order. Moving the camera afterwards does not update this record. Saving again deliberately replaces it. This snapshot lasts while the instrument is loaded; it is not written to disk.

Choose **FIXTURE** for known values. Red increases across its columns through 0, 1, 63, 127, 128, 192, 254 and 255. Blue uses those values down the rows; green alternates 0 and 255. This supplied pattern makes boundaries easy to inspect before returning to a captured image.

In **RGB**, read each triplet as colour. In **BGR**, exchange red and blue in the receiver. Apply the exchange twice and the original order returns. The source stays untouched throughout. The small checksum is an identity witness, not a measure of the image's quality or meaning.

In **UNSIGNED HEIGHT**, choose R, G or B with CHANNEL. A byte divided by 255 becomes a height, multiplied by the strength setting and 1.2 metres. In **SIGNED HEIGHT**, the same eight bits use two's-complement interpretation: 0–127 remain, while 128–255 mean −128 through −1. Height now uses the signed value divided by 128. Both scales are declared. The witness follows cell (4, 0): its red byte is 128 in the fixture, so the second reading crosses below zero. This is a chosen mapping from colour data, not measured camera depth.

The fifth reading requests **7 × 8 RGB**. It would require 168 bytes, but the record has 192. This lesson's strict decoder returns an invalid result instead of truncating, wrapping or reading past the buffer. Other contracts are possible; this one must be explicit. RESET VIEW restores RGB, channel R and 80% strength without replacing the saved bytes.

### Reconstruct the data operation

You bring arrays, loops, coordinates, colour components and functions. The museum camera, console, display meshes and XRTools input are supplied. The following is the complete data core used by this installed study. Save it as **saved_record.gd**. Its `capture(image)` method accepts a supplied Godot Image; `fixture()` provides a complete known input when testing without the museum renderer. The code rebuilds the record and its interpretations, not the camera or the console.

```gdscript
extends RefCounted
## A finite RGB8 record. Receivers borrow copies; they do not rewrite the source.
const SIDE := 8
const LENGTH := SIDE * SIDE * 3
var _bytes := PackedByteArray()

func load_bytes(source: PackedByteArray) -> bool:
	if source.size() != LENGTH: return false
	_bytes = source.duplicate()
	return true

func bytes() -> PackedByteArray:
	return _bytes.duplicate()

func digest() -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256);hash.update(_bytes)
	return hash.finish().hex_encode()

func capture(image: Image) -> bool:
	if image == null or image.is_empty(): return false
	var result := PackedByteArray()
	for y in SIDE:
		for x in SIDE:
			# One centre sample per region; this is not an average or depth scan.
			var px := mini(image.get_width()-1, floori((x+.5)*image.get_width()/SIDE))
			var py := mini(image.get_height()-1, floori((y+.5)*image.get_height()/SIDE))
			var colour := image.get_pixel(px,py)
			for value in [colour.r,colour.g,colour.b]: result.append(roundi(clampf(value,0,1)*255))
	return load_bytes(result)

func fixture() -> void:
	var levels := [0,1,63,127,128,192,254,255]
	var result := PackedByteArray()
	for y in SIDE:
		for x in SIDE:
			result.append(levels[x]);result.append(255 if (x+y)%2 else 0);result.append(levels[y])
	load_bytes(result)

static func decode(source: PackedByteArray, width: int, height: int, signed_values := false) -> Dictionary:
	if width <= 0 or height <= 0 or width > 64 or height > 64 or source.size() != width*height*3:
		return {"valid":false,"error":"RGB8 layout requires exactly width * height * 3 bytes","values":[]}
	var values: Array[int] = []
	for value in source:
		values.append(value if not signed_values or value < 128 else value-256)
	return {"valid":true,"error":"","values":values}

func colour_image(swapped := false) -> Image:
	var result := _bytes.duplicate()
	if swapped:
		for i in range(0,result.size(),3):
			result[i] = _bytes[i+2];result[i+2] = _bytes[i]
	return Image.create_from_data(SIDE,SIDE,false,Image.FORMAT_RGB8,result)

func heights(channel: int, signed_values: bool, gain: float) -> PackedFloat32Array:
	assert(channel >= 0 and channel < 3)
	var decoded := decode(_bytes,SIDE,SIDE,signed_values)
	assert(decoded.valid)
	var result := PackedFloat32Array()
	for cell in SIDE*SIDE:
		var value: int = decoded.values[cell*3+channel]
		result.append(value / (128.0 if signed_values else 255.0) * clampf(gain,0,1) * 1.2)
	return result
```

The cell address is `y * 8 + x`; multiply by three and add 0, 1 or 2 to select red, green or blue. `bytes()` and the receiver image use copies. That makes it possible to interpret or exchange channels without accidentally rewriting the retained source. The decoder checks dimensions and byte count before looking at values. A sign change belongs to decoding; the height scale belongs to the receiver.

Save **record_check.gd** beside the first file. In a Godot project, run `godot --headless --path <project-folder> --script res://record_check.gd` using your Godot executable. This small check requires no `.tscn`, add-on or hidden scene reference. The spatial encounter remains in Endless Museum.

```gdscript
extends SceneTree
const Record = preload("res://saved_record.gd")

func _initialize() -> void:
	var record = Record.new()
	record.fixture()
	var original: PackedByteArray = record.bytes()
	var checksum: String = record.digest()
	assert(original.size() == 192)
	var unsigned: Dictionary = Record.decode(original, 8, 8)
	var signed_values: Dictionary = Record.decode(original, 8, 8, true)
	assert(unsigned.valid and signed_values.valid)
	assert(unsigned.values[12] == 128)
	assert(signed_values.values[12] == -128)
	assert(is_equal_approx(record.heights(0, true, 1)[4], -1.2))
	var exchanged = Record.new()
	exchanged.load_bytes(record.colour_image(true).get_data())
	assert(exchanged.colour_image(true).get_data() == original)
	assert(not Record.decode(original, 7, 8).valid)
	assert(record.digest() == checksum and record.bytes() == original)
	print("RECORD EXAMPLE: 8 assertions passed")
	quit()
```

**Independent variation:** choose the blue channel at full strength. Predict which direction the fixture's slope runs, then compare it with red. Copy the saved bytes, set byte 12 to 255, and load that copy into another record. Unsigned reading gives 255; signed reading gives −1. Check that the original record and its checksum remain unchanged. This time you changed data deliberately; that is a different operation from switching receivers.

**Carry onward:** a bounded record, its address convention, an explicit interpretation and a way to detect whether it changed. The next uncertainty study can ask what happens when a reading returns to influence an action.
