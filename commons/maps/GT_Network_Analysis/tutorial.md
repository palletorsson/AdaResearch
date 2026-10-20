# Network Analysis — count a recorded relation

## Learning elements

- Directed records: source, destination, kind and provenance
- Incoming and outgoing counts
- Filtering and omission as different operations
- A measure that stays unchanged when the drawing moves

## Begin with the record wall

In the museum, find **A relation needs a record**. Use RECORD to follow a highlighted arrow into its written source. Use NODE to choose whose incoming and outgoing records are counted. FILTER changes which kinds count; LAYOUT moves the drawing. These are invented institutional records, not evidence about actual people.

In Pathfinding we asked for one journey. Here we ask a smaller question of every vertex: **how many of the selected records enter it, and how many leave it?** We will implement this count before making claims about importance.

Carry our seven IDs and the same point. Keep `point_body.gd`, `traversal.gd` and `route.gd` unchanged. Their seven undirected connections, including the last hall's extra 4–5 edge, remain our underlying scaffold. Add `ledger.gd` and replace the host with the complete `study.gd` below. Save all five scripts together; attach the host to one empty Node3D, or use the supplied one-node `study.tscn`. The existing Endless Museum supplies camera, lights, player and XRTools.

Place this study in the front-left learner bay at **map-local (4.5, -0.25, 6.5), Y rotation 180 degrees, scale 1**. In the isolated hall the equivalent root-local position is (4.5, -0.25, 10.5). The large record wall is already installed farther along the right wall.

## Give a connection a direction and a source

Previously, the edge 4–5 permitted travel both ways. That tells us nothing about who paid whom. We now author **one fictional directed record for each existing pair**. The direction and kind are new choices; neither the previous adjacency nor the positions can supply them.

Each dictionary names `from`, `to`, `kind` and `source`. P04 says that 4 pays 5. It counts once as outgoing at 4 and once as incoming at 5. It does not also record a payment in the other direction. The source string makes our claim inspectable; writing it does not establish that an event occurred.

<!-- student-code:ledger.gd -->
```gdscript
extends "route.gd"
# Invented events. Each direction is authored, not inferred from a drawing.
var records: Array = [
	{"from": 0, "to": 1, "kind": "report", "source": "R01: 0 reports to 1."},
	{"from": 0, "to": 2, "kind": "payment", "source": "P01: 0 pays 2."},
	{"from": 1, "to": 3, "kind": "report", "source": "R02: 1 reports to 3."},
	{"from": 1, "to": 4, "kind": "payment", "source": "P02: 1 pays 4."},
	{"from": 2, "to": 5, "kind": "report", "source": "R03: 2 reports to 5."},
	{"from": 2, "to": 6, "kind": "payment", "source": "P03: 2 pays 6."},
	{"from": 4, "to": 5, "kind": "payment", "source": "P04: 4 pays 5."},
]
var omitted: Array[int] = []
var filter_kind := "all"

func active_records() -> Array[int]:
	var result: Array[int] = []
	for i in range(records.size()):
		if i not in omitted and (filter_kind == "all" or records[i].kind == filter_kind):
			result.append(i)
	return result

func counts(vertex: int) -> Vector2i:
	var result := Vector2i.ZERO
	for i in active_records():
		var record: Dictionary = records[i]
		if record.to == vertex:
			result.x += 1
		if record.from == vertex:
			result.y += 1
	return result
```

`active_records()` returns indices into the full ledger. Filtering to payments keeps the reports in storage but leaves them outside this question. `omitted` can additionally exclude a particular record. Neither action renumbers the remaining entries or destroys the original list.

`counts()` reads only those active records. In its returned `Vector2i`, `x` means incoming and `y` means outgoing. These are two integer counters, not spatial coordinates. The two independent `if` statements matter: a self-addressed event would count in both directions. Two separate events between the same endpoints would each count. This is a count of recorded events, not unique neighbours, money, influence or trust.

The inherited `neighbours` still describes our **undirected scaffold**. This count does not use it, and the inherited route finder would not answer a directed question about the ledger. We preserve that distinction until Connectivity builds a directed adjacency from these records.

## Predict the effect before changing the view

Start with ALL and all seven records present.

