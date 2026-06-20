extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FernRoom

## @identity
## lineage: one fractal-plant grammar, instanced — a stand of ferns, no two alike
## essence: A room you walk into where several ferns of different size and seed
##   share a single rewrite rule. The variety is in the seed and the scale, not
##   in new rules — the room proves the rule is the species.
## truth: "Self-similarity all the way down." Change the seed, keep the grammar:
##   the part resembles the whole resembles the next fern over.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle_deg: float = 22.0
@export var fern_count: int = 4
@export var base_col: Color = Color(0.10, 0.42, 0.14)
@export var tip_col: Color = Color(0.55, 0.85, 0.30)
@export var sway_amount: float = 0.025

var _ferns: Array[MultiMeshInstance3D] = []


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
	fern_count = int(config.get("fern_count", fern_count))
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	sway_amount = float(config.get("sway_amount", sway_amount))
	for c in get_children():
		c.queue_free()
	_ferns.clear()
	_build()


func _build() -> void:
	# Room floor.
	var floor_mat := _matte_mat(Color(0.14, 0.16, 0.13), 0.95)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))

	var axiom := "X"
	var rules := {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}

	# Scatter ferns of varied size + seed across the floor.
	var n: int = max(fern_count, 1)
	for i in range(n):
		var seed_i: int = _rng.randi()
		var ang: float = angle_deg + _rng.randf_range(-3.0, 3.0)
		var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
			"angle_deg": ang,
			"step_len": 0.07,
			"step_shrink": 0.8,
			"base_width": 0.02,
			"width_shrink": 0.7,
			"seed": seed_i,
		})
		# Warm-to-cool variety per fern.
		var bc: Color = base_col.lerp(Color(0.06, 0.30, 0.18), _rng.randf())
		var tc: Color = tip_col.lerp(Color(0.70, 0.90, 0.45), _rng.randf())
		var fern: MultiMeshInstance3D = LST.to_tubes(walk, bc, tc, 6)

		var target_h: float = _rng.randf_range(2.0, 3.0)
		_scale_plant_to(fern, target_h)

		# Place on the floor in a loose ring.
		var theta: float = TAU * float(i) / float(n) + _rng.randf_range(-0.3, 0.3)
		var radius: float = _rng.randf_range(1.4, 2.6)
		fern.position = Vector3(cos(theta) * radius, 0.0, sin(theta) * radius)
		fern.rotation.y = _rng.randf_range(0.0, TAU)

		# A small earth pad under each.
		add_child(_cylinder(fern.position + Vector3(0.0, 0.02, 0.0), 0.18, 0.06, _matte_mat(Color(0.20, 0.13, 0.09), 0.9)))
		add_child(fern)
		_ferns.append(fern)

	add_child(_billboard_label("Ferns & self-similar plants", Vector3(0.0, 3.4, 0.0), 30, tip_col))
	add_child(_billboard_label("SELF-SIMILARITY ALL THE WAY DOWN", Vector3(0.0, 3.6, 0.0), 22, Color(0.85, 0.95, 0.8)))


func _scale_plant_to(node: MultiMeshInstance3D, target_h: float) -> void:
	if node == null or node.multimesh == null:
		return
	var span: float = maxf(_plant_height(node), 0.001)
	var s: float = clampf(target_h / span, 0.05, 12.0)
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
	var t: float = Time.get_ticks_msec() / 1000.0
	for i in range(_ferns.size()):
		var f: MultiMeshInstance3D = _ferns[i]
		if f == null:
			continue
		var phase: float = float(i) * 0.7
		f.rotation.z = sin(t * 0.5 + phase) * sway_amount
