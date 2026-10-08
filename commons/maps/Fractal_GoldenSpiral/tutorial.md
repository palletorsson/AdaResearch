# Two values, two views

**Learning elements**

- Numerical recurrence: add the previous two values.
- Append to an ordered array; retain its earlier entries.
- Pass the same record to two height functions.
- Detect one contact; release before accepting another.

## In the museum

Menger replaced each cube with a new generation. Here a new entry joins a record whose earlier values remain. At the first desk, two points carry the last two numbers. They begin at one and one. Predict the sum, then move one point against the other. Two appears in the row. Holding them together adds only once. Release both before asking for another sum; one hand can move a point to its resting partner. The held trigger also requests one step. NEXT, BACK and RESET stay beside you.

The points have the same size. Their labels carry quantities; their distance is only an interaction threshold. The new row on the left gives height a fixed unit. The row on the right compresses the larger values. Both read the same list. The large towers retain HEIGHT, SUM and RULE: SUM provides a fixed-unit witness of the last addition.

## Continue with the point and the cube

Use the prepared Endless Museum workspace. Save the two files below together and attach `sum_points.gd` to an empty, unit-scale Node3D on the floor of the workspace. Its front is local +Z. The museum supplies the camera, lighting, player and installed XRTools. This example creates its own points, labels and two rows; it needs no named scene children or dollar references. Keep your existing PointBody file if it is identical to the included version.

The installed artifact uses this same construction through a small adapter. Its values come from the existing Fibonacci desk, and adding calls that desk's NEXT. Your small script owns its list and computes each new value itself. The museum supplies the plinth and nearby buttons. You do not rebuild the surrounding helix, rectangle or player.

## Read two entries, append one

`values` begins as `[1, 1]`. Negative indices count backwards: `values[-1]` is the last entry; `values[-2]` is the preceding one. `advance()` reads both **before** appending their sum. The first request gives `[1, 1, 2]`; the next reads 1 and 2, giving `[1, 1, 2, 3]`. No earlier entry is replaced.

This is a recurrence: the next value depends on earlier values. The function does not call itself. Each gesture or Enter press asks for one more entry, up to ten. The interaction's `latched` Boolean keeps a contact lasting many physics frames from producing many sums. Releasing both points returns them to their places and clears the latch. This reuses the threshold and state reasoning from Trace and the interaction lessons.

`redraw()` loops over this record twice. `height_for(value, true)` gives each unit 0.05 metres. The other call uses the supplied natural logarithm `log`: `0.5 * log(value) + 0.5`. For 1, 2 and 55, those unscaled heights are approximately 0.500, 0.847 and 2.504 metres, compared with 0.050, 0.100 and 2.750 in the linear view. Logarithms need no derivation in this lesson; inspect what this declared mapping does.

Both rows then use the same `DISPLAY_SCALE = 0.2` to fit the hand table. The small linear row therefore gives one unit **one centimetre**. This common display reduction is separate from the choice of height rule. Neither mapping writes into `values`. A BoxMesh gives each entry a body; moving its centre by half its height keeps every base at the same level.

## The complete small construction

Hold a point and bring it to its partner, press its trigger, or use Enter. Release both points between held requests. Run the small study again to reset; the museum installation also has the nearby BACK and RESET buttons. A value is revealed by either request method, never by an automatic timer.

### sum_points.gd

<!-- student-code:sum_points.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const LIMIT := 10
const DISPLAY_SCALE := 0.2
var values: Array[int] = [1, 1]
var points: Array[XRToolsPickable] = []
var names: Array[Label3D] = []
var drawing: Node3D
var readout: Label3D
var latched := false

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	for i in 2:
		var point = PointBody.new()
		point.tint = Color("76d9d1") if i == 0 else Color("ffa366")
		add_child(point)
		point.position = home(i)
		point.action_pressed.connect(request_step)
		points.append(point)
		names.append(label("", home(i) + Vector3.UP * 0.18, self))
		names[i].pixel_size = 0.0012
	readout = label("", Vector3(0, 1.82, -0.08), self)
	readout.pixel_size = 0.0012
	redraw()

func home(i: int) -> Vector3:
	return Vector3(-0.32 + i * 0.64, 1.25, 0.46)

func any_held() -> bool:
	return points[0].held() or points[1].held()

