extends Node3D
class_name HomogeneousCoordinates

## Wall panel explaining homogeneous coordinates — why 4x4 matrices are used in 3D.
## Shows a color-coded 4x4 matrix with rotation (blue), translation (green),
## projection (red), and homogeneous row (gray). Demonstrates [x,y,z,1] → [x',y',z',1].

# --- Configuration ---

@export var color_panel: Color = Color(0.06, 0.06, 0.1)
@export var color_rotation: Color = Color(0.3, 0.5, 1.0)
@export var color_translation: Color = Color(0.3, 1.0, 0.5)
@export var color_projection: Color = Color(1.0, 0.35, 0.35)
@export var color_homogeneous: Color = Color(0.55, 0.55, 0.6)
@export var color_title: Color = Color(0.92, 0.92, 0.97)

# --- Internal ---

var _panel: MeshInstance3D


func _ready() -> void:
	_build_panel()
	_build_matrix_display()
	_build_point_transform()
	_build_coordinate_frame()
	_build_labels()


func _build_panel() -> void:
	_panel = MeshInstance3D.new()
	_panel.name = "BackPanel"
	var quad = QuadMesh.new()
	quad.size = Vector2(1.1, 0.85)
	_panel.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_panel
	mat.roughness = 0.9
	mat.metallic = 0.1
	_panel.material_override = mat

	add_child(_panel)


func _build_matrix_display() -> void:
	# 4x4 matrix with a sample rotation + translation
	# Color-coded by region:
	#   [R R R | T]   blue blue blue | green
	#   [R R R | T]   blue blue blue | green
	#   [R R R | T]   blue blue blue | green
	#   [P P P | H]   red  red  red  | gray

	var matrix_values = [
		["0.87", "-0.50", "0.00", "3.0"],
		["0.50", "0.87", "0.00", "1.5"],
		["0.00", "0.00", "1.00", "2.0"],
		["0", "0", "0", "1"],
	]

	var cell_colors = [
		[color_rotation, color_rotation, color_rotation, color_translation],
		[color_rotation, color_rotation, color_rotation, color_translation],
		[color_rotation, color_rotation, color_rotation, color_translation],
		[color_projection, color_projection, color_projection, color_homogeneous],
	]

	var cell_w = 0.1
	var cell_h = 0.055
	var origin_x = -0.32
	var origin_y = 0.1

	# Bracket lines using ImmediateMesh
	var bracket = MeshInstance3D.new()
	bracket.name = "MatrixBrackets"
	var bmesh = ImmediateMesh.new()
	bmesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var left_x = origin_x - cell_w * 0.7
	var right_x = origin_x + cell_w * 3.7
	var top_y = origin_y + cell_h * 1.8
	var bot_y = origin_y - cell_h * 2.2
	var bkt = 0.02
	var z = 0.003

	# Left bracket
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x + bkt, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x, bot_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x, bot_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(left_x + bkt, bot_y, z))

	# Right bracket
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x - bkt, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x, top_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x, bot_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x, bot_y, z))
	bmesh.surface_set_color(color_title)
	bmesh.surface_add_vertex(Vector3(right_x - bkt, bot_y, z))

	# Divider line: rotation vs translation column
	var div_x = origin_x + cell_w * 2.5
	bmesh.surface_set_color(Color(color_title, 0.2))
	bmesh.surface_add_vertex(Vector3(div_x, top_y - 0.01, z))
	bmesh.surface_set_color(Color(color_title, 0.2))
	bmesh.surface_add_vertex(Vector3(div_x, bot_y + 0.01, z))

	# Divider line: top 3 rows vs homogeneous row
	var div_y = origin_y - cell_h * 1.2
	bmesh.surface_set_color(Color(color_title, 0.2))
	bmesh.surface_add_vertex(Vector3(left_x + 0.01, div_y, z))
	bmesh.surface_set_color(Color(color_title, 0.2))
	bmesh.surface_add_vertex(Vector3(right_x - 0.01, div_y, z))

	bmesh.surface_end()
	bracket.mesh = bmesh

	var bmat = StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.vertex_color_use_as_albedo = true
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bracket.material_override = bmat
	add_child(bracket)

	# Matrix cell labels
	for row in range(4):
		for col in range(4):
			var lbl = Label3D.new()
			lbl.name = "Cell_%d_%d" % [row, col]
			lbl.text = matrix_values[row][col]
			lbl.font_size = 20
			lbl.pixel_size = 0.001
			lbl.position = Vector3(
				origin_x + col * cell_w,
				origin_y - row * cell_h,
				0.003
			)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.modulate = cell_colors[row][col]
			lbl.outline_size = 3
			lbl.outline_modulate = Color(0, 0, 0, 0.5)
			add_child(lbl)


