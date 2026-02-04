# static_reference_cube.gd
# Stage 1: Static baseline reference for oscillation progression
# Shows a motionless cube to contrast with animated versions
# "Without stillness, we cannot perceive motion"

extends Node3D

class_name StaticReferenceCube

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var cube_size: float = 0.3
@export var cube_color: Color = Color(0.3, 0.5, 0.8)
@export var show_ground_marker: bool = true
@export var show_label: bool = true

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _ground_marker: MeshInstance3D


func _ready():
	_create_cube()
	_create_ground_marker()
	_create_label()


func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	# Position cube slightly above ground (cube is centered, so offset by half size)
	_cube_instance.position.y = cube_size / 2.0
	add_child(_cube_instance)
	
	# Get the mesh for color customization
	var static_body = _cube_instance.get_node_or_null("CubeBaseStaticBody3D")
	if static_body:
		_cube_mesh = static_body.get_node_or_null("CubeBaseMesh")
		_apply_cube_color()


func _create_ground_marker():
	if not show_ground_marker:
		return
	
	_ground_marker = MeshInstance3D.new()
	var marker = CylinderMesh.new()
	marker.top_radius = cube_size * 0.6
	marker.bottom_radius = cube_size * 0.6
	marker.height = 0.01
	_ground_marker.mesh = marker
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.3, 0.4, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.6)
	mat.emission_energy_multiplier = 0.3
	_ground_marker.material_override = mat
	
	_ground_marker.position.y = 0.005
	add_child(_ground_marker)


func _create_label():
	if not show_label:
		return
	
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 64
	_label.outline_size = 8
	_label.text = "STATIC REFERENCE\nposition = constant"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.position = Vector3(0, cube_size + 0.15, 0)
	_label.modulate = Color(0.7, 0.8, 0.9)
	add_child(_label)
	
	# Formula label below
	var formula = Label3D.new()
	formula.pixel_size = 0.001
	formula.font_size = 48
	formula.outline_size = 6
	formula.text = "y = 0"
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula.position = Vector3(0, -0.05, cube_size * 0.8)
	formula.rotation.x = -PI / 6  # Tilt toward viewer
	formula.modulate = Color(0.5, 0.7, 0.9)
	add_child(formula)


func _apply_cube_color():
	if not _cube_mesh:
		return
	
	# Apply color to the shader material
	var mat = _cube_mesh.material_override
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("wireframeColor", cube_color)
		mat.set_shader_parameter("emissionColor", cube_color * 1.2)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)


# Public API

func get_position_value() -> float:
	"""Always returns 0 - it's static"""
	return 0.0


func get_cube_instance() -> Node3D:
	return _cube_instance


func get_cube_mesh() -> MeshInstance3D:
	return _cube_mesh
