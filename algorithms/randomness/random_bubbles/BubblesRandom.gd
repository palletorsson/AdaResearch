extends Node3D

# Bubble particle properties
@export var spawn_area_size: Vector3 = Vector3(6, 1.0, 6)  # Size of the area where bubbles spawn (matches smaller petri dish)
@export var min_bubble_size: float = 0.2
@export var max_bubble_size: float = 0.8
@export var min_rise_speed: float = 0.5
@export var max_rise_speed: float = 2.0
@export var max_bubble_count: int = 200
@export var spawn_rate: float = 2.0  # Bubbles per second
@export var bubble_lifetime: float = 10.0  # How long bubbles exist before fading out
@export var bubble_fade_time: float = 2.0  # Time it takes for a bubble to fade out
@export var bubble_scale_down_rate: float = 0.05  # How quickly bubbles shrink as they rise

# Petri dish properties
@export var petri_dish_radius: float = 3.5  # Radius of the petri dish (smaller)
@export var petri_dish_height: float = 0.25  # Height of the petri dish walls
@export var petri_dish_thickness: float = 0.04  # Wall thickness
@export var petri_dish_color: Color = Color(1.0, 0.7, 0.9, 0.4)  # Pink glass transparency

# Sound properties
@export var use_synthesized_sounds: bool = true
@export var sound_variations: int = 5  # Number of different bubble sounds to generate
@export var min_pitch_scale: float = 0.8
@export var max_pitch_scale: float = 1.5
@export var min_volume_db: float = -15.0
@export var max_volume_db: float = -5.0
@export var max_concurrent_sounds: int = 4  # Limit number of concurrent sounds
@export var sound_play_chance: float = 0.3  # Chance to play a sound for each bubble (0-1)

# Pre-recorded sounds (alternative to synthesis)
@export var bubble_sounds: Array[AudioStream] = []

# Internal properties
var bubble_timer: float = 0.0
var active_bubbles = []
var active_audio_players = []
var audio_player_pool = []
var synthesized_sounds: Array = []
var petri_dish_container: Node3D
#var sound_synthesizer: BubbleSoundSynthesizer

# Bubble class to track properties of each bubble
class Bubble:
	var mesh_instance: MeshInstance3D
	var rise_speed: float
	var age: float = 0.0
	var initial_scale: float
	var horizontal_drift: Vector2
	var wobble_amount: float
	var wobble_speed: float
	var material: StandardMaterial3D
	
	func _init(p_mesh_instance, p_rise_speed, p_initial_scale, p_wobble_amount, p_wobble_speed):
		mesh_instance = p_mesh_instance
		rise_speed = p_rise_speed
		initial_scale = p_initial_scale
		wobble_amount = p_wobble_amount
		wobble_speed = p_wobble_speed
		horizontal_drift = Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		
		# Set up the transparent material
		material = StandardMaterial3D.new()
		material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.7, 0.9, 0.3)  # Light pink, transparent
		material.emission = Color(0.8, 0.3, 0.5, 0.1)  # Slight pink glow
		material.roughness = 0.1
		material.metallic = 0.2
		material.metallic_specular = 1.0
		mesh_instance.set_surface_override_material(0, material)

func _ready():
	# Create the petri dish
	create_petri_dish()
	
	# Create the sound synthesizer
	#if use_synthesized_sounds:
		#sound_synthesizer = BubbleSoundSynthesizer.new()
		#add_child(sound_synthesizer)
		
		# Generate a set of bubble sounds with different properties
		#synthesized_sounds = sound_synthesizer.generate_bubble_sound_set(sound_variations)
	
	# Pre-create a pool of audio players
	#for i in range(max_concurrent_sounds):
		#var audio_player = AudioStreamPlayer3D.new()
		#audio_player.max_distance = 20.0
		#audio_player.unit_size = 2.0
		#audio_player.finished.connect(_on_audio_finished.bind(audio_player))
		#add_child(audio_player)
		#audio_player_pool.append(audio_player)

