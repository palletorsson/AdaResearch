extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RhizomeBench

## @identity
## name: Rhizome Bench — Cut It Anywhere, It Regrows
## concept: Rhizome networks
## tier: medium
## lineage: Deleuze & Guattari's rhizome (A Thousand Plateaus), principle of asignifying
##   rupture: "A rhizome may be broken, shattered at a given spot, but it will start up
##   again on one of its old lines, or on new lines." Unlike a tree, severing it does not
##   kill it — there is no single trunk to cut. Post-crisis, this is resilience without a
##   centre to defend.
## essence: a floor-standing bench (~1 m) holding a flat rhizome network. Periodically the
##   machine CUTS one edge — the edge flashes warm and severs (goes dark/gone) — and the
##   network immediately REGROWS a new edge around the gap, re-linking the two stranded
##   sides by a different route. The path between any two nodes survives every cut by
##   re-routing; the map of the network is never the same twice.
## truth: cut it anywhere and it regrows; the map is not the territory. Rupture is not
##   death — the rhizome starts up again on a new line.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var cut_amber: Color = Color(0.98, 0.55, 0.25)     # the flash of the severed edge
@export var regrow_teal: Color = Color(0.35, 0.88, 0.80)   # the fresh re-routed link
@export var node_count: int = 11
@export var cut_period: float = 1.6                        # seconds between cuts
@export var plane_radius: float = 0.34

var _t: float = 0.0
var _positions: Array = []       # Vector3 node positions on the bench plane
var _edges: Array = []           # {a:int, b:int, mi:MeshInstance3D, mat:StandardMaterial3D, state:String, glow:float}
var _node_mats: Array = []
var _plane_y: float = 1.05
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("node_count"):
		node_count = int(config["node_count"])
	if config.has("cut_period"):
		cut_period = float(config["cut_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_positions = []
	_edges = []
	_node_mats = []
	_accum = 0.0

	# --- bench (floor-standing) ---
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(slate, 0.85, 0.1)))
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, _steel_mat(Color(0.34, 0.36, 0.42))))
	# a faint deck disc the rhizome lies on
	add_child(_torus(Vector3(0.0, 0.86, 0.0), plane_radius + 0.02, 0.006, _glow_mat(wire_purple, 0.9)))

	# --- scatter nodes on the bench plane (the rhizome's points) ---
	var n: int = 0
	while n < node_count:
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = sqrt(_rng.randf()) * plane_radius
		var p: Vector3 = Vector3(cos(ang) * rad, _plane_y, sin(ang) * rad)
		_positions.append(p)
		n += 1

	# --- nodes as small spheres (none is the root) ---
	var q: int = 0
	while q < node_count:
		var nmat: StandardMaterial3D = _glow_mat(cool_white, 1.0)
		add_child(_sphere(_positions[q], 0.024, nmat))
		_node_mats.append(nmat)
		q += 1

	# --- initial edges: each node to its 2 nearest neighbours (acentered web) ---
	var i: int = 0
	while i < node_count:
		var order: Array = _nearest_order(i)
		var added: int = 0
		var o: int = 0
		while o < order.size() and added < 2:
			var j: int = int(order[o])
			if not _has_edge(i, j):
				_add_edge(i, j, "live")
				added += 1
			o += 1
		i += 1

	# --- billboard title ---
	add_child(_billboard_label("CUT IT ANYWHERE, IT REGROWS", Vector3(0.0, 1.5, 0.0), 24, cool_white))
	add_child(_billboard_label("the map is not the territory", Vector3(0.0, 1.34, 0.0), 16, regrow_teal))


func _nearest_order(idx: int) -> Array:
	var dists: Array = []
	var m: int = 0
	while m < node_count:
		if m != idx:
			dists.append({"j": m, "d": (Vector3(_positions[idx])).distance_to(Vector3(_positions[m]))})
		m += 1
	dists.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var out: Array = []
	var k: int = 0
	while k < dists.size():
		out.append(int((dists[k] as Dictionary)["j"]))
		k += 1
	return out


