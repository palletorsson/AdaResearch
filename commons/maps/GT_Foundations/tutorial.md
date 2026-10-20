# Two orders, the same connections

## Learning elements

- Vertex identifiers.
- Adjacency lists: which vertices are neighbours.
- Queue and stack: which pending entry comes next.
- Visited state: a vertex is visited once.
- Breadth-first and depth-first visit order.

**Carry:** the grabbable PointBody, arrays, loops, conditions and signals. **New work:** a record of connections and a procedure that visits it. **Supplied:** the museum, XR hands, and the small numbered lamp display printed below.

## Encounter

Find the fifteen lamps of *Two Travellers* in GT_Foundations. The blue tide spreads through a layer; the orange diver follows a branch. Choose a lamp and watch how long it waits under each rule. These are visits being replayed, not a body walking continuously along the rods.

We will reconstruct that choice with seven lamps, small enough to follow by hand. The installed exhibit records children in a fifteen-vertex tree. Our seven-vertex tree records each connection in both directions. The visiting rule is the same; the graph is deliberately smaller.

## Record what can follow

In Trace, an array kept positions. Here an array keeps **neighbours**. A vertex's ID is its row number, starting at zero. Row 1 contains `[0, 3, 4]`: from vertex 1, these three vertices are connected. No distance calculation decides this. The display keeps its positions separately.

Create `traversal.gd`. This is the complete new operation:

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

`restart()` puts vertex 0 in `pending` and clears the visit record. `next_visit()` removes one candidate. A queue takes the first entry with `pop_front()`; a stack takes the last with `pop_back()`. Both add new candidates at the end with `append()`.

The selected vertex enters `visited`, and its unvisited neighbours enter `pending`. The function returns its ID so the display can light that lamp. For the stack we reverse a **copy** of the neighbours: adding 2 before 1 lets 1 come off the stack first. The stored connections stay unchanged.

Because connections go both ways, the procedure must recognise a vertex it has already visited. On a graph with a cycle, a candidate can also reach `pending` more than once. The `while` and `continue` skip those repeats before returning the next new visit. An empty list returns `-1`, meaning there is no reachable vertex left to visit from this start.

## Put it in the museum

Keep these three scripts together. Attach `study.gd` to one empty Node3D, or instance the supplied `study.tscn`, under the GT_Foundations hall. Use the study bay on the opposite side from the travellers: map-local position `(3.5, 0, 4.5)`, rotation Y `180°`, scale 1. In an isolated museum run, the hall root includes a four-metre entrance vestibule: the corresponding position relative to that root is `(3.5, 0, 8.5)`. The downloaded study contains no camera, light or player; the existing Endless Museum supplies them. The native review capture tests this placement.

The host builds seven numbered lamps and six rods from the supplied drawing positions. It connects the carried point's trigger to `advance()`. All scene objects and the label are initialized here; there are no hidden child-node references.

<details>
<summary>Complete display and input host — study.gd</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Traversal = preload("traversal.gd")
const PointBody = preload("point_body.gd")
const PARK := Vector3(0, 0.85, 0.65)
const TIDE := Color("54bce8")
const DIVER := Color("efa252")
const NEUTRAL := Color("6c7280")
var graph = Traversal.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var places: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var current := -1
var finished := false

