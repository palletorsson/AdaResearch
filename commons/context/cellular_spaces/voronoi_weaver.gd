extends Node3D
## A stylised spider traces a precomputed Voronoi graph, laying one strand at
## a time and returning along completed strands. This is a construction
## illustration, not biological web growth. The completed graph is then released
## into the host's cable tension simulation.

signal completed

var speed: float = 2.0
var paused: bool = false
var finished: bool = false
var laid_count: int = 0
var route: Array[Vector3i] = [] # from vertex, to vertex, segment index
var segments: Array[Vector2i] = []
var step_index: int = 0
var step_distance: float = 0.0
var spider: Node3D
var _web: Node3D
var _batches: Array[MultiMesh] = []
var _original: Array[Transform3D] = []
var _laid := PackedByteArray()
var _knotted := PackedByteArray()
var _counts := Vector2i.ZERO
var _knots: MultiMesh
var _active: MeshInstance3D
var _legs: MultiMesh
var _gait: float = 0.0

func setup(web: Node3D) -> void:
	_web = web
	speed = web.weave_speed
	segments.assign(web.edges)
	segments.append_array(web.tethers)
	for label in ["CellEdges", "AnchorCords"]:
		_batches.append(web.generated.get_node(label).multimesh)
	for edge in segments:
		_original.append(web.strand_transform(web.vertices[edge.x], web.vertices[edge.y]))
	_knots = web.generated.get_node("Knots").multimesh
	_make_route()
	_make_spider()
	_active = MeshInstance3D.new()
	_active.name = "FreshSilk"
	_active.mesh = _batches[0].mesh
	_active.material_override = web.generated.get_node("CellEdges").material_override
	add_child(_active)
	restart()

func _make_route() -> void:
	var adjacency: Array = []
	adjacency.resize(_web.vertices.size())
	for i in range(adjacency.size()):
		adjacency[i] = []
	for i in range(segments.size()):
		adjacency[segments[i].x].append(i)
		adjacency[segments[i].y].append(i)
	var visited := PackedByteArray()
	visited.resize(segments.size())
	# Start at a real anchor. Iterative DFS avoids a recursion limit on dense
	# cells and makes every return trip follow a strand already laid.
	if segments.is_empty():
		return
	var first: int = int(_web.anchor_kinds.keys()[0]) if not _web.anchor_kinds.is_empty() else segments[0].x
	var stack: Array[Vector2i] = [Vector2i(first, -1)]
	while not stack.is_empty():
		var vertex: int = stack.back().x
		var next := -1
		for candidate: int in adjacency[vertex]:
			if not visited[candidate]:
				next = candidate
				break
		if next >= 0:
			visited[next] = 1
			var edge := segments[next]
			var destination := edge.y if edge.x == vertex else edge.x
			route.append(Vector3i(vertex, destination, next))
			stack.append(Vector2i(destination, next))
		else:
			var previous: Vector2i = stack.pop_back()
			if not stack.is_empty():
				route.append(Vector3i(vertex, stack.back().x, previous.y))
	# The generator retains a single connected net. Every strand is reachable
	# here; Finish reveals exactly the same graph, with no detached extras.

## Clear the silk and restart the same connected construction route.
func restart() -> void:
	_web.reset_tension()
	_laid.resize(segments.size())
	_laid.fill(0)
	_knotted.resize(_knots.instance_count)
	_knotted.fill(0)
	_counts = Vector2i.ZERO
	for batch in _batches:
		batch.visible_instance_count = 0
	_knots.visible_instance_count = 0
	laid_count = 0
	step_index = 0
	step_distance = 0.0
	_gait = 0.0
	paused = false
	finished = route.is_empty()
	spider.visible = not finished
	_active.visible = false
	set_process(not finished)
	if not finished:
		_show_knot(route[0].x)
		_pose()

## Show the full mathematical structure immediately and let the spider rest.
func finish() -> void:
	for i in range(segments.size()):
		_commit(i)
	for i in range(_knotted.size()):
		_show_knot(i)
	step_index = route.size()
	_active.visible = false
	finished = true
	paused = false
	follow_knots()
	set_process(false)
	completed.emit()

func _process(delta: float) -> void:
	advance(delta)

## Advance in seconds; the same path is used by playback and deterministic QA.
func advance(delta: float) -> void:
	if paused or finished or delta <= 0:
		return
	var remaining := delta * maxf(speed, 0.01)
	while remaining > 0 and step_index < route.size():
		var step := route[step_index]
		var length: float = _web.vertices[step.x].distance_to(_web.vertices[step.y])
		var distance := minf(remaining, maxf(0.0, length - step_distance))
		step_distance += distance
		_gait += distance * 15.0
		remaining -= distance
		if step_distance >= length - 0.000001:
			_commit(step.z)
			_show_knot(step.y)
			spider.position = _web.vertices[step.y]
			step_index += 1
			step_distance = 0
		else:
			break
	if step_index == route.size():
		finished = true
		follow_knots()
		_active.visible = false
		set_process(false)
		completed.emit()
	else:
		_pose()

