extends Node3D
## The edge skeleton of a 3D Voronoi diagram, dual to Delaunay tetrahedra.
## Cords are visible tubes, not opaque cell faces or a nearest-neighbour graph.
## The enclosing ellipsoid clips cells; separate tethers stage their boundary.

@export var seed_value: int = 74
@export_range(32, 240, 1) var site_count: int = 150
@export var radii := Vector3(3.3, 3.5, 2.9)
@export var centre_height: float = 4.3
@export_range(0.004, 0.04, 0.001) var strand_radius: float = 0.012
@export_range(0, 64, 1) var anchor_count: int = 36
@export var line_color := Color("25232c")
## Maximum distance to search for an existing floor, wall or ceiling.
@export_range(5.0, 100.0, 1.0) var surface_reach: float = 80.0
## A spider lays the exact graph progressively; disable to skip construction.
@export var weave_on_start: bool = true
## Spider travel speed in metres per second (an illustrative, enlarged animal).
@export_range(0.1, 20.0, 0.1) var weave_speed: float = 2.0
## Release the completed net under gravity with unbreakable shared knots.
@export var simulate_tension: bool = true
## Axial cable compliance in m/N; smaller values resist stretch more strongly.
@export_range(0.000001, 0.001, 0.000001) var cable_compliance: float = 0.00002
## Lumped mass at each free junction in kilograms (illustrative cord model).
@export_range(0.001, 0.1, 0.001) var knot_mass: float = 0.02

const Weaver = preload("res://commons/context/cellular_spaces/voronoi_weaver.gd")
const Network = preload("res://commons/context/cellular_spaces/strand_network.gd")
const Dynamics = preload("res://commons/context/cellular_spaces/strand_dynamics.gd")
var weaver: Node3D
var dynamics: RefCounted
var tension_active: bool = false
var tension_paused: bool = false
var physics_msec: float = 0.0
var _live_batches: Array[MultiMesh] = []
var _live_knots: MultiMesh
var _room_query := PhysicsRayQueryParameters3D.new()
var _room_state: PhysicsDirectSpaceState3D

var sites := PackedVector3Array()
var vertices := PackedVector3Array()
var edges: Array[Vector2i] = []
var tethers: Array[Vector2i] = []
var anchor_kinds: Dictionary = {} # shared vertex ID -> "floor", "wall" or "ceiling"
var anchor_normals: Dictionary = {} # inward surface normal in artifact coordinates
var generation_count: int = 0
var _generation_ticket: int = 0
signal network_built
var silk_vertex_count: int = 0
var tetrahedra := PackedInt32Array()
var circumcentres := PackedVector3Array()
var build_msec: int = 0
var generated: Node3D
var _vertex_ids: Dictionary = {}
var _edge_ids: Dictionary = {}
var _boundary_ids: Dictionary = {}

func _ready() -> void:
	_request_regeneration()

# Placement and room construction must finish before querying physics. The
# ticket cancels the initial request if deferred grid configuration supersedes it.
func _request_regeneration() -> void:
	_generation_ticket += 1
	var ticket := _generation_ticket
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_signal("build_finished"):
			if bool(ancestor.get("generation_in_progress")):
				await ancestor.build_finished
			break
		ancestor = ancestor.get_parent()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if ticket == _generation_ticket and is_inside_tree():
		regenerate()

