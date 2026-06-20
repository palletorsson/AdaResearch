extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParametricBench

## @identity
## title: Parametric L-systems
## truth: "hang numbers on the symbols and the grammar can taper and grow old"
##
## A bench-top tree grown from a single L-system string, but the SYMBOLS carry
## NUMBERS: the branch angle widens with depth, the step length and width shrink
## as the plant climbs. Two dials on the bench suggest the length/angle params
## you could turn. Same grammar, parameterised — so it tapers and looks old.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var angle: float = 22.0
@export var iterations: int = 4
@export var step_len: float = 0.07
@export var base_col: Color = Color(0.45, 0.30, 0.18)
@export var tip_col: Color = Color(0.55, 0.85, 0.35)

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
	# bench base
	add_child(_box(Vector3(0, 0.075, 0), Vector3(1.1, 0.15, 1.1), _matte_mat(Color(0.16, 0.17, 0.20), 0.9)))
	add_child(_box(Vector3(0, 0.78, 0), Vector3(1.0, 0.04, 1.0), _matte_mat(Color(0.22, 0.24, 0.28), 0.8)))
	# pillar holding the planter
	add_child(_cylinder(Vector3(0, 0.45, 0), 0.05, 0.66, _steel_mat(Color(0.55, 0.57, 0.62))))
	# planter pot on top
	add_child(_cylinder(Vector3(0, 0.83, 0), 0.14, 0.10, _matte_mat(Color(0.30, 0.22, 0.16), 0.85)))

	# two dials suggesting length / angle params — "numbers on the symbols"
	var dial_mat := _steel_mat(Color(0.70, 0.72, 0.78))
	var knob_mat := _glow_mat(Color(0.95, 0.65, 0.25), 1.4)
	# angle dial
	add_child(_cylinder(Vector3(-0.34, 0.83, 0.34), 0.06, 0.04, dial_mat))
	add_child(_box(Vector3(-0.34, 0.86, 0.40), Vector3(0.015, 0.04, 0.05), knob_mat))
	add_child(_billboard_label("angle", Vector3(-0.34, 0.96, 0.34), 22, Color(0.95, 0.65, 0.25)))
	# length dial
	add_child(_cylinder(Vector3(0.34, 0.83, 0.34), 0.06, 0.04, dial_mat))
	add_child(_box(Vector3(0.34, 0.86, 0.39), Vector3(0.015, 0.04, 0.05), _glow_mat(Color(0.45, 0.85, 0.95), 1.4)))
	add_child(_billboard_label("len", Vector3(0.34, 0.96, 0.34), 22, Color(0.45, 0.85, 0.95)))

	# the tree — parametric: angle widens with depth, step shrinks
	_sway_root = Node3D.new()
	_sway_root.position = Vector3(0, 0.88, 0)
	add_child(_sway_root)
	_grow_plant(_sway_root)

	# label
	add_child(_billboard_label("HANG NUMBERS ON THE SYMBOLS", Vector3(0, 1.6, 0), 40, Color(0.85, 0.95, 0.75)))


func _grow_plant(parent: Node3D) -> void:
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	var s := _expand("X", rules, iterations)
	# PARAMETRIC: width_shrink < step_shrink so the trunk tapers fast to thin twigs;
	# step_shrink makes each branch level shorter — the plant tapers and ages.
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle,
		"step_len": step_len,
		"step_shrink": 0.78,
		"base_width": 0.024,
		"width_shrink": 0.66,
		"seed": 1,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, base_col, tip_col, 6)
	parent.add_child(plant)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _sway_root != null:
		_sway_root.rotation.z = sin(Time.get_ticks_msec() * 0.0009) * 0.03
