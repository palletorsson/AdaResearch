extends RigidBody3D
class_name MagneticObject

# Magnetic properties
@export var magnetic_strength := 1.0
@export var pole_direction := Vector3(0, 1, 0)  # Direction from south to north pole
@export var pole_color_north := Color(1, 0, 0, 1)  # Red for north
@export var pole_color_south := Color(0, 0, 1, 1)  # Blue for south

# Visual representation
var north_pole: MeshInstance3D
var south_pole: MeshInstance3D
var body: MeshInstance3D

func _ready():
	# Create visual representation
	create_visual()
	
	# Set up physics
	can_sleep = false
	gravity_scale = 0.0  # Disable gravity for easier manipulation
	
	# Allow for user interaction
	input_ray_pickable = true

func create_visual():
	# Create the main body
	body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.1, 0.2, 0.1)
	body.mesh = body_mesh
	
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.8, 0.8, 0.8)
	body_mesh.material = body_material
	
	add_child(body)
	
	# Create north pole indicator
	north_pole = MeshInstance3D.new()
	var north_mesh = SphereMesh.new()
	north_mesh.radius = 0.05
	north_mesh.height = 0.1
	
	var north_material = StandardMaterial3D.new()
	north_material.albedo_color = pole_color_north
	north_material.emission_enabled = true
	north_material.emission = pole_color_north
	north_material.emission_energy = 0.5
	north_mesh.material = north_material
	
	north_pole.mesh = north_mesh
	north_pole.position = pole_direction.normalized() * 0.6
	add_child(north_pole)
	
	# Create south pole indicator
	south_pole = MeshInstance3D.new()
	var south_mesh = SphereMesh.new()
	south_mesh.radius = 0.05
	south_mesh.height = 0.1
	
	var south_material = StandardMaterial3D.new()
	south_material.albedo_color = pole_color_south
	south_material.emission_enabled = true
	south_material.emission = pole_color_south
	south_material.emission_energy = 0.5
	south_mesh.material = south_material
	
	south_pole.mesh = south_mesh
	south_pole.position = -pole_direction.normalized() * 0.6
	add_child(south_pole)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.1, 0.2, 0.1)
	collision.shape = shape
	add_child(collision)

func get_magnetic_moment() -> Vector3:
	# Return the magnetic moment vector
	# Direction is from south to north pole, scaled by strength
	return pole_direction.normalized() * magnetic_strength

func _integrate_forces(state):
	# This could be used to actually apply forces between magnets
	# But we're focusing on visualization for now
	pass

func flip_polarity():
	# Flip the magnetic poles
	pole_direction = -pole_direction
	
	# Swap pole positions
	var temp_pos = north_pole.position
	north_pole.position = south_pole.position
	south_pole.position = temp_pos
