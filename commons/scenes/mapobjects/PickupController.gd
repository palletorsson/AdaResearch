# Enhanced PickupController.gd
# Chapter 4+: Pickup Cube with Audio Integration
# Adds Mario-style pickup sounds to the interaction system

extends Node3D

@export var hover_color: Color = Color.YELLOW
@export var grab_color: Color = Color.GREEN
@export var hover_scale_boost: float = 1.1

# Audio settings
@export_group("Audio")
@export var play_hover_sound: bool = true
@export var play_grab_sound: bool = true
@export var hover_pitch: float = 1.2
@export var grab_pitch: float = 1.0

var original_material: Material
var mesh_instance: MeshInstance3D
var interaction_area: Area3D
var animator: Node3D
var audio_player: CubeAudioPlayer
var is_grabbed: bool = false
var is_hovered: bool = false

signal cube_grabbed(cube: Node3D)
signal cube_released(cube: Node3D)
signal cube_hovered(cube: Node3D)
signal cube_unhovered(cube: Node3D)

func _ready():
	mesh_instance = find_child("CubeBaseMesh", true, false)
	interaction_area = find_child("InteractionArea", false, false)
	animator = find_child("CubeAnimator", false, false)
	
	# Setup audio system
	_setup_audio()
	
	if mesh_instance:
		original_material = mesh_instance.material_override
	
	if interaction_area:
		interaction_area.area_entered.connect(_on_hand_entered)
		interaction_area.area_exited.connect(_on_hand_exited)
		print("PickupController: Interaction area connected")

func _setup_audio():
	# Create audio player component
	audio_player = CubeAudioPlayer.new()
	audio_player.name = "CubeAudioPlayer"
	audio_player.primary_sound = AudioSynthesizer.SoundType.PICKUP_MARIO
	audio_player.secondary_sound = AudioSynthesizer.SoundType.MELODIC_DRONE
	audio_player.volume_db = -6.0  # Slightly quieter
	add_child(audio_player)
	
	print("PickupController: Audio system ready")

func _on_hand_entered(area: Area3D):
	if "hand" in area.name.to_lower():
		_start_hover()

func _on_hand_exited(area: Area3D):
	if "hand" in area.name.to_lower():
		_end_hover()

func _start_hover():
	if is_grabbed:
		return
		
	is_hovered = true
	_apply_hover_effect()
	
	# Play hover sound
	if play_hover_sound and audio_player:
		audio_player.set_pitch(hover_pitch)
		audio_player.play_secondary_sound(true)  # Use secondary for hover
	
	cube_hovered.emit(self)

func _end_hover():
	if is_grabbed:
		return
		
	is_hovered = false
	_remove_hover_effect()
	cube_unhovered.emit(self)

func _apply_hover_effect():
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", hover_color)
	
	if animator:
		animator.scale *= hover_scale_boost

func _remove_hover_effect():
	if mesh_instance:
		mesh_instance.material_override = original_material
	
	if animator:
		animator.scale /= hover_scale_boost

# Called by XR-Tools when grabbed
func grabbed(grabber):
	is_grabbed = true
	_apply_grab_effect()
	
	# Play grab sound
	if play_grab_sound and audio_player:
		audio_player.set_pitch(grab_pitch)
		audio_player.play_primary_sound(true)  # Use primary for grab
	
	cube_grabbed.emit(self)
	print("PickupController: Cube grabbed with sound!")

# Called by XR-Tools when released
func released(grabber):
	is_grabbed = false
	_remove_grab_effect()
	cube_released.emit(self)
	print("PickupController: Cube released")

func _apply_grab_effect():
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", grab_color)

func _remove_grab_effect():
	_remove_hover_effect()

# Audio control methods
func set_audio_enabled(enabled: bool):
	play_hover_sound = enabled
	play_grab_sound = enabled

func set_grab_sound_pitch(pitch: float):
	grab_pitch = pitch

func set_hover_sound_pitch(pitch: float):
	hover_pitch = pitch
