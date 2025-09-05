# DistanceConstraint.gd - Attach to any 3D object that needs distance constraints
extends Node3D

# Constraint settings
@export var max_distance_from_start: float = 0.2
@export var constraint_strength: float = 1000.0

# Internal variables
var is_grabbed: bool = false
var start_position: Vector3
var grab_offset: Vector3

# Called when the object is first grabbed
func start_grab():
	if not is_grabbed:
		is_grabbed = true
		start_position = global_position
		print("Grab started at position: ", start_position)

# Called when the object is released
func release_grab():
	if is_grabbed:
		is_grabbed = false
		print("Grab released")

# Update constraint every physics frame
func _physics_process(delta):
	if is_grabbed:
		apply_distance_constraint()

# Apply the distance constraint
func apply_distance_constraint():
	var current_distance = global_position.distance_to(start_position)
	
	# If beyond max distance, apply constraint
	if current_distance > max_distance_from_start:
		# Calculate direction back to start position
		var direction_to_start = (start_position - global_position).normalized()
		
		# Calculate how far over the limit we are
		var overshoot = current_distance - max_distance_from_start
		
		# Get the parent RigidBody3D if it exists
		var rigid_body = get_parent()
		if rigid_body is RigidBody3D:
			# Apply corrective force to RigidBody3D
			var constraint_force = direction_to_start * overshoot * constraint_strength
			(rigid_body as RigidBody3D).apply_central_force(constraint_force)
			
			# Optional: Add damping to prevent oscillation
			var velocity_damping = -(rigid_body as RigidBody3D).linear_velocity * 5.0
			(rigid_body as RigidBody3D).apply_central_force(velocity_damping)
		else:
			# For non-physics objects, use hard constraint
			apply_hard_constraint()
		
		# Debug visualization
		print("Distance: %.3f, Over limit by: %.3f" % [current_distance, overshoot])

# Alternative method: Hard constraint (teleport back if too far)
func apply_hard_constraint():
	var current_distance = global_position.distance_to(start_position)
	
	if current_distance > max_distance_from_start:
		# Calculate the maximum allowed position
		var direction = (global_position - start_position).normalized()
		var max_position = start_position + direction * max_distance_from_start
		
		# Snap to the boundary
		global_position = max_position
		
		# Stop movement if parent is a physics body
		var rigid_body = get_parent()
		if rigid_body is RigidBody3D:
			(rigid_body as RigidBody3D).linear_velocity = Vector3.ZERO
			(rigid_body as RigidBody3D).angular_velocity = Vector3.ZERO
		elif rigid_body is CharacterBody3D:
			(rigid_body as CharacterBody3D).velocity = Vector3.ZERO
		
		print("Hard constraint applied - snapped to boundary")

# Call this from your grab system when grab starts
func _on_grab_started():
	start_grab()

# Call this from your grab system when grab ends  
func _on_grab_released():
	release_grab()

# Visual debug - draw the constraint sphere in editor
func _draw_debug():
	if Engine.is_editor_hint() and is_grabbed:
		# This would need to be implemented with a separate debug drawing system
		pass
