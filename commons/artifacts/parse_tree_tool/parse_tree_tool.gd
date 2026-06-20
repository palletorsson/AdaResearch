extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ParseTreeTool

## @identity
## lineage: parser tool — feeds an input string through a grammar, grows a live parse tree
## essence: an applied device with an input slot and a tree that re-derives on a timer,
##   cycling through a handful of input strings and showing each one's derivation.
## truth: grammar is generative; parsing is the same rewriting run in reverse — a string
##   in, a branching structure out. The parse tree and the plant share one engine.
##   Rebuild only on the timer, never per frame: the derivation is static between inputs.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var step_seconds: float = 2.0
@export var angle_deg: float = 26.0
@export var node_color: Color = Color(0.55, 0.80, 1.0)
@export var leaf_color: Color = Color(0.55, 1.0, 0.65)
@export var edge_color: Color = Color(0.40, 0.45, 0.55)

# Each input string maps to a derivation depth — longer input, deeper tree.
var _inputs: Array = [
	{"text": "a b", "iters": 1},
	{"text": "a a b", "iters": 2},
	{"text": "a a a b", "iters": 3},
	{"text": "a a a a b", "iters": 4},
]
var _idx: int = 0
var _timer: float = 0.0
var _slot_label: Label3D = null


func _ready() -> void:
	_rng.randomize()
	_idx = 0
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_idx = 0
	_timer = 0.0
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
	# --- ~1m device body ---
	var body_mat := _matte_mat(Color(0.14, 0.15, 0.19), 0.7, 0.1)
	add_child(_box(Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.5), body_mat))
	var plinth_mat := _steel_mat(Color(0.28, 0.29, 0.32))
	add_child(_box(Vector3(0, 0.04, 0), Vector3(0.8, 0.08, 0.6), plinth_mat))

	# --- input slot (where the string goes in) ---
	var slot_mat := _glow_mat(Color(0.10, 0.20, 0.30), 0.8)
	add_child(_box(Vector3(0, 0.30, 0.26), Vector3(0.46, 0.10, 0.02), slot_mat))
	_slot_label = _billboard_label("IN: %s" % String(_inputs[_idx]["text"]), Vector3(0, 0.30, 0.30), 20, Color(0.7, 0.95, 1.0))
	add_child(_slot_label)

	# --- readout panel above the slot ---
	var panel_mat := _glow_mat(Color(0.06, 0.10, 0.14), 0.8)
	add_child(_box(Vector3(0, 0.55, 0.26), Vector3(0.5, 0.20, 0.01), panel_mat))
	add_child(_billboard_label("S -> A b   A -> a A | a", Vector3(0, 0.55, 0.30), 14, Color(0.80, 0.86, 0.95)))
	# growth port (tree grows out the top)
	add_child(_cylinder(Vector3(0, 0.71, 0), 0.16, 0.04, _glow_mat(Color(0.15, 0.30, 0.40), 0.7)))

	# --- the live parse tree ---
	_grow_tree()

	# --- label ---
	add_child(_billboard_label("PARSER", Vector3(0, 1.3, 0), 26, Color(0.85, 0.92, 1.0)))


func _grow_tree() -> void:
	var old := get_node_or_null("ParseTree")
	if old:
		remove_child(old)
		old.queue_free()

	var iters := int(_inputs[_idx]["iters"])
	# A right-leaning derivation: A -> a A | a renders as a spine with branchings.
	var axiom := "X"
	var rules := {"X": "F[+F*]X", "F": "FF"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iters), {
		"angle_deg": angle_deg, "step_len": 0.085, "step_shrink": 0.82,
		"base_width": 0.012, "width_shrink": 0.78, "seed": 2,
	})
	var graph: Dictionary = LST.to_graph(walk)
	var positions: PackedVector3Array = graph["positions"]
	var edges: Array = graph["edges"]

	var tree := Node3D.new()
	tree.name = "ParseTree"
	tree.position = Vector3(0, 0.73, 0)
	tree.scale = Vector3.ONE * 0.8
	add_child(tree)

	var emat := _matte_mat(edge_color, 0.6, 0.2)
	for e in edges:
		var a: Vector3 = positions[int(e[0])]
		var b: Vector3 = positions[int(e[1])]
		tree.add_child(_cylinder_between(a, b, 0.007, emat))

	var max_y := 0.001
	for p in positions:
		max_y = maxf(max_y, p.y)
	var nmat := _glow_mat(node_color, 0.8)
	var lmat := _glow_mat(leaf_color, 1.0)
	for p in positions:
		var ht := clampf(p.y / max_y, 0.0, 1.0)
		var is_leaf := ht > 0.7
		tree.add_child(_sphere(p, 0.02 if is_leaf else 0.026, lmat if is_leaf else nmat))

	if _slot_label:
		_slot_label.text = "IN: %s" % String(_inputs[_idx]["text"])


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# re-parse the next input ONLY on the timer, not per frame
	_timer += delta
	if _timer >= step_seconds:
		_timer = 0.0
		_idx = (_idx + 1) % _inputs.size()
		_grow_tree()
	var tree := get_node_or_null("ParseTree")
	if tree:
		tree.rotation.y += delta * 0.3
