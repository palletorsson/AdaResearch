extends Node3D

# RotatingCube.gd
# Creates a cube that rotates continuously

@export var rotation_speed: Vector3 = Vector3(1.0, 2.0, 0.5) # Rotation speed in radians per second
@export var cube_size: float = 0.2 # Size in meters
@export var cube_color: Color = Color(1.0, 0.5, 0.0) # Orange

var cube: RigidBody3D

func _ready():
	cube = create_rotating_cube()

func _process(delta):
	# Apply continuous rotation using the _process method
	# Don't rotate if being held by player
	if cube and not is_being_held():
		cube.rotate_x(rotation_speed.x * delta)
		cube.rotate_y(rotation_speed.y * delta)
		cube.rotate_z(rotation_speed.z * delta)

func is_being_held() -> bool:
	# Check if the cube is currently being held by a player
	var pickable = cube.get_node_or_null("XRToolsPickable")
	if pickable:
		return pickable.picked_up_by != null
	return false

func create_rotating_cube():
	# Create a RigidBody3D as the root node for physics interaction
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "RotatingCube"
	rigid_body.mass = 1.0
	rigid_body.gravity_scale = 1.0
	
	# When not being held, we want it to stay in place
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
	# When picked up, unfreeze to allow physics
	cube.freeze = false

func _on_dropped(by):
	# When dropped, keep physics enabled to allow it to fall
	# It will return to rotating once it comes to rest
	await get_tree().create_timer(2.0).timeout
	
	# Check if it's still not being held
	if not is_being_held():
		cube.freeze = true
