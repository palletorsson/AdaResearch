extends Node3D
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var spawn_position: Vector3 = Vector3(0, 1, 0)  # Default position on table (y=1)
@onready var base_cube = $woodCube  # Template cube 
var spawned_cubes: Array = []  # Track spawned cubes
var spawn_timer: float = 0.0  # Timer for spawning
var next_spawn_time: float = 1.0  # Initial spawn time target (1 second)
const MAX_CUBES: int = 20     # Maximum number of cubes allowed

# Sound related variables
@onready var wood_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D
var wood_stream: AudioStreamGeneratorPlayback
var wood_generator: AudioStreamGenerator
var sound_ready = false

func _ready():
	if not base_cube:
		push_error("Base cube not found!")
		return
	
	print("Starting cube spawner initialization")
	base_cube.visible = false  # Hide the template
	
	# Create and synthesize the wood sound
	create_wood_sound()

func create_wood_sound():
	# Create the generator stream
	wood_generator = AudioStreamGenerator.new()
	wood_generator.mix_rate = 44100  # CD quality
	wood_generator.buffer_length = 0.2  # 200ms buffer

	# Set the stream on the existing AudioStreamPlayer3D
	wood_sound.stream = wood_generator
	wood_sound.unit_size = 3.0
	wood_sound.max_distance = 10.0

	# Play the sound first to initialize the playback system
	wood_sound.play()

	# Wait a frame to ensure the playback is initialized
	await get_tree().process_frame

	# Now get the playback to fill with data
	wood_stream = wood_sound.get_stream_playback()

	# Check if we successfully got a playback
	if wood_stream:
		# Generate a wooden knock sound
		synthesize_wood_knock()
	else:
		push_error("Failed to get stream playback")

func synthesize_wood_knock():
	# Fill the buffer with a synthesized wooden knock sound
	var buffer_size = wood_stream.get_frames_available()
	
	# Parameters for wood knock sound
	var amplitude = 0.5
	var decay_rate = 15.0  # Higher value means faster decay
	var main_freq = 800.0  # Main resonant frequency
	var second_freq = 1200.0  # Secondary resonant frequency
	var noise_factor = 0.15  # Amount of noise to add
	
	# Fill the buffer with the synthesized sound
	for i in range(buffer_size):
		var time = float(i) / wood_generator.mix_rate
		
		# Exponential decay envelope
		var envelope = amplitude * exp(-decay_rate * time)
		
		# Main resonant frequency
		var main_wave = sin(TAU * main_freq * time)
		
		# Secondary frequency
		var second_wave = sin(TAU * second_freq * time)
		
		# Noise component (simulates wood texture)
		var noise = randf_range(-1.0, 1.0) * noise_factor
		
		# Combine components
		var sample = envelope * (main_wave * 0.6 + second_wave * 0.3 + noise)
		
		# Apply sample to both channels
		wood_stream.push_frame(Vector2(sample, sample))
	sound_ready = true

func play_wood_sound(at_position: Vector3):
	if sound_ready:
		# Instead of creating a new AudioStreamPlayer, let's reuse the existing one
		# This avoids potential initialization issues with the audio stream playback
		
		# Position the sound
		wood_sound.global_position = at_position
		
		# Random variations for more natural sound
		wood_sound.pitch_scale = randf_range(0.85, 1.15)
		
		# Generate a new wood knock sound
		if wood_stream:
			# Parameters with slight random variations
			var amplitude = randf_range(0.4, 0.6)
			var decay_rate = randf_range(14.0, 16.0)
			var main_freq = randf_range(750.0, 850.0)
			var second_freq = randf_range(1150.0, 1250.0)
			var noise_factor = randf_range(0.1, 0.2)
			
			# Fill the buffer with a synthesized wooden knock sound
			var buffer_size = wood_stream.get_frames_available()
			
			# Fill the buffer with the synthesized sound
			for i in range(buffer_size):
				var time = float(i) / wood_generator.mix_rate
				var envelope = amplitude * exp(-decay_rate * time)
				var main_wave = sin(TAU * main_freq * time)
				var second_wave = sin(TAU * second_freq * time)
				var noise = randf_range(-1.0, 1.0) * noise_factor
				var sample = envelope * (main_wave * 0.6 + second_wave * 0.3 + noise)
				wood_stream.push_frame(Vector2(sample, sample))
			
			# Play the sound
			if not wood_sound.playing:
				wood_sound.play()
		else:
			push_warning("Wood stream not available")
			
			# Try to reinitialize the sound
			create_wood_sound()

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:  # Spawn at randomized intervals
		spawn_timer = 0.0  # Reset timer
		
		# Set the next spawn time to be 1-2 seconds
		next_spawn_time = 0.3 + randf()  # 1.0 + random(0,1)
		
		if spawned_cubes.size() < MAX_CUBES:
			spawn_cube()  # Spawn a new cube
		else:
			remove_random_cube_and_spawn()  # Remove random cube, then spawn new one

func spawn_cube():
	var total_size = cube_size + gutter
	var new_cube = base_cube.duplicate()
	new_cube.position = spawn_position  # Fixed position on table
	new_cube.visible = true
	add_child(new_cube)
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	spawned_cubes.append(new_cube)
	#print("Spawned cube at:", spawn_position)
	
	# Play wood sound at the spawned cube position
	play_wood_sound(spawn_position)

func remove_random_cube_and_spawn():
	if spawned_cubes.size() > 0:
		# Remove a random cube
		var random_index = randi() % spawned_cubes.size()
		var cube_to_remove = spawned_cubes[random_index]
		var removed_position = cube_to_remove.position
		cube_to_remove.queue_free()
		spawned_cubes.remove_at(random_index)
		#print("Removed cube at index ", random_index)
		
		# Spawn a new cube in the same spot
		spawn_cube()

func exit_tree():
	# Clean up all spawned cubes when the node is removed
	for cube in spawned_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	spawned_cubes.clear()
