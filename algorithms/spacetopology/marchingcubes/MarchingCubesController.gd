# MarchingCubesController.gd
# Simplified controller for automatic marching cubes terrain generation
# Designed for VR visualization without desktop UI

extends Node3D

# Terrain generation
var terrain_generator: TerrainGenerator
var terrain_container: Node3D

# Parameters
var terrain_size: float = 15.0
var terrain_height: float = 8.0
var noise_frequency: float = 0.05
var generation_timer: float = 0.0
var generation_interval: float = 10.0  # Regenerate every 10 seconds

# Camera rotation for automatic viewing
var camera_rotation_speed: float = 0.2
var camera: Camera3D

func _ready():
	setup_terrain_generator()
	setup_camera()
	
	# Generate initial terrain
	call_deferred("generate_terrain_async")

func setup_terrain_generator():
	"""Initialize terrain generation system"""
	terrain_generator = TerrainGenerator.new()
	terrain_generator.generation_progress.connect(_on_generation_progress)
	terrain_generator.generation_complete.connect(_on_generation_complete)
	
	# Get terrain container
	terrain_container = $TerrainContainer
	
	print("MarchingCubes: Terrain generator initialized")

func setup_camera():
	"""Setup camera system"""
	camera = $Camera3D
	print("MarchingCubes: Camera initialized")

func _process(delta):
	# Rotate camera automatically for better viewing
	if camera:
		camera.rotate_y(camera_rotation_speed * delta)
	
	# Auto-regenerate terrain periodically
	generation_timer += delta
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		call_deferred("generate_terrain_async")

func generate_terrain_async():
	"""Generate terrain asynchronously"""
	if not terrain_generator or not terrain_container:
		return
	
	# Clear existing terrain
	for child in terrain_container.get_children():
		child.queue_free()
	
	# Configure parameters
	terrain_generator.terrain_size = Vector2(terrain_size, terrain_size)
	terrain_generator.terrain_height = terrain_height
	terrain_generator.noise_frequency = noise_frequency
	
	# Start generation and get meshes
	var terrain_meshes = await terrain_generator.generate_terrain_async()
	
	# Add all generated meshes to the container
	for mesh in terrain_meshes:
		if mesh is MeshInstance3D:
			terrain_container.add_child(mesh)

func _on_generation_progress(progress: float):
	"""Handle generation progress updates"""
	# Could add visual feedback here if needed
	pass

func _on_generation_complete():
	"""Handle generation completion"""
	print("MarchingCubes: Terrain generation complete")
	
	# Randomize parameters for variety
	terrain_size = randf_range(10.0, 20.0)
	terrain_height = randf_range(5.0, 12.0)
	noise_frequency = randf_range(0.03, 0.08)
