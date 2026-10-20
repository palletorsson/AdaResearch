# Connectivity — a way back

**Learning elements**

- Directed adjacency from records
- Reachability using the queue we already built
- Reversing arrows without changing the ledger
- Set intersection and a strongly connected component

Our point already belongs to a graph. In Network Analysis we counted incoming and outgoing records. Now follow them: from point 4 you can reach 5, but the seven records provide no way back.

In the museum, inspect the two rings of the Tarjan exhibit. Each ring contains return routes; the arrow between them goes only one way. The larger procedure colours its completed components. Our smaller reconstruction will find the group containing one chosen start by using familiar traversal twice.

**Carry:** the same seven IDs, PointBody, traversal, route and ledger. **New:** directed adjacency and two reachability sets. **Supplied:** the previous display, controls, museum, player and XRTools. We will not reconstruct Tarjan's low-link procedure here.

## Keep the earlier object

Copy the Network Analysis lesson folder as `GT_Connectivity`. Rename its `study.gd` to `network_study.gd`; keep `point_body.gd`, `traversal.gd`, `route.gd` and `ledger.gd` unchanged. Create the two files printed below. The inherited host creates the point, lamps, arrow cylinders, labels and buttons. Our new host changes their behaviour; it does not create another player or camera.

Create a Node3D scene named `study.tscn`, attach the new `study.gd`, and instance it under this museum hall's root. Place it in the clear left bay. For the current hall root, use position `(3.5, -0.25, 9.5)`, rotation Y `180°`, scale `(1,1,1)`; this corresponds to map-local `(3.5, -0.25, 5.5)`. Run the existing museum. Remove the previous temporary learner instance if it is still installed.

## Follow, then reverse

Save this as `reachability.gd`.

<!-- student-code:reachability.gd -->
```gdscript
extends "ledger.gd"
const Walker = preload("traversal.gd")

func _init() -> void:
	# A new invented report, initially omitted. Earlier records stay intact.
	records.append({"from": 5, "to": 1, "kind": "report", "source": "R04: 5 reports to 1."})
	omitted.append(7)

func directed(reverse_arrows: bool) -> Array:
	var rows: Array = []
	for vertex in range(neighbours.size()):
		rows.append([])
	for index in active_records():
		var record: Dictionary = records[index]
		var a: int = record.to if reverse_arrows else record.from
		var b: int = record.from if reverse_arrows else record.to
		if b not in rows[a]:
			rows[a].append(b)
	return rows

func reachable(start: int, reverse_arrows: bool) -> Array[int]:
	if start < 0 or start >= neighbours.size():
		return []
	var walker = Walker.new()
	walker.neighbours = directed(reverse_arrows)
	walker.restart(true)
	walker.pending.assign([start])
	while walker.next_visit() != -1:
		pass
	return walker.visited

func component(start: int) -> Array[int]:
	var outward := reachable(start, false)
	var inward := reachable(start, true)
	var result: Array[int] = []
	for vertex in range(neighbours.size()):
		if vertex in outward and vertex in inward:
			result.append(vertex)
	return result
```

The seven earlier records are unchanged. `_init()` adds an eighth, invented report: **5 reports to 1**. It starts omitted. Including it is an explicit change to our model, not a discovery about the people imagined in the previous hall. Following mixed payment and report records is a graph exercise; it does not prove that money, a person or a message can physically travel that route.

`directed(false)` makes one fresh neighbour list for each ID, then places each destination in its source's list. It reads only active records, so the earlier omission and filter rules still apply. It never adds a reverse neighbour automatically. Duplicate events between the same endpoints need only one entry for reachability, although the earlier counting lesson counted every event.

`directed(true)` swaps source and destination **in these temporary lists**. It does not rewrite a record. If the reversed search can get from 4 to 0, the original graph can get from 0 to 4.

`reachable()` reuses our first hall's queue traversal. We replace its default neighbours with the directed lists and its default starting entry with the selected ID. Each call creates a fresh walker, so an earlier visit cannot make the next search skip a vertex. The `while` loop stops when `next_visit()` returns `-1`. The returned array records visited IDs, not a continuous walk or a shortest route.

The starting vertex is reachable from itself by a path of zero edges. An isolated vertex therefore forms a one-vertex strongly connected component. “No cycle” does not mean “no component.”

`component()` keeps the IDs found in **both** searches. For each retained vertex, the start can reach it and it can reach the start. Any two retained vertices can consequently reach each other through the start. Every vertex satisfying both conditions is included: this is the maximal strongly connected group containing that start. We find one component, not an entire partition in one pass.

## Predict the return

Keep START at 4 and all kinds included. Compare membership, not traversal order:

| Records | OUT: reachable from 4 | BACK: can reach 4 | BOTH: component |
| --- | --- | --- | --- |
| Original seven | 4, 5 | 0, 1, 4 | 4 |
| Include R04, 5→1 | 1, 3, 4, 5 | 0, 1, 2, 4, 5 | 1, 4, 5 |

