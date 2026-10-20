# Flow — room for another

**Learning elements**

- Directed capacity and allocated flow
- Reusing breadth-first pathfinding on residual connections
- The bottleneck of a route
- Reversing an earlier allocation
- Conservation, completion and a limiting cut

The tree connected everyone cheaply. It did not tell us how much could pass through a connection. We keep our point and seven vertex IDs, but give the links a new meaning: **crate slots available during one planning interval**. A capacity is not the build cost from Spanning Trees.

The small harbour is a fictional logistics model. Its buildings are stock, two depots, two transfer yards, a dock and a destination. The boxes on its links are allocation markers. We are planning deliveries before dispatch, not simulating trucks, queues or moving water. One marker means the link is used; the numeric label gives its assigned amount.

**Carry:** PointBody, the queue and the complete route finder from Pathfinding. **New:** a capacity table and a flow table. **Supplied:** the existing museum/XRTools and the complete harbour drawing below. Keep earlier lesson folders intact.

## First see the obstruction

The museum's existing push/relabel display fills source connections, then tries to pass excess onward. Its height is an algorithm label, not physical altitude. The implementation follows only original forward edges. It can stop with excess left at a junction, and its label explicitly says that a maximum has not been established. Keep that comparison: an early allocation may need revision.

Our smaller reconstruction uses complete source-to-destination paths. Every completed step conserves flow at intermediate vertices. It does **not** reproduce the comparison's temporary excess or height procedure.

## Give the route finder a different set of neighbours

Make a `GT_Flow` folder beside the earlier studies. Copy `point_body.gd` and `traversal.gd` unchanged from Spanning Trees, and `route.gd` unchanged from Pathfinding. Save this as `flow_model.gd`.

<!-- student-code:flow_model.gd -->
```gdscript
extends RefCounted
const Route = preload("route.gd")
const COUNT := 7
const SOURCE := 0
const SINK := 6
# One planning interval. Each integer is a number of crate slots.
var links: Array = [
	{"a": 0, "b": 1, "cap": 1}, {"a": 0, "b": 2, "cap": 1},
	{"a": 1, "b": 3, "cap": 1}, {"a": 1, "b": 4, "cap": 1},
	{"a": 2, "b": 3, "cap": 1}, {"a": 3, "b": 5, "cap": 1},
	{"a": 4, "b": 5, "cap": 1}, {"a": 5, "b": 6, "cap": 2},
]
var capacity: Array = []
var flow: Array = []
var path: Array[int] = []
var changes: Array = []
var total := 0
var done := false

func reset() -> void:
	capacity.clear()
	flow.clear()
	for i in range(COUNT):
		var row: Array[int] = []
		row.resize(COUNT)
		row.fill(0)
		capacity.append(row.duplicate())
		flow.append(row.duplicate())
	for link in links:
		capacity[link.a][link.b] += link.cap
	path.clear()
	changes.clear()
	total = 0
	done = false

func residual(a: int, b: int) -> int:
	return capacity[a][b] - flow[a][b]

func search() -> Array[int]:
	var walker = Route.new()
	walker.neighbours.clear()
	for a in range(COUNT):
		var row: Array[int] = []
		for b in range(COUNT):
			if residual(a, b) > 0:
				row.append(b)
		walker.neighbours.append(row)
	return walker.find_path(SOURCE, SINK, [])

func step() -> void:
	if done:
		return
	path = search()
	changes.clear()
	if path.is_empty():
		done = true
		return
	var amount: int = residual(path[0], path[1])
	for i in range(path.size() - 1):
		amount = mini(amount, residual(path[i], path[i + 1]))
	for i in range(path.size() - 1):
		var a: int = path[i]
		var b: int = path[i + 1]
		changes.append({"a": a, "b": b, "amount": amount, "undo": flow[a][b] < 0})
		flow[a][b] += amount
		flow[b][a] -= amount
	total += amount
```

`capacity[a][b]` is the declared limit. Each row is a separate array. `flow[a][b]` is the amount assigned in that direction, and the opposite entry records its negative. The example has no original pair of opposite links; the negative entry records permission to cancel an allocation, not a second physical road.

`residual(a, b)` subtracts what is assigned from what is available. After assigning one unit from 1 to 3, the forward residual is zero. The reverse entry is `0 - (-1)`, giving one unit of permission to revise that choice.

