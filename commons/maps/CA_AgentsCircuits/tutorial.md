# Two ways to make

## Learning elements

- Rule 90: a next cell is occupied when its two neighbours differ.
- Independent rows store successive states; a picture can show time along one axis.
- A supplied copying recipe places cubes without reading a cellular state.
- Change one input, then identify which construction responds.
- A finite boundary limits a pattern that appears to keep growing.

## Reading route

Read `next_row`, then inspect the inputs to supplied `copy_positions`. Change the cellular seed before changing either display; deriving the recursive recipe belongs to Fractals. The complete files also include the display and controls; keep those working while investigating the named functions.

## Return to the row

The previous hall separated what happens at an address from what it receives from neighbours. Here we return to the Boolean row from the CA opening and the saved history from the third hall. We change its rule, then compare its way of making with the pyramid already in the room.

At the explorer, select 90 and replay the single central seed. The stored rows appear both on the desk and on the floor. Take the same black point at the desk's front rail. Moving it sideways selects a current-row address; its trigger advances one generation. Read the neighbours before pressing. The point is an inspector and a STEP control here, not a seed brush.

Follow one triangular gap across the floor toward the pyramid. Both constructions suggest repeated shapes. Find out what each procedure reads before treating that resemblance as an explanation.

## Reconstruct this comparison

Save your earlier study. Put `procedures.gd`, `comparison.gd` and the unchanged `point_body.gd` together. Attach `comparison.gd` to the existing `PointStudy` Node3D in the Day Zero museum, at unit scale. Leave about 4 × 2.5 metres clear and approach its positive Z side. The museum continues to supply the player, camera, lighting and XR Tools. All required study children are built below.

The compact model shows one history table and one fixed cube construction. The museum also enlarges its history onto the floor and supplies richer rule controls. This reconstruction stays with Rule 90. Enter or the held point's trigger steps; R replays the selected seed; C switches between one cell and two adjacent cells and replays. C and R are keyboard controls here; use the installed desk's SEED and RST buttons in the full VR encounter. Walking keys remain available.

## What does a cell read?

For Rule 90 the centre does not affect the answer. Read the old left and right values. If exactly one is true, the next value is true. If they agree, it is false. For Booleans, `left != right` expresses exclusive OR, often called XOR.

| Left | Right | Next |
| --- | --- | --- |
| false | false | false |
| false | true | true |
| true | false | true |
| true | true | false |

The existing explorer evaluates a numbered eight-case rule including the centre. Its Rule 90 gives this same answer for all eight cases. The shorter expression below exposes that particular rule; it does not replace the general evaluator in the museum.

`next_row` reads the complete old row and returns a new one. The last address neighbours the first. `history` keeps those rows in chronological order. Each row's horizontal positions are space; advancing along the table shows time. New rows change neither the earlier arrays nor the pyramid's positions.

## What does the copying recipe read?

`copy_positions` is supplied from the installed pyramid's placement logic. It reads a position, spacing and remaining depth. At depth zero it returns one position. Otherwise it calls itself at six offsets with half the spacing and one less depth. A function that calls itself is recursive; we will study that process through the Fractals sequence. Here follow just one call and notice its inputs.

The six placements are four lower corners and two upper positions. This particular recipe has an extra upper branch. It does not inspect neighbouring cubes, read the cellular row, or wait for a clock. The returned list contains one entry per leaf call, including entries that may coincide. Every displayed cube keeps the same size; spacing changes during the construction. The result is a finite collection with overlaps, not a demonstration of an ideal fractal's dimension.

At depth 3 the procedure returns 6 × 6 × 6 = 216 entries. The large museum pyramid uses depth 4: 1,296 entries. The compact model scales all final positions and cube sizes together, so its smaller version retains the recipe's proportions. We supply that recipe to make the comparison inspectable; deriving it is not a prerequisite for the neighbour-rule lesson.

## Complete procedures — procedures.gd

