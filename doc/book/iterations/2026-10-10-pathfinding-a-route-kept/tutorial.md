# Pathfinding — keep the way back

## Learning elements

- Breadth-first search with a goal
- A predecessor record for each discovered vertex
- Reconstructing a route, distinct from search order
- Availability, detours and an explicit no-route result

## The river and the point

Watch the spark cross the museum river. Press its button and a stone on the route sinks. The exhibit asks for a new route immediately. If one exists, the spark starts again at a bank; otherwise it stops where it is. The stones supply the graph; their availability changes what the search can use. The little maze elsewhere in the room is a supporting encounter. We will build one route-finding operation here.

Keep our seven vertices and the point. In Layout, we changed the drawing without changing adjacency. Here we keep the drawing still and change **which vertices are available**. Our point becomes the traveller. Holding it pauses its journey; its trigger changes the available options. Releasing it returns it to the recorded journey.

There is one necessary addition. Our earlier graph was a tree: each pair of vertices had only one simple route between them. A detour requires another connection. Add the reciprocal edge **4–5**, keeping every previous vertex and edge. This is a deliberate change in the relation record, not a consequence of two drawn points being close.

## Continue inside the museum

Keep `traversal.gd` and `point_body.gd` unchanged from Layout. Add `route.gd` beside them and use the complete `study.gd` below. The layout simulation is set aside for this lesson; the initial coordinates return as a fixed drawing. Save the four scripts together and attach `study.gd` to one empty Node3D. The supplied `study.tscn` contains just this node. The museum project supplies camera, lighting, player and XRTools.

The reviewed learner bay is at **map-local (3.5, -0.25, 5.5), Y rotation 180 degrees, scale 1**. In the isolated museum its hall-root position is (3.5, -0.25, 9.5), because map zero starts four metres after that root. The permanent river is already in the right bay. Add one instance of the learner study in the left bay; do not replace the river or rebuild the player.

## What a search must remember

Our earlier queue answered: which vertex should be visited next? Now it also records **from which vertex each new discovery was reached**. `predecessor[2] = 0` means that this search first discovered 2 from 0. It is not a second adjacency list: it keeps only the discovery relation needed to recover this route.

`route.gd` extends our unchanged traversal file, so it already has `neighbours`, `pending`, `visited` and `restart()`. Its constructor adds 4–5 in both directions. `find_path()` clears old search state each time, refuses a blocked endpoint, and uses the same queue rule: take the oldest pending ID.

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

The predecessor record also marks discovery. We set it **when adding a vertex to the queue**, so another connection cannot add that vertex again or replace its first predecessor. This matters now that 4–5 creates a cycle. `visited` records vertices actually taken from the queue; it can contain branches the eventual traveller does not use.

Every edge has the same cost here. The queue reaches vertices in increasing numbers of edges from the start, so the first discovery gives a route with the fewest edges. This does not promise the shortest physical distance. The search never reads coordinates.

When the goal has a predecessor record, follow it backwards until the start's sentinel value `-1`. `push_front()` places those IDs in start-to-goal order. If the goal was never discovered, return an empty list. Looking up an absent goal would be a code error; **NO ROUTE** is a valid result.

## Three outcomes on the same drawing

We travel from **3 to 6**. Before running, trace these outcomes with your finger:

| Unavailable vertices | Returned route | Edges |
| --- | --- | --- |
| None | 3 → 1 → 0 → 2 → 6 | 4 |
| 0 | 3 → 1 → 4 → 5 → 2 → 6 | 5 |
| 0 and 4 | No route | — |

The original adjacency stays stored. A separate `blocked` list filters the search. Restoring availability therefore needs no rebuilding of the graph. A route is a result for those conditions: when they change, we search again.

## Let the point follow the result

This complete host continues the familiar numbered spheres and cylinders. Gold cylinders show the chosen route. Blocked vertices turn pink and their incident rods disappear; the underlying connection record is retained. The black point travels just in front of the rods so it remains visible.

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Route = preload("route.gd")
const PointBody = preload("point_body.gd")
const START := 3
const GOAL := 6
const NEUTRAL := Color("6c7280")
const OPEN := Color("54bce8")
const PATH := Color("f4c878")
const CLOSED := Color("d66079")
const FRONT := Vector3(0, 0, 0.14)
const PARK := Vector3(0, 0.8, 0.5)
var graph = Route.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var rods: Array[MeshInstance3D] = []
var ends: Array = []
var places: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var blocked: Array[int] = []
var path: Array[int] = []
var phase := 0
var leg := 0
var cursor := Vector3.ZERO

