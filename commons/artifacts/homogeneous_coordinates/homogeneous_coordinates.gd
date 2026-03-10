extends Node3D
class_name HomogeneousCoordinates
## Visualizes homogeneous coordinates — why 4×4 matrices encode 3D transforms.
## Displays a color-coded 4×4 matrix: rotation/scale (blue 3×3 block),
## translation (green column), projection (red row), and the homogeneous
## scalar w=1 (gray). A small 3D coordinate frame demonstrates the transform,
## with a VR slider to adjust frame scale interactively.

# --- Constants ---

const CELL_W := 0.1
const CELL_H := 0.055
const MATRIX_ORIGIN_X := -0.32
const MATRIX_ORIGIN_Y := 0.1
const Z_FRONT := 0.003
const Z_LABEL := 0.002
const BRACKET_TICK := 0.02
const LEGEND_SPACING := 0.24
const LEGEND_DOT_SIZE := Vector3(0.012, 0.012, 0.001)
const AXIS_LENGTH := 0.12
const AXIS_LENGTH_Z := 0.08

# --- Configuration ---

## Background panel color
@export var color_panel: Color = Color(0.06, 0.06, 0.1)
## Color for the 3×3 rotation/scale block (blue)
@export var color_rotation: Color = Color(0.3, 0.5, 1.0)
## Color for the translation column (green)
@export var color_translation: Color = Color(0.3, 1.0, 0.5)
## Color for the projection row (red)
@export var color_projection: Color = Color(1.0, 0.35, 0.35)
## Color for the homogeneous scalar w=1 (gray)
@export var color_homogeneous: Color = Color(0.55, 0.55, 0.6)
## Color for titles and bracket lines
@export var color_title: Color = Color(0.92, 0.92, 0.97)

# --- Internal ---

var _panel: MeshInstance3D
var _unshaded_mat: StandardMaterial3D
var _created_nodes: Array[Node] = []
var _frame_root: Node3D
var _frame_scale_slider: Node

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")


func _ready() -> void:
	_unshaded_mat = StandardMaterial3D.new()
	_unshaded_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_unshaded_mat.vertex_color_use_as_albedo = true
	_unshaded_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rebuild()


func _rebuild() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

	_build_panel()
	_build_matrix_display()
	_build_point_transform()
	_build_coordinate_frame()
	_build_labels()
	_setup_controls()


## Builds the background quad panel.
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

	_add_node(_panel)


## Builds the 4×4 matrix display with brackets and color-coded cells.
func _build_matrix_display() -> void:
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

	_build_brackets()
	_build_matrix_cells(matrix_values, cell_colors)


func _build_brackets() -> void:
	var bracket = MeshInstance3D.new()
	bracket.name = "MatrixBrackets"
	var bmesh = ImmediateMesh.new()
	bmesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var left_x = MATRIX_ORIGIN_X - CELL_W * 0.7
	var right_x = MATRIX_ORIGIN_X + CELL_W * 3.7
	var top_y = MATRIX_ORIGIN_Y + CELL_H * 1.8
	var bot_y = MATRIX_ORIGIN_Y - CELL_H * 2.2

	# Left bracket
	_add_line(bmesh, Vector3(left_x + BRACKET_TICK, top_y, Z_FRONT), Vector3(left_x, top_y, Z_FRONT), color_title)
	_add_line(bmesh, Vector3(left_x, top_y, Z_FRONT), Vector3(left_x, bot_y, Z_FRONT), color_title)
	_add_line(bmesh, Vector3(left_x, bot_y, Z_FRONT), Vector3(left_x + BRACKET_TICK, bot_y, Z_FRONT), color_title)

	# Right bracket
	_add_line(bmesh, Vector3(right_x - BRACKET_TICK, top_y, Z_FRONT), Vector3(right_x, top_y, Z_FRONT), color_title)
	_add_line(bmesh, Vector3(right_x, top_y, Z_FRONT), Vector3(right_x, bot_y, Z_FRONT), color_title)
	_add_line(bmesh, Vector3(right_x, bot_y, Z_FRONT), Vector3(right_x - BRACKET_TICK, bot_y, Z_FRONT), color_title)

	# Divider: rotation vs translation column
	var div_x = MATRIX_ORIGIN_X + CELL_W * 2.5
	var div_color = Color(color_title, 0.2)
	_add_line(bmesh, Vector3(div_x, top_y - 0.01, Z_FRONT), Vector3(div_x, bot_y + 0.01, Z_FRONT), div_color)

	# Divider: top 3 rows vs homogeneous row
	var div_y = MATRIX_ORIGIN_Y - CELL_H * 1.2
	_add_line(bmesh, Vector3(left_x + 0.01, div_y, Z_FRONT), Vector3(right_x - 0.01, div_y, Z_FRONT), div_color)

	bmesh.surface_end()
	bracket.mesh = bmesh
	bracket.material_override = _unshaded_mat
	_add_node(bracket)


