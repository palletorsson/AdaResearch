extends Node3D

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Context-Free Grammars — Parse Tree & Chomsky Hierarchy
## Visualizes grammar derivations as animated hierarchical parse trees.
## Shows attribute grammars with synthesized values, Chomsky hierarchy levels,
## and step-by-step leftmost derivation with proper tree layout.
##
## THE BODY (cabinet grammar, 2026-07-21): every live thing this artifact makes
## is drawn in the XY plane at z = 0 and read face-on — a parse tree hanging
## downward, a production-rule chart, a Chomsky nest, a derivation ticker. There
## is no field you look down at. So the dialect is VERTICAL and the body is a
## CHART CASE: a wide, SHALLOW wall-standing case, glazed lights over the
## reading fields, a routed legend niche under a transom in the left bay, a
## full-width service band below the sill carrying the STATE readout and the
## keypad wedge, and a sign cap over a full-width ember line. The interface is
## part of the body — nothing floats beside it.

@export var display_size: float = 0.8
@export var auto_play: bool = true
@export var speed: float = 2.0
@export var max_derivation_depth: int = 5

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## The whole case derives from HangarKit.finish_palette(), so one word re-skins
## every part instead of a dozen hand-typed colours.
@export var show_case: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "CG-10"
## Pedestal height. The case is authored around the artifact's own origin and
## reaches well below it, so the plinth hangs off the case BOTTOM; auto-grounding
## then lifts the whole assembly and the keypad lands in the VR reach band (G5).
@export var plinth_height: float = 0.72

# Chomsky hierarchy grammars (index = type level shown)
# 0: Regular (Type 3) — S → aS | b
# 1: Context-Free (Type 2) — S → (S)S | ε  (balanced parens)
# 2: Attribute CFG — E → E+T | T, T → T*F | F, F → (E) | n  (arithmetic)
# 3: Context-Sensitive hint — anbncn
var grammar_index: int = 2  # default to attribute grammar (arithmetic)

var grammars: Array[Dictionary] = []
var grammar_names: Array[String] = [
	"Type 3: Regular",
	"Type 2: Context-Free",
	"Type 2: Attribute Grammar",
	"Type 1: Context-Sensitive",
]

# Current state
var current_string: String = ""
var derivation_step: int = 0
var derivation_history: Array = []

# Parse tree structure
var _tree_root: Dictionary = {}  # {symbol, children, x, y, attr, id}
var _next_node_id: int = 0
var _node_positions: Dictionary = {}  # id -> Vector3

# Rendering
var _tree_mesh: ImmediateMesh
var _tree_instance: MeshInstance3D
var _rules_mesh: ImmediateMesh
var _rules_instance: MeshInstance3D
var _hierarchy_mesh: ImmediateMesh
var _hierarchy_instance: MeshInstance3D
var _derivation_mesh: ImmediateMesh
var _derivation_instance: MeshInstance3D

# Framed 2D-in-3D readout boards (R-027) — each rebuilt only when its text changes
var _info_board: Node3D
var _info_cache := ""
var _grammar_board: Node3D
var _grammar_cache := ""
var _derivation_board: Node3D
var _derivation_cache := ""

# The chart case (housing) and the control pad seated on its service band
var _case_root: Node3D
var _control_panel: Node3D
var _speed_slider: Node = null
var _metrics: Dictionary = {}

var _time: float = 0.0
var _step_timer: float = 0.0
var _pending_expansions: Array = []  # node IDs that can still be expanded

# Colors
const COL_NONTERMINAL := Color(0.3, 0.75, 1.0)
const COL_TERMINAL := Color(1.0, 0.82, 0.2)
const COL_EDGE := Color(0.5, 0.55, 0.65)
const COL_ACTIVE := Color(1.0, 0.35, 0.35)
const COL_ATTR := Color(0.55, 1.0, 0.55)
const COL_HIERARCHY := [
	Color(0.9, 0.3, 0.3, 0.25),   # Type 0 - unrestricted
	Color(0.9, 0.65, 0.2, 0.3),   # Type 1 - context-sensitive
	Color(0.3, 0.8, 0.4, 0.35),   # Type 2 - context-free
	Color(0.3, 0.6, 1.0, 0.4),    # Type 3 - regular
]


func _ready() -> void:
	_init_grammars()
	_create_displays()
	_create_labels()
	reset_derivation()
	_create_case()


func _process(delta: float) -> void:
	_time += delta

	if auto_play:
		_step_timer += delta
		var interval := 1.5 / maxf(speed, 0.1)
		if _step_timer >= interval:
			_step_timer = 0.0
			next_step()

	_draw_all()


func _init_grammars() -> void:
	# Type 3: Regular grammar  S -> aS | b
	grammars.append({
		"rules": {
			"S": [["a", "S"], ["b"]],
		},
		"start": "S",
		"terminals": ["a", "b"],
		"nonterminals": ["S"],
	})

	# Type 2: Context-Free  S -> (S)S | ε
	grammars.append({
		"rules": {
			"S": [["(", "S", ")", "S"], []],
		},
		"start": "S",
		"terminals": ["(", ")"],
		"nonterminals": ["S"],
	})

	# Type 2 Attribute Grammar: E -> E+T | T,  T -> T*F | F,  F -> (E) | n
	grammars.append({
		"rules": {
			"E": [["E", "+", "T"], ["T"]],
			"T": [["T", "*", "F"], ["F"]],
			"F": [["(", "E", ")"], ["n"]],
		},
		"start": "E",
		"terminals": ["+", "*", "(", ")", "n"],
		"nonterminals": ["E", "T", "F"],
	})

	# Type 1 hint: a^n b^n c^n (simplified — show the concept)
	grammars.append({
		"rules": {
			"S": [["a", "B", "C"], ["a", "S", "B", "C"]],
			"B": [["b"]],
			"C": [["c"]],
		},
		"start": "S",
		"terminals": ["a", "b", "c"],
		"nonterminals": ["S", "B", "C"],
	})


func reset_derivation() -> void:
	var g := grammars[grammar_index]
	_next_node_id = 0
	_tree_root = _make_node(g["start"])
	_pending_expansions = [_tree_root["id"]]
	derivation_step = 0
	current_string = g["start"]
	derivation_history = [current_string]
	_compute_tree_layout()
	_compute_attributes(_tree_root)


