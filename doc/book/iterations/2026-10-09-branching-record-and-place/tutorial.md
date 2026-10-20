# Branching Growth — a record and a place

## Learning elements

- Search for one nearest unreached target
- Retain the chosen target and parent indices
- Separate a record count from a position count
- Change whether a parent may act again

Keep the eight-point field from Space Colonization. There, each request chose a site, and that site combined its assigned directions. Here each active site chooses one nearest target. The relation has changed before a single branch appears.

## Look before pressing STEP

At the existing museum desk, RESET turns variation off. The root is at (0, 0, 0). Its nearest target is entry 0: (−2, 1.5, 0), 2.5 metres away. Normalize that displacement and take a half-metre step. The first child should be (−0.4, 0.3, 0). Press STEP and check the leftward lean.

Press STEP again. The root is still active. It creates another child at (−0.4, 0.3, 0), while the first child advances to (−0.8, 0.6, 0). We now have four records, including the root, but only three distinct positions. A second record need not add a new place.

## Rebuild the operation

Use the prepared Endless Museum. Save the three complete files below together and attach `branches.gd` to an empty Node3D at unit scale in your working copy. The test installation uses the gap before the old rear structure: hall-local (8.5, 0, 21), yaw 180 degrees. The existing player, camera, floor and XRTools remain our host.

The point is the same one we held in the previous hall. Its held trigger, or SPACE, advances once. T advances ten times. H keeps a specimen; R resets growth while retaining it. Moving the point alone does not grow a branch. The drawing remains a 0.4-scale miniature; a numerical half-metre edge appears as 0.2 metres. It supplies no floor or branch collision.

### Keep the choice in the record

The eight coordinates are unchanged. `reached` has one Boolean for each target; the target list itself stays in place, so its indices remain meaningful. A node keeps its position and parent, as before. We add `target`, the index chosen when this node was made, and `active`, whether the node may respond on another step. The root has no parent or chosen target, so both indices are −1.

`nearest()` scans the unreached points. It starts with a maximum distance of eight metres and replaces the choice only when it finds a closer one. A point exactly eight metres away is excluded. Equal distances keep the earlier entry in the list. A result of −1 means no eligible target was found; it is not a target index to draw.

`step()` reads the existing nodes, collects children separately, then appends them. A new child waits until the following generation before it can choose a target. The chosen index is written into the child, alongside its parent index. We can now ask both where a branch began and what it was answering.

<!-- student-code:growth.gd -->
```gdscript
extends RefCounted
const STEP := 0.5
const REACH := 8.0
const NEAR := 0.32
var nodes: Array = []
var points: Array = []
var reached: Array = []
var generation := 0
var reason := ""

static func field() -> Array:
	return [Vector3(-2,1.5,0), Vector3(-2.5,2.5,0.4), Vector3(-3,3.5,0),
		Vector3(1.5,2.5,0), Vector3(2,3.5,-0.5), Vector3(2.5,4.5,0),
		Vector3(0,5.5,1), Vector3(0,6,0)]

func reset() -> void:
	nodes = [{"position":Vector3.ZERO, "parent":-1, "target":-1, "active":true}]
	points = field()
	reached.resize(points.size()); reached.fill(false)
	generation = 0
	reason = ""

func nearest(at: Vector3) -> int:
	var chosen := -1
	var distance := REACH
	for i in points.size():
		if reached[i]: continue
		var d: float = at.distance_to(points[i])
		if d < distance:
			distance = d
			chosen = i
	return chosen

func step() -> bool:
	if nodes.size() >= 192:
		reason = "record budget"
		return false
	var additions: Array = []
	var consumed: Array = []
	for i in nodes.size():
		var branch: Dictionary = nodes[i]
		if not branch.active: continue
		var target: int = nearest(branch.position)
		if target < 0:
			branch.active = false
			continue
		var offset: Vector3 = points[target] - branch.position
		var next: Vector3 = branch.position + offset.normalized() * STEP
		additions.append({"position":next, "parent":i, "target":target, "active":true})
		if offset.length() < NEAR:
			consumed.append(target)
			branch.active = false
	for child in additions:
		if nodes.size() >= 192: break
		nodes.append(child)
	for i in consumed: reached[i] = true
	generation += 1
	reason = "" if not additions.is_empty() else "no active target in range"
	return not additions.is_empty()

func distinct_count() -> int:
	var positions: Dictionary = {}
	for row in nodes: positions[row.position] = true
	return positions.size()
```

This follows the installed opening with jitter and pulsing off. Notice its order: it proposes a child first, then tests the parent's old distance from the target. If that distance is strictly less than 0.32 metres, it retires the parent and marks the target reached after the pass. It does not snap the child to the target or remove the target before other sites have read it. At an exact match, the normalized displacement is zero and a coincident child can still be recorded. Those are properties of this implementation, not requirements for every growth algorithm.

Most parents remain active after making a child. That is why the same parent and target may produce the same position again. `distinct_count()` uses positions as dictionary keys, matching the desk's exact-coordinate count. It does not merge approximately equal positions or certify visibly separate branches.

The 192-record budget includes duplicates. Once it is reached, another step changes nothing. The learner model omits the installed jitter, pulse and random colour draws to isolate the nearest-target operation; it does not reproduce those optional variations.

