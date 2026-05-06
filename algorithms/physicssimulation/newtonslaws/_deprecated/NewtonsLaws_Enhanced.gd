# ===========================================================================
# Newton's Laws - Enhanced Visualization
# Beautiful animated demonstration of F=ma, momentum, and force interactions
# ===========================================================================

extends Node3D

class_name NewtonsLawsEnhanced

# Ball properties
class PhysicsBall:
	var node: CSGSphere3D
	var position: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var mass: float
	var color: Color
	var applied_force: Vector3
	var trail_points: Array[Vector3] = []
	var trail_mesh: ImmediateMesh
	var trail_node: MeshInstance3D

	func _init(n: CSGSphere3D, pos: Vector3, m: float, c: Color) -> void:
		node = n
		position = pos
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		mass = m
		color = c
		applied_force = Vector3.ZERO
		trail_points = []

# Physics parameters
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
@export var air_resistance: float = 0.02
@export var ground_friction: float = 0.9
@export var restitution: float = 0.7
@export var show_trails: bool = true
@export var show_force_vectors: bool = true
@export var show_velocity_vectors: bool = true
@export var trail_length: int = 100

# Balls
var balls: Array[PhysicsBall] = []
var ball_nodes: Array[CSGSphere3D] = []

# Force vectors
var force_arrows: Dictionary = {}
var velocity_arrows: Dictionary = {}
var gravity_arrows: Dictionary = {}

# UI
var info_labels: Array[Label3D] = []
var paused: bool = false
var time: float = 0.0

# Colors
var ball_colors = [
	Color(1.0, 0.3, 0.3, 1.0),  # Red - Ball 1 (gravity only)
	Color(0.3, 1.0, 0.3, 1.0),  # Green - Ball 2 (constant force)
	Color(0.3, 0.5, 1.0, 1.0),  # Blue - Ball 3 (oscillating force)
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_balls()
	create_force_visualization_system()
	create_ui()
	create_ground_visual()

	print("Newton's Laws Enhanced - Beautiful Physics Visualization!")

func create_balls() -> void:
	var initial_positions = [
		Vector3(-3, 2, 0),
		Vector3(0, 2, 0),
		Vector3(3, 2, 0)
	]

	var masses = [1.0, 1.5, 2.0]

	for i in range(3):
		# Create ball visual
		var ball_node = CSGSphere3D.new()
		ball_node.radius = 0.3 + i * 0.05

		# Create glowing material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = ball_colors[i]
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = ball_colors[i] * 0.8
		mat.emission_energy_multiplier = 2.0

		ball_node.material = mat
		ball_node.position = initial_positions[i]
		$Objects.add_child(ball_node)

		# Create ball data
		var ball = PhysicsBall.new(ball_node, initial_positions[i], masses[i], ball_colors[i])

		# Create trail
		create_trail_for_ball(ball, i)

		balls.append(ball)
		ball_nodes.append(ball_node)

func create_trail_for_ball(ball: PhysicsBall, index: int) -> void:
	# Create trail visualization
	ball.trail_mesh = ImmediateMesh.new()
	ball.trail_node = MeshInstance3D.new()
	ball.trail_node.mesh = ball.trail_mesh

	var trail_mat = StandardMaterial3D.new()
	trail_mat.albedo_color = ball.color
	trail_mat.emission_enabled = true
	trail_mat.emission = ball.color * 0.5
	trail_mat.emission_energy_multiplier = 1.0
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	ball.trail_node.material_override = trail_mat
	$Objects.add_child(ball.trail_node)

func create_force_visualization_system() -> void:
	# Create force arrow containers
	for i in range(balls.size()):
		# Applied force arrow
		var force_arrow = create_arrow(ball_colors[i], "Applied Force")
		$ForceVectors.add_child(force_arrow)
		force_arrows[i] = force_arrow

		# Velocity arrow
		var velocity_arrow = create_arrow(Color.YELLOW, "Velocity")
		$ForceVectors.add_child(velocity_arrow)
		velocity_arrows[i] = velocity_arrow

		# Gravity arrow
		var gravity_arrow = create_arrow(Color.WHITE, "Gravity")
		$ForceVectors.add_child(gravity_arrow)
		gravity_arrows[i] = gravity_arrow

func create_arrow(color: Color, label_text: String) -> Node3D:
	var arrow = Node3D.new()

	# Arrow shaft (cylinder)
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	shaft.mesh = cylinder

	var shaft_mat = StandardMaterial3D.new()
	shaft_mat.albedo_color = color
	shaft_mat.emission_enabled = true
	shaft_mat.emission = color * 0.8
	shaft_mat.emission_energy_multiplier = 1.5
	shaft.material_override = shaft_mat

	arrow.add_child(shaft)

	# Arrow head (cone)
	var head = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.08
	cone.height = 0.2
	head.mesh = cone
	head.material_override = shaft_mat
	head.position = Vector3(0, 0.6, 0)
	arrow.add_child(head)

	# Label
	var label = Label3D.new()
	label.text = label_text
	label.font_size = 12
	label.modulate = color
	label.outline_size = 2
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.8, 0)
	arrow.add_child(label)

	arrow.visible = false
	return arrow

