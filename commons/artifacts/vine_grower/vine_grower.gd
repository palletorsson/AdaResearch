extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VineGrower

## @identity
## lineage: the gardener's trellis — a climbing vine grown on a frame by one rule
## essence: A trellis device with a vine grown up it from a single rewrite rule.
##   The frame is the scaffold; the vine is the grammar that found it. The climb
##   is not planned — the vine forks, leans, and the lattice happens to be there.
## truth: "Branching is cheaper than planning." The vine spends symbols, not
##   foresight; the trellis lends the structure the rule never had to encode.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle_deg: float = 24.0
@export var step_len: float = 0.08
@export var base_col: Color = Color(0.20, 0.45, 0.18)
@export var tip_col: Color = Color(0.60, 0.85, 0.35)
@export var sway_amount: float = 0.025

var _vine: MultiMeshInstance3D = null


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
	_vine = null
	_build()


func _build() -> void:
	# Device base.
	var wood := _matte_mat(Color(0.34, 0.24, 0.16), 0.85)
	add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.5, 0.06, 0.3), wood))

	# Trellis frame — a lattice the vine climbs.
	var lat := _matte_mat(Color(0.50, 0.40, 0.28), 0.7)
	var top_y: float = 1.0
	# Two uprights.
	add_child(_cylinder(Vector3(-0.18, top_y * 0.5, 0.0), 0.012, top_y, lat))
	add_child(_cylinder(Vector3(0.18, top_y * 0.5, 0.0), 0.012, top_y, lat))
	# Horizontal rungs.
	for r in range(4):
		var ry: float = 0.2 + float(r) * 0.24
		var rung: MeshInstance3D = _cylinder(Vector3(0.0, ry, 0.0), 0.01, 0.36, lat)
		rung.rotation.z = PI * 0.5
		add_child(rung)

	# Vine L-system — climbs upward (axiom leans the grammar up the frame).
	var axiom := "F"
	var rules := {"F": "F[+&F]F[-^F][/F]"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle_deg,
		"step_len": step_len,
		"step_shrink": 0.84,
		"base_width": 0.014,
		"width_shrink": 0.78,
		"seed": _rng.randi(),
	})
	_vine = LST.to_tubes(walk, base_col, tip_col, 5)
	# Fit the vine to the trellis height, rooted at the base.
	_scale_plant_to(_vine, 0.95)
	_vine.position = Vector3(0.0, 0.06, 0.02)
	add_child(_vine)

	add_child(_billboard_label("Coral & vines", Vector3(0.0, 1.18, 0.0), 24, tip_col))
	add_child(_billboard_label("VINE TRELLIS", Vector3(0.0, 1.34, 0.0), 20, Color(0.85, 0.95, 0.78)))


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
	if _vine == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	_vine.rotation.z = sin(t * 0.5) * sway_amount
