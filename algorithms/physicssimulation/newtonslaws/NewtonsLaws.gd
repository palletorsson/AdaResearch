extends Node3D

class_name NewtonsLaws

var balls = []
var velocities = []
var forces = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var friction = 0.98

func _ready():
	# Initialize balls and their properties
	balls = [$Objects/Ball1, $Objects/Ball2, $Objects/Ball3]
	
	# Initialize velocities and forces for each ball
	for i in range(balls.size()):
		velocities.append(Vector3.ZERO)
		forces.append(Vector3.ZERO)
	
	# Set initial forces
	forces[1] = Vector3(2, 0, 0)  # Ball 2 gets horizontal force
	forces[2] = Vector3(-2, 0, 0)  # Ball 3 gets opposite force
	
	# Connect UI buttons
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)

func _physics_process(delta):
	if paused:
		return
	
	# Apply physics to each ball
	for i in range(balls.size()):
		_apply_physics(i, delta)

func _apply_physics(ball_index: int, delta: float):
	var ball = balls[ball_index]
	var velocity = velocities[ball_index]
	var force = forces[ball_index]
	
	# Apply gravity
	force += gravity
	
	# Apply force to velocity (F = ma, assuming mass = 1)
	velocity += force * delta
	
	# Apply friction
	velocity *= friction
	
	# Update position
	ball.position += velocity * delta
	
	# Ground collision
	if ball.position.y <= 0.5:
		ball.position.y = 0.5
		velocity.y = -velocity.y * 0.7  # Bounce with energy loss
		velocity.x *= 0.9  # Ground friction
	
	# Wall collisions
	if abs(ball.position.x) > 9:
		velocity.x = -velocity.x * 0.8
		ball.position.x = sign(ball.position.x) * 9
	
	if abs(ball.position.z) > 9:
		velocity.z = -velocity.z * 0.8
		ball.position.z = sign(ball.position.z) * 9
	
	# Update stored velocity
	velocities[ball_index] = velocity
	
	# Reset force for next frame (except applied forces)
	if ball_index == 1:
		forces[ball_index] = Vector3(2, 0, 0)
	elif ball_index == 2:
		forces[ball_index] = Vector3(-2, 0, 0)
	else:
		forces[ball_index] = Vector3.ZERO

func _on_reset_pressed():
	# Reset all balls to initial positions
	var initial_positions = [Vector3(-3, 2, 0), Vector3(0, 2, 0), Vector3(3, 2, 0)]
	
	for i in range(balls.size()):
		balls[i].position = initial_positions[i]
		velocities[i] = Vector3.ZERO

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"
