# VectorsVisualization.gd
# Visualization component for Vectors info board
extends Control

var visualization_type = "intro"
var animation_time = 0.0
var animation_playing = true

# Physics simulation objects
var particles = []
var forces = []
var velocity_trails = []
var field_vectors = []

# Constants for visualization
const GRID_SIZE = 400
const VECTOR_SCALE = 40
const BALL_RADIUS = 8
const FORCE_STRENGTH = 200
const DISTANCE_THRESHOLD = 80
const MAX_TRAIL_POINTS = 30
const FIELD_GRID_CELLS = 12
const FIELD_CELL_SIZE = 33
const ARROW_SIZE = 10

# Visual styling constants
const COLOR_PRIMARY = Color(0.2, 0.6, 0.8, 0.9)
const COLOR_SECONDARY = Color(0.8, 0.4, 0.2, 0.9)
const COLOR_TERTIARY = Color(0.4, 0.8, 0.4, 0.9)
const COLOR_HIGHLIGHT = Color(1.0, 0.9, 0.2, 0.9)
const COLOR_NEUTRAL = Color(0.7, 0.7, 0.7, 0.8)
const BG_COLOR = Color(0.08, 0.08, 0.1)

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	_initialize_particles()
	_initialize_forces()
	_initialize_trails()
	_initialize_field_vectors()

func _initialize_particles():
	particles = []
	for i in range(8):
		particles.append({
			"position": Vector2(
				rng.randf_range(80, GRID_SIZE - 80),
				rng.randf_range(80, GRID_SIZE - 80)
			),
			"velocity": Vector2(
				rng.randf_range(-30, 30),
				rng.randf_range(-30, 30)
			),
			"acceleration": Vector2.ZERO,
			"mass": rng.randf_range(1, 3),
			"color": Color(rng.randf_range(0.5, 1), rng.randf_range(0.5, 1), rng.randf_range(0.5, 1), 0.8)
		})

func _initialize_forces():
	forces = []
	for i in range(2):
		forces.append({
			"position": Vector2(
				rng.randf_range(100, GRID_SIZE - 100),
				rng.randf_range(100, GRID_SIZE - 100)
			),
			"strength": rng.randf_range(150, 250) * (1 if i % 2 == 0 else -1),
			"color": Color(1, 0.6, 0.2, 0.8) if i % 2 == 0 else Color(0.2, 0.6, 1, 0.8)
		})

func _initialize_trails():
	velocity_trails = []
	for i in range(particles.size()):
		velocity_trails.append([])

func _initialize_field_vectors():
	field_vectors = []
	for y in range(FIELD_GRID_CELLS):
		for x in range(FIELD_GRID_CELLS):
			var pos = Vector2(x, y) * FIELD_CELL_SIZE + Vector2(FIELD_CELL_SIZE/2, FIELD_CELL_SIZE/2)
			field_vectors.append({
				"position": pos,
				"vector": Vector2.ZERO
			})

func _process(delta):
	if animation_playing:
		match visualization_type:
			"intro":
				update_intro_physics(delta)
			"addition":
				pass  # Static visualization
			"multiplication":
				pass  # Static visualization
			"forces":
				update_forces_physics(delta)
			"fields":
				update_fields_physics(delta)

		animation_time += delta
		queue_redraw()

func set_animation_playing(playing: bool):
	animation_playing = playing

