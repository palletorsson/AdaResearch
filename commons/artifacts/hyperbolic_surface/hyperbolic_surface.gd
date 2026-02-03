# hyperbolic_surface.gd
# Saddle-shaped surface demonstrating negative curvature

extends Node3D

class_name HyperbolicSurface

@export var size: float = 0.5
@export var resolution: int = 20
@export var curvature: float = 1.0

var _mesh_instance: MeshInstance3D
var _label: Label3D

func _ready():
	_create_surface()
	_create_label()

func _create_surface():
	_mesh_instance = MeshInstance3D.new()
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var step = size * 2.0 / resolution
	
	for i in range(resolution):
		for j in range(resolution):
			var x1 = -size + i * step
			var z1 = -size + j * step
			var x2 = x1 + step
			var z2 = z1 + step
			
			# Saddle shape: y = x² - z² (negative Gaussian curvature)
			var y11 = curvature * (x1 * x1 - z1 * z1) * 0.5
			var y12 = curvature * (x1 * x1 - z2 * z2) * 0.5
			var y21 = curvature * (x2 * x2 - z1 * z1) * 0.5
			var y22 = curvature * (x2 * x2 - z2 * z2) * 0.5
			
			# Triangle 1
			surface_tool.add_vertex(Vector3(x1, y11, z1))
			surface_tool.add_vertex(Vector3(x2, y21, z1))
			surface_tool.add_vertex(Vector3(x1, y12, z2))
			
			# Triangle 2
			surface_tool.add_vertex(Vector3(x2, y21, z1))
			surface_tool.add_vertex(Vector3(x2, y22, z2))
			surface_tool.add_vertex(Vector3(x1, y12, z2))
	
	surface_tool.generate_normals()
	_mesh_instance.mesh = surface_tool.commit()
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.8)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "HYPERBOLIC SURFACE\nNegative curvature\nK < 0"
	_label.position = Vector3(0, -size - 0.1, 0)
	add_child(_label)
