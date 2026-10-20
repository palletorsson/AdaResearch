# Layout — move the drawing, keep the graph

## Learning elements

- Vertex identity and adjacency, separate from position
- Springs along edges; repulsion between every pair
- Velocity, damping and a shared simulation step
- A held point pins one vertex; release resumes its motion

## In this hall

Watch the existing blue graph move. Choose an edge and follow both ends. It can stretch without connecting different vertices. The museum exhibit has eight vertices and twelve edges, the connectivity of a cube. Our smaller reconstruction continues the **seven-vertex graph from Foundations**, with exactly the same neighbour lists and the same PointBody. We change its drawing.

The point was a step control. Here it becomes vertex 0. Hold it and move your hand: its connected neighbours respond. Release it and the point joins the motion. Nearness alone never adds an edge.

## Continue the student's object

Work inside the existing Endless Museum project, with the supplied desktop or XR player. Keep `traversal.gd` and `point_body.gd` unchanged from Foundations. Restore the original neighbour order if you changed it for that lesson's exercise. Add `layout.gd` beside them and replace the learner's `study.gd` with the complete host below. These are separate files, each with one responsibility.

Attach `study.gd` to one empty Node3D in GT_Layout's left learner bay. The saved `study.tscn` does only this. For the reviewed placement use map-local position **(4.5, -0.45, 4.5)** and Y rotation **180 degrees**. The small downward offset puts the initial point within reach. In the isolated museum the hall root starts four metres before map zero: its equivalent root-local position is (4.5, -0.45, 8.5). Keep scale at 1. The hall supplies camera, lighting and hands; the script creates its own graph, labels and point.

The new operation is `layout.gd`. The complete display and input host follows it. The two carried files are included at the end so the example can be reconstructed without hidden scene children.

## One graph, another record

`neighbours[0]` still contains `[1, 2]`. A second list, `positions`, says where to draw each ID. Entry 0 can move while the two neighbour IDs stay the same. `velocities` is another parallel list: entry 0 records how that drawn vertex is moving.

Every pair repels. Only a listed edge acts as a spring. The spring compares its present length with `rest_length`: a stretched spring pulls; a compressed one pushes. `a < b` counts a reciprocal connection once, and equal opposite forces go to its two ends. These are forces chosen to arrange a diagram. An edge in another kind of network need not describe a physical spring.

<!-- student-code:layout.gd -->
```gdscript
extends RefCounted

var positions: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var velocities: Array[Vector3] = []
var spring := 2.0
var rest_length := 0.65
var repulsion := 0.03
var damping := 3.0

func _init() -> void:
	for unused in positions:
		velocities.append(Vector3.ZERO)

func forces(neighbours: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for unused in positions:
		result.append(Vector3.ZERO)
	# Every pair repels. A minimum distance limits near-contact force.
	for a in range(positions.size()):
		for b in range(a + 1, positions.size()):
			var offset := positions[b] - positions[a]
			var distance := maxf(offset.length(), 0.1)
			var push := offset.normalized() * repulsion / (distance * distance)
			result[a] -= push
			result[b] += push
	# Only listed connections act as springs; count each undirected edge once.
	for a in range(neighbours.size()):
		for b: int in neighbours[a]:
			if a < b:
				var offset := positions[b] - positions[a]
				var pull := offset.normalized() * spring * (offset.length() - rest_length)
				result[a] += pull
				result[b] -= pull
	return result

func step(delta: float, neighbours: Array, pinned: int = -1) -> void:
	# All forces read the same positions before any position is advanced.
	var current := forces(neighbours)
	for vertex in range(positions.size()):
		if vertex == pinned:
			velocities[vertex] = Vector3.ZERO
			continue
		velocities[vertex] += current[vertex] * delta
		velocities[vertex] *= exp(-damping * delta)
		velocities[vertex] = velocities[vertex].limit_length(2.0)
		positions[vertex] += velocities[vertex] * delta
```

`forces()` reads all positions and returns a fresh force list. Only then does `step()` change velocities and positions. Updating positions inside the force calculation would let later vertices react to an already changed world.

The model uses unit mass. Force changes velocity by `force * delta`; velocity changes position by `velocity * delta`. Damping multiplies velocity by `exp(-damping * delta)`, so its strength is expressed per second. The force calculation still advances in discrete physics steps: this is not a guarantee of an exact or unique equilibrium. The speed limit and minimum repulsion distance keep this small study manageable. At exact coincidence a zero direction cannot push two vertices apart; start them at distinct positions.

A pinned vertex skips the integration and has zero velocity. Its position still participates in every force calculation, so its neighbours feel the move. No neighbour list is written by the layout.

## Give the drawing a body

The host keeps the earlier spheres, numbers and thin cylinders. Now `redraw()` updates **both** ends of each cylinder every physics step. Its `ends` list stores IDs, not copied coordinates. The display can therefore follow the motion without guessing which vertices should be connected.

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Traversal = preload("traversal.gd")
const Layout = preload("layout.gd")
const PointBody = preload("point_body.gd")
var graph = Traversal.new()
var drawing = Layout.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var numbers: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var ends: Array = []
var running := true