`search()` builds neighbours only where residual capacity is positive. Then it calls the **same** breadth-first route finder we already used. It finds a path with the fewest residual edges, not the shortest physical journey. We replace its old neighbours explicitly, so the old reciprocal detour does not leak into this model.

`step()` takes the smallest residual capacity along that path: its bottleneck. It adds that amount in each forward traversal and subtracts it in the opposite entry. A path that traverses a reverse residual edge cancels part of an earlier allocation. Each successful step increases the total reaching the destination.

This is Edmonds–Karp on a small integer network. Capacity and reverse-flow conventions can also be inspected in the [NetworkX maximum-flow documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html). Our code is implemented here; NetworkX is not a runtime dependency.

## Predict two allocations

| Action | Residual path | Result |
|---|---|---|
| First step | 0 → 1 → 3 → 5 → 6 | Allocate one crate slot |
| Second step | 0 → 2 → 3 → **1** → 4 → 5 → 6 | Cancel 1 → 3; total becomes two |
| Third step | No residual source-to-destination path | Mark the allocation complete |

On the second step, 3 → 1 is a revision. Final deliveries can follow 0 → 1 → 4 → 5 → 6 and 0 → 2 → 3 → 5 → 6. No delivered crate is magically retrieved. The final link 5 → 6 has capacity two. So do the two source links together: no allocation can exceed two, and our allocation achieves two. Here that gives a simple independent certificate of the maximum.

The two final routes share the dock. A route existing does not mean it owns all that capacity. Intermediate inflow must equal outflow after each complete augmentation; the source and destination are the exceptions.

## Put the plan in the museum

Save `study.gd` below on a single Node3D named `Study`, and save that node as `study.tscn`. All displayed objects and controls are created by the script. Place your study in the Flow hall at map-local `(9, 0, 3.8)`, yaw 180 degrees, scale 1. In the isolated hall wrapper, whose map starts four metres along Z, the equivalent local position is `(9, 0, 7.8)`.

The existing museum provides the player, camera, lighting and pickup function. This study adds the familiar black point, buildings, directed links, allocation markers and two nearby controls. The primary programming subject remains the small flow model; this full host makes it runnable.

<details open>
<summary>Complete harbour host — study.gd</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Flow = preload("flow_model.gd")
const PointBody = preload("point_body.gd")
# Same IDs, now arranged as a miniature harbour plan.
const INITIAL: Array[Vector3] = [
	Vector3(-1.35, 1, 0), Vector3(-0.7, 1, -0.65),
	Vector3(-0.7, 1, 0.65), Vector3(0, 1, -0.65),
	Vector3(0, 1, 0.65), Vector3(0.7, 1, 0), Vector3(1.35, 1, 0),
]
const NAMES := ["0 / stock", "1 / depot A", "2 / depot B", "3 / yard C", "4 / yard D", "5 / dock", "6 / destination"]
var model = Flow.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var houses: Array[MeshInstance3D] = []
var rods: Array[MeshInstance3D] = []
var arrows: Array[MeshInstance3D] = []
var crates: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var weights: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption: Label3D
var cancelled: MeshInstance3D

class PlanButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	box(Vector3(3.4, 0.12, 2.1), Vector3(0, 0.8, 0), Color("344957"))
	for i in range(places.size()):
		houses.append(box(Vector3(0.28, 0.22, 0.25), places[i], Color("dcddd3")))
		labels.append(label(NAMES[i], Vector3.ZERO, 20))
	for link in model.links:
		var rod := CylinderMesh.new()
		rod.top_radius = 0.025
		rod.bottom_radius = 0.025
		rods.append(body(rod, Color("689299")))
		var arrow := CylinderMesh.new()
		arrow.top_radius = 0
		arrow.bottom_radius = 0.07
		arrow.height = 0.13
		arrows.append(body(arrow, Color("a7c7cd")))
		crates.append(box(Vector3(0.12, 0.12, 0.12), Vector3.ZERO, Color("eab668")))
		weights.append(label("", Vector3.ZERO, 22))
	var undo_shape := CylinderMesh.new()
	undo_shape.top_radius = 0.015
	undo_shape.bottom_radius = 0.015
	cancelled = body(undo_shape, Color("e382aa"))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption = label("", Vector3(0, 2.15, -0.35), 23)
	for i in range(2):
		var button := PlanButton.new()
		button.position = Vector3(-0.45 + i * 0.9, 0.9, 1.15)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.7, 0.18, 0.08)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		box(shape.size, Vector3.ZERO, Color("a16984")).reparent(button, false)
		var title := label("PLAN NEXT" if i == 0 else "RESET", Vector3(0, 0, 0.05), 23)
		title.reparent(button, false)
		button.action = advance if i == 0 else reset
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	node.material_override = material
	add_child(node)
	return node

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := body(mesh, colour)
	node.position = at
	return node