### Draw what the record can tell us

These are the same sphere, cylinder and label helpers from Space Colonization. A line from the first active site to its selected target shows one current decision. The white segment previews its next step. The caption also names the parent and target of the last stored child. A preview and a historical record describe different moments.

HOLD deep-copies the node records and draws a smaller witness. It keeps the selected target indices, but this witness is not a saved simulation: it does not carry the current reached flags or a clock. The installed desk keeps a mesh witness instead. Both let us compare an earlier form; their records are different.

<!-- student-code:branches.gd -->
```gdscript
extends Node3D
const Growth = preload("growth.gd")
const Point = preload("point_body.gd")
const DISPLAY := 0.4
var model = Growth.new()
var point
var live: Node3D
var witness: Node3D
var caption: Label3D
var held: Array = []

func _ready() -> void:
	caption = label("", Vector3(0,2.85,0))
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,0.8))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_H: act("HOLD")
			KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"RESET": model.reset()
		"HOLD":
			held = model.nodes.duplicate(true)
			if is_instance_valid(witness): witness.free()
			witness = display(Vector3(-2,0.4,0), DISPLAY * 0.6)
			draw_record(held, witness, Color("c3b9df"))
	refresh()

func refresh() -> void:
	if is_instance_valid(live): live.free()
	live = display(Vector3(0,0.35,0), DISPLAY)
	draw_record(model.nodes, live, Color("8fd2c6"))
	for i in model.points.size():
		sphere(model.points[i], 0.055 if model.reached[i] else 0.1,
			Color("586270") if model.reached[i] else Color("efb2d1"), live)
	for row in model.nodes:
		if not row.active: continue
		var target: int = model.nearest(row.position)
		if target < 0: continue
		var direction: Vector3 = (model.points[target] - row.position).normalized()
		rod(row.position, model.points[target], 0.012, Color("946678"), live)
		rod(row.position, row.position + direction * Growth.STEP, 0.055, Color.WHITE, live)
		break
	var last: Dictionary = model.nodes.back()
	caption.text = "%d records / %d positions / step %d\nLast child: parent %d / target %d\nSPACE or held trigger: step | T: ten | H: hold | R: reset\n%s" % [model.nodes.size(), model.distinct_count(), model.generation, last.parent, last.target, model.reason]

func display(at: Vector3, factor: float) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.scale = Vector3.ONE * factor
	return node

func draw_record(rows: Array, host: Node3D, colour: Color) -> void:
	sphere(Vector3.ZERO, 0.13, colour, host)
	for row in rows:
		if row.parent >= 0: rod(rows[row.parent].position, row.position, 0.045, colour, host)

func mesh(shape: Mesh, at: Vector3, colour: Color, host: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	body.mesh = shape
	body.material_override = material
	body.position = at
	host.add_child(body)
	return body

func sphere(at: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var shape := SphereMesh.new()
	shape.radius = radius; shape.height = 2 * radius
	shape.radial_segments = 12; shape.rings = 6
	mesh(shape, at, colour, host)

func rod(a: Vector3, b: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var length := a.distance_to(b)
	if length < 0.0001: return
	var shape := CylinderMesh.new()
	shape.top_radius = radius; shape.bottom_radius = radius; shape.height = length
	shape.radial_segments = 8
	var body := mesh(shape, (a+b)/2, colour, host)
	body.quaternion = Quaternion(Vector3.UP, (b-a)/length)

func label(text: String, at: Vector3) -> Label3D:
	var node := Label3D.new()
	node.text = text; node.position = at; node.font_size = 26
	node.pixel_size = 0.002; node.outline_size = 8
	add_child(node)
	return node
```

### The carried point

`point_body.gd` is unchanged from Space Colonization. The host connects its action to STEP. Reuse it without adding a new grab system.

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

## Retire a parent after it grows

Run two steps first. Read four records and three positions; inspect the parent and target indices of the coincident children. HOLD, then RESET.

Now add `branch.active = false` immediately after the `additions.append(...)` line in `growth.gd`, at the same indentation. Keep the existing near-target check. Predict the second step before running again: the root no longer answers twice. There will be three records and three positions, with the new child attached to the previous child.

Request ten steps in both versions. Compare the counts and the retained specimen. From this single root, the edit makes a chain, since each site retires after its first child. It does not establish a general rule that no two sites may occupy the same position. The change is permission to act again, not geometric deduplication.

Explain the relation to the previous hall. Space Colonization changed which sites could receive several requests. Here we changed the lifetime of a site that selects one request. The same word, branching, was insufficient to tell us either rule.

## Return to the installed comparison

The museum's VARIATION button enables jitter and pulsing and resets the field. These can separate paths and vary edge length. They remain supplied behaviour in this lesson; they are not hidden prerequisites for the printed program. RESET turns them off again, while the held mesh stays.

Look at Organic Space nearby. Its shells and tunnels offer another account of an organic appearance. Keep that encounter alongside the tutorial without mistaking resemblance for a shared construction.

Carry the parent and target records, and the habit of checking what a count actually counts. In Percolation, the next hall, connectivity becomes the question: under a stated rule of contact, what can reach what?
