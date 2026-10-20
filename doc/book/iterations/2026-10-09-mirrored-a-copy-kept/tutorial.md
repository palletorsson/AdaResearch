# Mirrored Patterns — a copy kept

## Learning elements

- Hold an independent copy of a nested array
- Reflect addresses into a separate result
- Inspect the centre row and column of an odd-sized grid
- Change a copying rule while preserving its input

Sculpted Forms kept captured centres separate from their surface. Here we keep a field separate from the image copied out of it. The point returns as the action that commits an operation. The cells, arrays and loops are familiar; the new decision is which addresses may speak for others.

## Start with the existing field

At the museum desk, HOLD keeps the current cellular array. STENCIL returns to that held array and applies quadrant reflection, eight-way reflection, rotation or none. STEP first evolves the displayed field, then applies the selected copying rule. These are two operations in a chosen order.

Our reconstruction isolates quadrant reflection. It uses a declared five-by-five input, so you can account for every destination before trying the larger display. The original automaton, network and pattern tunnel remain available in the hall. We do not need another Life implementation to understand this copying step.

## Keep a witness

Save the following three files together in the prepared Endless Museum project. Attach `panels.gd` to an empty Node3D at unit scale in an open bay; our test placement is hall-local (8.5, 0, 6.5), yaw 180 degrees. The museum already supplies the player, camera and XRTools.

`reflection.gd` owns a held field and a result. Both contain rows, which are themselves arrays. `duplicate(true)` copies those rows too. A shallow copy would leave the rows shared: writing the result could silently alter the input we meant to preserve.

The function requires a non-empty square field. `n / 2` uses integer division. For five cells, the loop limit is two: rows 0–1 and columns 0–1 supply the values. The reflected partner of x is `n - 1 - x`, because valid addresses run from zero to n minus one. Thus 0 pairs with 4, 1 with 3, and 2 with itself.

<!-- student-code:reflection.gd -->
```gdscript
extends RefCounted
const INCLUDE_AXES := false
var held: Array = []
var result: Array = []

func hold(field: Array) -> void:
	assert(not field.is_empty())
	for row in field: assert(row.size() == field.size())
	held = field.duplicate(true)
	original()

func original() -> void:
	result = held.duplicate(true)

func reflect() -> void:
	original()
	var n := held.size()
	var limit := n / 2
	if INCLUDE_AXES: limit += n % 2
	for y in range(limit):
		for x in range(limit):
			var value: int = held[y][x]
			result[y][n - 1 - x] = value
			result[n - 1 - y][x] = value
			result[n - 1 - y][n - 1 - x] = value
```

Each REFLECT begins again from the held input. A cell in the upper-left quarter writes to its three partners; its own value is already in the copy. The held field never receives those writes. Applying the same operation twice gives the same result.

There is a deliberate limit here. With `INCLUDE_AXES` false, the centre row and column are not written. They retain their held values, which need not be symmetric. This reproduces the installed quadrant loop. A symmetric set of four corners is not proof that every cell in the image obeys the same reflection.

## Put input and result beside each other

`panels.gd` builds two grids from the cubes we already know. The display is fixed to five by five; the reflection model itself accepts any non-empty square array. Each cell is 0.16 metres apart. Dark cells contain 0; light cells contain 1. The pink cross marks the centre row and column in both panels, with dark and light pink carrying the same two values.

Hold the point and use its action to reflect. Moving the point alone does nothing to the array. SPACE does the same on desktop; V restores the held input to the result. The left panel is the witness throughout.

