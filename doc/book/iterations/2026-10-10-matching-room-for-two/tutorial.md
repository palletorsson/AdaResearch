# Matching — room for two

**Learning elements**

- Two sets and permitted pairings
- One partner per vertex
- Maximal versus maximum matching
- Reusing pathfinding along alternating edges
- Revising an earlier choice

At the workshop table, two people need tools for their declared tasks. Maker A can use either the drill or the saw. Maker B needs the drill. These are task requirements for this example, not judgments about the people. Each person gets at most one tool; each tool serves at most one person during this session.

The first listed pairing gives A the drill. It is permitted. It also leaves B waiting while the saw remains free. No further pair can simply be added. Press NEXT again: A releases the drill and takes the saw; B gets the drill. The revised collection has two pairs.

Flow taught us to revise a commitment. Here the commitment is a pairing. We carry the same PointBody class and unchanged route finder. We declare **four new vertex roles**, rather than quietly turning the harbour's seven places into people. Keep the previous lesson folder intact.

## Store the pairing

Create a `GT_Matching` folder beside Flow. Copy `point_body.gd`, `route.gd` and `traversal.gd` unchanged. Save the following as `matching_model.gd`.

`links` contains permitted pairs, always `[person, tool]`. The two sets use consecutive IDs from zero, with no overlap. `mate[id]` stores the chosen partner, or `-1` when free. A selected pair is recorded at both endpoints. The input here contains no same-set links.

<!-- student-code:matching_model.gd -->
```gdscript
extends RefCounted
const Route = preload("route.gd")
# People 0,1; tools 2,3. All IDs are consecutive from zero.
var people: Array[int] = [0, 1]
var tools: Array[int] = [2, 3]
var links: Array = [[0, 2], [0, 3], [1, 2]]
var mate: Array[int] = []
var path: Array[int] = []
var removed: Array = []
var done := false

func reset() -> void:
	mate.resize(people.size() + tools.size())
	mate.fill(-1)
	path.clear()
	removed.clear()
	done = false

func pair(a: int, b: int) -> void:
	mate[a] = b
	mate[b] = a

func greedy(reverse_order: bool = false) -> void:
	reset()
	var scan := links.duplicate()
	if reverse_order:
		scan.reverse()
	for edge in scan:
		var a: int = edge[0]
		var b: int = edge[1]
		if mate[a] == -1 and mate[b] == -1:
			pair(a, b)

func alternating_path() -> Array[int]:
	var route = Route.new()
	var neighbours: Array = []
	for i in range(mate.size()):
		neighbours.append([])
	for edge in links:
		var a: int = edge[0]
		var b: int = edge[1]
		if mate[a] == b:
			neighbours[b].append(a)
		else:
			neighbours[a].append(b)
	route.neighbours = neighbours
	for person in people:
		if mate[person] != -1:
			continue
		for tool in tools:
			if mate[tool] == -1:
				var found: Array[int] = route.find_path(person, tool, [])
				if not found.is_empty():
					return found
	return []

func augment() -> bool:
	path = alternating_path()
	removed.clear()
	if path.is_empty():
		done = true
		return false
	# Remove old pairs first; then select the other edges of the path.
	for i in range(1, path.size() - 1, 2):
		var a: int = path[i]
		var b: int = path[i + 1]
		removed.append([a, b])
		mate[a] = -1
		mate[b] = -1
	for i in range(0, path.size() - 1, 2):
		pair(path[i], path[i + 1])
	done = false
	return true

func size() -> int:
	var count := 0
	for person in people:
		if mate[person] != -1:
			count += 1
	return count
```

The listed greedy scan chooses `0–2`. It cannot then choose `0–3` or `1–2`: each touches an occupied endpoint. This is **maximal**—no edge can be added without disturbing an existing choice. It is not **maximum**, because two pairs are possible.

Reverse the scan order. It chooses `1–2`, then `0–3`. Changing the order exposes the earlier loss, but a fresh scan is not the same as repairing the first result.

## Make revision a path

The temporary search graph gives unused links the direction **person → tool**, and chosen links **tool → person**. Our unchanged BFS route finder can now find a path from a free person to a free tool.

After the first greedy scan, that path is `[1, 2, 0, 3]`: B → drill → A → saw. Its edges alternate unused, chosen, unused. We remove the old `2–0` pair first, then choose `1–2` and `0–3`. This complete update increases the count by one and leaves every endpoint in at most one pair. The temporary direction is a search device; a task-compatible pairing is not itself a one-way journey.

`augment()` searches and flips one path. Call it again until no path remains. For a valid bipartite matching, absence of an augmenting path characterises a maximum-cardinality matching. In this tiny case, two pairs already reach the simpler upper bound: there are only two people and two tools. We are maximising the **number of pairs**, not preference, benefit, consent or fairness.