With the return included, 3 is reachable but cannot return. Vertices 0 and 2 can enter the group but cannot be reached from it. Vertex 6 does neither. A vertex's incoming/outgoing counts alone cannot tell you these routes.

## Put the question in the hand

Save this as the new `study.gd`.

<!-- student-code:study.gd -->
```gdscript
extends "network_study.gd"
const Reachability = preload("reachability.gd")
var start := 4

func _init() -> void:
	ledger = Reachability.new()

func _ready() -> void:
	super._ready()
	for connection in point.action_pressed.get_connections():
		point.action_pressed.disconnect(connection.callable)
	point.action_pressed.connect(func(_source): toggle_record())
	for child in controls[0].get_children():
		if child is Label3D:
			child.text = "START"
	for child in controls[1].get_children():
		if child is Label3D:
			child.text = "RETURN"
	redraw()

# The inherited first button and key 1 call this method.
func cycle_filter() -> void:
	if point.held():
		return
	start = (start + 1) % places.size()
	redraw()

func toggle_record() -> void:
	if 7 in ledger.omitted:
		ledger.omitted.erase(7)
	else:
		ledger.omitted.append(7)
	redraw()

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[start] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[start] + FRONT
	redraw()

func redraw() -> void:
	super.redraw()
	var outward: Array[int] = ledger.reachable(start, false)
	var inward: Array[int] = ledger.reachable(start, true)
	for vertex in range(places.size()):
		var out: bool = vertex in outward
		var back: bool = vertex in inward
		var tag := "BOTH" if out and back else ("OUT" if out else ("BACK" if back else "neither"))
		labels[vertex].text = "%d / %s" % [vertex, tag]
		lamps[vertex].material_override.albedo_color = Color("8fe2ba") if out and back else (Color("eaa16d") if out else (Color("79a9ef") if back else Color("777984")))
	caption.text = "START %d / component %s" % [start, str(ledger.component(start))]
	caption.text += "\nOUT: reachable. BACK: can reach start. BOTH: mutual."
	caption.text += "\n1: start (release first)   trigger / 2: return   3: layout   R: reset"
	source_label.text = ledger.records[7].source
	source_label.text += "\n" + ("return omitted" if 7 in ledger.omitted else "return included")

func reset() -> void:
	if point.held():
		return
	super.reset()
	start = 4
	ledger.omitted.assign([7])
	redraw()
```

`extends "network_study.gd"` retains the previous construction. `super._ready()` builds it once; the new ledger is assigned before that construction begins. `super.redraw()` still places the arrows. We then replace the count labels with OUT, BACK, BOTH or neither, using colour as a second cue. The point remains black and pickable; its label identifies the selected start.

The inherited point signal is reconnected to `toggle_record()`. **Hold the point and press its trigger to include or omit the return.** Moving your hand changes the selected vertex's drawing position, not its connections. Let go before selecting another start, changing layout or resetting.

- **START / 1:** cycle through the seven starting IDs; the same point marks the selection.
- **RETURN / 2 / held trigger:** include or omit R04; its arrow appears or disappears.
- **LAYOUT / 3:** move the drawing without changing the component.
- **RESET / R:** return to start 4, the original drawing and R04 omitted.

The inherited method name `cycle_filter()` is overridden for START. This host no longer cycles kinds from a control; the ledger still supports filters for later reuse. The old route finder also remains in the carried files, but these searches use newly derived directed adjacency. They do not call that undirected route finder.

Include the return. Select 1, 4 and 5 in turn: each gives `[1, 4, 5]`. Then select 3. It stands alone even though an arrow reaches it from that group. Rearranging the drawing changes none of those answers.

## Make a different return

In `reachability.gd`, change R04's destination from **1 to 2**, and change its source sentence to **“R04: 5 reports to 2.”** Keep the other seven records and the start at 4. Before running, predict the result.

With the new return included, the component containing 4 is still `[4]`: 4 reaches 5 and 2, but they cannot get back to 4. Select 2 or 5 and the component is `[2, 5]`. Check the arrow's new endpoint as well as the labels. You have made a cycle, but it is not a return for every starting point.

Carry this distinction onward. Strong connectivity asks whether directed journeys exist in both directions. The next hall's spanning tree asks a different question about keeping an undirected network connected while selecting edges. It must declare that change of model; it cannot silently treat these event arrows as two-way roads.

## Complete carried files

These are unchanged from Network Analysis, with its host renamed `network_study.gd`. They are printed for reconstruction; the lesson's new work is in the two files above.

<details>
<summary>ledger.gd — carried unchanged</summary>

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

</details>

<details>
<summary>network_study.gd — carried unchanged</summary>

<!-- student-code:network_study.gd -->
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

</details>

<details>
<summary>route.gd — carried unchanged</summary>

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

<details>
<summary>traversal.gd — carried unchanged</summary>

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

</details>

<details>
<summary>point_body.gd — carried unchanged</summary>

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

