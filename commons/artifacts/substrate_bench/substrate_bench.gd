extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SubstrateBench

## SubstrateBench — Many substrates (the bridge), MEDIUM tier.
##
## The SAME L-system string rendered three ways side by side on a bench:
## lines (left), tubes (centre), node+edge graph (right). One genome,
## three materials — the turtle is the translation layer.
##
## @identity
##   truth: "the grammar is the DNA, the material is a choice"
##   truth: "one string, many materials — the bench is the bridge"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "FF-[-F+F+F]+[+F-F-F]"}
@export var iters: int = 3
@export var angle: float = 22.5
@export var c1: Color = Color(0.35, 0.22, 0.12)
@export var c2: Color = Color(0.55, 0.95, 0.55)
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


func _walk() -> Dictionary:
	return LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle, "step_len": 0.08, "step_shrink": 0.85,
		"base_width": 0.02, "width_shrink": 0.8, "seed": 1,
	})


func _build() -> void:
	# --- bench base -----------------------------------------------------------
	var top_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.7)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.06, 0.5), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_cylinder(Vector3(-0.45, 0.42, -0.18), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(0.45, 0.42, -0.18), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(-0.45, 0.42, 0.18), 0.03, 0.84, leg_mat))
	add_child(_cylinder(Vector3(0.45, 0.42, 0.18), 0.03, 0.84, leg_mat))

	var walk: Dictionary = _walk()

	# --- left: lines ----------------------------------------------------------
	var left_holder := Node3D.new()
	left_holder.position = Vector3(-0.38, 0.88, 0.0)
	add_child(left_holder)
	var lines: MeshInstance3D = LST.to_lines(walk, c1, c2)
	left_holder.add_child(lines)
	add_child(_billboard_label("LINES", Vector3(-0.38, 1.42, 0.0), 22, c2))

	# --- centre: tubes --------------------------------------------------------
	var mid_holder := Node3D.new()
	mid_holder.position = Vector3(0.0, 0.88, 0.0)
	add_child(mid_holder)
	var tubes: MultiMeshInstance3D = LST.to_tubes(walk, c1, c2, 6)
	mid_holder.add_child(tubes)
	add_child(_billboard_label("TUBES", Vector3(0.0, 1.42, 0.0), 22, c2))

	# --- right: graph ---------------------------------------------------------
	var right_holder := Node3D.new()
	right_holder.position = Vector3(0.38, 0.88, 0.0)
	add_child(right_holder)
	var g: Dictionary = LST.to_graph(walk)
	var node_mat := _glow_mat(c2, 1.0)
	var edge_mat := _matte_mat(c1)
	for p: Vector3 in g["positions"]:
		right_holder.add_child(_sphere(p, 0.02, node_mat))
	for e: Array in g["edges"]:
		right_holder.add_child(_cylinder_between(g["positions"][e[0]], g["positions"][e[1]], 0.006, edge_mat))
	add_child(_billboard_label("GRAPH", Vector3(0.38, 1.42, 0.0), 22, c2))

	# --- headline -------------------------------------------------------------
	add_child(_billboard_label("ONE STRING, MANY MATERIALS", Vector3(0.0, 1.6, 0.0), 30, c2))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	rotation.y = sin(t * 0.4) * sway_amount
