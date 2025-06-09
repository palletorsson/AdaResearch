# Enhanced TeleportController.gd  
# Chapter 7+: Teleporter with Electrostatic Drone Audio
# Adds synthesized drone sounds to teleporter charging/activation

extends "res://commons/primitives/cubes/VRGadgetController.gd"

@export var destination: String = ""
@export var activation_method: String = "touch"
@export var portal_color: Color = Color.CYAN
@export var charge_time: float = 2.0

# Audio settings
@export_group("Teleporter Audio")
@export var play_charge_drone: bool = true
@export var play_activation_sound: bool = true
@export var drone_volume: float = -3.0

var portal_effect: GPUParticles3D
var beam_area: Area3D
var teleport_audio: CubeAudioPlayer
var is_charging: bool = false
var charge_progress: float = 0.0
var players_in_beam: Array = []

signal teleporter_activated()
signal teleporter_charging(progress: float)
signal teleporter_ready()

func _ready():
	super()
	
	portal_effect = find_child("PortalEffect", false, false)
	beam_area = find_child("BeamArea", false, false)
	
	# Setup teleporter audio
	_setup_teleporter_audio()
	
	if portal_effect:
		portal_effect.emitting = false
	
	if beam_area:
		beam_area.body_entered.connect(_on_player_entered_beam)
		beam_area.body_exited.connect(_on_player_exited_beam)
	
	print("TeleportController: Ready with drone audio - destination: %s" % destination)

func _setup_teleporter_audio():
	# Create dedicated audio player for teleporter sounds
	teleport_audio = CubeAudioPlayer.new()
	teleport_audio.name = "TeleportAudio"
	teleport_audio.primary_sound = AudioSynthesizer.SoundType.TELEPORT_DRONE
	teleport_audio.secondary_sound = AudioSynthesizer.SoundType.GHOST_DRONE
	teleport_audio.volume_db = drone_volume
	teleport_audio.max_distance = 15.0  # Larger range for teleporter
	add_child(teleport_audio)
	
	print("TeleportController: Teleporter audio system ready")

func _process(delta):
	super(delta)
	
	if is_charging:
		charge_progress += delta / charge_time
		
		# Modulate drone pitch based on charge progress
		if teleport_audio:
			var pitch = 0.8 + (charge_progress * 0.4)  # 0.8 to 1.2
			teleport_audio.set_pitch(pitch)
		
		if charge_progress >= 1.0:
			_complete_teleport_charge()
		else:
			_update_charge_effects()
			teleporter_charging.emit(charge_progress)

func _on_player_entered_beam(body: Node3D):
	if _is_player_body(body):
		players_in_beam.append(body)
		print("TeleportController: Player entered beam")
		
		if activation_method == "proximity":
			_start_teleport_sequence()

func _on_player_exited_beam(body: Node3D):
	if body in players_in_beam:
		players_in_beam.erase(body)
		
		if players_in_beam.is_empty() and is_charging:
			_cancel_teleport_sequence()

func _is_player_body(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("player_body") or "player" in body.name.to_lower() or body.name.contains("XROrigin3D")

func _trigger_touch_interaction(touch_position: Vector3):
	super(touch_position)
	
	if activation_method == "touch":
		_start_teleport_sequence()

func grabbed(grabber):
	super.grabbed(grabber)
	
	if activation_method == "grab":
		_start_teleport_sequence()

func _start_teleport_sequence():
	if is_charging or destination.is_empty():
		return
	
	print("TeleportController: Starting teleport sequence")
	is_charging = true
	charge_progress = 0.0
	
	# Start visual effects
	if portal_effect:
		portal_effect.emitting = true
	
	# Start charging drone sound
	if play_charge_drone and teleport_audio:
		teleport_audio.play_primary_sound(true)  # Play drone spatially
	
	_start_charge_animation()

func _cancel_teleport_sequence():
	print("TeleportController: Teleport sequence cancelled")
	is_charging = false
	charge_progress = 0.0
	
	# Stop effects
	if portal_effect:
		portal_effect.emitting = false
	
	# Stop audio
	if teleport_audio:
		teleport_audio.stop_all_sounds()
	
	_stop_charge_animation()

func _complete_teleport_charge():
	print("TeleportController: Teleport fully charged!")
	is_charging = false
	charge_progress = 1.0
	
	teleporter_ready.emit()
	_activate_teleporter()

func _activate_teleporter():
	print("TeleportController: 🚀 TELEPORTER ACTIVATED!")
	
	# Stop charging drone, play activation sound
	if teleport_audio:
		teleport_audio.stop_all_sounds()
		
		if play_activation_sound:
			# Quick high-pitched burst for activation
			teleport_audio.set_pitch(2.0)
			teleport_audio.play_secondary_sound(true)
	
	# Visual flash effect
	_trigger_teleport_flash()
	
	# Emit activation signal
	teleporter_activated.emit()
	
	# Reset after delay
	await get_tree().create_timer(0.5).timeout
	_reset_teleporter_state()

func _trigger_teleport_flash():
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.WHITE)
			material.set_shader_parameter("emission_strength", 10.0)

func _reset_teleporter_state():
	# Reset all effects and state
	if portal_effect:
		portal_effect.emitting = false
	
	# Reset audio
	if teleport_audio:
		teleport_audio.set_pitch(1.0)
	
	_stop_charge_animation()
	
	# Restore normal appearance
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", portal_color)
			material.set_shader_parameter("emission_strength", 2.0)

func _start_charge_animation():
	if animator:
		animator.scale_pulse_speed = 4.0
		animator.oscillation_speed = 3.0

func _stop_charge_animation():
	if animator:
		animator.scale_pulse_speed = 1.5
		animator.oscillation_speed = 2.0

func _update_charge_effects():
	# Update visual effects based on charge progress
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			var intensity = 2.0 + charge_progress * 3.0
			material.set_shader_parameter("emission_strength", intensity)

# Audio control methods
func set_drone_volume(volume_db: float):
	drone_volume = volume_db
	if teleport_audio:
		teleport_audio.set_volume(volume_db)

func set_teleporter_audio_enabled(charging: bool, activation: bool):
	play_charge_drone = charging
	play_activation_sound = activation

func set_destination(new_destination: String):
	destination = new_destination

func get_destination() -> String:
	return destination
