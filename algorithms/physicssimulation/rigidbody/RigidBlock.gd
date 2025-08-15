extends Node3D

class_name RigidBlock

@export var block_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_rotation: Vector3 = Vector3.ZERO

var velocity: Vector3
var angular_velocity: Vector3
var block_size: Vector3 = Vector3(1, 1, 1)
var inertia_tensor: Vector3 = Vector3(1, 1, 1)  # Simplified inertia

func _ready():
	_create_block_mesh()
	_create_wireframe()

func _create_block_mesh():
	# Create the block cube
	var cube = CSGBox3D.new()
	cube.size = block_size
	cube.material = StandardMaterial3D.new()
	cube.material.albedo_color = block_color
	cube.material.emission_enabled = true
	cube.material.emission = block_color * 0.1
	
	add_child(cube)

func _create_wireframe():
	# Create wireframe edges for better visualization
	var wireframe_material = StandardMaterial3D.new()
	wireframe_material.albedo_color = Color.BLACK
	wireframe_material.wireframe = true
	wireframe_material.albedo_color.a = 0.3
	wireframe_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var wireframe_cube = CSGBox3D.new()
	wireframe_cube.size = block_size
	wireframe_cube.material = wireframe_material
	
	add_child(wireframe_cube)

func initialize():
	position = initial_position
	rotation = initial_rotation
	velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func update_physics(delta: float, gravity: Vector3):
	# Apply gravity
	velocity += gravity * delta
	
	# Apply air resistance
	velocity *= 0.99
	angular_velocity *= 0.98
	
	# Update position
	position += velocity * delta
	
	# Update rotation
	rotation += angular_velocity * delta
	
	# Check ground collision
	_check_ground_collision()
	
	# Check wall collisions
	_check_wall_collisions()

func _check_ground_collision():
	var ground_y = 0.5  # Half block height
	
	if position.y < ground_y:
		position.y = ground_y
		velocity.y = -velocity.y * 0.6  # Bounce with energy loss
		velocity.x *= 0.8  # Ground friction
		velocity.z *= 0.8
		
		# Angular friction on ground
		angular_velocity *= 0.7

func _check_wall_collisions():
	var wall_bounds = Vector3(9.5, 10, 9.5)  # Slightly inside walls
	var half_size = block_size / 2
	
	# X-axis walls
	if position.x - half_size.x < -wall_bounds.x:
		position.x = -wall_bounds.x + half_size.x
		velocity.x = -velocity.x * 0.7
		angular_velocity.y *= 0.8
		angular_velocity.z *= 0.8
	elif position.x + half_size.x > wall_bounds.x:
		position.x = wall_bounds.x - half_size.x
		velocity.x = -velocity.x * 0.7
		angular_velocity.y *= 0.8
		angular_velocity.z *= 0.8
	
	# Z-axis walls
	if position.z - half_size.z < -wall_bounds.z:
		position.z = -wall_bounds.z + half_size.z
		velocity.z = -velocity.z * 0.7
		angular_velocity.x *= 0.8
		angular_velocity.y *= 0.8
	elif position.z + half_size.z > wall_bounds.z:
		position.z = wall_bounds.z - half_size.z
		velocity.z = -velocity.z * 0.7
		angular_velocity.x *= 0.8
		angular_velocity.y *= 0.8

func reset_to_initial():
	position = initial_position
	rotation = initial_rotation
	velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