func next_step() -> void:
	if _pending_expansions.is_empty():
		# Restart after pause
		_step_timer = -1.0  # extra delay before restart
		reset_derivation()
		return

	var g := grammars[grammar_index]
	var node_id: int = _pending_expansions.pop_front()
	var node := _find_node(_tree_root, node_id)
	if node.is_empty():
		return

	var symbol: String = node["symbol"]
	if not symbol in g["rules"]:
		return

	var rules: Array = g["rules"][symbol]
	# Choose a rule — prefer non-recursive early, recursive later for variety
	var rule_idx: int
	if derivation_step < 2 and rules.size() > 1:
		# Prefer longer (recursive) production early for interesting trees
		rule_idx = 0
	else:
		rule_idx = randi() % rules.size()

	var production: Array = rules[rule_idx]
	var children: Array = []

	for s in production:
		var child := _make_node(s)
		children.append(child)
		if s in g["nonterminals"]:
			_pending_expansions.append(child["id"])

	node["children"] = children
	node["production_used"] = rule_idx

	derivation_step += 1

	# Rebuild current string from tree leaves
	current_string = _collect_leaves(_tree_root)
	derivation_history.append(current_string)

	# Limit depth
	if derivation_step >= max_derivation_depth:
		# Terminate all remaining nonterminals
		_terminate_all()

	_compute_tree_layout()
	_compute_attributes(_tree_root)


func _terminate_all() -> void:
	var g := grammars[grammar_index]
	while not _pending_expansions.is_empty():
		var nid: int = _pending_expansions.pop_front()
		var node := _find_node(_tree_root, nid)
		if node.is_empty():
			continue
		var symbol: String = node["symbol"]
		if not symbol in g["rules"]:
			continue
		var rules: Array = g["rules"][symbol]
		# Pick shortest (most terminal) production
		var best_idx := 0
		var best_len := 999
		for i in range(rules.size()):
			if rules[i].size() < best_len:
				best_len = rules[i].size()
				best_idx = i
		var production: Array = rules[best_idx]
		var children: Array = []
		for s in production:
			var child := _make_node(s)
			children.append(child)
			if s in g["nonterminals"]:
				_pending_expansions.append(child["id"])
		node["children"] = children

	current_string = _collect_leaves(_tree_root)
	derivation_history.append(current_string)


func _make_node(symbol: String) -> Dictionary:
	var node := {
		"symbol": symbol,
		"children": [],
		"id": _next_node_id,
		"x": 0.0,
		"y": 0.0,
		"attr": 0,  # synthesized attribute
		"production_used": -1,
	}
	_next_node_id += 1
	return node


func _find_node(root: Dictionary, target_id: int) -> Dictionary:
	if root.get("id", -1) == target_id:
		return root
	for child in root.get("children", []):
		var found := _find_node(child, target_id)
		if not found.is_empty():
			return found
	return {}


func _collect_leaves(node: Dictionary) -> String:
	var children: Array = node.get("children", [])
	if children.is_empty():
		return node["symbol"]
	var result := ""
	for child in children:
		result += _collect_leaves(child)
	return result


# --- Tree Layout (Reingold-Tilford simplified) ---

func _compute_tree_layout() -> void:
	_node_positions.clear()
	if _tree_root.is_empty():
		return
	# Assign y = depth, x = in-order position
	var counter := {"val": 0.0}
	_layout_inorder(_tree_root, 0, counter)

	# Center horizontally
	var min_x := INF
	var max_x := -INF
	for pos in _node_positions.values():
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
	var cx := (min_x + max_x) / 2.0
	for id in _node_positions:
		_node_positions[id].x -= cx


func _layout_inorder(node: Dictionary, depth: int, counter: Dictionary) -> void:
	var children: Array = node.get("children", [])

	if children.is_empty():
		node["x"] = counter["val"]
		node["y"] = float(depth)
		_node_positions[node["id"]] = Vector3(counter["val"], float(depth), 0.0)
		counter["val"] += 1.0
		return

	# Layout left children
	var half := children.size() / 2
	for i in range(half):
		_layout_inorder(children[i], depth + 1, counter)

	# Place this node
	node["x"] = counter["val"]
	node["y"] = float(depth)
	_node_positions[node["id"]] = Vector3(counter["val"], float(depth), 0.0)
	counter["val"] += 1.0

	# Layout right children
	for i in range(half, children.size()):
		_layout_inorder(children[i], depth + 1, counter)

	# Center parent over children
	var first_child_x: float = _node_positions[children[0]["id"]].x
	var last_child_x: float = _node_positions[children[-1]["id"]].x
	var parent_x := (first_child_x + last_child_x) / 2.0
	node["x"] = parent_x
	_node_positions[node["id"]].x = parent_x


# --- Attribute Grammar ---

func _compute_attributes(node: Dictionary) -> int:
	var children: Array = node.get("children", [])
	var g := grammars[grammar_index]

	if children.is_empty():
		# Terminal: attribute = 1 (leaf count) or special value
		if node["symbol"] == "n":
			node["attr"] = randi_range(1, 9)
		else:
			node["attr"] = 1
		return node["attr"]

	# Synthesized attribute: depends on grammar type
	match grammar_index:
		2:  # Arithmetic attribute grammar
			var symbol: String = node["symbol"]
			if symbol == "E" and children.size() == 3:
				# E -> E + T  →  attr = left.attr + right.attr
				var left := _compute_attributes(children[0])
				_compute_attributes(children[1])  # '+'
				var right := _compute_attributes(children[2])
				node["attr"] = left + right
			elif symbol == "T" and children.size() == 3:
				# T -> T * F  →  attr = left.attr * right.attr
				var left := _compute_attributes(children[0])
				_compute_attributes(children[1])  # '*'
				var right := _compute_attributes(children[2])
				node["attr"] = left * right
			elif symbol == "F" and children.size() == 3:
				# F -> (E)  →  attr = E.attr
				_compute_attributes(children[0])  # '('
				var inner := _compute_attributes(children[1])
				_compute_attributes(children[2])  # ')'
				node["attr"] = inner
			else:
				# Single child passthrough
				var val := 0
				for child in children:
					val = _compute_attributes(child)
				node["attr"] = val
		_:
			# Default: sum of children attributes (string length)
			var total := 0
			for child in children:
				total += _compute_attributes(child)
			node["attr"] = total

	return node["attr"]


# --- Drawing ---

func _draw_all() -> void:
	_draw_parse_tree()
	_draw_grammar_rules()
	_draw_chomsky_hierarchy()
	_draw_derivation_history()
	_update_labels()


func _draw_parse_tree() -> void:
	if not _tree_mesh:
		return
	_tree_mesh.clear_surfaces()

	if _node_positions.is_empty():
		return

	# Compute scale to fit display_size
	var max_extent := 1.0
	for pos in _node_positions.values():
		max_extent = maxf(max_extent, absf(pos.x))
		max_extent = maxf(max_extent, absf(pos.y))
	var scale := display_size * 0.35 / maxf(max_extent, 0.01)

	var g := grammars[grammar_index]
	var nonterminals: Array = g["nonterminals"]

	# Draw edges first
	_tree_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_tree_edges(_tree_root, scale, nonterminals)
	_tree_mesh.surface_end()

	# Draw nodes
	_tree_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_tree_nodes(_tree_root, scale, nonterminals)
	_tree_mesh.surface_end()


