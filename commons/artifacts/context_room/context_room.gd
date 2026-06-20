extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ContextRoom

## @identity
## title: Context-sensitive L-systems
## truth: "let a symbol read its neighbours and the plant answers its world"
##
## Room-scale: a tree PRUNED by its world. A faint ceiling plane caps the room;
## every branch segment whose end would pass that ceiling is dropped before the
## mesh is built — so the tree flattens and spreads into the space it is given.
## The boundary is the neighbour the symbols read. The plant answers its world.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var angle: float = 26.0
@export var iterations: int = 5
@export var step_len: float = 0.34
@export var ceiling_y: float = 2.6
@export var base_col: Color = Color(0.38, 0.26, 0.15)
@export var tip_col: Color = Color(0.50, 0.82, 0.34)

var _sway_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("iterations"):
		iterations = int(config["iterations"])
	if config.has("step_len"):
		step_len = float(config["step_len"])
	if config.has("ceiling_y"):
		ceiling_y = float(config["ceiling_y"])
	if config.has("base_col"):
		base_col = _parse_color(config["base_col"], base_col)
	if config.has("tip_col"):
		tip_col = _parse_color(config["tip_col"], tip_col)
	for c in get_children():
		c.queue_free()
	_build()


func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in range(iters):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# room floor
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.13, 0.14, 0.17), 0.95)))
	# rooted stump
	add_child(_cylinder(Vector3(0, 0.10, 0), 0.28, 0.20, _matte_mat(Color(0.25, 0.18, 0.12), 0.9)))

	# faint boundary plane — the ceiling that prunes the tree
	var glass := _glass_mat(Color(0.4, 0.7, 1.0), 0.12)
	add_child(_box(Vector3(0, ceiling_y, 0), Vector3(6.8, 0.02, 6.8), glass))

	# the pruned tree
	_sway_root = Node3D.new()
	_sway_root.position = Vector3(0, 0.18, 0)
	add_child(_sway_root)
	_grow_pruned(_sway_root)

	add_child(_billboard_label("THE PLANT ANSWERS ITS WORLD", Vector3(0, 3.6, 0), 60, Color(0.80, 0.92, 0.78)))


func _grow_pruned(parent: Node3D) -> void:
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	var s := _expand("X", rules, iterations)
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle,
		"step_len": step_len,
		"step_shrink": 0.80,
		"base_width": 0.10,
		"width_shrink": 0.64,
		"seed": 3,
	})

	# CONTEXT-SENSITIVE: the tree reads its world. Worldspace ceiling sits at
	# ceiling_y; the plant's local origin is parent.position.y, so the local
	# limit is (ceiling_y - origin_y). Drop any segment whose end passes it.
	var limit: float = ceiling_y - parent.position.y
	var kept: Array = []
	for seg: Array in walk.get("segments", []):
		var end_p: Vector3 = seg[1]
		if end_p.y <= limit:
			kept.append(seg)

	var trimmed := {
		"segments": kept,
		"leaves": [],
		"branch_points": [],
		"final_length": walk.get("final_length", 0.0),
	}
	var plant: MultiMeshInstance3D = LST.to_tubes(trimmed, base_col, tip_col, 8)
	parent.add_child(plant)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _sway_root != null:
		_sway_root.rotation.z = sin(Time.get_ticks_msec() * 0.0006) * 0.014