func regenerate() -> void:
	var started := Time.get_ticks_msec()
	set_physics_process(false)
	tension_active = false
	tension_paused = false
	dynamics = null
	_live_batches.clear()
	if is_instance_valid(weaver):
		remove_child(weaver)
		weaver.queue_free()
		weaver = null
	site_count = clampi(site_count, 32, 240)
	strand_radius = clampf(strand_radius, 0.004, 0.04)
	anchor_count = clampi(anchor_count, 0, 64)
	radii = radii.clamp(Vector3.ONE, Vector3.ONE * 6)
	centre_height = maxf(centre_height, radii.y + 0.4)
	sites.clear()
	vertices.clear()
	edges.clear()
	tethers.clear()
	anchor_kinds.clear()
	anchor_normals.clear()
	_vertex_ids.clear()
	_edge_ids.clear()
	_boundary_ids.clear()
	if is_instance_valid(generated):
		remove_child(generated)
		generated.queue_free()
	generated = Node3D.new()
	generated.name = "Strands"
	add_child(generated)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	while sites.size() < site_count:
		var p := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if p.length_squared() < 0.95:
			sites.append(p * radii)
	tetrahedra = Geometry3D.tetrahedralize_delaunay(sites)
	circumcentres.clear()
	var faces: Dictionary = {}
	for offset in range(0, tetrahedra.size(), 4):
		var ids := [tetrahedra[offset], tetrahedra[offset + 1], tetrahedra[offset + 2], tetrahedra[offset + 3]]
		var a: Vector3 = sites[ids[0]]
		var b: Vector3 = sites[ids[1]] - a
		var c: Vector3 = sites[ids[2]] - a
		var d: Vector3 = sites[ids[3]] - a
		var denominator := 2.0 * b.dot(c.cross(d))
		var cc := Vector3(INF, INF, INF)
		if absf(denominator) > 0.0000001:
			cc = a + (b.length_squared() * c.cross(d) + c.length_squared() * d.cross(b) + d.length_squared() * b.cross(c)) / denominator
		var index := circumcentres.size()
		circumcentres.append(cc)
		for opposite in range(4):
			var face: Array[int] = []
			for j in range(4):
				if j != opposite:
					face.append(ids[j])
			face.sort()
			var key := Vector3i(face[0], face[1], face[2])
			if faces.has(key):
				var other: Dictionary = faces[key]
				if cc.is_finite() and circumcentres[other.tet].is_finite():
					_clip_edge(circumcentres[other.tet], cc)
				faces.erase(key)
			else:
				faces[key] = {"tet": index, "opposite": ids[opposite]}
	# Hull faces have one adjacent tetrahedron: their dual is an outward ray.
	for key: Vector3i in faces:
		var face: Dictionary = faces[key]
		var cc := circumcentres[face.tet]
		if not cc.is_finite():
			continue
		var a := sites[key.x]
		var normal := (sites[key.y] - a).cross(sites[key.z] - a).normalized()
		if normal.dot(sites[face.opposite] - a) > 0:
			normal = -normal
		_clip_edge(cc, cc + normal * (cc.length() + 40.0))
	_add_tethers()
	_prune_unanchored_tips()
	var joined: Dictionary = Network.join_contacts(vertices, [edges, tethers])
	vertices = joined.vertices
	edges.assign(joined.groups[0])
	tethers.assign(joined.groups[1])
	var joined_anchors: Dictionary = {}
	var joined_normals: Dictionary = {}
	for id: int in anchor_kinds:
		joined_anchors[int(joined.aliases[id])] = anchor_kinds[id]
		joined_normals[int(joined.aliases[id])] = anchor_normals[id]
	anchor_kinds = joined_anchors
	anchor_normals = joined_normals
	_compact_network()
	silk_vertex_count = vertices.size()
	_draw_strands(edges, "CellEdges", strand_radius, line_color)
	_draw_strands(tethers, "AnchorCords", strand_radius * 0.65, line_color)
	_draw_junctions()
	_draw_surface_fixings()
	# A host without surfaces must not display an apparently supported net.
	generated.visible = anchor_count == 0 or not anchor_kinds.is_empty()
	if simulate_tension and not anchor_kinds.is_empty():
		dynamics = Dynamics.new()
		dynamics.compliance = cable_compliance
		dynamics.knot_mass = knot_mass
		dynamics.gravity = global_basis.inverse() * Vector3(0, -9.81, 0)
		var segments: Array[Vector2i] = edges.duplicate()
		segments.append_array(tethers)
		dynamics.setup(vertices, segments, anchor_kinds)
		dynamics.contact_resolver = _sweep_knot
		_room_query.collision_mask = 1
		for label in ["CellEdges", "AnchorCords"]:
			_live_batches.append(generated.get_node(label).multimesh)
		_live_knots = generated.get_node("Knots").multimesh
	if weave_on_start and not tethers.is_empty():
		weaver = Weaver.new()
		weaver.name = "Weaver"
		add_child(weaver)
		weaver.setup(self)
		weaver.completed.connect(_release_tension)
	else:
		_release_tension()
	build_msec = Time.get_ticks_msec() - started
	generation_count += 1
	network_built.emit()

# Construction is an illustration. Only the complete net is released, so no
# unbuilt or invisible strand can carry a simulated load.
func _release_tension() -> void:
	tension_active = dynamics != null
	tension_paused = false
	set_physics_process(tension_active)