func _draw_tree_edges(node: Dictionary, scale: float, nonterminals: Array) -> void:
	var children: Array = node.get("children", [])
	if children.is_empty():
		return

	var parent_pos: Vector3 = _node_positions.get(node["id"], Vector3.ZERO)
	var pp := Vector3(parent_pos.x * scale, -parent_pos.y * scale * 1.2, 0.0)

	for child in children:
		var child_pos: Vector3 = _node_positions.get(child["id"], Vector3.ZERO)
		var cp := Vector3(child_pos.x * scale, -child_pos.y * scale * 1.2, 0.0)

		# Draw edge as thin quad
		var dir := (cp - pp).normalized()
		var perp := Vector3(-dir.y, dir.x, 0.0) * 0.004
		if perp.length_squared() < 0.0001:
			perp = Vector3(0.004, 0, 0)

		var is_active := _pending_expansions.has(child["id"])
		var col := COL_ACTIVE if is_active else COL_EDGE

		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(pp + perp)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(pp - perp)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(cp + perp)

		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(pp - perp)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(cp - perp)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(cp + perp)

		_draw_tree_edges(child, scale, nonterminals)


func _draw_tree_nodes(node: Dictionary, scale: float, nonterminals: Array) -> void:
	var pos: Vector3 = _node_positions.get(node["id"], Vector3.ZERO)
	var p := Vector3(pos.x * scale, -pos.y * scale * 1.2, 0.0)

	var is_nt: bool = node["symbol"] in nonterminals
	var is_active := _pending_expansions.has(node["id"])
	var has_children: bool = not node.get("children", []).is_empty()

	var col: Color
	if is_active:
		# Pulse active nodes
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		col = COL_ACTIVE.lerp(COL_NONTERMINAL, pulse)
	elif is_nt and has_children:
		col = COL_NONTERMINAL
	elif is_nt:
		col = COL_NONTERMINAL.darkened(0.3)
	else:
		col = COL_TERMINAL

	# Show attribute value as brightness for attribute grammar
	if grammar_index == 2 and node["attr"] > 0:
		var attr_blend := clampf(float(node["attr"]) / 20.0, 0.0, 0.5)
		col = col.lerp(COL_ATTR, attr_blend)

	if is_nt:
		# Circle approximation (octagon)
		_draw_circle(p, 0.022, col)
	else:
		# Square for terminals
		_draw_square(p, 0.018, col)

	# Recurse
	for child in node.get("children", []):
		_draw_tree_nodes(child, scale, nonterminals)


func _draw_circle(center: Vector3, radius: float, col: Color) -> void:
	var segments := 8
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var v0 := center + Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var v1 := center + Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(center)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(v0)
		_tree_mesh.surface_set_color(col)
		_tree_mesh.surface_add_vertex(v1)


func _draw_square(center: Vector3, half: float, col: Color) -> void:
	var tl := center + Vector3(-half, half, 0.0)
	var tr := center + Vector3(half, half, 0.0)
	var bl := center + Vector3(-half, -half, 0.0)
	var br := center + Vector3(half, -half, 0.0)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(tl)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(bl)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(tr)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(bl)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(br)
	_tree_mesh.surface_set_color(col)
	_tree_mesh.surface_add_vertex(tr)


func _draw_grammar_rules() -> void:
	if not _rules_mesh:
		return
	_rules_mesh.clear_surfaces()

	var g := grammars[grammar_index]
	var rules: Dictionary = g["rules"]

	_rules_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var y_offset := 0.0
	var spacing := 0.06
	var x_base := 0.0

	for nt in rules:
		var productions: Array = rules[nt]

		# Nonterminal circle
		_draw_rule_circle(Vector3(x_base, y_offset, 0.0), 0.015, COL_NONTERMINAL)

		# Arrow
		_draw_rule_arrow(
			Vector3(x_base + 0.025, y_offset, 0.0),
			Vector3(x_base + 0.055, y_offset, 0.0),
			COL_EDGE
		)

		var px := x_base + 0.07
		for pi in range(productions.size()):
			var prod: Array = productions[pi]
			if pi > 0:
				# Draw pipe separator
				_draw_rule_square(Vector3(px, y_offset, 0.0), 0.005, COL_EDGE)
				px += 0.02

			if prod.is_empty():
				# Epsilon
				_draw_rule_square(Vector3(px, y_offset, 0.0), 0.008, Color(0.6, 0.4, 0.8))
				px += 0.02
			else:
				for symbol in prod:
					var col := COL_NONTERMINAL if symbol in g["nonterminals"] else COL_TERMINAL
					if symbol in g["nonterminals"]:
						_draw_rule_circle(Vector3(px, y_offset, 0.0), 0.01, col)
					else:
						_draw_rule_square(Vector3(px, y_offset, 0.0), 0.008, col)
					px += 0.025

		y_offset -= spacing

	_rules_mesh.surface_end()


func _draw_rule_circle(center: Vector3, radius: float, col: Color) -> void:
	for i in range(6):
		var a0 := TAU * float(i) / 6.0
		var a1 := TAU * float(i + 1) / 6.0
		_rules_mesh.surface_set_color(col)
		_rules_mesh.surface_add_vertex(center)
		_rules_mesh.surface_set_color(col)
		_rules_mesh.surface_add_vertex(center + Vector3(cos(a0) * radius, sin(a0) * radius, 0.0))
		_rules_mesh.surface_set_color(col)
		_rules_mesh.surface_add_vertex(center + Vector3(cos(a1) * radius, sin(a1) * radius, 0.0))


func _draw_rule_square(center: Vector3, half: float, col: Color) -> void:
	var tl := center + Vector3(-half, half, 0.0)
	var tr := center + Vector3(half, half, 0.0)
	var bl := center + Vector3(-half, -half, 0.0)
	var br := center + Vector3(half, -half, 0.0)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(tl)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(bl)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(tr)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(bl)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(br)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(tr)


func _draw_rule_arrow(from: Vector3, to: Vector3, col: Color) -> void:
	var dir := (to - from).normalized()
	var perp := Vector3(-dir.y, dir.x, 0.0) * 0.003
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(from + perp)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(from - perp)
	_rules_mesh.surface_set_color(col)
	_rules_mesh.surface_add_vertex(to)


func _draw_chomsky_hierarchy() -> void:
	if not _hierarchy_mesh:
		return
	_hierarchy_mesh.clear_surfaces()

	_hierarchy_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Four nested rectangles representing Chomsky hierarchy
	var sizes := [0.38, 0.30, 0.22, 0.14]
	var labels_y := [0.0, 0.0, 0.0, 0.0]

	for i in range(4):
		var s: float = sizes[i] * display_size
		var col: Color = COL_HIERARCHY[i]

		# Highlight current grammar's level
		if i == _chomsky_level_for_grammar(grammar_index):
			col.a = minf(col.a + 0.2, 0.6)
			# Pulse
			col.a += 0.1 * sin(_time * 2.0)

		# Draw filled rectangle
		var y_center := 0.0
		var tl := Vector3(-s, y_center + s * 0.6, 0.0)
		var tr := Vector3(s, y_center + s * 0.6, 0.0)
		var bl := Vector3(-s, y_center - s * 0.6, 0.0)
		var br := Vector3(s, y_center - s * 0.6, 0.0)

		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(tl)
		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(bl)
		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(tr)

		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(bl)
		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(br)
		_hierarchy_mesh.surface_set_color(col)
		_hierarchy_mesh.surface_add_vertex(tr)

	_hierarchy_mesh.surface_end()


