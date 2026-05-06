# transform_matrix_cube.gd
# Interactive 3x3 matrix transformation visualizer
# Shows how a matrix transforms a unit cube
#
# VR-enabled: grab matrix sliders to modify values
# QFEP: Matrix as "rule" - how one space maps to another

extends Node3D

class_name TransformMatrixCube

## Size of the unit cube visualization (meters)
@export_range(0.1, 2.0, 0.05) var cube_size: float = 0.4

## Current transformation matrix (3x3)
@export var matrix: Basis = Basis.IDENTITY:
	set(value):
		matrix = value
		_update_visualization()

## Color of the ghost original cube
@export var color_original: Color = Color(0.3, 0.3, 0.4, 0.3)
## Color of the transformed cube
@export var color_transformed: Color = Color(0.3, 1.0, 0.5, 0.7)
## Color of the X basis vector arrow
@export var color_i: Color = Color(1.0, 0.3, 0.3)
## Color of the Y basis vector arrow
@export var color_j: Color = Color(0.3, 1.0, 0.3)
## Color of the Z basis vector arrow
@export var color_k: Color = Color(0.3, 0.5, 1.0)

# Shared material templates
var _base_emissive_mat: StandardMaterial3D
var _edge_mat: StandardMaterial3D
var _face_mat: StandardMaterial3D

var _original_cube: MeshInstance3D
var _vertex_mm: MultiMesh
var _vertex_mmi: MultiMeshInstance3D
var _edge_mm: MultiMesh
var _edge_mmi: MultiMeshInstance3D
var _transformed_faces: MeshInstance3D
var _axis_arrows: Array[Node3D] = []
var _info_label: Label3D
var _matrix_label: Label3D
var _det_label: Label3D
var _control_panel: Node3D
var _created_nodes: Array[Node] = []

# Unit cube vertices
const CUBE_VERTICES = [
	Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),
	Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)
]

