# graph_basilica.gd
# A walk-in basilica whose entire architecture IS a graph. Six-to-seven
# cylindrical node-piers rise from a dark disc floor, each crowned with a
# glowing node-sphere; the vault overhead is nothing but edge-beams joining
# the spheres per a seeded adjacency (spanning tree first, then extra edges
# at ~0.45 probability — always connected, never regular). The same graph is
# drawn twice: above as structure, below as a faint floor-plan of rings and
# lines. Every ~6 seconds a breadth-first light-wave starts at a seeded node
# and rolls outward hop by hop — node flares, edge-halves light directionally,
# neighbours flare one hop later — so the player literally stands inside BFS.
#
# @identity
# essence: a nave with no walls and no roof — only RELATION made load-bearing.
#   Each pier is a vertex, each beam an adjacency, and the open sky between
#   beams is every edge the seed declined. Degree is legible as mass: the
#   better-connected a node, the larger and brighter its sphere. The building
#   does not CONTAIN a graph; the graph, lifted to three metres and given
#   columns, IS the building
# desire: to let a player stand at the exact centre of adjacency and feel a
#   breadth-first search pass through their body — source flares, the wave
#   takes the colonnade one hop at a time, and for a few seconds the whole
#   vault remembers which node spoke first. Architecture as proof that
#   connections define structure
# critical_parameter: rng_seed + edge_probability — together they ARE the
#   graph. Same seed, same basilica, stone for stone; nudge the probability
#   and the vault thickens or thins, but the spanning-tree pass guarantees
#   you can always get from any sphere to any other. The floor plan is just
#   the adjacency matrix you can walk on
# triggers: _ready() seeds the layout and raises the colonnade;
#   apply_grid_config rebuilds with new DNA; every ~6s _start_wave() elects a
#   new source and _process carries the BFS front across spheres and beams
# emerges: in graphtheory, spine order 16 — the late revelation that the
#   substrate was always under it all. Arrays were paths, grids were lattices,
#   trees were graphs without cycles; here the curriculum finally shows its
#   own skeleton and invites you to walk around inside it
# needs: a 9x9 cell clearing with open sky; darkness flatters the wave but
#   the emissive graph reads anywhere
# relationships: the maps' teleporter network is this building at world
#   scale — every map a node, every teleporter an edge, the player a token
#   on the graph; the curriculum spine itself is one long path walked through
#   that graph, and this basilica is the spine turning around to look at the
#   shape of its own walk
# truth: a building is a graph that agreed to hold still
#
extends Node3D
class_name GraphBasilica

@export var node_count: int = 7
@export var edge_probability: float = 0.45
@export var rng_seed: int = 16
@export var accent_color: Color = Color(0.35, 0.78, 1.0)
@export var pulse_speed: float = 1.0

const FLOOR_RADIUS: float = 4.4
const PIER_RADIUS: float = 0.45
const RING_MIN: float = 2.4
const RING_MAX: float = 3.5
const MIN_PIER_GAP: float = 1.75  # centre-to-centre; pigeonhole guarantees a >=1.4m doorway
const FLARE_GAIN_NODE: float = 2.8
const FLARE_GAIN_EDGE: float = 3.2

# --- built state ---
var _built: bool = false
var _pier_pos: PackedVector2Array = PackedVector2Array()   # plan positions
var _sphere_pos: PackedVector3Array = PackedVector3Array() # node-sphere centres
var _adj: Array = []                                       # Array of plain Arrays of int
var _edge_a: PackedInt32Array = PackedInt32Array()
var _edge_b: PackedInt32Array = PackedInt32Array()
var _node_mats: Array[StandardMaterial3D] = []
var _node_base: PackedFloat32Array = PackedFloat32Array()
var _edge_mats_a: Array[StandardMaterial3D] = []           # half nearest endpoint a
var _edge_mats_b: Array[StandardMaterial3D] = []           # half nearest endpoint b
const EDGE_BASE_ENERGY: float = 0.35

