# jelly_cube.gd
# A soft, deformable cube that jiggles when touched
# Demonstrates soft body physics - queer morphology precursor

extends Node3D

class_name JellyCube

## Size of the cube
@export var cube_size: float = 0.3

## Subdivisions (more = smoother deformation, slower)
@export_range(1, 8) var subdivisions: int = 4

## Jelly color
@export var jelly_color: Color = Color(0.2, 0.9, 0.5, 0.8)  # Semi-transparent green

## Physics properties
@export_group("Physics")
@export var stiffness: float = 0.5  # 0 = very soft, 1 = rigid
@export var damping: float = 0.01   # Energy loss
@export var pressure: float = 1.0    # Internal pressure
@export var mass: float = 1.0

## Emission for glow effect
@export_group("Appearance")
@export var emission_strength: float = 0.2
@export var use_transparency: bool = true

var _soft_body: SoftBody3D
var _material: StandardMaterial3D

func _ready():
	_create_soft_body()
	_create_pedestal()

func _create_soft_body():
	_soft_body = SoftBody3D.new()
	_soft_body.name = "JellySoftBody"
	
	# Create subdivided box mesh
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	box.subdivide_width = subdivisions
	box.subdivide_height = subdivisions
	box.subdivide_depth = subdivisions
	_soft_body.mesh = box
	
	# Physics settings
	_soft_body.simulation_precision = 5
	_soft_body.total_mass = mass
	_soft_body.linear_stiffness = stiffness
	_soft_body.pressure_coefficient = pressure
	_soft_body.damping_coefficient = damping
	_soft_body.drag_coefficient = 0.0
	
	# Collision
	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 1
	
	# Material
	_material = StandardMaterial3D.new()
	_material.albedo_color = jelly_color
	
	if use_transparency:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if emission_strength > 0:
		_material.emission_enabled = true
		_material.emission = jelly_color
		_material.emission_energy_multiplier = emission_strength
	
	_material.roughness = 0.2
	_material.metallic = 0.0
	
	_soft_body.material_override = _material
	
	# Position above pedestal
	_soft_body.position = Vector3(0, cube_size / 2 + 0.05, 0)
	
	add_child(_soft_body)

func _create_pedestal():
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cube_size * 0.6
	cylinder.bottom_radius = cube_size * 0.7
	cylinder.height = 0.04
	pedestal.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.8
	mat.roughness = 0.3
	pedestal.material_override = mat
	
	pedestal.position = Vector3(0, -0.02, 0)
	add_child(pedestal)
	
	# Add collision for pedestal
	var static_body = StaticBody3D.new()
	static_body.name = "PedestalCollision"
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = cube_size * 0.7
	shape.height = 0.04
	collision.shape = shape
	static_body.add_child(collision)
	static_body.position = Vector3(0, -0.02, 0)
	add_child(static_body)

## Apply an impulse to the jelly (for poking)
func poke(world_position: Vector3, force: float = 2.0):
	if not _soft_body:
		return
	
	# Find nearest point and apply force
	var direction = (_soft_body.global_position - world_position).normalized()
	# SoftBody3D doesn't have direct impulse, but we can use the physics server
	# For now, this is a placeholder - actual implementation would need RayCast to find vertices

## Set jelly color at runtime
func set_color(color: Color):
	jelly_color = color
	if _material:
		_material.albedo_color = color
		if emission_strength > 0:
			_material.emission = color

## Adjust physics properties at runtime
func set_stiffness(value: float):
	stiffness = value
	if _soft_body:
		_soft_body.linear_stiffness = value

func set_pressure(value: float):
	pressure = value
	if _soft_body:
		_soft_body.pressure_coefficient = value

func set_damping(value: float):
	damping = value
	if _soft_body:
		_soft_body.damping_coefficient = value
