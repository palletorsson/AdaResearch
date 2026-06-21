extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ColonizationGrower

## @identity
## name: "Space colonization"
## tier: applied
## lineage: the space-colonization rule turned into a live grower — venation/branching unfolding one
##   step per tick instead of resolved all at once.
## essence: a ~1m device. A food cloud hangs over a dish; a root climbs into it live — every ~0.4s the
##   algorithm runs one round (attractors pull their nearest nodes, each sprouts a step, reached food is
##   eaten) and the new branch segments appear. A readout counts the nodes and the food left. When the
##   cloud is consumed (or the cap is hit) it reseeds a fresh cloud and starts over. Growth you can watch.
## truth: the branch finds the food one reach at a time — a tree is a search you can see happen.

@export var grower_seed: int = 5
@export var attractor_count: int = 90
@export var node_cap: int = 130
@export var influence_radius: float = 0.42
@export var kill_radius: float = 0.09
@export var step: float = 0.05
@export var tick_interval: float = 0.4
@export var hold_after: float = 2.2
@export var cloud_size: Vector3 = Vector3(0.7, 0.6, 0.6)
@export var branch_col: Color = Color(0.52, 0.38, 0.25)
@export var tip_col: Color = Color(0.45, 0.78, 0.36)
@export var attractor_col: Color = Color(0.4, 0.8, 0.96)
@export var label_col: Color = Color(0.82, 0.95, 0.88)

const BASE_Y: float = 0.85

var _grow: Node3D = null
var _food: Node3D = null
var _readout: Label3D = null
var _rng_run := RandomNumberGenerator.new()
var _attractors: Array[Vector3] = []
var _alive: Array[bool] = []
var _nodes: Array[Vector3] = []
var _depths: Array[int] = []
var _remaining: int = 0
var _t: float = 0.0
var _done: bool = false
var _hold_t: float = 0.0
var _generation: int = 1


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grower_seed"):
		grower_seed = int(config["grower_seed"])
	if config.has("attractor_count"):
		attractor_count = clampi(int(config["attractor_count"]), 30, 300)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_grow = null
	_food = null
	_readout = null
	_build()


func _build() -> void:
	# device — a dish on a stem
	add_child(_cylinder(Vector3(0.0, BASE_Y - 0.02, 0.0), 0.36, 0.05, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_cylinder(Vector3(0.0, (BASE_Y - 0.06) * 0.5, 0.0), 0.05, BASE_Y - 0.06, _steel_mat(Color(0.26, 0.28, 0.33))))
	add_child(_box(Vector3(0.0, 0.025, 0.0), Vector3(0.42, 0.05, 0.42), _matte_mat(Color(0.14, 0.15, 0.18), 0.9)))
	add_child(_billboard_label("COLONIZATION GROWER\na tree is a search you can watch", Vector3(0.0, BASE_Y + 1.05, 0.0), 16, label_col))

	_grow = Node3D.new()
	_grow.position = Vector3(0.0, BASE_Y, 0.0)
	add_child(_grow)
	_food = Node3D.new()
	_food.position = Vector3(0.0, BASE_Y, 0.0)
	add_child(_food)

	_readout = _billboard_label("NODES 1\nFOOD 0", Vector3(0.0, BASE_Y + 0.78, 0.0), 18, Color(0.6, 0.95, 0.7))
	add_child(_readout)

	_generation = 1
	_seed_cloud()


# Reset the food cloud and the root — start a fresh growth run.
func _seed_cloud() -> void:
	_rng_run.seed = grower_seed + _generation * 1013
	_attractors.clear()
	_alive.clear()
	for _i in range(attractor_count):
		var p := Vector3(
			(_rng_run.randf() - 0.5) * cloud_size.x,
			_rng_run.randf() * cloud_size.y + 0.14,
			(_rng_run.randf() - 0.5) * cloud_size.z
		)
		_attractors.append(p)
		_alive.append(true)
	_nodes = [Vector3(0.0, 0.04, 0.0)]
	_depths = [0]
	_remaining = attractor_count
	_done = false
	_t = 0.0
	_hold_t = 0.0
	_clear(_grow)
	_redraw_food()
	if _readout != null:
		_readout.text = "GEN %d   NODES 1\nFOOD %d" % [_generation, _remaining]


func _clear(n: Node3D) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


# One round of the space-colonization algorithm. Returns true if anything grew.
func _grow_step() -> bool:
	if _nodes.size() >= node_cap or _remaining <= 0:
		return false
	var pull := {}
	var pull_n := {}
	for ai in range(_attractors.size()):
		if not _alive[ai]:
			continue
		var a: Vector3 = _attractors[ai]
		var best_i: int = -1
		var best_d: float = influence_radius
		for ni in range(_nodes.size()):
			var d: float = a.distance_to(_nodes[ni])
			if d < best_d:
				best_d = d
				best_i = ni
		if best_i >= 0:
			var dir: Vector3 = (a - _nodes[best_i]).normalized()
			if pull.has(best_i):
				pull[best_i] += dir
				pull_n[best_i] += 1
			else:
				pull[best_i] = dir
				pull_n[best_i] = 1
	if pull.is_empty():
		return false

	var max_depth: int = 1
	for d in _depths:
		max_depth = maxi(max_depth, d)

	for ni in pull.keys():
		if _nodes.size() >= node_cap:
			break
		var avg: Vector3 = (pull[ni] as Vector3) / float(pull_n[ni])
		if avg.length() < 0.0001:
			continue
		var new_p: Vector3 = _nodes[ni] + avg.normalized() * step
		var new_index: int = _nodes.size()
		var frac: float = float(_depths[ni] + 1) / float(max_depth + 2)
		var radius: float = lerpf(0.011, 0.003, clampf(frac, 0.0, 1.0))
		var col: Color = branch_col.lerp(tip_col, clampf(frac, 0.0, 1.0))
		var mat: StandardMaterial3D = _matte_mat(col, 0.85) if frac < 0.55 else _glow_mat(col, 0.5)
		_grow.add_child(_cylinder_between(_nodes[ni], new_p, radius, mat))
		_nodes.append(new_p)
		_depths.append(_depths[ni] + 1)

	# eat reached food
	for ai in range(_attractors.size()):
		if not _alive[ai]:
			continue
		for ni in range(_nodes.size()):
			if _attractors[ai].distance_to(_nodes[ni]) < kill_radius:
				_alive[ai] = false
				_remaining -= 1
				break
	return true


# Redraw the surviving food motes.
func _redraw_food() -> void:
	_clear(_food)
	var glow := _glow_mat(attractor_col, 0.6)
	for ai in range(_attractors.size()):
		if _alive[ai]:
			_food.add_child(_sphere(_attractors[ai], 0.006, glow))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _grow == null:
		return
	if _done:
		# hold the finished tree a moment, then reseed
		_hold_t += delta
		if _hold_t >= hold_after:
			_generation += 1
			_seed_cloud()
		return
	_t += delta
	if _t < tick_interval:
		return
	_t = 0.0
	var advanced: bool = _grow_step()
	_redraw_food()
	if _readout != null:
		_readout.text = "GEN %d   NODES %d\nFOOD %d" % [_generation, _nodes.size(), _remaining]
	if not advanced or _nodes.size() >= node_cap or _remaining <= 0:
		_done = true
		_hold_t = 0.0