func _chomsky_level_for_grammar(idx: int) -> int:
	match idx:
		0: return 3  # Regular
		1: return 2  # CFG
		2: return 2  # Attribute CFG
		3: return 1  # Context-sensitive
	return 0


func _draw_derivation_history() -> void:
	if not _derivation_mesh:
		return
	_derivation_mesh.clear_surfaces()

	if derivation_history.is_empty():
		return

	var g := grammars[grammar_index]
	_derivation_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var visible_steps := mini(derivation_history.size(), 8)
	var start_idx := maxi(0, derivation_history.size() - visible_steps)

	for step_i in range(visible_steps):
		var step_str: String = derivation_history[start_idx + step_i]
		var y_pos := -float(step_i) * 0.045
		var str_len := mini(step_str.length(), 30)

		for ci in range(str_len):
			var ch := step_str[ci]
			var x_pos := float(ci) * 0.025 - float(str_len) * 0.0125
			var center := Vector3(x_pos, y_pos, 0.0)

			var is_nt: bool = ch in g["nonterminals"]
			var col := COL_NONTERMINAL if is_nt else COL_TERMINAL

			# Fade older steps
			var age_fade := 1.0 - float(visible_steps - 1 - step_i) * 0.1
			col = col.darkened(1.0 - age_fade)

			_draw_deriv_square(center, 0.008, col)

		if str_len < step_str.length():
			# Ellipsis dots
			for d in range(3):
				var ex := float(str_len + d) * 0.025 - float(str_len) * 0.0125
				_draw_deriv_square(Vector3(ex, y_pos, 0.0), 0.003, COL_EDGE)

	_derivation_mesh.surface_end()


func _draw_deriv_square(center: Vector3, half: float, col: Color) -> void:
	var tl := center + Vector3(-half, half, 0.0)
	var tr := center + Vector3(half, half, 0.0)
	var bl := center + Vector3(-half, -half, 0.0)
	var br := center + Vector3(half, -half, 0.0)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(tl)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(bl)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(tr)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(bl)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(br)
	_derivation_mesh.surface_set_color(col)
	_derivation_mesh.surface_add_vertex(tr)


func _update_labels() -> void:
	# Rebuild each board only when its string changes — never per frame (R-027).
	# The three boards are no longer a row of plates floating above the artifact:
	# STATE sits inset in the service band under the hero light, PRODUCTIONS on
	# the transom of the left bay above its own legend niche, YIELD inside the
	# right light under the ticker it summarises. The sign cap owns the title,
	# so the old "Context-Free Grammars" line is gone from the readout text.
	var m: Dictionary = _case_metrics()

	var info_lines: Array = [
		grammar_names[grammar_index],
		"STEP %d   NODES %d" % [derivation_step, _next_node_id],
	]
	if grammar_index == 2 and not _tree_root.is_empty():
		info_lines.append("VALUE %d" % int(_tree_root.get("attr", 0)))
	var info_text: String = _join_lines(info_lines)
	if info_text != _info_cache:
		_info_cache = info_text
		if is_instance_valid(_info_board):
			_info_board.queue_free()
		var state_pos: Vector3 = m["state_pos"]
		var state_size: Vector2 = m["state_size"]
		_info_board = _make_board("STATE", info_lines, state_size, state_pos)

	var grammar_text: String = _grammar_rules_text()
	if grammar_text != _grammar_cache:
		_grammar_cache = grammar_text
		if is_instance_valid(_grammar_board):
			_grammar_board.queue_free()
		var prod_lines: Array = []
		for row in grammar_text.split("\n"):
			prod_lines.append(String(row))
		var prod_pos: Vector3 = m["prod_pos"]
		var prod_size: Vector2 = m["prod_size"]
		_grammar_board = _make_board("PRODUCTIONS", prod_lines, prod_size, prod_pos)

	var display_str: String = current_string
	if display_str.length() > 40:
		display_str = display_str.substr(0, 37) + "..."
	var deriv_lines: Array = [display_str, "LEN %d" % current_string.length()]
	var deriv_text: String = _join_lines(deriv_lines)
	if deriv_text != _derivation_cache:
		_derivation_cache = deriv_text
		if is_instance_valid(_derivation_board):
			_derivation_board.queue_free()
		var yield_pos: Vector3 = m["yield_pos"]
		var yield_size: Vector2 = m["yield_size"]
		_derivation_board = _make_board("YIELD", deriv_lines, yield_size, yield_pos)


# Change-detection key for a board's lines (R-027) — one string compare per
# frame instead of rebuilding baked text every frame.
func _join_lines(lines: Array) -> String:
	var out: String = ""
	for l in lines:
		out += str(l) + "|"
	return out


func _grammar_rules_text() -> String:
	var g := grammars[grammar_index]
	var text := ""
	for nt in g["rules"]:
		var prods: Array = g["rules"][nt]
		var parts := []
		for prod in prods:
			if prod.is_empty():
				parts.append("ε")
			else:
				parts.append("".join(prod))
		text += "%s → %s\n" % [nt, " | ".join(parts)]
	return text.strip_edges()


# --- Display Setup ---

func _create_displays() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Parse tree (center)
	_tree_mesh = ImmediateMesh.new()
	_tree_instance = MeshInstance3D.new()
	_tree_instance.name = "ParseTreeDisplay"
	_tree_instance.mesh = _tree_mesh
	_tree_instance.material_override = mat
	add_child(_tree_instance)

	# Grammar rules (upper left)
	_rules_mesh = ImmediateMesh.new()
	_rules_instance = MeshInstance3D.new()
	_rules_instance.name = "RulesDisplay"
	_rules_instance.mesh = _rules_mesh
	var rules_mat := mat.duplicate()
	_rules_instance.material_override = rules_mat
	add_child(_rules_instance)

	# Chomsky hierarchy (lower left)
	_hierarchy_mesh = ImmediateMesh.new()
	_hierarchy_instance = MeshInstance3D.new()
	_hierarchy_instance.name = "HierarchyDisplay"
	_hierarchy_instance.mesh = _hierarchy_mesh
	var hier_mat := mat.duplicate()
	_hierarchy_instance.material_override = hier_mat
	add_child(_hierarchy_instance)

	# Derivation history (right)
	_derivation_mesh = ImmediateMesh.new()
	_derivation_instance = MeshInstance3D.new()
	_derivation_instance.name = "DerivationDisplay"
	_derivation_instance.mesh = _derivation_mesh
	var deriv_mat := mat.duplicate()
	_derivation_instance.material_override = deriv_mat
	add_child(_derivation_instance)

	_layout_displays()

	# Ground plate — only when the artifact runs WITHOUT its case. The case's
	# own dark light-backdrops and sill do this job, and this plate's
	# (0.08, 0.08, 0.12) is a near-miss grey that would read as a different
	# manufacturer next to the canon dark (G4).
	if not show_case:
		var ground := MeshInstance3D.new()
		ground.name = "Ground"
		var plane := PlaneMesh.new()
		plane.size = Vector2(display_size * 1.6, display_size * 1.2)
		ground.mesh = plane
		var ground_mat := StandardMaterial3D.new()
		ground_mat.albedo_color = Color(0.08, 0.08, 0.12)
		ground_mat.roughness = 0.95
		ground.material_override = ground_mat
		ground.position = Vector3(0, -display_size * 0.55, 0)
		add_child(ground)


