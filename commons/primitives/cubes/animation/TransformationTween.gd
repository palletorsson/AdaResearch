# TransformationTween.gd
# Simple position/movement animation using Tween
# Moves the cube from one position to another and back

extends Node

@export_group("Movement Settings")
@export var movement_distance: Vector3 = Vector3(0, 3, 0)  # How far to move
@export var duration: float = 2.0  # How long each movement takes
@export var auto_start: bool = true  # Start animation automatically
@export var loop_animation: bool = true  # Keep moving back and forth

var target_node: Node3D
var initial_position: Vector3
var tween: Tween
var is_moving_forward: bool = true

func _ready():
	# Find the cube to animate
	target_node = get_parent().get_node("CubeBaseStaticBody3D")
	if not target_node:
		print("TransformationTween: Could not find target cube node!")
		return
	
	# Store the starting position
	initial_position = target_node.position
	
	# Start animation if enabled
	if auto_start:
		start_movement()

func start_movement():
	"""Start the movement animation"""
	if not target_node:
		return
	
	# Create a new tween
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Move to the target position
	var target_position = initial_position + movement_distance
	tween.tween_property(target_node, "position", target_position, duration)
	tween.tween_callback(_on_movement_complete)

func _on_movement_complete():
	"""Called when one movement is finished"""
	if not loop_animation:
		return
	
	# Switch direction and move again
	is_moving_forward = !is_moving_forward
	
	# Create new tween for return movement
	tween = create_tween()
	
	var target_position: Vector3
	if is_moving_forward:
		target_position = initial_position + movement_distance
	else:
		target_position = initial_position
	
	tween.tween_property(target_node, "position", target_position, duration)
	tween.tween_callback(_on_movement_complete)

func stop_movement():
	"""Stop the animation"""
	if tween:
		tween.kill()

func reset_position():
	"""Reset cube to starting position"""
	if target_node:
		target_node.position = initial_position
		is_moving_forward = true 