# --- wave state ---
var _pulse_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _wave_time: float = 0.0
var _period: float = 6.0
var _node_start: PackedFloat32Array = PackedFloat32Array()
var _edge_start_a: PackedFloat32Array = PackedFloat32Array()
var _edge_start_b: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	if config_data.has("node_count"):
		node_count = int(config_data["node_count"])
	if config_data.has("edge_probability"):
		edge_probability = float(config_data["edge_probability"])
	if config_data.has("rng_seed"):
		rng_seed = int(config_data["rng_seed"])
	elif config_data.has("seed"):
		rng_seed = int(config_data["seed"])
	if config_data.has("pulse_speed"):
		pulse_speed = float(config_data["pulse_speed"])
	if config_data.has("accent_color"):
		var v: Variant = config_data["accent_color"]
		if v is String:
			accent_color = Color.from_string(str(v), accent_color)
		elif v is Array and (v as Array).size() >= 3:
			var arr: Array = v
			accent_color = Color(float(arr[0]), float(arr[1]), float(arr[2]))
		elif v is Color:
			accent_color = v
	if config_data.has("scale"):
		var s: float = maxf(float(config_data["scale"]), 0.05)
		scale = Vector3(s, s, s)
	_build()


# ---------------------------------------------------------------- build ---

func _build() -> void:
	_built = false
	for child in get_children():
		child.queue_free()
	_node_mats.clear()
	_edge_mats_a.clear()
	_edge_mats_b.clear()
	_adj.clear()
	_edge_a = PackedInt32Array()
	_edge_b = PackedInt32Array()

	node_count = clampi(node_count, 3, 12)
	var p: float = clampf(edge_probability, 0.0, 1.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed

	_layout_nodes(rng)
	_generate_edges(rng, p)
	var degrees: PackedInt32Array = _compute_degrees()
	_place_spheres(rng, degrees)

	_build_floor()
	_build_piers(degrees)
	_build_spheres(degrees)
	_build_edges_geometry()
	_build_center_light()
	_build_capture_camera()

	_pulse_rng.seed = rng_seed * 7919 + 13
	_built = true
	_start_wave()


func _layout_nodes(rng: RandomNumberGenerator) -> void:
	_pier_pos = PackedVector2Array()
	_pier_pos.resize(node_count)
	# Node 0: roughly central, jittered (graphs have no altar axis).
	_pier_pos[0] = Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
	# Remaining nodes: an IRREGULAR ring — jittered angles, varied radii.
	var ring_n: int = node_count - 1
	var angle0: float = rng.randf_range(0.0, TAU)
	for i in range(1, node_count):
		var base_ang: float = angle0 + float(i - 1) * TAU / float(ring_n)
		var ang: float = base_ang + rng.randf_range(-0.32, 0.32)
		var rad: float = rng.randf_range(RING_MIN, RING_MAX)
		_pier_pos[i] = Vector2(cos(ang), sin(ang)) * rad
	# Relaxation: keep piers apart so the colonnade stays walkable. Because
	# the total perimeter is fixed, at least one inter-pier gap always ends
	# up >= 1.4m clear — that gap is the doorway.
	for _pass in 6:
		for i in node_count:
			for j in range(i + 1, node_count):
				var d: float = _pier_pos[i].distance_to(_pier_pos[j])
				if d < MIN_PIER_GAP and d > 0.001:
					var push: Vector2 = (_pier_pos[j] - _pier_pos[i]).normalized() * ((MIN_PIER_GAP - d) * 0.5)
					_pier_pos[i] = _pier_pos[i] - push
					_pier_pos[j] = _pier_pos[j] + push
		# Re-clamp: node 0 stays near centre, ring stays inside the floor.
		var c0: Vector2 = _pier_pos[0]
		if c0.length() > 0.9:
			_pier_pos[0] = c0.normalized() * 0.9
		for i in range(1, node_count):
			var pos: Vector2 = _pier_pos[i]
			var ln: float = pos.length()
			if ln < 0.01:
				continue
			var clamped: float = clampf(ln, RING_MIN, RING_MAX)
			if absf(clamped - ln) > 0.001:
				_pier_pos[i] = pos.normalized() * clamped


func _generate_edges(rng: RandomNumberGenerator, p: float) -> void:
	for i in node_count:
		_adj.append([])
	var taken: Dictionary = {}
	# Spanning tree pass — random attachment order, so the graph is always
	# connected before probability says anything.
	var order: Array[int] = []
	for i in node_count:
		order.append(i)
	for i in range(node_count - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	for i in range(1, node_count):
		var a: int = order[i]
		var b: int = order[rng.randi_range(0, i - 1)]
		_add_edge(a, b, taken)
	# Probability pass — every remaining pair flips the seeded coin.
	for i in node_count:
		for j in range(i + 1, node_count):
			var key: int = i * 100 + j
			if taken.has(key):
				continue
			if rng.randf() < p:
				_add_edge(i, j, taken)


func _add_edge(a: int, b: int, taken: Dictionary) -> void:
	var lo: int = mini(a, b)
	var hi: int = maxi(a, b)
	taken[lo * 100 + hi] = true
	_edge_a.append(lo)
	_edge_b.append(hi)
	var adj_lo: Array = _adj[lo]
	var adj_hi: Array = _adj[hi]
	adj_lo.append(hi)
	adj_hi.append(lo)


func _compute_degrees() -> PackedInt32Array:
	var degrees: PackedInt32Array = PackedInt32Array()
	degrees.resize(node_count)
	for k in _edge_a.size():
		degrees[_edge_a[k]] += 1
		degrees[_edge_b[k]] += 1
	return degrees


func _place_spheres(rng: RandomNumberGenerator, degrees: PackedInt32Array) -> void:
	_sphere_pos = PackedVector3Array()
	_sphere_pos.resize(node_count)
	for i in node_count:
		var h: float = 3.55 if i == 0 else rng.randf_range(2.75, 3.2)
		_sphere_pos[i] = Vector3(_pier_pos[i].x, h, _pier_pos[i].y)
	# degrees kept for callers; sphere radii derived where meshes are built
	if degrees.size() != node_count:
		push_warning("[graph_basilica] degree array mismatch")


func _sphere_radius(degree: int) -> float:
	return clampf(0.24 + 0.055 * float(degree), 0.26, 0.62)


# ----------------------------------------------------------- geometry ---

func _build_floor() -> void:
	var mesh_i: MeshInstance3D = MeshInstance3D.new()
	mesh_i.name = "FloorDisc"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = FLOOR_RADIUS
	cyl.bottom_radius = FLOOR_RADIUS
	cyl.height = 0.05
	cyl.radial_segments = 48
	mesh_i.mesh = cyl
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.065, 0.085)
	mat.roughness = 0.92
	mat.metallic = 0.05
	mesh_i.material_override = mat
	mesh_i.position = Vector3(0.0, 0.025, 0.0)
	add_child(mesh_i)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "FloorBody"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cshape: CylinderShape3D = CylinderShape3D.new()
	cshape.radius = FLOOR_RADIUS
	cshape.height = 0.05
	shape.shape = cshape
	body.add_child(shape)
	body.position = Vector3(0.0, 0.025, 0.0)
	add_child(body)


func _build_piers(degrees: PackedInt32Array) -> void:
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = Color(0.13, 0.135, 0.165)
	stone.roughness = 0.85
	for i in node_count:
		var sphere_y: float = _sphere_pos[i].y
		var pier_h: float = sphere_y - 0.05
		var pier: MeshInstance3D = MeshInstance3D.new()
		pier.name = "Pier%d" % i
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.bottom_radius = PIER_RADIUS
		cyl.top_radius = 0.16
		cyl.height = pier_h
		cyl.radial_segments = 18
		pier.mesh = cyl
		pier.material_override = stone
		pier.position = Vector3(_pier_pos[i].x, 0.05 + pier_h * 0.5, _pier_pos[i].y)
		add_child(pier)

		# Collision — VR players cannot walk through a vertex.
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "PierBody%d" % i
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cshape: CylinderShape3D = CylinderShape3D.new()
		cshape.radius = PIER_RADIUS
		cshape.height = pier_h
		shape.shape = cshape
		body.add_child(shape)
		body.position = pier.position
		add_child(body)

		# Glowing floor-ring under the pier — the plan view of the vertex.
		var ring: MeshInstance3D = MeshInstance3D.new()
		ring.name = "FloorRing%d" % i
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = 0.56
		torus.outer_radius = 0.7
		torus.rings = 32
		ring.mesh = torus
		ring.position = Vector3(_pier_pos[i].x, 0.06, _pier_pos[i].y)
		add_child(ring)
		# Ring shares the node's pulsing material — assigned in _build_spheres
		ring.set_meta("node_index", i)

	if node_count >= 2:
		_attach_labels(1, degrees)


func _build_spheres(degrees: PackedInt32Array) -> void:
	_node_mats.clear()
	_node_base = PackedFloat32Array()
	_node_base.resize(node_count)
	for i in node_count:
		var deg: int = degrees[i]
		var mat: StandardMaterial3D = _emissive_mat(accent_color, 1.0)
		var base_e: float = 0.55 + 0.22 * float(deg)
		mat.emission_energy_multiplier = base_e
		_node_base[i] = base_e
		_node_mats.append(mat)

		var sphere: MeshInstance3D = MeshInstance3D.new()
		sphere.name = "NodeSphere%d" % i
		var sm: SphereMesh = SphereMesh.new()
		var r: float = _sphere_radius(deg)
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 24
		sm.rings = 12
		sphere.mesh = sm
		sphere.material_override = mat
		sphere.position = _sphere_pos[i]
		add_child(sphere)
	# Hand the shared node materials to the floor rings (skip any children
	# queued for deletion by a rebuild — they die at frame end).
	for child in get_children():
		if child.is_queued_for_deletion():
			continue
		if child is MeshInstance3D and child.has_meta("node_index"):
			var idx: int = int(child.get_meta("node_index"))
			if idx >= 0 and idx < _node_mats.size():
				(child as MeshInstance3D).material_override = _node_mats[idx]


func _build_edges_geometry() -> void:
	var dark: StandardMaterial3D = StandardMaterial3D.new()
	dark.albedo_color = Color(0.09, 0.09, 0.115)
	dark.roughness = 0.8
	_edge_mats_a.clear()
	_edge_mats_b.clear()
	for k in _edge_a.size():
		var a: int = _edge_a[k]
		var b: int = _edge_b[k]
		var pa: Vector3 = _sphere_pos[a]
		var pb: Vector3 = _sphere_pos[b]
		var seg: Vector3 = pb - pa
		var seg_len: float = seg.length()
		if seg_len < 0.01:
			_edge_mats_a.append(null)
			_edge_mats_b.append(null)
			continue
		var dirn: Vector3 = seg / seg_len
		var beam_basis: Basis = _beam_basis(dirn)

		# Structural beam — the vault is nothing but these.
		var beam: MeshInstance3D = MeshInstance3D.new()
		beam.name = "Beam%d_%d" % [a, b]
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.24, 0.34, seg_len)
		beam.mesh = box
		beam.material_override = dark
		beam.transform = Transform3D(beam_basis, (pa + pb) * 0.5)
		add_child(beam)

		# Emissive line in two halves — the wave crosses a-half, then b-half.
		var mat_a: StandardMaterial3D = _emissive_mat(accent_color, EDGE_BASE_ENERGY)
		var mat_b: StandardMaterial3D = _emissive_mat(accent_color, EDGE_BASE_ENERGY)
		_edge_mats_a.append(mat_a)
		_edge_mats_b.append(mat_b)
		var half: float = seg_len * 0.5
		var under: Vector3 = beam_basis * Vector3(0.0, -0.21, 0.0)
		_add_line_box(pa + dirn * (half * 0.5) + under, beam_basis, Vector3(0.06, 0.06, half * 0.96), mat_a, "BeamLineA%d" % k)
		_add_line_box(pa + dirn * (half * 1.5) + under, beam_basis, Vector3(0.06, 0.06, half * 0.96), mat_b, "BeamLineB%d" % k)

		# Floor projection — the same adjacency as plan, sharing the same
		# pulsing materials so the ground reads the wave too.
		var fa: Vector3 = Vector3(pa.x, 0.058, pa.z)
		var fb: Vector3 = Vector3(pb.x, 0.058, pb.z)
		var fseg: Vector3 = fb - fa
		var flen: float = fseg.length()
		if flen > 0.05:
			var fdir: Vector3 = fseg / flen
			var fbasis: Basis = _beam_basis(fdir)
			var fhalf: float = flen * 0.5
			_add_line_box(fa + fdir * (fhalf * 0.5), fbasis, Vector3(0.09, 0.012, fhalf * 0.98), mat_a, "FloorLineA%d" % k)
			_add_line_box(fa + fdir * (fhalf * 1.5), fbasis, Vector3(0.09, 0.012, fhalf * 0.98), mat_b, "FloorLineB%d" % k)


