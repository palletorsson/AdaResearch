extends Node3D

# OscillatingCube.gd
# Creates a cube that oscillates up and down

@export var oscillation_height: float = 0.5 # Height of oscillation in meters
@export var oscillation_speed: float = 2.0 # Speed in cycles per second
@export var cube_size: float = 0.2 # Size in meters
@export var cube_color: Color = Color(0.0, 1.0, 0.5) # Green
@export var phase_offset: float = 0.0 # Starting phase (0.0 to 1.0)

var cube: RigidBody3D
var start_position: Vector3
var time_passed: float = 0.0

func _ready():
	cube = create_oscillating_cube()
	start_position = cube.position
	
	# Apply initial phase offset
	time_passed = phase_offset * (2 * PI / oscillation_speed)

func _process(delta):
	# Only update if not being held
	if cube and not is_being_held():
		time_passed += delta
		
		# Calculate new Y position using sine wave
		var new_y = start_position.y + sin(time_passed * oscillation_speed) * oscillation_height
		
		# Update position
		cube.position.y = new_y

func is_being_held() -> bool:
	# Check if the cube is currently being held by a player
	var pickable = cube.get_node_or_null("XRToolsPickable")
	if pickable:
		return pickable.picked_up_by != null
	return false

func create_oscillating_cube():
	# Create a RigidBody3D as the root node for physics interaction
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "OscillatingCube"
	rigid_body.mass = 1.0
	
	# We'll control the position directly, so disable gravity and freeze
	rigid_body.gravity_scale = 0.0
	rigid_body.freeze = true
	
	# Create visual representation
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "CubeMesh"
	
	# Create cube mesh
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(cube_size, cube_size, cube_size)
	mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = cube_color
	mesh_instance.material_override = material
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = box_shape
	
	# Add XRToolsPickable component if using Godot XR Tools
	var pickable = load("res://addons/godot-xr-tools/objects/pickable.tscn").instantiate()
	
	# Connect signals to handle being picked up
	pickable.picked_up.connect(_on_picked_up)
	pickable.dropped.connect(_on_dropped)
	
	# Setup the hierarchy
	rigid_body.add_child(mesh_instance)
	rigid_body.add_child(collision_shape)
	rigid_body.add_child(pickable)
	
	# Position the cube 
	rigid_body.position = Vector3(0, 1, 0)
	
	# Add to scene
	add_child(rigid_body)
	
	return rigid_body

func _on_picked_up(by):
	# When picked up, allow physics to take over
	cube.freeze = false
	cube.gravity_scale = 1.0

func _on_dropped(by):
	# When dropped, let it fall to the ground
	await get_tree().create_timer(1.0).timeout
	
	# Check if it's still not being held and reset it
	if not is_being_held():
		# Resume oscillation
		cube.freeze = true
		cube.gravity_scale = 0.0
		start_position = Vector3(cube.position.x, 1.0, cube.position.z)
