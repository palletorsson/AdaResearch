extends Node3D
class_name NoiseBlobSpawner

# Spawning parameters
@export var blob_count: int = 25
@export var spawn_radius: float = 40.0
@export var height_offset: float = 2.0
@export var auto_spawn: bool = true
@export var spawn_interval: float = 2.0
@export var max_blobs: int = 50

# Blob movement parameters
@export var blob_speed: float = 1.5
@export var wander_strength: float = 0.3
@export var follow_terrain: bool = true
@export var float_height: float = 1.5

# Visual parameters
@export var blob_size_min: float = 0.5
@export var blob_size_max: float = 2.0
@export var blob_colors: Array[Color] = [
	Color(0.2, 0.8, 1.0, 0.7),  # Cyan
	Color(1.0, 0.5, 0.8, 0.7),  # Pink
	Color(0.5, 1.0, 0.3, 0.7),  # Green
	Color(1.0, 0.8, 0.2, 0.7),  # Yellow
	Color(0.8, 0.3, 1.0, 0.7)   # Purple
]

# Internal variables
var terrain_reference: QueerNoiseTerrain
var blobs: Array[NoiseBlobInstance] = []
var spawn_timer: float = 0.0
var blob_material: ShaderMaterial
var time_elapsed: float = 0.0

# Blob mesh
var blob_mesh: SphereMesh

class NoiseBlobInstance:
	var mesh_instance: MeshInstance3D
	var position: Vector3
	var velocity: Vector3
	var size: float
	var birth_time: float
	var lifetime: float
	var wander_phase: Vector3
	var target_height: float
	
	func _init(mesh_inst: MeshInstance3D, pos: Vector3, vel: Vector3, blob_size: float, time: float):
		mesh_instance = mesh_inst
		position = pos
		velocity = vel
		size = blob_size
		birth_time = time
		lifetime = randf_range(10.0, 25.0)  # Random lifetime between 10-25 seconds
		wander_phase = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		target_height = pos.y

func _ready():
	setup_blob_system()
	find_terrain_reference()
	if auto_spawn:
		spawn_initial_blobs()

func _process(delta):
	time_elapsed += delta
	
	if auto_spawn:
		spawn_timer += delta
		if spawn_timer >= spawn_interval and blobs.size() < max_blobs:
			spawn_timer = 0.0
			spawn_single_blob()
	
	update_blobs(delta)
	cleanup_old_blobs()

func setup_blob_system():
	# Create blob mesh
	blob_mesh = SphereMesh.new()
	blob_mesh.radius = 1.0
	blob_mesh.height = 2.0
	blob_mesh.rings = 16
	blob_mesh.radial_segments = 32
	
	# Load and setup shader material
	var shader = load("res://algorithms/randomness/noiseterrain/noise_blob_shader.gdshader")
	if shader == null:
		print("ERROR: Could not load noise blob shader!")
		return
	
	blob_material = ShaderMaterial.new()
	blob_material.shader = shader
	
	# Set default shader parameters
	blob_material.set_shader_parameter("time_scale", 1.0)
	blob_material.set_shader_parameter("blob_speed", blob_speed)
	blob_material.set_shader_parameter("blob_intensity", 1.0)
	blob_material.set_shader_parameter("noise_scale", 2.0)
	blob_material.set_shader_parameter("noise_strength", 0.5)
	blob_material.set_shader_parameter("noise_octaves", 4)
	blob_material.set_shader_parameter("base_size", 1.0)
	blob_material.set_shader_parameter("size_variation", 0.3)
	blob_material.set_shader_parameter("morph_speed", 2.0)
	blob_material.set_shader_parameter("color_shift_speed", 1.0)
	
	print("Blob system setup complete!")

func find_terrain_reference():
	# Look for terrain in parent or sibling nodes
	var parent = get_parent()
	if parent is QueerNoiseTerrain:
		terrain_reference = parent
		print("Found terrain reference in parent")
		return
	
	# Look in siblings
	if parent:
		for child in parent.get_children():
			if child is QueerNoiseTerrain:
				terrain_reference = child
				print("Found terrain reference in sibling")
				return
	
	# Look globally
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_reference = terrain_nodes[0]
		print("Found terrain reference globally")
	else:
		print("WARNING: No terrain reference found!")

func spawn_initial_blobs():
	print("Spawning ", blob_count, " initial blobs...")
	for i in range(blob_count):
		spawn_single_blob()