func _add_line_box(at: Vector3, line_basis: Basis, box_size: Vector3, mat: StandardMaterial3D, line_name: String) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = line_name
	var box: BoxMesh = BoxMesh.new()
	box.size = box_size
	mi.mesh = box
	mi.material_override = mat
	mi.transform = Transform3D(line_basis, at)
	add_child(mi)


func _beam_basis(dirn: Vector3) -> Basis:
	# Rotate the box's +Z onto dirn via axis-angle; guard the antiparallel case.
	var from_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
	var d: float = clampf(from_axis.dot(dirn), -1.0, 1.0)
	var axis: Vector3 = from_axis.cross(dirn)
	if axis.length() < 0.0001:
		if d < 0.0:
			return Basis(Vector3.UP, PI)
		return Basis()
	return Basis(axis.normalized(), acos(d))


func _build_center_light() -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "NaveLight"
	light.light_color = accent_color
	light.light_energy = 0.9
	light.omni_range = 7.5
	light.position = Vector3(_pier_pos[0].x, 2.9, _pier_pos[0].y)
	add_child(light)


func _attach_labels(pier_index: int, degrees: PackedInt32Array) -> void:
	if pier_index >= _pier_pos.size():
		return
	var pos2: Vector2 = _pier_pos[pier_index]
	var to_center: Vector2 = -pos2
	if to_center.length() < 0.01:
		to_center = Vector2(0.0, 1.0)
	to_center = to_center.normalized()
	var face_pos: Vector3 = Vector3(pos2.x, 1.55, pos2.y) + Vector3(to_center.x, 0.0, to_center.y) * (PIER_RADIUS * 0.78 + 0.06)
	var away: Vector3 = Vector3(-to_center.x, 0.0, -to_center.y)
	var face_basis: Basis = Basis.looking_at(away, Vector3.UP)

	var lbl: Label3D = Label3D.new()
	lbl.name = "GraphLabel"
	lbl.text = "GRAPH — the substrate\nthat was always under it all"
	lbl.font_size = 40
	lbl.pixel_size = 0.0042
	lbl.modulate = Color(0.88, 0.93, 1.0)
	lbl.outline_size = 6
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform = Transform3D(face_basis, face_pos)
	add_child(lbl)

	var sub: Label3D = Label3D.new()
	sub.name = "ConceptLabel"
	sub.text = "concept architecture — RELATION"
	sub.font_size = 22
	sub.pixel_size = 0.0036
	sub.modulate = Color(0.45, 0.47, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.transform = Transform3D(face_basis, face_pos + Vector3(0.0, -0.34, 0.0))
	add_child(sub)

	# A tiny degree readout: the pier admits its own connectivity.
	if pier_index < degrees.size():
		var deg_lbl: Label3D = Label3D.new()
		deg_lbl.name = "DegreeLabel"
		deg_lbl.text = "deg(v) = %d" % degrees[pier_index]
		deg_lbl.font_size = 18
		deg_lbl.pixel_size = 0.0034
		deg_lbl.modulate = Color(0.4, 0.42, 0.5)
		deg_lbl.transform = Transform3D(face_basis, face_pos + Vector3(0.0, -0.58, 0.0))
		add_child(deg_lbl)


func _build_capture_camera() -> void:
	# Stand the camera in the widest doorway gap, eye height, looking through
	# the central node toward the far piers — the engulfing interior shot.
	var angles: Array[float] = []
	for i in range(1, node_count):
		angles.append(atan2(_pier_pos[i].y, _pier_pos[i].x))
	angles.sort()
	var best_gap: float = -1.0
	var best_mid: float = 0.0
	for i in angles.size():
		var a0: float = angles[i]
		var a1: float = angles[(i + 1) % angles.size()]
		var gap: float = a1 - a0
		if i == angles.size() - 1:
			gap = (a1 + TAU) - a0
		if gap > best_gap:
			best_gap = gap
			best_mid = a0 + gap * 0.5
	var dir2: Vector2 = Vector2(cos(best_mid), sin(best_mid))
	var cam_pos: Vector3 = Vector3(dir2.x, 0.0, dir2.y) * (FLOOR_RADIUS - 0.45)
	cam_pos.y = 1.6
	var target: Vector3 = Vector3(_pier_pos[0].x, 2.25, _pier_pos[0].y)
	var look: Vector3 = (target - cam_pos)
	if look.length() < 0.01:
		look = Vector3(0.0, 0.0, -1.0)
	var cam: Camera3D = Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 76.0
	cam.transform = Transform3D(Basis.looking_at(look.normalized(), Vector3.UP), cam_pos)
	add_child(cam)


func _emissive_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.05)
	m.roughness = 0.6
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


