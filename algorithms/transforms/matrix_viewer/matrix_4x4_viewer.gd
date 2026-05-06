# matrix_4x4_viewer.gd
# Matrix 4x4 Viewer — interactive transformation matrix with live 3D preview
# Shows a wireframe cube being transformed by sliders (translate, rotate, scale).
# The 4x4 matrix values update in real time as a grid of Label3D nodes.
#
# @identity
# essence: the matrix is the truth of the transform — numbers become geometry
# desire: slide translate/rotate/scale, watch the cube warp and the 16 numbers shift
# critical_parameter: rotation — the only transform that mixes matrix columns
# triggers: MOVE X/Y/Z sliders shift columns 3; ROTATE slider fills rotation submatrix; SCALE slider scales diagonal
# emerges: identity matrix = no change; rotation fills off-diagonal cells; translation only touches the last column
# needs: RackTemplates panel [has]; ImmediateMesh wireframe cube [has]; Label3D 4x4 grid [has]
# relationships: sibling to homogeneous_coordinates (theory); feeds into transform_composition (application)
# truth: Every spatial transformation hides inside 16 numbers — the matrix makes the invisible scaffolding visible.

extends Node3D

class_name Matrix4x4Viewer

# ── Layout ────────────────────────────────────────────────────────────
const CUBE_SIZE: float = 0.15
const EDGE_RADIUS: float = 0.002
const MATRIX_CELL_SPACING: float = 0.045
const MATRIX_ORIGIN := Vector3(-0.22, 0.48, 0)

# ── State ─────────────────────────────────────────────────────────────
var _translate := Vector3.ZERO
var _rotate_y: float = 0.0
var _scale_uniform: float = 1.0

var _cube_root: Node3D
var _edge_meshes: Array[MeshInstance3D] = []
var _matrix_labels: Array[Label3D] = []


func _ready() -> void:
	_build_wireframe_cube()
	_build_matrix_display()
	_build_panel()
	_update_transform()


# ═════════════════════════════════════════════════════════════════════
# WIREFRAME CUBE
# ═════════════════════════════════════════════════════════════════════

func _build_wireframe_cube() -> void:
	_cube_root = Node3D.new()
	_cube_root.name = "CubeRoot"
	_cube_root.position = Vector3(0.18, 0.48, -0.02)
	add_child(_cube_root)

	var half: float = CUBE_SIZE / 2.0
	# 8 corners of a unit cube
	var corners := [
		Vector3(-half, -half, -half), Vector3(half, -half, -half),
		Vector3(half, half, -half), Vector3(-half, half, -half),
		Vector3(-half, -half, half), Vector3(half, -half, half),
		Vector3(half, half, half), Vector3(-half, half, half),
	]
	# 12 edges as index pairs
	var edges := [
		[0,1],[1,2],[2,3],[3,0],  # back face
		[4,5],[5,6],[6,7],[7,4],  # front face
		[0,4],[1,5],[2,6],[3,7],  # connecting edges
	]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 0.95)
	mat.emission = Color(0.3, 0.85, 0.95)
	mat.emission_energy_multiplier = 0.6

	for edge in edges:
		var a: Vector3 = corners[edge[0]]
		var b: Vector3 = corners[edge[1]]
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = EDGE_RADIUS
		cyl.bottom_radius = EDGE_RADIUS
		cyl.height = a.distance_to(b)
		mi.mesh = cyl
		mi.material_override = mat

		# Position at midpoint, orient along the edge direction
		mi.position = (a + b) / 2.0
		var dir: Vector3 = (b - a).normalized()
		if dir.is_equal_approx(Vector3.UP):
			pass  # default cylinder orientation
		elif dir.is_equal_approx(Vector3.DOWN):
			mi.rotation.z = PI
		else:
			var axis: Vector3 = Vector3.UP.cross(dir).normalized()
			var angle: float = acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
			if axis.length() > 0.001:
				mi.transform.basis = Basis(axis, angle)
				mi.position = (a + b) / 2.0

		_cube_root.add_child(mi)
		_edge_meshes.append(mi)

	# Reference axes at cube center (small colored lines)
	_add_axis_indicator(_cube_root, Vector3.RIGHT * 0.08, Color(1, 0.3, 0.3))
	_add_axis_indicator(_cube_root, Vector3.UP * 0.08, Color(0.3, 1, 0.3))
	_add_axis_indicator(_cube_root, Vector3.BACK * 0.08, Color(0.3, 0.3, 1))


