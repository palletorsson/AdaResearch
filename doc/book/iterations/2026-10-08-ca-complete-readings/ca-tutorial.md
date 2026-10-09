# Cellular Automata — complete tutorial

8 October 2026. All eight current canonical manuscripts, unabridged. Full code retained. Image paths and footnote identifiers are made portable; original sources are included.

## Contents

- [A row with neighbours](#CA_Introduction)
- [A state that lingers](#CA_ElementaryRules)
- [Keep a generation](#CA_GameOfLife)
- [A pattern visits an address](#CA_BeyondBinary)
- [The surface includes you](#CA_ExpandingSpace)
- [What a neighbour offers](#CA_SoftRules)
- [Two ways to make](#CA_AgentsCircuits)
- [What a difference keeps](#CA_EdgeOfChaos)


---

<a id="CA_Introduction"></a>

**01 / 08 · CA_Introduction**

## A row with neighbours

### Learning elements

- Binary cell state: `bool`.
- An ordered neighbourhood: left, self, right.
- A rule as eight stored answers.
- A synchronous update: read the old row, then replace it.
- A wrapped boundary.
- Current state and retained history.

### At the board

We are in Endless Museum. The explorer already works. Hold its small black point and move your hand sideways: three marks follow the selected address. The point reads the row; it does not turn a cell on. Press the trigger to advance one generation. The overhead ring receives the same stored rows.

Choose Rule 90 and a single seed. Pause before stepping. Pick a cell, read its left neighbour, itself and its right neighbour, and predict its next state from the table below. The museum's side plate can check your answer. Our smaller reconstruction leaves that prediction to you.

### What we carry

Trace gave us an array of positions; Grid gave those positions addresses. Arrays let us read and replace stored entries. Here each address holds a Boolean: `false` or `true`. The address stays; its state changes. We reuse the pickable sphere from the point lessons as a reader. Its hand position selects an address in the study's local frame.

Continue on your existing `PointStudy` node inside the museum, keeping its earlier script as a previous working version. Save both files below in one folder and attach `row.gd` to that node. Use unit scale. This builds a separate small experiment inside the museum. The camera, lighting, player and XR Tools are already present from Day Zero. No authored mesh, label or scene-child reference is required. Face the node's positive Z side; the board is 0.95 metres above its origin. Keep this experiment separate from the installed explorer while comparing them.

### Three inputs, eight answers

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

### Give every cell the same present

`evolve` allocates a separate `next` array. Its loop reads only `old`. The result replaces `current` after all addresses have received an answer. Writing directly into `old` would allow a freshly changed neighbour to affect a later calculation.

`posmod` supplies our boundary choice. With 32 cells, the left neighbour of cell 0 is cell 31; the right neighbour of 31 is 0. The calculation joins the ends even when we draw a straight row.

`remember` puts a copy of the current row at the front of `history`. This copy is an observation, not another neighbourhood. Twenty-four observations fit on the board. Older ones leave the display while the generation count continues. The newest row is at the far edge; earlier rows extend towards you. History's second dimension describes time, not a second spatial direction in the rule.

### Complete `row.gd`

The first half defines the state and its update. `make_display` supplies the repeated boxes, marks and label; `redraw` gives those boxes the stored states. Both are included so the experiment can be reconstructed. MultiMesh is display plumbing here, not another lesson to master before understanding the rule.

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

### Carried `point_body.gd`

This is the earlier pickable sphere construction, reduced to an 8.5 cm radius for this desk. The finish and desktop hooks are supplied adapters. `held()` accepts an XR pickup or the museum's desktop grab; release leaves the reader parked at its selected cell. The point does not collide with or edit the automaton. The complete helper is here so no prior file is silently missing.

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

### Try a change and account for it

1. Keep the table unchanged. Set `seeds` to `[15, 16]`. Before running, write the addresses you predict will be active after one step. Run and compare. Explain one address where the two seeds meet.
2. Return to `[16]`. Reverse the traversal by replacing `for i in range(old.size()):` with `for i in range(old.size() - 1, -1, -1):`. Predict whether the next row will change. Test both versions from the same seed, keeping the original file.
3. Use `[0]` as the seed. Follow both sides of its first generation and explain where the boundary appears in the drawing.

Hold the point to inspect. Trigger or Enter advances the reconstruction once. Re-running or calling `reset()` restores the selected seed and clears its history. Unlike the installed explorer, this small study has no automatic RUN, rule slider or overhead receiver. The same eight-answer list can later receive a different interface.

Carry the row engine, its explicit boundary and its independent history. In the next hall we will change what a cell can hold and who counts as its neighbour. The rug and growing network remain encounters in the wider museum; we do not need to rebuild them to understand this step.


---

<a id="CA_ElementaryRules"></a>

**02 / 08 · CA_ElementaryRules**

## A state that lingers

### Learning elements

- Three cell states: empty, active, fading.
- A three-dimensional address stored in one array.
- A neighbourhood of 26 positions; count only active cells.
- A transition function: the current state changes which answer is possible.
- A synchronous update and an empty outer boundary.
- State, visible surface and colour as separate decisions.

### Follow the cell

We are still in Endless Museum. The small volume and the enlarged neighbourhood show the same running calculation. Gold marks one address. Pick up the black point beside the console; its trigger advances one generation. You can carry the control while walking around a cube that hides another. The console's STEP does the same job.

Press REPLAY. The gold-framed centre begins active, with eleven active neighbours. STEP makes it green: fading. Now it has seven active neighbours. Predict its next state before stepping again. Does enough company make it active, or does its present state prevent that?

### What we carry

The last hall read an old row and wrote a separate next row. We keep that agreement, along with arrays, loops and the PointBody class. An integer now replaces each Boolean: `0` means empty, `1` active, `2` fading. One address still holds one value. A visible green cell holds a value that the active-neighbour count excludes.

The point now carries the step action. Moving it does not edit the cells or select a different address. We keep watching one centre, so its history can be followed without moving the question.

Continue on the existing `PointStudy` node in the museum, saving the row script as a previous working version. Put the two files below together and attach `volume.gd`. Keep the node at unit scale on level floor, with clear space around it; face its positive Z side. The museum already supplies camera, light, player and XR Tools. This construction supplies its own geometry, label and pickable point. No authored scene children are assumed.

Our study is a **7 × 7 × 7 volume with twelve deliberately placed active cells**. The installed work is a 50 × 50 × 50 seeded volume. They share the three-state rule and empty outer shell, but their beginnings and resulting shapes differ. We reconstruct the operation, then return to the larger encounter.

### Give a volume addresses

`index(p)` stores X positions next to each other. Moving one step in Y skips `SIZE` entries; one step in Z skips `SIZE * SIZE`. This is still one array. `Vector3i` keeps the address integer-valued; the drawn position uses metres separately.

The three nested loops in `active_neighbours` visit offsets −1, 0 and 1 on each axis: 27 combinations. Excluding `(0, 0, 0)` leaves 26 neighbours. Face, edge and corner neighbours each count once. Only entries equal to `1` count. This function is called for interior addresses, whose whole neighbourhood fits inside the array.

### One function chooses the next state

| Current state | Active neighbours | Next state |
|---|---|---|
| Empty, 0 | 6, 7 or 8 | Active, 1 |
| Empty, 0 | Any other count | Empty, 0 |
| Active, 1 | 6, 7 or 8 | Active, 1 |
| Active, 1 | Any other count | Fading, 2 |
| Fading, 2 | Any count | Empty, 0 |

`next_state` checks fading first. That is why a green cell with seven active neighbours empties. Moving the neighbour-count branch ahead of the fading branch would change the rule. The function assumes the three valid states listed above and a count from zero through twenty-six.

`evolve` creates a fresh, empty array and fills only its interior. It reads every answer from `old`, then `step` replaces `current`. The outer shell remains zero. Unlike the previous row, these edges do not wrap. Traversing the interior backwards should produce the same result.

### The complete construction — volume.gd

The update functions are the lesson. `make_display` builds its viewing apparatus; `redraw` reads the state without changing it. A gold frame holds the central address. Empty cells are hidden; pink and green cells remain visible. This small version draws all occupied cells, without the installed work's hidden-interior optimisation.

```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const SIZE := 7
const SPACING := 0.18
const CENTRE := Vector3i(3, 3, 3)
const COLOURS := [Color("53616b"), Color("df76b4"), Color("89d7a3")]
var current: Array[int] = []
var generation := 0
var point: XRToolsPickable
var reading := Label3D.new()
var cells := MultiMesh.new()

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park()

func index(p: Vector3i) -> int:
	return p.x + SIZE * p.y + SIZE * SIZE * p.z

func reset() -> void:
	current.resize(SIZE * SIZE * SIZE)
	current.fill(0)
	# Nine cells in a flat square; three more just above its middle row.
	for z in range(2, 5):
		for x in range(2, 5):
			current[index(Vector3i(x, 3, z))] = 1
	for x in range(2, 5):
		current[index(Vector3i(x, 4, 3))] = 1
	generation = 0
	redraw()

func active_neighbours(old: Array[int], p: Vector3i) -> int:
	var count := 0
	for z in range(-1, 2):
		for y in range(-1, 2):
			for x in range(-1, 2):
				var offset := Vector3i(x, y, z)
				if offset != Vector3i.ZERO and old[index(p + offset)] == 1:
					count += 1
	return count

func next_state(state: int, neighbours: int) -> int:
	if state == 2:
		return 0
	if neighbours >= 6 and neighbours <= 8:
		return 1
	if state == 1:
		return 2
	return 0

func evolve(old: Array[int]) -> Array[int]:
	var next: Array[int] = []
	next.resize(old.size())
	next.fill(0)
	# The outer shell stays empty; only interior addresses receive answers.
	for z in range(1, SIZE - 1):
		for y in range(1, SIZE - 1):
			for x in range(1, SIZE - 1):
				var p := Vector3i(x, y, z)
				next[index(p)] = next_state(old[index(p)], active_neighbours(old, p))
	return next

func step() -> void:
	current = evolve(current)
	generation += 1
	redraw()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0.8, 1.05, 0.65)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			reset()
			get_viewport().set_input_as_handled()

func make_display() -> void:
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = SIZE * SIZE * SIZE
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * SPACING * 0.65
	cells.mesh = cube
	var view := MultiMeshInstance3D.new()
	view.multimesh = cells
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.vertex_color_use_as_albedo = true
	view.material_override = finish
	add_child(view)
	reading.position = Vector3(0, 1.9, 0)
	reading.font_size = 30
	reading.pixel_size = 0.0015
	reading.outline_size = 4
	add_child(reading)
	# A gold address stays after the central cell disappears.
	for axis in range(3):
		for a in [-1, 1]:
			for b in [-1, 1]:
				var edge := MeshInstance3D.new()
				var bar := BoxMesh.new()
				bar.size = Vector3.ONE * 0.006
				bar.size[axis] = SPACING
				edge.mesh = bar
				edge.position = Vector3(0, 1.05, 0)
				edge.position[(axis + 1) % 3] += a * SPACING / 2
				edge.position[(axis + 2) % 3] += b * SPACING / 2
				var gold := StandardMaterial3D.new()
				gold.albedo_color = Color("ffd77d")
				edge.material_override = gold
				add_child(edge)

func redraw() -> void:
	for z in SIZE:
		for y in SIZE:
			for x in SIZE:
				var p := Vector3i(x, y, z)
				var i := index(p)
				var basis := Basis.IDENTITY if current[i] > 0 else Basis.IDENTITY.scaled(Vector3.ZERO)
				var at := Vector3(p - CENTRE) * SPACING + Vector3(0, 1.05, 0)
				cells.set_instance_transform(i, Transform3D(basis, at))
				cells.set_instance_color(i, COLOURS[current[i]])
	var words := ["EMPTY", "ACTIVE", "FADING"]
	reading.text = "GEN %d / CENTRE %s\n%d ACTIVE NEIGHBOURS\nHOLD POINT + TRIGGER: STEP\nENTER: STEP / R: REPLAY" % [generation, words[current[index(CENTRE)]], active_neighbours(current, CENTRE)]
```

### Carry the point — point_body.gd

This is the same small PointBody from the previous hall, unchanged. It contains the sphere and its pickup boundary. The new volume connects its existing action signal to `step`. Release returns the point to its resting place. With a keyboard, Enter steps and R replays the twelve-cell beginning.

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

### Try a change you can account for

Before running the script, predict the central cell's first two states. The twelve-cell beginning gives it eleven active neighbours at generation zero. Record your prediction, the observed states and the line that explains any difference. The readout always reports the current generation's neighbours, not the count used to produce that generation.

Then replace the twelve-cell beginning with just two adjacent active cells: the centre and one face neighbour. Predict two generations for the whole volume before running it. Keep the rule unchanged. Explain why a visible fading cell does not keep the other one active. This is your own seed, not a change to the museum installation.

Finally, ask the transition function for the next state of an empty cell with seven active neighbours and a fading cell with seven. Their counts match. Explain why their answers differ. A good test checks both cases; a successful screenshot alone does not establish that distinction.

### Return to the larger work

REPLAY returns the installed volume to its own seed. The chosen address `(26, 22, 24)` goes from active with eleven active neighbours, to fading with seven, to empty with five. Its surrounding cells keep evolving too. The gold frame keeps the question at the same address.

VIEW changes the colours without advancing a generation. DRAWN can be smaller than ACTIVE plus FADING because the installed renderer hides occupied cells enclosed on all six faces. That is a drawing decision; the state array still includes them. The six-face visibility test and the twenty-six-neighbour update answer different questions.

RUN, the twenty-step budget and the height-colour view belong to the installed observation apparatus. Our reconstruction needs only a step and a replay. Keep them distinct from the rule you have just written.

Carry onward a transition function that distinguishes presence from participation, and an update that gives every cell the same old world. In **CA_GameOfLife**, a retained generation will become a layer of a structure. Here we replace the array; there we will also keep a history we can approach.


---

<a id="CA_GameOfLife"></a>

**03 / 08 · CA_GameOfLife**

## Keep a generation

### Learning elements

- A history made from independent array snapshots.
- Generation and site as different indices.
- One record mapped to two arrangements.
- Visible geometry and collision as separate responsibilities.
- Reading an earlier state without reversing the calculation.
- A fixed record budget and an explicit restart.

### Walk beside the record

We are in Endless Museum. The desk, the tiles in the basin and the upright lattice show the same Rule 30 history. Twelve rows greet you. Walk along the margin: gold follows your position through the record. Turn back. The later rows remain.

Return to the desk and press REPLAY, then STEP. A single occupied site becomes three. This is the row rule from the opening hall. The previous room expanded the neighbourhood into a three-state volume; here we return to the simpler row to investigate **what happens when its past is kept**. The map's historical name, CA_GameOfLife, does not name this rule. Conway's Life is the next hall's main lesson.

### Continue with the point

We carry arrays, loops, an old-to-next update and the small PointBody. Save the previous lesson's script, then attach `history.gd` to the existing `PointStudy` Node3D in the museum. Keep unit scale, place it on level floor with about 2 × 2 metres clear, and face its positive Z side. Put the unchanged `point_body.gd` beside it. The museum supplies the camera, lighting, player and XR Tools; these files create the study itself.

This is a small comparison you can walk around. One saved row becomes a horizontal band and a vertical strip. Move the held point along Z to select an existing generation. Trigger, or Enter, appends a new row. R restarts. Release parks the point at the selected row. In the installed basin your body selects the row; in this reconstruction your familiar point is the reader. The small tiles are not a replacement floor course.

![The complete printed study temporarily running in the museum: a held point reads the same generation across horizontal tiles and a vertical screen.](assets/CA_GameOfLife/history-learner.png)

*The code below after eleven steps. Gold reads generation three; all twelve saved rows remain.*

### Save an independent row

`current` is the latest state. `history[g]` is a saved generation; `history[g][x]` reads one site in it. We append in time order: generation zero stays at index zero. This differs from a display that keeps only its newest rows and discards old ones.

`current.duplicate()` gives the record its own row. These entries are Boolean values, so a shallow copy is sufficient. Appending `current` alone would share that array: a later in-place edit could alter the supposed snapshot. A history of nested objects would need a more specific copying agreement.

`next_row` still reads only the old row while writing a fresh one. Left, centre and right make an index from 0 to 7. `ANSWERS` stores Rule 30 in that ascending order, 000 to 111. Left and right wrap at the row's ends. We have not added a new automaton.

The record holds 24 generations, including the seed. At capacity STEP returns without changing it. REPLAY clears the record and begins again from `seeds`. There is no claim of unlimited memory.

### Give the record two uses

In `deck_position`, site X stays horizontal. In `screen_position`, the same site rises vertically. Generation G becomes depth Z in both. A gold marker shows the selected generation, but it contributes no support.

`redraw` reads the record. It does not evolve it. A recorded true cell shows a cube in each view. The horizontal cube also enables its matching collision shape; the upright cube has no collision. Each cell has a reserved instance, indexed by `g * WIDTH + x`. A zero-sized basis hides inactive instances. `set_deferred` changes collision after the current physics work finishes.

An unoccupied recorded cell and an unrecorded future slot both show no cube. The label distinguishes them: it reports the recorded range and refuses a selection outside it. The installed desk makes this distinction with different dark tones as well.

### Complete study — history.gd

The two mapping functions are the part to change in your own arrangement. `make_display` builds the repeated geometry and collision pool once. `redraw` updates those existing receivers. There are no required scene children hidden behind references.

```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const WIDTH := 15
const ROWS := 24
const CELL := 0.08
const ANSWERS := [false, true, true, true, true, false, false, false]
var seeds: Array[int] = [7]
var current: Array[bool] = []
var history: Array[Array] = []
var selected := 0
var point: XRToolsPickable
var reading := Label3D.new()
var deck := MultiMesh.new()
var screen := MultiMesh.new()
var shapes: Array[CollisionShape3D] = []
var deck_mark: MeshInstance3D
var screen_mark: MeshInstance3D

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	replay()
	park()

func replay() -> void:
	current.resize(WIDTH)
	current.fill(false)
	for x in seeds:
		assert(x >= 0 and x < WIDTH)
		current[x] = true
	history.clear()
	history.append(current.duplicate())
	selected = 0
	redraw()

func next_row(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(WIDTH)
	for x in WIDTH:
		var left := old[posmod(x - 1, WIDTH)]
		var self_cell := old[x]
		var right := old[posmod(x + 1, WIDTH)]
		next[x] = ANSWERS[4 * int(left) + 2 * int(self_cell) + int(right)]
	return next

func step() -> void:
	if history.size() == ROWS:
		return
	current = next_row(current)
	history.append(current.duplicate())
	selected = history.size() - 1
	redraw()

func select_row(g: int) -> void:
	if g < 0 or g >= history.size():
		return
	selected = g
	deck_mark.position.z = g * CELL
	screen_mark.position.z = g * CELL
	reading.text = "RULE 30 / GEN 0..%d / READ %d\nMOVE POINT ALONG Z: READ HISTORY\nTRIGGER OR ENTER: STEP / R: REPLAY" % [history.size() - 1, selected]

func _physics_process(_delta: float) -> void:
	if point.held():
		var p := to_local(point.global_position)
		select_row(floori(p.z / CELL + 0.5))
	else:
		park()

func park() -> void:
	point.position = Vector3(-0.85, 1.05, selected * CELL)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			replay()
			get_viewport().set_input_as_handled()

func deck_position(x: int, g: int) -> Vector3:
	return Vector3((x - 7) * CELL, 1.0, g * CELL)

func screen_position(x: int, g: int) -> Vector3:
	return Vector3(0.85, 1.05 + x * 0.055, g * CELL)

func make_view(mm: MultiMesh, size: Vector3) -> void:
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = WIDTH * ROWS
	var cube := BoxMesh.new()
	cube.size = size
	mm.mesh = cube
	var view := MultiMeshInstance3D.new()
	view.multimesh = mm
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.vertex_color_use_as_albedo = true
	view.material_override = finish
	add_child(view)

func marker(size: Vector3, at: Vector3) -> MeshInstance3D:
	var mark := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mark.mesh = cube
	mark.position = at
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffcc72")
	mark.material_override = gold
	add_child(mark)
	return mark

func make_display() -> void:
	make_view(deck, Vector3(CELL, 0.022, CELL))
	make_view(screen, Vector3(0.014, 0.05, CELL * 0.9))
	var support := StaticBody3D.new()
	add_child(support)
	var tile := BoxShape3D.new()
	tile.size = Vector3(CELL, 0.022, CELL)
	for g in ROWS:
		for x in WIDTH:
			var shape := CollisionShape3D.new()
			shape.shape = tile
			shape.position = deck_position(x, g)
			shape.disabled = true
			support.add_child(shape)
			shapes.append(shape)
	deck_mark = marker(Vector3(1.4, 0.008, 0.012), Vector3(0, 1.018, 0))
	screen_mark = marker(Vector3(0.025, 0.86, 0.012), Vector3(0.85, 1.435, 0))
	reading.position = Vector3(0, 2.1, 0.9)
	reading.font_size = 30
	reading.pixel_size = 0.0015
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for g in ROWS:
		for x in WIDTH:
			var i := g * WIDTH + x
			var occupied: bool = g < history.size() and history[g][x]
			var basis := Basis.IDENTITY if occupied else Basis.IDENTITY.scaled(Vector3.ZERO)
			var colour := Color("78d9bd").lerp(Color("e2a4de"), float(g) / (ROWS - 1))
			deck.set_instance_transform(i, Transform3D(basis, deck_position(x, g)))
			screen.set_instance_transform(i, Transform3D(basis, screen_position(x, g)))
			deck.set_instance_color(i, colour)
			screen.set_instance_color(i, colour)
			shapes[i].set_deferred("disabled", not occupied)
	select_row(selected)
```

### Carried file — point_body.gd

This is the same point as in the previous two halls. Its construction is printed here so the pair of files is complete; you do not need to rebuild or redesign it. The inherited pickable action supplies the trigger signal.

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

### Read without rewriting

Make six rows. Hold the point and move it back toward generation one. Both gold marks return there. STEP still calculates from the latest `current`, not from the selected row. Selection changes the reading; it does not fork the history. While held, your point's position continues to select the row under your hand after a step.

In the large installation, walking back also leaves the update clock alone. Its manual ROW button pauses RUN; walking does not. That distinction belongs to the controls, not to Rule 30.

### Make another beginning

Change `seeds` from `[7]` to `[5, 9]`, then run the study. Predict the first new row: sites 4, 5, 6, 8, 9 and 10 should appear. Confirm it in both views. Keep that history and change the screen's mapping to `1.05 + (WIDTH - 1 - x) * 0.055`. The wall reading flips vertically; the horizontal tiles, saved rows and future calculation should stay the same. Explain why.

### What travels onward

We can keep a state without confusing it with the current calculation, and change its display without changing the record. Next, a two-dimensional grid holds one present. A glider will seem to move through it while the addressed cells remain in place. A pattern's apparent movement and our stored history are different constructions.


---

<a id="CA_BeyondBinary"></a>

**04 / 08 · CA_BeyondBinary**

## A pattern visits an address

### Learning elements

- A two-dimensional present: X and Y are sites, not generations.
- Eight surrounding neighbours; exclude the centre.
- Birth and survival: B3/S23.
- Fixed address, changing occupancy, apparent movement.
- A separate output: one cell controls one lamp.

### Enter with the point

The last hall kept each new row as history. Here both grid directions belong to the **same present**. Five cells wait in a dish, repeated on the floor. Press STEP four times. The arrangement returns one address farther along both directions. No mesh has moved. Different fixed cells have become occupied.

Take the small black point beside the controls. Carry it to a gold square on the floor and use its trigger to STEP. Follow the address while the pattern passes. The point carries the control; its position does not write into the automaton. REPLAY returns to the beginning. The floor remains solid whether a cell is empty or occupied.

We will reconstruct this relationship at table scale: the same 24 × 24 rule and beginning, one marked address, one lamp and the familiar PointBody. The installation has three lamps, RUN, TRACE and preset buttons. The compact study uses one lamp and manual steps. Those other controls are not needed to understand this operation.

Save the previous lesson. Attach `life.gd` to your existing `PointStudy` Node3D in the museum; keep unit scale and about 3 × 3 metres clear. Face its positive Z side. Keep the unchanged `point_body.gd` beside it. The established museum provides camera, light, player and XR Tools. These two files create all of the study's geometry and behaviour; no prepared child nodes are required.

### Count the surroundings

`current` holds 576 Boolean values. `index(x, y)` finds one address in that flat array. Both coordinates wrap at the boundaries. Logical Y becomes depth Z in `cell_position`; the table's physical height stays fixed. Unlike the previous lesson, stepping does not add a row behind the others.

`neighbours` reads a 3 × 3 patch. The condition `dx != 0 or dy != 0` excludes only its centre, leaving eight neighbours. Their count, together with the centre's old state, selects the answer:

| Current cell | Occupied neighbours | Next cell |
| --- | --- | --- |
| Empty | Exactly 3 | Occupied: birth |
| Occupied | 2 or 3 | Occupied: survival |
| Either | Any other count for that state | Empty |

This is Conway's Game of Life, written B3/S23. `evolve` uses the buffer agreement we already know: read every neighbourhood from `old`, write every answer into a new array, then replace `current`. Reading the answers you have just written would produce a different process, dependent on loop order.

### Connect an address

`SITE` is (10,10). Its gold frame stays in place. `redraw` colours the existing cell instances and passes this site's value to `receive`. That function changes the lamp and its globe. It cannot change the next state of any cell.

Press L while the lamp is lit. The connection is off, so the lamp goes dark. STEP still evolves the cells. Press L again: the lamp reads the current value immediately, without advancing time. REPLAY resets the beginning and generation counter, but preserves your link setting.

We separate a rule from a use of its answer. The same false value that removed support in the previous hall now makes a dark patch on a solid table. `make_display` builds that support once; `redraw` never removes it.

### Complete study — life.gd

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

### Carried file — point_body.gd

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

### Follow what stays

Use the held trigger or Enter to step. After four generations, the glider has the seed's arrangement shifted by (1,1). At generation eight, A is occupied and its linked lamp is lit. At generation twelve, A is empty again. Each tile's position stayed fixed throughout. R replays; the forty-eight-step limit holds the last state.

### Make another beginning

Replace `seeds` with three positions: (9,10), (10,10), (11,10). Predict the first answer before running: a vertical line at (10,9), (10,10), (10,11). Step again to recover the horizontal line. The centre survives both phases, so A's lamp stays lit. Disconnect the lamp and repeat. Explain why the cells still alternate.

Now connect a different address by changing `SITE` to (9,10). The frame, wire and lamp reading move together. The same blinker should make this lamp alternate. The rule and the cell record do not need to change. You have changed which state the room receives.

### What travels onward

A pattern can travel while its addressed receivers stay put. A Boolean rule can answer a separate object without accepting any influence back from it. In the next hall, proximity becomes an input: the observer's body will enter the conditions of the update.


---

<a id="CA_ExpandingSpace"></a>

**05 / 08 · CA_ExpandingSpace**

## The surface includes you

### Learning elements

- An external position becomes input to a cellular rule.
- A dictionary pairs each grid address with a fractional state.
- Four axial neighbours and a bounded field.
- Separate thresholds for recovery and physical support.
- Snapshot updates compared with a directional scan.

### Bring the same point

In the previous hall, carrying the point changed nothing in the cells. It carried STEP. Here **where you hold it matters**. The bridge and its wall frieze show the same field. Take the black point beside the desk, bring it near a tile and press its trigger. Each press selects HAND and advances one tenth of a simulated second. A nearby tile loses health. Release the point and STEP again: recovery now depends on what remains around the tile.

Try the installed bridge first. Its desk also offers a fixed PROBE and the actual VISITOR as input, RUN for repeated steps, and a full RESTORE. The gold address W appears on both floor and wall. Below 0.2, its floor tile loses collision support. The basin catches you; the ramps return you to the museum floor. A wall panel can show the same value without opening a hole in the wall.

We reconstruct this operation at one-fifth scale, with the same PointBody and rule. Save the previous lesson. Attach `presence.gd` to your existing `PointStudy` Node3D in the museum. Keep unit scale, about 2 × 3 metres clear, and face its positive Z side. Place the unchanged `point_body.gd` beside it. Day Zero's museum still supplies the player, camera, light and XR Tools. These two files create all study geometry; no prepared child nodes are needed. The small model has manual steps, one point input and a tray beneath its tiles. Walk on the installed bridge, not this table.

### An address keeps a fraction

`current[Vector2i(x, y)]` holds a number from 0 to 1. The dictionary makes the address explicit; it replaces the flat Boolean array used in Life. All 80 addresses exist throughout the experiment. A disappearing tile does not delete its entry.

Logical Y runs along the bridge, becoming physical Z in `cell_position`. `view_position` shrinks that simulation position and places it on the table. `input_position` reverses the conversion: world position → study-local position → simulation position. This lets the smaller model use the installed rule's distances. Moving or rotating the entire study does not alter those local relations.

The radius is 1.35 simulation metres, which appears as 0.27 metres on this model. Distance uses all three coordinates, including height. The input is the held point's centre. In the installed VISITOR mode it is the tracked body's origin. Neither measures weight or contact pressure.

### One update

For each address, `evolve` makes one choice. If the point is held and its centre is nearer than `RADIUS`, health falls by 0.04. Otherwise each healthy axial neighbour adds 0.01. The four directions are north, south, east and west; diagonals and the centre are excluded. Missing neighbours at the boundary contribute nothing. This field does not wrap as Life did.

`maxf` and `minf` keep the result between 0 and 1. Near the input, decay takes the whole branch: recovery is not added at the same time. Moving the point while the clock is stopped changes no cell. Trigger or Enter commits one update.

| Health | Helps neighbours recover? | Tile supports a body? |
| --- | --- | --- |
| Greater than 0.5 | Yes | Yes |
| 0.2 through 0.5 | No | Yes |
| Below 0.2 | No | No |

`redraw` uses the new value to change colour and collision. Each wall panel shares its floor tile's material. The wall backing and lower tray stay solid. Changing a state and deciding what that state permits remain separate operations.

### Complete study — presence.gd

Read `input_position`, `neighbours`, `evolve` and `step` first. They contain the new operation. `make_display` builds the two views and their support; it is included so the reconstruction is complete. There is one `_ready`, and every reference is created or declared here.

```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const WIDTH := 5
const LENGTH := 16
const PITCH := 0.6
const RADIUS := 1.35
const DT := 0.1
const LIMIT := 300
const VIEW_SCALE := 0.2
const VIEW_ORIGIN := Vector3(0, 1.02, 0)
const W := Vector2i(2, 6)
const DIRECTIONS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
var current: Dictionary = {}
var materials: Dictionary = {}
var supports: Dictionary = {}
var point: XRToolsPickable
var reading := Label3D.new()
var ticks := 0
var chain := false
var synchronous := true
var backwards := false

func _ready() -> void:
	for y in LENGTH:
		for x in WIDTH:
			current[Vector2i(x, y)] = 1.0
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	park()
	reset()

func cell_position(site: Vector2i) -> Vector3:
	return Vector3((site.x - 2) * PITCH, -0.1, site.y * PITCH)

func view_position(site: Vector2i) -> Vector3:
	return VIEW_ORIGIN + cell_position(site) * VIEW_SCALE

func input_position() -> Vector3:
	return (to_local(point.global_position) - VIEW_ORIGIN) / VIEW_SCALE

func neighbours(old: Dictionary, site: Vector2i) -> int:
	var count := 0
	for direction in DIRECTIONS:
		var other: Vector2i = site + direction
		if old.has(other) and old[other] > 0.5:
			count += 1
	return count

func evolve(old: Dictionary, at: Vector3, present: bool) -> Dictionary:
	var next := old.duplicate()
	var read: Dictionary = old if synchronous else next
	var order := old.keys()
	if backwards:
		order.reverse()
	for site: Vector2i in order:
		var health: float = old[site]
		if present and cell_position(site).distance_to(at) < RADIUS:
			next[site] = maxf(0.0, health - 0.08 * DT * 5.0)
		else:
			next[site] = minf(1.0, health + 1.0 * DT * 0.1 * neighbours(read, site))
	return next

func step() -> void:
	if ticks == LIMIT:
		return
	current = evolve(current, input_position(), point.held() and not chain)
	ticks += 1
	redraw()

func reset() -> void:
	ticks = 0
	for site in current:
		current[site] = 0.0 if chain else 1.0
	if chain:
		current[Vector2i(1, 6)] = 0.6
		current[W] = 0.495
	redraw()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(-0.65, 1.12, 0.3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: chain = false; reset()
			KEY_C: chain = true; reset()
			KEY_O: synchronous = not synchronous; reset()
			KEY_V: backwards = not backwards; reset()
			_: return
		get_viewport().set_input_as_handled()

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

func solid(node: MeshInstance3D, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	boundary.shape = shape
	node.add_child(body)
	body.add_child(boundary)
	return boundary

func make_display() -> void:
	var tray := box(Vector3(0.72, 0.04, 2.0), Vector3(0, 0.86, 0.9), Color("354650"))
	solid(tray, Vector3(0.72, 0.04, 2.0))
	box(Vector3(0.1, 0.84, 0.1), Vector3(0, 0.42, 0.9), Color("bf9469"))
	var wall := box(Vector3(0.04, 0.38, 2), Vector3(0.55, 1.28, 0.9), Color("20373a"))
	solid(wall, Vector3(0.04, 0.38, 2))
	for site: Vector2i in current:
		var tile := box(Vector3(0.114, 0.04, 0.114), view_position(site), Color.WHITE)
		materials[site] = tile.material_override
		supports[site] = solid(tile, Vector3(0.12, 0.04, 0.12))
		var panel := box(Vector3(0.02, 0.058, 0.106), Vector3(0.52, 1.15 + site.x * 0.064, site.y * 0.12), Color.WHITE)
		panel.material_override = materials[site]
	var at := view_position(W) + Vector3.UP * 0.025
	for side in [-1, 1]:
		box(Vector3(0.124, 0.008, 0.008), at + Vector3(0, 0, side * 0.062), Color("ffd484"))
		box(Vector3(0.008, 0.008, 0.124), at + Vector3(side * 0.062, 0, 0), Color("ffd484"))
	reading.position = Vector3(0, 1.8, 0.6)
	reading.font_size = 28
	reading.pixel_size = 0.0014
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for site: Vector2i in current:
		var health: float = current[site]
		var finish: StandardMaterial3D = materials[site]
		finish.albedo_color = Color("a86c88").lerp(Color("8cd9be"), health)
		finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if health < 0.2 else BaseMaterial3D.TRANSPARENCY_DISABLED
		finish.albedo_color.a = 0.18 + health if health < 0.2 else 1.0
		supports[site].set_deferred("disabled", health < 0.2)
	reading.text = "W (2,6) / HEALTH %.3f / SUPPORT %s\n%s / %s / %.1f s\nTRIGGER / ENTER: STEP   R: FULL   C: CHAIN\nO: SYNC/SCAN   V: REVERSE" % [current[W], "ON" if current[W] >= 0.2 else "OFF", "SYNC" if synchronous else "SCAN", "REVERSE" if backwards else "FORWARD", ticks * DT]
```

### Unchanged carried object — point_body.gd

This is the same PointBody file used in the previous hall. It keeps its small dark sphere, pickup behaviour and action signal. Copy it only if it is not already beside the new script.

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

### Let the edge recover

Hold the point's centre about 0.05 metres above W and STEP 21 times without moving it. The value reaches 0.16; the faint tile no longer supplies support. Release the point. Each later Enter press advances recovery without a proximity input. The outer edge of the depleted patch recovers first because it still has healthy neighbours. A wholly empty field has none and will not repair itself merely because you leave.

Now hold the point directly above W but more than 0.27 metres from its centre. Predict the next update before pressing. Height alone can take it outside the radius. Lower it and repeat. You are testing a three-dimensional distance, not painting onto a two-dimensional grid. Desktop learners can use the museum's established grab operation and Enter while holding the point.

### Does the order count?

This comparison returns to the old-to-next agreement; it does not add another input. Press C. The field begins at zero except (1,6) = 0.600 and W = 0.495. Hand influence is disabled for this comparison. In SYNC, all recovery counts read `old`. STEP once: W becomes 0.505, but (3,6) remains zero because it read W's old value.

Press O to select SCAN and reset that same beginning. Now counts read `next`, including answers already written. STEP: (3,6) becomes 0.01. W's newly healthy value was available before the loop reached its neighbour. Press V to reverse the scan and reset; STEP again. That neighbour now stays at zero. SYNC gives the same answer in either order.

Make one independent edit: change W's CHAIN beginning from 0.495 to **0.49**. Predict whether the third cell gains anything in forward SCAN, then run it. W reaches exactly 0.5. The condition is strictly greater than 0.5, so the third cell still gains nothing. The threshold, not the rounded appearance of the colour, decides.

R restores the full field and permits hand input again. O and V preserve the chosen beginning while resetting time. At 300 steps—30 simulated seconds—the study holds its state until reset. Releasing the point does not advance time by itself.

### Try a route before explaining it

Return to the installed bridge. RESTORE, choose VISITOR, keep SYNC, and start RUN. Pick a route towards the far end. Pause somewhere because you want to look, then respond to what happens beneath you. The basin and ramps are part of this encounter. If a changed tile alters where you go next, that new position becomes another input. Your movement connects the cellular update to the museum's collision and locomotion systems.

Keep a brief account of one attempt: your intended route, where it changed, and what you did next. A second attempt need not improve the crossing; it might pursue something you noticed on the first. Afterwards, choose one event to examine with the step controls. Continuous play and a controlled comparison can ask different questions of the same work. The compact table remains a hand experiment; it is not the walkable bridge.

You leave with an input connection you can name, and two consequences you can distinguish: a value can cease to help its neighbours before it ceases to hold you. The next room asks what happens when the neighbourhood offers more than a count above a threshold.


---

<a id="CA_SoftRules"></a>

**06 / 08 · CA_SoftRules**

## What a neighbour offers

### Learning elements

- Two fractional values at each address: U and V.
- A neighbour contributes a difference, rather than a count above a threshold.
- A small model class keeps state separate from its display.
- Matched beginnings isolate one changed operation.
- The carried point chooses an address for a shared intervention.

### Bring the point to the tables

In the previous room a healthy neighbour contributed to recovery. Here **how much it differs matters**. Two tables begin with the same square. Each table's field also covers a curved wall. A exchanges with its neighbours; B starts with exchange off. Both still perform the same local reaction.

Find W, the gold address just beside the starting square. At the side desk, press STEP. A receives a little V at W; B receives none. Press +100 to see that small difference develop. EXCHANGE B enables the missing operation and restores both beginnings. Step again: they now agree.

Take the black point beside the desk. Hold its centre just above either table and use its trigger. You plant the same small patch at the corresponding address in both fields. Moving the point without triggering does nothing. Release returns it to its shelf; use the desk to advance time. The floor crossing and INJECT offer a fixed patch instead. These are interventions in a running field, not a different rule.

### Reconstruct the comparison

Save the previous study. Put `field.gd`, `exchange.gd` and the unchanged `point_body.gd` together. Attach `exchange.gd` to the existing `PointStudy` Node3D in your Day Zero museum. Keep unit scale and about 3.3 × 2.4 metres clear, facing its positive Z side. The museum supplies the player, camera, lighting and XR Tools. These files create every child used by this study.

The compact reconstruction has two tables and two flat upright displays. The installed walls are larger and curved; they use the same operation. Use Enter for one step, Space for 100, E to change B's exchange and restart both fields, R to replay, and V to view U or V. In VR the point's trigger plants a seed. The compact model's clock and comparison controls use the keyboard; the installed exhibit has nearby VR desk controls. Desktop learners use the museum's pickup and I while holding the point.

### A field stores two values

`Field` is a small class extending `RefCounted`. Each instance owns two arrays, one for U and one for V. It needs no position or mesh because its job is calculation. `left` and `right` are separate instances, not two names for the same arrays.

The grid has 32 × 32 addresses. `index(x, y)` turns two coordinates into one array index. `posmod` wraps either coordinate to 0–31: the neighbour left of x = 0 is x = 31. This periodic boundary differs from the bounded bridge in the previous hall. The starting 6 × 6 square holds U = 0.5 and V = 0.25; elsewhere U = 1 and V = 0.

### Receive a difference

`laplacian` adds the four axial neighbours and subtracts four copies of the centre. Equivalently, it adds four neighbour-minus-centre differences. A uniform field gives zero. A higher neighbour contributes positively; lower neighbours contribute negatively. The centre is not an extra fifth neighbour.

The supplied Gray–Scott reaction in `next_pair` uses U × V × V to remove U and add V. Feed replenishes U; feed plus kill removes V. Exchange adds 0.16 times U's neighbour difference and 0.08 times V's. B can set just that exchange contribution to zero. `clampf` bounds both results to 0–1. The lesson uses this fixed reaction to compare exchange; deriving the chemical model and choosing a stable numerical scheme are later work.

One call is one numerical step with dt = 1, not one second of real time. `step` reads only the old arrays, writes both answers into new arrays, then replaces the old state. This keeps the simultaneous-update agreement from the earlier halls. A fresh pair of arrays makes that agreement visible; the larger installation reuses its spare buffers.

W is (12,15), just outside the square. Its U neighbours sum to 3.5 and its V neighbours to 0.25. Its own U = 1 and V = 0, so the reaction contributes nothing there. After one step:

| Field | U at W | V at W |
| --- | --- | --- |
| A, exchange on | 0.92 | 0.02 |
| B, exchange off | 1.00 | 0.00 |

That first difference is small enough to predict before watching it spread.

### Complete model — field.gd

```gdscript
extends RefCounted
const N := 32
const FEED := 0.037
const KILL := 0.060
var u := PackedFloat32Array()
var v := PackedFloat32Array()
var exchange := true
var ticks := 0

func _init() -> void:
	u.resize(N * N)
	v.resize(N * N)
	reset()

func index(x: int, y: int) -> int:
	return posmod(y, N) * N + posmod(x, N)

func reset() -> void:
	u.fill(1.0)
	v.fill(0.0)
	ticks = 0
	for y in range(13, 19):
		for x in range(13, 19):
			u[index(x, y)] = 0.5
			v[index(x, y)] = 0.25

func seed_at(site: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			u[index(site.x + dx, site.y + dy)] = 0.5
			v[index(site.x + dx, site.y + dy)] = 0.25

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
	return values[index(x - 1, y)] + values[index(x + 1, y)] + values[index(x, y - 1)] + values[index(x, y + 1)] - 4.0 * values[index(x, y)]

func next_pair(a: float, b: float, lap_u: float, lap_v: float) -> Vector2:
	# Supplied Gray–Scott model. One numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var uvv := a * b * b
	return Vector2(
		clampf(a + coupling * 0.16 * lap_u - uvv + FEED * (1.0 - a), 0.0, 1.0),
		clampf(b + coupling * 0.08 * lap_v + uvv - (KILL + FEED) * b, 0.0, 1.0)
	)

func step() -> void:
	var next_u := PackedFloat32Array()
	var next_v := PackedFloat32Array()
	next_u.resize(N * N)
	next_v.resize(N * N)
	for y in N:
		for x in N:
			var i := index(x, y)
			var answer := next_pair(u[i], v[i], laplacian(u, x, y), laplacian(v, x, y))
			next_u[i] = answer.x
			next_v[i] = answer.y
	u = next_u
	v = next_v
	ticks += 1
```

### A position becomes an address

The point keeps its pickup behaviour. `target_site` converts its world position into the study's local space, checks whether it is near either tabletop, and divides its offset into 0.04-metre cells. Logical grid Y becomes tabletop Z. An invalid target returns (-1,-1), so an unheld point or a trigger away from the tables plants nothing.

`seed_at` replaces a 3 × 3 patch with U = 0.5, V = 0.25. It does not add concentrations and does not advance the clock. Both fields receive the same intervention, but can retain different histories elsewhere. R restores the original square. E changes B's exchange and resets both histories for a fair comparison; R alone keeps that choice.

`paint` reads state without changing it. Each table and its upright display share one texture. The initial palette maps V × 2 into colour, clamped at one; U has another palette. V changes the view, not the simulation. A saturated colour need not mean a stored concentration of one. These surfaces are pictures of the field; the tables keep their physical support.

### Complete study — exchange.gd

Read `target_site`, `plant`, `advance` and `paint` first. `box` and `make_display` provide the complete staging. There is one `_ready`, and no required child is hidden in a scene reference.

```gdscript
extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const LIMIT := 2400
const W := Vector2i(12, 15)
var left := Field.new()
var right := Field.new()
var point: XRToolsPickable
var reading := Label3D.new()
var textures: Array[ImageTexture] = []
var show_u := false
var injections := 0

func _ready() -> void:
	right.exchange = false
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): plant())
	park()
	reset()

func reset() -> void:
	left.reset()
	right.reset()
	injections = 0
	paint()

func advance(count: int) -> void:
	for i in mini(count, LIMIT - left.ticks):
		left.step()
		right.step()
	paint()

func change_exchange() -> void:
	right.exchange = not right.exchange
	reset()

func target_site() -> Vector2i:
	if not point.held():
		return Vector2i(-1, -1)
	var at := to_local(point.global_position)
	for cx in [0.85, -0.85]:
		if absf(at.x - cx) < 0.64 and absf(at.z - 0.5) < 0.64 and absf(at.y - 1.01) < 0.35:
			return Vector2i(floori((at.x - cx + 0.64) / 0.04), floori((at.z - 0.5 + 0.64) / 0.04))
	return Vector2i(-1, -1)

func plant() -> void:
	var site := target_site()
	if site.x < 0:
		return
	left.seed_at(site)
	right.seed_at(site)
	injections += 1
	paint()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0, 1.12, -0.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: advance(1)
			KEY_SPACE: advance(100)
			KEY_R: reset()
			KEY_E: change_exchange()
			KEY_V: show_u = not show_u; paint()
			KEY_I: plant()
			_: return
		get_viewport().set_input_as_handled()

func tint(value: float) -> Color:
	if show_u:
		return Color("241e46").lerp(Color("bce8bc"), value)
	return Color("122d3d").lerp(Color("edb1cb"), clampf(value * 2.0, 0.0, 1.0))

func paint() -> void:
	for side in 2:
		var field = left if side == 0 else right
		var data: PackedFloat32Array = field.u if show_u else field.v
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				image.set_pixel(x, y, tint(data[y * 32 + x]))
		textures[side].update(image)
	var i := left.index(W.x, W.y)
	reading.text = "TICK %d / W (12,15)\nA: U %.3f  V %.3f\nB: U %.3f  V %.3f\nB EXCHANGE %s / VIEW %s / SEEDS %d\nENTER: STEP   SPACE: +100   R: REPLAY\nE: EXCHANGE B   V: VIEW   TRIGGER / I: PLANT" % [left.ticks, left.u[i], left.v[i], right.u[i], right.v[i], "ON" if right.exchange else "OFF", "U" if show_u else "V x2", injections]

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("263744")
	node.material_override = material
	add_child(node)
	return node

func make_display() -> void:
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
		var title := Label3D.new()
		title.text = "A" if side == 0 else "B"
		title.position = Vector3(cx, 2.42, -0.4)
		title.font_size = 52
		title.pixel_size = 0.0015
		add_child(title)
		var finish := StandardMaterial3D.new()
		finish.albedo_texture = texture
		finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		var table := box(Vector3(1.36, 0.08, 1.36), Vector3(cx, 0.96, 0.5))
		box(Vector3(0.5, 0.92, 0.5), Vector3(cx, 0.46, 0.5))
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.36, 0.08, 1.36)
		boundary.shape = shape
		table.add_child(body)
		body.add_child(boundary)
		for wall in [false, true]:
			var display := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(1.28, 1.28)
			display.mesh = plane
			display.material_override = finish
			display.position = Vector3(cx, 1.7, -0.4) if wall else Vector3(cx, 1.01, 0.5)
			if wall:
				display.rotation.x = PI / 2.0
			add_child(display)
		var mark := box(Vector3(0.038, 0.004, 0.038), Vector3(cx + (W.x + 0.5 - 16) * 0.04, 1.014, 0.5 + (W.y + 0.5 - 16) * 0.04))
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color("ffe49a")
		gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gold.albedo_color.a = 0.3
		mark.material_override = gold
	reading.position = Vector3(0, 2.65, 0.5)
	reading.font_size = 30
	reading.pixel_size = 0.0013
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	add_child(reading)
```

### The same carried object — point_body.gd

This file is unchanged from the previous hall. Keep your existing copy. It appears here so the three-file example is complete.

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

### Predict, intervene, compare

Replay with B's exchange off and step once. Check W's two answers against the table above. Press V: the colours change while the tick and stored values remain the same. Press E and step once: with exchange on for both, every address should agree.

Now restore B's exchange-off comparison. Carry the point to a different address, outside the starting square, and plant. Step 100 times. Find a site just beyond that second patch. Can anything make its first V arrive without exchange? At an untouched site, V = 0 makes the local reaction product zero. An address can receive its first V from its neighbours.

Make one independent edit: in `reset`, after `right.reset()`, add `left.seed_at(Vector2i(0, 0))` and `right.seed_at(Vector2i(0, 0))`. Predict all nine addresses before replaying. The patch appears at x = 31, 0, 1 and y = 31, 0, 1. Its split appearance is one neighbourhood crossing the periodic boundary, not four unrelated seeds. After replay, find which side can send V into an adjacent unseeded address. Remove those two added lines to return to the original beginning.

Both clocks stop at 2,400 steps. Reset to make another comparison. You leave with a field class that can be shown on more than one surface, a point that can intervene without replacing the rule, and a distinction between what happens at an address and what can arrive from elsewhere. The next hall compares a cellular history with recursive construction: similar forms can have different ways of becoming.


---

<a id="CA_AgentsCircuits"></a>

**07 / 08 · CA_AgentsCircuits**

## Two ways to make

### Learning elements

- Rule 90: a next cell is occupied when its two neighbours differ.
- Independent rows store successive states; a picture can show time along one axis.
- A supplied copying recipe places cubes without reading a cellular state.
- Change one input, then identify which construction responds.
- A finite boundary limits a pattern that appears to keep growing.

### Return to the row

The previous hall separated what happens at an address from what it receives from neighbours. Here we return to the Boolean row from the CA opening and the saved history from the third hall. We change its rule, then compare its way of making with the pyramid already in the room.

At the explorer, select 90 and replay the single central seed. The stored rows appear both on the desk and on the floor. Take the same black point at the desk's front rail. Moving it sideways selects a current-row address; its trigger advances one generation. Read the neighbours before pressing. The point is an inspector and a STEP control here, not a seed brush.

Follow one triangular gap across the floor toward the pyramid. Both constructions suggest repeated shapes. Find out what each procedure reads before treating that resemblance as an explanation.

### Reconstruct this comparison

Save your earlier study. Put `procedures.gd`, `comparison.gd` and the unchanged `point_body.gd` together. Attach `comparison.gd` to the existing `PointStudy` Node3D in the Day Zero museum, at unit scale. Leave about 4 × 2.5 metres clear and approach its positive Z side. The museum continues to supply the player, camera, lighting and XR Tools. All required study children are built below.

The compact model shows one history table and one fixed cube construction. The museum also enlarges its history onto the floor and supplies richer rule controls. This reconstruction stays with Rule 90. Enter or the held point's trigger steps; R replays the selected seed; C switches between one cell and two adjacent cells and replays. C and R are keyboard controls here; use the installed desk's SEED and RST buttons in the full VR encounter. Walking keys remain available.

### What does a cell read?

For Rule 90 the centre does not affect the answer. Read the old left and right values. If exactly one is true, the next value is true. If they agree, it is false. For Booleans, `left != right` expresses exclusive OR, often called XOR.

| Left | Right | Next |
| --- | --- | --- |
| false | false | false |
| false | true | true |
| true | false | true |
| true | true | false |

The existing explorer evaluates a numbered eight-case rule including the centre. Its Rule 90 gives this same answer for all eight cases. The shorter expression below exposes that particular rule; it does not replace the general evaluator in the museum.

`next_row` reads the complete old row and returns a new one. The last address neighbours the first. `history` keeps those rows in chronological order. Each row's horizontal positions are space; advancing along the table shows time. New rows change neither the earlier arrays nor the pyramid's positions.

### What does the copying recipe read?

`copy_positions` is supplied from the installed pyramid's placement logic. It reads a position, spacing and remaining depth. At depth zero it returns one position. Otherwise it calls itself at six offsets with half the spacing and one less depth. A function that calls itself is recursive; we will study that process through the Fractals sequence. Here follow just one call and notice its inputs.

The six placements are four lower corners and two upper positions. This particular recipe has an extra upper branch. It does not inspect neighbouring cubes, read the cellular row, or wait for a clock. The returned list contains one entry per leaf call, including entries that may coincide. Every displayed cube keeps the same size; spacing changes during the construction. The result is a finite collection with overlaps, not a demonstration of an ideal fractal's dimension.

At depth 3 the procedure returns 6 × 6 × 6 = 216 entries. The large museum pyramid uses depth 4: 1,296 entries. The compact model scales all final positions and cube sizes together, so its smaller version retains the recipe's proportions. We supply that recipe to make the comparison inspectable; deriving it is not a prerequisite for the neighbour-rule lesson.

### Complete procedures — procedures.gd

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

### Keep the two constructions independent

`make_display` asks for the cube positions once. `step` asks only for a next cellular row. `reset` restores that history from `seed_sites`. None of those cellular operations rebuilds or edits the cubes.

The same PointBody from the previous room supplies its held world position. Converting to study-local X selects an address along the rail. This changes `selected`, not the cells. The readout predicts that address's next value. Release parks the point at the selected address.

`redraw` places every recorded cell, including zeros. Dark tiles show false; they are not holes. Unrecorded rows have zero-size transforms. The table's collider remains solid beneath both states. The miniature cubes are visual instances on a solid plinth; the installed pyramid uses the museum's cube prefab and its colliders. The compact model does not rebuild that larger climbing geometry.

### Complete study — comparison.gd

Read `reset`, `step` and `readout` first. `draw_instances` and `make_display` include the staging so the example can run without prepared child nodes. There is one `_ready`.

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

### Unchanged carried object — point_body.gd

Keep your existing copy from the previous hall. It is repeated here only to make the three-file example complete.

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

### One beginning, two kinds of change

Replay the single cell at address 16. Before STEP, predict addresses 15, 16 and 17. After one update, 15 and 17 are occupied; 16 is empty. Both new cells read the old 16. No cube in the pyramid moves.

Advance to generation 15 and compare a gap with the fixed sculpture. Then predict generation 16 before pressing. On this 32-cell ring, both expanding edges reach the same opposite address. That address reads two true neighbours, so XOR returns false. The entire next row is empty and remains empty. The pattern did not reach an infinite limit: the finite periodic boundary changed the situation.

Press C to try two adjacent cells. It restarts the cellular history while keeping the same copying construction. Step and compare. Which resemblance survives? You can test the changed row; a visual match with the sculpture remains a judgment about selected features, not a proof that the procedures agree.

Make one independent edit: set `seed_sites` to **[14, 16, 18]**, then restart the script. Predict the first row before pressing Enter. Only addresses **13 and 19** should be occupied. Addresses 15 and 17 each receive two true neighbours and cancel. Check the readout at either cancelled address, and confirm that the 216 cube transforms stayed the same. R replays your edited seed; C returns to the built-in single/pair choices.

The compact table stops after 24 stored rows, generations 0–23, so the comparison stays inspectable. The installed explorer can continue and scrolls its last 24 rows; it labels that retained range. These are different display budgets for the same row update.

You can now distinguish repeating an update from repeating a placement. The next hall keeps the procedure fixed and changes one starting value, asking how far that difference travels.


---

<a id="CA_EdgeOfChaos"></a>

**08 / 08 · CA_EdgeOfChaos**

## What a difference keeps

### Learning elements

- Copy a beginning and change one address.
- Keep the update and forcing identical in two runs.
- Measure how many addresses differ and how large the difference is.
- Compare integer truncation with retained fractional values.
- Select a spatial section without advancing time.
- Read display gain separately from the values it makes visible.

### Bring the comparison forward

In the previous room, a changed seed altered the row history while the copied pyramid stayed fixed. Here both volumes use the same procedure. We change one starting value in B and follow what happens to that difference.

Begin in the existing paired study. Set SEED to UNIFORM, DRIVE to zero, PULL to 0.25 and ONE CELL on. Both volumes start at four, except B's centre, which starts at five. Their update counter is still zero.

Walk between the volumes. At Z=5, the selected section contains that centre; at Z=6, it does not. The floor and wall can lose sight of a difference without the arrays losing it. Take the familiar black point beside the console to choose the section by hand instead. While it is held, the hand takes priority. Release it to resume walking as the reader. Its trigger advances one update.

### Reconstruct this experiment

Keep the Day Zero museum and save the previous study. Put `paired.gd`, `difference.gd` and your unchanged `point_body.gd` together. Attach `difference.gd` to the existing `PointStudy`, at unit scale. Approach from positive Z; leave about 3.2 × 2.5 metres clear. The existing museum supplies the player, camera, lighting and XR Tools. Every study mesh, material, label and collider is created below.

The miniature keeps both complete 11³ volumes and their three section images. Move the held point forward and back along the middle rail to select Z. Trigger or Enter advances one update. It starts with the quiet, uniform, integer comparison above; the full exhibit initially uses its scattered, driven beginning. The miniature uses keyboard controls for parameters. The installation retains its nearby VR buttons and walking reader, plus the enlarged difference floor.

### Copy, then intervene

`a` and `b` are packed arrays of 64-bit floating-point numbers. One index represents `x + N*y + N*N*z`. `b = a.duplicate()` makes an independent copy. Only then does B gain one at `site`.

For each address we keep a list of valid neighbours. This is the 26-neighbour volume from the second CA hall, with positions outside the box omitted. A corner has seven neighbours. It does not wrap to the opposite side.

One update keeps three quarters of the present value and adds one quarter of the neighbours' average. More generally, `pull` selects that fraction. Both next arrays are completed from the old arrays before either becomes the present.

The supplied `sample` function returns a reproducible forcing value for an address and generation. A and B receive the **same** value. It is a finite arithmetic schedule, not a claim of independent random samples. Its number recipe is supplied so this lesson can focus on a fair comparison.

`integer_storage` describes what answers we retain, not the array's machine type. In that mode, `int(value)` discards the fractional part before the result returns to the floating-point array. Fractional mode retains that part, subject to finite floating-point precision. Both modes clip answers to the range 0–9.

### Complete paired model — paired.gd

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

### Measure before judging the picture

`report` subtracts the arrays address by address. The count includes only absolute differences greater than 0.000001. Maximum and mean use every stored difference, including those below that threshold. These quantities answer different questions: how widely detectable difference is distributed, how large the largest difference is, and its average over the whole volume.

The A and B palettes use the same fixed 0–9 scale. The third image magnifies absolute difference by `gain = 1 / max(maximum, 0.000001)`. Gain changes only the image. It is printed beside the measurements because a bright picture can accompany a fading difference.

`select_slice` changes an address in the receiver, not a generation in the model. At each selected Z, X and Y remain spatial coordinates. Gold frames locate that plane in both volumes. Moving the point alone changes neither array; its trigger calls `step`. On release it parks at the selected slice.

### Complete study — difference.gd

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

### Carried object — point_body.gd

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

### Make three predictions

**First, keep INTEGER, UNIFORM, PULL 0.25 and DRIVE 0.** At the changed centre, the calculated answer is 4.75. Integer storage keeps four. Its neighbours' small increases also lose their fractions. After one update the count and maximum difference are zero. Both complete arrays agree.

**Now press I.** This selects FRACTIONAL and replays the same beginning. After one update, predict a smaller peak spread over more addresses: the centre differs by 0.75; each of its 26 neighbours differs by 0.25/26. The count is 27. Continue to update 20. Read the maximum beside the gain before calling the larger lit region an amplification.

**Press P to set PULL to zero.** With DRIVE still zero, this replays the beginning and then preserves the original difference at one address through every step. An unchanged picture can retain something that the smoothing update distributes.

Press C to remove the one-cell intervention. A and B should agree. Press N to enable the shared drive; they should still agree. This is a control for the comparison. Press B to switch to the supplied scattered beginning. C, N, B, I and P all replay both arrays after changing their setting. R replays while preserving settings. None changes the selected slice. The model stops at 100 updates.

### Make an independent change

In `paired.gd`, change `site` to `Vector3i(0, 0, 0)`. Run in UNIFORM, FRACTIONAL mode with PULL 0.25 and DRIVE zero. Select Z=0 to see the beginning. Before STEP, predict which addresses can receive it.

After one step, **eight** addresses differ: the corner itself and its seven valid neighbours. The corner difference is still 0.75. A receiving cell averages its own neighbour list: the adjacent edge cell (1,0,0) receives 0.25/11; the interior cell (1,1,1) receives 0.25/26. There is no wrap to the far face. The changed location exposes a boundary choice hidden by the central example. The scaffold expects `site` inside 0–10 on each axis; its +1 experiment is compared from the uniform beginning.

Explain three different disappearances: moving to a slice that misses the changed address, integer storage discarding the difference, and a stored difference falling below the count's threshold. They require different evidence.

This completes the required cellular-automata passage with a testable comparison. In the unforced fractional case, averaging spreads and reduces the peak; brightness alone does not establish chaos.

### Optional composition — follow a question of your own

Return to one working study and connect it to an operation from an earlier sequence. Keep the original folder. Choose an encounter you want to make possible, rather than another effect the lesson has already predicted. A field might change a route, a moving cube might supply a position, or a trace might let an intervention return. One borrowed operation is enough to begin.

For a concrete starting point, bring **Trace's stored positions** back to `presence.gd` from *The surface includes you*. Record the input in simulation coordinates before each committed step, together with whether the point is held and active as an input. Store one entry per update, including pauses and repeated positions. Trace's minimum-distance filter would lose the duration of a pause here. An absent input must remain distinct from a point parked somewhere in space.

Keep the starting field, update count and SYNC/SCAN and REVERSE settings with that record. Replay it through `evolve` without consulting the live hand. With the same beginning, settings and ordered inputs, each replayed field should match the recorded run. Compare all eighty values, not only the final picture. This agreement tests the recorder; it does not decide whether the encounter was interesting.

Use the live hand to pursue a shape, a disappearing support or something you had not intended. Replay the attempt, find a moment worth revisiting, then make a new attempt in response. The museum bridge already connects bodily position to support and back to possible movement. Its VISITOR source is the tracked body origin; the table records the held point's centre. Do not present a hand replay as a record of a visitor's walk.

You can choose another connection. State which input, rule or receiver you changed and keep enough of its beginning to revisit it. Submit the working variant, one observation that changed your question, and one check that its code still does what you say. You are not required to produce an unexpected result or a prettier pattern. This open task has no single supplied answer and adds no new required code to the eight lessons.

Fractals returns to explicit repetition: what changes when the procedure calls itself instead of waiting for neighbouring states to exchange values?