# ----------------------------------------------------------- BFS wave ---

func _start_wave() -> void:
	_wave_time = 0.0
	var n: int = _node_mats.size()
	if n == 0:
		_period = 6.0
		return
	var hop: float = 0.7 / maxf(pulse_speed, 0.05)
	var src: int = _pulse_rng.randi_range(0, n - 1)

	var depth: PackedInt32Array = PackedInt32Array()
	depth.resize(n)
	depth.fill(-1)
	depth[src] = 0
	var queue: Array[int] = [src]
	var head: int = 0
	var max_d: int = 0
	while head < queue.size():
		var u: int = queue[head]
		head += 1
		var neighbours: Array = _adj[u]
		for v in neighbours:
			var vi: int = v
			if depth[vi] == -1:
				depth[vi] = depth[u] + 1
				if depth[vi] > max_d:
					max_d = depth[vi]
				queue.append(vi)

	_node_start = PackedFloat32Array()
	_node_start.resize(n)
	for i in n:
		var d: int = depth[i] if depth[i] >= 0 else max_d
		_node_start[i] = float(d) * hop

	var e_count: int = _edge_a.size()
	_edge_start_a = PackedFloat32Array()
	_edge_start_a.resize(e_count)
	_edge_start_b = PackedFloat32Array()
	_edge_start_b.resize(e_count)
	for k in e_count:
		var da: int = depth[_edge_a[k]]
		var db: int = depth[_edge_b[k]]
		if da < 0:
			da = max_d
		if db < 0:
			db = max_d
		if da <= db:
			_edge_start_a[k] = float(da) * hop
			_edge_start_b[k] = float(da) * hop + hop * 0.5
		else:
			_edge_start_b[k] = float(db) * hop
			_edge_start_a[k] = float(db) * hop + hop * 0.5

	_period = maxf(6.0 / maxf(pulse_speed, 0.05), float(max_d + 1) * hop + 1.8)


