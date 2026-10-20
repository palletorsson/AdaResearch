# Caves and Mazes — a route needs room

## Learning elements

- Reuse recorded positions as carving centres
- Store a solid volume in a one-dimensional array
- Clear a footprint and headroom around each centre
- Separate the route, its cleared volume and its display

Percolation kept the cells and changed which ones a signal could reach. Here we change the cells themselves. Our point still advances the work. The position list returns from Trace: a position tells us where an operation happens, but does not yet say how much space it needs.

## Read the existing cave

At the museum desk, turn on TRACE. Gold dots mark carving centres inside the cave. They include repeated visits. They do not connect separate walkers into one invented journey. CAVE SEED changes the walk while keeping the carving rule.

The installed cave starts walkers on four sides, biases them towards the centre, then makes them wander and climb through prescribed levels. Its construction is partly random and partly directed. We will isolate one operation from it: clear cells around a supplied centre. Learning another random walker would hide that operation among things we already know.

## Keep the route; give it room

Save the three complete files below together in the prepared Endless Museum project. Attach `cave.gd` to an empty Node3D at unit scale in a clear working bay. Our tested placement is hall-local (10.5, 0, 10), yaw 180 degrees. The museum supplies the floor, player, camera and XRTools.

`carver.gd` is the data model. A cell contains 1 for solid or 0 for air. We store a seven-by-four-by-seven volume as 196 bytes in a `PackedByteArray`. This is a compact list of integer values. `index()` gives each three-dimensional address one slot: x changes fastest, then z, then y. Advancing x adds 1; advancing z adds 7; advancing y adds 49. Check the bounds before reading or writing a slot.

`carve()` applies a footprint at a centre. With radius 1, the lateral distance test admits the centre and four face neighbours in the x/z plane. It excludes the four diagonal corners. This is a five-cell cross, not a three-by-three square and not a sphere. The operation repeats that footprint upwards for two layers: dy is 0, then 1. At a boundary, out-of-volume cells are ignored.

<!-- student-code:carver.gd -->
```gdscript
extends RefCounted
const SIZE := Vector3i(7, 4, 7)
const RADIUS := 1
const HEADROOM := 2
var solid := PackedByteArray()
var history: Array[Vector3i] = []

func reset() -> void:
	solid.resize(SIZE.x * SIZE.y * SIZE.z)
	solid.fill(1)
	history.clear()

func inside(p: Vector3i) -> bool:
	return p.x >= 0 and p.x < SIZE.x and p.y >= 0 and p.y < SIZE.y and p.z >= 0 and p.z < SIZE.z

func index(p: Vector3i) -> int:
	return (p.y * SIZE.z + p.z) * SIZE.x + p.x

func carve(center: Vector3i) -> void:
	history.append(center)
	for dy in HEADROOM:
		for dz in range(-RADIUS, RADIUS + 1):
			for dx in range(-RADIUS, RADIUS + 1):
				var p := center + Vector3i(dx, dy, dz)
				if inside(p) and Vector2i(dx, dz).length() <= RADIUS:
					solid[index(p)] = 0

func air_count() -> int:
	return solid.count(0)
```

For one interior centre at ground level, predict ten empty cells: five across two layers. At the front boundary only eight fit inside the volume. A repeated carve leaves the same air cells, but adds another entry to `history`. The final void cannot tell us how many times we cleared it.

## Watch each removal

`cave.gd` supplies nine centres, including one repeated position. The route enters at z = 6, turns, and leaves at z = 0. These are declared test data, not a recording secretly obtained from another scene. You can later supply a saved, suitably mapped trace. Here we keep this short list fixed so that two clearance choices can be compared exactly.

Each press of SPACE, or action on the held point, applies the next centre. `cursor` is the index of that entry; it stops at the list's length. F applies the remaining entries. R refills the volume and clears the operation history. None of these changes the route.

The display uses our existing cube and sphere construction. A remaining solid cell becomes a cube; a recorded centre becomes a gold dot. `location()` converts addresses to the small study's local positions. At 0.28 metres per cell, two layers mean 0.56 metres, so this is a hand model. The production cave has one-metre cells. Its two-layer clearance is nominally two metres before we check turns, boundaries, support and the player's actual body.