## The complete workshop

The workshop already stands in Endless Museum. Reconstruct a second instance in the clear front-right bay: map-local `(10, 0, 5)`, Y rotation `180°`, scale `1`. In the isolated hall-root coordinate frame used by the capture tool, the same location is `(10, 0, 9)`. The museum supplies the player, camera, lighting and XRTools.

Make a one-node `Node3D` scene with this `study.gd` attached. The script creates its figures, tools, table, cylinder links, labels and controls. No prebuilt mesh nodes or dollar references are required. The small human/tool geometry is supplied display construction; the new algorithm is the model above.

<details open>
<summary>Complete study.gd</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Matching = preload("matching_model.gd")
const PointBody = preload("point_body.gd")
const INITIAL: Array[Vector3] = [
	Vector3(-0.9, 1, -0.65), Vector3(-0.9, 1, 0.65),
	Vector3(0.9, 1, -0.65), Vector3(0.9, 1, 0.65),
]
const NAMES := ["0 / maker A", "1 / maker B", "2 / drill", "3 / saw"]
var model = Matching.new()
var point = PointBody.new()
var places: Array[Vector3] = INITIAL.duplicate()
var figures: Array[Node3D] = []
var rods: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var controls: Array[StaticBody3D] = []
var caption: Label3D
var cancelled: MeshInstance3D
var reverse_order := false
var phase := 0
var history: Array[int] = [0]

class WorkshopButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:
			action.call()

func _ready() -> void:
	box(Vector3(3.2, 0.12, 2.5), Vector3(0, 0.8, 0), Color("435953"))
	for i in range(4):
		var figure := Node3D.new()
		add_child(figure)
		figures.append(figure)
		if i < 2:
			var head := SphereMesh.new()
			head.radius = 0.09
			head.height = 0.18
			body(head, Vector3(0, 0.44, 0), Color("e4b6ca"), figure)
			box(Vector3(0.15, 0.23, 0.12), Vector3(0, 0.23, 0), Color("e4b6ca"), figure)
			for x in [-0.05, 0.05]:
				box(Vector3(0.055, 0.15, 0.07), Vector3(x, 0.065, 0), Color("e4b6ca"), figure)
		else:
			if i == 2:
				box(Vector3(0.1, 0.25, 0.1), Vector3(0, 0.1, 0), Color("dca95d"), figure)
				box(Vector3(0.4, 0.14, 0.12), Vector3(0, 0.24, 0), Color("dca95d"), figure)
				box(Vector3(0.18, 0.025, 0.025), Vector3(0.28, 0.24, 0), Color("cccccc"), figure)
			else:
				box(Vector3(0.45, 0.17, 0.025), Vector3(0.12, 0.2, 0), Color("cccccc"), figure)
				box(Vector3(0.045, 0.23, 0.07), Vector3(-0.25, 0.2, 0), Color("dca95d"), figure)
				for y in [0.1, 0.3]:
					box(Vector3(0.17, 0.04, 0.07), Vector3(-0.17, y, 0), Color("dca95d"), figure)
				for x in [-0.04, 0.04, 0.12, 0.2, 0.28]:
					box(Vector3(0.025, 0.045, 0.025), Vector3(x, 0.1, 0), Color("cccccc"), figure)
		labels.append(label(NAMES[i], Vector3.ZERO, 26))
	for edge in model.links:
		rods.append(new_rod(Color("88aaa9")))
	cancelled = new_rod(Color("ee85ba"))
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	box(Vector3(3.1, 0.55, 0.03), Vector3(0, 2.35, -0.34), Color("252b32"))
	caption = label("", Vector3(0, 2.35, -0.3), 26)
	for i in range(3):
		var button := WorkshopButton.new()
		button.position = Vector3(-1 + i, 0.9, 1.4)
		button.collision_layer = (1 << 20) | (1 << 22)
		button.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.85, 0.18, 0.08)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		button.add_child(collision)
		box(shape.size, Vector3.ZERO, Color("9f6886"), button)
		var title := label(["NEXT", "ORDER", "RESET"][i], Vector3(0, 0, 0.06), 24)
		title.reparent(button, false)
		button.action = [advance, change_order, reset][i]
		add_child(button)
		controls.append(button)
	reset()

