# Spanning Trees — the cost of a spare

**Learning elements**

- Undirected links and explicit weights
- Sorting edge indices by cost
- Reusing reachability to reject a cycle
- A minimum spanning tree and a disconnected forest
- A spare route under a different objective

In Connectivity, our point asked whether a directed journey could return. Now we give the same seven vertices a different job: connect them with undirected links at minimum total build cost.

This is a **new model**. Its endpoint pairs recall our earlier graph, including the last hall's extra 1–5 pair. Each link can now be followed in either direction. Its weight is a cost we assign, not a payment record, a direction or the length of the drawing. Keep the earlier ledger in its own lesson folder.

**Carry:** the same PointBody, vertex IDs, initial positions and queue traversal. **New:** a weighted edge list and a rule for selecting edges. **Supplied:** the museum, XRTools and the complete drawing/input host below. Union-find, Prim and other implementations can wait.

## Look at the existing construction

The museum's larger graph uses ten vertices and distance-based weights calculated from its own generated positions. Its Kruskal procedure considers low-weight edges first. Green overlays mark accepted edges. A considered edge underneath stays yellow; a rejected edge is not painted red, and some grey edges are never considered because the procedure stops after nine acceptances. The wall film presents the same seeded graph as a comparison.

We will reconstruct the selection with seven familiar vertices and deliberately assigned costs. Our small scan continues through all eight links so that both refusals can be inspected. That difference is intentional.

## Reuse a search to decide

Create a `GT_Spanning_Trees` folder beside the earlier lessons. Copy `point_body.gd` and `traversal.gd` unchanged from Connectivity. Save this new file as `tree_model.gd`.

<!-- student-code:tree_model.gd -->
```gdscript
extends RefCounted
const Walker = preload("traversal.gd")
const VERTICES := 7
# New undirected build costs; these are not the earlier event records.
var links: Array = [
	{"a": 0, "b": 1, "cost": 4.0},
	{"a": 0, "b": 2, "cost": 2.0},
	{"a": 1, "b": 3, "cost": 1.0},
	{"a": 1, "b": 4, "cost": 3.0},
	{"a": 2, "b": 5, "cost": 6.0},
	{"a": 2, "b": 6, "cost": 5.0},
	{"a": 4, "b": 5, "cost": 7.0},
	{"a": 1, "b": 5, "cost": 8.0},
]
var order: Array[int] = []
var chosen: Array[int] = []
var refused: Array[int] = []
var cursor := 0
var current := -1

func reset() -> void:
	order.clear()
	for i in range(links.size()):
		order.append(i)
	order.sort_custom(func(a, b):
		if links[a].cost == links[b].cost:
			return a < b
		return links[a].cost < links[b].cost)
	chosen.clear()
	refused.clear()
	cursor = 0
	current = -1

func reachable(kept: Array[int], start: int) -> Array[int]:
	if start < 0 or start >= VERTICES:
		return []
	var walker = Walker.new()
	walker.neighbours.clear()
	for vertex in range(VERTICES):
		walker.neighbours.append([])
	for i in kept:
		var link: Dictionary = links[i]
		walker.neighbours[link.a].append(link.b)
		walker.neighbours[link.b].append(link.a)
	walker.restart(true)
	walker.pending.assign([start])
	while walker.next_visit() != -1:
		pass
	return walker.visited

func step() -> void:
	if complete():
		return
	current = order[cursor]
	cursor += 1
	var link: Dictionary = links[current]
	if link.b in reachable(chosen, link.a):
		refused.append(current)
	else:
		chosen.append(current)

func complete() -> bool:
	return cursor >= order.size()

func spans() -> bool:
	return chosen.size() == VERTICES - 1 and reachable(chosen, 0).size() == VERTICES

func cost(kept: Array[int]) -> float:
	var total := 0.0
	for i in kept:
		total += links[i].cost
	return total
```

Each dictionary holds two endpoints and a cost. `reset()` sorts **indices** into the link array, leaving its order and IDs intact. If two costs tie, the earlier index goes first. Another tie order can choose another tree with the same minimum total.

`reachable()` is our queue traversal again. This time it builds neighbours only from the selected links, adding each connection in **both** directions. That is the new undirected contract. It starts a fresh search, so visited state never leaks from an earlier question.

