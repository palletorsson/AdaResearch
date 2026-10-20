# A row with neighbours

## Learning elements

- Binary cell state: `bool`.
- An ordered neighbourhood: left, self, right.
- A rule as eight stored answers.
- A synchronous update: read the old row, then replace it.
- A wrapped boundary.
- Current state and retained history.

## Reading route

Read `answer`, `evolve` and `remember`: one local answer, one simultaneous update, one copied record. The complete files also include the display and controls; keep those working while investigating the named functions.

## At the board

We are in Endless Museum. The explorer already works. Hold its small black point and move your hand sideways: three marks follow the selected address. The point reads the row; it does not turn a cell on. Press the trigger to advance one generation. The overhead ring receives the same stored rows.

Choose Rule 90 and a single seed. Pause before stepping. Pick a cell, read its left neighbour, itself and its right neighbour, and predict its next state from the table below. The museum's side plate can check your answer. Our smaller reconstruction leaves that prediction to you.

## What we carry

The Shader sequence ended with a field that kept its previous state. We keep that old-to-next agreement and open a smaller rule: three Boolean inputs choose one answer. No shader machinery is needed for this row.

Trace gave us an array of positions; Grid gave those positions addresses. Arrays let us read and replace stored entries. Here each address holds a Boolean: `false` or `true`. The address stays; its state changes. We reuse the pickable sphere from the point lessons as a reader. Its hand position selects an address in the study's local frame.

Continue on your existing `PointStudy` node inside the museum, keeping its earlier script as a previous working version. Save both files below in one folder and attach `row.gd` to that node. Use unit scale. This builds a separate small experiment inside the museum. The camera, lighting, player and XR Tools are already present from Day Zero. If the node is not present in your working scene, add an empty Node3D named `PointStudy` under the hall you are editing. Attach only the current lesson host to it. Save each lesson in its own folder before replacing the host; all relative helper paths resolve inside that folder. No authored mesh, label or scene-child reference is required. Face the node's positive Z side; the board is 0.95 metres above its origin. Keep this experiment separate from the installed explorer while comparing them.

The existing project's XRTools setup includes the `XRToolsUserSettings` and `XRToolsRumbleManager` autoloads, from `addons/godot-xr-tools/user_settings/user_settings.gd` and `addons/godot-xr-tools/rumble/rumble_manager.gd`. They are supplied dependencies, not objects to rebuild in this lesson.

## Three inputs, eight answers

| Left / self / right | Address in the answer list | Next state, Rule 90 |
|---|---:|---:|
| 000 | 0 | 0 |
| 001 | 1 | 1 |
| 010 | 2 | 0 |
| 011 | 3 | 1 |
| 100 | 4 | 1 |
| 101 | 5 | 0 |
| 110 | 6 | 1 |
| 111 | 7 | 0 |

`4 * int(left) + 2 * int(self_cell) + int(right)` turns the ordered inputs into an address. `int(false)` is zero; `int(true)` is one. Compare `100` with `010`: both contain one active cell, but use different entries. A count alone would lose information.

The installed explorer packs these eight answers into the number 90. We keep them as a readable list. They give the same answers; bit operations can wait.

## Give every cell the same present

`evolve` allocates a separate `next` array. Its loop reads only `old`. The result replaces `current` after all addresses have received an answer. Writing directly into `old` would allow a freshly changed neighbour to affect a later calculation.

`posmod` supplies our boundary choice. With 32 cells, the left neighbour of cell 0 is cell 31; the right neighbour of 31 is 0. The calculation joins the ends even when we draw a straight row.

`remember` puts a copy of the current row at the front of `history`. This copy is an observation, not another neighbourhood. Twenty-four observations fit on the board. Older ones leave the display while the generation count continues. The newest row is at the far edge; earlier rows extend towards you. History's second dimension describes time, not a second spatial direction in the rule.

## Complete `row.gd`

The first half defines the state and its update. `make_display` supplies the repeated boxes, marks and label; `redraw` gives those boxes the stored states. Both are included so the experiment can be reconstructed. MultiMesh is display plumbing here, not another lesson to master before understanding the rule.

<!-- student-code:row.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const WIDTH := 32
const ROWS := 24
const SPAN := 1.6
# Inputs:                  000    001   010    011   100   101    110   111
var answers: Array[bool] = [false, true, false, true, true, false, true, false]
var seeds: Array[int] = [16]
var current: Array[bool] = []
var history: Array[Array] = []
var generation := 0
var selected := 16
var point: XRToolsPickable
var tiles := MultiMesh.new()
var reading := Label3D.new()
var marks: Array[MeshInstance3D] = []

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park_point()

func reset() -> void:
	current = []
	current.resize(WIDTH)
	current.fill(false)
	for address in seeds:
		assert(address >= 0 and address < WIDTH)
		current[address] = true
	generation = 0
	history.clear()
	remember()
	redraw()

func answer(left: bool, self_cell: bool, right: bool) -> bool:
	var index := 4 * int(left) + 2 * int(self_cell) + int(right)
	return answers[index]