## The four reading fields' anchors. Split out of _create_displays() so a late
## apply_grid_config() that changes display_size can re-seat them together with
## the case instead of leaving the body and the drawing at two different scales.
func _layout_displays() -> void:
	if is_instance_valid(_tree_instance):
		_tree_instance.position = Vector3(0, display_size * 0.3, 0)
	if is_instance_valid(_rules_instance):
		_rules_instance.position = Vector3(-display_size * 0.55, display_size * 0.55, 0)
	if is_instance_valid(_hierarchy_instance):
		_hierarchy_instance.position = Vector3(-display_size * 0.55, -display_size * 0.25, 0)
	if is_instance_valid(_derivation_instance):
		_derivation_instance.position = Vector3(display_size * 0.55, display_size * 0.3, 0)


func _create_labels() -> void:
	# The STATE / PRODUCTIONS / YIELD readouts are framed boards built lazily by
	# _update_labels() (R-027) — nothing to pre-create here.

	# Chomsky hierarchy level tags. They keep their level colours: those are the
	# artifact's own phenomenon KEY, which the palette rule exempts. What changes
	# is where and how they sit — baked FLAT (billboard off, so they cannot swing
	# out of the case) and clamped inside the legend niche in the case's left bay
	# instead of hanging off the corners of the nest and reaching into the hero
	# light. Read down the niche, they are a legend: four levels, four rows.
	var m: Dictionary = _case_metrics()
	var lo: float = float(m["legend_x0"]) + 0.03
	var hi: float = float(m["legend_x1"]) - 0.03
	var tag_h: float = 0.022
	var level_names := ["Type 0: Unrestricted", "Type 1: Context-Sens.", "Type 2: Context-Free", "Type 3: Regular"]
	var sizes := [0.38, 0.30, 0.22, 0.14]
	for i in range(4):
		var col: Color = COL_HIERARCHY[i]
		col.a = 1.0
		var name_i: String = String(level_names[i])
		var lbl: Node3D = BakedText.make_tag(name_i, col, tag_h,
			Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
		if lbl:
			# make_tag auto-fits its plate width to the text; keep the whole
			# plate inside the niche so no tag crosses a mullion.
			var half_w: float = tag_h * (0.9 + 0.66 * float(name_i.length())) * 0.5
			var tx: float = -display_size * 0.55 + float(sizes[i]) * display_size - 0.02
			var tx_min: float = lo + half_w
			var tx_max: float = maxf(hi - half_w, tx_min)
			lbl.position = Vector3(
				clampf(tx, tx_min, tx_max),
				-display_size * 0.25 + float(sizes[i]) * display_size * 0.6 + 0.02,
				0.012
			)
			add_child(lbl)


## One seated instrument readout: a dark POCKET, the kit's framed screen inset
## in it, and an ember lip along the pocket's top edge. Replaces the old
## hand-rolled _plate(), whose (0.62,0.60,0.56) frame and (0.10,0.11,0.14) face
## were near-miss greys — the drift that quietly breaks a family (G4).
func _make_board(header: String, lines: Array, size: Vector2, pos: Vector3) -> Node3D:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var screen_c: Color = pal["screen"]
	var text_c: Color = pal["text"]
	var head_c: Color = pal["header"]
	var accent_c: Color = pal["accent"]

	var root := Node3D.new()
	root.name = "Board"
	root.position = pos
	root.add_child(HangarKit.box(Vector3(0, 0, -0.022),
		Vector3(size.x + 0.075, size.y + 0.075, 0.03), dark))
	var screen: Node3D = HangarKit.readout(header, lines, size,
		screen_c, text_c, head_c)
	if screen:
		screen.position = Vector3(0, 0, 0.008)
		root.add_child(screen)
	root.add_child(HangarKit.box(Vector3(0, size.y * 0.5 + 0.045, 0.0),
		Vector3(size.x + 0.035, 0.006, 0.006), HangarKit.emissive(accent_c, 2.0)))

	var host: Node = _case_root if is_instance_valid(_case_root) else self
	host.add_child(root)
	return root


# ═════════════════════════════════════════════════════════════════════════════
# THE CHART CASE  (cabinet grammar · vertical dialect · body: "chart case")
#
# Nothing below changes what this artifact computes or draws. It gives the four
# reading fields a body to live in, and pulls the readouts, the title and the
# keypad onto that body — an artifact's interface is part of the artifact.
#
# Why a new body rather than one of the canon eight: the phenomenon here is a
# DIAGRAM, not an object. Zero depth, four unequal reading fields, and a legend
# the other bodies have no use for. So: a wide, SHALLOW wall-standing glass case
# — jambs, sill, head rail, sign cap — with a routed LEGEND NICHE under a shelf
# in the left bay, and the service band below the sill carrying the STATE
# readout and the keypad wedge.
# ═════════════════════════════════════════════════════════════════════════════

## Every derived dimension of the case, read off the artifact's OWN numbers: the
## four display anchors from _layout_displays(), and the field extents from the
## draw code. Two of the four fields draw at ABSOLUTE metres and ignore
## display_size — _draw_grammar_rules steps 0.06 per row and 0.025 per symbol,
## _draw_derivation_history steps 0.025 per cell capped at 30 chars plus three
## ellipsis dots — so each light takes maxf(ds-derived, absolute). Without that,
## a map setting display_size: 2.0 would put two fields back outside the body.
func _case_metrics() -> Dictionary:
	var ds: float = display_size
	# _update_labels() asks for these every frame — memoise on display_size.
	if not _metrics.is_empty() and is_equal_approx(float(_metrics["ds"]), ds):
		return _metrics

	# field anchors — must match _layout_displays()
	var tree_y: float = ds * 0.30
	var side_x: float = ds * 0.55
	var rules_y: float = ds * 0.55
	var hier_y: float = -ds * 0.25
	var band_y: float = ds * 0.70

	# field half-extents
	var tree_hw: float = ds * 0.35
	var tree_drop: float = ds * 0.50
	var hier_hw: float = ds * 0.38
	var hier_hh: float = ds * 0.228
	var rules_drop: float = maxf(ds * 0.22, 0.18)
	var tick_r: float = maxf(ds * 0.55, 0.44)
	var tick_drop: float = maxf(ds * 0.45, 0.36)

	# The sill: the artifact's own ground-plate line, unless the ticker's
	# ABSOLUTE drop hangs below it (small display_size) — then the sill drops to
	# stay under the deepest field. The sill is the case's line, not the
	# drawing's, so moving it moves no ink.
	var sill_y: float = minf(-ds * 0.55, tree_y - tick_drop - 0.055)

	# glazing — three lights of unequal width, divided by seam battens on the
	# backboard rather than by full mullion bars. Measured reason: the rule
	# chart draws rightward from its anchor and the ticker draws symmetrically
	# about its own, so both routinely cross the light boundaries. A bar there
	# would slice the artifact's own diagram; a batten lets the ink pass over it.
	var seam_w: float = 0.030
	var mull_a: float = -(tree_hw + 0.06)
	var mull_b: float = tree_hw + 0.06
	var l_left: float = minf(-side_x - hier_hw - 0.045, mull_a - 0.24)
	var r_right: float = maxf(side_x + tick_r + 0.045, mull_b + 0.24)
	var light_top: float = maxf(rules_y + 0.05, tree_y + 0.06)
	var light_bot: float = sill_y + 0.025
	var shelf_y: float = hier_y + hier_hh + 0.035

	# envelope
	var left_edge: float = l_left - 0.12
	var right_edge: float = r_right + 0.12
	var body_top: float = band_y + 0.10
	var band_bottom: float = sill_y - maxf(ds * 0.50, 0.40)
	var band_top: float = sill_y - 0.025
	var band_face_bot: float = band_bottom + 0.10          # above the base rail
	var band_mid: float = (band_top + band_face_bot) * 0.5

	# the left bay's routed legend niche
	var legend_x0: float = l_left + 0.02
	var legend_x1: float = (mull_a - seam_w * 0.5) - 0.02
	var legend_y0: float = light_bot + 0.02
	var legend_y1: float = shelf_y + 0.008

	# Board slots. HangarKit.readout adds a bezel of max(w,h)*0.06 on every side,
	# so a slot's usable width is ~0.86 of it — sizing to (slot - a constant)
	# overflows once the slot scales.
	var prod_gap0: float = hier_y + hier_hh                # top of the nest
	var prod_gap1: float = rules_y - rules_drop            # bottom of the chart
	var prod_h: float = clampf((prod_gap1 - prod_gap0) * 0.55, 0.05, 0.15)
	var prod_w: float = maxf((legend_x1 - legend_x0) * 0.86, 0.16)

	# YIELD sits in the right light, in the gap between the ticker's lowest row
	# and the sill — so its height follows that gap, not a fixed number.
	var tick_bot: float = tree_y - tick_drop
	var yield_left: float = mull_b + seam_w * 0.5
	var yield_w: float = maxf((r_right - yield_left) * 0.86, 0.20)
	var yield_h: float = clampf((tick_bot - light_bot) * 0.50, 0.05, 0.115)
	var yield_half: float = yield_h * 0.5 + maxf(yield_w, yield_h) * 0.06 + 0.018
	var yield_y: float = clampf(tick_bot - yield_half, light_bot + yield_half, tick_bot)

	# STATE sits in the service band, in the clear run between the keypad wedge
	# and the vent block — centred on that run, never overlapping either.
	var pad_x: float = left_edge + 0.26
	var vent_x: float = side_x + 0.28
	var state_lo: float = pad_x + 0.14
	var state_hi: float = vent_x - 0.17
	var state_avail: float = maxf(state_hi - state_lo, 0.30)
	var state_w: float = clampf(ds * 0.62, 0.30, minf(1.10, state_avail * 0.84))
	var state_h: float = 0.20

	_metrics = {
		"ds": ds,
		"tree_y": tree_y, "side_x": side_x, "rules_y": rules_y, "hier_y": hier_y,
		"band_y": band_y, "sill_y": sill_y,
		"tree_hw": tree_hw, "tree_drop": tree_drop,
		"hier_hw": hier_hw, "hier_hh": hier_hh, "rules_drop": rules_drop,
		"tick_r": tick_r, "tick_drop": tick_drop,
		"seam_w": seam_w, "mull_a": mull_a, "mull_b": mull_b,
		"l_left": l_left, "r_right": r_right,
		"light_top": light_top, "light_bot": light_bot, "shelf_y": shelf_y,
		"left_edge": left_edge, "right_edge": right_edge,
		"total_w": right_edge - left_edge, "cx": (left_edge + right_edge) * 0.5,
		"body_top": body_top, "band_bottom": band_bottom, "band_top": band_top,
		"band_mid": band_mid,
		"back_z": -0.11, "board_z": -0.072, "seam_z": -0.060, "niche_z": -0.050,
		"face_z": 0.05, "depth": 0.22,
		"legend_x0": legend_x0, "legend_x1": legend_x1,
		"legend_y0": legend_y0, "legend_y1": legend_y1,
		"state_size": Vector2(state_w, state_h),
		"prod_size": Vector2(prod_w, prod_h),
		"yield_size": Vector2(yield_w, yield_h),
		"state_pos": Vector3((state_lo + state_hi) * 0.5, band_mid, 0.075),
		"prod_pos": Vector3((legend_x0 + legend_x1) * 0.5,
			(prod_gap0 + prod_gap1) * 0.5, -0.010),
		"yield_pos": Vector3((yield_left + r_right) * 0.5, yield_y, -0.010),
		"pad_pos": Vector3(pad_x, sill_y - 0.17, 0.05),
		"vent_x": vent_x,
	}
	return _metrics


func _create_case() -> void:
	if show_case:
		_build_case_body()
	_mount_controls()


## Rebuild after a late apply_grid_config() changed display_size — the body must
## track the drawing, or the case fits an artifact that is no longer there.
func _rebuild_case() -> void:
	# remove_child BEFORE queue_free: the old node lives until the end of the
	# frame, and a second child named "Cabinet" would be auto-renamed.
	if is_instance_valid(_case_root):
		remove_child(_case_root)
		_case_root.queue_free()
	_case_root = null
	if is_instance_valid(_control_panel):
		remove_child(_control_panel)
		_control_panel.queue_free()
	_control_panel = null
	_speed_slider = null
	# the boards live on the case; drop them with it and let R-027 re-make them
	for b in [_info_board, _grammar_board, _derivation_board]:
		if is_instance_valid(b):
			(b as Node).queue_free()
	_info_board = null
	_grammar_board = null
	_derivation_board = null
	_info_cache = ""
	_grammar_cache = ""
	_derivation_cache = ""
	_create_case()


func _build_case_body() -> void:
	var m: Dictionary = _case_metrics()
	var cx: float = m["cx"]
	var total_w: float = m["total_w"]
	var left_edge: float = m["left_edge"]
	var right_edge: float = m["right_edge"]
	var body_top: float = m["body_top"]
	var band_bottom: float = m["band_bottom"]
	var sill_y: float = m["sill_y"]
	var light_top: float = m["light_top"]
	var light_bot: float = m["light_bot"]
	var l_left: float = m["l_left"]
	var r_right: float = m["r_right"]
	var mull_a: float = m["mull_a"]
	var mull_b: float = m["mull_b"]
	var seam_w: float = m["seam_w"]
	var shelf_y: float = m["shelf_y"]
	var back_z: float = m["back_z"]
	var board_z: float = m["board_z"]
	var seam_z: float = m["seam_z"]
	var niche_z: float = m["niche_z"]
	var face_z: float = m["face_z"]
	var depth: float = m["depth"]
	var body_h: float = body_top - band_bottom

	var case_root := Node3D.new()
	case_root.name = "Cabinet"
	case_root.set_meta("housing", true)     # scopes the grammar probe's rules
	add_child(case_root)
	_case_root = case_root

	# ── one palette word drives every part (the kit's finish system) ──────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)
	# the PALE window glass, not the anthracite screen glass: the parse tree has
	# to read THROUGH this, and a milky pane hides the phenomenon.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.62, 0.72, 0.85, 0.055)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.10

	# ── back slab: one continuous plate behind everything ────────────────
	case_root.add_child(HangarKit.box(
		Vector3(cx, (body_top + band_bottom) * 0.5, back_z),
		Vector3(total_w, body_h, 0.05), shell))

	# ── three lights: dark backdrop + pale glass, unequal widths ─────────
	var light_h: float = light_top - light_bot
	var light_cy: float = (light_top + light_bot) * 0.5
	var lights: Array = [
		Vector2(l_left, mull_a - seam_w * 0.5),
		Vector2(mull_a + seam_w * 0.5, mull_b - seam_w * 0.5),
		Vector2(mull_b + seam_w * 0.5, r_right),
	]
	for span in lights:
		var s: Vector2 = span
		var w: float = s.y - s.x
		var mid: float = (s.x + s.y) * 0.5
		case_root.add_child(HangarKit.box(Vector3(mid, light_cy, board_z),
			Vector3(w, light_h, 0.014), dark))
		case_root.add_child(HangarKit.box(Vector3(mid, light_cy, face_z),
			Vector3(w, light_h, 0.004), glass))

	# ── seam battens + the left bay's shelf, all BEHIND the drawing plane ─
	for mx in [mull_a, mull_b]:
		var x: float = mx
		case_root.add_child(HangarKit.box(Vector3(x, light_cy, seam_z),
			Vector3(seam_w, light_h, 0.012), shell))
		case_root.add_child(HangarKit.bolts(
			Vector3(x, light_bot + 0.06, seam_z + 0.010),
			Vector3(x, light_top - 0.06, seam_z + 0.010),
			7, 0.007, steel))
	var bay_w: float = (mull_a - seam_w * 0.5) - l_left
	case_root.add_child(HangarKit.box(
		Vector3(l_left + bay_w * 0.5, shelf_y, seam_z),
		Vector3(bay_w, 0.022, 0.012), shell))

	# ── legend niche: the routed pocket the Chomsky key is printed on ────
	var lx0: float = m["legend_x0"]
	var lx1: float = m["legend_x1"]
	var ly0: float = m["legend_y0"]
	var ly1: float = m["legend_y1"]
	case_root.add_child(HangarKit.box(
		Vector3((lx0 + lx1) * 0.5, (ly0 + ly1) * 0.5, niche_z),
		Vector3(lx1 - lx0, ly1 - ly0, 0.012), dark))
	case_root.add_child(HangarKit.box(
		Vector3((lx0 + lx1) * 0.5, ly1 + 0.006, niche_z + 0.008),
		Vector3((lx1 - lx0) - 0.03, 0.005, 0.005), accent))

	# ── jambs: maroon flank left, shell jamb right ───────────────────────
	case_root.add_child(HangarKit.box(
		Vector3(left_edge + 0.05, (body_top + band_bottom) * 0.5, -0.02),
		Vector3(0.10, body_h, depth), maroon))
	case_root.add_child(HangarKit.bolts(
		Vector3(left_edge + 0.05, band_bottom + 0.12, depth * 0.5 - 0.018),
		Vector3(left_edge + 0.05, body_top - 0.10, depth * 0.5 - 0.018),
		9, 0.009, steel))
	case_root.add_child(HangarKit.box(
		Vector3(right_edge - 0.06, (body_top + band_bottom) * 0.5, -0.02),
		Vector3(0.12, body_h, depth), shell))
	case_root.add_child(HangarKit.bolts(
		Vector3(right_edge - 0.06, band_bottom + 0.12, depth * 0.5 - 0.018),
		Vector3(right_edge - 0.06, body_top - 0.10, depth * 0.5 - 0.018),
		9, 0.009, steel))

	# ── head rail above the lights ───────────────────────────────────────
	case_root.add_child(HangarKit.box(
		Vector3(cx, (light_top + body_top) * 0.5, -0.02),
		Vector3(total_w, body_top - light_top, depth), shell))

	# ── sill + its ember inlay (the line the whole face stands on) ───────
	var sill_front: float = -0.02 + (depth + 0.04) * 0.5
	case_root.add_child(HangarKit.box(Vector3(cx, sill_y, -0.02),
		Vector3(total_w, 0.05, depth + 0.04), shell))
	case_root.add_child(HangarKit.box(Vector3(cx, sill_y + 0.020, sill_front - 0.003),
		Vector3(total_w - 0.06, 0.006, 0.006), accent))

	# ── service band: the solid face under the sill ──────────────────────
	var band_h: float = (sill_y - 0.025) - band_bottom
	case_root.add_child(HangarKit.box(
		Vector3(cx, (sill_y - 0.025 + band_bottom) * 0.5, -0.03),
		Vector3(total_w, band_h, 0.16), shell))

	# keypad shoulder: the pad meets the body instead of hanging in air
	var pad_pos: Vector3 = m["pad_pos"]
	var wedge: MeshInstance3D = HangarKit.wedge(0.26, 0.26, 0.100, 0.028, dark)
	if wedge:
		wedge.position = pad_pos
		case_root.add_child(wedge)

	# The plinth is the reach corrector (G5): capped so the pad lands inside the
	# 0.75–1.35 band even when a map scales the artifact up.
	var pad_lift: float = pad_pos.y - band_bottom
	var ped_h: float = clampf(plinth_height, 0.0, maxf(1.10 - pad_lift, 0.0))

	# vent slats, accent triad and the unit number — stacked on the band face to
	# the right of the STATE screen, all above the base rail so nothing is buried.
	var band_face_bot: float = band_bottom + 0.10
	var vent_x: float = m["vent_x"]
	for gi in range(6):
		case_root.add_child(HangarKit.box(
			Vector3(vent_x, band_face_bot + 0.055 + float(gi) * 0.024, 0.056),
			Vector3(0.34, 0.010, 0.012), dark))
	var bar: Node3D = HangarKit.three_color_bar(0.34, 0.018)
	if bar:
		bar.position = Vector3(vent_x, band_face_bot + 0.215, 0.056)
		case_root.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.13, 0.032),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(vent_x, band_face_bot + 0.255, 0.056)
		case_root.add_child(code)

	# ── age: an opaque dirt shadow at the BASE of a light, flat face ─────
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.055, 0.056, col_body)
	if gb:
		gb.position.x = cx
		gb.position.y = band_face_bot + 0.0275
		case_root.add_child(gb)

	# ── base rail (+ feet only when nothing else carries the body) ───────
	case_root.add_child(HangarKit.box(Vector3(cx, band_bottom + 0.05, -0.02),
		Vector3(total_w, 0.10, depth + 0.10), dark))
	if ped_h <= 0.05:
		for fx in [-total_w * 0.5 + 0.11, total_w * 0.5 - 0.11]:
			case_root.add_child(HangarKit.box(
				Vector3(cx + float(fx), band_bottom - 0.012, -0.02),
				Vector3(0.13, 0.024, depth + 0.06), dark))

	# ── sign cap over a full-width ember line: the sign owns the name ────
	var cap_y: float = body_top + 0.065
	var cap_front: float = -0.02 + (depth + 0.04) * 0.5
	case_root.add_child(HangarKit.box(Vector3(cx, cap_y, -0.02),
		Vector3(total_w + 0.06, 0.13, depth + 0.04), shell))
	case_root.add_child(HangarKit.box(Vector3(cx, body_top + 0.005, -0.02 + depth * 0.5 + 0.006),
		Vector3(total_w + 0.06, 0.007, 0.004), accent))
	case_root.add_child(HangarKit.box(Vector3(cx, cap_y, cap_front - 0.004),
		Vector3(total_w - 0.10, 0.082, 0.012), dark))
	var sign_title: Node3D = BakedText.make_tag(
		"CONTEXT-FREE GRAMMARS", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, cap_y + 0.015, cap_front + 0.004)
		case_root.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"RULES THAT MAKE STRUCTURE", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, cap_y - 0.022, cap_front + 0.004)
		case_root.add_child(sign_sub)

	# ── pedestal: the case is authored around the artifact origin and hangs
	#    well below it, so the plinth is seated on the case BOTTOM and the
	#    grid's base-to-floor grounding lifts the whole assembly (G5). Its
	#    height was capped above so the pad lands INSIDE the 0.75–1.35 reach
	#    band even when a map scales the artifact up. ────
	if ped_h > 0.05:
		var ped: Node3D = HangarKit.plinth(total_w, depth + 0.16, ped_h,
			finish, ew, col_accent, unit_code)
		if ped:
			ped.position = Vector3(cx, band_bottom, -0.02)
			case_root.add_child(ped)