| View | Vertex 4: in / out | Vertex 5: in / out |
| --- | --- | --- |
| All records | 1 / 1 | 2 / 0 |
| All, omitting P04 | 1 / 0 | 1 / 0 |
| Payments | 1 / 1 | 1 / 0 |
| Reports | 0 / 0 | 1 / 0 |

In the reports view, omitting P04 cannot change the counts: that payment was already outside the filter. Switching back to all records makes its omission visible again. Layout should change none of these answers.

## Keep the drawing answerable to the records

The same black point now marks vertex 4, the source of P04. Hold it and move that vertex in the drawing plane, as we did in Layout. The blue marker shows the projected position. Cylinders and arrowheads follow their recorded endpoints; every label shows its incoming and outgoing count. Release returns the black point to the plane.

Trigger or **1** cycles ALL → PAYMENTS → REPORTS. **2** omits or restores P04. **3** changes the arrangement. **R** resets. The nearby pointer buttons provide the same actions in VR. Release the point before LAYOUT or RESET; those two controls deliberately wait while it is held.

The host supplies the display and input wiring in full. The new counting operation is in the shorter ledger above.

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Ledger = preload("ledger.gd")
const PointBody = preload("point_body.gd")
const FILTERS := ["all", "payment", "report"]
const FRONT := Vector3(0, 0, 0.14)
const INITIAL: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var ledger = Ledger.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var lamps: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var controls: Array[StaticBody3D] = []
var caption := Label3D.new()
var source_label := Label3D.new()
var filter_index := 0
var circular := false

class RecordButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	for i in range(places.size()):
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamps.append(body(sphere, Color("65bdd3")))
		var label := Label3D.new()
		label.font_size = 26
		label.pixel_size = 0.0018
		add_child(label)
		labels.append(label)
	for record in ledger.records:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.008
		cylinder.bottom_radius = 0.008
		rods.append(body(cylinder, Color("797984")))
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.03
		cone.height = 0.08
		tips.append(body(cone, Color("e4ab56")))
	add_child(point)
	point.action_pressed.connect(func(_source): cycle_filter())
	caption.position = Vector3(0, 2.9, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	source_label.position = Vector3(0, 1.1, 0.7)
	source_label.font_size = 26
	source_label.pixel_size = 0.0018
	add_child(source_label)
	var names := ["FILTER", "OMIT P04", "LAYOUT", "RESET"]
	var actions: Array[Callable] = [cycle_filter, toggle_record, switch_layout, reset]
	for i in range(names.size()):
		var button := RecordButton.new()
		button.position = Vector3(-0.9 + i * 0.6, 0.95, 0.5)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.53, 0.16, 0.06)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		var box := BoxMesh.new()
		box.size = shape.size
		var mesh := body(box, Color("ae647d"))
		mesh.reparent(button, false)
		var nameplate := Label3D.new()
		nameplate.text = names[i]
		nameplate.font_size = 24
		nameplate.pixel_size = 0.0015
		nameplate.position.z = 0.04
		button.add_child(nameplate)
		button.action = actions[i]
		add_child(button)
		controls.append(button)
	redraw()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.6
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[4] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[4] + FRONT
	redraw()

func redraw() -> void:
	var active: Array[int] = ledger.active_records()
	for i in range(places.size()):
		lamps[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.2, 0.04)
		var count: Vector2i = ledger.counts(i)
		labels[i].text = "%d\nin %d / out %d" % [i, count.x, count.y]
	for i in range(ledger.records.size()):
		var record: Dictionary = ledger.records[i]
		var a: Vector3 = places[record.from]
		var b: Vector3 = places[record.to]
		var direction := b - a
		var drawn: bool = i in active and direction.length() > 0.001
		rods[i].visible = drawn
		tips[i].visible = drawn
		if drawn:
			rods[i].mesh.height = direction.length()
			rods[i].position = (a + b) * 0.5
			rods[i].quaternion = Quaternion(Vector3.UP, direction.normalized())
			tips[i].position = a.lerp(b, 0.72)
			tips[i].quaternion = rods[i].quaternion
	caption.text = "FICTIONAL RECORDS / %s / %d active" % [ledger.filter_kind, active.size()]
	caption.text += "\nHold 4: move drawing. Trigger / 1: filter."
	caption.text += "\n2: omit P04   3: layout   R: reset (release first)"
	source_label.text = ledger.records[-1].source
	source_label.text += "\n" + ("omitted" if 6 in ledger.omitted else "kept")
	source_label.text += " / " + ("counted" if 6 in active else "not counted in this view")

