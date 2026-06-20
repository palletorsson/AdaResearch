extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CityBench

## CityBench — Grammar architecture (cities/dungeons), MEDIUM tier.
##
## An orthogonal L-system street/block layout on a bench (angle 90). The
## same engine that grew a tree, pointed at right angles, reads as a
## little city plan: streets, blocks, intersections.
##
## @identity
##   truth: "point the rules at right angles and the same engine grows a city"
##   truth: "the grammar is the DNA, the material is a choice"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "FF+[+F-F-F]-[-F+F+F]"}
@export var iters: int = 3
@export var angle: float = 90.0
@export var c1: Color = Color(0.4, 0.45, 0.55)
@export var c2: Color = Color(0.5, 0.9, 1.0)
@export var sway_amount: float = 0.02


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("axiom"):
		axiom = String(config["axiom"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("c1"):
		c1 = _parse_color(config["c1"], c1)
	if config.has("c2"):
		c2 = _parse_color(config["c2"], c2)
	for child in get_children():
		child.queue_free()
	_build()


func _expand(p_axiom: String, p_rules: Dictionary, p_iters: int) -> String:
	var s := p_axiom
	for _i in range(p_iters):
		var out := ""
		for ch: String in s:
			out += String(p_rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- bench base -----------------------------------------------------------
	var top_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.7)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.06, 0.6), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_cylinder(Vector3(-0.45, 0.42, -0.22), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(0.45, 0.42, -0.22), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(-0.45, 0.42, 0.22), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(0.45, 0.42, 0.22), 0.03, 0.84, leg_mat))

	# --- city plan grown on top -----------------------------------------------
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle, "step_len": 0.08, "step_shrink": 0.85,
		"base_width": 0.02, "width_shrink": 0.8, "seed": 1,
	})

	var holder := Node3D.new()
	# the orthogonal turtle starts heading UP — lay the plan flat on the bench
	holder.position = Vector3(0.0, 0.88, 0.0)
	holder.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	holder.scale = Vector3.ONE * 1.4
	add_child(holder)
	# render streets/blocks as low tube walls
	var tubes: MultiMeshInstance3D = LST.to_tubes(walk, c1, c2, 6)
	holder.add_child(tubes)
	# node dots at intersections for a city-plan read
	var g: Dictionary = LST.to_graph(walk)
	var dot_mat := _glow_mat(c2, 1.2)
	for p: Vector3 in g["positions"]:
		holder.add_child(_sphere(p, 0.012, dot_mat))

	add_child(_billboard_label("GRAMMAR BUILDS A CITY", Vector3(0.0, 1.6, 0.0), 30, c2))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	rotation.y = sin(t * 0.4) * sway_amount
