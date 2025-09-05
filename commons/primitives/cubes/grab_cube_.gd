# XRDistanceConstraint.gd - Add as child to XRToolsPickable objects
extends Node

# Constraint settings
@export var max_distance_from_start: float = 0.2
@export var constraint_strength: float = 1000.0
@export var use_hard_constraint: bool = false  # True for instant snap, false for smooth forces

# Internal variables
var is_grabbed: bool = false
var start_position: Vector3
var target_node: Node3D  # The XRToolsPickable node we're constraining
var pickable_parent: XRToolsPickable

func _ready():
	# Find the parent XRToolsPickable node
	pickable_parent = get_parent() as XRToolsPickable
	target_node = pickable_parent as Node3D
	
	if not pickable_parent:
		push_error("XRDistanceConstraint: Parent must be XRToolsPickable")
		return
	
	if not target_node:
		push_error("XRDistanceConstraint: Parent must be a Node3D")
		return
	
	# Connect to XR Tools pickup/drop signals
	pickable_parent.picked_up.connect(_on_picked_up)
	pickable_parent.dropped.connect(_on_dropped)
	
	print("XR Distance constraint attached to: ", target_node.name)

# Called when the object is picked up in VR
func _on_picked_up(_pickable):
	is_grabbed = true
	start_position = target_node.global_position
	print("XR Grab started at position: ", start_position)

# Called when the object is dropped in VR
func _on_dropped(_pickable):
	is_grabbed = false
	print("XR Grab released")

# Update constraint every physics frame
func _physics_process(delta):
	if is_grabbed:
		if use_hard_constraint:
			apply_hard_constraint()
		else:
			apply_distance_constraint()

# Apply smooth force-based distance constraint
func apply_distance_constraint():
	if not target_node:
		return
		
	var current_distance = target_node.global_position.distance_to(start_position)
	
	# If beyond max distance, apply constraint
	if current_distance > max_distance_from_start:
		# Calculate direction back to start position
		var direction_to_start = (start_position - target_node.global_position).normalized()
		
		# Calculate how far over the limit we are
		var overshoot = current_distance - max_distance_from_start
		
		# Apply constraint based on node type
		if target_node is RigidBody3D:
			# Use physics forces for RigidBody3D
			var rigid_body = target_node as RigidBody3D
			var constraint_force = direction_to_start * overshoot * constraint_strength
			rigid_body.apply_central_force(constraint_force)
			
			# Add damping to prevent oscillation
			var velocity_damping = -rigid_body.linear_velocity * 5.0
			rigid_body.apply_central_force(velocity_damping)
			
		elif target_node is CharacterBody3D:
			# Use velocity for CharacterBody3D
			var char_body = target_node as CharacterBody3D
			var correction_velocity = direction_to_start * overshoot * 10.0
			char_body.velocity += correction_velocity
			
		else:
			# For other Node3D types, use direct position manipulation
			var max_position = start_position + (target_node.global_position - start_position).normalized() * max_distance_from_start
			target_node.global_position = max_position
		
		# Debug output (comment out for performance)
		# print("Distance: %.3f, Over limit by: %.3f" % [current_distance, overshoot])

# Apply instant snap-back constraint
func apply_hard_constraint():
	if not target_node:
		return
		
	var current_distance = target_node.global_position.distance_to(start_position)
	
	if current_distance > max_distance_from_start:
		# Calculate the maximum allowed position
		var direction = (target_node.global_position - start_position).normalized()
		var max_position = start_position + direction * max_distance_from_start
		
		# Snap to the boundary
		target_node.global_position = max_position
		
		# Stop movement for physics bodies
		if target_node is RigidBody3D:
			var rigid_body = target_node as RigidBody3D
			rigid_body.linear_velocity = Vector3.ZERO
			rigid_body.angular_velocity = Vector3.ZERO
		elif target_node is CharacterBody3D:
			(target_node as CharacterBody3D).velocity = Vector3.ZERO
		
		print("Hard constraint applied - snapped to boundary")

# Optional: Get the controller currently holding this object
func get_holding_controller() -> XRController3D:
	if pickable_parent and is_grabbed:
		return pickable_parent.get_picked_up_by_controller()
	return null

# Optional: Apply constraint relative to controller position instead of start position
func apply_controller_relative_constraint():
	var controller = get_holding_controller()
	if not controller:
		return
		
	var controller_position = controller.global_position
	var current_distance = target_node.global_position.distance_to(controller_position)
	
	if current_distance > max_distance_from_start:
		var direction_to_controller = (controller_position - target_node.global_position).normalized()
		var overshoot = current_distance - max_distance_from_start
		
		if target_node is RigidBody3D:
			var rigid_body = target_node as RigidBody3D
			var constraint_force = direction_to_controller * overshoot * constraint_strength
			rigid_body.apply_central_force(constraint_force)
