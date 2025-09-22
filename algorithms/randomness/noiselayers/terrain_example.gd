# TerrainExample.gd
# Example script demonstrating the optimized three-layer noise terrain system
# This script shows how to integrate the terrain with player movement and LOD

extends Node3D

@onready var terrain: NoiseLayers
@onready var player: CharacterBody3D
@onready var camera: Camera3D

# Terrain configuration
@export var auto_setup_terrain: bool = true
@export var terrain_size: int = 100
@export var terrain_scale: float = 2.0
@export var height_scale: float = 15.0

# Player movement settings
@export var player_speed: float = 5.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 20.0

# LOD settings
@export var enable_lod: bool = true
@export var lod_update_interval: float = 0.1  # Update LOD every 0.1 seconds

var velocity: Vector3 = Vector3.ZERO
var last_lod_update: float = 0.0

func _ready():
	"""Initialize the terrain example"""
	print("Initializing Terrain Example...")
	
	# Setup camera
	setup_camera()
	
	# Setup terrain
	if auto_setup_terrain:
		setup_terrain()
	
	# Setup player
	setup_player()
	
	print("Terrain Example initialized successfully!")

func setup_camera():
	"""Setup the camera for terrain viewing"""
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 20, 10)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)

func setup_terrain():
	"""Setup the optimized terrain system"""
	terrain = NoiseLayers.new()
	terrain.name = "OptimizedTerrain"
	
	# Configure terrain parameters
	terrain.terrain_size = terrain_size
	terrain.terrain_scale = terrain_scale
	terrain.height_scale = height_scale
	
	# Enable optimizations
	terrain.enable_lod = enable_lod
	terrain.enable_collision_optimization = true
	terrain.enable_erosion_simulation = true
	
	# Configure noise layers for better terrain
	terrain.low_freq_scale = 0.015
	terrain.low_freq_amplitude = 12.0
	terrain.med_freq_scale = 0.04
	terrain.med_freq_amplitude = 6.0
	terrain.high_freq_scale = 0.08
	terrain.high_freq_amplitude = 1.5
	
	# Configure walkable surfaces
	terrain.max_walkable_slope = 30.0
	terrain.slope_smoothing = 0.8
	
	add_child(terrain)
	
	# Wait for terrain to generate
	await get_tree().process_frame
	print("Terrain generated successfully!")

func setup_player():
	"""Setup a simple player character"""
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 10, 0)  # Start above terrain
	
	# Create player visual (simple capsule)
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.height = 2.0
	capsule_mesh.top_radius = 0.5
	capsule_mesh.bottom_radius = 0.5
	mesh_instance.mesh = capsule_mesh
	
	# Create player material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	mesh_instance.set_surface_override_material(0, material)
	
	player.add_child(mesh_instance)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.height = 2.0
	capsule_shape.radius = 0.5
	collision_shape.shape = capsule_shape
	player.add_child(collision_shape)
	
	add_child(player)
	
	# Make camera follow player
	camera.position = player.position + Vector3(0, 5, 5)
	camera.look_at(player.position, Vector3.UP)

func _process(delta):
	"""Main game loop"""
	if not terrain or not player:
		return
	
	# Handle player input
	handle_player_input(delta)
	
	# Update LOD system
	if enable_lod:
		update_lod_system(delta)
	
	# Update camera to follow player
	update_camera()

func handle_player_input(delta):
	"""Handle player movement input"""
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	
	# Convert to 3D movement
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Apply movement
	if direction != Vector3.ZERO:
		velocity.x = direction.x * player_speed
		velocity.z = direction.z * player_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_speed * delta)
		velocity.z = move_toward(velocity.z, 0, player_speed * delta)
	
	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		velocity.y = jump_velocity
	
	# Apply gravity
	if not player.is_on_floor():
		velocity.y -= gravity * delta
	
	# Move player
	player.velocity = velocity
	player.move_and_slide()
	
	# Check if player is on walkable surface
	if player.is_on_floor():
		var ground_position = player.position
		ground_position.y -= 1.0  # Check slightly below player
		
		if terrain.is_position_walkable(ground_position):
			# Player is on walkable terrain
			pass
		else:
			# Player is on non-walkable terrain (steep slope, etc.)
			# You could add sliding or other effects here
			pass

func update_lod_system(delta):
	"""Update LOD system based on player position"""
	last_lod_update += delta
	
	if last_lod_update >= lod_update_interval:
		# Update player position for LOD calculations
		terrain.set_player_position(player.position)
		last_lod_update = 0.0

func update_camera():
	"""Update camera to follow player"""
	var target_position = player.position + Vector3(0, 5, 5)
	var current_position = camera.position
	
	# Smooth camera movement
	camera.position = current_position.lerp(target_position, 0.1)
	camera.look_at(player.position, Vector3.UP)

func _input(event):
	"""Handle additional input events"""
	if event.is_action_pressed("ui_cancel"):
		# Regenerate terrain
		if terrain:
			print("Regenerating terrain...")
			terrain.regenerate_terrain()
	
	elif event.is_action_pressed("ui_select"):
		# Toggle LOD system
		if terrain:
			terrain.enable_lod = !terrain.enable_lod
			print("LOD system: %s" % ("Enabled" if terrain.enable_lod else "Disabled"))
	
	elif event.is_action_pressed("ui_home"):
		# Debug terrain information
		if terrain:
			terrain.debug_terrain_info()
			terrain.debug_show_walkable_areas()
			
			var lod_info = terrain.get_current_lod_info()
			print("Current LOD: %d, Resolution: %d, Vertices: %d" % [
				lod_info.level, 
				lod_info.resolution, 
				lod_info.vertex_count
			])

func _on_terrain_generation_complete():
	"""Called when terrain generation is complete"""
	print("Terrain generation complete!")
	
	# Position player on terrain
	if terrain:
		var player_height = terrain.get_terrain_height_at_position(player.position.x, player.position.z)
		player.position.y = player_height + 2.0  # Place player 2 units above terrain

# Utility functions for terrain interaction
func get_terrain_height_at_player() -> float:
	"""Get terrain height at player position"""
	if terrain:
		return terrain.get_terrain_height_at_position(player.position.x, player.position.z)
	return 0.0

func get_terrain_slope_at_player() -> float:
	"""Get terrain slope at player position"""
	if terrain:
		return terrain.get_terrain_slope_at_position(player.position.x, player.position.z)
	return 0.0

func is_player_on_walkable_terrain() -> bool:
	"""Check if player is on walkable terrain"""
	if terrain:
		var ground_position = player.position
		ground_position.y -= 1.0
		return terrain.is_position_walkable(ground_position)
	return false