func _ready() -> void:
	for vertex in range(places.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.position = places[vertex]
		lamp.material_override = finish(NEUTRAL)
		add_child(lamp)
		lamps.append(lamp)
		var number := Label3D.new()
		number.text = str(vertex)
		number.position = places[vertex] + Vector3(0, 0.14, 0.08)
		number.font_size = 40
		number.pixel_size = 0.002
		add_child(number)
	for a in range(graph.neighbours.size()):
		for b: int in graph.neighbours[a]:
			if a < b:
				draw_edge(places[a], places[b])
	point.position = PARK
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 32
	caption.pixel_size = 0.002
	add_child(caption)
	restart(true)

func _process(_delta: float) -> void:
	if not point.held():
		point.position = PARK

func restart(use_queue: bool) -> void:
	graph.restart(use_queue)
	current = -1
	finished = false
	refresh()

func advance() -> void:
	if finished:
		restart(not graph.breadth)
		return
	current = graph.next_visit()
	finished = current == -1 or graph.visited.size() == places.size()
	refresh()

func refresh() -> void:
	var tint := TIDE if graph.breadth else DIVER
	for vertex in range(lamps.size()):
		var material: StandardMaterial3D = lamps[vertex].material_override
		material.albedo_color = tint if vertex in graph.visited else NEUTRAL
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.8 if vertex == current else 0.15
	var method := "QUEUE / take left" if graph.breadth else "STACK / take right"
	caption.text = method + "\nVisited: " + str(graph.visited)
	caption.text += "\nPending: " + str(graph.pending)
	caption.text += "\nTrigger / 1: " + ("other order" if finished else "one visit")
	caption.text += "    2: switch    R: restart"

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.15
	material.roughness = 0.6
	return material

func draw_edge(a: Vector3, b: Vector3) -> void:
	var rod := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = a.distance_to(b)
	rod.mesh = cylinder
	rod.position = (a + b) * 0.5
	rod.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	rod.material_override = finish(NEUTRAL)
	add_child(rod)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_2:
			restart(not graph.breadth)
		elif event.keycode == KEY_R:
			restart(graph.breadth)
```

</details>

<details>
<summary>Carried unchanged — point_body.gd</summary>

This is the same small PointBody used through Soft Bodies. It provides pickup, release and the inherited action signal. It controls the study; moving the point does not change an edge or a vertex position.

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

Hold the black point and press its trigger once. One lamp is visited. Release returns the point to its place and keeps the current visit record. The desktop equivalent is **1**. After the seventh visit, another press prepares the other order; the following press starts its visits. **2** switches and restarts immediately; **R** restarts the current order.

Predict the third visit before advancing. Compare the pending list with the lamps:

| Rule | Visit order from 0 |
| --- | --- |
| Queue / breadth-first | 0, 1, 2, 3, 4, 5, 6 |
| Stack / depth-first | 0, 1, 3, 4, 2, 5, 6 |

Both reach the same seven vertices. Breadth-first visits them in layers of edge distance from 0 in this unweighted graph. Depth-first follows the first available branch before taking the waiting alternative. Neither rule consults the lamps' coordinates.

## Change one decision

In `neighbours`, change **only row 0** from `[1, 2]` to `[2, 1]`. Predict both orders before running. The same two neighbours remain connected, but their consideration order changes. The queue should begin `0, 2, 1`; the stack should begin `0, 2, 5, 6`. Explain why both now favour the right branch without moving a lamp or adding an edge.

Restore `[1, 2]` before the next hall. Keep `neighbours`, `pending` and `visited` distinct. In Layout we will move the drawing while keeping the vertex IDs and connections: a shorter-looking rod need not be a new connection.

The bridge model is a separate encounter. Crossing every **edge** once is a different question from visiting every reachable **vertex** once; we do not combine those lessons here.

## Check the reconstruction

Run `python tools/test_graph_foundations.py` from the AdaResearch project. It extracts the exact printed scripts, checks the two predicted orders, the independent row edit, cycles and disconnected vertices, then exercises keyboard and XRTools pickup/action/release. The review report contains its receipt. This is an executable author-operated reconstruction; headset comfort and a new reader's understanding still require people.

API reference: [Godot Array](https://docs.godotengine.org/en/stable/classes/class_array.html) for the three list operations; [Godot Quaternion](https://docs.godotengine.org/en/stable/classes/class_quaternion.html) for the supplied rod orientation. The host's drawing code is available to inspect, but the lesson's new work is choosing the next pending vertex.