<!-- student-code:cave.gd -->
```gdscript
extends Node3D
const Carver = preload("carver.gd")
const PointBody = preload("point_body.gd")
const EDGE := 0.28
const ROUTE := [Vector3i(3,0,6), Vector3i(3,0,5), Vector3i(3,0,4),
	Vector3i(3,0,4), Vector3i(4,0,4), Vector3i(4,0,3),
	Vector3i(4,0,2), Vector3i(4,0,1), Vector3i(4,0,0)]
var model := Carver.new()
var point := PointBody.new()
var drawing := Node3D.new()
var caption := Label3D.new()
var cursor := 0
var cutaway := false

func _ready() -> void:
	add_child(drawing)
	add_child(caption)
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	park()
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 1.45))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("STEP")
		KEY_F: act("FINISH")
		KEY_C: act("CUT")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"STEP": advance()
		"FINISH":
			while cursor < ROUTE.size(): advance()
		"CUT": cutaway = not cutaway
		"RESET":
			model.reset()
			cursor = 0
	redraw()

func advance() -> void:
	if cursor < ROUTE.size():
		model.carve(ROUTE[cursor])
		cursor += 1

func location(p: Vector3i) -> Vector3:
	return Vector3(p - Vector3i(3,0,3)) * EDGE + Vector3(0, 0.75 + EDGE / 2, 0)

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("eee8dc")
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("efb751")
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * EDGE
	for y in Carver.SIZE.y:
		for z in Carver.SIZE.z:
			for x in Carver.SIZE.x:
				var p := Vector3i(x,y,z)
				if model.solid[model.index(p)] == 0: continue
				if cutaway and y >= 2: continue
				var cell := MeshInstance3D.new()
				cell.mesh = cube
				cell.material_override = stone
				cell.position = location(p)
				drawing.add_child(cell)
	var dot := SphereMesh.new()
	dot.radius = 0.025
	dot.height = 0.05
	for p in model.history:
		var mark := MeshInstance3D.new()
		mark.mesh = dot
		mark.material_override = gold
		mark.position = location(p)
		drawing.add_child(mark)
	caption.text = "A ROUTE NEEDS ROOM\n%d / %d centres | %d empty cells | headroom %d\nSPACE / held action: carve | F: finish | C: cutaway | R: reset\n%s" % [cursor, ROUTE.size(), model.air_count(), Carver.HEADROOM,
		"CUTAWAY: upper two layers hidden, data kept" if cutaway else "All remaining solid cells shown"]
```

The cubes touch face to face. Their bottom layer begins 0.75 metres above the host origin; this floating model has no floor or collision. It is an illustration of the carved data, not a second walkable cave.

C hides the upper two layers for inspection. It does **not** carve them or change the array. Its caption names the cutaway. With the complete solid visible, look through the entrance; with the cutaway, follow the bend from above. A display decision must not quietly become a claim about the interior.

## The point stays the same

Copy `point_body.gd` unchanged from Percolation. Its complete contents are printed here so the example has no hidden construction. The sphere remains our held control: moving it alone does not carve; its action advances one entry. Releasing it returns it beside the model. These behaviours belong to the host script above, not a new point class.

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

## Change one condition

Before editing, finish the nine entries and inspect the entrance with C off. Change **only** `HEADROOM := 2` to `HEADROOM := 3` in `carver.gd`, run again, and finish the same route.

Predict three things: the recorded centres remain identical; every previously empty cell remains empty; one more layer clears above each distinct footprint cell. The roof is still present at y = 3 because this volume has four layers. The first interior centre now clears fifteen cells. The front-boundary centre clears twelve. A repeated visit still adds history without making more air.

Explain why doubling the number of recorded visits would not necessarily double the void. Then return to the full cave. A connected route of centres and an adequately clear, supported passage are different results. This small model makes the footprint visible; a body-clearance test belongs to the actual collision geometry.

## Compare the maze; carry the distinction

The other installed study removes walls in a nine-by-nine grid. MAZE STEP chooses an unvisited neighbour, opens the intervening wall and pushes the previous cell onto a stack. At a dead end it pops a previous cell and tries another branch. FINISH completes it; RESET starts that construction again. This is the next comparison to read in the room, not a second implementation hidden in our three files. Binary space partitioning remains another museum artifact.

The cave stores solid and air at volume addresses. The maze stores walls, visited cells and a return stack. Neither record alone measures whether your body fits. Keep the distinction between a list of centres, the volume produced around them, and the object shown by the renderer. Sculpted Forms will ask what another sampling operation can keep from a group of moving bodies.

Source operations: `algorithms/proceduralgeneration/growth_systems/caverandomwalk/caverandomwalk.gd` (`_idx`, `_carve_ball`, `_carve_cave`) and the installed controls in `commons/artifacts/timing_machines/pg_workshop.gd`. The maze comparison uses `algorithms/proceduralgeneration/procedural_logic/mazegeneration/maze_generator_vr.gd`.

## Keep, change, compare

Keep the nine carving centres, including the repeated entry. Change headroom. Compare the empty cells and the event history separately: the finished void does not record how often a cell was cleared.
