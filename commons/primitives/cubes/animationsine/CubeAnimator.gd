# CubeAnimator.gd
# Chapter 3: The Animated Cube
# Handles rotation, oscillation, and scale animations with individual controls

extends Node3D

# Animation Enable/Disable Controls
@export_group("Animation Controls")
@export var enable_rotation: bool = true
@export var enable_oscillation: bool = true  
@export var enable_scale_pulse: bool = true

# Rotation Settings
@export_group("Rotation")
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)  # degrees per second

# Oscillation Settings  
@export_group("Oscillation")
@export var oscillation_height: float = 0.2
@export var oscillation_speed: float = 2.0

# Scale Pulse Settings
@export_group("Scale Pulse")
@export var scale_pulse_amount: float = 0.1
@export var scale_pulse_speed: float = 1.5

var target_node: Node3D
var initial_position: Vector3
var initial_scale: Vector3
var time_elapsed: float = 0.0

func _ready():
	# Find the cube mesh to animate
	target_node = get_parent().get_node("CubeBaseStaticBody3D")
	if not target_node:
		print("CubeAnimator: Could not find target cube node!")
		return
	
	# Store initial transform values
	initial_position = target_node.position
	initial_scale = target_node.scale
	
	print("CubeAnimator: Starting animation")
	print("  Rotation: %s" % ("ON" if enable_rotation else "OFF"))
	print("  Oscillation: %s" % ("ON" if enable_oscillation else "OFF"))
	print("  Scale Pulse: %s" % ("ON" if enable_scale_pulse else "OFF"))

func _process(delta):
	if not target_node:
		return
		
	time_elapsed += delta
	
	# Apply animations only if enabled
	if enable_rotation:
		_update_rotation(delta)
	
	if enable_oscillation:
		_update_oscillation()
	else:
		# Keep at initial position if oscillation disabled
		target_node.position = initial_position
	
	if enable_scale_pulse:
		_update_scale_pulse()
	else:
		# Keep at initial scale if pulse disabled
		target_node.scale = initial_scale

func _update_rotation(delta):
	"""Handle rotation animation"""
	target_node.rotation_degrees += rotation_speed * delta

func _update_oscillation():
	"""Handle up/down oscillation animation"""
	var oscillation_offset = sin(time_elapsed * oscillation_speed) * oscillation_height
	target_node.position = initial_position + Vector3(0, oscillation_offset, 0)

func _update_scale_pulse():
	"""Handle scale pulsing animation"""
	var scale_multiplier = 1.0 + sin(time_elapsed * scale_pulse_speed) * scale_pulse_amount
	target_node.scale = initial_scale * scale_multiplier

# Control methods for external interaction
func pause_animation():
	set_process(false)

func resume_animation():
	set_process(true)

func reset_animation():
	if not target_node:
		return
	time_elapsed = 0.0
	target_node.position = initial_position
	target_node.scale = initial_scale
	target_node.rotation_degrees = Vector3.ZERO

func set_animation_speed(speed_multiplier: float):
	rotation_speed = Vector3(0, 45, 0) * speed_multiplier
	oscillation_speed = 2.0 * speed_multiplier
	scale_pulse_speed = 1.5 * speed_multiplier

# Individual animation control methods
func toggle_rotation(enabled: bool):
	enable_rotation = enabled
	print("CubeAnimator: Rotation %s" % ("enabled" if enabled else "disabled"))

func toggle_oscillation(enabled: bool):
	enable_oscillation = enabled
	if not enabled and target_node:
		target_node.position = initial_position
	print("CubeAnimator: Oscillation %s" % ("enabled" if enabled else "disabled"))

func toggle_scale_pulse(enabled: bool):
	enable_scale_pulse = enabled
	if not enabled and target_node:
		target_node.scale = initial_scale
	print("CubeAnimator: Scale pulse %s" % ("enabled" if enabled else "disabled"))

# Preset combinations for teaching
func set_animation_preset(preset_name: String):
	match preset_name:
		"none":
			enable_rotation = false
			enable_oscillation = false
			enable_scale_pulse = false
		"rotation_only":
			enable_rotation = true
			enable_oscillation = false
			enable_scale_pulse = false
		"oscillation_only":
			enable_rotation = false
			enable_oscillation = true
			enable_scale_pulse = false
		"scale_only":
			enable_rotation = false
			enable_oscillation = false
			enable_scale_pulse = true
		"rotation_and_oscillation":
			enable_rotation = true
			enable_oscillation = true
			enable_scale_pulse = false
		"all":
			enable_rotation = true
			enable_oscillation = true
			enable_scale_pulse = true
		_:
			print("CubeAnimator: Unknown preset: %s" % preset_name)
			return
	
	print("CubeAnimator: Applied preset '%s'" % preset_name)
