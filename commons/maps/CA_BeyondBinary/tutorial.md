# A pattern visits an address

## Learning elements

- A two-dimensional present: X and Y are sites, not generations.
- Eight surrounding neighbours; exclude the centre.
- Birth and survival: B3/S23.
- Fixed address, changing occupancy, apparent movement.
- A separate output: one cell controls one lamp.

## Enter with the point

The last hall kept each new row as history. Here both grid directions belong to the **same present**. Five cells wait in a dish, repeated on the floor. Press STEP four times. The arrangement returns one address farther along both directions. No mesh has moved. Different fixed cells have become occupied.

Take the small black point beside the controls. Carry it to a gold square on the floor and use its trigger to STEP. Follow the address while the pattern passes. The point carries the control; its position does not write into the automaton. REPLAY returns to the beginning. The floor remains solid whether a cell is empty or occupied.

We will reconstruct this relationship at table scale: the same 24 × 24 rule and beginning, one marked address, one lamp and the familiar PointBody. The installation has three lamps, RUN, TRACE and preset buttons. The compact study uses one lamp and manual steps. Those other controls are not needed to understand this operation.

Save the previous lesson. Attach `life.gd` to your existing `PointStudy` Node3D in the museum; keep unit scale and about 3 × 3 metres clear. Face its positive Z side. Keep the unchanged `point_body.gd` beside it. The established museum provides camera, light, player and XR Tools. These two files create all of the study's geometry and behaviour; no prepared child nodes are required.

## Count the surroundings

`current` holds 576 Boolean values. `index(x, y)` finds one address in that flat array. Both coordinates wrap at the boundaries. Logical Y becomes depth Z in `cell_position`; the table's physical height stays fixed. Unlike the previous lesson, stepping does not add a row behind the others.

`neighbours` reads a 3 × 3 patch. The condition `dx != 0 or dy != 0` excludes only its centre, leaving eight neighbours. Their count, together with the centre's old state, selects the answer:

| Current cell | Occupied neighbours | Next cell |
| --- | --- | --- |
| Empty | Exactly 3 | Occupied: birth |
| Occupied | 2 or 3 | Occupied: survival |
| Either | Any other count for that state | Empty |

This is Conway's Game of Life, written B3/S23. `evolve` uses the buffer agreement we already know: read every neighbourhood from `old`, write every answer into a new array, then replace `current`. Reading the answers you have just written would produce a different process, dependent on loop order.

## Connect an address

`SITE` is (10,10). Its gold frame stays in place. `redraw` colours the existing cell instances and passes this site's value to `receive`. That function changes the lamp and its globe. It cannot change the next state of any cell.

Press L while the lamp is lit. The connection is off, so the lamp goes dark. STEP still evolves the cells. Press L again: the lamp reads the current value immediately, without advancing time. REPLAY resets the beginning and generation counter, but preserves your link setting.

We separate a rule from a use of its answer. The same false value that removed support in the previous hall now makes a dark patch on a solid table. `make_display` builds that support once; `redraw` never removes it.

## Complete study — life.gd

The rule is in `neighbours`, `next_state` and `evolve`. The remaining code creates its visible receivers and connects the controls. The full file is included so the example runs; the new lesson does not require memorising the furniture construction.

