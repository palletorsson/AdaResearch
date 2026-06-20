extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ContextPruner

## @identity
## title: Context-sensitive L-systems
## truth: "let a symbol read its neighbours and the plant answers its world"
##
## APPLIED: a desk device. A tree grows against a solid obstacle wall; every
## branch segment whose end would cross into the obstacle is trimmed before the
## mesh is built — context-sensitive pruning. The obstacle is shown, so you can
## see the tree bend away from the neighbour it is reading. It answers its world.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var angle: float = 24.0
@export var iterations: int = 5
@export var step_len: float = 0.06
@export var wall_x: float = 0.22
@export var base_col: Color = Color(0.40, 0.27, 0.16)
@export var tip_col: Color = Color(0.52, 0.84, 0.36)

var _plant_root: Node3D = null


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
	if config.has("wall_x"):
		wall_x = float(config["wall_x"])
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
	# ~1m device: base + planter offset to one side so the tree grows toward the wall
	add_child(_box(Vector3(0, 0.05, 0), Vector3(0.7, 0.10, 0.5), _matte_mat(Color(0.15, 0.16, 0.19), 0.9)))
	add_child(_cylinder(Vector3(-0.12, 0.42, 0), 0.05, 0.64, _steel_mat(Color(0.55, 0.57, 0.62))))
	add_child(_cylinder(Vector3(-0.12, 0.74, 0), 0.12, 0.08, _matte_mat(Color(0.27, 0.20, 0.14), 0.85)))

	# the obstacle wall — a solid slab the tree is pruned against
	var wall_mat := _matte_mat(Color(0.55, 0.30, 0.28), 0.7, 0.2)
	# wall plane is at local-x = (wall_x - planter_origin_x). Draw it there.
	var wall_local_x: float = wall_x - (-0.12)
	add_child(_box(Vector3(-0.12 + wall_local_x, 0.95, 0), Vector3(0.04, 0.55, 0.45), wall_mat))
	add_child(_billboard_label("obstacle", Vector3(-0.12 + wall_local_x, 1.30, 0), 18, Color(0.95, 0.55, 0.50)))

	# the pruned plant
	_plant_root = Node3D.new()
	_plant_root.position = Vector3(-0.12, 0.78, 0)
	add_child(_plant_root)
	_grow_pruned(_plant_root)

	add_child(_billboard_label("CONTEXT PRUNER", Vector3(-0.12, 1.5, 0), 34, Color(0.78, 0.90, 0.80)))


func _grow_pruned(parent: Node3D) -> void:
	# bias the grammar to push branches sideways toward the wall
	var rules := {
		"X": "F+[[X]+X]-F[+FX]+X",
		"F": "FF",
	}
	var s := _expand("X", rules, iterations)
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle,
		"step_len": step_len,
		"step_shrink": 0.80,
		"base_width": 0.020,
		"width_shrink": 0.66,
		"seed": 5,
	})

	# CONTEXT-SENSITIVE: obstacle is at worldspace x = wall_x; in the plant's
	# local frame that is (wall_x - origin_x). Drop any segment that reaches it.
	var limit_x: float = wall_x - parent.position.x
	var kept: Array = []
	for seg: Array in walk.get("segments", []):
		var end_p: Vector3 = seg[1]
		if end_p.x < limit_x:
			kept.append(seg)

	var trimmed := {
		"segments": kept,
		"leaves": [],
		"branch_points": [],
		"final_length": walk.get("final_length", 0.0),
	}
	var plant: MultiMeshInstance3D = LST.to_tubes(trimmed, base_col, tip_col, 6)
	parent.add_child(plant)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _plant_root != null:
		_plant_root.rotation.z = sin(Time.get_ticks_msec() * 0.0008) * 0.02
