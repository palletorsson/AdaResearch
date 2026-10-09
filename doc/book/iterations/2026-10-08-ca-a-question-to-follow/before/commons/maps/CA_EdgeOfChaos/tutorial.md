# What a difference keeps

## Learning elements

- Copy a beginning and change one address.
- Keep the update and forcing identical in two runs.
- Measure how many addresses differ and how large the difference is.
- Compare integer truncation with retained fractional values.
- Select a spatial section without advancing time.
- Read display gain separately from the values it makes visible.

## Bring the comparison forward

In the previous room, a changed seed altered the row history while the copied pyramid stayed fixed. Here both volumes use the same procedure. We change one starting value in B and follow what happens to that difference.

Begin in the existing paired study. Set SEED to UNIFORM, DRIVE to zero, PULL to 0.25 and ONE CELL on. Both volumes start at four, except B's centre, which starts at five. Their update counter is still zero.

Walk between the volumes. At Z=5, the selected section contains that centre; at Z=6, it does not. The floor and wall can lose sight of a difference without the arrays losing it. Take the familiar black point beside the console to choose the section by hand instead. While it is held, the hand takes priority. Release it to resume walking as the reader. Its trigger advances one update.

## Reconstruct this experiment

Keep the Day Zero museum and save the previous study. Put `paired.gd`, `difference.gd` and your unchanged `point_body.gd` together. Attach `difference.gd` to the existing `PointStudy`, at unit scale. Approach from positive Z; leave about 3.2 × 2.5 metres clear. The existing museum supplies the player, camera, lighting and XR Tools. Every study mesh, material, label and collider is created below.

The miniature keeps both complete 11³ volumes and their three section images. Move the held point forward and back along the middle rail to select Z. Trigger or Enter advances one update. It starts with the quiet, uniform, integer comparison above; the full exhibit initially uses its scattered, driven beginning. The miniature uses keyboard controls for parameters. The installation retains its nearby VR buttons and walking reader, plus the enlarged difference floor.

## Copy, then intervene

`a` and `b` are packed arrays of 64-bit floating-point numbers. One index represents `x + N*y + N*N*z`. `b = a.duplicate()` makes an independent copy. Only then does B gain one at `site`.

For each address we keep a list of valid neighbours. This is the 26-neighbour volume from the second CA hall, with positions outside the box omitted. A corner has seven neighbours. It does not wrap to the opposite side.

One update keeps three quarters of the present value and adds one quarter of the neighbours' average. More generally, `pull` selects that fraction. Both next arrays are completed from the old arrays before either becomes the present.

The supplied `sample` function returns a reproducible forcing value for an address and generation. A and B receive the **same** value. It is a finite arithmetic schedule, not a claim of independent random samples. Its number recipe is supplied so this lesson can focus on a fair comparison.

`integer_storage` describes what answers we retain, not the array's machine type. In that mode, `int(value)` discards the fractional part before the result returns to the floating-point array. Fractional mode retains that part, subject to finite floating-point precision. Both modes clip answers to the range 0–9.

## Complete paired model — paired.gd

```gdscript
extends RefCounted
const N := 11
const COUNT := N * N * N
const LIMIT := 100
var site := Vector3i(5, 5, 5)
var a := PackedFloat64Array()
var b := PackedFloat64Array()
var neighbours: Array[PackedInt32Array] = []
var tick := 0
var pull := 0.25
var drive := 0.0
var integer_storage := true
var scattered := false
var changed := true

func _init() -> void:
	for z in N:
		for y in N:
			for x in N:
				var ns := PackedInt32Array()
				for dz in range(-1, 2):
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							if dx == 0 and dy == 0 and dz == 0:
								continue
							var p := Vector3i(x + dx, y + dy, z + dz)
							if p.x >= 0 and p.x < N and p.y >= 0 and p.y < N and p.z >= 0 and p.z < N:
								ns.append(index(p))
				neighbours.append(ns)
	reset()

func index(p: Vector3i) -> int:
	return p.x + N * p.y + N * N * p.z

func reset() -> void:
	tick = 0
	a.resize(COUNT)
	for i in COUNT:
		a[i] = float((i * 73 + i * i * 19 + 17) % 10) if scattered else 4.0
	b = a.duplicate()
	if changed:
		b[index(site)] += 1.0

func sample(i: int, generation: int) -> float:
	var h: int = ((i + 1) * 73856093 + (generation + 1) * 19349663 + 83492791) % 2147483647
	h = (h * 48271) % 2147483647
	return float(h % 2001) / 1000.0 - 1.0

func step() -> void:
	if tick >= LIMIT:
		return
	var na := PackedFloat64Array()
	var nb := PackedFloat64Array()
	na.resize(COUNT)
	nb.resize(COUNT)
	for i in COUNT:
		var sa := 0.0
		var sb := 0.0
		for j in neighbours[i]:
			sa += a[j]
			sb += b[j]
		var forcing := drive * sample(i, tick)
		var va := clampf(a[i] * (1.0 - pull) + sa / neighbours[i].size() * pull + forcing, 0.0, 9.0)
		var vb := clampf(b[i] * (1.0 - pull) + sb / neighbours[i].size() * pull + forcing, 0.0, 9.0)
		na[i] = float(int(va)) if integer_storage else va
		nb[i] = float(int(vb)) if integer_storage else vb
	a = na
	b = nb
	tick += 1

func report() -> Dictionary:
	var count := 0
	var maximum := 0.0
	var total := 0.0
	for i in COUNT:
		var difference := absf(a[i] - b[i])
		maximum = maxf(maximum, difference)
		total += difference
		if difference > 0.000001:
			count += 1
	return {"count": count, "maximum": maximum, "mean": total / COUNT}
```