func _build_matrix_cells(values: Array, colors: Array) -> void:
	for row in range(4):
		for col in range(4):
			var lbl = Label3D.new()
			lbl.name = "Cell_%d_%d" % [row, col]
			lbl.text = values[row][col]
			lbl.font_size = 20
			lbl.pixel_size = 0.001
			lbl.position = Vector3(
				MATRIX_ORIGIN_X + col * CELL_W,
				MATRIX_ORIGIN_Y - row * CELL_H,
				Z_FRONT
			)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.modulate = colors[row][col]
			lbl.outline_size = 3
			lbl.outline_modulate = Color(0, 0, 0, 0.5)
			_add_node(lbl)


## Builds the [x,y,z,1] → M → [x',y',z',1] demonstration below the matrix.
func _build_point_transform() -> void:
	var y_pos = -0.2

	var input_label = Label3D.new()
	input_label.name = "InputVector"
	input_label.text = "[x, y, z, 1]"
	input_label.font_size = 20
	input_label.pixel_size = 0.001
	input_label.position = Vector3(-0.35, y_pos, Z_LABEL)
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_label.modulate = Color(0.9, 0.85, 0.7)
	input_label.outline_size = 3
	_add_node(input_label)

	# Arrow
	var arrow = MeshInstance3D.new()
	arrow.name = "TransformArrow"
	var amesh = ImmediateMesh.new()
	amesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var ax_start = -0.17
	var ax_end = 0.02
	var head = 0.02
	var ac = Color(0.75, 0.75, 0.8)

	_add_line(amesh, Vector3(ax_start, y_pos, Z_LABEL), Vector3(ax_end, y_pos, Z_LABEL), ac)
	_add_line(amesh, Vector3(ax_end, y_pos, Z_LABEL), Vector3(ax_end - head, y_pos + head * 0.5, Z_LABEL), ac)
	_add_line(amesh, Vector3(ax_end, y_pos, Z_LABEL), Vector3(ax_end - head, y_pos - head * 0.5, Z_LABEL), ac)

	amesh.surface_end()
	arrow.mesh = amesh
	arrow.material_override = _unshaded_mat
	_add_node(arrow)

	# "M" label on arrow
	var m_label = Label3D.new()
	m_label.name = "MLabel"
	m_label.text = "M"
	m_label.font_size = 16
	m_label.pixel_size = 0.001
	m_label.position = Vector3((ax_start + ax_end) / 2.0, y_pos + 0.025, Z_LABEL)
	m_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_label.modulate = Color(0.75, 0.75, 0.8)
	m_label.outline_size = 3
	_add_node(m_label)

	var output_label = Label3D.new()
	output_label.name = "OutputVector"
	output_label.text = "[x', y', z', 1]"
	output_label.font_size = 20
	output_label.pixel_size = 0.001
	output_label.position = Vector3(0.2, y_pos, Z_LABEL)
	output_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output_label.modulate = Color(0.9, 0.85, 0.7)
	output_label.outline_size = 3
	_add_node(output_label)


## Builds the 3D coordinate frame with axes, origin dot, and translation vector.
func _build_coordinate_frame() -> void:
	_frame_root = Node3D.new()
	_frame_root.name = "CoordinateFrame"
	_frame_root.position = Vector3(0.38, 0.05, 0.02)
	_add_node(_frame_root)

	var axes = [
		{"dir": Vector3(AXIS_LENGTH, 0, 0), "color": color_rotation, "label": "X"},
		{"dir": Vector3(0, AXIS_LENGTH, 0), "color": color_rotation, "label": "Y"},
		{"dir": Vector3(0, 0, AXIS_LENGTH_Z), "color": color_rotation, "label": "Z"},
	]

	_build_axis_lines(axes)
	_build_axis_labels(axes)
	_build_origin_dot()
	_build_translation_arrow()


func _build_axis_lines(axes: Array) -> void:
	var frame_mesh = ImmediateMesh.new()
	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for axis in axes:
		_add_line(frame_mesh, Vector3.ZERO, axis["dir"], axis["color"])

	frame_mesh.surface_end()

	var frame_inst = MeshInstance3D.new()
	frame_inst.name = "FrameLines"
	frame_inst.mesh = frame_mesh
	frame_inst.material_override = _unshaded_mat
	_frame_root.add_child(frame_inst)
	_created_nodes.append(frame_inst)


func _build_axis_labels(axes: Array) -> void:
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
		_frame_root.add_child(lbl)
		_created_nodes.append(lbl)


func _build_origin_dot() -> void:
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
	_frame_root.add_child(origin_dot)
	_created_nodes.append(origin_dot)