func create_ground_visual() -> void:
	# Create a grid ground
	var grid_size = 20
	var grid_spacing = 1.0

	for x in range(-grid_size, grid_size + 1):
		create_grid_line(
			Vector3(x * grid_spacing, 0, -grid_size * grid_spacing),
			Vector3(x * grid_spacing, 0, grid_size * grid_spacing)
		)

	for z in range(-grid_size, grid_size + 1):
		create_grid_line(
			Vector3(-grid_size * grid_spacing, 0, z * grid_spacing),
			Vector3(grid_size * grid_spacing, 0, z * grid_spacing)
		)

func create_grid_line(from: Vector3, to: Vector3) -> void:
	var line = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	line.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = mat

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()

	$Ground.add_child(line)

func create_ui() -> void:
	# Create info labels for each ball
	for i in range(balls.size()):
		var label = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 16
		label.outline_size = 3
		label.outline_modulate = Color.BLACK
		label.modulate = ball_colors[i]
		add_child(label)
		info_labels.append(label)

	# Main title
	var title = Label3D.new()
	title.text = "NEWTON'S LAWS OF MOTION"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 32
	title.outline_size = 4
	title.outline_modulate = Color.BLACK
	title.position = Vector3(0, 5, 0)
	add_child(title)

	# Instructions
	var instructions = Label3D.new()
	instructions.text = "[R] Reset | [P] Pause | [T] Toggle Trails | [F] Toggle Forces"
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.outline_size = 3
	instructions.outline_modulate = Color.BLACK
	instructions.position = Vector3(0, 4.3, 0)
	add_child(instructions)

func _process(delta: float) -> void:
	if paused:
		return

	time += delta

	# Update physics for each ball
	for i in range(balls.size()):
		update_ball_physics(i, delta)

	# Update visualizations
	update_force_vectors()
	update_trails()
	update_info_labels()

func update_ball_physics(index: int, delta: float) -> void:
	var ball = balls[index]

	# Reset acceleration
	ball.acceleration = Vector3.ZERO

	# Apply gravity (F = mg)
	var gravity_force = gravity * ball.mass
	ball.acceleration += gravity_force / ball.mass

	# Apply different forces based on ball
	match index:
		0:
			# Ball 1: Gravity only (free fall and bounce)
			pass
		1:
			# Ball 2: Constant horizontal force
			var constant_force = Vector3(3, 0, 0)
			ball.applied_force = constant_force
			ball.acceleration += constant_force / ball.mass
		2:
			# Ball 3: Oscillating force
			var oscillating_force = Vector3(
				sin(time * 2) * 5,
				0,
				cos(time * 1.5) * 3
			)
			ball.applied_force = oscillating_force
			ball.acceleration += oscillating_force / ball.mass

	# Air resistance (F = -kv²)
	if ball.velocity.length() > 0.1:
		var drag = -ball.velocity.normalized() * ball.velocity.length_squared() * air_resistance
		ball.acceleration += drag / ball.mass

	# Update velocity (v = v + at)
	ball.velocity += ball.acceleration * delta

	# Update position (p = p + vt)
	ball.position += ball.velocity * delta

	# Ground collision with bounce
	if ball.position.y <= 0.5:
		ball.position.y = 0.5
		ball.velocity.y = -ball.velocity.y * restitution
		ball.velocity.x *= ground_friction
		ball.velocity.z *= ground_friction

		# Create bounce effect
		create_bounce_effect(ball.position, ball.color)

	# Wall collisions
	var wall_distance = 9.0
	if abs(ball.position.x) > wall_distance:
		ball.velocity.x = -ball.velocity.x * 0.8
		ball.position.x = sign(ball.position.x) * wall_distance

	if abs(ball.position.z) > wall_distance:
		ball.velocity.z = -ball.velocity.z * 0.8
		ball.position.z = sign(ball.position.z) * wall_distance

	# Update visual position
	ball.node.position = ball.position

	# Add pulsing effect based on velocity
	var speed = ball.velocity.length()
	var pulse = 1.0 + sin(time * 10) * 0.1 * clamp(speed / 5.0, 0, 1)
	ball.node.scale = Vector3.ONE * pulse