func _physics_process(_dt: float) -> void:
	for i in 2:
		if not points[i].held():
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, home(i))
		names[i].global_position = points[i].global_position + global_basis.y * 0.18
	if not any_held():
		latched = false
		show_pair()
	elif not latched and points[0].position.distance_to(points[1].position) < 0.19:
		request_step()

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		request_step()

func request_step(_body = null) -> void:
	if latched:
		return
	latched = any_held()
	advance()

func advance() -> void:
	if values.size() >= LIMIT:
		readout.text = "Ten terms. Keep this record; run again to reset."
		return
	var a := values[-2]
	var b := values[-1]
	values.append(a + b)
	redraw()
	names[0].text = str(a)
	names[1].text = str(b)
	readout.text = "%d + %d = %d\nRelease both points for the next pair." % [a, b, a + b]

func height_for(value: int, linear: bool) -> float:
	if linear:
		return 0.05 * value
	return 0.5 * log(float(value)) + 0.5

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	for row in 2:
		var center_x := -0.64 if row == 0 else 0.64
		var linear := row == 0
		for i in values.size():
			var height := height_for(values[i], linear) * DISPLAY_SCALE
			var bar := MeshInstance3D.new()
			var shape := BoxMesh.new()
			shape.size = Vector3(0.075, height, 0.075)
			bar.mesh = shape
			bar.position = Vector3(center_x + (i - 4.5) * 0.10, 1.02 + height * 0.5, 0)
			var finish := StandardMaterial3D.new()
			finish.albedo_color = Color("76d9d1") if i == values.size() - 2 else Color("ffa366") if i == values.size() - 1 else Color("b3c0e6")
			bar.material_override = finish
			drawing.add_child(bar)
			label(str(values[i]), bar.position + Vector3(0, height * 0.5 + 0.05, 0), drawing)
		var heading := label("LINEAR" if linear else "LOGARITHMIC", Vector3(center_x, 1.67, 0), drawing)
		heading.pixel_size = 0.0011
	show_pair()

func show_pair() -> void:
	names[0].text = str(values[-2])
	names[1].text = str(values[-1])
	readout.text = "Same values / two height rules\n%d terms · bring the last pair together" % values.size()
	if values.size() == LIMIT:
		readout.text = "Ten terms · same record in both views\nRun again to reset."

func label(text: String, at: Vector3, host: Node3D) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.00065
	tag.outline_size = 7
	host.add_child(tag)
	return tag
```

### point_body.gd — carried unchanged

This is the same small, frozen pickable point used in the preceding hand models. It supplies pickup, release, the action signal and desktop grab hooks. We reuse that interaction so the new lesson can concern the record and its representations.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## Check what stays the same

After eight requests beyond the two seeds, read:

`1, 1, 2, 3, 5, 8, 13, 21, 34, 55`

There should be ten bars in each row and the same labels in both. A ninth request changes nothing. The last small linear bar is 0.55 metres high; the corresponding logarithmic bar is about 0.501 metres. Joining the points and keeping them together must append only once. After release, their labels become the new last pair.

At the large display, reveal ten terms and turn on SUM. The 21-unit and 34-unit pieces together match 55 units at a common scale. Switching HEIGHT leaves the values and this witness unchanged. Logarithmic tower heights do not add this way: the mapping changes the relation between height and addition.

**Make one independent change.** Change only the starting array to `[1, 2]`. Predict the first five entries and the tenth before running it. The same addition should produce `1, 2, 3, 5, 8, …, 89`. Both views must receive that new record. You changed the initial conditions, while retaining the operation. Keep positive seeds for this supplied logarithmic mapping.

## A separate geometric comparison

Continue to the upright golden rectangle. NEXT removes a square from the remaining rectangle; MEASURE names actual side lengths. Its five-metre width starts with a height of `5 / phi`, where `phi = (1 + sqrt(5)) / 2`. The remainder turns and keeps the long-side/short-side ratio. The squares get smaller while their cut indices increase. They are not the increasing values from your array.

ARC adds quarter circles through those squares. Turning it off leaves the partition. The joined circular pieces are not an exact logarithmic spiral. The nearby helix, seed pattern and shell-like objects also need their own position and turn rules. Keep their differences visible; this lesson's required construction is the pair, record and two readers.

Carry this distinction into Synthesis: a procedure makes data, and another procedure gives that data a form. Name both when composing the next work.