<!-- student-code:procedures.gd -->
```gdscript
extends RefCounted
const N := 32

func next_row(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(N)
	for i in N:
		var left := old[posmod(i - 1, N)]
		var right := old[(i + 1) % N]
		next[i] = left != right
	return next

func copy_positions(at: Vector3, spacing: float, depth: int) -> Array[Vector3]:
	# Supplied recipe from the installed pyramid; it reads no cell states.
	if depth == 0:
		return [at]
	var half := spacing / 2.0
	var offset := half / 2.0
	var shifts: Array[Vector3] = [
		Vector3(0, half, 0), Vector3(0, offset, 0),
		Vector3(-offset, -offset, -offset), Vector3(offset, -offset, -offset),
		Vector3(-offset, -offset, offset), Vector3(offset, -offset, offset)
	]
	var positions: Array[Vector3] = []
	for shift in shifts:
		positions.append_array(copy_positions(at + shift, half, depth - 1))
	return positions
```

## Keep the two constructions independent

`make_display` asks for the cube positions once. `step` asks only for a next cellular row. `reset` restores that history from `seed_sites`. None of those cellular operations rebuilds or edits the cubes.

The same PointBody from the previous room supplies its held world position. Converting to study-local X selects an address along the rail. This changes `selected`, not the cells. The readout predicts that address's next value. Release parks the point at the selected address.

`redraw` places every recorded cell, including zeros. Dark tiles show false; they are not holes. Unrecorded rows have zero-size transforms. The table's collider remains solid beneath both states. The miniature cubes are visual instances on a solid plinth; the installed pyramid uses the museum's cube prefab and its colliders. The compact model does not rebuild that larger climbing geometry.

## Complete study — comparison.gd

Read `reset`, `step` and `readout` first. `draw_instances` and `make_display` include the staging so the example can run without prepared child nodes. There is one `_ready`.

<!-- student-code:comparison.gd -->
```gdscript
extends Node3D
const Procedures = preload("procedures.gd")
const PointBody = preload("point_body.gd")
const ROWS := 24
const PITCH := 0.05
const DEPTH := 3
const VIEW_SCALE := 0.18
var methods := Procedures.new()
var seed_sites: Array[int] = [16]
var history: Array[Array] = []
var cells := MultiMesh.new()
var copies := MultiMesh.new()
var positions: Array[Vector3] = []
var point: XRToolsPickable
var reading := Label3D.new()
var selected := 16

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park()

func reset() -> void:
	var row: Array[bool] = []
	row.resize(Procedures.N)
	row.fill(false)
	for i in seed_sites:
		row[posmod(i, Procedures.N)] = true
	history.clear()
	history.append(row)
	redraw()

func step() -> void:
	if history.size() == ROWS:
		return
	var old: Array[bool] = []
	old.assign(history.back())
	history.append(methods.next_row(old))
	redraw()

func change_seed() -> void:
	seed_sites.assign([16, 17] if seed_sites.size() == 1 else [16])
	reset()

func _physics_process(_delta: float) -> void:
	if point.held():
		var x := to_local(point.global_position).x
		selected = clampi(floori((x + 1.15) / PITCH + 16), 0, 31)
	else:
		park()
	readout()

func park() -> void:
	point.position = Vector3(-1.15 + (selected - 15.5) * PITCH, 1.15, 0.85)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: reset()
			KEY_C: change_seed()
			_: return
		get_viewport().set_input_as_handled()

func at(col: int, row: int) -> Vector3:
	return Vector3(-1.15 + (col - 15.5) * PITCH, 1.005, (11.5 - row) * PITCH)

func redraw() -> void:
	for row in ROWS:
		for col in Procedures.N:
			var recorded := row < history.size()
			var alive: bool = recorded and history[row][col]
			var basis := Basis.IDENTITY if recorded else Basis.IDENTITY.scaled(Vector3.ZERO)
			cells.set_instance_transform(row * 32 + col, Transform3D(basis, at(col, row)))
			cells.set_instance_color(row * 32 + col, Color("eadcc1") if alive else Color("183f45"))
	readout()

func readout() -> void:
	var row: Array = history.back()
	var left: bool = row[posmod(selected - 1, 32)]
	var right: bool = row[(selected + 1) % 32]
	reading.text = "RULE 90 / GEN %d / CELL %d\nLEFT %d   RIGHT %d   NEXT %d\nENTER / TRIGGER: STEP   R: REPLAY   C: SEED\nHISTORY CHANGES / %d COPY POSITIONS STAY" % [history.size() - 1, selected, int(left), int(right), int(left != right), positions.size()]

func box(size: Vector3, place: Vector3, colour: Color, solid: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = place
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	if solid:
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		boundary.shape = shape
		node.add_child(body)
		body.add_child(boundary)
	return node

func draw_instances(data: MultiMesh, size: Vector3, colour: Color, colours: bool) -> void:
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_colors = colours
	var mesh := BoxMesh.new()
	mesh.size = size
	data.mesh = mesh
	var view := MultiMeshInstance3D.new()
	view.multimesh = data
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.vertex_color_use_as_albedo = colours
	view.material_override = material
	add_child(view)

func make_display() -> void:
	box(Vector3(1.72, 0.08, 1.32), Vector3(-1.15, 0.96, 0), Color("c9c5bd"), true)
	box(Vector3(0.6, 0.92, 0.6), Vector3(-1.15, 0.46, 0), Color("aaa89f"))
	draw_instances(cells, Vector3(PITCH * 0.95, 0.006, PITCH * 0.95), Color.WHITE, true)
	cells.instance_count = 32 * ROWS
	box(Vector3(1.25, 1.08, 1.25), Vector3(0.8, 0.54, 0), Color("c9c5bd"), true)
	draw_instances(copies, Vector3.ONE * VIEW_SCALE, Color("dfacc4"), false)
	positions = methods.copy_positions(Vector3.ZERO, pow(2, DEPTH - 1), DEPTH)
	copies.instance_count = positions.size()
	for i in positions.size():
		copies.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0.8, 1.50, 0) + positions[i] * VIEW_SCALE))
	box(Vector3(1.6, 0.006, 0.008), Vector3(-1.15, 1.04, 0.85), Color("ffd77d"))
	reading.position = Vector3(-0.4, 2.45, -0.5)
	reading.font_size = 34
	reading.pixel_size = 0.0015
	add_child(reading)
```