## Restore the construction before replay; no accumulated velocity survives.
func reset_tension() -> void:
	tension_active = false
	tension_paused = false
	set_physics_process(false)
	if dynamics != null:
		dynamics.reset()
		vertices = dynamics.positions.duplicate()
		_sync_tension_meshes()

func _physics_process(delta: float) -> void:
	advance_tension(delta)

## Same fixed-step simulation for live playback and deterministic probes.
func advance_tension(delta: float) -> void:
	if not tension_active or tension_paused or dynamics == null:
		return
	var started := Time.get_ticks_usec()
	_room_state = get_world_3d().direct_space_state
	if dynamics.advance(delta) > 0:
		vertices = dynamics.positions.duplicate()
		_sync_tension_meshes()
	physics_msec = (Time.get_ticks_usec() - started) / 1000.0

func _sweep_knot(from: Vector3, to: Vector3) -> Vector3:
	_room_query.from = to_global(from)
	_room_query.to = to_global(to)
	var hit := _room_state.intersect_ray(_room_query)
	if not hit.is_empty() and hit.collider is StaticBody3D:
		return to_local(hit.position + hit.normal * strand_radius)
	return to

# Reuse the original four batches. Every incident endpoint and its knot sphere
# read exactly the same moving particle; anchors/fixing plates remain fixed.
func _sync_tension_meshes() -> void:
	for group in range(2):
		var segments: Array[Vector2i] = edges if group == 0 else tethers
		for i in range(segments.size()):
			var edge := segments[i]
			_live_batches[group].set_instance_transform(i, strand_transform(vertices[edge.x], vertices[edge.y]))
	for i in range(vertices.size()):
		_live_knots.set_instance_transform(i, Transform3D(Basis.IDENTITY, vertices[i]))
	if is_instance_valid(weaver) and weaver.finished:
		weaver.follow_knots()

## Tug a chosen knot with an impulse in local coordinates. Returns false during
## construction or for a fixed anchor; a junction always remains a single node.
func tug_knot(id: int, impulse: Vector3) -> bool:
	return tension_active and not tension_paused and dynamics != null and dynamics.apply_impulse(id, impulse)

## Choose a visible free knot near the centre of the camera view for a tug.
func tug_from_camera(camera: Camera3D) -> int:
	if not tension_active or tension_paused:
		return -1
	var best := INF
	var chosen := -1
	var forward := -camera.global_basis.z
	for i in range(vertices.size()):
		if anchor_kinds.has(i):
			continue
		var offset := to_global(vertices[i]) - camera.global_position
		var depth := offset.dot(forward)
		if depth <= 0:
			continue
		var score := (offset - forward * depth).length_squared() / (depth * depth)
		if score < best:
			best = score
			chosen = i
	if chosen >= 0:
		var toward := to_global(vertices[chosen]).direction_to(camera.global_position)
		if not tug_knot(chosen, global_basis.inverse() * toward * 0.12):
			return -1
	return chosen

static func strand_transform(a: Vector3, b: Vector3) -> Transform3D:
	var delta := b - a
	var length := delta.length()
	if length < 0.0000001:
		return Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), a)
	var direction := delta / length
	var reference := Vector3.RIGHT if absf(direction.y) > 0.9 else Vector3.UP
	var side := reference.cross(direction).normalized()
	return Transform3D(Basis(side, direction * length, side.cross(direction)), (a + b) * 0.5)

func _clip_edge(a: Vector3, b: Vector3) -> void:
	var start := a / radii
	var delta := (b - a) / radii
	var aa := delta.length_squared()
	if aa < 0.00000001:
		return
	var bb := 2.0 * start.dot(delta)
	var cc := start.length_squared() - 1.0
	var discriminant := bb * bb - 4.0 * aa * cc
	if discriminant < 0.0:
		return
	var root := sqrt(discriminant)
	var entry := maxf(0.0, (-bb - root) / (2.0 * aa))
	var leave := minf(1.0, (-bb + root) / (2.0 * aa))
	if leave - entry < 0.000001:
		return
	var i := _vertex(a.lerp(b, entry))
	var j := _vertex(a.lerp(b, leave))
	if i == j:
		return
	var key := Vector2i(mini(i, j), maxi(i, j))
	if not _edge_ids.has(key):
		_edge_ids[key] = true
		edges.append(key)
	if entry > 0.00001:
		_boundary_ids[i] = true
	if leave < 0.99999:
		_boundary_ids[j] = true