`step()` considers the next cheapest link. If its second endpoint can already be reached from its first using selected edges, another connection between them would complete a cycle. Refuse it. Otherwise, join the two separate groups.

This is Kruskal's selection rule with repeated reachability checks in place of union-find. It is suitable for our small graph. Sorting gives the cheapest remaining candidates; the cycle check prevents paying for a connection within a group already joined. For a connected undirected graph this rule yields a minimum-total-weight spanning tree. On a disconnected input it yields a minimum spanning forest; it cannot invent missing links.

`spans()` checks that our acyclic selection reaches all seven vertices with six edges. It does **not** prove minimum cost. A valid tree can be expensive. Our separate test enumerates every six-edge subset of this small graph and compares the costs of those that span. That checks the implementation on this data; it is not a proof for every possible graph.

## Predict eight decisions

All weights are fixed even when you move the point.

| Step | Link | Cost | Decision |
| --- | --- | --- | --- |
| 1 | 1–3 | 1 | Join |
| 2 | 0–2 | 2 | Join |
| 3 | 1–4 | 3 | Join |
| 4 | 0–1 | 4 | Join |
| 5 | 2–6 | 5 | Join |
| 6 | 2–5 | 6 | Join: all seven now connected |
| 7 | 4–5 | 7 | Refuse: 4–1–0–2–5 already exists |
| 8 | 1–5 | 8 | Refuse: 1–0–2–5 already exists |

The chosen cost is **21**. Six edges connect seven vertices. The direct 4–5 link is unused, even though keeping it would shorten that particular trip in number of links. Minimum construction cost and shortest individual journey are different objectives.

## Keep the point in the museum

Create a Node3D scene named `study.tscn`, attach the complete `study.gd` below, and instance it under this hall's root. Use hall-root position `(4.0, -0.25, 10.0)`, Y rotation `180°`, scale `(1,1,1)`; this is map-local `(4.0, -0.25, 6.0)` in the left learner bay. Run the existing museum. Remove the previous temporary learner instance if it remains installed.

The host reuses our point construction and the same positions. It creates undirected cylinders, cost/state labels and nearby controls. The former ledger host is left in its own folder; it is not turned into a fictitious source of weighted links.

- **STEP / 1 / point trigger:** consider one link. Hold the point at vertex 4 while stepping if you like.
- **BREAK 0–1 / 2:** after all eight decisions, disable that selected connection.
- **SPARE 4–5 / 3:** after the scan, include the previously refused connection.
- **RESET / R:** release the point first, then restart the scan and drawing.

Mint links are selected; pink links were refused; grey links are waiting. Gold marks the added spare. Words accompany the colours. The lamps report which vertices remain reachable from 0 through **active** links. A broken connection loses its cylinder and keeps its “broken” label.

<details open>
<summary>study.gd — complete drawing and interaction host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const TreeModel = preload("tree_model.gd")
const PointBody = preload("point_body.gd")
const FRONT := Vector3(0, 0, 0.14)
const INITIAL: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var model = TreeModel.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var lamps: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var weights: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption := Label3D.new()
var decision := Label3D.new()
var broken := false
var spare := false

class StudyButton extends StaticBody3D:
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
		labels.append(label(str(i), 26))
	for link in model.links:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.009
		cylinder.bottom_radius = 0.009
		rods.append(body(cylinder, Color("777984")))
		weights.append(label("", 23))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption.position = Vector3(0, 2.9, 0)
	caption.font_size = 28
	caption.pixel_size = 0.002
	add_child(caption)
	decision.position = Vector3(0, 0.65, 0.5)
	decision.font_size = 25
	decision.pixel_size = 0.0018
	add_child(decision)
	var names := ["STEP", "BREAK 0-1", "SPARE 4-5", "RESET"]
	var actions: Array[Callable] = [advance, toggle_break, toggle_spare, reset]
	for i in range(names.size()):
		var button := StudyButton.new()
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
		body(box, Color("ae647d")).reparent(button, false)
		var nameplate := label(names[i], 24)
		nameplate.reparent(button, false)
		nameplate.position.z = 0.04
		button.action = actions[i]
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.6
	node.mesh = mesh
	node.material_override = material
	add_child(node)
	return node

