extends Node3D

## Context-Free Grammars — Parse Tree & Chomsky Hierarchy
## Visualizes grammar derivations as animated hierarchical parse trees.
## Shows attribute grammars with synthesized values, Chomsky hierarchy levels,
## and step-by-step leftmost derivation with proper tree layout.

@export var display_size: float = 0.8
@export var auto_play: bool = true
@export var speed: float = 2.0
@export var max_derivation_depth: int = 5

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

var _info_label: Label3D
var _grammar_label: Label3D
var _derivation_label: Label3D

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

	var parent_pos := _node_positions.get(node["id"], Vector3.ZERO)
	var pp := Vector3(parent_pos.x * scale, -parent_pos.y * scale * 1.2, 0.0)

	for child in children:
		var child_pos := _node_positions.get(child["id"], Vector3.ZERO)
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
	var pos := _node_positions.get(node["id"], Vector3.ZERO)
	var p := Vector3(pos.x * scale, -pos.y * scale * 1.2, 0.0)

	var is_nt := node["symbol"] in nonterminals
	var is_active := _pending_expansions.has(node["id"])
	var has_children := not node.get("children", []).is_empty()

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
		var s := sizes[i] * display_size
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

			var is_nt := ch in g["nonterminals"]
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
	if _info_label:
		var attr_text := ""
		if grammar_index == 2 and not _tree_root.is_empty():
			attr_text = "\nSynthesized value: %d" % _tree_root.get("attr", 0)
		_info_label.text = "Context-Free Grammars\n%s\nStep: %d  Nodes: %d%s" % [
			grammar_names[grammar_index],
			derivation_step,
			_next_node_id,
			attr_text,
		]

	if _grammar_label:
		_grammar_label.text = _grammar_rules_text()

	if _derivation_label:
		var display_str := current_string
		if display_str.length() > 40:
			display_str = display_str.substr(0, 37) + "..."
		_derivation_label.text = "Yield: %s\nLength: %d" % [display_str, current_string.length()]


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
	_tree_instance.position = Vector3(0, display_size * 0.3, 0)
	add_child(_tree_instance)

	# Grammar rules (upper left)
	_rules_mesh = ImmediateMesh.new()
	_rules_instance = MeshInstance3D.new()
	_rules_instance.name = "RulesDisplay"
	_rules_instance.mesh = _rules_mesh
	var rules_mat := mat.duplicate()
	_rules_instance.material_override = rules_mat
	_rules_instance.position = Vector3(-display_size * 0.55, display_size * 0.55, 0)
	add_child(_rules_instance)

	# Chomsky hierarchy (lower left)
	_hierarchy_mesh = ImmediateMesh.new()
	_hierarchy_instance = MeshInstance3D.new()
	_hierarchy_instance.name = "HierarchyDisplay"
	_hierarchy_instance.mesh = _hierarchy_mesh
	var hier_mat := mat.duplicate()
	_hierarchy_instance.material_override = hier_mat
	_hierarchy_instance.position = Vector3(-display_size * 0.55, -display_size * 0.25, 0)
	add_child(_hierarchy_instance)

	# Derivation history (right)
	_derivation_mesh = ImmediateMesh.new()
	_derivation_instance = MeshInstance3D.new()
	_derivation_instance.name = "DerivationDisplay"
	_derivation_instance.mesh = _derivation_mesh
	var deriv_mat := mat.duplicate()
	_derivation_instance.material_override = deriv_mat
	_derivation_instance.position = Vector3(display_size * 0.55, display_size * 0.3, 0)
	add_child(_derivation_instance)

	# Ground plate
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


func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 24
	_info_label.outline_size = 4
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	_info_label.position = Vector3(0, display_size * 0.7, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_info_label)

	_grammar_label = Label3D.new()
	_grammar_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_grammar_label.font_size = 18
	_grammar_label.outline_size = 3
	_grammar_label.modulate = Color(0.7, 0.85, 1.0)
	_grammar_label.position = Vector3(-display_size * 0.55, display_size * 0.7, 0)
	_grammar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_grammar_label)

	_derivation_label = Label3D.new()
	_derivation_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_derivation_label.font_size = 18
	_derivation_label.outline_size = 3
	_derivation_label.modulate = Color(1.0, 0.85, 0.4)
	_derivation_label.position = Vector3(display_size * 0.55, display_size * 0.7, 0)
	_derivation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_derivation_label)

	# Chomsky hierarchy level labels
	var level_names := ["Type 0: Unrestricted", "Type 1: Context-Sens.", "Type 2: Context-Free", "Type 3: Regular"]
	var sizes := [0.38, 0.30, 0.22, 0.14]
	for i in range(4):
		var lbl := Label3D.new()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 12
		lbl.outline_size = 2
		lbl.modulate = COL_HIERARCHY[i]
		lbl.modulate.a = 1.0
		lbl.text = level_names[i]
		lbl.position = Vector3(
			-display_size * 0.55 + sizes[i] * display_size - 0.02,
			-display_size * 0.25 + sizes[i] * display_size * 0.6 + 0.01,
			0.01
		)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(lbl)


func set_grammar(index: int) -> void:
	grammar_index = clampi(index, 0, grammars.size() - 1)
	reset_derivation()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
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
	reset_derivation()
