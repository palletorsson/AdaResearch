# RotationTween.gd
# Simple rotation animation using Tween
# Rotates the cube around specified axes

extends Node

@export_group("Rotation Settings")
@export var rotation_amount: Vector3 = Vector3(0, 360, 0)  # How much to rotate (degrees)
@export var duration: float = 3.0  # How long the rotation takes
@export var auto_start: bool = true  # Start rotation automatically
@export var loop_animation: bool = true  # Keep rotating continuously

var target_node: Node3D
var initial_rotation: Vector3
var tween: Tween

func _ready():
	# Find the cube to animate
	target_node = get_parent().get_node("CubeBaseStaticBody3D")
	if not target_node:
		print("RotationTween: Could not find target cube node!")
		return
	
	# Store the starting rotation
	initial_rotation = target_node.rotation_degrees
	
	# Start animation if enabled
	if auto_start:
		start_rotation()

func start_rotation():
	"""Start the rotation animation"""
	if not target_node:
		return
	
	# Create a new tween
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Rotate by the specified amount
	var target_rotation = target_node.rotation_degrees + rotation_amount
	tween.tween_property(target_node, "rotation_degrees", target_rotation, duration)
	tween.tween_callback(_on_rotation_complete)

func _on_rotation_complete():
	"""Called when one rotation is finished"""
	if not loop_animation:
		return
	
	# Continue rotating - just start another rotation cycle
	start_rotation()

func stop_rotation():
	"""Stop the rotation animation"""
	if tween:
		tween.kill()

func reset_rotation():
	"""Reset cube to starting rotation"""
	if target_node:
		target_node.rotation_degrees = initial_rotation

func set_rotation_speed(speed_multiplier: float):
	"""Change rotation speed by adjusting duration"""
	duration = 3.0 / speed_multiplier
	# Restart with new speed if currently rotating
	if tween and tween.is_valid():
		start_rotation() 