func label(words: String, at: Vector3, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = words
	node.position = at
	node.font_size = size
	node.pixel_size = 0.002
	add_child(node)
	return node

func connect_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var direction := b - a
	node.visible = direction.length() > 0.001
	if node.visible:
		node.mesh.height = direction.length()
		node.position = (a + b) * 0.5
		node.quaternion = Quaternion(Vector3.UP, direction.normalized())

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - Vector3.UP * 0.24
		places[4] = Vector3(local.x, 1, local.z)
	else:
		point.position = places[4] + Vector3.UP * 0.24
	redraw()

func redraw() -> void:
	for i in range(places.size()):
		houses[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.42, 0)
	for i in range(model.links.size()):
		var link: Dictionary = model.links[i]
		var a: Vector3 = places[link.a]
		var b: Vector3 = places[link.b]
		var assigned: int = model.flow[link.a][link.b]
		connect_rod(rods[i], a, b)
		arrows[i].visible = rods[i].visible
		if rods[i].visible:
			arrows[i].position = a.lerp(b, 0.7)
			arrows[i].quaternion = rods[i].quaternion
		crates[i].visible = assigned > 0
		crates[i].position = a.lerp(b, 0.4) + Vector3.UP * 0.08
		weights[i].position = a.lerp(b, 0.5) + Vector3.UP * 0.2
		weights[i].text = "%d / %d" % [assigned, link.cap]
		rods[i].material_override.albedo_color = Color("eab668") if assigned > 0 else Color("689299")
	cancelled.hide()
	var revision := ""
	for change in model.changes:
		if change.undo:
			connect_rod(cancelled, places[change.a] + Vector3.UP * 0.28, places[change.b] + Vector3.UP * 0.28)
			revision = "\nPink: cancel %d slot on %d -> %d." % [change.amount, change.b, change.a]
	caption.text = "HARBOUR / %d crate slots allocated\nLabels: assigned / capacity. One planning interval." % model.total
	caption.text += revision
	caption.text += "\nNo more residual routes." if model.done else "\nTrigger / 1: plan next. R: reset after release."
	caption.text += "\nPlanning markers, not crates travelling back in time."

func advance() -> void:
	model.step()
	redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_R:
			reset()
```

</details>

Hold the black point above yard 4 to move that building across the plan. As in Layout, a change of coordinates leaves the represented connections unchanged. We now project onto local XZ because this is a tabletop. Capacities remain fixed. Its trigger or `1` plans the next allocation; the nearby PLAN NEXT control does the same. Release before `R` or RESET.

Labels show **assigned / capacity**. A pink raised connection identifies a cancelled allocation on the latest step. It is separate from the original directed roads. The final empty search clears the latest path display; the assigned totals stay visible.

## Make a different limit

Change only the final link, 5 → 6, from capacity 2 to **1**. Reset and predict the result before stepping. One crate slot reaches the destination; no second residual path can pass its full final link. The network is still connected by routes. Its capacity is smaller.

Now restore that capacity to 2 and set 1 → 4 to **0**. Predict the same total of one for a different reason: both depots must compete for the single slot on 3 → 5. A zero-capacity link can remain in the drawing while being unavailable to the search.

The tests reconstruct the printed code, check conservation and capacities, compare many small inputs with independently enumerated cuts, and reject a version that cannot cancel earlier choices. Passing a single demonstration is not enough.

## Carried code, unchanged

These files are printed so the lesson can be reconstructed without an undisclosed dependency. They are not new lessons.

<details>
<summary>point_body.gd — unchanged</summary>

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
<summary>traversal.gd — unchanged</summary>

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
<summary>route.gd — unchanged</summary>

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

The next hall is Matching. One early pair can prevent two later pairs; an alternating path will give revision another concrete job.