## Measure before judging the picture

`report` subtracts the arrays address by address. The count includes only absolute differences greater than 0.000001. Maximum and mean use every stored difference, including those below that threshold. These quantities answer different questions: how widely detectable difference is distributed, how large the largest difference is, and its average over the whole volume.

The A and B palettes use the same fixed 0–9 scale. The third image magnifies absolute difference by `gain = 1 / max(maximum, 0.000001)`. Gain changes only the image. It is printed beside the measurements because a bright picture can accompany a fading difference.

`select_slice` changes an address in the receiver, not a generation in the model. At each selected Z, X and Y remain spatial coordinates. Gold frames locate that plane in both volumes. Moving the point alone changes neither array; its trigger calls `step`. On release it parks at the selected slice.

## Complete study — difference.gd

Read `step`, `select_slice` and `paint` first. `make_display` supplies the staging. As before, the model and its display have separate jobs.

```gdscript
extends Node3D
const Pair = preload("paired.gd")
const Point = preload("point_body.gd")
const PITCH := 0.085
var model = Pair.new()
var slice_z := 5
var gain := 1.0
var point: Node3D
var reading: Label3D
var textures: Array[ImageTexture] = []
var volumes: Array[MultiMesh] = []
var frames: Array[Node3D] = []

func _ready() -> void:
	make_display()
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): step())
	park()
	paint()

func step() -> void:
	model.step()
	paint()

func select_slice(value: int) -> void:
	var selected := clampi(value, 0, Pair.N - 1)
	if selected != slice_z:
		slice_z = selected
		paint()

func _physics_process(_delta: float) -> void:
	if point.held():
		select_slice(roundi(to_local(point.global_position).z / PITCH + 5.0))
	else:
		park()

func park() -> void:
	point.position = Vector3(0, 1.24, (slice_z - 5) * PITCH)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER:
			step()
			return
		KEY_R: pass
		KEY_I: model.integer_storage = not model.integer_storage
		KEY_C: model.changed = not model.changed
		KEY_P: model.pull = 0.0 if model.pull > 0.0 else 0.25
		KEY_N: model.drive = 1.0 if model.drive == 0.0 else 0.0
		KEY_B: model.scattered = not model.scattered
		_: return
	model.reset()
	paint()

func tint(value: float) -> Color:
	return Color("182c42").lerp(Color("efc0d6"), value / 9.0)

func paint() -> void:
	var result: Dictionary = model.report()
	gain = 1.0 / maxf(result.maximum, 0.000001)
	for side in 3:
		var img := Image.create(Pair.N, Pair.N, false, Image.FORMAT_RGBA8)
		for y in Pair.N:
			for x in Pair.N:
				var i: int = model.index(Vector3i(x, y, slice_z))
				var colour := tint(model.a[i] if side == 0 else model.b[i])
				if side == 2:
					colour = Color("112c31").lerp(Color("ffd18e"), absf(model.a[i] - model.b[i]) * gain)
				img.set_pixel(x, Pair.N - 1 - y, colour)
		textures[side].update(img)
	for side in 2:
		var values: PackedFloat64Array = model.a if side == 0 else model.b
		for i in Pair.COUNT:
			volumes[side].set_instance_color(i, tint(values[i]))
		frames[side].position.z = (slice_z - 5) * PITCH
	reading.text = "UPDATE %d / Z SLICE %d\n%s / %s / ONE CELL %s\nPULL %.2f / DRIVE %.1f\nDIFFERENT %d (>0.000001)\nMAX %.8f / MEAN %.8f / GAIN x%.1f" % [model.tick, slice_z,
		"INTEGER" if model.integer_storage else "FRACTIONAL", "SCATTERED" if model.scattered else "UNIFORM",
		"ON" if model.changed else "OFF", model.pull, model.drive, result.count, result.maximum, result.mean, gain]

func box(parent: Node3D, size: Vector3, at: Vector3, colour: Color, solid: bool = false) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	surface.material_override = material
	parent.add_child(surface)
	if solid:
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		boundary.shape = shape
		surface.add_child(body)
		body.add_child(boundary)

func label(words: String, at: Vector3, pixel: float = 0.0014) -> Label3D:
	var result := Label3D.new()
	result.text = words
	result.position = at
	result.font_size = 32
	result.pixel_size = pixel
	add_child(result)
	return result

func make_display() -> void:
	box(self, Vector3(2.95, 0.08, 1.5), Vector3(0, 1.0, 0), Color("e4dfd4"), true)
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		box(self, Vector3(0.6, 0.96, 0.6), Vector3(cx, 0.48, 0), Color("e4dfd4"))
		var cells := MultiMesh.new()
		cells.transform_format = MultiMesh.TRANSFORM_3D
		cells.use_colors = true
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.03
		cells.mesh = cube
		cells.instance_count = Pair.COUNT
		for z in Pair.N:
			for y in Pair.N:
				for x in Pair.N:
					cells.set_instance_transform(model.index(Vector3i(x, y, z)), Transform3D(Basis.IDENTITY, Vector3(cx + (x - 5) * PITCH, 1.12 + y * PITCH, (z - 5) * PITCH)))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = cells
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		instance.material_override = material
		add_child(instance)
		volumes.append(cells)
		var frame := Node3D.new()
		frame.position = Vector3(cx, 1.545, 0)
		add_child(frame)
		frames.append(frame)
		for sign_ in [-1, 1]:
			box(frame, Vector3(0.012, 0.94, 0.012), Vector3(sign_ * 0.47, 0, 0), Color("ffd18e"))
			box(frame, Vector3(0.94, 0.012, 0.012), Vector3(0, sign_ * 0.47, 0), Color("ffd18e"))
	for side in 3:
		var cx := (side - 1) * 0.85
		var img := Image.create(Pair.N, Pair.N, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(img)
		textures.append(texture)
		box(self, Vector3(0.74, 0.74, 0.035), Vector3(cx, 2.5, -0.8), Color("b59a79"))
		var view := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.7, 0.7)
		view.mesh = quad
		view.position = Vector3(cx, 2.5, -0.777)
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		view.material_override = material
		add_child(view)
		label(["A", "B", "|A-B| x GAIN"][side], Vector3(cx, 2.96, -0.77))
	box(self, Vector3(0.009, 0.009, 0.94), Vector3(0, 1.08, 0), Color("ffd18e"))
	box(self, Vector3(2.6, 0.47, 0.04), Vector3(0, 0.77, 0.78), Color("172937"))
	reading = label("", Vector3(0, 0.77, 0.807), 0.001)
	label("ENTER step / R replay / I storage / C one cell\nP pull / N drive / B seed", Vector3(0, 0.43, 0.81), 0.0009)
```

