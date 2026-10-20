# Percolation — a rule of contact

## Learning elements

- Represent occupied cells separately from reached cells
- Define six face neighbours with integer offsets
- Read one generation while writing the next
- Test reachability by changing a contact rule

The point returns as our stepping control. The cubes return as cells with integer addresses. Branching Growth kept a parent relation for each new position. Here the positions are already present. We ask which of them a signal can reach.

## Two cubes first

At the existing museum desk, press RESET. A pink source touches a white cube along a face. Predict the result of STEP. Then press CONTACT: the second cube moves to a corner contact. They still touch, but STEP no longer transmits between them.

The program consults six offsets: one cell in either direction along each axis. A diagonal contact is absent from that list. This is the new decision to inspect. The old/next update returns from Cellular Automata; it makes that decision once per generation.

## Keep the lattice; change what has reached it

Save these three complete files together in your prepared Endless Museum working copy. Attach `lattice.gd` to an empty Node3D at unit scale in an open working bay. Our test placement is hall-local (8.5, 0, 18), yaw 180 degrees. The museum supplies the player, camera, floor and XRTools.

The small model has six cells along each axis. The installed comparison has eighteen. Each dictionary key is a Vector3i address; its value is simply true. Membership answers a question: is this cell occupied, a source, or reached? We do not store a false entry. `occupied` stays fixed during propagation. `sources` stays fixed too. `reached` is the changing state.

For the contact test we place a source at (2, 1, 2). The second cell is either (3, 1, 2), one face away, or (3, 2, 3), one corner away. A cell outside the occupied set cannot acquire flow: the update never visits it. The grid does not wrap at its boundaries.

`step()` starts with a copy of the old reached set. It visits occupied cells and asks whether any of their permitted neighbours was already reached. It reads `reached`, writes `next`, and swaps them only after the pass. A newly reached cell cannot transmit again during that same pass. `break` stops the neighbour search after one successful contact; one is enough. The returned number counts additions on this step.

<!-- student-code:reach.gd -->
```gdscript
extends RefCounted
const SIZE := 6
const OFFSETS := [Vector3i(1,0,0), Vector3i(-1,0,0),
	Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
var occupied: Dictionary = {}
var sources: Dictionary = {}
var reached: Dictionary = {}
var generation := 0

func contact(corner: bool) -> void:
	var a := Vector3i(2,1,2)
	var b := Vector3i(3,2,3) if corner else Vector3i(3,1,2)
	occupied = {a:true, b:true}
	sources = {a:true}
	restart()

func lattice(cutoff: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	occupied = {}; sources = {}
	for x in SIZE:
		for y in SIZE:
			for z in SIZE:
				if rng.randf() < cutoff: occupied[Vector3i(x,y,z)] = true
	for x in SIZE:
		for y in SIZE:
			var cell := Vector3i(x,y,SIZE-1)
			occupied[cell] = true
			sources[cell] = true
	restart()

func restart() -> void:
	reached = sources.duplicate()
	generation = 0

func step() -> int:
	if generation >= 64: return 0
	var next := reached.duplicate()
	for cell: Vector3i in occupied:
		if reached.has(cell): continue
		for offset: Vector3i in OFFSETS:
			if reached.has(cell + offset):
				next[cell] = true
				break
	var added := next.size() - reached.size()
	reached = next
	generation += 1
	return added

func far_count() -> int:
	var count := 0
	for cell: Vector3i in reached:
		if cell.z == 0: count += 1
	return count
```

R restarts propagation by copying the sources, leaving the occupied arrangement intact. The Boolean values and integer keys need only an ordinary dictionary copy. There are no nested records here. Changing the copy to an alias would change the meaning of a generation.

L builds the six-cubed comparison. The local random generator restarts at seed 1337 and visits addresses in x, y, z order. D changes the occupation cutoff between 0.2, 0.4 and 0.6 using those same draws. The whole z = 5 face is then explicitly occupied and supplied as a source, regardless of its draws. This matches the museum desk's boundary policy; the standalone production artifact normally seeds only occupied boundary cells. A boundary condition is part of the experiment.

One step crosses at most one permitted contact. A row of four face-connected cells needs three steps to reach its last cell from the first. Repeating a step cannot carry the signal across an empty gap. The 64-step limit is a working budget, not proof that every possible six-cubed path has been explored.

## Make that decision visible

These are the cubes and materials we already know. Their edge length and address spacing are both 0.3 metres, so neighbouring faces actually meet. White means occupied but unreached, pink means reached, and dark pink identifies a source. The geometry is drawn from the records; moving its host does not change adjacency.