func _has_edge(a: int, b: int) -> bool:
	var e: int = 0
	while e < _edges.size():
		var ed: Dictionary = _edges[e]
		if (int(ed["a"]) == a and int(ed["b"]) == b) or (int(ed["a"]) == b and int(ed["b"]) == a):
			if String(ed["state"]) != "dead":
				return true
		e += 1
	return false


func _add_edge(a: int, b: int, state: String) -> void:
	var col: Color = regrow_teal if state == "fresh" else wire_purple
	var emat: StandardMaterial3D = _glow_mat(col, 0.6)
	var mi: MeshInstance3D = _cylinder_between(_positions[a], _positions[b], 0.006, emat)
	add_child(mi)
	_edges.append({"a": a, "b": b, "mi": mi, "mat": emat, "state": state, "glow": 1.0 if state == "fresh" else 0.0})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# --- on a timer: cut a live edge, then regrow a new route around the gap ---
	_accum += delta
	if _accum >= cut_period:
		_accum = 0.0
		_cut_and_regrow()

	# --- animate edge states: cut edges flash amber and fade out; fresh edges cool ---
	var i: int = _edges.size() - 1
	while i >= 0:
		var ed: Dictionary = _edges[i]
		var st: String = String(ed["state"])
		var mat: StandardMaterial3D = ed["mat"]
		var mi: MeshInstance3D = ed["mi"]
		if st == "cutting":
			ed["glow"] = float(ed["glow"]) - delta * 1.8
			var g: float = float(ed["glow"])
			if g <= 0.0:
				if is_instance_valid(mi):
					mi.queue_free()
				ed["state"] = "dead"
			else:
				mat.albedo_color = cut_amber
				mat.emission = cut_amber
				mat.emission_energy_multiplier = (3.0 * g) if emissive else 0.3
		elif st == "fresh":
			ed["glow"] = maxf(0.0, float(ed["glow"]) - delta * 0.8)
			var f: float = float(ed["glow"])
			mat.albedo_color = wire_purple.lerp(regrow_teal, f)
			mat.emission = wire_purple.lerp(regrow_teal, f)
			mat.emission_energy_multiplier = (0.6 + 2.0 * f) if emissive else 0.2
			if f <= 0.02:
				ed["state"] = "live"
		else:
			mat.emission_energy_multiplier = 0.6 if emissive else 0.2
		i -= 1

	# gentle node shimmer
	var q: int = 0
	while q < _node_mats.size():
		var nm: StandardMaterial3D = _node_mats[q]
		nm.emission_energy_multiplier = (1.0 + 0.3 * sin(_t * 2.0 + float(q))) if emissive else 0.3
		q += 1


func _cut_and_regrow() -> void:
	# collect currently-live edges
	var live: Array = []
	var e: int = 0
	while e < _edges.size():
		if String((_edges[e] as Dictionary)["state"]) == "live":
			live.append(e)
		e += 1
	if live.size() == 0:
		return
	# cut one at random
	var pick: int = int(live[_rng.randi() % live.size()])
	var cut_ed: Dictionary = _edges[pick]
	var sa: int = int(cut_ed["a"])
	var sb: int = int(cut_ed["b"])
	cut_ed["state"] = "cutting"
	cut_ed["glow"] = 1.0

	# regrow: re-link the two stranded sides by a NEW route — connect sa to a different
	# nearby node it is not already linked to (the rhizome starts up on a new line)
	var order: Array = _nearest_order(sa)
	var o: int = 0
	while o < order.size():
		var cand: int = int(order[o])
		if cand != sb and not _has_edge(sa, cand):
			_add_edge(sa, cand, "fresh")
			return
		o += 1
	# fallback: re-link sb instead so connectivity is restored on a fresh line
	var order2: Array = _nearest_order(sb)
	var o2: int = 0
	while o2 < order2.size():
		var cand2: int = int(order2[o2])
		if cand2 != sa and not _has_edge(sb, cand2):
			_add_edge(sb, cand2, "fresh")
			return
		o2 += 1
