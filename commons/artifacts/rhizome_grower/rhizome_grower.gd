extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RhizomeGrower

## @identity
## name: Rhizome Grower — It Grows Sideways, Not Up
## concept: Rhizome networks
## tier: applied
## lineage: Deleuze & Guattari's rhizome (A Thousand Plateaus). A tree grows UP from a root,
##   each node owing its place to a single parent above it. A rhizome grows SIDEWAYS: a new
##   shoot connects to several existing points at once, with no parent and no level. Grown
##   live, no hierarchy ever forms — there is no generation 0, no trunk, only a thickening
##   mat of cross-connections.
## essence: a ~1 m device that grows a rhizome network in real time. Every ~0.4 s a new node
##   sprouts at the rim of the current cloud and immediately links to SEVERAL nearby existing
##   nodes (never to one single root). Edges accumulate faster than nodes — the mat thickens
##   sideways. A readout climbs: "NODES: N  EDGES: E  (no root)". When it fills, it clears
##   and a different, equally rootless rhizome grows.
## truth: it grows sideways, not up. New points join the many, not a parent — no centre
##   forms, no hierarchy, just a spreading web.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var grow_teal: Color = Color(0.35, 0.88, 0.80)     # warm constructive accent
@export var max_nodes: int = 40
@export var links_per_node: int = 3                        # connect each new shoot to several
@export var grow_period: float = 0.4                       # seconds between sprouts
@export var spread: float = 0.36                           # cloud radius

var _t: float = 0.0
var _positions: Array = []       # Vector3 node positions (local, around _origin)
var _node_field: MultiMeshInstance3D
var _edge_field: MultiMeshInstance3D
var _edges: Array = []           # {a:int, b:int}
var _node_total: int = 0
var _edge_total: int = 0
var _readout: Label3D
var _accum: float = 0.0
var _origin := Vector3(0.0, 1.05, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_nodes"):
		max_nodes = int(config["max_nodes"])
	if config.has("links_per_node"):
		links_per_node = int(config["links_per_node"])
	if config.has("grow_period"):
		grow_period = float(config["grow_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _node_mm() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = SphereMesh.new()
	mm.instance_count = max_nodes
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _edge_mm() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.006
	cyl.height = 1.0
	mm.mesh = cyl
	mm.instance_count = max_nodes * links_per_node
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.5 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build() -> void:
	_positions = []
	_edges = []
	_node_total = 0
	_edge_total = 0
	_accum = 0.0

	# --- compact device body (~1 m) ---
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 0.7), _matte_mat(slate, 0.85, 0.15)))
	add_child(_cylinder(Vector3(0.0, 0.66, 0.0), 0.05, 0.5, _steel_mat(Color(0.34, 0.36, 0.42))))
	add_child(_torus(_origin, spread + 0.03, 0.006, _glow_mat(wire_purple, 0.9)))

	# --- node + edge MultiMesh fields (never MeshInstance3D per element) ---
	_node_field = _node_mm()
	add_child(_node_field)
	_edge_field = _edge_mm()
	add_child(_edge_field)
	_clear_fields()

	# seed with a couple of nodes so the first shoot has several points to join
	_add_node(Vector3(_rng.randf_range(-0.05, 0.05), 0.0, _rng.randf_range(-0.05, 0.05)))
	_add_node(Vector3(_rng.randf_range(-0.05, 0.05), 0.0, _rng.randf_range(-0.05, 0.05)))

	# --- readout ---
	_readout = _billboard_label("RHIZOME GROWER\nNODES: 0  EDGES: 0  (no root)", _origin + Vector3(0.0, 0.75, 0.0), 22, grow_teal)
	add_child(_readout)
	add_child(_billboard_label("it grows sideways, not up", _origin + Vector3(0.0, 0.52, 0.0), 14, wire_purple))


