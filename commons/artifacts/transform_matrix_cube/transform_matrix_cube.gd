# transform_matrix_cube.gd
# Interactive 3x3 matrix transformation visualizer
# Shows how a matrix transforms a unit cube
#
# VR-enabled: grab matrix sliders to modify values
# QFEP: Matrix as "rule" - how one space maps to another

extends Node3D

class_name TransformMatrixCube

## Display settings
@export var cube_size: float = 0.4

## Current transformation matrix (3x3)
@export var matrix: Basis = Basis.IDENTITY:
	set(value):
		matrix = value
		_update_visualization()

## Colors
@export var color_original: Color = Color(0.3, 0.3, 0.4, 0.3)  # Ghost original
@export var color_transformed: Color = Color(0.3, 1.0, 0.5, 0.7)  # Transformed
@export var color_i: Color = Color(1.0, 0.3, 0.3)  # X axis
@export var color_j: Color = Color(0.3, 1.0, 0.3)  # Y axis
@export var color_k: Color = Color(0.3, 0.5, 1.0)  # Z axis

var _original_cube: MeshInstance3D
var _transformed_vertices: Array[MeshInstance3D] = []
var _transformed_edges: Array[MeshInstance3D] = []
var _transformed_faces: MeshInstance3D
var _axis_arrows: Array[Node3D] = []
var _info_label: Label3D
var _matrix_label: Label3D
var _det_label: Label3D
var _control_panel: Node3D

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

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_original_cube()
	_create_transformed_cube()
	_create_axis_arrows()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_original_cube():
	# Ghost cube showing original unit cube
	_original_cube = MeshInstance3D.new()
	_original_cube.name = "OriginalCube"
	
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	_original_cube.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_original
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_original_cube.material_override = mat
	
	# Center at origin (cube from 0 to 1 in each axis)
	_original_cube.position = Vector3(cube_size/2, cube_size/2, cube_size/2)
	add_child(_original_cube)

func _create_transformed_cube():
	# Create vertex markers
	for i in range(8):
		var vertex = MeshInstance3D.new()
		vertex.name = "TransformedVertex%d" % i
		var sphere = SphereMesh.new()
		sphere.radius = 0.015
		sphere.height = 0.03
		vertex.mesh = sphere
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_transformed
		mat.emission_enabled = true
		mat.emission = color_transformed
		mat.emission_energy_multiplier = 0.3
		vertex.material_override = mat
		
		_transformed_vertices.append(vertex)
		add_child(vertex)
	
	# Create edge lines
	for i in range(12):
		var edge = MeshInstance3D.new()
		edge.name = "TransformedEdge%d" % i
		_transformed_edges.append(edge)
		add_child(edge)
	
	# Faces mesh
	_transformed_faces = MeshInstance3D.new()
	_transformed_faces.name = "TransformedFaces"
	add_child(_transformed_faces)

func _create_axis_arrows():
	# Show transformed basis vectors (columns of matrix)
	var colors = [color_i, color_j, color_k]
	var labels = ["i'", "j'", "k'"]
	
	for i in range(3):
		var arrow = _create_arrow("Axis%d" % i, colors[i], labels[i])
		_axis_arrows.append(arrow)
		add_child(arrow)

func _create_arrow(arrow_name: String, color: Color, label_text: String) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	shaft.material_override = mat
	arrow.add_child(shaft)
	
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.02
	cone.height = 0.04
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

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 18
	_info_label.position = Vector3(0, cube_size * 2, 0)
	_info_label.text = "MATRIX TRANSFORM"
	add_child(_info_label)
	
	_matrix_label = Label3D.new()
	_matrix_label.name = "MatrixLabel"
	_matrix_label.pixel_size = 0.0012
	_matrix_label.font_size = 12
	_matrix_label.position = Vector3(-cube_size - 0.2, cube_size, 0)
	_matrix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_matrix_label)
	
	_det_label = Label3D.new()
	_det_label.name = "DetLabel"
	_det_label.pixel_size = 0.0015
	_det_label.font_size = 14
	_det_label.position = Vector3(0, cube_size * 1.7, 0)
	_det_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_det_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, cube_size + 0.35)
	_control_panel.rotation_degrees = Vector3(-30, 180, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.15, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Transform presets
	var presets = [
		["IDENTITY", Basis.IDENTITY],
		["SCALE 2X", Basis.from_scale(Vector3(2, 2, 2))],
		["SHEAR", Basis(Vector3(1, 0.5, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))],
		["ROT 45°", Basis(Vector3.UP, deg_to_rad(45))],
		["REFLECT", Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))],
		["SQUISH", Basis.from_scale(Vector3(2, 0.5, 1))]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.2 + (i % 3) * 0.13, 0.035 - (i / 3) * 0.06, -0.005)
		btn.scale = Vector3(0.6, 0.6, 0.6)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var m = presets[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _apply_matrix(m))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.022, 0.01)
	btn.add_child(lbl)

func _apply_matrix(m: Basis):
	matrix = m