func update_intro_physics(delta):
	if particles.size() > 0:
		var center = Vector2(GRID_SIZE/2, GRID_SIZE/2)
		var radius = 100
		var angle = animation_time * 1.2

		particles[0].position = center + Vector2(cos(angle), sin(angle)) * radius
		particles[0].velocity = Vector2(-sin(angle), cos(angle)) * radius * 1.2

		if velocity_trails.size() > 0:
			var trail = velocity_trails[0]
			trail.append(particles[0].position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

func update_forces_physics(delta):
	for i in range(particles.size()):
		var particle = particles[i]
		particle.acceleration = Vector2.ZERO

		# Apply forces from attractors/repellers
		for force in forces:
			var force_dir = force.position - particle.position
			var distance = force_dir.length()

			if distance > 0 and distance < 250:
				force_dir = force_dir.normalized()
				var strength = force.strength / (distance * particle.mass)
				particle.acceleration += force_dir * strength

		# Apply gravity
		particle.acceleration += Vector2(0, 50)

		# Boundary forces
		var margin = 50
		if particle.position.x < margin:
			particle.acceleration.x += 3.0 * (margin - particle.position.x) / margin
		elif particle.position.x > GRID_SIZE - margin:
			particle.acceleration.x -= 3.0 * (particle.position.x - (GRID_SIZE - margin)) / margin
		if particle.position.y < margin:
			particle.acceleration.y += 3.0 * (margin - particle.position.y) / margin
		elif particle.position.y > GRID_SIZE - margin:
			particle.acceleration.y -= 3.0 * (particle.position.y - (GRID_SIZE - margin)) / margin

		# Update physics
		particle.velocity += particle.acceleration * delta
		particle.position += particle.velocity * delta
		particle.velocity *= 0.995  # Damping

		# Store trail
		var trail = velocity_trails[i]
		if trail.size() == 0 or trail[trail.size() - 1].distance_to(particle.position) > 5:
			trail.append(particle.position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

func update_fields_physics(delta):
	var field_type = int(animation_time / 6) % 3

	# Update vector field
	for field_vec in field_vectors:
		var pos = field_vec.position
		var center = Vector2(GRID_SIZE/2, GRID_SIZE/2)
		var offset = pos - center

		match field_type:
			0:  # Circular field
				field_vec.vector = Vector2(-offset.y, offset.x).normalized() * 25
			1:  # Noise field
				var noise_x = sin(pos.x * 0.02 + animation_time) * cos(pos.y * 0.02)
				var noise_y = cos(pos.x * 0.02) * sin(pos.y * 0.02 + animation_time)
				field_vec.vector = Vector2(noise_x, noise_y) * 25
			2:  # Sink/source field
				var dist = offset.length()
				if dist > 0:
					var direction = offset.normalized()
					var strength = sin(animation_time * 0.5) * 35
					field_vec.vector = direction * strength

	# Move particles based on field
	for i in range(particles.size()):
		var particle = particles[i]
		particle.acceleration = Vector2.ZERO

		var field_force = Vector2.ZERO
		var total_weight = 0

		for field_vec in field_vectors:
			var dist = particle.position.distance_to(field_vec.position)
			if dist < FIELD_CELL_SIZE * 2.5:
				var weight = 1.0 / max(0.1, dist)
				field_force += field_vec.vector * weight
				total_weight += weight

		if total_weight > 0:
			field_force /= total_weight
			particle.acceleration = field_force / particle.mass

		# Boundary forces
		var margin = 50
		if particle.position.x < margin:
			particle.acceleration.x += 2.0 * (margin - particle.position.x) / margin
		elif particle.position.x > GRID_SIZE - margin:
			particle.acceleration.x -= 2.0 * (particle.position.x - (GRID_SIZE - margin)) / margin
		if particle.position.y < margin:
			particle.acceleration.y += 2.0 * (margin - particle.position.y) / margin
		elif particle.position.y > GRID_SIZE - margin:
			particle.acceleration.y -= 2.0 * (particle.position.y - (GRID_SIZE - margin)) / margin

		particle.velocity += particle.acceleration * delta
		particle.velocity *= 0.98
		particle.position += particle.velocity * delta

		# Store trail
		var trail = velocity_trails[i]
		if trail.size() == 0 or trail[trail.size() - 1].distance_to(particle.position) > 5:
			trail.append(particle.position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

func _draw():
	if size.x < 10 or size.y < 10:
		return

	var center_x = size.x / 2
	var center_y = size.y / 2

	match visualization_type:
		"intro":
			draw_intro_visualization(center_x, center_y)
		"addition":
			draw_addition_visualization(center_x, center_y)
		"multiplication":
			draw_multiplication_visualization(center_x, center_y)
		"forces":
			draw_forces_visualization(center_x, center_y)
		"fields":
			draw_fields_visualization(center_x, center_y)

func draw_intro_visualization(center_x, center_y):
	var grid_offset_x = center_x - float(GRID_SIZE) / 2.0
	var grid_offset_y = center_y - float(GRID_SIZE) / 2.0

	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	draw_grid(grid_offset_x, grid_offset_y)
	draw_axes(grid_offset_x, grid_offset_y)

	if particles.size() > 0:
		var particle = particles[0]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)
		var vel = particle.velocity

		# Draw trail
		if velocity_trails.size() > 0 and velocity_trails[0].size() > 1:
			var points = PackedVector2Array()
			for point in velocity_trails[0]:
				points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
			draw_polyline(points, COLOR_TERTIARY, 2)

		# Draw position vector from origin
		var origin = Vector2(grid_offset_x + GRID_SIZE/2, grid_offset_y + GRID_SIZE/2)
		draw_vector(origin, pos - origin, COLOR_HIGHLIGHT, 3)

		# Draw velocity vector
		draw_vector(pos, vel * 0.4, COLOR_PRIMARY, 2)

		# Draw particle
		draw_circle(pos, BALL_RADIUS, particle.color)

func draw_addition_visualization(center_x, center_y):
	var grid_offset_x = center_x - float(GRID_SIZE) / 2.0
	var grid_offset_y = center_y - float(GRID_SIZE) / 2.0

	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	draw_grid(grid_offset_x, grid_offset_y)

	var origin = Vector2(grid_offset_x + GRID_SIZE * 0.3, grid_offset_y + GRID_SIZE * 0.6)

	var angle1 = sin(animation_time * 0.5) * 0.5 + 0.8
	var angle2 = cos(animation_time * 0.4) * 0.6 - 0.3
	var vector1 = Vector2(cos(angle1), sin(angle1)) * 90
	var vector2 = Vector2(cos(angle2), sin(angle2)) * 75
	var vector_sum = vector1 + vector2

	# Head-to-tail method
	draw_vector(origin, vector1, COLOR_PRIMARY, 3)
	draw_vector(origin + vector1, vector2, COLOR_SECONDARY, 3)
	draw_vector(origin, vector_sum, COLOR_HIGHLIGHT, 3, true)

func draw_multiplication_visualization(center_x, center_y):
	var grid_offset_x = center_x - float(GRID_SIZE) / 2.0
	var grid_offset_y = center_y - float(GRID_SIZE) / 2.0

	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	draw_grid(grid_offset_x, grid_offset_y)

	var origin = Vector2(grid_offset_x + GRID_SIZE * 0.25, grid_offset_y + GRID_SIZE * 0.5)
	var angle = sin(animation_time * 0.3) * 0.5 + 0.3
	var base_vector = Vector2(cos(angle), sin(angle)) * 50

	# Draw base vector
	draw_vector(origin, base_vector, COLOR_PRIMARY, 3)

	# Draw scaled vectors
	var scales = [0.5, 1.5, 2.5]
	var colors = [COLOR_SECONDARY, COLOR_TERTIARY, COLOR_HIGHLIGHT]

	for i in range(scales.size()):
		var scaled = base_vector * scales[i]
		draw_vector(origin, scaled, colors[i], 2, true)

func draw_forces_visualization(center_x, center_y):
	var grid_offset_x = center_x - float(GRID_SIZE) / 2.0
	var grid_offset_y = center_y - float(GRID_SIZE) / 2.0

	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	draw_grid(grid_offset_x, grid_offset_y)

	# Draw force points
	for force in forces:
		var force_pos = Vector2(grid_offset_x + force.position.x, grid_offset_y + force.position.y)
		draw_circle(force_pos, 180, Color(force.color.r, force.color.g, force.color.b, 0.08))
		draw_circle(force_pos, 12, force.color)

	# Draw trails
	for i in range(velocity_trails.size()):
		var trail = velocity_trails[i]
		if trail.size() > 1:
			var points = PackedVector2Array()
			for point in trail:
				points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
			draw_polyline(points, Color(particles[i].color.r, particles[i].color.g, particles[i].color.b, 0.4), 2)

	# Draw particles
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)

		if particle.velocity.length() > 1:
			draw_vector(pos, particle.velocity * 0.4, COLOR_PRIMARY, 2)

		draw_circle(pos, BALL_RADIUS * sqrt(particle.mass), particle.color)

func draw_fields_visualization(center_x, center_y):
	var grid_offset_x = center_x - float(GRID_SIZE) / 2.0
	var grid_offset_y = center_y - float(GRID_SIZE) / 2.0

	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)

	# Draw vector field
	for field_vec in field_vectors:
		var pos = Vector2(grid_offset_x + field_vec.position.x, grid_offset_y + field_vec.position.y)
		var vector = field_vec.vector

		if vector.length() > 1:
			var magnitude = clamp(vector.length() / 35, 0, 1)
			var color = COLOR_PRIMARY.lerp(COLOR_HIGHLIGHT, magnitude)
			color.a = 0.6
			draw_vector(pos, vector * 0.7, color, 1)

	# Draw trails
	for i in range(velocity_trails.size()):
		var trail = velocity_trails[i]
		if trail.size() > 1:
			var points = PackedVector2Array()
			for point in trail:
				points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
			draw_polyline(points, Color(particles[i].color.r, particles[i].color.g, particles[i].color.b, 0.4), 2)

	# Draw particles
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)
		draw_circle(pos, BALL_RADIUS * sqrt(particle.mass), particle.color)

