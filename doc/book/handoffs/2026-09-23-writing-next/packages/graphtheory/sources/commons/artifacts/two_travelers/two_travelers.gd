extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TwoTravelers

## @identity
## lineage: the graph taxonomy's rung 9 — one tree of lamps, two travellers taking
##   turns. THE TIDE floods it breadth-first: root, then every child, then every
##   grandchild, light rising in level waves. THE DIVER goes depth-first: one branch
##   to its leaf, then back up and down the next, a single bright thread worming the
##   tree. Same fifteen lamps, two completely different stories of visiting.
## essence: a traversal is an ITINERARY — the graph does not order its own nodes; the
##   algorithm does. BFS is distance-order (the tide), DFS is commitment-order (the
##   diver). Both computed honestly here from the same adjacency, then replayed as
##   light.
## truth: same tree, two orders. Every algorithm is an itinerary.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 9 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const TIDE := Color(0.3, 0.7, 0.95)
const DIVER := Color(0.95, 0.6, 0.2)

@export var seed: int = 46
@export var step: float = 0.45          # seconds per visit
@export var rest: float = 1.6           # pause between travellers

var _nodes: Array = []                  # {pos, mat}
var _children: Array = []               # adjacency: index -> [child indices]
var _bfs_order: Array = []
var _dfs_order: Array = []
var _mode_bfs := true
var _cursor := 0
var _clock := 0.0
var _resting := 0.0
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_grow_tree()
	_bfs_order = _bfs()
	_dfs_order = _dfs()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "step"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- one tree, grown once, walked twice ---------------------------------------------

func _grow_tree() -> void:
	# levels: 1 + 3 + 6 + 5 lamps, laid out as a fan
	var specs := [[0, -1], [1, 0], [2, 0], [3, 0], [4, 1], [5, 1], [6, 2], [7, 2], [8, 3], [9, 3], [10, 4], [11, 5], [12, 6], [13, 8], [14, 9]]
	_children.resize(specs.size())
	for i in range(specs.size()):
		_children[i] = []
	var depth := []
	depth.resize(specs.size())
	for s in specs:
		var i: int = s[0]
		var p: int = s[1]
		depth[i] = 0 if p < 0 else depth[p] + 1
		if p >= 0:
			_children[p].append(i)
	# positions: depth = height (root on top), siblings fanned by index
	var per_level := {}
	for s in specs:
		per_level[depth[s[0]]] = per_level.get(depth[s[0]], 0) + 1
	var seen := {}
	for s in specs:
		var i: int = s[0]
		var d: int = depth[i]
		var k: int = seen.get(d, 0)
		seen[d] = k + 1
		var n: int = per_level[d]
		var x := (float(k) - float(n - 1) * 0.5) * (2.6 / maxf(float(n) - 1.0, 1.0) if n > 1 else 1.0)
		var pos := Vector3(x, 2.5 - 0.62 * float(d), sin(float(i) * 1.7) * 0.15)
		var lamp := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.075
		lm.height = 0.15
		lamp.mesh = lm
		lamp.position = pos
		var mat := _glow_mat(Color(0.5, 0.5, 0.55), 0.25)
		lamp.material_override = mat
		add_child(lamp)
		_nodes.append({"pos": pos, "mat": mat})
	for s in specs:
		if s[1] >= 0:
			var a: Vector3 = _nodes[s[1]]["pos"]
			var b: Vector3 = _nodes[s[0]]["pos"]
			var e := MeshInstance3D.new()
			var em := CylinderMesh.new()
			em.top_radius = 0.01
			em.bottom_radius = 0.01
			em.height = a.distance_to(b)
			e.mesh = em
			e.position = (a + b) * 0.5
			var dir := (b - a).normalized()
			var axis := Vector3.UP.cross(dir)
			if axis.length() > 0.001:
				e.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
			e.material_override = _matte_mat(Color(0.35, 0.35, 0.38), 0.7)
			add_child(e)

func _bfs() -> Array:
	var order := []
	var queue := [0]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		order.append(i)
		for c in _children[i]:
			queue.append(c)
	return order

func _dfs() -> Array:
	var order := []
	var stack := [0]
	while not stack.is_empty():
		var i: int = stack.pop_back()
		order.append(i)
		var kids: Array = _children[i].duplicate()
		kids.reverse()
		for c in kids:
			stack.append(c)
	return order

# --- the replay ---------------------------------------------------------------------

func _process(delta: float) -> void:
	# lamps cool toward grey; the current traveller reheats them in ITS order
	for n in _nodes:
		var m: StandardMaterial3D = n["mat"]
		m.emission_energy_multiplier = maxf(m.emission_energy_multiplier - delta * 0.55, 0.25)
	if _resting > 0.0:
		_resting -= delta
		if _resting <= 0.0:
			_mode_bfs = not _mode_bfs
			_cursor = 0
		return
	_clock += delta
	if _clock < step:
		return
	_clock = 0.0
	var order := _bfs_order if _mode_bfs else _dfs_order
	if _cursor >= order.size():
		_resting = rest
		return
	var i: int = order[_cursor]
	var m: StandardMaterial3D = _nodes[i]["mat"]
	var tint := TIDE if _mode_bfs else DIVER
	m.albedo_color = tint
	m.emission = tint
	m.emission_energy_multiplier = 2.4
	_cursor += 1
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("THE TIDE - BFS" if _mode_bfs else "THE DIVER - DFS",
			("visits by distance: level after level" if _mode_bfs else "commits to a branch, then backtracks")
			+ "  (%d / %d)" % [_cursor, order.size()])

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "TravelersPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.7, 0.24, 0.8)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("TWO TRAVELERS",
			"Same fifteen lamps, two orders: the tide floods level by level (BFS),\nthe diver follows one branch to its leaf and backtracks (DFS). The graph\ndoes not order its own nodes - the algorithm is the itinerary.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.36
	_readout.position = Vector3(1.7, 0.24, 0.8)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
