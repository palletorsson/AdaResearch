extends RefCounted

class_name VectorInfoFrame

# Static helper that builds a museum-style info frame backdrop
# with title, formula, and description text.
# Usage: VectorInfoFrame.create(parent, "Title", "formula", "description", position)

const FRAME_COLOR := Color(0.3, 0.35, 0.4)
const BACKING_COLOR := Color(0.03, 0.04, 0.06, 0.92)
const TITLE_BG_COLOR := Color(0.06, 0.07, 0.1, 0.95)
const FORMULA_COLOR := Color(0.85, 0.95, 1.0)
const DESC_COLOR := Color(0.6, 0.65, 0.7)
const TITLE_COLOR := Color.WHITE

static func create(parent: Node3D, title: String, formula: String, description: String = "", pos: Vector3 = Vector3(0, 0.6, -0.3), frame_size: Vector2 = Vector2(1.0, 0.5)) -> Node3D:
	var root = Node3D.new()
	root.name = "InfoFrame"
	root.position = pos
	parent.add_child(root)

	var thickness = 0.004
	var depth = 0.006

	# === BACKING PANEL ===
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(frame_size.x, frame_size.y, 0.005)
	backing.mesh = box
	var back_mat = StandardMaterial3D.new()
	back_mat.albedo_color = BACKING_COLOR
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.metallic = 0.15
	back_mat.roughness = 0.85
	back_mat.render_priority = -10
	backing.material_override = back_mat
	root.add_child(backing)

	# === FRAME BORDER ===
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = FRAME_COLOR
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.4

	var half_w = frame_size.x / 2.0
	var half_h = frame_size.y / 2.0

	# Top and bottom edges
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(frame_size.x + thickness * 2, thickness, depth)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, 0)
		root.add_child(edge)

	# Left and right edges
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(thickness, frame_size.y, depth)
		edge.mesh = edge_box
		edge.material_override = frame_mat
		edge.position = Vector3(half_w * x_mult, 0, 0)
		root.add_child(edge)

	# === TITLE BAR ===
	var title_height = 0.06
	var title_bar = MeshInstance3D.new()
	var title_box = BoxMesh.new()
	title_box.size = Vector3(frame_size.x - thickness * 2, title_height, 0.006)
	title_bar.mesh = title_box
	var title_mat = StandardMaterial3D.new()
	title_mat.albedo_color = TITLE_BG_COLOR
	title_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	title_mat.render_priority = -9
	title_bar.material_override = title_mat
	title_bar.position = Vector3(0, half_h - title_height / 2.0 - thickness, 0.001)
	root.add_child(title_bar)

	# === TITLE TEXT ===
	var title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = title.to_upper()
	title_label.pixel_size = 0.001
	title_label.font_size = 32
	title_label.modulate = TITLE_COLOR
	title_label.no_depth_test = true
	title_label.render_priority = 100
	title_label.outline_size = 4
	title_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.position = Vector3(0, half_h - title_height / 2.0 - thickness, 0.005)
	root.add_child(title_label)

	# === FORMULA TEXT ===
	var formula_label = Label3D.new()
	formula_label.name = "FormulaLabel"
	formula_label.text = formula
	formula_label.pixel_size = 0.001
	formula_label.font_size = 28
	formula_label.modulate = FORMULA_COLOR
	formula_label.no_depth_test = true
	formula_label.render_priority = 100
	formula_label.outline_size = 3
	formula_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	formula_label.position = Vector3(0, 0.02, 0.005)
	root.add_child(formula_label)

	# === DESCRIPTION TEXT ===
	if description != "":
		var desc_label = Label3D.new()
		desc_label.name = "DescLabel"
		desc_label.text = description
		desc_label.pixel_size = 0.001
		desc_label.font_size = 20
		desc_label.modulate = DESC_COLOR
		desc_label.no_depth_test = true
		desc_label.render_priority = 100
		desc_label.outline_size = 2
		desc_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.6)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc_label.position = Vector3(0, -half_h + 0.06, 0.005)
		root.add_child(desc_label)

	# === ACCENT LINE ===
	# Thin colored line under the title bar
	var accent = MeshInstance3D.new()
	var accent_box = BoxMesh.new()
	accent_box.size = Vector3(frame_size.x * 0.6, 0.002, 0.007)
	accent.mesh = accent_box
	var accent_mat = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.4, 0.7, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.3, 0.5, 0.8)
	accent_mat.emission_energy_multiplier = 1.5
	accent.material_override = accent_mat
	accent.position = Vector3(0, half_h - title_height - thickness * 2, 0.003)
	root.add_child(accent)

	return root

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

