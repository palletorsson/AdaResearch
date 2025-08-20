extends Node3D
class_name BouncingBall

var balls = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var obstacles = []

# Performance optimization variables
var trail_update_timer = 0.0
var trail_update_interval = 0.033  # Update trails at ~30fps even if physics runs at 60fps
var physics_accumulator = 0.0
var fixed_timestep = 1.0/60.0  # Fixed physics timestep

# Cached values
var ball_radius = 0.5
var bounds = Vector3(7.5, 10, 7.5)

func _ready():
	_initialize_balls()
	_initialize_obstacles()
	_connect_ui()
	
	# Cache ball radius from first ball
	if balls.size() > 0:
		ball_radius = balls[0].get_radius()

func _initialize_balls():
	# Get all balls
	balls = $Balls.get_children()
	
	# Initialize each ball
	for ball in balls:
		ball.initialize()

func _initialize_obstacles():
	# Get all obstacles for collision detection
	obstacles = $Environment/Obstacles.get_children()
	
	# Pre-calculate obstacle bounds for performance
	for obstacle in obstacles:
		if not obstacle.has_meta("bounds_cached"):
			var bounds_data = {
				"position": obstacle.position,
				"half_size": obstacle.size * 0.5
			}
			obstacle.set_meta("bounds_cached", bounds_data)

func _physics_process(delta):
	if paused:
		return
	
	# Use fixed timestep for stable physics
	physics_accumulator += delta
	
	while physics_accumulator >= fixed_timestep:
		physics_accumulator -= fixed_timestep
		_update_physics_step(fixed_timestep)
	
	# Update trail visualization at lower frequency
	trail_update_timer += delta
	if trail_update_timer >= trail_update_interval:
		trail_update_timer = 0.0
		_update_trail_visualizations()

func _update_physics_step(delta: float):
	# Update physics for each ball
	for ball in balls:
		ball.update_physics(delta, gravity)
		_check_collisions(ball)

func _update_trail_visualizations():
	# Update trail meshes at controlled frequency
	for ball in balls:
		ball.update_trail_visualization()

func _check_collisions(ball):
	# Check wall collisions (most optimized)
	_check_wall_collisions_optimized(ball)
	
	# Check obstacle collisions
	_check_obstacle_collisions_optimized(ball)
	
	# Check ball-to-ball collisions
	_check_ball_collisions_optimized(ball)

func _check_wall_collisions_optimized(ball):
	var pos = ball.position
	var vel = ball.velocity
	var radius = ball_radius
	
	# X-axis walls
	if pos.x - radius < -bounds.x:
		ball.position.x = -bounds.x + radius
		ball.velocity.x = -vel.x * 0.8
	elif pos.x + radius > bounds.x:
		ball.position.x = bounds.x - radius
		ball.velocity.x = -vel.x * 0.8
	
	# Z-axis walls
	if pos.z - radius < -bounds.z:
		ball.position.z = -bounds.z + radius
		ball.velocity.z = -vel.z * 0.8
	elif pos.z + radius > bounds.z:
		ball.position.z = bounds.z - radius
		ball.velocity.z = -vel.z * 0.8
	
	# Ground collision
	if pos.y - radius < 0:
		ball.position.y = radius
		ball.velocity.y = -vel.y * 0.7
		ball.velocity.x *= 0.9
		ball.velocity.z *= 0.9

func _check_obstacle_collisions_optimized(ball):
	var ball_pos = ball.position
	
	for obstacle in obstacles:
		var bounds_data = obstacle.get_meta("bounds_cached")
		var obstacle_pos = bounds_data.position
		var half_size = bounds_data.half_size
		
		# Quick AABB check first
		var diff = ball_pos - obstacle_pos
		if abs(diff.x) > half_size.x + ball_radius or \
		   abs(diff.y) > half_size.y + ball_radius or \
		   abs(diff.z) > half_size.z + ball_radius:
			continue  # No collision possible
		
		# Calculate closest point on obstacle to ball
		var closest_x = clamp(ball_pos.x, obstacle_pos.x - half_size.x, obstacle_pos.x + half_size.x)
		var closest_z = clamp(ball_pos.z, obstacle_pos.z - half_size.z, obstacle_pos.z + half_size.z)
		var closest_y = clamp(ball_pos.y, obstacle_pos.y - half_size.y, obstacle_pos.y + half_size.y)
		
		var closest_point = Vector3(closest_x, closest_y, closest_z)
		var distance_sq = ball_pos.distance_squared_to(closest_point)
		var radius_sq = ball_radius * ball_radius
		
		if distance_sq < radius_sq:
			# Collision detected - push ball away
			var distance = sqrt(distance_sq)
			var push_direction = (ball_pos - closest_point).normalized()
			ball.position = closest_point + push_direction * ball_radius
			
			# Reflect velocity based on collision normal
			var velocity = ball.velocity
			var dot_product = velocity.dot(push_direction)
			ball.velocity = velocity - 2 * dot_product * push_direction
			ball.velocity *= 0.8

func _check_ball_collisions_optimized(ball):
	var ball_pos = ball.position
	var min_distance = ball_radius * 2
	var min_distance_sq = min_distance * min_distance
	
	for other_ball in balls:
		if other_ball == ball:
			continue
		
		var distance_sq = ball_pos.distance_squared_to(other_ball.position)
		
		if distance_sq < min_distance_sq:
			# Collision detected
			var distance = sqrt(distance_sq)
			var collision_normal = (ball_pos - other_ball.position).normalized()
			
			# Separate balls
			var overlap = min_distance - distance
			var separation = collision_normal * overlap * 0.5
			ball.position += separation
			other_ball.position -= separation
			
			# Calculate collision response (elastic collision)
			var relative_velocity = ball.velocity - other_ball.velocity
			var velocity_along_normal = relative_velocity.dot(collision_normal)
			
			# Only resolve collision if balls are moving toward each other
			if velocity_along_normal < 0:
				var restitution = 0.8
				var impulse = -(1 + restitution) * velocity_along_normal
				
				# Apply impulse (assuming equal masses)
				var impulse_vector = collision_normal * impulse
				ball.velocity += impulse_vector
				other_ball.velocity -= impulse_vector

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/GravitySlider.value_changed.connect(_on_gravity_changed)
	
	# Add trail quality control
	if $UI/VBoxContainer.has_node("TrailQualitySlider"):
		$UI/VBoxContainer/TrailQualitySlider.value_changed.connect(_on_trail_quality_changed)

func _on_reset_pressed():
	# Reset all balls to initial positions
	for ball in balls:
		ball.reset_to_initial()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_gravity_changed(value: float):
	gravity = Vector3(0, -value, 0)
	$UI/VBoxContainer/GravityLabel.text = "Gravity: " + str(value)

func _on_trail_quality_changed(value: int):
	# Optional: Adjust trail quality for all balls
	for ball in balls:
		ball.set_trail_quality(value)

# Performance monitoring (optional)
func get_performance_stats() -> Dictionary:
	return {
		"ball_count": balls.size(),
		"physics_fps": 1.0 / fixed_timestep,
		"trail_fps": 1.0 / trail_update_interval,
		"total_trail_points": _get_total_trail_points()
	}

func _get_total_trail_points() -> int:
	var total = 0
	for ball in balls:
		total += ball.trail_points.size()
	return total