## The controls are part of the body, not a pad floating in front of it: the
## rack panel is seated on the wedge shoulder at the left end of the service
## band. (This interface only ever existed in CFG_UI.gd, which no scene loads —
## the artifact has been shipping with no controls at all.)
func _mount_controls() -> void:
	var m: Dictionary = _case_metrics()
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_control_panel = RackTpl.create_panel("CFG GRAMMAR", [
		[
			{"type": "slider_h", "label": "SPEED", "default": 0.2},
		],
		[
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "STEP"},
		],
		[
			{"type": "button", "label": "GRAMMAR"},
			{"type": "button", "label": "RESET"},
		],
	])
	if _control_panel == null:
		return
	var pad_pos: Vector3 = m["pad_pos"]
	if show_case:
		_control_panel.position = pad_pos + Vector3(0, 0, 0.078)
		_control_panel.rotation_degrees = Vector3(-16, 0, 0)
		_control_panel.scale = Vector3(0.92, 0.92, 0.92)   # inside the wedge footprint
	else:
		_control_panel.position = Vector3(0, float(m["sill_y"]) - 0.12, 0.10)
		_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	_speed_slider = _control_panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		var err: int = _speed_slider.connect("slider_moved", Callable(self, "_on_speed_changed"))
		if err != OK:
			push_warning("context_free_grammars: speed slider not connected (%d)" % err)

	var auto_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if auto_btn:
		var a0: Node = auto_btn.get_node_or_null("InteractableAreaButton")
		if a0:
			a0.button_pressed.connect(func(_b): _on_auto_toggled())
	var step_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if step_btn:
		var a1: Node = step_btn.get_node_or_null("InteractableAreaButton")
		if a1:
			a1.button_pressed.connect(func(_b): next_step())
	var grammar_btn: Node = _control_panel.find_child("Btn_2", true, false)
	if grammar_btn:
		var a2: Node = grammar_btn.get_node_or_null("InteractableAreaButton")
		if a2:
			a2.button_pressed.connect(func(_b): _on_grammar_cycle())
	var reset_btn: Node = _control_panel.find_child("Btn_3", true, false)
	if reset_btn:
		var a3: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if a3:
			a3.button_pressed.connect(func(_b): reset_derivation())


