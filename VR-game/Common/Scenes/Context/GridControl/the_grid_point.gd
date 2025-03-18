extends Node3D
@export var grid_spacing: float = 0.2  # Distance between grid points
@onready var player = $"../../XROrigin3D" # Reference to the player
@onready var PlainGrid = $PlanGrid  # Reference to the plane grid

# Sound related variables
@onready var audio_player = $AudioStreamPlayer3D
@onready var drone_player = $DroneAudioPlayer3D
var synth_sound_generator: AudioStreamGenerator
var synth_playback: AudioStreamGeneratorPlayback
var drone_generator: AudioStreamGenerator
var drone_playback: AudioStreamGeneratorPlayback
var previously_colored_pixels = {}  # To track pixels we've already colored
var drone_playing = false

# Grid related variables
var drawing_texture: Image
var drawing_texture_data: ImageTexture
var player_start_position: Vector3
var texture_size_x: int = 11
var texture_size_y: int = 21
var last_grid_x = -1
var last_grid_y = -1

# Heat map tracking
var grid_point_visit_count = {}  # Dictionary to track visit counts for heat map

# Sound synthesis parameters
var sample_hz = 44100.0
var pulse_hz = 440.0
var phase = 0.0
var sound_duration = 0.3  # longer for eerie effect

# Drone parameters
var drone_phase = 0.0
var drone_base_freq = 110.0 # Deep base frequency for the drone

func _ready():
	# Store the player's initial position
	player_start_position = player.global_transform.origin
	
	# Initialize grid texture
	create_grid_texture(texture_size_x, texture_size_y)
	
	# Initialize sound generation
	setup_audio()
	
	# Set the visualization to start at player's initial position
	var initial_snapped_pos = snap_to_grid(player_start_position, grid_spacing)
	update_grid_texture(Vector3.ZERO) # Start with center point
	
	# Start the background drone
	start_drone()

func _process(delta):
	# Snap the player to the nearest grid point based on their position
	var player_pos = player.global_transform.origin
	var snapped_pos = snap_to_grid(player_pos, grid_spacing)
	
	# Update grid texture to highlight player position
	update_grid_texture(snapped_pos)
	
	# Keep the drone going
	update_drone(delta)

func setup_audio():
	# Create audio player if it doesn't exist
	if !has_node("AudioStreamPlayer3D"):
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioStreamPlayer3D"
		add_child(audio_player)
	
	# Setup generator stream
	synth_sound_generator = AudioStreamGenerator.new()
	synth_sound_generator.mix_rate = sample_hz
	synth_sound_generator.buffer_length = 0.5  # 500ms buffer for longer sounds
	
	# Assign to player and get playback
	audio_player.stream = synth_sound_generator
	audio_player.volume_db = -4.0  # Slightly louder for the effect
	audio_player.max_distance = 20.0  # Longer distance for eerie presence
	audio_player.attenuation_filter_cutoff_hz = 5000.0  # Filter high frequencies at distance
	audio_player.attenuation_filter_db = 10.0  # More filter effect
	audio_player.play()
	synth_playback = audio_player.get_stream_playback()
	
	# Setup drone audio player
	if !has_node("DroneAudioPlayer3D"):
		drone_player = AudioStreamPlayer3D.new()
		drone_player.name = "DroneAudioPlayer3D"
		add_child(drone_player)
	
	# Setup drone generator stream
	drone_generator = AudioStreamGenerator.new()
	drone_generator.mix_rate = sample_hz
	drone_generator.buffer_length = 1.0  # 1 second buffer for continuous drone
	
	# Assign to drone player and get playback
	drone_player.stream = drone_generator
	drone_player.volume_db = 1.0  # Lower volume for background
	drone_player.max_distance = 40.0  # Longer distance for ambient presence
	drone_player.attenuation_filter_cutoff_hz = 2000.0  # Filter high frequencies
	drone_player.attenuation_filter_db = 6.0  # Less filtering than main sounds
	drone_player.play()
	drone_playback = drone_player.get_stream_playback()

func update_drone(delta):
	# Make sure the drone is continuously playing
	if drone_playback.get_frames_available() > 0:
		generate_drone_audio()

func start_drone():
	# Initialize the drone
	drone_playing = true
	generate_drone_audio()

func generate_drone_audio():
	# Fill as many frames as are available in the buffer
	var frames_available = drone_playback.get_frames_available()
	var increment = 1.0 / sample_hz
	
	if frames_available > 0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		
		# Determine how many colored grid points we have - affects drone complexity
		var colored_points = previously_colored_pixels.size()
		
		# Let's fill the buffer with our drone sound
		for i in range(frames_available):
			# Time keeps advancing for continuous sound
			drone_phase += increment
			var time = drone_phase
			
			# Create a deep drone base - sine wave at low frequency
			var drone_sample = sin(time * drone_base_freq * 2.0 * PI) * 0.3
			
			# Add a subtle fifth overtone for richness
			drone_sample += sin(time * drone_base_freq * 1.5 * 2.0 * PI) * 0.1
			
			# Add some very subtle harmonics
			drone_sample += sin(time * drone_base_freq * 2.0 * 2.0 * PI) * 0.05
			drone_sample += sin(time * drone_base_freq * 3.0 * 2.0 * PI) * 0.02
			
			# Add slow LFO modulation
			drone_sample *= 1.0 + 0.1 * sin(time * 0.2 * 2.0 * PI)
			
			# As more grid points are colored, add more digital artifacts to the drone
			if colored_points > 0:
				# The more points colored, the more digital the drone becomes
				var digital_amount = min(colored_points / 20.0, 0.7) # Cap at 70% digital
				
				# Digital artifacts increase with more colored points
				if colored_points > 5 and rng.randf() < 0.01 * digital_amount:
					drone_sample *= rng.randf_range(0.7, 1.2) # Occasional volume fluctuations
				
				# Add digital noise proportional to colored points
				drone_sample += (rng.randf() * 2.0 - 1.0) * 0.02 * digital_amount
				
				# Add slight bit-crushing effect proportional to colored points
				var crush_rate = max(8, 32 - colored_points)
				drone_sample = floor(drone_sample * crush_rate) / crush_rate
			
			# Very subtle stereo effect
			var stereo_offset = sin(time * 0.3) * 0.02
			drone_playback.push_frame(Vector2(drone_sample - stereo_offset, drone_sample + stereo_offset))

