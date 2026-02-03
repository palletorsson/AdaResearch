# riemann_sphere.gd
# The Riemann sphere - compactified complex plane

extends Node3D

class_name RiemannSphere

@export var radius: float = 0.3
@export var show_projection_lines: bool = true

var _sphere: MeshInstance3D
var _north_pole: MeshInstance3D
var _projection_plane: MeshInstance3D
var _label: Label3D

func _ready():
	_create_sphere()
	_create_north_pole()
	_create_projection_plane()
	_create_label()

func _create_sphere():
	_sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 32
	mesh.rings = 16
	_sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.6, 0.9, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.4
	_sphere.material_override = mat
	add_child(_sphere)
	
	# Equator line
	var equator = _create_circle(radius, Color(1, 1, 0, 0.8))
	equator.rotation_degrees.x = 90
	add_child(equator)

func _create_north_pole():
	_north_pole = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	_north_pole.mesh = sphere
	_north_pole.position.y = radius
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.3, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.2)
	mat.emission_energy_multiplier = 0.5
	_north_pole.material_override = mat
	add_child(_north_pole)
	
	var pole_label = Label3D.new()
	pole_label.text = "∞"
	pole_label.pixel_size = 0.002
	pole_label.font_size = 24
	pole_label.position = Vector3(0, radius + 0.05, 0)
	add_child(pole_label)

func _create_projection_plane():
	_projection_plane = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(radius * 3, radius * 3)
	_projection_plane.mesh = plane
	_projection_plane.position.y = -radius
	_projection_plane.rotation_degrees.x = 0
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_projection_plane.material_override = mat
	add_child(_projection_plane)

func _create_circle(r: float, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = r - 0.005
	torus.outer_radius = r + 0.005
	torus.rings = 48
	torus.ring_segments = 8
	mesh_instance.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	return mesh_instance

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "RIEMANN SPHERE\nComplex plane + ∞"
	_label.position = Vector3(0, -radius - 0.2, 0)
	add_child(_label)