func _vertex(p: Vector3) -> int:
	# A 0.1 mm weld removes duplicate cells' shared junctions.
	var key := Vector3i((p * 10000.0).round())
	if _vertex_ids.has(key):
		return _vertex_ids[key]
	var index := vertices.size()
	vertices.append(p + Vector3.UP * centre_height)
	_vertex_ids[key] = index
	return index

func _add_tethers() -> void:
	var boundary: Array = _boundary_ids.keys()
	if boundary.is_empty():
		return
	var used: Dictionary = {}
	# Spread the attachment directions around the room. Actual physics hits,
	# rather than a guessed bounding box, define every terminal vertex.
	for i in range(anchor_count):
		var y := 1.0 - 2.0 * (i + 0.5) / float(anchor_count)
		var angle := i * 2.39996323
		var direction := Vector3(cos(angle) * sqrt(1.0 - y*y), y, sin(angle) * sqrt(1.0 - y*y))
		var best := -INF
		var chosen := -1
		for id: int in boundary:
			if used.has(id):
				continue
			var dot := ((vertices[id] - Vector3.UP * centre_height) / radii).dot(direction)
			if dot > best:
				best = dot
				chosen = id
		if chosen < 0:
			break
		used[chosen] = true
		var start := vertices[chosen]
		var hit := _find_surface(start, direction)
		if hit.is_empty():
			continue # never manufacture an attachment in empty space
		var endpoint := to_local(hit.position)
		var anchor := _vertex(endpoint - Vector3.UP * centre_height)
		anchor_kinds[anchor] = "floor" if hit.normal.y > 0.6 else ("ceiling" if hit.normal.y < -0.6 else "wall")
		anchor_normals[anchor] = (global_basis.transposed() * hit.normal).normalized()
		tethers.append(Vector2i(chosen, anchor))

func _find_surface(start: Vector3, direction: Vector3) -> Dictionary:
	var state := get_world_3d().direct_space_state
	var origin := to_global(start)
	# Cast outward in three dimensions: upper cells reach the ceiling, lower
	# cells the floor, and side cells the walls. The first surface owns the cord.
	var outward := (global_basis * direction).normalized()
	var direct_query := PhysicsRayQueryParameters3D.create(origin, origin + outward * surface_reach, 1)
	var direct := state.intersect_ray(direct_query)
	if _is_surface(direct) and origin.distance_to(direct.position) > 0.2:
		return direct
	var azimuth := atan2(direction.z, direction.x)
	# Open-roof galleries have no overhead hit. Look for nearby walls at lower
	# heights, then check the complete diagonal cord against all room surfaces.
	for height in [maxf(0.8, start.y), 2.0, 1.0]:
		for turn in [0.0, 0.35, -0.35, 0.7, -0.7]:
			var ray := Vector3(cos(azimuth + turn), 0, sin(azimuth + turn))
			var from := to_global(Vector3(start.x, height, start.z))
			var query := PhysicsRayQueryParameters3D.create(from, from + (global_basis * ray).normalized() * surface_reach, 1)
			var candidate := state.intersect_ray(query)
			if not _is_surface(candidate):
				continue
			# The first visible surface encountered owns the attachment instead.
			query.from = origin
			query.to = origin + origin.direction_to(candidate.position) * minf(surface_reach, origin.distance_to(candidate.position) + 0.04)
			var visible := state.intersect_ray(query)
			if _is_surface(visible) and origin.distance_to(visible.position) > 0.2:
				return visible
	return {}

func _is_surface(hit: Dictionary) -> bool:
	return not hit.is_empty() and hit.collider is StaticBody3D and hit.normal.length_squared() > 0.9

func _prune_unanchored_tips() -> void:
	var anchored: Dictionary = {}
	for tether in tethers:
		anchored[tether.x] = true
	edges = edges.filter(func(edge: Vector2i) -> bool:
		return (not _boundary_ids.has(edge.x) or anchored.has(edge.x)) and (not _boundary_ids.has(edge.y) or anchored.has(edge.y)))
	# Crop open boundary cells to their connected core, retaining chosen tethers.
	while true:
		var degree: Dictionary = {}
		for edge in edges:
			degree[edge.x] = int(degree.get(edge.x, 0)) + 1
			degree[edge.y] = int(degree.get(edge.y, 0)) + 1
		var kept: Array[Vector2i] = []
		for edge in edges:
			if (degree[edge.x] > 1 or anchored.has(edge.x)) and (degree[edge.y] > 1 or anchored.has(edge.y)):
				kept.append(edge)
		if kept.size() == edges.size():
			break
		edges = kept
	# Keep one connected net and discard orphan tethers; Finish must never
	# resurrect a disconnected piece that the spider cannot reach.
	var core: Dictionary = Network.largest_component(vertices.size(), edges)
	edges = edges.filter(func(edge: Vector2i) -> bool: return core.has(edge.x) and core.has(edge.y))
	tethers = tethers.filter(func(edge: Vector2i) -> bool: return core.has(edge.x))
	_compact_network()