func snap_to_grid(play_position: Vector3, spacing: float) -> Vector3:
	# Snap position to grid
	var snapped_x = round(play_position.x / spacing) * spacing
	var snapped_y = round(play_position.y / spacing) * spacing
	var snapped_z = round(play_position.z / spacing) * spacing
	return Vector3(snapped_x, snapped_y, snapped_z)

func create_grid_texture(rows: int, cols: int):
	# Create an image to represent the grid
	drawing_texture = Image.create(rows, cols, false, Image.FORMAT_RGBA8)
	drawing_texture.fill(Color(1, 1, 1, 1))  # White background with full alpha
	
	# Draw grid lines
	var line_color = Color(0.8, 0.8, 0.8, 1)  # Light gray grid lines for better heat map visibility
	for row in range(rows):
		for col in range(cols):
			# Draw grid points and lines
			if row % 2 == 0 or col % 2 == 0:
				drawing_texture.set_pixel(row, col, line_color)
	
	drawing_texture_data = ImageTexture.create_from_image(drawing_texture)
	update_material(drawing_texture_data)
	
func update_grid_texture(snapped_pos: Vector3):
	# Calculate relative position from player start position
	var relative_pos = snapped_pos - player_start_position
	
	# Calculate grid coordinates using modulo to wrap within texture bounds
	# Center point (player_start_position) will be at texture_size/2, texture_size/2
	var center_x = texture_size_x / 2
	var center_y = texture_size_y / 2
	var grid_x = int(posmod(center_x + relative_pos.x, texture_size_x))
	var grid_y = int(posmod(2 + relative_pos.z, texture_size_y))
	
	# Get the current color of the pixel at (grid_x, grid_y)
	var current_color = drawing_texture.get_pixel(grid_x, grid_y)
	
	# Create a unique key for the pixel
	var pixel_key = str(grid_x) + "_" + str(grid_y)
	
	# Update visit count for heat map
	if !grid_point_visit_count.has(pixel_key):
		grid_point_visit_count[pixel_key] = 0
	grid_point_visit_count[pixel_key] += 1
	
	# Calculate heat intensity - logarithmic scale for better gradient
	var visit_count = grid_point_visit_count[pixel_key]
	var heat_intensity = min(log(visit_count + 1) / log(20), 1.0)  # Logarithmic scale with max at ~20 visits
	
	# Color the pixel based on heat map intensity
	# Start with white/light color and transition to more intense colors with more visits
	var heat_color = Color(1, 1, 1, 1)  # Start with white
	
	if visit_count > 1:
		# Gradient from white -> yellow -> orange -> red -> deep red
		if heat_intensity < 0.25:
			# White to yellow (reduce blue)
			heat_color = Color(1, 1, 1 - (heat_intensity * 4), 1)
		elif heat_intensity < 0.5:
			# Yellow to orange (reduce green)
			heat_color = Color(1, 1 - ((heat_intensity - 0.25) * 2), 0, 1)
		elif heat_intensity < 0.75:
			# Orange to red (reduce green completely)
			heat_color = Color(1, 0.5 - ((heat_intensity - 0.5) * 2), 0, 1)
		else:
			# Red to deep red (reduce red)
			heat_color = Color(1 - ((heat_intensity - 0.75) * 0.5), 0, 0, 1)
			
		# Add a bit of blue for highly visited areas for a more digital feel
		if visit_count > 15:
			heat_color.b = 0.2
	
	# Only update colors for grid points, not lines
	if row_is_grid_point(grid_x) or col_is_grid_point(grid_y):
		drawing_texture.set_pixel(grid_x, grid_y, heat_color)
	
	# Store the current visit count
	previously_colored_pixels[pixel_key] = heat_intensity

	
	# Update the last grid position
	last_grid_x = grid_x
	last_grid_y = grid_y
	
	# Update the texture
	drawing_texture_data.update(drawing_texture)
	update_material(drawing_texture_data)

# Helper functions to determine if a position is a grid point vs. a grid line
func row_is_grid_point(row):
	return row % 2 != 0  # Odd rows are grid points, even rows are grid lines

func col_is_grid_point(col):
	return col % 2 != 0  # Odd columns are grid points, even columns are grid lines

			
func update_material(tex: ImageTexture):
	if PlainGrid.material_override is ShaderMaterial:
		var shader_material = PlainGrid.material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		PlainGrid.material_override = material