func body(mesh: Mesh, at: Vector3, colour: Color, parent: Node = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.65
	node.material_override = material
	(parent if parent != null else self).add_child(node)
	return node

func box(size: Vector3, at: Vector3, colour: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return body(mesh, at, colour, parent)

func label(words: String, at: Vector3, size: int) -> Label3D:
	var node := Label3D.new()
	node.text = words
	node.position = at
	node.font_size = size
	node.pixel_size = 0.0025
	add_child(node)
	return node

func new_rod(colour: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.022
	mesh.bottom_radius = 0.022
	return body(mesh, Vector3.ZERO, colour)

func connect_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	node.visible = delta.length() > 0.001
	if node.visible:
		node.mesh.height = delta.length()
		node.position = (a + b) * 0.5
		node.quaternion = Quaternion(Vector3.UP, delta.normalized())

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - Vector3.UP * 0.6
		places[0] = Vector3(local.x, 1, local.z)
	else:
		point.position = places[0] + Vector3.UP * 0.6
	redraw()

func redraw() -> void:
	for i in range(4):
		figures[i].position = places[i]
		labels[i].position = places[i] + Vector3(0, 0.78, 0)
		labels[i].text = NAMES[i] + (" / free" if model.mate[i] == -1 else " / paired %d" % model.mate[i])
	for i in range(model.links.size()):
		var edge: Array = model.links[i]
		connect_rod(rods[i], places[edge[0]], places[edge[1]])
		rods[i].material_override.albedo_color = Color("e6b260") if model.mate[edge[0]] == edge[1] else Color("88aaa9")
	cancelled.hide()
	if not model.removed.is_empty():
		var edge: Array = model.removed[0]
		connect_rod(cancelled, places[edge[0]] + Vector3.UP * 0.25, places[edge[1]] + Vector3.UP * 0.25)
	caption.text = "TWO MAKERS / TWO TOOLS\n%d pairs / %s order" % [model.size(), "reverse" if reverse_order else "listed"]
	caption.text += "\nNext: greedy scan." if phase == 0 else ("\nNo augmenting path remains." if model.done else "\nNext: find and flip an alternating path.")
	caption.text += "\nPair-count history: " + str(history)
	caption.text += "\nTrigger / 1: next. O: order. R: reset after release."

func advance() -> void:
	if phase == 0:
		model.greedy(reverse_order)
		phase = 1
	else:
		model.augment()
	if history.back() != model.size():
		history.append(model.size())
	redraw()

func reset() -> void:
	if point.held():
		return
	model.reset()
	places = INITIAL.duplicate()
	phase = 0
	history = [0]
	redraw()

func change_order() -> void:
	if point.held():
		return
	reverse_order = not reverse_order
	reset()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_O:
			change_order()
		elif event.keycode == KEY_R:
			reset()
```

</details>

NEXT or `1` first runs the greedy scan, then searches for one augmentation per press. ORDER or `O` changes the scan order and resets. RESET or `R` clears the pairing after the point is released. The displayed history is only the pair count after changes: `[0, 1, 2]`; it is not a recording of the whole workshop state.

The familiar black sphere is a handle above maker A. Grab it to move that figure in the table's local XZ plane. Its place changes; permitted pairs do not. The held trigger calls NEXT. On release, the same point stays with the same figure. We reuse pickup/release rather than teaching it again.

<details>
<summary>Unchanged files carried from Flow — complete dependencies</summary>

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

## Change one condition yourself

In a separate copy, replace the link `[0, 3]` with `[1, 3]`. Predict both scan orders before running them. The listed order now finds two pairs directly. The reversed order first takes `1–2` and leaves A waiting; augmentation follows `[0, 2, 1, 3]` and restores two pairs. Explain why moving a figure would not have changed this requirement. Only editing the relation changes the available partnerships.

The workshop's fixed four-role drawing is not a general graph editor. The model can accept larger consecutive disjoint sets, but a larger scene needs corresponding figures and links. We test that distinction instead of promising a display that automatically adapts to every input.

## Compare the other things in the room

The larger ring-and-spokes exhibit uses an odd cycle and a greedy scan. CYCLE FIRST gives three pairs; SPOKES FIRST gives five on the same ten vertices and ten edges. Its order button restarts the scan. It does not implement the alternating-path repair above, and its general graph cannot be fed unchanged into our bipartite model. Full blossom handling, weighted assignment and preference-based matching are further subjects.

The **Ada relations** model is a companion for reading the project. VIEW separates the spine's recommended order, declared dependencies, concept returns, shared artifact tokens and selected dated review milestones. PREVIOUS/NEXT selects a sequence; HALLS/ALL shows its rooms. These relationships are many-to-many. A sequence may depend on several others; a concept may return repeatedly. They are not pairings with an exclusivity rule.

Read the source ledger beside that model. Plan declarations are not evidence that a learner has mastered a subject. Shared tokens do not establish shared live state. Dates name selected saved review folders, not the first invention of an idea. The graph lets us inspect our chosen account of Ada; it does not complete that account.

The next sequence, Foundations Crisis, asks what a procedure's success entitles us to claim. Carry this distinction: a valid pairing, a largest collection and a good arrangement for the people are three different questions.

Algorithm reference: [Princeton Algorithms: bipartite matching](https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/BipartiteMatching.html). The GDScript above uses the route finder already built in Ada; it is not Princeton's implementation.
