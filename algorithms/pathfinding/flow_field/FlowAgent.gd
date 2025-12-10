extends CharacterBody3D

var grid: FlowGrid
var speed: float = 8.0
var steers_force: float = 20.0

func initialize(g: FlowGrid, start_pos: Vector3):
	grid = g
	position = start_pos

func _physics_process(delta):
	# 1. Bounds Check (Force Return if off-map)
	# Grid is roughly -20 to +20. If outside, turn back.
	if position.length() > 22.0: 
		var return_dir = -position.normalized()
		velocity = velocity.lerp(return_dir * speed, 5.0 * delta)
		move_and_slide()
		if velocity.length() > 0.1:
			look_at(position + velocity, Vector3.UP)
		return

	# 2. Flow Field Lookup
	var desired_dir = _get_vector_safe(position)
	
	if desired_dir.length_squared() > 0.01:
		# Normal Flow
		var target_vel = desired_dir * speed
		velocity = velocity.lerp(target_vel, steers_force * delta)
		
		# Rotate
		if velocity.length() > 0.1:
			var look_t = position + velocity
			look_at(look_t, Vector3.UP)
	else:
		# Zero Vector (Target or Wall)
		# Wander to escape potential wall traps or buzz around target
		var wander = Vector3(randf()-0.5, 0, randf()-0.5).normalized()
		velocity = velocity.lerp(wander * speed * 0.5, 2.0 * delta)
		
	move_and_slide()

# Helper to flatten vector
func _get_vector_safe(pos):
	var v = grid.get_vector(pos)
	return Vector3(v.x, 0, v.z) # Grid returns Vector3(x,0,z) already? Check FlowGrid.
	# grid.get_vector returns Vector3(v2.x, 0, v2.y). Correction: v2.y maps to Z. Correct.
