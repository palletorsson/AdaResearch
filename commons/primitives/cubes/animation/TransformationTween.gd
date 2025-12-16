# TransformationTween.gd
# Matched to pick_up_cube.gd logic for synchronization
# Uses simple sine wave bobbing instead of Tween

extends Node

@export_group("Bobbing Settings")
@export var bob_height: float = 0.2  # Height of the bob
@export var bob_speed: float = 2.0   # Speed of the bob
@export var auto_start: bool = true

var target_node: Node3D
var initial_position: Vector3
var time_passed: float = 0.0
var is_active: bool = false

func _ready():
	# Find the cube to animate
	# Assuming structure: Parent -> [ThisScript, CubeBaseStaticBody3D]
	target_node = get_parent().get_node_or_null("CubeBaseStaticBody3D")
	
	# Fallback: try to animate parent if specific node not found (for flexibility)
	if not target_node:
		target_node = get_parent()
	
	if target_node:
		initial_position = target_node.position
		if auto_start:
			is_active = true
	else:
		print("TransformationTween: No target node found")

func _process(delta: float):
	if not is_active or not target_node:
		return
		
	time_passed += delta
	
	# Match pick_up_cube.gd logic:
	# var bob_offset = sin(time_passed * bob_speed) * bob_height
	# global_position.y = original_y + bob_offset
	
	# We apply to local position here to be safe within the scene hierarchy
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	
	# Apply strictly to Y axis for "bobbing" (Standard Pickup Behavior)
	var new_pos = initial_position
	new_pos.y += bob_offset
	target_node.position = new_pos

func stop_movement():
	is_active = false

func start_movement():
	is_active = true

func reset_position():
	if target_node:
		target_node.position = initial_position
	time_passed = 0.0