func _ready() -> void:
	for vertex in range(drawing.positions.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.material_override = finish(Color("54bce8"))
		lamp.visible = vertex != 0 # The carried point itself shows vertex zero.
		add_child(lamp)
		lamps.append(lamp)
		var number := Label3D.new()
		number.text = str(vertex)
		number.font_size = 40
		number.pixel_size = 0.002
		add_child(number)
		numbers.append(number)
	for a in range(graph.neighbours.size()):
		for b: int in graph.neighbours[a]:
			if a < b:
				var rod := MeshInstance3D.new()
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.008
				cylinder.bottom_radius = 0.008
				rod.mesh = cylinder
				rod.material_override = finish(Color("6c7280"))
				add_child(rod)
				rods.append(rod)
				ends.append([a, b])
	add_child(point)
	point.action_pressed.connect(func(_source): toggle())
	caption.position = Vector3(0, 3.25, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	refresh_caption()
	redraw()

func _physics_process(delta: float) -> void:
	var pinned := -1
	if point.held():
		# Hand is in world space. This drawing uses the host's local XY plane.
		var hand := to_local(point.global_position)
		drawing.positions[0] = Vector3(hand.x, hand.y, 0)
		drawing.velocities[0] = Vector3.ZERO
		pinned = 0
	if running:
		drawing.step(delta, graph.neighbours, pinned)
	redraw()

func redraw() -> void:
	lamps[0].visible = point.held() # Show the planar projection while the hand is off-plane.
	for vertex in range(lamps.size()):
		lamps[vertex].position = drawing.positions[vertex]
		numbers[vertex].position = drawing.positions[vertex] + Vector3(0, 0.14, 0.08)
	if not point.held():
		point.position = drawing.positions[0]
	for index in range(rods.size()):
		var a: Vector3 = drawing.positions[ends[index][0]]
		var b: Vector3 = drawing.positions[ends[index][1]]
		var offset := b - a
		rods[index].visible = offset.length() > 0.001
		rods[index].mesh.height = maxf(offset.length(), 0.001)
		rods[index].position = (a + b) * 0.5
		if rods[index].visible:
			rods[index].quaternion = Quaternion(Vector3.UP, offset.normalized())

func visit_order(breadth: bool) -> Array[int]:
	graph.restart(breadth)
	while graph.next_visit() != -1:
		pass
	return graph.visited.duplicate()

func refresh_caption() -> void:
	caption.text = "MOVING DRAWING" if running else "PAUSED DRAWING"
	caption.text += "\nQueue: " + str(visit_order(true))
	caption.text += "\nStack: " + str(visit_order(false))
	caption.text += "\nHold black point: move vertex 0 in this plane"
	caption.text += "\nTrigger / 1: pause or resume    R: reset drawing"

func toggle() -> void:
	running = not running
	refresh_caption()

func restart() -> void:
	drawing = Layout.new()
	running = true
	refresh_caption()
	redraw()

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.6
	return material

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			toggle()
		elif event.keycode == KEY_R:
			restart()
```

The hand arrives in world coordinates. `to_local()` brings it into this study's frame. Setting Z to zero projects the movement onto the drawing's XY plane. While you hold the point, a blue marker shows that projected vertex; your black point can be in front of the plane. On release the black point returns to the projected position and continues with the simulation. This is a planar layout, not a new three-dimensional graph.

Trigger or keyboard **1** pauses/resumes the simulation. You can still reposition vertex 0 while paused. **R** resets only the drawing and its velocities; release the point first if you want to see the initial arrangement. The queue and stack readouts use the previous lesson's traversal. Their orders remain unchanged as the drawing moves.

## Try, predict, explain

1. Follow edge 0–1 while pulling the point sideways. Predict which two vertices have direct springs to 0. Check the unchanged list `[1, 2]`; every other vertex can still respond through repulsion or through the rest of the graph.
2. Pause, move the point, and inspect the stretched cylinders. Explain why an unconnected neighbour on the screen has not gained an edge. Resume and release.
3. Change only `rest_length` from **0.65 to 0.9** in `layout.gd` and restart from the same positions. A longer rest length reduces a stretched spring's pull at the same separation, or increases its push if compressed. Expect a more spread-out drawing in this example. It is not an instruction to make every edge exactly 0.9: repulsion also acts. Predict that both visit orders remain identical, then check them.

You should still read queue **0,1,2,3,4,5,6** and stack **0,1,3,4,2,5,6**. The runnable checks also compare average edge length after the same number of simulation steps, so the independent edit tests a visible consequence rather than merely compiling.

## Carried files — unchanged

`traversal.gd` retains vertex identities, adjacency and the queue/stack procedure. It never reads `positions`.

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

`point_body.gd` is the same pickable point. XRTools supplies grabbing; the museum supplies the pickup function. This lesson connects the inherited action signal and reads `held()` rather than rebuilding that interaction.

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

## What travels onward

Carry the point, the neighbour lists and this distinction: **a drawing can change while its routes remain available**. In Pathfinding, making a vertex or connection unavailable can change the route itself. A new position alone did not do that here.