func draw_grid(offset_x, offset_y):
	var grid_color = Color(1, 1, 1, 0.08)
	var step = 40

	for x in range(0, GRID_SIZE + 1, step):
		draw_line(
			Vector2(offset_x + x, offset_y),
			Vector2(offset_x + x, offset_y + GRID_SIZE),
			grid_color
		)

	for y in range(0, GRID_SIZE + 1, step):
		draw_line(
			Vector2(offset_x, offset_y + y),
			Vector2(offset_x + GRID_SIZE, offset_y + y),
			grid_color
		)

func draw_axes(offset_x, offset_y):
	draw_line(
		Vector2(offset_x, offset_y + GRID_SIZE / 2),
		Vector2(offset_x + GRID_SIZE, offset_y + GRID_SIZE / 2),
		Color(1, 1, 1, 0.2),
		2
	)
	draw_line(
		Vector2(offset_x + GRID_SIZE / 2, offset_y),
		Vector2(offset_x + GRID_SIZE / 2, offset_y + GRID_SIZE),
		Color(1, 1, 1, 0.2),
		2
	)

func draw_vector(start_pos, vector, color, width, dashed = false):
	if vector.length() < 0.1:
		return

	var end_pos = start_pos + vector

	if dashed:
		draw_dashed_line(start_pos, end_pos, color, width)
	else:
		draw_line(start_pos, end_pos, color, width)

	# Draw arrowhead
	var arrow_size = max(6, width * 2.5)
	var direction = vector.normalized()
	var perpendicular = Vector2(-direction.y, direction.x)

	var arrow_point1 = end_pos - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_point2 = end_pos - direction * arrow_size - perpendicular * arrow_size * 0.5

	var points = PackedVector2Array([end_pos, arrow_point1, arrow_point2])
	draw_colored_polygon(points, color)

func draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, dash_length: float = 8.0, gap_length: float = 4.0, cap_start: bool = false, cap_end: bool = false):
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	var current_distance = 0

	while current_distance < distance:
		var start = from + direction * current_distance
		var end = from + direction * min(current_distance + dash_length, distance)
		draw_line(start, end, color, width)
		current_distance += dash_length + gap_length