func _build_translation_arrow() -> void:
	var t_end = Vector3(0.07, 0.04, 0.03)
	var tvec_mesh = ImmediateMesh.new()
	tvec_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_add_line(tvec_mesh, Vector3.ZERO, t_end, color_translation)
	tvec_mesh.surface_end()

	var tvec_inst = MeshInstance3D.new()
	tvec_inst.name = "TranslationVector"
	tvec_inst.mesh = tvec_mesh
	tvec_inst.material_override = _unshaded_mat
	_frame_root.add_child(tvec_inst)
	_created_nodes.append(tvec_inst)

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
	_frame_root.add_child(t_label)
	_created_nodes.append(t_label)


## Builds title, subtitle, legend, and insight labels.
func _build_labels() -> void:
	_build_title_labels()
	_build_legend()
	_build_insight_label()


func _build_title_labels() -> void:
	var title = Label3D.new()
	title.name = "TitleLabel"
	title.text = "HOMOGENEOUS COORDINATES"
	title.font_size = 28
	title.pixel_size = 0.001
	title.position = Vector3(0, 0.35, Z_LABEL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = color_title
	title.outline_size = 4
	_add_node(title)

	var subtitle = Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Why 4x4 matrices for 3D transforms"
	subtitle.font_size = 16
	subtitle.pixel_size = 0.001
	subtitle.position = Vector3(0, 0.3, Z_LABEL)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(color_title, 0.7)
	subtitle.outline_size = 3
	_add_node(subtitle)


func _build_legend() -> void:
	var legend_y = -0.3
	var legend_items = [
		{"text": "Rotation / Scale", "color": color_rotation},
		{"text": "Translation", "color": color_translation},
		{"text": "Projection", "color": color_projection},
		{"text": "Homogeneous (w=1)", "color": color_homogeneous},
	]

	var start_x = -0.4

	# Legend dots via MultiMesh (single draw call instead of 4 MeshInstance3D)
	var box := BoxMesh.new()
	box.size = LEGEND_DOT_SIZE

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = legend_items.size()

	for i in legend_items.size():
		var xf := Transform3D()
		xf.origin = Vector3(start_x + i * LEGEND_SPACING, legend_y, Z_LABEL)
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, legend_items[i]["color"])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "LegendDots"
	mmi.multimesh = mm

	var legend_mat := StandardMaterial3D.new()
	legend_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	legend_mat.vertex_color_use_as_albedo = true
	mmi.material_override = legend_mat
	_add_node(mmi)

	# Legend text labels
	for i in legend_items.size():
		var item = legend_items[i]
		var lbl = Label3D.new()
		lbl.text = item["text"]
		lbl.font_size = 12
		lbl.pixel_size = 0.001
		lbl.position = Vector3(start_x + i * LEGEND_SPACING + 0.015, legend_y, Z_LABEL)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.modulate = item["color"]
		lbl.outline_size = 2
		_add_node(lbl)


func _build_insight_label() -> void:
	var insight = Label3D.new()
	insight.name = "InsightLabel"
	insight.text = "Translation lives in the last column — impossible with 3x3 alone"
	insight.font_size = 13
	insight.pixel_size = 0.001
	insight.position = Vector3(0, -0.37, Z_LABEL)
	insight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	insight.modulate = Color(color_translation, 0.85)
	insight.outline_size = 3
	insight.outline_modulate = Color(0, 0, 0, 0.5)
	_add_node(insight)


## Sets up VR slider to control coordinate frame scale.
func _setup_controls() -> void:
	_frame_scale_slider = SliderScene.instantiate()
	_frame_scale_slider.position = Vector3(0.38, -0.15, 0.03)
	_frame_scale_slider.set_param_name("Frame Scale")
	_frame_scale_slider.set_normalized_value(0.5)
	_frame_scale_slider.slider_moved.connect(_on_frame_scale_changed)
	_add_node(_frame_scale_slider)


func _on_frame_scale_changed() -> void:
	var val = _frame_scale_slider.get_normalized_value()
	var s = 0.5 + val * 1.5
	_frame_root.scale = Vector3(s, s, s)


# --- Helpers ---

func _add_line(mesh: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(to)


func _add_node(node: Node) -> void:
	add_child(node)
	_created_nodes.append(node)


func _exit_tree() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("color_panel"):
		color_panel = config_data["color_panel"]
	if config_data.has("color_rotation"):
		color_rotation = config_data["color_rotation"]
	if config_data.has("color_translation"):
		color_translation = config_data["color_translation"]
	if config_data.has("color_projection"):
		color_projection = config_data["color_projection"]
	if config_data.has("color_homogeneous"):
		color_homogeneous = config_data["color_homogeneous"]
	if config_data.has("color_title"):
		color_title = config_data["color_title"]
	if is_inside_tree():
		_rebuild()
