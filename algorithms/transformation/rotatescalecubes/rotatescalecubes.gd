# VRCubes.gd
# A Godot 4 implementation of the Three.js VR Cubes example.
# This scene fills a space with hundreds of randomly colored, rotating cubes.
extends Node3D

## The total number of cubes to generate.
@export var cube_count: int = 500

## The radius of the sphere within which cubes will be randomly placed.
@export var spread_radius: float = 10.0

## The overall speed of the cube rotations.
@export var animation_speed: float = 0.5

var multi_mesh_instance: MultiMeshInstance3D
var rotation_speeds: Array[Vector3] = []

func _ready():
	setup_lighting()
	setup_cubes()

func setup_lighting():
	# Create a simple environment for basic lighting and a dark background.
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.2, 0.2)
	env.environment = environment
	add_child(env)
	
	# Add a key light to give the cubes some definition.
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)

func create_grid_shader_material() -> ShaderMaterial:
	"""Create a Grid shader material like the one used in cube_scene.tscn"""
	var material = ShaderMaterial.new()
	
	# Load the Grid shader
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		
		# Set default shader parameters (similar to cube_scene.tscn)
		material.set_shader_parameter("modelColor", Color(0.5, 0.5, 0.5, 1.0))
		material.set_shader_parameter("wireframeColor", Color(0.0, 1.0, 0.0, 1.0))  # Green wireframe
		material.set_shader_parameter("emissionColor", Color(0.8, 0.1, 0.7, 1.0))   # Magenta emission
		material.set_shader_parameter("width", 8.68)
		material.set_shader_parameter("blur", 0.581)
		material.set_shader_parameter("emission_strength", 2.018)
		material.set_shader_parameter("modelOpacity", 0.924)
	else:
		print("Warning: Could not load Grid shader, falling back to standard material")
		# Fallback to standard material if shader loading fails
		var fallback_material = StandardMaterial3D.new()
		fallback_material.albedo_color = Color.GRAY
		fallback_material.emission_enabled = true
		fallback_material.emission = Color(0.8, 0.1, 0.7)
		return fallback_material
	
	return material

func setup_cubes():
	# Use a MultiMesh for performance, which is ideal for drawing
	# thousands of identical meshes.
	multi_mesh_instance = MultiMeshInstance3D.new()
	
	# 1. Create the MultiMesh resource.
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = cube_count
	
	# 2. Define the mesh that will be repeated - using cube_scene.tscn mesh.
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.2, 0.2, 0.2)
	
	# 3. Define the Grid shader material from cube_scene.tscn
	var material = create_grid_shader_material()
	box_mesh.surface_set_material(0, material)
	
	multimesh.mesh = box_mesh
	multi_mesh_instance.multimesh = multimesh
	add_child(multi_mesh_instance)
	
	# 4. Position each instance and store random colors.
	var instance_colors: Array[Color] = []
	for i in range(cube_count):
		# Generate a random position within a sphere.
		var position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf() * spread_radius
		
		# Create the transform for this instance.
		var transform = Transform3D(Basis(), position)
		multimesh.set_instance_transform(i, transform)
		
		# Store a random color for this instance (used for wireframe color variation)
		var random_color = Color.from_hsv(randf(), 0.85, 0.9)
		instance_colors.append(random_color)
		
		# Store a random rotation speed for the animation.
		var speed = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		rotation_speeds.append(speed)
	
	# Store colors for potential future use (Grid shader can't use per-instance colors directly)
	# The cubes will all have the same Grid shader appearance for performance
	print("VRCubes: Created %d cubes with Grid shader wireframe effect" % cube_count)

func _process(delta):
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var multimesh = multi_mesh_instance.multimesh
	var time_delta = delta * animation_speed
	
	# Animate each cube by updating its transform in the MultiMesh.
	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)
		var rotation_axis = rotation_speeds[i]
		
		# Store the original position
		var original_position = transform.origin
		
		# Apply rotation.
		transform = transform.rotated_local(rotation_axis, time_delta)
		
		# Apply very minimal scaling animation (just 0.005 scale change)
		var time = Time.get_time_dict_from_system()["second"]
		var scale_factor = 1.0 + sin(time * 1.0) * 0.005  # Very subtle scale change
		transform = transform.scaled(Vector3.ONE * scale_factor)
		
		# Restore the original position so cubes don't move
		transform.origin = original_position
		
		multimesh.set_instance_transform(i, transform)
