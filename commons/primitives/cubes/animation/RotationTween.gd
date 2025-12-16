# RotationTween.gd
# Matched to pick_up_cube.gd logic for synchronization
# Uses continuous _process rotation instead of Tween

extends Node

@export_group("Rotation Settings")
@export var rotation_speed: float = 2.0  # Speed in radians/sec (matches PickupCube default)
@export var axis: Vector3 = Vector3(0, 1, 0) # Default Y axis
@export var auto_start: bool = true

var target_node: Node3D
var is_active: bool = false

func _ready():
	# Find the cube to animate
	target_node = get_parent().get_node_or_null("CubeBaseStaticBody3D")
	
	# Fallback
	if not target_node:
		target_node = get_parent()
	
	if target_node:
		if auto_start:
			is_active = true
	else:
		print("RotationTween: No target node found")

func _process(delta: float):
	if not is_active or not target_node:
		return
		
	# Match pick_up_cube.gd logic:
	# rotate_y(rotation_speed * delta)
	
	if axis.y > 0.9: # Optimized for standard Y rotation
		target_node.rotate_y(rotation_speed * delta)
	else:
		# Generic axis rotation
		target_node.rotate_object_local(axis.normalized(), rotation_speed * delta)

func stop_rotation():
	is_active = false

func start_rotation():
	is_active = true

func set_rotation_speed(new_speed: float):
	rotation_speed = new_speed