func _on_auto_toggled() -> void:
	auto_play = not auto_play


func _on_speed_changed(_value: float) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		speed = clampf(float(_speed_slider.get_normalized_value()) * 10.0, 0.1, 10.0)


func _on_grammar_cycle() -> void:
	set_grammar((grammar_index + 1) % grammars.size())


func set_grammar(index: int) -> void:
	grammar_index = clampi(index, 0, grammars.size() - 1)
	reset_derivation()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	var old_size: float = display_size
	if config.has("grammar_index"):
		grammar_index = clampi(int(config["grammar_index"]), 0, 3)
	if config.has("display_size"):
		display_size = clampf(float(config["display_size"]), 0.3, 3.0)
	if config.has("speed"):
		speed = clampf(float(config["speed"]), 0.1, 10.0)
	if config.has("max_derivation_depth"):
		max_derivation_depth = clampi(int(config["max_derivation_depth"]), 2, 12)
	if config.has("auto_play"):
		auto_play = bool(config["auto_play"])
	if config.has("show_case"):
		show_case = bool(config["show_case"])
	if config.has("finish"):
		finish = str(config["finish"])
	if config.has("unit_code"):
		unit_code = str(config["unit_code"])
	if config.has("plinth_height"):
		plinth_height = clampf(float(config["plinth_height"]), 0.0, 1.4)
	# GridInteractablesComponent calls this DEFERRED, i.e. after _ready() has
	# already built displays and case at the old size. Re-seat both together so
	# the body never fits an artifact that is no longer there.
	if is_instance_valid(_case_root) or is_instance_valid(_control_panel):
		if not is_equal_approx(old_size, display_size):
			_layout_displays()
		_rebuild_case()
	if not grammars.is_empty():
		reset_derivation()