func spawn_single_blob():
	# Generate random spawn position within radius
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var spawn_pos = Vector3(
		cos(angle) * distance,
		0.0,  # Will be adjusted to terrain height
		sin(angle) * distance
	)
	
	# Adjust height to terrain if available
	if terrain_reference:
		spawn_pos.y = terrain_reference.get_height_at_world_position(spawn_pos) + height_offset
	else:
		spawn_pos.y = height_offset
	
	# Create blob mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = blob_mesh
	
	# Create unique material for this blob
	var blob_mat = blob_material.duplicate()
	var color_index = randi() % blob_colors.size()
	blob_mat.set_shader_parameter("blob_color", blob_colors[color_index])
	
	# Randomize some shader parameters for variety
	blob_mat.set_shader_parameter("base_size", randf_range(blob_size_min, blob_size_max))
	blob_mat.set_shader_parameter("morph_speed", randf_range(1.0, 3.0))
	blob_mat.set_shader_parameter("color_shift_speed", randf_range(0.5, 2.0))
	blob_mat.set_shader_parameter("noise_scale", randf_range(1.5, 3.0))
	
	mesh_instance.material_override = blob_mat
	mesh_instance.position = spawn_pos
	
	add_child(mesh_instance)
	
	# Create blob instance data
	var velocity = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized() * blob_speed * randf_range(0.5, 1.5)
	
	var blob_instance = NoiseBlobInstance.new(
		mesh_instance,
		spawn_pos,
		velocity,
		randf_range(blob_size_min, blob_size_max),
		time_elapsed
	)
	
	blobs.append(blob_instance)
	print("Spawned blob at position: ", spawn_pos)

func update_blobs(delta: float):
	for blob in blobs:
		if not is_instance_valid(blob.mesh_instance):
			continue
		
		# Update wander behavior
		blob.wander_phase += Vector3(delta, delta * 1.3, delta * 0.7)
		var wander_force = Vector3(
			sin(blob.wander_phase.x) * wander_strength,
			0.0,
			cos(blob.wander_phase.z) * wander_strength
		)
		
		# Apply movement
		blob.velocity += wander_force * delta
		blob.velocity = blob.velocity.normalized() * blob_speed
		blob.position += blob.velocity * delta
		
		# Follow terrain height if enabled
		if follow_terrain and terrain_reference:
			blob.target_height = terrain_reference.get_height_at_world_position(blob.position) + float_height
			# Smooth height adjustment
			blob.position.y = lerp(blob.position.y, blob.target_height, delta * 2.0)
		
		# Update mesh position
		blob.mesh_instance.position = blob.position
		
		# Add some rotation for visual interest
		blob.mesh_instance.rotation.y += delta * 0.5
		blob.mesh_instance.rotation.x = sin(time_elapsed + blob.birth_time) * 0.1

func cleanup_old_blobs():
	var blobs_to_remove = []
	
	for i in range(blobs.size() - 1, -1, -1):
		var blob = blobs[i]
		var age = time_elapsed - blob.birth_time
		
		# Remove old blobs or blobs that have wandered too far
		var distance_from_origin = blob.position.length()
		if age > blob.lifetime or distance_from_origin > spawn_radius * 2.0:
			if is_instance_valid(blob.mesh_instance):
				blob.mesh_instance.queue_free()
			blobs.remove_at(i)
			print("Removed old blob")

# Public API functions
func spawn_blob_at_position(pos: Vector3):
	"""Spawn a blob at a specific position"""
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = blob_mesh
	
	var blob_mat = blob_material.duplicate()
	var color_index = randi() % blob_colors.size()
	blob_mat.set_shader_parameter("blob_color", blob_colors[color_index])
	blob_mat.set_shader_parameter("base_size", randf_range(blob_size_min, blob_size_max))
	
	mesh_instance.material_override = blob_mat
	mesh_instance.position = pos
	add_child(mesh_instance)
	
	var velocity = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized() * blob_speed
	
	var blob_instance = NoiseBlobInstance.new(
		mesh_instance,
		pos,
		velocity,
		randf_range(blob_size_min, blob_size_max),
		time_elapsed
	)
	
	blobs.append(blob_instance)

func clear_all_blobs():
	"""Remove all blobs"""
	for blob in blobs:
		if is_instance_valid(blob.mesh_instance):
			blob.mesh_instance.queue_free()
	blobs.clear()
	print("Cleared all blobs")

func set_blob_parameters(params: Dictionary):
	"""Update blob parameters dynamically"""
	if params.has("blob_count"):
		blob_count = params.blob_count
	if params.has("blob_speed"):
		blob_speed = params.blob_speed
	if params.has("spawn_radius"):
		spawn_radius = params.spawn_radius
	if params.has("float_height"):
		float_height = params.float_height

func get_blob_stats() -> Dictionary:
	"""Get current blob statistics"""
	return {
		"active_blobs": blobs.size(),
		"max_blobs": max_blobs,
		"spawn_radius": spawn_radius,
		"average_age": get_average_blob_age()
	}

func get_average_blob_age() -> float:
	if blobs.size() == 0:
		return 0.0
	
	var total_age = 0.0
	for blob in blobs:
		total_age += time_elapsed - blob.birth_time
	
	return total_age / blobs.size()

# Debug functions
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_B:
				spawn_single_blob()
				print("Spawned debug blob")
			KEY_V:
				clear_all_blobs()
				print("Cleared all blobs")
			KEY_N:
				print("Blob stats: ", get_blob_stats())

