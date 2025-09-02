# Simple Pink Beam Scene - Just the abstract architectural elements
extends Node3D

@export_category("Pink Beam Settings")
@export var beam_color: Color = Color(0.85, 0.25, 0.65, 1.0)  # Hot pink
@export var beam_metallic: float = 0.4
@export var beam_roughness: float = 0.15
@export var beam_glow: float = 0.1

@export_category("Beam Configuration")
@export var main_beam_size: Vector3 = Vector3(0.8, 6.0, 0.8)
@export var horizontal_beam_size: Vector3 = Vector3(4.0, 0.6, 0.8)
@export var create_l_shape: bool = true

func _ready():
	print("Creating simple pink beam structure...")
	create_basic_floor()
	create_pink_beam_structure()
	setup_simple_lighting()
	print("Pink beam structure complete!")

func create_basic_floor():
	"""Create a simple floor to stand on"""
	
	var floor_body = StaticBody3D.new()
	floor_body.name = "SimpleFloor"
	add_child(floor_body)
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(20, 0.2, 15)  # Large flat floor
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.95, 1.0)  # Light gray
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	floor_body.add_child(mesh_instance)
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(20, 0.2, 15)
	collision_shape.shape = box_shape
	floor_body.add_child(collision_shape)
	
	floor_body.position = Vector3(0, -0.1, 0)

func create_pink_beam_structure():
	"""Create the main abstract pink beam architecture"""
	
	# Main vertical beam (the prominent pink pillar)
	create_beam(
		main_beam_size,
		Vector3(0, main_beam_size.y/2, 0),  # Center it on floor
		"MainPinkBeam"
	)
	
	# Horizontal connecting beam
	create_beam(
		horizontal_beam_size,
		Vector3(horizontal_beam_size.x/2, 4.5, 0),  # Attach to main beam
		"HorizontalBeam"
	)
	
	# Optional L-shaped element
	if create_l_shape:
		create_l_shaped_structure()

func create_beam(size: Vector3, pos: Vector3, name: String):
	"""Create a single pink beam with collision"""
	
	var beam_body = StaticBody3D.new()
	beam_body.name = name
	add_child(beam_body)
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	
	# Create the pink material
	var material = StandardMaterial3D.new()
	material.albedo_color = beam_color
	material.metallic = beam_metallic
	material.roughness = beam_roughness
	
	# Add subtle glow
	if beam_glow > 0:
		material.emission_enabled = true
		material.emission = beam_color * beam_glow
	
	mesh_instance.material_override = material
	beam_body.add_child(mesh_instance)
	
	# Add collision
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	beam_body.add_child(collision_shape)
	
	beam_body.position = pos
	
	print("Created beam: ", name, " at position: ", pos)

func create_l_shaped_structure():
	"""Create an L-shaped architectural element"""
	
	# Vertical part of L
	create_beam(
		Vector3(0.6, 3.0, 0.6),
		Vector3(-3, 1.5, 2),
		"L_Vertical"
	)
	
	# Horizontal part of L extending from vertical
	create_beam(
		Vector3(2.5, 0.6, 0.6),
		Vector3(-1.75, 3, 2),
		"L_Horizontal"
	)

func setup_simple_lighting():
	"""Basic lighting for the beam structure"""
	
	# Main light
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.light_energy = 1.0
	main_light.position = Vector3(5, 8, 5)
	main_light.rotation_degrees = Vector3(-45, -30, 0)
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Simple environment
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.2, 0.2, 0.25, 1.0)  # Dark blue-gray
	environment.ambient_light_energy = 0.3
	environment.ambient_light_color = Color(0.8, 0.8, 1.0, 1.0)
	
	var world_env = WorldEnvironment.new()
	world_env.name = "SimpleEnvironment"
	world_env.environment = environment
	add_child(world_env)
	
	# Accent light for the pink beam
	var accent_light = OmniLight3D.new()
	accent_light.name = "BeamAccentLight"
	accent_light.light_color = Color(1.0, 0.5, 0.8, 1.0)  # Pink-ish
	accent_light.light_energy = 0.8
	accent_light.omni_range = 6.0
	accent_light.position = Vector3(2, 4, 1)
	add_child(accent_light)



# Function to add color scanner testing cubes
func add_test_cubes():
	"""Add some colored cubes for scanner testing"""
	
	var test_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN]
	
	for i in range(test_colors.size()):
		var cube_body = StaticBody3D.new()
		cube_body.name = "TestCube_" + str(i)
		add_child(cube_body)
		
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.3, 0.125, 0.01)  # Your color block size
		mesh_instance.mesh = box_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = test_colors[i]
		mesh_instance.material_override = material
		
		cube_body.add_child(mesh_instance)
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.3, 0.125, 0.01)
		collision_shape.shape = box_shape
		cube_body.add_child(collision_shape)
		
		# Position cubes in a line
		cube_body.position = Vector3(i - 2, 0.5, -2)

# Call this if you want test cubes
func add_test_cubes_if_needed():
	"""Add test cubes only when explicitly needed"""
	call_deferred("add_test_cubes")
