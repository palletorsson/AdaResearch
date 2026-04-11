# grammar_provenance.gd
# Side-by-side L-system trees from different cultural/historical sources.
# Same rendering engine, different axioms and rules. Labels explain provenance.
#
# @identity
# essence: Three L-system trees from three traditions — Lindenmayer 1968, Islamic geometric subdivision, Aboriginal kinship recursion — same engine, different grammars, different worlds
# desire: to make visible that every grammar encodes a worldview, and the question "whose grammar?" is always a political question
# critical_parameter: generation_depth — at depth 1 all three look alike; at depth 5 the cultural divergence becomes unmistakable
# triggers: increasing depth reveals that Lindenmayer's tree grows UP (botanical hierarchy), the Islamic pattern grows OUT (tiling symmetry), the kinship pattern grows AROUND (reciprocal branching)
# emerges: the viewer notices that "natural" branching is itself a cultural assumption — the L-system engine is neutral, but the axioms never are
# needs: [has] depth slider via ArtifactControls; [has] Label3D provenance annotations; [missing] no audio; no axiom editor
# relationships: placed in LSystems_Grammar_Lab alongside lsystem_editor and lsystem_tree; responds to the critical.md question "whose grammar?"
# truth: the grammar is never just math — it is always also a claim about what counts as growth

extends Node3D

class_name GrammarProvenance

## How many generations to expand each L-system
@export_range(1, 6) var generation_depth: int = 4:
	set(value):
		generation_depth = clampi(value, 1, 6)
		if is_inside_tree():
			_regenerate_all()

## Spacing between the three trees (meters)
@export var tree_spacing: float = 1.2

# ── Grammars ────────────────────────────────────────────────
# Each grammar: { axiom, rules, angle_deg, length, label, subtitle }
var _grammars: Array[Dictionary] = [
	{
		"axiom": "F",
		"rules": {"F": "F[+F]F[-F]F"},
		"angle_deg": 25.7,
		"length": 0.08,
		"label": "Lindenmayer (1968)",
		"subtitle": "Botanical hierarchy\nAxiom: F\nRule: F -> F[+F]F[-F]F\nGrows UP — trunk, branch, leaf",
		"color_base": Color(0.45, 0.28, 0.12),
		"color_tip": Color(0.2, 0.65, 0.15),
	},
	{
		"axiom": "F+F+F+F",
		"rules": {"F": "F+F-F-FF+F+F-F"},
		"angle_deg": 90.0,
		"length": 0.04,
		"label": "Islamic Geometric",
		"subtitle": "Recursive tiling subdivision\nAxiom: F+F+F+F\nRule: F -> F+F-F-FF+F+F-F\nGrows OUT — fourfold symmetry",
		"color_base": Color(0.15, 0.35, 0.55),
		"color_tip": Color(0.3, 0.7, 0.9),
	},
	{
		"axiom": "F",
		"rules": {"F": "F[-F[+F]]F[+F[-F]]"},
		"angle_deg": 35.0,
		"length": 0.07,
		"label": "Kinship Recursion",
		"subtitle": "Reciprocal branching structure\nAxiom: F\nRule: F -> F[-F[+F]]F[+F[-F]]\nGrows AROUND — every branch mirrors",
		"color_base": Color(0.55, 0.2, 0.15),
		"color_tip": Color(0.9, 0.6, 0.2),
	},
]

var _tree_meshes: Array[MeshInstance3D] = []
var _immediate_meshes: Array[ImmediateMesh] = []
var _labels: Array[Label3D] = []
var _title_labels: Array[Label3D] = []
var _controls: Node  # ArtifactControls


func _ready() -> void:
	_build_trees()
	_build_controls()
	_build_header()
	_regenerate_all()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


# ── Build ───────────────────────────────────────────────────