func create_bounce_effect(pos: Vector3, color: Color) -> void:
	# Create particle ring on bounce
	var ring = CPUParticles3D.new()
	ring.emitting = true
	ring.one_shot = true
	ring.amount = 12
	ring.lifetime = 0.3
	ring.position = pos
	ring.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ring.emission_ring_radius = 0.3
	ring.emission_ring_inner_radius = 0.2
	ring.gravity = Vector3.ZERO
	ring.initial_velocity_min = 1.0
	ring.initial_velocity_max = 2.0
	ring.scale_amount_min = 0.05
	ring.scale_amount_max = 0.1
	ring.color = color

	add_child(ring)

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(ring):
		ring.queue_free()

func update_force_vectors() -> void:
	if not show_force_vectors:
		for arrow in force_arrows.values():
			arrow.visible = false
		for arrow in velocity_arrows.values():
			arrow.visible = false
		for arrow in gravity_arrows.values():
			arrow.visible = false
		return

	for i in range(balls.size()):
		var ball = balls[i]

		# Applied force arrow
		if ball.applied_force.length() > 0.01:
			var arrow = force_arrows[i]
			arrow.visible = true
			arrow.position = ball.position
			arrow.look_at(ball.position + ball.applied_force.normalized(), Vector3.UP)
			arrow.scale = Vector3.ONE * (ball.applied_force.length() / 5.0)
		else:
			force_arrows[i].visible = false

		# Velocity arrow
		if ball.velocity.length() > 0.01 and show_velocity_vectors:
			var arrow = velocity_arrows[i]
			arrow.visible = true
			arrow.position = ball.position + Vector3(0, 0.4, 0)
			arrow.look_at(ball.position + Vector3(0, 0.4, 0) + ball.velocity.normalized(), Vector3.UP)
			arrow.scale = Vector3.ONE * clamp(ball.velocity.length() / 3.0, 0.2, 2.0)
		else:
			velocity_arrows[i].visible = false

		# Gravity arrow
		var g_arrow = gravity_arrows[i]
		g_arrow.visible = true
		g_arrow.position = ball.position + Vector3(0.4, 0, 0)
		g_arrow.look_at(ball.position + Vector3(0.4, 0, 0) + gravity.normalized(), Vector3.UP)
		g_arrow.scale = Vector3.ONE * 0.5

func update_trails() -> void:
	if not show_trails:
		for ball in balls:
			ball.trail_node.visible = false
		return

	for ball in balls:
		ball.trail_node.visible = true

		# Add current position to trail
		ball.trail_points.append(ball.position)

		# Limit trail length
		if ball.trail_points.size() > trail_length:
			ball.trail_points.remove_at(0)

		# Draw trail
		if ball.trail_points.size() > 1:
			ball.trail_mesh.clear_surfaces()
			ball.trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

			for j in range(ball.trail_points.size()):
				var alpha = float(j) / ball.trail_points.size()
				ball.trail_mesh.surface_set_color(Color(ball.color.r, ball.color.g, ball.color.b, alpha))
				ball.trail_mesh.surface_add_vertex(ball.trail_points[j])

			ball.trail_mesh.surface_end()

func update_info_labels() -> void:
	for i in range(balls.size()):
		var ball = balls[i]
		var label = info_labels[i]

		label.position = ball.position + Vector3(0, 0.8, 0)

		var speed = ball.velocity.length()
		var force = ball.applied_force.length()
		var ke = 0.5 * ball.mass * speed * speed  # Kinetic energy

		match i:
			0:
				label.text = "Ball 1: Gravity Only\nSpeed: %.1f m/s\nKE: %.1f J" % [speed, ke]
			1:
				label.text = "Ball 2: Constant Force\nF=%.1f N | v=%.1f m/s\nKE: %.1f J" % [force, speed, ke]
			2:
				label.text = "Ball 3: Oscillating Force\nF=%.1f N | v=%.1f m/s\nKE: %.1f J" % [force, speed, ke]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_simulation()
			KEY_P:
				paused = !paused
			KEY_T:
				show_trails = !show_trails
			KEY_F:
				show_force_vectors = !show_force_vectors
			KEY_V:
				show_velocity_vectors = !show_velocity_vectors

func reset_simulation() -> void:
	var initial_positions = [
		Vector3(-3, 2, 0),
		Vector3(0, 2, 0),
		Vector3(3, 2, 0)
	]

	for i in range(balls.size()):
		balls[i].position = initial_positions[i]
		balls[i].velocity = Vector3.ZERO
		balls[i].acceleration = Vector3.ZERO
		balls[i].trail_points.clear()
		balls[i].node.position = initial_positions[i]

	time = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