func _add_axis_indicator(parent: Node3D, direction: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.001
	cyl.bottom_radius = 0.003
	cyl.height = direction.length()
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat

	mi.position = direction / 2.0
	var dir: Vector3 = direction.normalized()
	if not dir.is_equal_approx(Vector3.UP) and not dir.is_equal_approx(Vector3.DOWN):
		var axis: Vector3 = Vector3.UP.cross(dir).normalized()
		var angle: float = acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
		if axis.length() > 0.001:
			mi.transform.basis = Basis(axis, angle)
			mi.position = direction / 2.0
	parent.add_child(mi)


# ═════════════════════════════════════════════════════════════════════
# MATRIX DISPLAY
# ═════════════════════════════════════════════════════════════════════

func _build_matrix_display() -> void:
	# Background plate for matrix
	var bg := MeshInstance3D.new()
	var bgbox := BoxMesh.new()
	bgbox.size = Vector3(MATRIX_CELL_SPACING * 4.0 + 0.02, MATRIX_CELL_SPACING * 4.0 + 0.02, 0.004)
	bg.mesh = bgbox
	var bgmat := StandardMaterial3D.new()
	bgmat.albedo_color = Color(0.06, 0.06, 0.08)
	bg.material_override = bgmat
	bg.position = MATRIX_ORIGIN + Vector3(MATRIX_CELL_SPACING * 1.5, -MATRIX_CELL_SPACING * 1.5, -0.002)
	add_child(bg)

	# Bracket labels
	var left_bracket := Label3D.new()
	left_bracket.text = "["
	left_bracket.font_size = 32
	left_bracket.pixel_size = 0.002
	left_bracket.modulate = Color(0.5, 0.5, 0.5)
	left_bracket.position = MATRIX_ORIGIN + Vector3(-0.03, -MATRIX_CELL_SPACING * 1.5, 0.001)
	add_child(left_bracket)

	var right_bracket := Label3D.new()
	right_bracket.text = "]"
	right_bracket.font_size = 32
	right_bracket.pixel_size = 0.002
	right_bracket.modulate = Color(0.5, 0.5, 0.5)
	right_bracket.position = MATRIX_ORIGIN + Vector3(MATRIX_CELL_SPACING * 3.0 + 0.03, -MATRIX_CELL_SPACING * 1.5, 0.001)
	add_child(right_bracket)

	# 4x4 grid of labels
	for row in 4:
		for col in 4:
			var lbl := Label3D.new()
			lbl.name = "M_%d_%d" % [row, col]
			lbl.text = "0.00"
			lbl.pixel_size = 0.0015
			lbl.font_size = 14
			lbl.modulate = Color(0.9, 0.85, 0.5)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.position = MATRIX_ORIGIN + Vector3(
				float(col) * MATRIX_CELL_SPACING,
				-float(row) * MATRIX_CELL_SPACING,
				0.001
			)
			add_child(lbl)
			_matrix_labels.append(lbl)

	# Title above matrix
	var title := Label3D.new()
	title.text = "TRANSFORM MATRIX"
	title.pixel_size = 0.002
	title.font_size = 14
	title.modulate = Color(0.9, 0.85, 0.5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = MATRIX_ORIGIN + Vector3(MATRIX_CELL_SPACING * 1.5, 0.04, 0)
	add_child(title)


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("MATRIX VIEWER", [
		[{"type": "slider_h", "label": "MOVE X", "default": 0.5}],
		[{"type": "slider_h", "label": "MOVE Y", "default": 0.5}],
		[{"type": "slider_h", "label": "MOVE Z", "default": 0.5}],
		[{"type": "slider_h", "label": "ROTATE", "default": 0.0}],
		[{"type": "slider_h", "label": "SCALE", "default": 0.33}],
	])
	panel.position = Vector3(0, 0.08, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(panel)

	# Connect all sliders
	for i in 5:
		var slider: Node = panel.find_child("Param_%d" % i, true, false)
		if slider and slider.has_signal("slider_moved"):
			slider.slider_moved.connect(_on_slider_changed)


func _on_slider_changed(_value: float) -> void:
	var panel_node: Node = get_node_or_null("MATRIX_VIEWER")
	if not panel_node:
		return

	# Read all 5 sliders
	for i in 5:
		var slider: Node = panel_node.find_child("Param_%d" % i, true, false)
		if slider and slider.has_method("get_normalized_value"):
			var norm: float = slider.get_normalized_value()
			match i:
				0: _translate.x = (norm - 0.5) * 0.4  # -0.2 to 0.2
				1: _translate.y = (norm - 0.5) * 0.4
				2: _translate.z = (norm - 0.5) * 0.4
				3: _rotate_y = norm * 360.0  # 0 to 360
				4: _scale_uniform = 0.5 + norm * 1.5  # 0.5 to 2.0

	_update_transform()


# ═════════════════════════════════════════════════════════════════════
# UPDATE
# ═════════════════════════════════════════════════════════════════════

func _update_transform() -> void:
	# Build Transform3D from slider values
	var xform := Transform3D.IDENTITY
	xform = xform.scaled(Vector3.ONE * _scale_uniform)
	xform = xform.rotated(Vector3.UP, deg_to_rad(_rotate_y))
	xform.origin = _translate

	# Apply to cube
	if _cube_root:
		var base_pos: Vector3 = Vector3(0.18, 0.48, -0.02)
		var local_xform := xform
		local_xform.origin += base_pos
		_cube_root.transform = local_xform

	# Update matrix labels
	var basis := xform.basis
	var origin := xform.origin
	# Godot uses column-major: basis[col][row]
	# Display as row-major 4x4 for standard math notation
	var values := [
		basis[0].x, basis[1].x, basis[2].x, origin.x,
		basis[0].y, basis[1].y, basis[2].y, origin.y,
		basis[0].z, basis[1].z, basis[2].z, origin.z,
		0.0, 0.0, 0.0, 1.0,
	]

	# Color coding: rotation/scale = cyan, translation = green, bottom row = gray
	var color_rotation := Color(0.3, 0.85, 0.95)
	var color_translation := Color(0.3, 0.95, 0.4)
	var color_bottom := Color(0.5, 0.5, 0.5)

	for i in 16:
		if i < _matrix_labels.size():
			_matrix_labels[i].text = "%6.2f" % values[i]
			var row: int = i / 4
			var col: int = i % 4
			if row == 3:
				_matrix_labels[i].modulate = color_bottom
			elif col == 3:
				_matrix_labels[i].modulate = color_translation
			else:
				_matrix_labels[i].modulate = color_rotation


func apply_grid_config(config: Dictionary) -> void:
	pass