```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const SIZE := 24
const CELL := 0.08
const LIMIT := 48
const SITE := Vector2i(10, 10)
var seeds: Array[Vector2i] = [Vector2i(7, 6), Vector2i(8, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
var current: Array[bool] = []
var generation := 0
var linked := true
var point: XRToolsPickable
var cells := MultiMesh.new()
var reading := Label3D.new()
var lamp := OmniLight3D.new()
var lamp_finish := StandardMaterial3D.new()

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	replay()
	park()

func index(x: int, y: int) -> int:
	return posmod(y, SIZE) * SIZE + posmod(x, SIZE)

func replay() -> void:
	current.resize(SIZE * SIZE)
	current.fill(false)
	for site in seeds:
		current[index(site.x, site.y)] = true
	generation = 0
	redraw()

func neighbours(old: Array[bool], x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dy != 0:
				count += int(old[index(x + dx, y + dy)])
	return count

func next_state(alive: bool, count: int) -> bool:
	if alive:
		return count == 2 or count == 3
	return count == 3

func evolve(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			next[index(x, y)] = next_state(old[index(x, y)], neighbours(old, x, y))
	return next

func step() -> void:
	if generation == LIMIT:
		return
	current = evolve(current)
	generation += 1
	redraw()

func toggle_link() -> void:
	linked = not linked
	redraw()

func receive(occupied: bool, connected: bool) -> void:
	var lit := occupied and connected
	lamp.light_energy = 1.2 if lit else 0.0
	lamp_finish.albedo_color = Color("90ebca") if lit else Color("50495b")
	lamp_finish.emission = Color("62c4a4") if lit else Color.BLACK
	lamp_finish.emission_energy_multiplier = 1.3 if lit else 0.0

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(-1.2, 1.12, 0.75)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: replay()
			KEY_L: toggle_link()
			_: return
		get_viewport().set_input_as_handled()

func cell_position(x: int, y: int) -> Vector3:
	return Vector3((x - 11.5) * CELL, 1.06, (y - 11.5) * CELL)

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	return node

func make_display() -> void:
	var table := box(Vector3(2.04, 0.1, 2.04), Vector3(0, 1, 0), Color("365159"))
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.04, 0.1, 2.04)
	boundary.shape = shape
	table.add_child(body)
	body.add_child(boundary)
	box(Vector3(0.16, 0.95, 0.16), Vector3(0, 0.475, 0), Color("b39470"))
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = SIZE * SIZE
	var tile := BoxMesh.new()
	tile.size = Vector3(CELL * 0.92, 0.012, CELL * 0.92)
	cells.mesh = tile
	var view := MultiMeshInstance3D.new()
	view.multimesh = cells
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.vertex_color_use_as_albedo = true
	view.material_override = ink
	add_child(view)
	for y in SIZE:
		for x in SIZE:
			cells.set_instance_transform(index(x, y), Transform3D(Basis.IDENTITY, cell_position(x, y)))
	var at := cell_position(SITE.x, SITE.y) + Vector3.UP * 0.015
	for side in [-1, 1]:
		box(Vector3(CELL, 0.008, 0.008), at + Vector3(0, 0, side * CELL / 2), Color("ffcc70"))
		box(Vector3(0.008, 0.008, CELL), at + Vector3(side * CELL / 2, 0, 0), Color("ffcc70"))
	box(Vector3(1.2 - at.x, 0.008, 0.008), Vector3((1.2 + at.x) / 2, at.y, at.z), Color("ffcc70"))
	var globe := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	globe.mesh = sphere
	globe.position = Vector3(1.2, 1.3, at.z)
	lamp_finish.emission_enabled = true
	globe.material_override = lamp_finish
	add_child(globe)
	lamp.position = globe.position
	lamp.light_color = Color("90ebca")
	lamp.omni_range = 1.0
	add_child(lamp)
	reading.position = Vector3(0, 1.85, -0.5)
	reading.font_size = 28
	reading.pixel_size = 0.0015
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for i in current.size():
		cells.set_instance_color(i, Color("90ebca") if current[i] else Color("273e49"))
	var occupied := current[index(SITE.x, SITE.y)]
	receive(occupied, linked)
	reading.text = "B3/S23 / GEN %d / LIMIT %d\nA (%d,%d) = %d / LAMP %s\nTRIGGER / ENTER: STEP   R: REPLAY   L: LINK" % [generation, LIMIT, SITE.x, SITE.y, int(occupied), "LINKED" if linked else "UNLINKED"]
```

## Carried file — point_body.gd

This file is unchanged from the previous hall. Keep it, rather than rebuilding the point. Its inherited pickable action supplies the trigger signal. Release returns this study's point to its local parking position.

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

## Follow what stays

Use the held trigger or Enter to step. After four generations, the glider has the seed's arrangement shifted by (1,1). At generation eight, A is occupied and its linked lamp is lit. At generation twelve, A is empty again. Each tile's position stayed fixed throughout. R replays; the forty-eight-step limit holds the last state.

## Make another beginning

Replace `seeds` with three positions: (9,10), (10,10), (11,10). Predict the first answer before running: a vertical line at (10,9), (10,10), (10,11). Step again to recover the horizontal line. The centre survives both phases, so A's lamp stays lit. Disconnect the lamp and repeat. Explain why the cells still alternate.

Now connect a different address by changing `SITE` to (9,10). The frame, wire and lamp reading move together. The same blinker should make this lamp alternate. The rule and the cell record do not need to change. You have changed which state the room receives.

## What travels onward

A pattern can travel while its addressed receivers stay put. A Boolean rule can answer a separate object without accepting any influence back from it. In the next hall, proximity becomes an input: the observer's body will enter the conditions of the update.
