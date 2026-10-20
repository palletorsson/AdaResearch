# A state that lingers

## Learning elements

- Three cell states: empty, active, fading.
- A three-dimensional address stored in one array.
- A neighbourhood of 26 positions; count only active cells.
- A transition function: the current state changes which answer is possible.
- A synchronous update and an empty outer boundary.
- State, visible surface and colour as separate decisions.

## Reading route

Read `next_state` before `active_neighbours` and `evolve`. The new idea is a state that remains visible but no longer contributes to the active count. The complete files also include the display and controls; keep those working while investigating the named functions.

## Follow the cell

We are still in Endless Museum. The small volume and the enlarged neighbourhood show the same running calculation. Gold marks one address. Pick up the black point beside the console; its trigger advances one generation. You can carry the control while walking around a cube that hides another. The console's STEP does the same job.

Press REPLAY. The gold-framed centre begins active, with eleven active neighbours. STEP makes it green: fading. Now it has seven active neighbours. Predict its next state before stepping again. Does enough company make it active, or does its present state prevent that?

## What we carry

The last hall read an old row and wrote a separate next row. We keep that agreement, along with arrays, loops and the PointBody class. An integer now replaces each Boolean: `0` means empty, `1` active, `2` fading. One address still holds one value. A visible green cell holds a value that the active-neighbour count excludes.

The point now carries the step action. Moving it does not edit the cells or select a different address. We keep watching one centre, so its history can be followed without moving the question.

Continue on the existing `PointStudy` node in the museum, saving the row script as a previous working version. Put the two files below together and attach `volume.gd`. Keep the node at unit scale on level floor, with clear space around it; face its positive Z side. The museum already supplies camera, light, player and XR Tools. This construction supplies its own geometry, label and pickable point. No authored scene children are assumed.

Our study is a **7 × 7 × 7 volume with twelve deliberately placed active cells**. The installed work is a 50 × 50 × 50 seeded volume. They share the three-state rule and empty outer shell, but their beginnings and resulting shapes differ. In the printed twelve-cell seed, the central active-neighbour counts are **11 → 14 → 5**. At the installed gold address they are **11 → 7 → 5**. Both follow active → fading → empty. Compare the transition rule, not the two specimens as identical fields. We reconstruct the operation, then return to the larger encounter.

## Give a volume addresses

`index(p)` stores X positions next to each other. Moving one step in Y skips `SIZE` entries; one step in Z skips `SIZE * SIZE`. This is still one array. `Vector3i` keeps the address integer-valued; the drawn position uses metres separately.

The three nested loops in `active_neighbours` visit offsets −1, 0 and 1 on each axis: 27 combinations. Excluding `(0, 0, 0)` leaves 26 neighbours. Face, edge and corner neighbours each count once. Only entries equal to `1` count. This function is called for interior addresses, whose whole neighbourhood fits inside the array.

## One function chooses the next state

| Current state | Active neighbours | Next state |
|---|---|---|
| Empty, 0 | 6, 7 or 8 | Active, 1 |
| Empty, 0 | Any other count | Empty, 0 |
| Active, 1 | 6, 7 or 8 | Active, 1 |
| Active, 1 | Any other count | Fading, 2 |
| Fading, 2 | Any count | Empty, 0 |

`next_state` checks fading first. That is why a green cell with seven active neighbours empties. Moving the neighbour-count branch ahead of the fading branch would change the rule. The function assumes the three valid states listed above and a count from zero through twenty-six.

`evolve` creates a fresh, empty array and fills only its interior. It reads every answer from `old`, then `step` replaces `current`. The outer shell remains zero. Unlike the previous row, these edges do not wrap. Traversing the interior backwards should produce the same result.

## The complete construction — volume.gd

The update functions are the lesson. `make_display` builds its viewing apparatus; `redraw` reads the state without changing it. A gold frame holds the central address. Empty cells are hidden; pink and green cells remain visible. This small version draws all occupied cells, without the installed work's hidden-interior optimisation.

<!-- student-code:volume.gd -->
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

## Carry the point — point_body.gd

This is the same small PointBody from the previous hall, unchanged. It contains the sphere and its pickup boundary. The new volume connects its existing action signal to `step`. Release returns the point to its resting place. With a keyboard, Enter steps and R replays the twelve-cell beginning.

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

## Try a change you can account for

Before running the script, predict the central cell's first two states. The twelve-cell beginning gives it eleven active neighbours at generation zero. Record your prediction, the observed states and the line that explains any difference. The readout always reports the current generation's neighbours, not the count used to produce that generation.

Then replace the twelve-cell beginning with just two adjacent active cells: the centre and one face neighbour. Predict two generations for the whole volume before running it. Keep the rule unchanged. Explain why a visible fading cell does not keep the other one active. This is a prescribed seed comparison in your copy, not a change to the museum installation.

Finally, ask the transition function for the next state of an empty cell with seven active neighbours and a fading cell with seven. Their counts match. Explain why their answers differ. A good test checks both cases; a successful screenshot alone does not establish that distinction.

## Return to the larger work

REPLAY returns the installed volume to its own seed. The chosen address `(26, 22, 24)` goes from active with eleven active neighbours, to fading with seven, to empty with five. Its surrounding cells keep evolving too. The gold frame keeps the question at the same address.

VIEW changes the colours without advancing a generation. DRAWN can be smaller than ACTIVE plus FADING because the installed renderer hides occupied cells enclosed on all six faces. That is a drawing decision; the state array still includes them. The six-face visibility test and the twenty-six-neighbour update answer different questions.

RUN, the twenty-step budget and the height-colour view belong to the installed observation apparatus. Our reconstruction needs only a step and a replay. Keep them distinct from the rule you have just written.

Carry onward a transition function that distinguishes presence from participation, and an update that gives every cell the same old world. In **CA_GameOfLife**, a retained generation will become a layer of a structure. Here we replace the array; there we will also keep a history we can approach.

## Your own test

Choose a different small seed wholly inside the outer shell. Follow one nominated address for two steps. Record its state and active-neighbour count separately. Keep your prediction, the observed values and a runnable assertion in a separate test script. If they disagree, identify whether the prediction, test or study needs changing.