# Edge connections (pairs of vertex indices)
const CUBE_EDGES = [
	[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
	[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
	[0, 4], [1, 5], [2, 6], [3, 7]   # Verticals
]

const VERTEX_RADIUS := 0.015
const VERTEX_HEIGHT := 0.03
const EDGE_RADIUS := 0.004
const ARROW_SHAFT_RADIUS := 0.008
const ARROW_HEAD_RADIUS := 0.02
const ARROW_HEAD_HEIGHT := 0.04
const ARROW_LABEL_OFFSET := 0.06
const MIN_EDGE_LENGTH := 0.001
const MIN_ARROW_LENGTH := 0.01
const DET_THRESHOLD := 0.01


func _ready() -> void:
	_init_shared_materials()
	_create_original_cube()
	_create_transformed_cube()
	_create_axis_arrows()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _init_shared_materials() -> void:
	_base_emissive_mat = StandardMaterial3D.new()
	_base_emissive_mat.emission_enabled = true
	_base_emissive_mat.emission_energy_multiplier = 0.3

	_edge_mat = StandardMaterial3D.new()
	_edge_mat.albedo_color = color_transformed
	_edge_mat.emission_enabled = true
	_edge_mat.emission = color_transformed
	_edge_mat.emission_energy_multiplier = 0.2

	_face_mat = StandardMaterial3D.new()
	_face_mat.albedo_color = Color(color_transformed.r, color_transformed.g, color_transformed.b, 0.15)
	_face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

func _create_original_cube() -> void:
	_original_cube = MeshInstance3D.new()
	_original_cube.name = "OriginalCube"

	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	_original_cube.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_original
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_original_cube.material_override = mat

	_original_cube.position = Vector3(cube_size / 2.0, cube_size / 2.0, cube_size / 2.0)
	_add_node(_original_cube)

func _create_transformed_cube() -> void:
	# Vertex markers via MultiMesh (8 spheres, one draw call)
	var sphere := SphereMesh.new()
	sphere.radius = VERTEX_RADIUS
	sphere.height = VERTEX_HEIGHT

	_vertex_mm = MultiMesh.new()
	_vertex_mm.transform_format = MultiMesh.TRANSFORM_3D
	_vertex_mm.use_colors = false
	_vertex_mm.mesh = sphere
	_vertex_mm.instance_count = 8

	_vertex_mmi = MultiMeshInstance3D.new()
	_vertex_mmi.name = "TransformedVertices"
	_vertex_mmi.multimesh = _vertex_mm

	var vert_mat := _base_emissive_mat.duplicate() as StandardMaterial3D
	vert_mat.albedo_color = color_transformed
	vert_mat.emission = color_transformed
	_vertex_mmi.material_override = vert_mat
	_add_node(_vertex_mmi)

	# Edge lines via MultiMesh (12 cylinders, one draw call)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = EDGE_RADIUS
	cylinder.bottom_radius = EDGE_RADIUS
	cylinder.height = 1.0

	_edge_mm = MultiMesh.new()
	_edge_mm.transform_format = MultiMesh.TRANSFORM_3D
	_edge_mm.use_colors = false
	_edge_mm.mesh = cylinder
	_edge_mm.instance_count = 12

	_edge_mmi = MultiMeshInstance3D.new()
	_edge_mmi.name = "TransformedEdges"
	_edge_mmi.multimesh = _edge_mm
	_edge_mmi.material_override = _edge_mat
	_add_node(_edge_mmi)

	# Faces mesh
	_transformed_faces = MeshInstance3D.new()
	_transformed_faces.name = "TransformedFaces"
	_transformed_faces.material_override = _face_mat
	_add_node(_transformed_faces)

func _create_axis_arrows() -> void:
	var colors = [color_i, color_j, color_k]
	var labels = ["i'", "j'", "k'"]

	_axis_arrows.resize(3)
	for i in range(3):
		var arrow = _create_arrow("Axis%d" % i, colors[i], labels[i])
		_axis_arrows[i] = arrow
		_add_node(arrow)

func _create_arrow(arrow_name: String, color: Color, label_text: String) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name

	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = ARROW_SHAFT_RADIUS
	cylinder.bottom_radius = ARROW_SHAFT_RADIUS
	cylinder.height = 1.0
	shaft.mesh = cylinder

	var mat := _base_emissive_mat.duplicate() as StandardMaterial3D
	mat.albedo_color = color
	mat.emission = color
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_HEAD_RADIUS
	cone.height = ARROW_HEAD_HEIGHT
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)

	var lbl = Label3D.new()
	lbl.name = "Label"
	lbl.text = label_text
	lbl.pixel_size = 0.0015
	lbl.font_size = 14
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(lbl)

	return arrow

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 18
	_info_label.position = Vector3(0, cube_size * 2, 0)
	_info_label.text = "MATRIX TRANSFORM"
	_add_node(_info_label)

	_matrix_label = Label3D.new()
	_matrix_label.name = "MatrixLabel"
	_matrix_label.pixel_size = 0.0012
	_matrix_label.font_size = 12
	_matrix_label.position = Vector3(-cube_size - 0.2, cube_size, 0)
	_matrix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_add_node(_matrix_label)

	_det_label = Label3D.new()
	_det_label.name = "DetLabel"
	_det_label.pixel_size = 0.0015
	_det_label.font_size = 14
	_det_label.position = Vector3(0, cube_size * 1.7, 0)
	_det_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_node(_det_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("MATRIX", [
		[
			{"type": "button", "label": "IDENTITY"},
			{"type": "button", "label": "SCALE 2X"},
			{"type": "button", "label": "SHEAR"},
		],
		[
			{"type": "button", "label": "ROT 45"},
			{"type": "button", "label": "REFLECT"},
			{"type": "button", "label": "SQUISH"},
		],
	])
	_control_panel.position = Vector3(0, 0.04, cube_size + 0.35)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	_add_node(_control_panel)

	var presets: Array[Basis] = [
		Basis.IDENTITY,
		Basis.from_scale(Vector3(2, 2, 2)),
		Basis(Vector3(1, 0.5, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)),
		Basis(Vector3.UP, deg_to_rad(45)),
		Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)),
		Basis.from_scale(Vector3(2, 0.5, 1)),
	]
	for i in range(presets.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var m: Basis = presets[i]
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _apply_matrix(m))

func _apply_matrix(m: Basis) -> void:
	matrix = m

func _add_node(node: Node) -> void:
	add_child(node)
	_created_nodes.append(node)

func _update_visualization() -> void:
	if not _vertex_mm or not _edge_mm:
		return

	# Compute transformed vertex positions
	var positions: Array[Vector3] = []
	positions.resize(8)
	for i in range(8):
		var original = CUBE_VERTICES[i] * cube_size
		positions[i] = matrix * original
		var xf := Transform3D()
		xf.origin = positions[i]
		_vertex_mm.set_instance_transform(i, xf)

	# Update edges via MultiMesh transforms
	for i in range(12):
		var v0 = positions[CUBE_EDGES[i][0]]
		var v1 = positions[CUBE_EDGES[i][1]]
		_set_edge_transform(i, v0, v1)

	# Update faces
	_update_faces(positions)

	# Update axis arrows (show where i, j, k go)
	_update_axis_arrow(_axis_arrows[0], matrix.x * cube_size)
	_update_axis_arrow(_axis_arrows[1], matrix.y * cube_size)
	_update_axis_arrow(_axis_arrows[2], matrix.z * cube_size)

	# Update labels
	_update_labels()

