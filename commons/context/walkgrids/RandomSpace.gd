# RandomSpace.gd - Animated chaos optimized for VR
extends TopologySpace
class_name RandomSpace

@export var chaos_level: float = 2.0
@export var seed_value: int = 12345

# Animation properties
@export var enable_animation: bool = true
@export var animation_speed: float = 1.0
@export var animation_amplitude: float = 0.5
@export var animation_frequency: float = 0.1
@export var animation_type: AnimationType = AnimationType.WAVE

# VR Performance optimization
@export var update_frequency: float = 30.0  # Updates per second
@export var collision_update_interval: float = 0.5  # Collision update interval in seconds
@export var enable_lod: bool = true
@export var lod_distance: float = 50.0

enum AnimationType {
	WAVE,
	RIPPLE,
	RANDOM_WALK,
	PERLIN_NOISE,
	CHAOTIC
}

# Internal variables
var base_heights: Array = []
var current_heights: Array = []
var animation_time: float = 0.0
var update_timer: float = 0.0
var collision_timer: float = 0.0
var rng: RandomNumberGenerator
var noise: FastNoiseLite
var player_node: Node3D
var last_player_distance: float = 0.0

func _ready():
	super._ready()
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_find_player()
	_generate_base_heights()

func _find_player():
	# Find player for LOD calculations
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		player_node = get_tree().get_first_node_in_group("vr_player")

func _generate_base_heights():
	"""Generate the base height map that will be animated"""
	# Ensure RNG is initialized
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.seed = seed_value
	
	base_heights.clear()
	current_heights.clear()
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			# Pure randomness - mathematical anarchy
			var height = rng.randf_range(-chaos_level, chaos_level)
			base_heights.append(height * height_scale)
			current_heights.append(height * height_scale)

func generate_space():
	"""Generate the initial space"""
	_generate_base_heights()
	_update_mesh()
	_update_collision()
	_setup_material()

func _setup_material():
	"""Setup the material for the space"""
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.LIGHT_PINK
	material.roughness = 0.1
	material.metallic = 1.0
	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return
	
	animation_time += delta * animation_speed
	update_timer += delta
	collision_timer += delta
	
	# Update mesh at specified frequency for performance
	if update_timer >= 1.0 / update_frequency:
		_update_mesh()
		update_timer = 0.0
	
	# Update collision less frequently to reduce CPU load
	if collision_timer >= collision_update_interval:
		_update_collision()
		collision_timer = 0.0

func _update_mesh():
	"""Update the mesh with animated heights"""
	if not enable_animation or base_heights.is_empty():
		return
	
	# Calculate LOD factor if enabled
	var lod_factor = 1.0
	if enable_lod and player_node:
		var distance = global_position.distance_to(player_node.global_position)
		lod_factor = clamp(1.0 - (distance / lod_distance), 0.1, 1.0)
	
	# Update heights based on animation type
	_animate_heights(lod_factor)
	
	# Create and apply new mesh
	var mesh = create_mesh_from_heights(current_heights)
	mesh_instance.mesh = mesh

func _animate_heights(lod_factor: float = 1.0):
	"""Animate the heights based on the selected animation type"""
	var effective_amplitude = animation_amplitude * lod_factor
	
	match animation_type:
		AnimationType.WAVE:
			_animate_wave(effective_amplitude)
		AnimationType.RIPPLE:
			_animate_ripple(effective_amplitude)
		AnimationType.RANDOM_WALK:
			_animate_random_walk(effective_amplitude)
		AnimationType.PERLIN_NOISE:
			_animate_perlin_noise(effective_amplitude)
		AnimationType.CHAOTIC:
			_animate_chaotic(effective_amplitude)

func _animate_wave(amplitude: float):
	"""Wave animation - smooth waves across the surface"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var wave_x = sin(animation_time * animation_frequency + x * 0.1) * amplitude
			var wave_z = cos(animation_time * animation_frequency + z * 0.1) * amplitude
			current_heights[index] = base_heights[index] + (wave_x + wave_z) * 0.5

func _animate_ripple(amplitude: float):
	"""Ripple animation - expanding ripples from center"""
	var center_x = resolution / 2.0
	var center_z = resolution / 2.0
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var distance = sqrt(pow(x - center_x, 2) + pow(z - center_z, 2))
			var ripple = sin(distance * 0.5 - animation_time * animation_frequency * 2.0) * amplitude
			current_heights[index] = base_heights[index] + ripple

func _animate_random_walk(amplitude: float):
	"""Random walk animation - chaotic but smooth movement"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var noise_x = sin(animation_time * animation_frequency + x * 0.3) * 0.5
			var noise_z = cos(animation_time * animation_frequency + z * 0.3) * 0.5
			var walk = (noise_x + noise_z) * amplitude
			current_heights[index] = base_heights[index] + walk

func _animate_perlin_noise(amplitude: float):
	"""Perlin noise animation - natural-looking terrain movement"""
	# Ensure noise is initialized
	if not noise:
		noise = FastNoiseLite.new()
		noise.seed = seed_value
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var noise_x = x * 0.1 + animation_time * animation_frequency
			var noise_z = z * 0.1 + animation_time * animation_frequency
			var noise_value = noise.get_noise_2d(noise_x, noise_z) * amplitude
			current_heights[index] = base_heights[index] + noise_value

func _animate_chaotic(amplitude: float):
	"""Chaotic animation - pure mathematical chaos"""
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var index = z * (resolution + 1) + x
			var chaos_x = sin(animation_time * animation_frequency * 3.0 + x * 0.2) * 0.5
			var chaos_z = cos(animation_time * animation_frequency * 2.0 + z * 0.2) * 0.5
			var chaos_combined = sin(chaos_x + chaos_z + animation_time) * amplitude
			current_heights[index] = base_heights[index] + chaos_combined

func _update_collision():
	"""Update collision shape - called less frequently for performance"""
	if mesh_instance.mesh:
		# Use convex collision for better VR performance
		create_collision_single_convex(mesh_instance.mesh)

# Public API for external control
func set_animation_type(new_type: AnimationType):
	animation_type = new_type
	print("RandomSpace: Animation type set to ", AnimationType.keys()[new_type])

func set_animation_speed(speed: float):
	animation_speed = speed
	print("RandomSpace: Animation speed set to ", speed)

func set_animation_amplitude(amp: float):
	animation_amplitude = amp
	print("RandomSpace: Animation amplitude set to ", amp)

func toggle_animation():
	enable_animation = !enable_animation
	print("RandomSpace: Animation ", "enabled" if enable_animation else "disabled")

func reset_animation():
	"""Reset animation to base state"""
	animation_time = 0.0
	current_heights = base_heights.duplicate()
	_update_mesh()
	_update_collision()
	print("RandomSpace: Animation reset")

func get_animation_info() -> Dictionary:
	"""Get current animation state information"""
	return {
		"enabled": enable_animation,
		"type": AnimationType.keys()[animation_type],
		"speed": animation_speed,
		"amplitude": animation_amplitude,
		"frequency": animation_frequency,
		"time": animation_time,
		"update_frequency": update_frequency,
		"collision_interval": collision_update_interval,
		"lod_enabled": enable_lod
	}
