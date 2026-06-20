extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParametricRoom

## @identity
## title: Parametric L-systems
## truth: "hang numbers on the symbols and the grammar can taper and grow old"
##
## Room-scale: one L-system tree, ~3m tall, where the numbers on the symbols do
## the visible work. The trunk is thick and slow at the base, then every branch
## level shrinks in length and width — taper from trunk to twig. Walk under it.
## The grammar grew old because the symbols carry numbers, not just letters.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var angle: float = 24.0
@export var iterations: int = 5
@export var step_len: float = 0.34
@export var base_col: Color = Color(0.40, 0.27, 0.16)
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
	# a thick rooted base / stump the tree rises from
	add_child(_cylinder(Vector3(0, 0.10, 0), 0.30, 0.20, _matte_mat(Color(0.26, 0.19, 0.13), 0.9)))

	# the tree — parametric taper, ~3m
	_sway_root = Node3D.new()
	_sway_root.position = Vector3(0, 0.18, 0)
	add_child(_sway_root)
	_grow_plant(_sway_root)

	# overhead label
	add_child(_billboard_label("TAPER, BEND, GROW OLD", Vector3(0, 3.6, 0), 64, Color(0.85, 0.95, 0.75)))


func _grow_plant(parent: Node3D) -> void:
	var rules := {
		"X": "F-[[X]+X]+F[+FX]-X",
		"F": "FF",
	}
	var s := _expand("X", rules, iterations)
	# PARAMETRIC: heavy base width, strong width_shrink → clear trunk→twig taper.
	# step_shrink ages each branch level shorter than its parent.
	var walk: Dictionary = LST.walk(s, {
		"angle_deg": angle,
		"step_len": step_len,
		"step_shrink": 0.80,
		"base_width": 0.11,
		"width_shrink": 0.62,
		"seed": 3,
	})
	var plant: MultiMeshInstance3D = LST.to_tubes(walk, base_col, tip_col, 8)
	parent.add_child(plant)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _sway_root != null:
		var t := Time.get_ticks_msec() * 0.0006
		_sway_root.rotation.z = sin(t) * 0.018
		_sway_root.rotation.x = cos(t * 0.8) * 0.012