func _set_edge_transform(idx: int, start: Vector3, end: Vector3) -> void:
	var direction = end - start
	var length = direction.length()

	if length < MIN_EDGE_LENGTH:
		# Hide by scaling to zero
		_edge_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		return

	var midpoint = (start + end) / 2.0
	var dir_n = direction / length

	# Build basis that aligns Y axis with the edge direction
	var up = Vector3.UP
	if abs(dir_n.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var right = dir_n.cross(up).normalized()
	var forward = right.cross(dir_n).normalized()

	var basis = Basis(right, dir_n, forward) * Basis.IDENTITY.scaled(Vector3(1, length, 1))
	_edge_mm.set_instance_transform(idx, Transform3D(basis, midpoint))

func _update_faces(positions: Array[Vector3]) -> void:
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var faces = [
		[0, 1, 2, 3],  # Bottom
		[4, 7, 6, 5],  # Top
		[0, 4, 5, 1],  # Front
		[2, 6, 7, 3],  # Back
		[0, 3, 7, 4],  # Left
		[1, 5, 6, 2]   # Right
	]

	for face in faces:
		var v0 = positions[face[0]]
		var v1 = positions[face[1]]
		var v2 = positions[face[2]]
		var v3 = positions[face[3]]

		immediate_mesh.surface_add_vertex(v0)
		immediate_mesh.surface_add_vertex(v1)
		immediate_mesh.surface_add_vertex(v2)

		immediate_mesh.surface_add_vertex(v0)
		immediate_mesh.surface_add_vertex(v2)
		immediate_mesh.surface_add_vertex(v3)

	immediate_mesh.surface_end()
	_transformed_faces.mesh = immediate_mesh

func _update_axis_arrow(arrow: Node3D, direction: Vector3) -> void:
	var length = direction.length()
	if length < MIN_ARROW_LENGTH:
		arrow.visible = false
		return
	arrow.visible = true

	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	var lbl = arrow.get_node("Label")

	shaft.scale = Vector3(1, length, 1)
	shaft.position = direction / 2.0
	head.position = direction
	lbl.position = direction + direction.normalized() * ARROW_LABEL_OFFSET

	# Orient
	arrow.transform = Transform3D.IDENTITY
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + direction, up)
	arrow.rotate_object_local(Vector3.RIGHT, -PI / 2)

func _update_labels() -> void:
	var m = matrix
	_matrix_label.text = "M =\n"
	_matrix_label.text += "| %.2f  %.2f  %.2f |\n" % [m.x.x, m.y.x, m.z.x]
	_matrix_label.text += "| %.2f  %.2f  %.2f |\n" % [m.x.y, m.y.y, m.z.y]
	_matrix_label.text += "| %.2f  %.2f  %.2f |" % [m.x.z, m.y.z, m.z.z]

	var det = matrix.determinant()
	var det_meaning = ""
	if det > DET_THRESHOLD:
		det_meaning = "preserves orientation"
	elif det < -DET_THRESHOLD:
		det_meaning = "flips orientation"
	else:
		det_meaning = "collapses dimension!"

	_det_label.text = "det(M) = %.3f\n(%s)" % [det, det_meaning]

	if absf(det) < DET_THRESHOLD:
		_det_label.modulate = Color(1, 0.3, 0.3)  # Red - singular
	elif det < 0:
		_det_label.modulate = Color(1, 0.8, 0.3)  # Orange - reflection
	else:
		_det_label.modulate = Color(0.3, 1, 0.5)  # Green - proper

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_matrix(Basis.IDENTITY)
			KEY_2: _apply_matrix(Basis.from_scale(Vector3(2, 2, 2)))
			KEY_3: _apply_matrix(Basis(Vector3(1, 0.5, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)))
			KEY_4: _apply_matrix(Basis(Vector3.UP, deg_to_rad(45)))
			KEY_5: _apply_matrix(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)))
			KEY_6: _apply_matrix(Basis.from_scale(Vector3(2, 0.5, 1)))

func set_matrix(m: Basis) -> void:
	matrix = m

func get_determinant() -> float:
	return matrix.determinant()

func animate_to(target_matrix: Basis, duration: float = 1.0) -> void:
	var tween = create_tween()
	var start = matrix
	tween.tween_method(func(t):
		matrix = start.slerp(target_matrix, t)
	, 0.0, 1.0, duration)

func apply_grid_config(config_data: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()