func _process(delta):
	# Spawn new bubbles
	bubble_timer += delta
	if bubble_timer >= 1.0 / spawn_rate and active_bubbles.size() < max_bubble_count:
		spawn_bubble()
		bubble_timer = 0.0
	
	# Update existing bubbles
	var i = 0
	while i < active_bubbles.size():
		var bubble = active_bubbles[i]
		bubble.age += delta
		
		if bubble.age >= bubble_lifetime:
			# Remove and free the bubble
			bubble.mesh_instance.queue_free()
			active_bubbles.remove_at(i)
			continue
		
		# Move the bubble upward
		var pos = bubble.mesh_instance.position
		pos.y += bubble.rise_speed * delta
		
		# Add horizontal drift
		pos.x += bubble.horizontal_drift.x * delta
		pos.z += bubble.horizontal_drift.y * delta
		
		# Add wobble motion
		var wobble_x = sin(bubble.age * bubble.wobble_speed) * bubble.wobble_amount
		var wobble_z = cos(bubble.age * bubble.wobble_speed * 0.7) * bubble.wobble_amount
		pos.x += wobble_x * delta
		pos.z += wobble_z * delta
		
		bubble.mesh_instance.position = pos
		
		# Scale down as the bubble rises
		var current_scale = bubble.initial_scale * (1.0 - (bubble.age / bubble_lifetime) * bubble_scale_down_rate)
		bubble.mesh_instance.scale = Vector3(current_scale, current_scale, current_scale)
		
		# Fade out when near the end of lifetime
		if bubble.age > (bubble_lifetime - bubble_fade_time):
			var alpha = 0.3 * (1.0 - (bubble.age - (bubble_lifetime - bubble_fade_time)) / bubble_fade_time)
			bubble.material.albedo_color.a = alpha
		
		i += 1

func create_petri_dish():
	"""Create a realistic petri dish with glass-like appearance"""
	petri_dish_container = Node3D.new()
	petri_dish_container.name = "PetriDish"
	add_child(petri_dish_container)
	
	# Create glass material for the petri dish
	var glass_material = StandardMaterial3D.new()
	glass_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = petri_dish_color
	glass_material.roughness = 0.05  # Very smooth for glass
	glass_material.metallic = 0.0
	glass_material.refraction_enabled = true
	glass_material.refraction_scale = 0.05
	glass_material.rim_enabled = true
	glass_material.rim = 0.9
	glass_material.rim_color = Color(1.0, 0.8, 0.95, 0.7)  # Pink-tinted rim
	
	# Create the bottom plate (main circular base)
	var bottom_cylinder = CylinderMesh.new()
	bottom_cylinder.top_radius = petri_dish_radius
	bottom_cylinder.bottom_radius = petri_dish_radius
	bottom_cylinder.height = petri_dish_thickness
	
	var bottom_instance = MeshInstance3D.new()
	bottom_instance.mesh = bottom_cylinder
	bottom_instance.set_surface_override_material(0, glass_material)
	bottom_instance.position = Vector3(0, -petri_dish_thickness/2, 0)
	bottom_instance.name = "PetriDishBottom"
	petri_dish_container.add_child(bottom_instance)
	
	# Create the side walls (outer ring)
	var wall_cylinder = CylinderMesh.new()
	wall_cylinder.top_radius = petri_dish_radius
	wall_cylinder.bottom_radius = petri_dish_radius
	wall_cylinder.height = petri_dish_height
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_cylinder
	wall_instance.set_surface_override_material(0, glass_material)
	wall_instance.position = Vector3(0, petri_dish_height/2, 0)
	wall_instance.name = "PetriDishWalls"
	petri_dish_container.add_child(wall_instance)
	
	# Create inner walls (to make it look hollow)
	var inner_wall_cylinder = CylinderMesh.new()
	inner_wall_cylinder.top_radius = petri_dish_radius - petri_dish_thickness
	inner_wall_cylinder.bottom_radius = petri_dish_radius - petri_dish_thickness
	inner_wall_cylinder.height = petri_dish_height - petri_dish_thickness
	
	var inner_wall_instance = MeshInstance3D.new()
	inner_wall_instance.mesh = inner_wall_cylinder
	# Create inverted material for inner walls
	var inner_material = glass_material.duplicate()
	inner_material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render from inside
	inner_wall_instance.set_surface_override_material(0, inner_material)
	inner_wall_instance.position = Vector3(0, (petri_dish_height - petri_dish_thickness)/2, 0)
	inner_wall_instance.name = "PetriDishInnerWalls"
	petri_dish_container.add_child(inner_wall_instance)
	
	# Add some subtle lighting enhancement around the dish
	var area_light = OmniLight3D.new()
	area_light.light_energy = 0.4
	area_light.light_color = Color(1.0, 0.85, 0.95)  # Pink-tinted light
	area_light.omni_range = petri_dish_radius * 2.5
	area_light.position = Vector3(0, petri_dish_height + 0.8, 0)
	area_light.name = "PetriDishLight"
	petri_dish_container.add_child(area_light)
	
	print("BubblesRandom: Created petri dish with radius %.1f and height %.1f" % [petri_dish_radius, petri_dish_height])

