extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RhizomeToy

## @identity
## name: Rhizome Toy — No Centre, No Root
## concept: Rhizome networks
## tier: small
## lineage: Deleuze & Guattari's rhizome (A Thousand Plateaus). Against the tree — the
##   arborescent model with its single root, trunk, and hierarchy of branches — the rhizome
##   has no centre and no origin: any point may connect to any other, and it can be entered
##   from anywhere. Post-crisis, it is the figure for knowledge and organisation after the
##   single foundation falls away.
## essence: a held mesh of ~9 nodes (~0.4 m), densely cross-linked so there is no trunk and
##   no leaf — every node wired to several others. A pulse of light is released at a random
##   node and travels outward along EVERY route at once, reaching the whole mesh by many
##   paths rather than one. No node is the root; the glow has no preferred direction.
## truth: any point connects to any other; no centre, no hierarchy. Enter anywhere, reach
##   everywhere — the rhizome has no trunk to climb.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var pulse_teal: Color = Color(0.35, 0.88, 0.80)   # warm constructive accent
@export var node_count: int = 9
@export var link_range: float = 0.24                       # nodes closer than this get wired
@export var pulse_period: float = 2.2                      # seconds between fresh pulses
@export var spin_speed: float = 0.4

var _t: float = 0.0
var _positions: Array = []       # Vector3 node positions (local, centred)
var _node_mis: Array = []        # MeshInstance3D per node
var _node_mats: Array = []       # their materials
var _edges: Array = []           # {a:int, b:int, mat:StandardMaterial3D}
var _node_glow: Array = []       # per-node activation 0..1 (the spreading pulse)
var _pulse_accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("node_count"):
		node_count = int(config["node_count"])
	if config.has("link_range"):
		link_range = float(config["link_range"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_positions = []
	_node_mis = []
	_node_mats = []
	_edges = []
	_node_glow = []
	_pulse_accum = 0.0

	# --- scatter nodes in a small blob (no tier base — held object ~0.4 m) ---
	var n: int = 0
	while n < node_count:
		var p: Vector3 = Vector3(
			_rng.randf_range(-0.16, 0.16),
			_rng.randf_range(-0.14, 0.14),
			_rng.randf_range(-0.16, 0.16))
		_positions.append(p)
		_node_glow.append(0.0)
		n += 1

	# --- wire any pair within link_range (acentered: no root, dense cross-links) ---
	var i: int = 0
	while i < node_count:
		var j: int = i + 1
		while j < node_count:
			if (Vector3(_positions[i])).distance_to(Vector3(_positions[j])) <= link_range:
				var emat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
				add_child(_cylinder_between(_positions[i], _positions[j], 0.006, emat))
				_edges.append({"a": i, "b": j, "mat": emat})
			j += 1
		i += 1

	# guarantee connectivity so the pulse can reach everything: link each lonely node
	# to its nearest neighbour
	var k: int = 0
	while k < node_count:
		var has_edge: bool = false
		var e: int = 0
		while e < _edges.size():
			var ed: Dictionary = _edges[e]
			if int(ed["a"]) == k or int(ed["b"]) == k:
				has_edge = true
				break
			e += 1
		if not has_edge:
			var nearest: int = -1
			var best: float = 1e9
			var m: int = 0
			while m < node_count:
				if m != k:
					var d: float = (Vector3(_positions[k])).distance_to(Vector3(_positions[m]))
					if d < best:
						best = d
						nearest = m
				m += 1
			if nearest >= 0:
				var emat2: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
				add_child(_cylinder_between(_positions[k], _positions[nearest], 0.006, emat2))
				_edges.append({"a": k, "b": nearest, "mat": emat2})
		k += 1

	# --- nodes as spheres (no node is bigger — none is the root) ---
	var q: int = 0
	while q < node_count:
		var nmat: StandardMaterial3D = _glow_mat(cool_white, 0.9)
		var mi: MeshInstance3D = _sphere(_positions[q], 0.026, nmat)
		add_child(mi)
		_node_mis.append(mi)
		_node_mats.append(nmat)
		q += 1

	# --- billboard title ---
	add_child(_billboard_label("NO CENTRE, NO ROOT", Vector3(0.0, 0.26, 0.0), 18, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	rotation.y += delta * spin_speed

	# --- release a fresh pulse at a random node periodically ---
	_pulse_accum += delta
	if _pulse_accum >= pulse_period:
		_pulse_accum = 0.0
		if _node_glow.size() > 0:
			_node_glow[_rng.randi() % _node_glow.size()] = 1.0

	# --- spread activation along EVERY edge (the pulse takes all routes at once) ---
	var spread: Array = _node_glow.duplicate()
	var e: int = 0
	while e < _edges.size():
		var ed: Dictionary = _edges[e]
		var a: int = int(ed["a"])
		var b: int = int(ed["b"])
		var ga: float = float(_node_glow[a])
		var gb: float = float(_node_glow[b])
		# each endpoint pulls a little of the other's glow — symmetric, no direction
		spread[a] = maxf(float(spread[a]), gb * 0.85)
		spread[b] = maxf(float(spread[b]), ga * 0.85)
		# light the edge by the brighter endpoint
		var lit: float = maxf(ga, gb)
		var em: StandardMaterial3D = ed["mat"]
		em.albedo_color = wire_purple.lerp(pulse_teal, lit)
		em.emission = wire_purple.lerp(pulse_teal, lit)
		em.emission_energy_multiplier = (0.6 + 2.0 * lit) if emissive else 0.2
		e += 1

	# decay + commit the spread back into the node glows
	var g: int = 0
	while g < _node_glow.size():
		var v: float = maxf(float(spread[g]), float(_node_glow[g])) - delta * 0.9
		_node_glow[g] = clampf(v, 0.0, 1.0)
		var nm: StandardMaterial3D = _node_mats[g]
		var lv: float = float(_node_glow[g])
		nm.albedo_color = cool_white.lerp(pulse_teal, lv)
		nm.emission = cool_white.lerp(pulse_teal, lv)
		nm.emission_energy_multiplier = (0.9 + 2.2 * lv) if emissive else 0.3
		g += 1
