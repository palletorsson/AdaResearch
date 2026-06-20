extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BracketPruner

## @identity
## lineage: bracketed branching, bounded — pruning a recursive grammar by capping how deep the stack may go
## essence: the pruner refuses to descend past a depth; every branch beyond the limit is simply never drawn
## truth: "BRANCH PRUNER" — recursion without a base case is infinite; the cut is what makes the tree finite and shaped
##
## APPLIED tier. A device (~1m): a bracketed tree pre-pruned to a maximum branch depth,
## with a clipper tool on an arm poised at the cut line. The tree is built then filtered:
## any segment whose turtle-depth exceeds max_depth is removed before rendering.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle_deg: float = 22.5
@export var max_depth: int = 3
@export var device_height: float = 0.9
@export var trunk_color: Color = Color(0.42, 0.28, 0.17)
@export var tip_color: Color = Color(0.45, 0.85, 0.40)
@export var cut_color: Color = Color(0.95, 0.30, 0.25)
@export var base_color: Color = Color(0.16, 0.17, 0.20)


func _expand(axiom: String, rules: Dictionary, iter_count: int) -> String:
	var s := axiom
	for _i in range(iter_count):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle_deg"):
		angle_deg = float(config["angle_deg"])
	if config.has("max_depth"):
		max_depth = int(config["max_depth"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Device base plate.
	add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.7, 0.06, 0.7), _matte_mat(base_color, 0.6)))
	add_child(_cylinder(Vector3(0.0, 0.10, 0.0), 0.12, 0.08, _steel_mat(Color(0.35, 0.37, 0.4))))

	# Bracketed plant.
	var axiom := "X"
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": angle_deg,
		"step_len": 0.05,
		"step_shrink": 0.82,
		"base_width": 0.02,
		"width_shrink": 0.74,
		"seed": 5,
	})

	# PRUNE: drop every segment beyond max_depth before rendering.
	var pruned := _prune_walk(walk, max_depth)
	var plant: MultiMeshInstance3D = LST.to_tubes(pruned, trunk_color, tip_color, 6)
	var raw_h: float = _walk_height(pruned)
	var s: float = device_height / maxf(raw_h, 0.001)
	plant.scale = Vector3.ONE * s
	plant.position = Vector3(0.0, 0.14, 0.0)
	add_child(plant)

	# Cut line: a thin red disc at the height where pruning happened.
	var cut_y := 0.14 + device_height * _depth_height_fraction(walk, max_depth)
	add_child(_torus(Vector3(0.0, cut_y, 0.0), 0.22, 0.006, _glow_mat(cut_color, 1.6)))

	# Clipper tool on an arm, poised at the cut line.
	_build_clipper(Vector3(0.30, cut_y, 0.0))

	add_child(_billboard_label("BRANCH PRUNER", Vector3(0.0, device_height + 0.30, 0.0), 22, cut_color))


func _build_clipper(cut_point: Vector3) -> void:
	# Arm from base post to the cut point.
	var arm_mat := _steel_mat(Color(0.4, 0.42, 0.45))
	var anchor := Vector3(0.34, 0.20, 0.0)
	add_child(_cylinder_between(anchor, cut_point, 0.012, arm_mat))
	# Two clipper blades meeting at the cut point.
	var blade_mat := _glow_mat(cut_color, 1.2)
	var open := Vector3(0.05, 0.04, 0.0)
	add_child(_cylinder_between(cut_point, cut_point + open, 0.008, blade_mat))
	add_child(_cylinder_between(cut_point, cut_point + Vector3(open.x, -open.y, 0.0), 0.008, blade_mat))
	# Pivot bolt.
	add_child(_sphere(cut_point, 0.012, _steel_mat(Color(0.6, 0.62, 0.65))))


# Keep only segments at depth <= limit, re-emit as a walk dict for to_tubes.
func _prune_walk(walk: Dictionary, limit: int) -> Dictionary:
	var segments: Array = walk["segments"]
	var kept: Array = []
	for seg: Array in segments:
		var d: int = int(seg[2])
		if d <= limit:
			kept.append(seg)
	var leaves: Array = []
	# Leaves carry no depth in the engine; keep them only if anything survived.
	if not kept.is_empty():
		leaves = walk.get("leaves", [])
	return {
		"segments": kept,
		"leaves": leaves,
		"branch_points": walk.get("branch_points", []),
		"final_length": walk.get("final_length", 0.0),
	}


func _walk_height(walk: Dictionary) -> float:
	var segments: Array = walk["segments"]
	var min_y := 1e9
	var max_y := -1e9
	for seg: Array in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		min_y = minf(min_y, minf(a.y, b.y))
		max_y = maxf(max_y, maxf(a.y, b.y))
	if max_y <= min_y:
		return 1.0
	return max_y - min_y


# Where, as a 0..1 fraction of full height, the prune-depth band sits.
func _depth_height_fraction(walk: Dictionary, limit: int) -> float:
	var segments: Array = walk["segments"]
	var full_min := 1e9
	var full_max := -1e9
	var cut_max := -1e9
	for seg: Array in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var lo := minf(a.y, b.y)
		var hi := maxf(a.y, b.y)
		full_min = minf(full_min, lo)
		full_max = maxf(full_max, hi)
		if int(seg[2]) <= limit:
			cut_max = maxf(cut_max, hi)
	if full_max <= full_min or cut_max < full_min:
		return 0.6
	return clampf((cut_max - full_min) / (full_max - full_min), 0.1, 0.95)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