func _compact_network() -> void:
	var remap: Dictionary = {}
	var compact := PackedVector3Array()
	for group in [edges, tethers]:
		for i in range(group.size()):
			var edge: Vector2i = group[i]
			for id in [edge.x, edge.y]:
				if not remap.has(id):
					remap[id] = compact.size()
					compact.append(vertices[id])
			group[i] = Vector2i(remap[edge.x], remap[edge.y])
	vertices = compact
	var retained: Dictionary = {}
	var retained_normals: Dictionary = {}
	for id: int in anchor_kinds:
		if remap.has(id):
			retained[remap[id]] = anchor_kinds[id]
			retained_normals[remap[id]] = anchor_normals[id]
	anchor_kinds = retained
	anchor_normals = retained_normals

func _draw_surface_fixings() -> void:
	var plate := BoxMesh.new()
	plate.size = Vector3(0.16, 0.16, 0.025)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = plate
	batch.instance_count = anchor_kinds.size()
	var i := 0
	for id: int in anchor_kinds:
		var normal: Vector3 = anchor_normals[id]
		var reference := Vector3.RIGHT if absf(normal.y) > 0.9 else Vector3.UP
		var basis := Basis.looking_at(-normal, reference)
		batch.set_instance_transform(i, Transform3D(basis, vertices[id] + normal * 0.0125))
		i += 1
	var instance := MultiMeshInstance3D.new()
	instance.name = "SurfaceFixings"
	instance.multimesh = batch
	instance.material_override = _material(line_color)
	generated.add_child(instance)

func _draw_strands(segments: Array[Vector2i], label: String, radius: float, color: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.height = 1
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.radial_segments = 6
	cylinder.rings = 1
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = cylinder
	batch.instance_count = segments.size()
	for i in range(segments.size()):
		var a := vertices[segments[i].x]
		var b := vertices[segments[i].y]
		var direction := (b - a).normalized()
		var reference := Vector3.RIGHT if absf(direction.y) > 0.9 else Vector3.UP
		var side := reference.cross(direction).normalized()
		var basis := Basis(side, direction * a.distance_to(b), side.cross(direction))
		batch.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = batch
	instance.material_override = _material(color)
	generated.add_child(instance)

func _draw_junctions() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = strand_radius * 1.6
	sphere.height = sphere.radius * 2
	sphere.radial_segments = 6
	sphere.rings = 3
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = sphere
	batch.instance_count = silk_vertex_count
	for i in range(silk_vertex_count):
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, vertices[i]))
	var instance := MultiMeshInstance3D.new()
	instance.name = "Knots"
	instance.multimesh = batch
	instance.material_override = _material(line_color)
	generated.add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed"):
		seed_value = int(config.seed)
	if config.has("cells"):
		site_count = clampi(int(config.cells), 32, 240)
	if config.has("anchors"):
		anchor_count = clampi(int(config.anchors), 0, 64)
	if config.has("thickness"):
		strand_radius = clampf(float(config.thickness), 0.004, 0.04)
	if config.has("weave"):
		weave_on_start = str(config.weave).to_lower() not in ["false", "0"]
	if config.has("weave_speed"):
		weave_speed = clampf(float(config.weave_speed), 0.1, 20.0)
	if config.has("wall_reach"):
		surface_reach = clampf(float(config.wall_reach), 5.0, 100.0) # legacy map token
	if config.has("surface_reach"):
		surface_reach = clampf(float(config.surface_reach), 5.0, 100.0)
	if config.has("tension"):
		simulate_tension = str(config.tension).to_lower() not in ["false", "0"]
	if config.has("compliance"):
		cable_compliance = clampf(float(config.compliance), 0.000001, 0.001)
	if config.has("knot_mass"):
		knot_mass = clampf(float(config.knot_mass), 0.001, 0.1)
	if is_node_ready():
		if generation_count > 0:
			regenerate()
		else:
			_request_regeneration()
