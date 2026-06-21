extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ColonizationBench

## @identity
## name: "Space colonization"
## tier: medium
## lineage: Runions et al. — the venation/branching algorithm where leaves (attractors) summon the vein
##   toward them. Growth is pulled, not pushed; the form is the negative of where the food was.
## essence: ~120 attractor points scatter in a volume above the bench. A single root grows upward: each
##   attractor tugs its nearest node, every tugged node sprouts one new node a step along the averaged
##   pull, and any attractor the tree reaches is consumed. ~150 nodes of branch fall out — a little tree
##   that drew itself toward what fed it. Built once (deterministic seed); rendered as tapering tubes.
## truth: branches grow toward what they feed on — the shape is the memory of a hunger answered.

@export var bench_seed: int = 7
@export var attractor_count: int = 120
@export var node_cap: int = 150
@export var influence_radius: float = 0.34
@export var kill_radius: float = 0.075
@export var step: float = 0.045
@export var cloud_size: Vector3 = Vector3(0.7, 0.62, 0.6)
@export var branch_col: Color = Color(0.55, 0.40, 0.26)
@export var tip_col: Color = Color(0.42, 0.72, 0.34)
@export var attractor_col: Color = Color(0.4, 0.78, 0.95)
@export var label_col: Color = Color(0.78, 0.95, 0.86)

const BASE_Y: float = 0.85

var _root: Node3D = null
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bench_seed"):
		bench_seed = int(config["bench_seed"])
	if config.has("attractor_count"):
		attractor_count = clampi(int(config["attractor_count"]), 20, 400)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_root = null
	_build()


func _build() -> void:
	# bench
	add_child(_box(Vector3(0.0, BASE_Y - 0.09, 0.0), Vector3(1.2, 0.18, 0.7), _matte_mat(Color(0.16, 0.17, 0.2), 0.85)))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.18) * 0.5, 0.0), 0.07, BASE_Y - 0.18, _steel_mat(Color(0.32, 0.34, 0.4))))
	add_child(_billboard_label("SPACE COLONIZATION\nbranches grow toward what they feed on", Vector3(0.0, BASE_Y + 0.95, 0.0), 17, label_col))

	# the tree grows in its own little holder above the bench top
	_root = Node3D.new()
	_root.position = Vector3(0.0, BASE_Y, 0.0)
	add_child(_root)

	# deterministic run
	var rng := RandomNumberGenerator.new()
	rng.seed = bench_seed

	# attractor cloud — a dome of food above the root
	var attractors: Array[Vector3] = []
	var alive: Array[bool] = []
	for _i in range(attractor_count):
		var p := Vector3(
			(rng.randf() - 0.5) * cloud_size.x,
			rng.randf() * cloud_size.y + 0.12,
			(rng.randf() - 0.5) * cloud_size.z
		)
		attractors.append(p)
		alive.append(true)

	# nodes — start with a single root at the bench top
	var nodes: Array[Vector3] = [Vector3(0.0, 0.02, 0.0)]
	var parents: Array[int] = [-1]
	var depths: Array[int] = [0]
	var edges: Array = []   # [from_index, to_index]

	var remaining: int = attractor_count
	var safety: int = 0
	while nodes.size() < node_cap and remaining > 0 and safety < node_cap * 4:
		safety += 1
		# accumulate pull per node from every attractor that owns it
		var pull := {}        # node_index -> Vector3 summed direction
		var pull_n := {}      # node_index -> count
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			var a: Vector3 = attractors[ai]
			# nearest node within influence radius
			var best_i: int = -1
			var best_d: float = influence_radius
			for ni in range(nodes.size()):
				var d: float = a.distance_to(nodes[ni])
				if d < best_d:
					best_d = d
					best_i = ni
			if best_i >= 0:
				var dir: Vector3 = (a - nodes[best_i]).normalized()
				if pull.has(best_i):
					pull[best_i] += dir
					pull_n[best_i] += 1
				else:
					pull[best_i] = dir
					pull_n[best_i] = 1
		if pull.is_empty():
			break
		# grow a new node from each pulled node along the averaged direction
		for ni in pull.keys():
			if nodes.size() >= node_cap:
				break
			var avg: Vector3 = (pull[ni] as Vector3) / float(pull_n[ni])
			if avg.length() < 0.0001:
				continue
			var new_p: Vector3 = nodes[ni] + avg.normalized() * step
			var new_index: int = nodes.size()
			nodes.append(new_p)
			parents.append(ni)
			depths.append(depths[ni] + 1)
			edges.append([ni, new_index])
		# kill attractors the tree has reached
		for ai in range(attractors.size()):
			if not alive[ai]:
				continue
			for ni in range(nodes.size()):
				if attractors[ai].distance_to(nodes[ni]) < kill_radius:
					alive[ai] = false
					remaining -= 1
					break

	# render edges as tapering tubes — thicker at the root, greener at the tips
	var max_depth: int = 1
	for d in depths:
		max_depth = maxi(max_depth, d)
	var branch_mat := _matte_mat(branch_col, 0.85)
	for e in edges:
		var fi: int = e[0]
		var ti: int = e[1]
		var frac: float = float(depths[ti]) / float(max_depth)
		var radius: float = lerpf(0.012, 0.003, frac)
		var col: Color = branch_col.lerp(tip_col, clampf(frac, 0.0, 1.0))
		var mat: StandardMaterial3D = branch_mat if frac < 0.55 else _glow_mat(col, 0.5)
		_root.add_child(_cylinder_between(nodes[fi], nodes[ti], radius, mat))

	# a few faint surviving attractors, to show the food it never reached
	var glow := _glow_mat(attractor_col, 0.6)
	var shown: int = 0
	for ai in range(attractors.size()):
		if alive[ai] and shown < 30:
			_root.add_child(_sphere(attractors[ai], 0.006, glow))
			shown += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _root == null:
		return
	# gentle sway — the finished tree breathes
	_t += delta
	_root.rotation.y = sin(_t * 0.4) * 0.08
