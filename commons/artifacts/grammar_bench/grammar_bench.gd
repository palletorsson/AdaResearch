extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GrammarBench

## @identity
## lineage: formal-grammar bench — a grammar parsing a string into a parse tree
## essence: a bench that draws the derivation; nodes are spheres, productions are
##   edges, the same branching that a plant L-system traces.
## truth: grammar = parse tree = plant. A Chomsky grammar and a Lindenmayer system
##   are the same idea wearing different clothes — rewriting symbols into structure.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var angle_deg: float = 24.0
@export var node_color: Color = Color(0.55, 0.80, 1.0)
@export var leaf_color: Color = Color(0.55, 1.0, 0.65)
@export var edge_color: Color = Color(0.40, 0.45, 0.55)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
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
	# --- bench base ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.85)
	add_child(_box(Vector3(0, 0.42, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	var leg_mat := _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.45, 0.45]:
		for sz in [-0.27, 0.27]:
			add_child(_cylinder(Vector3(sx, 0.21, sz), 0.03, 0.42, leg_mat))

	# --- the input string being parsed ---
	add_child(_billboard_label("S -> A B   A -> a A | a   B -> b", Vector3(0, 0.62, 0.28), 16, Color(0.80, 0.86, 0.95)))

	# --- parse tree: built from a small bracketed L-system, rendered as nodes + edges ---
	# A compact derivation tree. Each branch a production, each node a symbol.
	var axiom := "X"
	var rules := {"X": "F[+FX][-FX]F", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, 3), {
		"angle_deg": angle_deg, "step_len": 0.09, "step_shrink": 0.74,
		"base_width": 0.012, "width_shrink": 0.7, "seed": 2,
	})
	var graph: Dictionary = LST.to_graph(walk)
	var positions: PackedVector3Array = graph["positions"]
	var edges: Array = graph["edges"]

	var tree := Node3D.new()
	tree.name = "ParseTree"
	tree.position = Vector3(0, 0.85, 0.0)
	tree.scale = Vector3.ONE * 0.7
	add_child(tree)

	# edges as thin cylinders
	var emat := _matte_mat(edge_color, 0.6, 0.2)
	for e in edges:
		var a: Vector3 = positions[int(e[0])]
		var b: Vector3 = positions[int(e[1])]
		tree.add_child(_cylinder_between(a, b, 0.008, emat))

	# nodes as spheres — colour by height (root trunk -> leaf tips)
	var max_y := 0.001
	for p in positions:
		max_y = maxf(max_y, p.y)
	var nmat := _glow_mat(node_color, 0.8)
	var lmat := _glow_mat(leaf_color, 1.0)
	for p in positions:
		var ht := clampf(p.y / max_y, 0.0, 1.0)
		var is_leaf := ht > 0.66
		tree.add_child(_sphere(p, 0.022 if is_leaf else 0.03, lmat if is_leaf else nmat))

	# --- title ---
	add_child(_billboard_label("GRAMMAR = PARSE TREE = PLANT", Vector3(0, 1.6, 0.0), 26, Color(0.85, 0.92, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var tree := get_node_or_null("ParseTree")
	if tree:
		tree.rotation.y += delta * 0.25
