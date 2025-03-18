extends Node3D

@export var depth_count: int = 17 # Number of panels in depth (Z direction)
@export var rows: int = 3  # Number of rows
@export var panel_scene: PackedScene  # Reference panel scene for collision and properties
@export var spacing_x: float = 1.6 # Distance between panels in X direction
@export var spacing_z: float = 1.6  # Distance between panels in Z direction
@export var panel_scale: Vector3 = Vector3(1.5, 1.5, 1.5)  # Default panel scale
@export var rotation_speed: float = 3.0  # How quickly panels rotate to face player
@export var scale_distance: float = 8.0  # The distance at which scaling begins
@export var min_scale_factor: float = 0.1  # Minimum scale factor when close to player

# Sound parameters - PRE-GENERATED
@export var enable_sound: bool = true  # Toggle for sound
@export var min_pitch: float = 0.8  # Minimum pitch for sound
@export var max_pitch: float = 2.0  # Maximum pitch for sound
@export var max_active_sounds: int = 5  # Maximum number of panels making sound at once
@export var sound_check_interval: float = 0.2  # Time between sound updates

# MultiMesh Configuration
@export var use_multimesh: bool = true  # Option to use MultiMesh for better performance
@export var panel_mesh: Mesh  # The mesh to use for panels (required for MultiMesh)
@export var panel_material: Material  # Material for the panels

@onready var vr_player = $"../../XROrigin3D/XRCamera3D/lookat" # Reference to the player

# Debug
var debug_label: Label3D

# Panel tracking
var panel_positions = []  # Store positions for each panel
var panel_rotations = []  # Store current rotations
var panel_scales = []    # Store current scales
var panel_instances = [] # For non-multimesh mode

# MultiMesh instance
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh

# Sound system
var sound_timer: float = 0.0
var active_sound_panels = []  # Track which panels are currently making sound
var audio_players = []  # Array of pre-configured audio players
var pre_generated_sounds = []  # Store pre-generated audio streams

func _ready():
	# Create debug label
	debug_label = Label3D.new()
	debug_label.position = Vector3(0, 8, 0)
	debug_label.scale = Vector3(2, 2, 2)
	add_child(debug_label)
	
	# Check VR player reference
	if not vr_player:
		print("ERROR: Could not find VR player node. Make sure the path is correct.")
		debug_label.text = "ERROR: Player not found"
		return
	
	# Pre-generate audio if sound is enabled
	if enable_sound:
		_setup_audio_system()
	
	# Setup panel system
	if use_multimesh and panel_mesh != null:
		_setup_multimesh()
	else:
		_setup_individual_panels()
	
	debug_label.text = "System initialized with " + str(panel_positions.size()) + " panels"

func _setup_audio_system():
	# Create pre-generated audio streams at different pitch levels
	for i in range(5):  # Create 5 different pitch levels
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 44100
		stream.buffer_length = 1.0  # 1 second buffer
		pre_generated_sounds.append(stream)
	
	# Create audio players pool - fewer than the number of panels
	for i in range(max_active_sounds):
		var audio_player = AudioStreamPlayer3D.new()
		audio_player.max_distance = scale_distance
		audio_player.unit_size = 5.0  # Make sound carry further
		
		# Assign one of our pre-generated streams
		var stream_index = i % pre_generated_sounds.size()
		audio_player.stream = pre_generated_sounds[stream_index]
		
		add_child(audio_player)
		audio_players.append({
			"player": audio_player,
			"in_use": false,
			"panel_index": -1,
			"initialized": false
		})
	
	# Generate the actual audio data for each stream - do this once at startup
	for i in range(pre_generated_sounds.size()):
		var pitch = lerp(min_pitch, max_pitch, float(i) / (pre_generated_sounds.size() - 1))
		_generate_tone(pre_generated_sounds[i], pitch)

func _generate_tone(stream, pitch):
	# Create an audio player just to get a playback instance
	var temp_player = AudioStreamPlayer.new()
	add_child(temp_player)
	temp_player.stream = stream
	temp_player.play()
	
	# Get the playback to push frames
	var playback = temp_player.get_stream_playback()
	if playback:
		var frames = playback.get_frames_available()
		var base_freq = 220.0 * pitch  # A3 note scaled by pitch
		var amplitude = 0.3
		
		# Generate a simple sine wave tone
		var increment = 1.0 / 44100.0
		var time = 0.0
		
		for j in range(frames):
			var sample = sin(time * base_freq * TAU) * amplitude
			playback.push_frame(Vector2(sample, sample))
			time += increment
	
	# We've generated the audio, now remove the temporary player
	temp_player.stop()
	temp_player.queue_free()

func _setup_multimesh():
	# Create the MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = panel_mesh
	
	# Calculate total number of panels
	var total_panels = rows * depth_count
	multimesh.instance_count = total_panels
	
	# Initialize panel data arrays first
	var panel_index = 0
	var transforms = []
	
	for row in range(rows):
		for depth in range(depth_count):
			# Calculate panel position
			var y_position = row * spacing_x
			var position = Vector3(0, y_position + 1.6, depth * spacing_z)
			
			# Store panel data
			panel_positions.append(position)
			panel_rotations.append(0.0)  # Initial Y rotation
			panel_scales.append(panel_scale)
			
			# Create transform for this panel
			var transform = Transform3D()
			transform.origin = position
			transform.basis = Basis().scaled(panel_scale)
			transforms.append(transform)
			
			panel_index += 1
	
	# Create the MultiMeshInstance3D
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	if panel_material:
		multimesh_instance.material_override = panel_material
	add_child(multimesh_instance)
	
	# Now apply all transforms after the multimesh is fully set up
	for i in range(transforms.size()):
		if i < multimesh.instance_count:
			multimesh.set_instance_transform(i, transforms[i])

