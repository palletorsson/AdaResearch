extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SubstrateRoom

## SubstrateRoom — Many substrates (the bridge), LARGE tier.
##
## A room where the same L-system string is a tube tree, a glowing graph,
## and a line skeleton — three pedestals you walk between. Same DNA,
## different substrate. The grammar is shared; the material is the choice.
##
## @identity
##   truth: "the grammar is the DNA, the material is a choice"
##   truth: "walk between the substrates — the string never changes"

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "FF-[-F+F+F]+[+F-F-F]"}
@export var iters: int = 4
@export var angle: float = 22.5
@export var c1: Color = Color(0.3, 0.2, 0.12)
@export var c2: Color = Color(0.45, 0.95, 0.7)
@export var sway_amount: float = 0.05


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


func _pedestal(center: Vector3) -> void:
	var mat := _matte_mat(Color(0.14, 0.15, 0.18), 0.7)
	add_child(_cylinder(center + Vector3(0.0, 0.4, 0.0), 0.45, 0.8, mat))
	add_child(_cylinder(center + Vector3(0.0, 0.81, 0.0), 0.5, 0.04, _steel_mat(Color(0.32, 0.34, 0.38))))


func _build() -> void:
	# --- room floor -----------------------------------------------------------
	var floor_mat := _matte_mat(Color(0.1, 0.11, 0.13), 0.9)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))

	var walk: Dictionary = _walk()

	# --- pedestal A: tube tree (left) ----------------------------------------
	var pa := Vector3(-2.2, 0.0, 0.0)
	_pedestal(pa)
	var tube_holder := Node3D.new()
	tube_holder.position = pa + Vector3(0.0, 0.85, 0.0)
	tube_holder.scale = Vector3.ONE * 2.2
	add_child(tube_holder)
	var tubes: MultiMeshInstance3D = LST.to_tubes(walk, c1, c2, 6)
	tube_holder.add_child(tubes)
	add_child(_billboard_label("TUBE TREE", pa + Vector3(0.0, 2.4, 0.0), 28, c2))

	# --- pedestal B: glowing graph (centre) ----------------------------------
	var pb := Vector3(0.0, 0.0, 0.0)
	_pedestal(pb)
	var graph_holder := Node3D.new()
	graph_holder.position = pb + Vector3(0.0, 0.85, 0.0)
	graph_holder.scale = Vector3.ONE * 2.2
	add_child(graph_holder)
	var g: Dictionary = LST.to_graph(walk)
	var node_mat := _glow_mat(c2, 1.6)
	var edge_mat := _glow_mat(c1, 0.6)
	for p: Vector3 in g["positions"]:
		graph_holder.add_child(_sphere(p, 0.02, node_mat))
	for e: Array in g["edges"]:
		graph_holder.add_child(_cylinder_between(g["positions"][e[0]], g["positions"][e[1]], 0.006, edge_mat))
	add_child(_billboard_label("GLOWING GRAPH", pb + Vector3(0.0, 2.4, 0.0), 28, c2))

	# --- pedestal C: line skeleton (right) -----------------------------------
	var pc := Vector3(2.2, 0.0, 0.0)
	_pedestal(pc)
	var line_holder := Node3D.new()
	line_holder.position = pc + Vector3(0.0, 0.85, 0.0)
	line_holder.scale = Vector3.ONE * 2.2
	add_child(line_holder)
	var lines: MeshInstance3D = LST.to_lines(walk, c1, c2)
	line_holder.add_child(lines)
	add_child(_billboard_label("LINE SKELETON", pc + Vector3(0.0, 2.4, 0.0), 28, c2))

	# --- overhead headline ----------------------------------------------------
	add_child(_billboard_label("THE GRAMMAR IS THE DNA, THE MATERIAL IS A CHOICE", Vector3(0.0, 3.6, 0.0), 40, c2))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	for child in get_children():
		if child is Node3D and (child as Node3D).scale.is_equal_approx(Vector3.ONE * 2.2):
			(child as Node3D).rotation.y = sin(t * 0.3) * sway_amount
