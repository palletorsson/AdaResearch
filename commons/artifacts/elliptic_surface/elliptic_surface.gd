# elliptic_surface.gd
# Dome/sphere-like surface demonstrating positive curvature

extends Node3D

class_name EllipticSurface

@export var radius: float = 0.4
@export var resolution: int = 24

var _mesh_instance: MeshInstance3D
var _label: Label3D

func _ready():
	_create_surface()
	_create_label()

func _create_surface():
	_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = resolution
	sphere.rings = resolution / 2
	_mesh_instance.mesh = sphere
	
	# Only show upper hemisphere
	_mesh_instance.position.y = -radius * 0.3
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.5, 0.3)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "ELLIPTIC SURFACE\nPositive curvature\nK > 0"
	_label.position = Vector3(0, -radius - 0.15, 0)
	add_child(_label)