func _build_point_transform() -> void:
	# Show [x, y, z, 1] → M → [x', y', z', 1] below the matrix
	var y_pos = -0.2

	var input_label = Label3D.new()
	input_label.name = "InputVector"
	input_label.text = "[x, y, z, 1]"
	input_label.font_size = 20
	input_label.pixel_size = 0.001
	input_label.position = Vector3(-0.35, y_pos, 0.002)
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_label.modulate = Color(0.9, 0.85, 0.7)
	input_label.outline_size = 3
	add_child(input_label)

	# Arrow
	var arrow = MeshInstance3D.new()
	arrow.name = "TransformArrow"
	var amesh = ImmediateMesh.new()
	amesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var ax_start = -0.17
	var ax_end = 0.02
	var head = 0.02
	var ac = Color(0.75, 0.75, 0.8)

	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_start, y_pos, 0.002))
	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_end, y_pos, 0.002))
	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_end, y_pos, 0.002))
	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_end - head, y_pos + head * 0.5, 0.002))
	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_end, y_pos, 0.002))
	amesh.surface_set_color(ac)
	amesh.surface_add_vertex(Vector3(ax_end - head, y_pos - head * 0.5, 0.002))

	amesh.surface_end()
	arrow.mesh = amesh

	var amat = StandardMaterial3D.new()
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amat.vertex_color_use_as_albedo = true
	arrow.material_override = amat
	add_child(arrow)

	# "M" label on arrow
	var m_label = Label3D.new()
	m_label.name = "MLabel"
	m_label.text = "M"
	m_label.font_size = 16
	m_label.pixel_size = 0.001
	m_label.position = Vector3((ax_start + ax_end) / 2.0, y_pos + 0.025, 0.002)
	m_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_label.modulate = Color(0.75, 0.75, 0.8)
	m_label.outline_size = 3
	add_child(m_label)

	var output_label = Label3D.new()
	output_label.name = "OutputVector"
	output_label.text = "[x', y', z', 1]"
	output_label.font_size = 20
	output_label.pixel_size = 0.001
	output_label.position = Vector3(0.2, y_pos, 0.002)
	output_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output_label.modulate = Color(0.9, 0.85, 0.7)
	output_label.outline_size = 3
	add_child(output_label)


