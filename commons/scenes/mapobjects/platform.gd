extends Node3D
# Queer VR Platform Lift with Procedural Sound Effects

# Configuration
@export var lift_height: float = 5.0  # How high the platform lifts
@export var lift_speed: float = 2.0   # Speed of movement
@export var return_delay: float = 4.0  # Seconds to wait before returning to start position
@export var start_delay: float = 2.0   # Seconds to wait before starting to lift

# Sound customization
@export_group("Sound Settings")
@export_range(0, 1) var detection_volume: float = 0.7
@export_range(0, 1) var lift_volume: float = 0.8
@export_range(0, 1) var warning_volume: float = 0.9
@export_range(0, 1) var ambient_volume: float = 0.3
@export_range(0, 1) var entropy: float = 0.4  # Controls randomness/noise in sounds
@export_range(0, 1) var queer_factor: float = 0.7  # Controls harmonic shifting in sounds

# Internal variables
var initial_position: Vector3
var target_position: Vector3
var is_moving: bool = false
var is_returning: bool = false
var player_on_platform: bool = false
var return_timer: float = 0.0
var start_timer: float = 0.0       # Timer for the start delay
var waiting_to_start: bool = false # Flag to indicate we're in the start delay period

# Audio nodes
@onready var detection_player: AudioStreamPlayer3D = $AudioPlayers/DetectionPlayer
@onready var lift_start_player: AudioStreamPlayer3D = $AudioPlayers/LiftStartPlayer
@onready var lift_loop_player: AudioStreamPlayer3D = $AudioPlayers/LiftLoopPlayer
@onready var lift_stop_player: AudioStreamPlayer3D = $AudioPlayers/LiftStopPlayer
@onready var warning_player: AudioStreamPlayer3D = $AudioPlayers/WarningPlayer
@onready var ambient_player: AudioStreamPlayer3D = $AudioPlayers/AmbientPlayer

# Reference to the area that detects the player
@onready var detection_area = $DetectionArea
@onready var label = $DetectionArea/Label3D

func _ready():
	# Store initial position
	initial_position = global_position
	
	# Calculate target position (lift_height units higher)
	target_position = initial_position + Vector3(0, lift_height, 0)
	label.text = "Platform Ready"
	
	# Setup audio players
	setup_audio_players()
	
	# Start ambient sound
	ambient_player.play()

func setup_audio_players():
	# Create audio players if they don't exist
	if not has_node("AudioPlayers"):
		var audio_players = Node3D.new()
		audio_players.name = "AudioPlayers"
		add_child(audio_players)
		
		detection_player = AudioStreamPlayer3D.new()
		detection_player.name = "DetectionPlayer"
		audio_players.add_child(detection_player)
		
		lift_start_player = AudioStreamPlayer3D.new()
		lift_start_player.name = "LiftStartPlayer"
		audio_players.add_child(lift_start_player)
		
		lift_loop_player = AudioStreamPlayer3D.new()
		lift_loop_player.name = "LiftLoopPlayer"
		audio_players.add_child(lift_loop_player)
		
		lift_stop_player = AudioStreamPlayer3D.new()
		lift_stop_player.name = "LiftStopPlayer"
		audio_players.add_child(lift_stop_player)
		
		warning_player = AudioStreamPlayer3D.new()
		warning_player.name = "WarningPlayer"
		audio_players.add_child(warning_player)
		
		ambient_player = AudioStreamPlayer3D.new()
		ambient_player.name = "AmbientPlayer"
		audio_players.add_child(ambient_player)
	
	# Generate procedural sound effects
	generate_procedural_sounds()
	
	# Configure audio properties
	configure_audio_properties()

func generate_procedural_sounds():
	# Generate all sounds using the SyntheticSoundGenerator
	detection_player.stream = SyntheticSoundGenerator.create_detection_sound(entropy, queer_factor)
	lift_start_player.stream = SyntheticSoundGenerator.create_lift_start_sound(entropy, queer_factor)
	lift_loop_player.stream = SyntheticSoundGenerator.create_lift_loop_sound(entropy, queer_factor)
	lift_stop_player.stream = SyntheticSoundGenerator.create_lift_stop_sound(entropy, queer_factor)
	warning_player.stream = SyntheticSoundGenerator.create_warning_sound(entropy, queer_factor)
	ambient_player.stream = SyntheticSoundGenerator.create_ambient_sound(entropy, queer_factor)

func configure_audio_properties():
	# Set volumes
	detection_player.volume_db = linear_to_db(detection_volume)
	lift_start_player.volume_db = linear_to_db(lift_volume)
	lift_loop_player.volume_db = linear_to_db(lift_volume * 0.8)  # Slightly quieter for the loop
	lift_stop_player.volume_db = linear_to_db(lift_volume)
	warning_player.volume_db = linear_to_db(warning_volume)
	ambient_player.volume_db = linear_to_db(ambient_volume)
	
	# Configure spatial audio properties
	for player in [detection_player, lift_start_player, lift_loop_player, 
				  lift_stop_player, warning_player, ambient_player]:
		player.max_distance = 20.0
		player.attenuation_filter_cutoff_hz = 5000.0
		player.attenuation_filter_db = -12.0

