# angle_sum_triangle.gd
# Demonstrates that triangle angles sum to 180° (in Euclidean space)

extends Node3D

@export var size: float = 0.4
var _triangle: MeshInstance3D
var _angle_labels: Array[Label3D] = []
var _sum_label: Label3D

func _ready():
	_create_triangle()
	_create_labels()

func _create_triangle():
	_triangle = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var v1 = Vector3(0, size * 0.5, 0)
	var v2 = Vector3(-size * 0.4, -size * 0.3, 0)
	var v3 = Vector3(size * 0.4, -size * 0.3, 0)
	
	im.surface_add_vertex(v1)
	im.surface_add_vertex(v2)
	im.surface_add_vertex(v3)
	im.surface_add_vertex(v1)
	im.surface_end()
	
	_triangle.mesh = im
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.8, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_triangle.material_override = mat
	add_child(_triangle)

func _create_labels():
	var angles = ["60°", "60°", "60°"]  # Equilateral for simplicity
	var positions = [Vector3(0, size * 0.55, 0.01), Vector3(-size * 0.45, -size * 0.35, 0.01), Vector3(size * 0.45, -size * 0.35, 0.01)]
	
	for i in range(3):
		var lbl = Label3D.new()
		lbl.text = angles[i]
		lbl.pixel_size = 0.001
		lbl.font_size = 14
		lbl.position = positions[i]
		lbl.modulate = Color(1, 0.9, 0.5)
		add_child(lbl)
		_angle_labels.append(lbl)
	
	_sum_label = Label3D.new()
	_sum_label.text = "60° + 60° + 60° = 180°"
	_sum_label.pixel_size = 0.001
	_sum_label.font_size = 12
	_sum_label.position = Vector3(0, -size * 0.6, 0)
	add_child(_sum_label)