func _update_visualization():
	# Transform vertices
	for i in range(8):
		var original = CUBE_VERTICES[i] * cube_size
		var transformed = matrix * original
		_transformed_vertices[i].position = transformed
	
	# Update edges
	for i in range(12):
		var v0 = _transformed_vertices[CUBE_EDGES[i][0]].position
		var v1 = _transformed_vertices[CUBE_EDGES[i][1]].position
		_update_edge(_transformed_edges[i], v0, v1)
	
	# Update faces
	_update_faces()
	
	# Update axis arrows (show where i, j, k go)
	_update_axis_arrow(_axis_arrows[0], matrix.x * cube_size)
	_update_axis_arrow(_axis_arrows[1], matrix.y * cube_size)
	_update_axis_arrow(_axis_arrows[2], matrix.z * cube_size)
	
	# Update labels
	_update_labels()

func _update_edge(edge: MeshInstance3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.001:
		edge.visible = false
		return
	edge.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = length
	edge.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_transformed
	mat.emission_enabled = true
	mat.emission = color_transformed
	mat.emission_energy_multiplier = 0.2
	edge.material_override = mat
	
	edge.position = (start + end) / 2.0
	
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	edge.look_at(edge.global_position + direction, up)
	edge.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_faces():
	# Build mesh for transformed cube faces
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Six faces, each as two triangles
	var faces = [
		[0, 1, 2, 3],  # Bottom
		[4, 7, 6, 5],  # Top
		[0, 4, 5, 1],  # Front
		[2, 6, 7, 3],  # Back
		[0, 3, 7, 4],  # Left
		[1, 5, 6, 2]   # Right
	]
	
	for face in faces:
		var v0 = _transformed_vertices[face[0]].position
		var v1 = _transformed_vertices[face[1]].position
		var v2 = _transformed_vertices[face[2]].position
		var v3 = _transformed_vertices[face[3]].position
		
		# Triangle 1
		immediate_mesh.surface_add_vertex(v0)
		immediate_mesh.surface_add_vertex(v1)
		immediate_mesh.surface_add_vertex(v2)
		
		# Triangle 2
		immediate_mesh.surface_add_vertex(v0)
		immediate_mesh.surface_add_vertex(v2)
		immediate_mesh.surface_add_vertex(v3)
	
	immediate_mesh.surface_end()
	_transformed_faces.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color_transformed.r, color_transformed.g, color_transformed.b, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_transformed_faces.material_override = mat

func _update_axis_arrow(arrow: Node3D, direction: Vector3):
	var length = direction.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	var lbl = arrow.get_node("Label")
	
	shaft.scale = Vector3(1, length, 1)
	shaft.position = direction / 2.0
	head.position = direction
	lbl.position = direction + direction.normalized() * 0.06
	
	# Orient
	arrow.transform = Transform3D.IDENTITY
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + direction, up)
	arrow.rotate_object_local(Vector3.RIGHT, -PI/2)

func _update_labels():
	# Matrix display
	var m = matrix
	_matrix_label.text = "M =\n"
	_matrix_label.text += "| %.2f  %.2f  %.2f |\n" % [m.x.x, m.y.x, m.z.x]
	_matrix_label.text += "| %.2f  %.2f  %.2f |\n" % [m.x.y, m.y.y, m.z.y]
	_matrix_label.text += "| %.2f  %.2f  %.2f |" % [m.x.z, m.y.z, m.z.z]
	
	# Determinant
	var det = matrix.determinant()
	var det_meaning = ""
	if det > 0.01:
		det_meaning = "preserves orientation"
	elif det < -0.01:
		det_meaning = "flips orientation"
	else:
		det_meaning = "collapses dimension!"
	
	_det_label.text = "det(M) = %.3f\n(%s)" % [det, det_meaning]
	
	# Color based on determinant
	if absf(det) < 0.01:
		_det_label.modulate = Color(1, 0.3, 0.3)  # Red - singular
	elif det < 0:
		_det_label.modulate = Color(1, 0.8, 0.3)  # Orange - reflection
	else:
		_det_label.modulate = Color(0.3, 1, 0.5)  # Green - proper

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_matrix(Basis.IDENTITY)
			KEY_2: _apply_matrix(Basis.from_scale(Vector3(2, 2, 2)))
			KEY_3: _apply_matrix(Basis(Vector3(1, 0.5, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)))
			KEY_4: _apply_matrix(Basis(Vector3.UP, deg_to_rad(45)))
			KEY_5: _apply_matrix(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)))
			KEY_6: _apply_matrix(Basis.from_scale(Vector3(2, 0.5, 1)))

func set_matrix(m: Basis):
	matrix = m

func get_determinant() -> float:
	return matrix.determinant()

func animate_to(target_matrix: Basis, duration: float = 1.0):
	# Could implement smooth interpolation here
	var tween = create_tween()
	var start = matrix
	tween.tween_method(func(t): 
		matrix = start.slerp(target_matrix, t)
	, 0.0, 1.0, duration)