func label(text: String, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.0018
	add_child(node)
	return node

func active_links() -> Array[int]:
	var result: Array[int] = model.chosen.duplicate()
	if spare and 6 not in result:
		result.append(6)
	if broken:
		result.erase(0)
	return result

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[4] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[4] + FRONT
	redraw()

func redraw() -> void:
	var reached: Array[int] = model.reachable(active_links(), 0)
	for i in range(places.size()):
		lamps[i].position = places[i]
		lamps[i].material_override.albedo_color = Color("8fe2ba") if i in reached else Color("eaa16d")
		labels[i].position = places[i] + Vector3(0, -0.2 if i >= 3 else 0.2, 0.04)
		labels[i].text = "%d / %s" % [i, "from 0" if i in reached else "apart"]
	for i in range(model.links.size()):
		var link: Dictionary = model.links[i]
		var a: Vector3 = places[link.a]
		var b: Vector3 = places[link.b]
		var direction := b - a
		rods[i].visible = direction.length() > 0.001 and not (broken and i == 0)
		if rods[i].visible:
			rods[i].mesh.height = direction.length()
			rods[i].position = (a + b) * 0.5
			rods[i].quaternion = Quaternion(Vector3.UP, direction.normalized())
		var state := "kept" if i in model.chosen else ("cycle" if i in model.refused else "waiting")
		var colour := Color("8fe2ba") if i in model.chosen else (Color("d87f9d") if i in model.refused else Color("777984"))
		if spare and i == 6 and i not in model.chosen:
			state = "spare"
			colour = Color("e4ab56")
		if broken and i == 0:
			state = "broken"
		rods[i].material_override.albedo_color = colour
		weights[i].position = (a + b) * 0.5 + Vector3(0, -0.065, 0.05)
		weights[i].text = "%.1f\n%s" % [link.cost, state]
	var extra: float = model.links[6].cost if spare and 6 not in model.chosen else 0.0
	caption.text = "%d / %d decisions   chosen cost %.1f + spare %.1f" % [model.cursor, model.order.size(), model.cost(model.chosen), extra]
	caption.text += "\nFrom 0: %d / 7 reachable. Weights stay fixed when moved." % reached.size()
	caption.text += "\nTrigger / 1: step   2: break   3: spare   R: reset (release first)"
	decision.text = "Predict the next edge. Cheapest first; refuse a cycle."
	if model.current >= 0:
		var link: Dictionary = model.links[model.current]
		decision.text = "%d-%d / %.1f / %s" % [link.a, link.b, link.cost, "JOIN" if model.current in model.chosen else "CYCLE: REFUSE"]
	if model.complete():
		decision.text = ("Tree selected." if model.spans() else "Forest: some vertices remain apart.")
		decision.text += "\nBreak 0-1, then add the spare."

func advance() -> void:
	model.step()
	redraw()

func toggle_break() -> void:
	if model.complete():
		broken = not broken
		redraw()

func toggle_spare() -> void:
	if model.complete():
		spare = not spare
		redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	broken = false
	spare = false
	places = INITIAL.duplicate()
	redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: advance()
			KEY_2: toggle_break()
			KEY_3: toggle_spare()
			KEY_R: reset()
```

</details>

`active_links()` copies the selected list, optionally adds the spare, then removes the failed link. It does not rerun Kruskal or modify the original costs. We are testing the selected design under failure. The displayed chosen cost still includes the failed connection's original build cost; it is not a bill for currently working links.

Complete the scan, then break 0–1. Vertices 1, 3 and 4 become unreachable from 0; only 0, 2, 5 and 6 stay on its side. Add the spare 4–5: all seven reconnect through a different route. Restore 0–1 as well and you now have a cycle. The added connection costs 7, making the chosen design plus spare cost 28.

One spare does not protect every connection. If 1–3 fails, vertex 3 is still cut off. The spare protects the cycle it creates, not the whole network against any failure.

## Change the cost, not the rule

In `tree_model.gd`, change the 4–5 cost from **7.0 to 0.5**. Before running, predict what enters the tree and what leaves it.

The new tree keeps 4–5 and refuses 2–5. Its total is **15.5**. The algorithm is unchanged; the declared costs changed its answer. Check the cost label as well as the selected links. In this edited version, SPARE 4–5 adds nothing because that link is already selected. Break 0–1 and that button cannot supply a second copy as an alternate route.

Carry the distinction onward: a route can be selected, available and reachable without being able to carry everything sent through it. Flow will introduce capacity as another quantity, distinct from this build cost.

## Complete carried files

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