The inherited point advances STEP when its held trigger is pressed. SPACE does the same; T makes ten requests. C alternates the two contacts, L opens the small lattice, D changes density, and R restarts only the current flow. R therefore differs from the museum desk's RESET, which returns to its face-contact opening. The caption counts all reached non-source cells so far, not just the most recent step.

<!-- student-code:lattice.gd -->
```gdscript
extends Node3D
const Reach = preload("reach.gd")
const Point = preload("point_body.gd")
const EDGE := 0.3
var model = Reach.new()
var point
var cells: Node3D
var caption: Label3D
var corner := false
var is_lattice := false
var density := 0

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0,2.85,0)
	caption.font_size = 26; caption.pixel_size = 0.002; caption.outline_size = 8
	add_child(caption)
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	model.contact(false)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_C: act("CONTACT")
			KEY_L: act("LATTICE")
			KEY_D: act("DENSITY")
			KEY_R: act("RESTART")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"CONTACT":
			corner = not corner
			is_lattice = false
			model.contact(corner)
		"LATTICE":
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"DENSITY":
			density = (density + 1) % 3
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"RESTART": model.restart()
	refresh()

func refresh() -> void:
	if is_instance_valid(cells): cells.free()
	cells = Node3D.new()
	add_child(cells)
	for cell: Vector3i in model.occupied:
		var body := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3.ONE * EDGE
		body.mesh = shape
		body.position = (Vector3(cell) - Vector3(2.5,0,2.5)) * EDGE + Vector3(0,0.55,0)
		var finish := StandardMaterial3D.new()
		finish.roughness = 0.7
		finish.albedo_color = Color("faf6ee")
		if model.reached.has(cell): finish.albedo_color = Color("ec9ebd")
		if model.sources.has(cell): finish.albedo_color = Color("8b345b")
		body.material_override = finish
		cells.add_child(body)
	var mode: String = "Lattice p=%s" % [0.2,0.4,0.6][density] if is_lattice else ("CORNER" if corner else "FACE")
	caption.text = "%s | step %d/64\n%d reached beyond %d source sites\nSPACE or held trigger: step | T: ten | C: contact\nL: lattice | D: density | R: restart" % [mode, model.generation, model.reached.size()-model.sources.size(), model.sources.size()]
	if is_lattice: caption.text += "\n%d reached on opposite z face" % model.far_count()
```

The miniature supplies no cube collision. The installed white cubes do: their collision is removed when they become flowing. That separate physical rule is visible in the hall, but it is not required to calculate reachability. Neither a pink cell nor a connected chain of centres guarantees a supported route for your body.

### Carry the point

This file is unchanged from Branching Growth. The host gives its existing action another job. Moving it alone does not advance the field; releasing it parks it beside the model.

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

## Permit one more kind of contact

Run the corner test first and predict that it stays white. Add `Vector3i(1,1,1)` and `Vector3i(-1,-1,-1)` to `OFFSETS`. These opposite offsets permit one diagonal orientation in both directions. They do not admit every possible edge or corner contact.

Run the same corner test again. The cube should now be reached in one step, without changing either position. A different corner, such as an offset of (1, 1, −1), should still fail. Explain why both results follow from the list. Then return to the seeded lattice and compare the two rules at the same density and generation. The occupied arrangement must remain identical; only the permitted relations have changed.

Do not expect every edited rule to produce a visibly different result in every field. Test a contact that distinguishes them before using a larger arrangement. An empty far-face count after a few steps may mean the wave has not arrived yet. A stopped wave on this finite field is not a universal critical threshold.

## Return to the large field

Use LATTICE and DENSITY at the museum desk. Its 18-cubed field has a supplied z = 17 source plane, and the opposite plane is z = 0. These are opposing sides, not top and bottom in Godot's y-up world. The seed and cutoff match our construction procedure, but the different grid size changes which random draw belongs to each address. The two fields are not scaled copies.

Our model keeps the reachability decision only. The installed artifact also stores numerical flow, decay, randomized transfer amounts and separate flowing/connected states. The tutorial does not reconstruct those amplitudes or claim to simulate a conserved fluid. Its Boolean wave is checked against which sites the installed update reaches, under supplied fixtures.

Keep the dark sphere and stand as other encounters in the hall. Carry the occupied addresses, reached set and explicit contact rule onward. Caves / Mazes will ask how to construct an interior for a body, after this signal has needed only a relation.