func cycle_filter() -> void:
	filter_index = (filter_index + 1) % FILTERS.size()
	ledger.filter_kind = FILTERS[filter_index]
	redraw()

func toggle_record() -> void:
	if 6 in ledger.omitted:
		ledger.omitted.erase(6)
	else:
		ledger.omitted.append(6)
	redraw()

func switch_layout() -> void:
	if point.held():
		return
	circular = not circular
	places = INITIAL.duplicate()
	if circular:
		for i in range(places.size()):
			var angle := TAU * float(i) / places.size()
			places[i] = Vector3(cos(angle), 1.9 + sin(angle) * 0.65, 0)
	redraw()

func reset() -> void:
	if point.held():
		return
	filter_index = 0
	ledger.filter_kind = "all"
	ledger.omitted.clear()
	circular = false
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: cycle_filter()
			KEY_2: toggle_record()
			KEY_3: switch_layout()
			KEY_R: reset()
```

Moving a marker cannot create or remove a record. Even if two markers coincide, their counts remain distinct. The host hides a zero-length arrow because it has no drawable direction; the record remains counted. Its label and ledger still identify what the picture can no longer separate.

## Make one independent change

Edit P04 to say **5 pays 4**: change its `from` to 5, its `to` to 4 and its source sentence to match. Leave every other record unchanged. In ALL, predict that vertex 4 changes from **1 in / 1 out** to **2 in / 0 out**, while vertex 5 changes from **2 in / 0 out** to **1 in / 1 out**. The arrow reverses and the total number of records stays seven. Then move the point: the new counts must remain.

Explain why deleting P04, reversing it and moving its endpoints are three different edits. Restore the original record before continuing.

## Carried files — unchanged

These complete files make the reconstruction runnable. They are the previous hall's work, not new operations to learn here.

<details>
<summary>PointBody: the same pickable sphere</summary>

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

</details>

<details>
<summary>Traversal and route: the retained undirected scaffold</summary>

<!-- student-code:traversal.gd -->
```gdscript
extends RefCounted

# The row number is a vertex ID; its entries are neighbouring IDs.
var neighbours: Array = [
	[1, 2],
	[0, 3, 4],
	[0, 5, 6],
	[1],
	[1],
	[2],
	[2],
]
var pending: Array[int] = []
var visited: Array[int] = []
var breadth := true

func restart(use_queue: bool) -> void:
	breadth = use_queue
	pending.assign([0])
	visited.clear()

func next_visit() -> int:
	while not pending.is_empty():
		var vertex: int = pending.pop_front() if breadth else pending.pop_back()
		if vertex in visited:
			continue
		visited.append(vertex)
		var following: Array = neighbours[vertex].duplicate()
		if not breadth:
			following.reverse()
		for other: int in following:
			if other not in visited:
				pending.append(other)
		return vertex
	return -1
```

<!-- student-code:route.gd -->
```gdscript
extends "traversal.gd"

var predecessor: Dictionary = {}

func _init() -> void:
	# Keep the previous tree; add one reciprocal connection for a detour.
	neighbours[4].append(5)
	neighbours[5].append(4)

func find_path(start: int, goal: int, blocked: Array[int]) -> Array[int]:
	restart(true)
	pending.clear()
	predecessor.clear()
	if start < 0 or start >= neighbours.size() or goal < 0 or goal >= neighbours.size():
		return []
	if start in blocked or goal in blocked:
		return []
	pending.append(start)
	predecessor[start] = -1
	while not pending.is_empty():
		var vertex: int = pending.pop_front()
		visited.append(vertex)
		if vertex == goal:
			break
		for other: int in neighbours[vertex]:
			if other not in blocked and not predecessor.has(other):
				predecessor[other] = vertex
				pending.append(other)
	if not predecessor.has(goal):
		return []
	var path: Array[int] = []
	var vertex := goal
	while vertex != -1:
		path.push_front(vertex)
		vertex = predecessor[vertex]
	return path
```

</details>

## What travels onward

Keep the point, stable IDs and directed ledger. The museum wall has eight named institutions and twelve records; our reconstruction deliberately uses the seven vertices we already built. Both make a count traceable to selected source records.

Incoming and outgoing counts do not establish whether a journey can return. In Connectivity, we will follow the directed records and ask where mutual reachability begins and ends.