func _flare(u: float) -> float:
	# Sharp attack, slow decay — a light-wave front, not a sine.
	if u < 0.0:
		return 0.0
	var attack: float = clampf(u / 0.12, 0.0, 1.0)
	var decay: float = exp(-maxf(u - 0.12, 0.0) / 0.85)
	return attack * decay


func _process(delta: float) -> void:
	if not _built or _node_mats.is_empty():
		return
	_wave_time += delta
	if _wave_time >= _period:
		_start_wave()
	var t: float = _wave_time
	for i in _node_mats.size():
		var m: StandardMaterial3D = _node_mats[i]
		if m == null or i >= _node_start.size():
			continue
		var e: float = _flare(t - _node_start[i])
		m.emission_energy_multiplier = _node_base[i] * (1.0 + FLARE_GAIN_NODE * e)
	for k in _edge_mats_a.size():
		if k >= _edge_start_a.size():
			break
		var ma: StandardMaterial3D = _edge_mats_a[k]
		if ma != null:
			var ea: float = _flare(t - _edge_start_a[k])
			ma.emission_energy_multiplier = EDGE_BASE_ENERGY + FLARE_GAIN_EDGE * ea
		var mb: StandardMaterial3D = _edge_mats_b[k]
		if mb != null:
			var eb: float = _flare(t - _edge_start_b[k])
			mb.emission_energy_multiplier = EDGE_BASE_ENERGY + FLARE_GAIN_EDGE * eb