func _build_coordinate_frame() -> void:
	# Small 3D coordinate frame on the right side showing XYZ axes
	var frame_root = Node3D.new()
	frame_root.name = "CoordinateFrame"
	frame_root.position = Vector3(0.38, 0.05, 0.02)
	add_child(frame_root)

	var axes = [
		{"dir": Vector3(0.12, 0, 0), "color": color_rotation, "label": "X"},
		{"dir": Vector3(0, 0.12, 0), "color": color_rotation, "label": "Y"},
		{"dir": Vector3(0, 0, 0.08), "color": color_rotation, "label": "Z"},
	]

	var frame_mesh = ImmediateMesh.new()
	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for axis in axes:
		var d: Vector3 = axis["dir"]
		var c: Color = axis["color"]

		# Axis line
		frame_mesh.surface_set_color(c)
		frame_mesh.surface_add_vertex(Vector3.ZERO)
		frame_mesh.surface_set_color(c)
		frame_mesh.surface_add_vertex(d)

	frame_mesh.surface_end()

	var frame_inst = MeshInstance3D.new()
	frame_inst.name = "FrameLines"
	frame_inst.mesh = frame_mesh

	var fmat = StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.vertex_color_use_as_albedo = true
	frame_inst.material_override = fmat
	frame_root.add_child(frame_inst)

	# Axis labels
	for axis in axes:
		var lbl = Label3D.new()
		lbl.name = "Axis_%s" % axis["label"]
		lbl.text = axis["label"]
		lbl.font_size = 16
		lbl.pixel_size = 0.001
		lbl.position = axis["dir"] * 1.2
		lbl.modulate = axis["color"]
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.outline_size = 4
		lbl.outline_modulate = Color(0, 0, 0, 0.6)
		frame_root.add_child(lbl)

	# Origin dot
	var origin_dot = MeshInstance3D.new()
	origin_dot.name = "OriginDot"
	var sphere = SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	origin_dot.mesh = sphere

	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.9, 0.9, 0.95)
	dmat.emission_enabled = true
	dmat.emission = Color(0.9, 0.9, 0.95)
	dmat.emission_energy_multiplier = 0.3
	origin_dot.material_override = dmat
	frame_root.add_child(origin_dot)

	# Translation vector from origin (green arrow showing tx, ty, tz)
	var t_end = Vector3(0.07, 0.04, 0.03)
	var tvec_mesh = ImmediateMesh.new()
	tvec_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	tvec_mesh.surface_set_color(color_translation)
	tvec_mesh.surface_add_vertex(Vector3.ZERO)
	tvec_mesh.surface_set_color(color_translation)
	tvec_mesh.surface_add_vertex(t_end)
	tvec_mesh.surface_end()

	var tvec_inst = MeshInstance3D.new()
	tvec_inst.name = "TranslationVector"
	tvec_inst.mesh = tvec_mesh
	tvec_inst.material_override = fmat
	frame_root.add_child(tvec_inst)

	var t_label = Label3D.new()
	t_label.name = "TranslationLabel"
	t_label.text = "T"
	t_label.font_size = 14
	t_label.pixel_size = 0.001
	t_label.position = t_end + Vector3(0.01, 0.01, 0)
	t_label.modulate = color_translation
	t_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	t_label.outline_size = 4
	t_label.outline_modulate = Color(0, 0, 0, 0.6)
	frame_root.add_child(t_label)


func _build_labels() -> void:
	# Title
	var title = Label3D.new()
	title.name = "TitleLabel"
	title.text = "HOMOGENEOUS COORDINATES"
	title.font_size = 28
	title.pixel_size = 0.001
	title.position = Vector3(0, 0.35, 0.002)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = color_title
	title.outline_size = 4
	add_child(title)

	# Subtitle
	var subtitle = Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Why 4x4 matrices for 3D transforms"
	subtitle.font_size = 16
	subtitle.pixel_size = 0.001
	subtitle.position = Vector3(0, 0.3, 0.002)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(color_title, 0.7)
	subtitle.outline_size = 3
	add_child(subtitle)

	# Legend: color key
	var legend_y = -0.3
	var legend_items = [
		{"text": "Rotation / Scale", "color": color_rotation},
		{"text": "Translation", "color": color_translation},
		{"text": "Projection", "color": color_projection},
		{"text": "Homogeneous (w=1)", "color": color_homogeneous},
	]

	var lx = -0.4
	for item in legend_items:
		var dot = MeshInstance3D.new()
		var sq = BoxMesh.new()
		sq.size = Vector3(0.012, 0.012, 0.001)
		dot.mesh = sq
		dot.position = Vector3(lx, legend_y, 0.002)

		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = item["color"]
		dmat.emission_enabled = true
		dmat.emission = item["color"]
		dmat.emission_energy_multiplier = 0.4
		dot.material_override = dmat
		add_child(dot)

		var lbl = Label3D.new()
		lbl.text = item["text"]
		lbl.font_size = 12
		lbl.pixel_size = 0.001
		lbl.position = Vector3(lx + 0.015, legend_y, 0.002)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.modulate = item["color"]
		lbl.outline_size = 2
		add_child(lbl)

		lx += 0.24

	# Key insight annotation
	var insight = Label3D.new()
	insight.name = "InsightLabel"
	insight.text = "Translation lives in the last column — impossible with 3x3 alone"
	insight.font_size = 13
	insight.pixel_size = 0.001
	insight.position = Vector3(0, -0.37, 0.002)
	insight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	insight.modulate = Color(color_translation, 0.85)
	insight.outline_size = 3
	insight.outline_modulate = Color(0, 0, 0, 0.5)
	add_child(insight)


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	pass
