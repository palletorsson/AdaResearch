extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HilbertBench

## @identity
## lineage: space-filling curves → Hilbert (1891), the continuous map of [0,1] onto the square
## essence: one unbroken line, folded by a single rewrite rule, until it touches every cell of a grid
## truth: "A LINE THAT FILLS A SQUARE" — dimension is not given, it is generated; a 1D thread becomes 2D area
##
## MEDIUM tier. A 2D Hilbert curve rendered flat on a bench top (to_lines, iters 4).
## The grammar A/B are non-drawing rewrite symbols; only F draws. At 90° the turtle
## stays in one plane and the path never crosses itself.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var curve_span: float = 0.62
@export var trunk_color: Color = Color(0.25, 0.85, 0.95)
@export var tip_color: Color = Color(0.95, 0.45, 0.85)
@export var bench_color: Color = Color(0.18, 0.19, 0.22)


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
	if config.has("curve_span"):
		curve_span = float(config["curve_span"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Bench base
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.12, 0.04, 0.72), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	# Pillar (decorative leg cluster)
	add_child(_cylinder(Vector3(0.0, 0.20, 0.0), 0.05, 0.40, _steel_mat(Color(0.35, 0.37, 0.4))))

	# Hilbert 2D curve. axiom "A", rules per classic Hilbert, angle 90, iters ~4.
	var axiom := "A"
	var rules := {
		"A": "-BF+AFA+FB-",
		"B": "+AF-BFB-FA+",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": 90.0,
		"step_len": 0.08,
		"step_shrink": 1.0,
		"base_width": 0.02,
		"width_shrink": 1.0,
		"seed": 1,
	})

	var curve: MeshInstance3D = LST.to_lines(walk, trunk_color, tip_color)
	# The turtle starts heading UP (+Y); Hilbert with 90° rolls stays planar but in
	# the X/Y-ish plane. Lay it flat onto the bench top and centre it.
	curve.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	# Normalise to the bench top footprint.
	var raw_span: float = 0.08 * float(pow(2, iters) - 1)
	var s: float = curve_span / maxf(raw_span, 0.001)
	curve.scale = Vector3.ONE * s
	curve.position = Vector3(-curve_span * 0.5, 0.88, curve_span * 0.5)
	add_child(curve)

	# Corner dots mark the square the line fills.
	var dot_mat := _glow_mat(tip_color, 1.4)
	var hs := curve_span * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_sphere(Vector3(float(sx) * hs, 0.88, float(sz) * hs), 0.012, dot_mat))

	add_child(_billboard_label("A LINE THAT FILLS A SQUARE", Vector3(0.0, 1.6, 0.0), 28, trunk_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Static artifact — no rebuild. Gentle idle only.
	pass
