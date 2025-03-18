extends Node3D

# BasicCube.gd
# Creates a simple interactable cube for VR

func _ready():
	create_basic_cube()

func create_basic_cube():
	# Create a RigidBody3D as the root node for physics interaction
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "PickupCube"
	rigid_body.mass = 1.0
	rigid_body.gravity_scale = 1.0
	
	# Create visual representation
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "CubeMesh"
	
	# Create cube mesh
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.2, 0.2, 0.2) # 20cm cube
	mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.5, 1.0) # Blue
	mesh_instance.material_override = material
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.2, 0.2, 0.2) # Match mesh size
	collision_shape.shape = box_shape
	
	# Add XRToolsPickable component if using Godot XR Tools
	var pickable = load("res://addons/godot-xr-tools/objects/pickable.tscn").instantiate()
	
	# Setup the hierarchy
	rigid_body.add_child(mesh_instance)
	rigid_body.add_child(collision_shape)
	rigid_body.add_child(pickable)
	
	# Position the cube 
	rigid_body.position = Vector3(0, 1, 0)
	
	# Add to scene
	add_child(rigid_body)
	
	return rigid_body
