extends Node3D
class_name ShearMatrixDemo

## Wall panel showing shearing transformation — a unit square sheared into a parallelogram.
## Displays the 2x2 shear matrix and both original/transformed shapes side by side.

# --- Configuration ---

@export var shear_factor: float = 0.5
@export var shape_size: float = 0.25
@export var color_original: Color = Color(0.3, 0.5, 1.0)
@export var color_sheared: Color = Color(1.0, 0.6, 0.2)
@export var color_panel: Color = Color(0.08, 0.08, 0.12)
@export var color_arrow: Color = Color(0.7, 0.7, 0.8)

# --- Internal ---

var _panel: MeshInstance3D
var _original_mesh: MeshInstance3D
var _sheared_mesh: MeshInstance3D
var _arrow_mesh: MeshInstance3D
var _matrix_label: Label3D
var _title_label: Label3D
var _original_label: Label3D
var _sheared_label: Label3D


func _ready() -> void:
	_build_panel()
	_build_original_square()
	_build_sheared_parallelogram()
	_build_arrow()
	_build_labels()


func _build_panel() -> void:
	_panel = MeshInstance3D.new()
	_panel.name = "BackPanel"
	var quad = QuadMesh.new()
	quad.size = Vector2(1.0, 0.7)
	_panel.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_panel
	mat.roughness = 0.9
	mat.metallic = 0.1
	_panel.material_override = mat

	add_child(_panel)


func _build_original_square() -> void:
	_original_mesh = MeshInstance3D.new()
	_original_mesh.name = "OriginalSquare"

	var mesh = ImmediateMesh.new()
	var s = shape_size
	var offset_x = -0.28

	# Draw unit square outline
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var verts = [
		Vector3(offset_x, -s / 2.0, 0.001),
		Vector3(offset_x + s, -s / 2.0, 0.001),
		Vector3(offset_x + s, s / 2.0, 0.001),
		Vector3(offset_x, s / 2.0, 0.001),
	]

	# Draw 4 edges of the square
	for i in range(4):
		mesh.surface_set_color(color_original)
		mesh.surface_add_vertex(verts[i])
		mesh.surface_set_color(color_original)
		mesh.surface_add_vertex(verts[(i + 1) % 4])

	# Draw diagonal for visual reference
	mesh.surface_set_color(Color(color_original, 0.3))
	mesh.surface_add_vertex(verts[0])
	mesh.surface_set_color(Color(color_original, 0.3))
	mesh.surface_add_vertex(verts[2])

	mesh.surface_end()
	_original_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_original_mesh.material_override = mat

	add_child(_original_mesh)


func _build_sheared_parallelogram() -> void:
	_sheared_mesh = MeshInstance3D.new()
	_sheared_mesh.name = "ShearedParallelogram"

	var mesh = ImmediateMesh.new()
	var s = shape_size
	var k = shear_factor
	var offset_x = 0.08

	# Shear matrix [[1, k], [0, 1]] applied to unit square vertices
	# (x, y) -> (x + k*y, y)
	var verts = [
		Vector3(offset_x + 0.0, -s / 2.0, 0.001),                    # (0,0) -> (0,0)
		Vector3(offset_x + s, -s / 2.0, 0.001),                       # (1,0) -> (1,0)
		Vector3(offset_x + s + k * s, s / 2.0, 0.001),                # (1,1) -> (1+k, 1)
		Vector3(offset_x + k * s, s / 2.0, 0.001),                    # (0,1) -> (k, 1)
	]

	# Draw 4 edges of the parallelogram
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(4):
		mesh.surface_set_color(color_sheared)
		mesh.surface_add_vertex(verts[i])
		mesh.surface_set_color(color_sheared)
		mesh.surface_add_vertex(verts[(i + 1) % 4])

	# Draw diagonal
	mesh.surface_set_color(Color(color_sheared, 0.3))
	mesh.surface_add_vertex(verts[0])
	mesh.surface_set_color(Color(color_sheared, 0.3))
	mesh.surface_add_vertex(verts[2])

	mesh.surface_end()
	_sheared_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sheared_mesh.material_override = mat

	add_child(_sheared_mesh)


func _build_arrow() -> void:
	_arrow_mesh = MeshInstance3D.new()
	_arrow_mesh.name = "TransformArrow"

	var mesh = ImmediateMesh.new()
	var arrow_y = 0.0
	var arrow_x_start = -0.01
	var arrow_x_end = 0.06
	var head_size = 0.02

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Arrow shaft
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_start, arrow_y, 0.001))
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_end, arrow_y, 0.001))

	# Arrowhead top
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_end, arrow_y, 0.001))
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_end - head_size, arrow_y + head_size * 0.6, 0.001))

	# Arrowhead bottom
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_end, arrow_y, 0.001))
	mesh.surface_set_color(color_arrow)
	mesh.surface_add_vertex(Vector3(arrow_x_end - head_size, arrow_y - head_size * 0.6, 0.001))

	mesh.surface_end()
	_arrow_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_arrow_mesh.material_override = mat

	add_child(_arrow_mesh)


func _build_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "SHEAR TRANSFORMATION"
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.28, 0.002)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.9, 0.9, 0.95)
	_title_label.outline_size = 4
	add_child(_title_label)

	# Matrix label
	_matrix_label = Label3D.new()
	_matrix_label.name = "MatrixLabel"
	var k_str = "%.1f" % shear_factor
	_matrix_label.text = "S =\n| 1   %s |\n| 0   1  |" % k_str
	_matrix_label.font_size = 22
	_matrix_label.pixel_size = 0.001
	_matrix_label.position = Vector3(0, -0.2, 0.002)
	_matrix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_matrix_label.modulate = Color(0.85, 0.85, 0.9)
	_matrix_label.outline_size = 3
	add_child(_matrix_label)

	# "Original" label under left square
	_original_label = Label3D.new()
	_original_label.name = "OriginalLabel"
	_original_label.text = "Original"
	_original_label.font_size = 18
	_original_label.pixel_size = 0.001
	_original_label.position = Vector3(-0.155, -0.18, 0.002)
	_original_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_original_label.modulate = color_original
	_original_label.outline_size = 3
	add_child(_original_label)

	# "Sheared" label under right parallelogram
	_sheared_label = Label3D.new()
	_sheared_label.name = "ShearedLabel"
	_sheared_label.text = "Sheared (k=%s)" % ("%.1f" % shear_factor)
	_sheared_label.font_size = 18
	_sheared_label.pixel_size = 0.001
	_sheared_label.position = Vector3(0.21, -0.18, 0.002)
	_sheared_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheared_label.modulate = color_sheared
	_sheared_label.outline_size = 3
	add_child(_sheared_label)


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("shear_factor"):
		shear_factor = float(config_data["shear_factor"])
	if config_data.has("shape_size"):
		shape_size = float(config_data["shape_size"])