func _clear_fields() -> void:
	var nm: MultiMesh = _node_field.multimesh
	var i: int = 0
	while i < nm.instance_count:
		nm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		nm.set_instance_color(i, Color(0, 0, 0, 0))
		i += 1
	var em: MultiMesh = _edge_field.multimesh
	var k: int = 0
	while k < em.instance_count:
		em.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		em.set_instance_color(k, Color(0, 0, 0, 0))
		k += 1


func _add_node(local_pos: Vector3) -> int:
	if _node_total >= max_nodes:
		return -1
	var idx: int = _node_total
	_positions.append(local_pos)
	var nm: MultiMesh = _node_field.multimesh
	var world: Vector3 = _origin + local_pos
	var s: float = 0.03
	nm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(s, s, s)), world))
	# colour by birth order: cool early -> warm teal as the mat thickens (no node is "the" root)
	var f: float = float(idx) / float(max_nodes)
	nm.set_instance_color(idx, cool_white.lerp(grow_teal, f))
	_node_total += 1
	return idx


func _add_edge(a: int, b: int) -> void:
	var em: MultiMesh = _edge_field.multimesh
	if _edge_total >= em.instance_count:
		return
	var pa: Vector3 = _origin + Vector3(_positions[a])
	var pb: Vector3 = _origin + Vector3(_positions[b])
	var mid: Vector3 = (pa + pb) * 0.5
	var len: float = maxf(pa.distance_to(pb), 0.001)
	var basis: Basis = _basis_y_to(pb - pa)
	basis = basis.scaled(Vector3(1.0, len, 1.0))
	em.set_instance_transform(_edge_total, Transform3D(basis, mid))
	em.set_instance_color(_edge_total, wire_purple)
	_edges.append({"a": a, "b": b})
	_edge_total += 1


func _nearest_indices(from: Vector3, count: int) -> Array:
	var dists: Array = []
	var m: int = 0
	while m < _positions.size():
		dists.append({"j": m, "d": from.distance_to(Vector3(_positions[m]))})
		m += 1
	dists.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var out: Array = []
	var k: int = 0
	while k < dists.size() and k < count:
		out.append(int((dists[k] as Dictionary)["j"]))
		k += 1
	return out


func _grow_shoot() -> void:
	# sprout a new node at the rim of the current cloud (grows outward, sideways)
	var ang: float = _rng.randf_range(0.0, TAU)
	var rad: float = _rng.randf_range(spread * 0.4, spread)
	var pos: Vector3 = Vector3(cos(ang) * rad, _rng.randf_range(-0.06, 0.06), sin(ang) * rad)
	# link to SEVERAL nearest existing nodes BEFORE adding (so it never picks itself)
	var targets: Array = _nearest_indices(pos, links_per_node)
	var new_idx: int = _add_node(pos)
	if new_idx < 0:
		return
	var t: int = 0
	while t < targets.size():
		_add_edge(new_idx, int(targets[t]))
		t += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# gentle device idle
	if is_instance_valid(_node_field):
		_node_field.rotation.y = sin(_t * 0.3) * 0.07
	if is_instance_valid(_edge_field):
		_edge_field.rotation.y = sin(_t * 0.3) * 0.07

	# --- on a timer: grow a new sideways shoot, or reset when full ---
	_accum += delta
	if _accum >= grow_period:
		_accum = 0.0
		if _node_total >= max_nodes:
			_positions = []
			_edges = []
			_node_total = 0
			_edge_total = 0
			_clear_fields()
			_add_node(Vector3(_rng.randf_range(-0.05, 0.05), 0.0, _rng.randf_range(-0.05, 0.05)))
			_add_node(Vector3(_rng.randf_range(-0.05, 0.05), 0.0, _rng.randf_range(-0.05, 0.05)))
		else:
			_grow_shoot()
		if _readout != null:
			_readout.text = "RHIZOME GROWER\nNODES: %d  EDGES: %d  (no root)" % [_node_total, _edge_total]
