extends Node3D

class_name BouncingBall

var balls = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var obstacles = []

func _ready():
	_initialize_balls()
	_initialize_obstacles()
	_connect_ui()

func _initialize_balls():
	# Get all balls
	balls = $Balls.get_children()
	
	# Initialize each ball
	for ball in balls:
		ball.initialize()

func _initialize_obstacles():
	# Get all obstacles for collision detection
	obstacles = $Environment/Obstacles.get_children()

func _physics_process(delta):
	if paused:
		return
	
	# Update physics for each ball
	for ball in balls:
		ball.update_physics(delta, gravity)
		_check_collisions(ball)

func _check_collisions(ball):
	# Check wall collisions
	_check_wall_collisions(ball)
	
	# Check obstacle collisions
	_check_obstacle_collisions(ball)
	
	# Check ball-to-ball collisions
	_check_ball_collisions(ball)

func _check_wall_collisions(ball):
	var ball_radius = 0.5
	var bounds = Vector3(7.5, 10, 7.5)  # Half of wall dimensions
	
	# X-axis walls
	if ball.position.x - ball_radius < -bounds.x:
		ball.position.x = -bounds.x + ball_radius
		ball.velocity.x = -ball.velocity.x * 0.8  # Bounce with energy loss
	elif ball.position.x + ball_radius > bounds.x:
		ball.position.x = bounds.x - ball_radius
		ball.velocity.x = -ball.velocity.x * 0.8
	
	# Z-axis walls
	if ball.position.z - ball_radius < -bounds.z:
		ball.position.z = -bounds.z + ball_radius
		ball.velocity.z = -ball.velocity.z * 0.8
	elif ball.position.z + ball_radius > bounds.z:
		ball.position.z = bounds.z - ball_radius
		ball.velocity.z = -ball.velocity.z * 0.8
	
	# Ground collision
	if ball.position.y - ball_radius < 0:
		ball.position.y = ball_radius
		ball.velocity.y = -ball.velocity.y * 0.7  # Bounce with energy loss
		ball.velocity.x *= 0.9  # Ground friction
		ball.velocity.z *= 0.9

func _check_obstacle_collisions(ball):
	var ball_radius = 0.5
	
	for obstacle in obstacles:
		var obstacle_pos = obstacle.position
		var obstacle_size = obstacle.size
		
		# Calculate closest point on obstacle to ball
		var closest_x = clamp(ball.position.x, obstacle_pos.x - obstacle_size.x/2, obstacle_pos.x + obstacle_size.x/2)
		var closest_z = clamp(ball.position.z, obstacle_pos.z - obstacle_size.z/2, obstacle_pos.z + obstacle_size.z/2)
		var closest_y = clamp(ball.position.y, obstacle_pos.y - obstacle_size.y/2, obstacle_pos.y + obstacle_size.y/2)
		
		var closest_point = Vector3(closest_x, closest_y, closest_z)
		var distance = ball.position.distance_to(closest_point)
		
		if distance < ball_radius:
			# Collision detected - push ball away
			var push_direction = (ball.position - closest_point).normalized()
			ball.position = closest_point + push_direction * ball_radius
			
			# Reflect velocity based on collision normal
			var normal = push_direction
			var velocity = ball.velocity
			
			# Reflect velocity: v' = v - 2(v·n)n
			var dot_product = velocity.dot(normal)
			ball.velocity = velocity - 2 * dot_product * normal
			
			# Apply energy loss
			ball.velocity *= 0.8

func _check_ball_collisions(ball):
	var ball_radius = 0.5
	
	for other_ball in balls:
		if other_ball == ball:
			continue
		
		var distance = ball.position.distance_to(other_ball.position)
		var min_distance = ball_radius + ball_radius
		
		if distance < min_distance:
			# Collision detected
			var collision_normal = (ball.position - other_ball.position).normalized()
			
			# Separate balls
			var overlap = min_distance - distance
			ball.position += collision_normal * overlap * 0.5
			other_ball.position -= collision_normal * overlap * 0.5
			
			# Calculate collision response (elastic collision)
			var relative_velocity = ball.velocity - other_ball.velocity
			var velocity_along_normal = relative_velocity.dot(collision_normal)
			
			# Only resolve collision if balls are moving toward each other
			if velocity_along_normal < 0:
				var restitution = 0.8  # Energy loss factor
				var impulse = -(1 + restitution) * velocity_along_normal
				
				# Apply impulse (assuming equal masses)
				ball.velocity += collision_normal * impulse
				other_ball.velocity -= collision_normal * impulse

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/GravitySlider.value_changed.connect(_on_gravity_changed)

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
