extends Node3D

class_name NewtonsLaws

var balls = []
var velocities = []
var forces = []
var masses = [1.0, 1.5, 2.0]
var paused = false
var gravity = Vector3(0, -9.8, 0)
var friction = 0.98
var time = 0.0

# Visualization
var force_vectors = []
var velocity_vectors = []
var trails = []
var show_vectors = true
var show_trails = true

# Colors
var ball_colors = [
	Color(1.0, 0.3, 0.3, 1.0),  # Red
	Color(0.3, 1.0, 0.3, 1.0),  # Green
	Color(0.3, 0.5, 1.0, 1.0),  # Blue
]

func _ready():
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	# Initialize balls and their properties
	balls = [$Objects/Ball1, $Objects/Ball2, $Objects/Ball3]

	# Enhance ball visuals
	enhance_ball_visuals()

	# Initialize velocities and forces for each ball
	for i in range(balls.size()):
		velocities.append(Vector3.ZERO)
		forces.append(Vector3.ZERO)
		create_visualization_for_ball(i)

	# Set initial forces
	forces[1] = Vector3(3, 0, 0)  # Ball 2 gets horizontal force
	forces[2] = Vector3(-3, 0, 0)  # Ball 3 gets opposite force

	# Connect UI buttons
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)

	print("Newton's Laws - Enhanced Visualization!")

func enhance_ball_visuals():
	for i in range(balls.size()):
		var ball = balls[i]
		if ball is CSGSphere3D:
			# Create glowing material
			var mat = StandardMaterial3D.new()
			mat.albedo_color = ball_colors[i]
			mat.metallic = 0.3
			mat.roughness = 0.4
			mat.emission_enabled = true
			mat.emission = ball_colors[i] * 0.8
			mat.emission_energy_multiplier = 2.0
			ball.material = mat

func create_visualization_for_ball(index: int):
	# Create force vector arrow
	var force_arrow = create_arrow(ball_colors[index])
	$ForceVectors.add_child(force_arrow)
	force_vectors.append(force_arrow)

	# Create velocity vector arrow
	var velocity_arrow = create_arrow(Color.YELLOW)
	$ForceVectors.add_child(velocity_arrow)
	velocity_vectors.append(velocity_arrow)

	# Create trail
	var trail = create_trail(ball_colors[index])
	$ForceVectors.add_child(trail)
	trails.append(trail)

func create_arrow(color: Color) -> MeshInstance3D:
	var arrow = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	arrow.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.8
	mat.emission_energy_multiplier = 2.0
	arrow.material_override = mat

	arrow.visible = false
	return arrow

func create_trail(_color: Color) -> ImmediateMesh:
	var trail = ImmediateMesh.new()
	return trail

func _process(delta):
	time += delta
	update_visualizations()

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
	var mass = masses[ball_index]

	# Apply gravity (F = mg)
	force += gravity * mass

	# Apply force to velocity (F = ma)
	var acceleration = force / mass
	velocity += acceleration * delta

	# Apply air resistance
	velocity *= friction

	# Update position
	ball.position += velocity * delta

	# Add pulsing animation based on speed
	var speed = velocity.length()
	var pulse = 1.0 + sin(time * 10) * 0.05 * clamp(speed / 5.0, 0, 1)
	ball.scale = Vector3.ONE * pulse

	# Ground collision with bounce effect
	if ball.position.y <= 0.5:
		ball.position.y = 0.5
		velocity.y = -velocity.y * 0.7  # Bounce with energy loss
		velocity.x *= 0.9  # Ground friction
		velocity.z *= 0.9

		# Create bounce particles
		if velocity.y > 1.0:
			create_bounce_effect(ball.position, ball_colors[ball_index])

	# Wall collisions
	if abs(ball.position.x) > 9:
		velocity.x = -velocity.x * 0.8
		ball.position.x = sign(ball.position.x) * 9

	if abs(ball.position.z) > 9:
		velocity.z = -velocity.z * 0.8
		ball.position.z = sign(ball.position.z) * 9

	# Update stored velocity
	velocities[ball_index] = velocity

	# Reset force for next frame (with different patterns for each ball)
	if ball_index == 1:
		# Constant force
		forces[ball_index] = Vector3(3, 0, 0)
	elif ball_index == 2:
		# Oscillating force
		forces[ball_index] = Vector3(
			sin(time * 2) * 4,
			0,
			cos(time * 1.5) * 2
		)
	else:
		forces[ball_index] = Vector3.ZERO

func create_bounce_effect(pos: Vector3, color: Color):
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.position = pos
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_radius = 0.2
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.5
	particles.scale_amount_min = 0.03
	particles.scale_amount_max = 0.06
	particles.color = color

	add_child(particles)

	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func update_visualizations():
	if not show_vectors:
		for arrow in force_vectors:
			arrow.visible = false
		for arrow in velocity_vectors:
			arrow.visible = false
		return

	# Update force and velocity vectors
	for i in range(balls.size()):
		var ball = balls[i]
		var force = forces[i]
		var velocity = velocities[i]

		# Force vector
		if force.length() > 0.1 and i < force_vectors.size():
			var arrow = force_vectors[i]
			arrow.visible = true
			arrow.position = ball.position
			if force.length() > 0:
				arrow.look_at(ball.position + force.normalized(), Vector3.UP)
			arrow.scale = Vector3(1, clamp(force.length() / 5.0, 0.3, 2.0), 1)
		elif i < force_vectors.size():
			force_vectors[i].visible = false

		# Velocity vector
		if velocity.length() > 0.1 and i < velocity_vectors.size():
			var arrow = velocity_vectors[i]
			arrow.visible = true
			arrow.position = ball.position + Vector3(0, 0.4, 0)
			if velocity.length() > 0:
				arrow.look_at(ball.position + Vector3(0, 0.4, 0) + velocity.normalized(), Vector3.UP)
			arrow.scale = Vector3(1, clamp(velocity.length() / 3.0, 0.2, 1.5), 1)
		elif i < velocity_vectors.size():
			velocity_vectors[i].visible = false

func _on_reset_pressed():
	# Reset all balls to initial positions
	var initial_positions = [Vector3(-3, 2, 0), Vector3(0, 2, 0), Vector3(3, 2, 0)]

	for i in range(balls.size()):
		balls[i].position = initial_positions[i]
		balls[i].scale = Vector3.ONE
		velocities[i] = Vector3.ZERO
		forces[i] = Vector3.ZERO

	time = 0.0

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_on_reset_pressed()
			KEY_V:
				show_vectors = !show_vectors
			KEY_T:
				show_trails = !show_trails