## Unchanged carried object — point_body.gd

Keep your existing copy from the previous hall. It is repeated here only to make the three-file example complete.

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

## One beginning, two kinds of change

Replay the single cell at address 16. Before STEP, predict addresses 15, 16 and 17. After one update, 15 and 17 are occupied; 16 is empty. Both new cells read the old 16. No cube in the pyramid moves.

Advance to generation 15 and compare a gap with the fixed sculpture. Then predict generation 16 before pressing. On this 32-cell ring, both expanding edges reach the same opposite address. That address reads two true neighbours, so XOR returns false. The entire next row is empty and remains empty. The pattern did not reach an infinite limit: the finite periodic boundary changed the situation.

Press C to try two adjacent cells. It restarts the cellular history while keeping the same copying construction. Step and compare. Which resemblance survives? You can test the changed row; a visual match with the sculpture remains a judgment about selected features, not a proof that the procedures agree.

Make this guided edit: set `seed_sites` to **[14, 16, 18]**, then restart the script. Predict the first row before pressing Enter. Only addresses **13 and 19** should be occupied. Addresses 15 and 17 each receive two true neighbours and cancel. Check the readout at either cancelled address, and confirm that the 216 cube transforms stayed the same. R replays your edited seed; C returns to the built-in single/pair choices.

The compact table stops after 24 stored rows, generations 0–23, so the comparison stays inspectable. The installed explorer can continue and scrolls its last 24 rows; it labels that retained range. These are different display budgets for the same row update.

You can now distinguish repeating an update from repeating a placement. The next hall keeps the procedure fixed and changes one starting value, asking how far that difference travels.

## Your own test

Choose another seed and nominate a feature to compare with the fixed sculpture. Verify that the cube transforms stay fixed, even if the visual resemblance no longer persuades you. Keep your prediction, the observed values and a runnable assertion in a separate test script. If they disagree, identify whether the prediction, test or study needs changing.