## Rest at the starting anchor when construction ends; it remains attached as
## the net relaxes. Finish skips the remaining traversal back to this anchor.
func follow_knots() -> void:
	if finished and not route.is_empty():
		spider.position = _web.vertices[route[0].x]

func _commit(index: int) -> void:
	if _laid[index]:
		return
	_laid[index] = 1
	laid_count += 1
	var group := 0 if index < _web.edges.size() else 1
	var batch := _batches[group]
	batch.set_instance_transform(_counts[group], _original[index])
	_counts[group] += 1
	batch.visible_instance_count = _counts[group]

func _show_knot(index: int) -> void:
	if _knotted[index]:
		return
	_knotted[index] = 1
	var count := _knots.visible_instance_count
	_knots.set_instance_transform(count, Transform3D(Basis.IDENTITY, _web.vertices[index]))
	_knots.visible_instance_count = count + 1

func _pose() -> void:
	var step := route[step_index]
	var a: Vector3 = _web.vertices[step.x]
	var b: Vector3 = _web.vertices[step.y]
	var direction := (b - a).normalized()
	var tip := a + direction * step_distance
	spider.position = tip # spinneret stays at the growing end of the silk
	var up := spider.basis.y
	if absf(direction.dot(up)) > 0.95:
		up = Vector3.RIGHT if absf(direction.x) < 0.9 else Vector3.UP
	spider.basis = Basis.looking_at(direction, up)
	var is_cord: bool = step.z >= _web.edges.size()
	_active.visible = not _laid[step.z] and step_distance > 0.0001 and (not is_cord or _web.generated.get_node("AnchorCords").visible)
	if _active.visible:
		_active.transform = _line_transform(a, tip, 0.65 if is_cord else 1.0)
	_animate_legs()

func _line_transform(a: Vector3, b: Vector3, width: float = 1.0) -> Transform3D:
	var direction := (b - a).normalized()
	var reference := Vector3.RIGHT if absf(direction.y) > 0.9 else Vector3.UP
	var side := reference.cross(direction).normalized()
	return Transform3D(Basis(side * width, direction * a.distance_to(b), side.cross(direction) * width), (a + b) * 0.5)

func _make_spider() -> void:
	spider = Node3D.new()
	spider.name = "Spider"
	add_child(spider)
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color("b96731")
	shell.metallic = 0.2
	shell.roughness = 0.45
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("332322")
	dark.roughness = 0.65
	_body_part("Abdomen", Vector3(0, 0.10, -0.14), Vector3(0.15, 0.12, 0.20), shell)
	_body_part("Cephalothorax", Vector3(0, 0.09, -0.39), Vector3(0.105, 0.08, 0.12), shell)
	for side in [-1, 1]:
		_body_part("Eye", Vector3(side * 0.043, 0.12, -0.49), Vector3.ONE * 0.026, dark)
	var leg_mesh := CylinderMesh.new()
	leg_mesh.height = 1
	leg_mesh.top_radius = 0.010
	leg_mesh.bottom_radius = 0.016
	leg_mesh.radial_segments = 6
	leg_mesh.rings = 1
	_legs = MultiMesh.new()
	_legs.transform_format = MultiMesh.TRANSFORM_3D
	_legs.mesh = leg_mesh
	_legs.instance_count = 24 # eight legs, three articulated pieces each
	var legs := MultiMeshInstance3D.new()
	legs.name = "EightLegs"
	legs.multimesh = _legs
	legs.material_override = dark
	spider.add_child(legs)

func _body_part(label: String, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.scale = size
	part.position = at
	part.material_override = material
	spider.add_child(part)

func _animate_legs() -> void:
	for i in range(8):
		var side := -1.0 if i < 4 else 1.0
		var pair := i % 4
		var phase := _gait + PI * float((pair + i / 4) % 2)
		var spread := (float(pair) - 1.5) * 0.14
		var hip := Vector3(side * 0.065, 0.11, -0.30 + spread * 0.4)
		var knee := Vector3(side * 0.23, 0.20, -0.30 + spread)
		var ankle := Vector3(side * 0.34, 0.07, -0.30 + spread * 1.3)
		var foot := Vector3(side * 0.035, maxf(0, sin(phase)) * 0.07, -0.30 + spread * 1.6 + cos(phase) * 0.07)
		_legs.set_instance_transform(i * 3, _line_transform(hip, knee))
		_legs.set_instance_transform(i * 3 + 1, _line_transform(knee, ankle))
		_legs.set_instance_transform(i * 3 + 2, _line_transform(ankle, foot))
