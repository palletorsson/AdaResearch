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

func setup_cubes():
	# Use a MultiMesh for performance, which is ideal for drawing
	# thousands of identical meshes.
	multi_mesh_instance = MultiMeshInstance3D.new()
	
	# 1. Create the MultiMesh resource.
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = cube_count
	
	# 2. Define the mesh that will be repeated.
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.2, 0.2, 0.2)
	
	# 3. Define the material for the mesh. We will set colors per-instance.
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	box_mesh.surface_set_material(0, material)
	
	multimesh.mesh = box_mesh
	multi_mesh_instance.multimesh = multimesh
	add_child(multi_mesh_instance)
	
	# 4. Position and color each instance.
	for i in range(cube_count):
		# Generate a random position within a sphere.
		var position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf() * spread_radius
		
		# Create the transform for this instance.
		var transform = Transform3D(Basis(), position)
		multimesh.set_instance_transform(i, transform)
		
		# Assign a random color to this instance.
		var random_color = Color.from_hsv(randf(), 0.85, 0.9)
		multimesh.set_instance_color(i, random_color)
		
		# Store a random rotation speed for the animation.
		var speed = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		rotation_speeds.append(speed)

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