func _process(delta):
	# Handle start delay timer
	if waiting_to_start:
		start_timer -= delta
		#label.text = "Starting in: " + str(int(start_timer) + 1)
		
		if start_timer <= 0:
			waiting_to_start = false
			is_moving = true
			label.text = "Lifting..."
			
			# Play lift start sound
			lift_start_player.play()
			# Start the loop sound with a slight delay
			create_tween().tween_callback(func(): lift_loop_player.play()).set_delay(0.3)
	
	elif is_moving:
		# Move towards target position
		if is_returning:
			global_position = global_position.move_toward(initial_position, lift_speed * delta)
			
			# Check if we've reached the starting position
			if global_position.distance_to(initial_position) < 0.01:
				global_position = initial_position
				is_moving = false
				is_returning = false
				label.text = "At bottom"
				
				# Stop sounds
				lift_loop_player.stop()
				lift_stop_player.play()
				warning_player.stop()
		else:
			global_position = global_position.move_toward(target_position, lift_speed * delta)
			
			# Check if we've reached the target position
			if global_position.distance_to(target_position) < 0.01:
				global_position = target_position
				label.text = "At top"
				
				# Stop movement sound, play stop sound
				lift_loop_player.stop()
				lift_stop_player.play()
				
				# Always start the return timer when reaching the top
				return_timer = return_delay
				is_moving = false
	
	# Handle return timer - now this always runs when we're at the top
	elif return_timer > 0 and global_position.distance_to(target_position) < 0.01:
		return_timer -= delta
		label.text = "Returning in: " + str(int(return_timer) + 1)
		
		# Play warning sound during the last 2 seconds
		if return_timer <= 2.0 and not warning_player.playing:
			warning_player.play()
		
		if return_timer <= 0:
			start_return()

func _on_detection_area_body_entered(body):
	# Check if the entering body is the VR player
	if _is_vr_player(body):
		player_on_platform = true
		label.text = "Player detected: " + str(body)
		
		# Play detection sound
		detection_player.play()
		
		start_lift()

func _on_detection_area_body_exited(body):
	
	# Check if the exiting body is the VR player
	if _is_vr_player(body):
		player_on_platform = false
		
		# Play exit sound (reuse detection sound with lower pitch)
		detection_player.pitch_scale = 0.8  # Lower pitch for exit
		detection_player.play()
		detection_player.pitch_scale = 1.0  # Reset pitch
		
		# Cancel start delay if player exits during the delay
		if waiting_to_start:
			waiting_to_start = false
			start_timer = 0
			label.text = "Cancelled"

func _is_vr_player(body) -> bool:
	# This function determines if the body is the VR player
	# Modify this check based on your player node structure
	return body.is_in_group("vr_player") or body.name.contains("XROrigin3D") or body.name.contains("Player")

func start_lift():
	# Only start lifting if we're at the bottom and not already moving or waiting
	if global_position.distance_to(initial_position) < 0.01 and not is_moving and not waiting_to_start:
		if start_delay > 0:
			# Start the delay timer
			waiting_to_start = true
			start_timer = start_delay
			#label.text = "Preparing to lift..."
		else:
			# No delay, start immediately
			is_moving = true
			is_returning = false
			
			# Play startup sound
			lift_start_player.play()
			# Start the loop sound with a slight delay
			create_tween().tween_callback(func(): lift_loop_player.play()).set_delay(0.3)

func start_return():
	# Always return if we're at the top, regardless of player presence
	if global_position.distance_to(target_position) < 0.01:
		is_moving = true
		is_returning = true
		label.text = "Returning..."
		
		# Play startup sound for return journey
		lift_start_player.play()
		
		# Start the loop sound with a slight delay
		create_tween().tween_callback(func(): lift_loop_player.play()).set_delay(0.3)
		
		# Stop warning sound if it was playing
		warning_player.stop()
		
		# If player is still on the platform, keep the warning sound going
		if player_on_platform:
			label.text = "Warning! Returning..."
			warning_player.play()

# Function to regenerate sounds with different parameters
func regenerate_sounds(new_entropy: float = -1, new_queer_factor: float = -1):
	# Update parameters if provided
	if new_entropy >= 0:
		entropy = clamp(new_entropy, 0, 1)
	if new_queer_factor >= 0:
		queer_factor = clamp(new_queer_factor, 0, 1)
		
	# Stop any playing sounds
	for player in [detection_player, lift_start_player, lift_loop_player, 
				  lift_stop_player, warning_player]:
		player.stop()
	
	# Keep track if ambient was playing
	var ambient_was_playing = ambient_player.playing
	ambient_player.stop()
	
	# Regenerate all sounds
	generate_procedural_sounds()
	
	# Restart ambient if it was playing
	if ambient_was_playing:
		ambient_player.play()