<!-- student-code:panels.gd -->
```gdscript
extends Node3D
const Reflection = preload("reflection.gd")
const PointBody = preload("point_body.gd")
const FIELD := [[1,0,1,0,0], [0,1,0,1,0], [0,1,1,0,1],
	[1,0,1,0,0], [0,1,0,0,1]]
const EDGE := 0.16
var model := Reflection.new()
var cells: Array = [[], []]
var point := PointBody.new()
var caption := Label3D.new()
var finishes: Array = []

func _ready() -> void:
	model.hold(FIELD)
	for tint in [Color("25212a"), Color("f4f0e8"), Color("653647"), Color("f3a7c0")]:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finishes.append(material)
	for side in 2:
		for y in FIELD.size():
			for x in FIELD.size():
				var cell := MeshInstance3D.new()
				var cube := BoxMesh.new()
				cube.size = Vector3(EDGE*0.9, EDGE*0.9, 0.04)
				cell.mesh = cube
				cell.position = Vector3((side*2-1)*0.55 + (x-2)*EDGE, 1.55 + (2-y)*EDGE, 0)
				add_child(cell)
				cells[side].append(cell)
	add_child(caption)
	caption.position = Vector3(0,2.2,0)
	caption.font_size = 26
	caption.pixel_size = 0.0018
	add_child(point)
	point.action_pressed.connect(func(_p): act("REFLECT"))
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.2))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("REFLECT")
		KEY_V: act("ORIGINAL")
		KEY_M: act("MARK")
		KEY_H: act("HOLD")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"REFLECT": model.reflect()
		"ORIGINAL": model.original()
		"MARK": model.result[2][4] = 1 - model.result[2][4]
		"HOLD": model.hold(model.result)
		"RESET": model.hold(FIELD)
	refresh()

func refresh() -> void:
	var fields := [model.held, model.result]
	var differences := 0
	for y in 5:
		for x in 5:
			if model.held[y][x] != model.result[y][x]: differences += 1
			for side in 2:
				var axis := 2 if x == 2 or y == 2 else 0
				cells[side][y*5+x].material_override = finishes[axis + fields[side][y][x]]
	caption.text = "HELD INPUT                         RESULT\nPink cross: centre row and column | %d changed cells\nAction / SPACE: reflect | V: original | M: mark right tip\nH: hold result | R: reset | include axes: %s" % [differences, Reflection.INCLUDE_AXES]
```

M flips the right tip of the result's centre row: address (4, 2), written as `result[2][4]`. It does not edit the held input. Press REFLECT and the mark disappears because the operation starts from that input again. This is not an accumulating drawing tool.

Try M, then H instead. HOLD takes the changed result as a new independent input. Now REFLECT retains that centre-row mark in the baseline rule, since this loop does not overwrite the axes. R restores the declared opening field. These actions make the difference between viewing, editing and committing a record visible.

The inherited point is unchanged from Sculpted Forms. It supplies pickup and action; its host keeps the release position in the museum's local frame.

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

## Give the axes a rule

Change only `INCLUDE_AXES := false` to `INCLUDE_AXES := true` in `reflection.gd`. Restart the whole example with the same field.

For five cells, the loop limit becomes three. The top half of the centre column now supplies its lower half; the left half of the centre row supplies its right half. The central cell maps to itself. This is an intentional extension of the installed quadrant operation, not a correction silently made to the museum artifact.

Predict the right-hand centre row: 0, 1, 1, 1, 0. Predict the centre column from top to bottom: 1, 0, 1, 0, 1. Four cells change between the baseline reflection and this edit. Both results still contain thirteen 1s. A count alone cannot tell you whether the axes are symmetric; inspect the addresses and their partners.

The left panel must stay identical. Compare every right-hand address with its horizontal and vertical partner. Then make a different five-by-five input and predict the result before running it. For an even-sized square there is no centre row or column: the two model versions should agree. Our automated checks include those arrays; the five-by-five display would need its layout loops resized before showing them.

## Return to the other constructions

The museum's held field contains 31 by 31 cells. Its quadrant loop reads 15 by 15 positions and leaves the middle cross alone. Eight-way and rotational copying use different loops; this lesson does not claim that they are the same operation with a different name. The rotational implementation passes through floating-point trigonometry and integer addresses.

The network beside the image asks another question. NETWORK changes how six seed positions are connected; SURFACE adds or hides their tunnel skin. Its collision is disabled in both views. The graph counts describe connections, not a guarantee that a body can walk through the specimen. Repeating an image value creates no new passage by itself.

We leave this sequence with operations we can compose: select, guide, branch, connect, carve, sample and copy. Keep their inputs and results explicit. An image can look complete while an address, an opening or a body's support still needs its own rule.

Source: `algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd`, `apply_quad_symmetry()`. Held-field control: `commons/artifacts/timing_machines/pg_workshop.gd`, `_stencil()`.