func _ready() -> void:
	for vertex in range(places.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.position = places[vertex]
		lamp.material_override = finish(OPEN)
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
				var rod := MeshInstance3D.new()
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.008
				cylinder.bottom_radius = 0.008
				cylinder.height = places[a].distance_to(places[b])
				rod.mesh = cylinder
				rod.position = (places[a] + places[b]) * 0.5
				rod.quaternion = Quaternion(Vector3.UP, (places[b] - places[a]).normalized())
				rod.material_override = finish(NEUTRAL)
				add_child(rod)
				rods.append(rod)
				ends.append([a, b])
	add_child(point)
	point.action_pressed.connect(func(_source): change_availability())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	replan()

func change_availability() -> void:
	phase = (phase + 1) % 3
	blocked.clear()
	if phase >= 1:
		blocked.append(0)
	if phase == 2:
		blocked.append(4)
	replan()

func replan() -> void:
	path = graph.find_path(START, GOAL, blocked)
	leg = 0
	cursor = PARK if path.is_empty() else places[path[0]] + FRONT
	if not point.held():
		point.position = cursor
	for vertex in range(lamps.size()):
		lamps[vertex].material_override.albedo_color = CLOSED if vertex in blocked else OPEN
	for i in range(rods.size()):
		var a: int = ends[i][0]
		var b: int = ends[i][1]
		rods[i].visible = a not in blocked and b not in blocked
		var on_path := false
		for step in range(path.size() - 1):
			on_path = on_path or (a == path[step] and b == path[step + 1]) or (b == path[step] and a == path[step + 1])
		rods[i].material_override.albedo_color = PATH if on_path else NEUTRAL
	caption.text = "FROM %d TO %d / blocked: %s" % [START, GOAL, str(blocked)]
	caption.text += "\nRoute: " + ("NO ROUTE" if path.is_empty() else str(path))
	caption.text += "\nSearch visited: " + str(graph.visited)
	caption.text += "\nTrigger / 1: block 0, then 4, then restore"
	caption.text += "\nHold: pause traveller    R: replay this route"

func _process(delta: float) -> void:
	if point.held():
		return
	if leg < path.size() - 1:
		var target := places[path[leg + 1]] + FRONT
		cursor = cursor.move_toward(target, 0.55 * delta)
		if cursor.is_equal_approx(target):
			leg += 1
	point.position = cursor

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.6
	return material

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			change_availability()
		elif event.keycode == KEY_R:
			replan()
```

The host searches to completion before the point moves. The readout separates **Route** from **Search visited**. The animation plays the answer; it is not a display of the search running one step at a time.

Trigger or **1** cycles through blocking 0, blocking 0 and 4, and restoring both. Each change replans from 3 and starts a new journey. **R** replays the current route without changing availability. Holding the point pauses its cursor; on release it returns to that cursor. If you change availability while holding it, release starts the newly computed journey instead. With no route it waits in the small parking position, where it remains pickable for the next action.

## Change something the code depends on

Remove the two append lines in `route.gd` that add 4–5, leaving `pass` as the body of `_init()`. Predict before running: the initial route remains 3, 1, 0, 2, 6, but blocking 0 now gives **NO ROUTE**. You removed the detour itself. Restore the two lines afterwards.

Then inspect the normal search's predecessor record. Recover the route by hand, starting at 6. Explain why a vertex in `visited` can be absent from `path`. You have learned more than making a sphere move: you can say which stored relation made its journey possible and why another attempt fails.

## Carried files — unchanged

`traversal.gd` provides the original graph and traversal state. The route subclass adds to this existing construction rather than introducing an unrelated Graph class.

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

`point_body.gd` still supplies the same pickable point. The new host connects its inherited trigger and uses its existing held state.

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

## What the larger exhibit adds

The river uses Godot's `AStar3D`, with a seeded arrangement of stones and links based on proximity. That default search minimises summed Euclidean segment lengths, whereas our queue minimises the number of edges. The river's displayed stone count describes the returned route; it is not the search's optimisation rule. We have rebuilt the availability-and-route question with a smaller cost model, not claimed to reproduce A* here. [Godot AStar3D documentation](https://docs.godotengine.org/en/stable/classes/class_astar3d.html)

Carry the graph, availability record and predecessor chain onward. Network Analysis will ask what a vertex's relationships permit across the graph, beyond the single journey we just requested.