## Carried object — point_body.gd

Keep your existing PointBody. Its unchanged code is included so the three-file reconstruction is complete.

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

## Make three predictions

**First, keep INTEGER, UNIFORM, PULL 0.25 and DRIVE 0.** At the changed centre, the calculated answer is 4.75. Integer storage keeps four. Its neighbours' small increases also lose their fractions. After one update the count and maximum difference are zero. Both complete arrays agree.

**Now press I.** This selects FRACTIONAL and replays the same beginning. After one update, predict a smaller peak spread over more addresses: the centre differs by 0.75; each of its 26 neighbours differs by 0.25/26. The count is 27. Continue to update 20. Read the maximum beside the gain before calling the larger lit region an amplification.

**Press P to set PULL to zero.** With DRIVE still zero, this replays the beginning and then preserves the original difference at one address through every step. An unchanged picture can retain something that the smoothing update distributes.

Press C to remove the one-cell intervention. A and B should agree. Press N to enable the shared drive; they should still agree. This is a control for the comparison. Press B to switch to the supplied scattered beginning. C, N, B, I and P all replay both arrays after changing their setting. R replays while preserving settings. None changes the selected slice. The model stops at 100 updates.

## Make an independent change

In `paired.gd`, change `site` to `Vector3i(0, 0, 0)`. Run in UNIFORM, FRACTIONAL mode with PULL 0.25 and DRIVE zero. Select Z=0 to see the beginning. Before STEP, predict which addresses can receive it.

After one step, **eight** addresses differ: the corner itself and its seven valid neighbours. The corner difference is still 0.75. A receiving cell averages its own neighbour list: the adjacent edge cell (1,0,0) receives 0.25/11; the interior cell (1,1,1) receives 0.25/26. There is no wrap to the far face. The changed location exposes a boundary choice hidden by the central example. The scaffold expects `site` inside 0–10 on each axis; its +1 experiment is compared from the uniform beginning.

Explain three different disappearances: moving to a slice that misses the changed address, integer storage discarding the difference, and a stored difference falling below the count's threshold. They require different evidence.

This finishes the cellular-automata passage with a testable comparison. In the unforced fractional case, averaging spreads and reduces the peak; brightness alone does not establish chaos. Fractals returns to explicit repetition: what changes when the procedure calls itself instead of waiting for neighbouring states to exchange values?