func _setup_individual_panels():
	for row in range(rows):
		for depth in range(depth_count):
			# Calculate panel position
			var y_position = row * spacing_x
			var position = Vector3(0, y_position + 1.6, depth * spacing_z)
			
			# Store panel data
			panel_positions.append(position)
			panel_rotations.append(0.0)  # Initial Y rotation
			panel_scales.append(panel_scale)
			
			# Create panel instance
			var panel = panel_scene.instantiate()
			panel.position = position
			panel.scale = panel_scale
			add_child(panel)
			panel_instances.append(panel)

func _process(delta):
	if not vr_player:
		return
		
	# Update panel transforms
	_update_panels(delta)
	
	# Update sounds less frequently
	sound_timer -= delta
	if sound_timer <= 0 and enable_sound:
		_update_panel_sounds()
		sound_timer = sound_check_interval

func _update_panels(delta):
	var player_pos = vr_player.global_transform.origin
	
	var panels_in_range = 0
	
	for i in range(panel_positions.size()):
		var panel_pos = panel_positions[i]
		
		# Calculate direction to player in the XZ plane (ignoring Y)
		var direction_to_player = Vector2(player_pos.x - panel_pos.x, player_pos.z - panel_pos.z).normalized()
		
		# Calculate the target angle (in radians)
		var target_angle = atan2(direction_to_player.x, direction_to_player.y)
		
		# Smoothly interpolate to target Y rotation
		var current_y_rot = panel_rotations[i]
		var new_y_rot = lerp_angle(current_y_rot, target_angle, delta * rotation_speed)
		panel_rotations[i] = new_y_rot
		
		# Calculate distance to player for scaling
		var distance_to_player = panel_pos.distance_to(player_pos)
		
		# Apply scaling based on distance
		var target_scale
		if distance_to_player < scale_distance:
			panels_in_range += 1
			
			# Calculate scale factor based on distance
			var distance_ratio = distance_to_player / scale_distance
			var scale_factor = min_scale_factor + distance_ratio * (1.0 - min_scale_factor)
			target_scale = panel_scale * scale_factor
		else:
			target_scale = panel_scale
		
		panel_scales[i] = target_scale
		
		# Apply updates to the panel
		if use_multimesh:
			var transform = Transform3D()
			transform.origin = panel_pos
			
			# Create rotation matrix (only around Y axis)
			var basis = Basis()
			basis = basis.rotated(Vector3.UP, new_y_rot)
			basis = basis.scaled(target_scale)
			transform.basis = basis
		if multimesh != null:	
			multimesh.set_instance_transform(i, transform)
		else:
			var panel = panel_instances[i]
			panel.rotation.y = new_y_rot
			panel.scale = target_scale
	
	debug_label.text = "Panels in range: " + str(panels_in_range)

func _update_panel_sounds():
	# Get panels sorted by distance (closest first)
	var sorted_panels = []
	var player_pos = vr_player.global_transform.origin
	
	for i in range(panel_positions.size()):
		var panel_pos = panel_positions[i]
		var distance = panel_pos.distance_to(player_pos)
		
		if distance < scale_distance:
			sorted_panels.append({
				"index": i,
				"distance": distance,
				"distance_ratio": distance / scale_distance
			})
	
	# Sort panels by distance
	sorted_panels.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Reset currently playing audio
	for audio_data in audio_players:
		audio_data.in_use = false
	
	# Assign audio players to the closest panels
	var active_count = min(sorted_panels.size(), max_active_sounds)
	
	for i in range(active_count):
		var panel_data = sorted_panels[i]
		var panel_index = panel_data.index
		var distance_ratio = panel_data.distance_ratio
		
		# Find an available audio player
		for audio_data in audio_players:
			if not audio_data.in_use:
				# Pitch selection based on distance (use closest pre-generated sound)
				var pitch_index = floor(distance_ratio * (pre_generated_sounds.size() - 1))
				pitch_index = clamp(pitch_index, 0, pre_generated_sounds.size() - 1)
				
				# Get the appropriate player
				var audio_player = audio_data.player
				
				# Position the audio at the panel's location
				audio_player.global_position = panel_positions[panel_index]
				
				# Set volume based on distance
				var volume_factor = 1.0 - distance_ratio
				#audio_player.unit_db = -20 + (volume_factor * 10.0)
				
				# Start playing if not already
				if not audio_player.playing:
					audio_player.play()
				
				# Mark this player as in use
				audio_data.in_use = true
				audio_data.panel_index = panel_index
				break
	
	# Stop any players not assigned to panels
	for audio_data in audio_players:
		if not audio_data.in_use and audio_data.player.playing:
			audio_data.player.stop()
			audio_data.panel_index = -1
