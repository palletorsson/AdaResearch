# ScaleTween.gd
# Simple scale/size animation using Tween
# Makes the cube grow and shrink

extends Node

@export_group("Scale Settings")
@export var scale_amount: float = 1.5  # How big to scale (1.0 = normal size)
@export var duration: float = 1.5  # How long each scale change takes
@export var auto_start: bool = true  # Start scaling automatically
@export var loop_animation: bool = true  # Keep scaling back and forth

var target_node: Node3D
var initial_scale: Vector3
var tween: Tween
var is_scaling_up: bool = true

func _ready():
	# Find the cube to animate
	target_node = get_parent().get_node("CubeBaseStaticBody3D")
	if not target_node:
		print("ScaleTween: Could not find target cube node!")
		return
	
	# Store the starting scale
	initial_scale = target_node.scale
	
	# Start animation if enabled
	if auto_start:
		start_scaling()

func start_scaling():
	"""Start the scale animation"""
	if not target_node:
		return
	
	# Create a new tween
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Scale to the target size
	var target_scale = initial_scale * scale_amount
	tween.tween_property(target_node, "scale", target_scale, duration)
	tween.tween_callback(_on_scale_complete)

func _on_scale_complete():
	"""Called when one scale animation is finished"""
	if not loop_animation:
		return
	
	# Switch direction and scale again
	is_scaling_up = !is_scaling_up
	
	# Create new tween for return scaling
	tween = create_tween()
	
	var target_scale: Vector3
	if is_scaling_up:
		target_scale = initial_scale * scale_amount
	else:
		target_scale = initial_scale
	
	tween.tween_property(target_node, "scale", target_scale, duration)
	tween.tween_callback(_on_scale_complete)

func stop_scaling():
	"""Stop the scaling animation"""
	if tween:
		tween.kill()

func reset_scale():
	"""Reset cube to starting scale"""
	if target_node:
		target_node.scale = initial_scale
		is_scaling_up = true

func set_scale_speed(speed_multiplier: float):
	"""Change scaling speed by adjusting duration"""
	duration = 1.5 / speed_multiplier
	# Restart with new speed if currently scaling
	if tween and tween.is_valid():
		start_scaling() 