func _build_trees() -> void:
	for i in range(3):
		var im := ImmediateMesh.new()
		_immediate_meshes.append(im)

		var mi := MeshInstance3D.new()
		mi.name = "Tree_%d" % i
		mi.mesh = im
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mi.material_override = mat
		mi.position = Vector3((i - 1) * tree_spacing, 0, 0)
		add_child(mi)
		_tree_meshes.append(mi)

		# Base platform
		var base := MeshInstance3D.new()
		base.name = "Base_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.3
		cyl.bottom_radius = 0.35
		cyl.height = 0.02
		base.mesh = cyl
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.12, 0.1, 0.08)
		bmat.metallic = 0.3
		bmat.roughness = 0.7
		base.material_override = bmat
		base.position = Vector3(0, -0.01, 0)
		mi.add_child(base)

		# Title label (grammar name)
		var title := Label3D.new()
		title.name = "Title_%d" % i
		title.text = _grammars[i]["label"]
		title.font_size = 32
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.position = Vector3(0, -0.1, 0)
		title.modulate = Color(1, 1, 1, 0.9)
		mi.add_child(title)
		_title_labels.append(title)

		# Provenance label (below)
		var lbl := Label3D.new()
		lbl.name = "Provenance_%d" % i
		lbl.text = _grammars[i]["subtitle"]
		lbl.font_size = 18
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, -0.25, 0)
		lbl.modulate = Color(0.8, 0.8, 0.8, 0.7)
		mi.add_child(lbl)
		_labels.append(lbl)


func _build_controls() -> void:
	_controls = ArtifactControls.new()
	_controls.name = "Controls"
	_controls.position = Vector3(2.0, 1.2, 0.0)
	add_child(_controls)

	_controls.add_slider("DEPTH", float(generation_depth - 1) / 5.0, func(v: float):
		generation_depth = int(round(v * 5.0)) + 1
	)
	_controls.add_label("depth_display", "Depth: %d" % generation_depth)


func _build_header() -> void:
	var header := Label3D.new()
	header.name = "Header"
	header.text = "WHOSE GRAMMAR?"
	header.font_size = 48
	header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	header.position = Vector3(0, 1.8, 0)
	header.modulate = Color(1, 0.9, 0.7, 0.9)
	add_child(header)

	var sub := Label3D.new()
	sub.name = "SubHeader"
	sub.text = "Same engine. Different axioms. Different worlds."
	sub.font_size = 22
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub.position = Vector3(0, 1.6, 0)
	sub.modulate = Color(0.8, 0.8, 0.8, 0.7)
	add_child(sub)


# ── L-System Engine ─────────────────────────────────────────

func _expand(axiom: String, rules: Dictionary, depth: int) -> String:
	var current := axiom
	for _gen in range(depth):
		var next := ""
		for ch in current:
			if rules.has(ch):
				next += rules[ch]
			else:
				next += ch
		current = next
	return current


func _render_lsystem(im: ImmediateMesh, grammar: Dictionary, depth: int) -> void:
	im.clear_surfaces()

	var lstring := _expand(grammar["axiom"], grammar["rules"], depth)
	var angle_rad := deg_to_rad(grammar["angle_deg"])
	var seg_length: float = grammar["length"] * pow(0.7, depth - 1)
	var color_base: Color = grammar["color_base"]
	var color_tip: Color = grammar["color_tip"]

	# Turtle state
	var pos := Vector3.ZERO
	var direction := Vector3.UP
	var right := Vector3.RIGHT
	var stack: Array = []
	var max_depth_count := 0
	var current_depth := 0

	# First pass: count max bracket depth for color mapping
	for ch in lstring:
		if ch == "[":
			current_depth += 1
			max_depth_count = max(max_depth_count, current_depth)
		elif ch == "]":
			current_depth -= 1
	if max_depth_count == 0:
		max_depth_count = 1

	im.surface_begin(Mesh.PRIMITIVE_LINES)

	current_depth = 0
	for ch in lstring:
		match ch:
			"F":
				var t := float(current_depth) / float(max_depth_count)
				var col := color_base.lerp(color_tip, t)
				im.surface_set_color(col)
				im.surface_add_vertex(pos)
				var new_pos := pos + direction * seg_length
				im.surface_set_color(col)
				im.surface_add_vertex(new_pos)
				pos = new_pos
			"+":
				direction = direction.rotated(right.cross(direction).normalized(), angle_rad)
			"-":
				direction = direction.rotated(right.cross(direction).normalized(), -angle_rad)
			"[":
				stack.append({"pos": pos, "dir": direction, "right": right, "depth": current_depth})
				current_depth += 1
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					direction = state["dir"]
					right = state["right"]
					current_depth = state["depth"]

	im.surface_end()


func _regenerate_all() -> void:
	for i in range(3):
		if i < _immediate_meshes.size() and i < _grammars.size():
			_render_lsystem(_immediate_meshes[i], _grammars[i], generation_depth)

	# Update depth label
	if _controls and _controls.has_method("update_label"):
		_controls.update_label("depth_display", "Depth: %d" % generation_depth)
