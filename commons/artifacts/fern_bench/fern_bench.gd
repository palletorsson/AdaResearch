extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FernBench

## @identity
## lineage: Lindenmayer 1968 → turtle graphics → the fractal-plant grammar
## essence: A single fern grown on a bench from one rewrite rule. The frond
##   is built of fronds; the leaf is the plant scaled down and rotated.
## truth: "The leaf is the plant is the frond." Self-similarity all the way down —
##   there is no separate blueprint for the part and the whole; one rule serves both.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle_deg: float = 22.0
@export var step_len: float = 0.07
@export var base_col: Color = Color(0.12, 0.45, 0.14)
@export var tip_col: Color = Color(0.55, 0.85, 0.30)
@export var sway_amount: float = 0.03

var _plant: MultiMeshInstance3D = null


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
	_plant = null
	_build()


func _build() -> void:
	# Housing — a low bench.
	var wood := _matte_mat(Color(0.30, 0.22, 0.16), 0.85)
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), wood))
	# Top plate.
	add_child(_box(Vector3(0.0, 0.86, 0.0), Vector3(1.15, 0.05, 0.75), _matte_mat(Color(0.42, 0.31, 0.22), 0.7)))
	# Small pot the fern grows from.
	var pot := _matte_mat(Color(0.45, 0.27, 0.20), 0.7)
	add_child(_cylinder(Vector3(0.0, 0.94, 0.0), 0.12, 0.16, pot))
	add_child(_cylinder(Vector3(0.0, 1.0, 0.0), 0.10, 0.04, _matte_mat(Color(0.18, 0.12, 0.08), 0.95)))

	# Fern L-system.
	var axiom := "X"
	var rules := {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle_deg,
		"step_len": step_len,
		"step_shrink": 0.8,
		"base_width": 0.018,
		"width_shrink": 0.7,
		"seed": _rng.randi(),
	})
	_plant = LST.to_tubes(walk, base_col, tip_col, 6)
	# Sit the fern ON TOP of the bench, ~0.7m tall.
	_scale_plant_to(_plant, 0.7)
	_plant.position = Vector3(0.0, 1.02, 0.0)
	add_child(_plant)

	add_child(_billboard_label("Ferns & self-similar plants", Vector3(0.0, 1.42, 0.0), 26, tip_col))
	add_child(_billboard_label("THE LEAF IS THE PLANT IS THE FROND", Vector3(0.0, 1.62, 0.0), 18, Color(0.85, 0.95, 0.8)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	# Estimate plant span from segment origins (the unit-cylinder AABB is not the plant).
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
	if _plant == null:
		return
	# Gentle frond curl/sway — a slow lean, never a rebuild.
	var t: float = Time.get_ticks_msec() / 1000.0
	_plant.rotation.z = sin(t * 0.6) * sway_amount
	_plant.rotation.x = cos(t * 0.45) * sway_amount * 0.5
