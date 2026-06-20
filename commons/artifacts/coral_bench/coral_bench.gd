extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CoralBench

## @identity
## lineage: branching corals & climbing vines — growth as a greedy local rule
## essence: A 3D coral on a bench, grown by one rewrite rule that forks in three
##   directions and pitches off-plane. No coral plans its silhouette; each polyp
##   only knows the local rule, and the reef-shape is the sum of that.
## truth: "Branching is cheaper than planning." A fork costs one symbol; a designed
##   form costs a blueprint. Evolution buys the fork.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle_deg: float = 25.0
@export var step_len: float = 0.07
@export var base_col: Color = Color(0.85, 0.35, 0.30)
@export var tip_col: Color = Color(0.98, 0.70, 0.55)
@export var sway_amount: float = 0.02

var _coral: MultiMeshInstance3D = null


func _expand(axiom: String, rules: Dictionary, n: int) -> String:
	var s := axiom
	for _i in range(n):
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
	emissive = bool(config.get("emissive", emissive))
	iters = int(config.get("iters", iters))
	angle_deg = float(config.get("angle_deg", angle_deg))
	step_len = float(config.get("step_len", step_len))
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_coral = null
	_build()


func _build() -> void:
	# Bench housing.
	var stone := _matte_mat(Color(0.22, 0.28, 0.33), 0.85)
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), stone))
	add_child(_box(Vector3(0.0, 0.86, 0.0), Vector3(1.15, 0.05, 0.75), _matte_mat(Color(0.30, 0.37, 0.43), 0.7)))
	# A rocky base the coral roots on.
	add_child(_sphere(Vector3(0.0, 0.92, 0.0), 0.13, _matte_mat(Color(0.35, 0.30, 0.28), 0.95)))

	# 3D coral L-system: fork-of-three with pitch & roll added for off-plane growth.
	var axiom := "F"
	var rules := {"F": "FF-[-F+&F+^F]+[+F-&F-^F]"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle_deg,
		"step_len": step_len,
		"step_shrink": 0.78,
		"base_width": 0.028,
		"width_shrink": 0.72,
		"seed": _rng.randi(),
	})
	_coral = LST.to_tubes(walk, base_col, tip_col, 6)
	_scale_plant_to(_coral, 0.7)
	_coral.position = Vector3(0.0, 0.96, 0.0)
	add_child(_coral)

	add_child(_billboard_label("Coral & vines", Vector3(0.0, 1.42, 0.0), 26, tip_col))
	add_child(_billboard_label("BRANCHING IS CHEAPER THAN PLANNING", Vector3(0.0, 1.62, 0.0), 18, Color(0.98, 0.88, 0.82)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	var span: float = maxf(_plant_height(node), 0.001)
	var s: float = clampf(target_h / span, 0.05, 8.0)
	node.scale = Vector3.ONE * s


func _plant_height(node: MultiMeshInstance3D) -> float:
	var mm: MultiMesh = node.multimesh
	var min_y := INF
	var max_y := -INF
	for i in range(mm.instance_count):
		var o: Vector3 = mm.get_instance_transform(i).origin
		min_y = minf(min_y, o.y)
		max_y = maxf(max_y, o.y)
	if min_y == INF:
		return 1.0
	return max_y - min_y


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _coral == null:
		return
	# Slow underwater drift.
	var t: float = Time.get_ticks_msec() / 1000.0
	_coral.rotation.z = sin(t * 0.4) * sway_amount
	_coral.rotation.x = cos(t * 0.33) * sway_amount