func spawn_bubble():
	# Create a random position within the spawn area
	var pos = Vector3(
		randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
		randf_range(-spawn_area_size.y/2, spawn_area_size.y/2),
		randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
	)
	
	# Create a sphere mesh (optimized for many bubbles)
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8  # Reduced polygon count for better performance
	sphere.rings = 4           # Reduced polygon count for better performance
	
	# Create mesh instance and add to scene
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	mesh_instance.position = pos
	
	# Random properties
	var initial_scale = randf_range(min_bubble_size, max_bubble_size)
	mesh_instance.scale = Vector3(initial_scale, initial_scale, initial_scale)
	
	var rise_speed = randf_range(min_rise_speed, max_rise_speed)
	var wobble_amount = randf_range(0.05, 0.25)
	var wobble_speed = randf_range(1.0, 3.0)
	
	# Create and track the bubble
	var bubble = Bubble.new(mesh_instance, rise_speed, initial_scale, wobble_amount, wobble_speed)
	active_bubbles.append(bubble)
	
	# Play bubble sound effect
	play_bubble_sound(pos, initial_scale)

func play_bubble_sound(position: Vector3, bubble_size: float):
	# Determine normalized bubble size (0-1)
	var size_factor = (bubble_size - min_bubble_size) / (max_bubble_size - min_bubble_size)
	
	# Only play sound occasionally to avoid too many sound effects
	if randf() > sound_play_chance or audio_player_pool.size() == 0:
		return
	
	# Check if we have any sounds to play
	var available_sounds = use_synthesized_sounds if  synthesized_sounds else bubble_sounds
	if available_sounds:
		return
		
	# Get an available audio player from the pool
	var audio_player = audio_player_pool.pop_back()
	active_audio_players.append(audio_player)
	
	# Set the audio player's position to match the bubble
	audio_player.position = position
	
	# Choose a sound based on bubble size
	var sound_index
	if use_synthesized_sounds:
		# For synthesized sounds, we have a range from small to large
		sound_index = int(size_factor * (available_sounds.size() - 1))
	else:
		# For pre-recorded sounds, choose randomly
		sound_index = randi() % available_sounds.size()
	
	# Apply a small random variation to index to add variety
	sound_index = clamp(sound_index + randi() % 3 - 1, 0, available_sounds.size() - 1)
	audio_player.stream = available_sounds[sound_index]
	
	# Scale pitch and volume based on bubble size
	# Smaller bubbles = higher pitch, quieter
	audio_player.pitch_scale = lerp(max_pitch_scale, min_pitch_scale, size_factor)
	audio_player.volume_db = lerp(min_volume_db, max_volume_db, size_factor)
	
	# Add a slight randomization to pitch for variety
	audio_player.pitch_scale *= randf_range(0.95, 1.05)
	
	# Play the sound
	audio_player.play()

func _on_audio_finished(audio_player):
	# Return the audio player to the pool when finished
	if active_audio_players.has(audio_player):
		active_audio_players.erase(audio_player)
		audio_player_pool.append(audio_player)