func evolve(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(old.size())
	for i in range(old.size()):
		var left := old[posmod(i - 1, old.size())]
		var right := old[posmod(i + 1, old.size())]
		next[i] = answer(left, old[i], right)
	return next

func step() -> void:
	current = evolve(current)
	generation += 1
	remember()
	redraw()

func remember() -> void:
	history.push_front(current.duplicate())
	if history.size() > ROWS:
		history.pop_back()

func _physics_process(_delta: float) -> void:
	if point.held():
		var x := to_local(point.global_position).x
		selected = clampi(int(floor((x / SPAN + 0.5) * WIDTH)), 0, WIDTH - 1)
	else:
		park_point()
	show_reading()

func park_point() -> void:
	point.position = Vector3(cell_x(selected), 1.15, 0.90)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		step()
		get_viewport().set_input_as_handled()

func cell_x(i: int) -> float:
	return ((i + 0.5) / WIDTH - 0.5) * SPAN

func make_display() -> void:
	tiles.transform_format = MultiMesh.TRANSFORM_3D
	tiles.use_colors = true
	tiles.instance_count = WIDTH * ROWS
	var cell := BoxMesh.new()
	cell.size = Vector3(SPAN / WIDTH * 0.94, 0.014, 1.2 / ROWS * 0.94)
	tiles.mesh = cell
	var board := MultiMeshInstance3D.new()
	board.multimesh = tiles
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	board.material_override = finish
	add_child(board)
	for row in range(ROWS):
		for col in range(WIDTH):
			var at := Vector3(cell_x(col), 0.95, -0.6 + (row + 0.5) * 1.2 / ROWS)
			tiles.set_instance_transform(row * WIDTH + col, Transform3D(Basis.IDENTITY, at))
	reading.position = Vector3(0, 1.42, -0.66)
	reading.font_size = 30
	reading.pixel_size = 0.0017
	reading.outline_size = 4
	add_child(reading)
	for j in range(3):
		var mark := MeshInstance3D.new()
		var edge := BoxMesh.new()
		edge.size = Vector3(SPAN / WIDTH * 0.94, 0.006, 0.006)
		mark.mesh = edge
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color = Color("ff80b4") if j == 1 else Color("ffd77d")
		mark.material_override = ink
		add_child(mark)
		marks.append(mark)

func redraw() -> void:
	tiles.visible_instance_count = history.size() * WIDTH
	for row in range(history.size()):
		for col in range(WIDTH):
			var ink := Color("87dca5") if history[row][col] else Color("243238")
			tiles.set_instance_color(row * WIDTH + col, ink)
	show_reading()

func show_reading() -> void:
	var left := posmod(selected - 1, WIDTH)
	var right := posmod(selected + 1, WIDTH)
	reading.text = "GEN %d / CELL %d\nLEFT %d   SELF %d   RIGHT %d\nMove point: inspect / trigger or Enter: STEP" % [generation, selected, int(current[left]), int(current[selected]), int(current[right])]
	for j in range(3):
		marks[j].position = Vector3(cell_x(posmod(selected + j - 1, WIDTH)), 0.963, -0.597)
```

## Carried `point_body.gd`

This is the earlier pickable sphere construction, reduced to an 8.5 cm radius for this desk. The finish and desktop hooks are supplied adapters. `held()` accepts an XR pickup or the museum's desktop grab; release leaves the reader parked at its selected cell. The point does not collide with or edit the automaton. The complete helper is here so no prior file is silently missing.

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

## Try a change and account for it

1. Keep the table unchanged. Set `seeds` to `[15, 16]`. Before running, write the addresses you predict will be active after one step. Run and compare. Explain one address where the two seeds meet.
2. Return to `[16]`. Reverse the traversal by replacing `for i in range(old.size()):` with `for i in range(old.size() - 1, -1, -1):`. Predict whether the next row will change. Test both versions from the same seed, keeping the original file.
3. Use `[0]` as the seed. Follow both sides of its first generation and explain where the boundary appears in the drawing.

Hold the point to inspect. Trigger or Enter advances the reconstruction once. Re-running or calling `reset()` restores the selected seed and clears its history. Unlike the installed explorer, this small study has no automatic RUN, rule slider or overhead receiver. The same eight-answer list can later receive a different interface.

Build and compare on desktop, then return to the installed exhibit for its full VR controls. Later compact studies name keyboard-only comparison controls explicitly. Reusing PointBody means retaining its construction and behaviour in your code; these listings do not transfer a live object or saved field automatically between halls.

Carry the row engine, its explicit boundary and its independent history. In the next hall we will change what a cell can hold and who counts as its neighbour. The rug and growing network remain encounters in the wider museum; we do not need to rebuild them to understand this step.

## Your own test

Choose another pair of seed addresses, away from the pair already tried. Predict their first combined row and test it. Keep the boundary and rule fixed. Keep your prediction, the observed values and a runnable assertion in a separate test script. If they disagree, identify whether the prediction, test or study needs changing.

