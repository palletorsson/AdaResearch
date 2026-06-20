extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FernPress

## @identity
## lineage: the botanist's flower press meets the fractal-plant grammar
## essence: A fern grown by one rewrite rule, then flattened to z≈0 and pinned
##   between two glass plates in a screw-press frame. The press is the moment the
##   3D recursion is projected to a 2D specimen — the herbarium of an algorithm.
## truth: "The leaf is the plant is the frond" — even pressed flat, the part still
##   holds the shape of the whole. Self-similarity survives projection.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle_deg: float = 22.0
@export var base_col: Color = Color(0.20, 0.40, 0.16)
@export var tip_col: Color = Color(0.55, 0.78, 0.30)

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
	base_col = _parse_color(config.get("base_col"), base_col)
	tip_col = _parse_color(config.get("tip_col"), tip_col)
	for c in get_children():
		c.queue_free()
	_plant = null
	_build()


func _build() -> void:
	# Stand — small device ~1m.
	var steel := _steel_mat(Color(0.55, 0.57, 0.6))
	add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(0.6, 0.06, 0.4), steel))           # base plate
	add_child(_cylinder(Vector3(-0.26, 0.35, -0.16), 0.02, 0.6, steel))               # corner posts
	add_child(_cylinder(Vector3(0.26, 0.35, -0.16), 0.02, 0.6, steel))
	add_child(_cylinder(Vector3(-0.26, 0.35, 0.16), 0.02, 0.6, steel))
	add_child(_cylinder(Vector3(0.26, 0.35, 0.16), 0.02, 0.6, steel))

	# Pressing frame — two glass plates with the fern pinned between.
	var glass := _glass_mat(Color(0.7, 0.85, 0.9), 0.22)
	var press_y: float = 0.62
	# Back plate (slightly behind the fern).
	add_child(_box(Vector3(0.0, press_y, -0.025), Vector3(0.5, 0.55, 0.012), glass))
	# Front plate (slightly in front).
	add_child(_box(Vector3(0.0, press_y, 0.025), Vector3(0.5, 0.55, 0.012), glass))
	# Wing screws that clamp the plates.
	add_child(_cylinder(Vector3(-0.20, press_y, 0.0), 0.025, 0.09, steel))
	add_child(_cylinder(Vector3(0.20, press_y, 0.0), 0.025, 0.09, steel))
	(get_child(get_child_count() - 2) as MeshInstance3D).rotation.x = PI * 0.5
	(get_child(get_child_count() - 1) as MeshInstance3D).rotation.x = PI * 0.5

	# Fern L-system — built, then PRESSED flat (z scaled to near-zero).
	var axiom := "X"
	var rules := {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle_deg,
		"step_len": 0.07,
		"step_shrink": 0.8,
		"base_width": 0.012,
		"width_shrink": 0.7,
		"seed": _rng.randi(),
	})
	_plant = LST.to_tubes(walk, base_col, tip_col, 5)
	# Scale to fit the plate, then flatten depth → a pressed specimen.
	var span: float = maxf(_plant_height(_plant), 0.001)
	var fit: float = clampf(0.46 / span, 0.05, 6.0)
	_plant.scale = Vector3(fit, fit, fit * 0.04)
	# Sit it inside the glass, growing up from the base of the plate.
	_plant.position = Vector3(0.0, press_y - 0.24, 0.0)
	add_child(_plant)

	add_child(_billboard_label("Ferns & self-similar plants", Vector3(0.0, 1.02, 0.0), 24, tip_col))
	add_child(_billboard_label("FERN PRESS", Vector3(0.0, 1.18, 0.0), 20, Color(0.9, 0.95, 0.85)))


func _plant_height(node: MultiMeshInstance3D) -> float:
	var mm: MultiMesh = node.multimesh
	if mm == null:
		return 1.0
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
	# Pressed specimen is static — nothing to sway.
