# ForcesVisualizationControl.gd
# Physics simulation visualizations — moved from VectorsVisualizationControl.gd
# Covers: intro (particle motion), addition (head-to-tail), multiplication (scaling/normalization),
#          forces (attractors/repellers), fields (circular/noise/sink-source)
extends Control

var visualization_type = "intro"
var animation_time = 0.0
var animation_speed = 2.0
var animation_playing = true

# Physics simulation objects
var particles = []
var forces = []
var velocity_trails = []
var field_vectors = []

# Constants for visualization
const GRID_SIZE = 400
const VECTOR_SCALE = 40
const BALL_RADIUS = 10
const FORCE_STRENGTH = 200
const DISTANCE_THRESHOLD = 80
const MAX_TRAIL_POINTS = 50
const FIELD_GRID_CELLS = 15
const FIELD_CELL_SIZE = 30
const ARROW_SIZE = 10

# Visual styling constants
const COLOR_PRIMARY = Color(0.2, 0.6, 0.8, 0.8)
const COLOR_SECONDARY = Color(0.8, 0.4, 0.2, 0.8)
const COLOR_TERTIARY = Color(0.4, 0.8, 0.4, 0.8)
const COLOR_HIGHLIGHT = Color(1.0, 0.9, 0.2, 0.8)
const COLOR_NEUTRAL = Color(0.7, 0.7, 0.7, 0.8)
const BG_COLOR = Color(0.15, 0.15, 0.2)

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	_initialize_trails()
	_initialize_field_vectors()

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
				update_addition_physics(delta)
			"multiplication":
				update_multiplication_physics(delta)
			"forces":
				update_forces_physics(delta)
			"fields":
				update_fields_physics(delta)
		animation_time += delta * animation_speed
		queue_redraw()

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

# Physics update functions
func update_intro_physics(_delta):
	var time_factor = animation_time * 0.5
	if particles.size() > 0:
		var center = Vector2(GRID_SIZE/2, GRID_SIZE/2)
		var radius = 100
		var angle = time_factor * 1.5
		particles[0].position = center + Vector2(cos(angle), sin(angle)) * radius
		particles[0].velocity = Vector2(-sin(angle), cos(angle)) * radius * 1.5
		if velocity_trails.size() > 0:
			var trail = velocity_trails[0]
			trail.append(particles[0].position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

func update_addition_physics(_delta):
	pass

func update_multiplication_physics(_delta):
	pass

func update_forces_physics(delta):
	delta *= animation_speed
	for i in range(particles.size()):
		var particle = particles[i]
		particle.acceleration = Vector2.ZERO
		for force in forces:
			var force_dir = force.position - particle.position
			var distance = force_dir.length()
			if distance > 0 and distance < 200:
				force_dir = force_dir.normalized()
				var strength = force.strength / (distance * particle.mass)
				particle.acceleration += force_dir * strength
		particle.acceleration += Vector2(0, 98)
		var boundary_force = 5.0
		var margin = 50
		if particle.position.x < margin:
			particle.acceleration.x += boundary_force * (margin - particle.position.x) / margin
		elif particle.position.x > GRID_SIZE - margin:
			particle.acceleration.x -= boundary_force * (particle.position.x - (GRID_SIZE - margin)) / margin
		if particle.position.y < margin:
			particle.acceleration.y += boundary_force * (margin - particle.position.y) / margin
		elif particle.position.y > GRID_SIZE - margin:
			particle.acceleration.y -= boundary_force * (particle.position.y - (GRID_SIZE - margin)) / margin
		particle.velocity += particle.acceleration * delta
		particle.position += particle.velocity * delta
		particle.velocity *= 0.99
		var trail = velocity_trails[i]
		if trail.size() == 0 or trail[trail.size() - 1].distance_to(particle.position) > 5:
			trail.append(particle.position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

func update_fields_physics(delta):
	delta *= animation_speed
	var field_type = int(animation_time / 5) % 3
	for field_vec in field_vectors:
		var pos = field_vec.position
		var center = Vector2(GRID_SIZE/2, GRID_SIZE/2)
		var offset = pos - center
		match field_type:
			0:
				field_vec.vector = Vector2(-offset.y, offset.x).normalized() * 20
			1:
				var noise_x = sin(pos.x * 0.02 + animation_time) * cos(pos.y * 0.02)
				var noise_y = cos(pos.x * 0.02) * sin(pos.y * 0.02 + animation_time)
				field_vec.vector = Vector2(noise_x, noise_y) * 20
			2:
				var dist = offset.length()
				if dist > 0:
					var direction = offset.normalized()
					var strength = sin(animation_time) * 30
					field_vec.vector = direction * strength
	for i in range(particles.size()):
		var particle = particles[i]
		particle.acceleration = Vector2.ZERO
		var field_force = Vector2.ZERO
		var total_weight = 0
		for field_vec in field_vectors:
			var dist = particle.position.distance_to(field_vec.position)
			if dist < FIELD_CELL_SIZE * 2:
				var weight = 1.0 / max(0.1, dist)
				field_force += field_vec.vector * weight
				total_weight += weight
		if total_weight > 0:
			field_force /= total_weight
			particle.acceleration = field_force / particle.mass
		var boundary_force = 1.0
		var margin = 50
		if particle.position.x < margin:
			particle.acceleration.x += boundary_force * (margin - particle.position.x) / margin
		elif particle.position.x > GRID_SIZE - margin:
			particle.acceleration.x -= boundary_force * (particle.position.x - (GRID_SIZE - margin)) / margin
		if particle.position.y < margin:
			particle.acceleration.y += boundary_force * (margin - particle.position.y) / margin
		elif particle.position.y > GRID_SIZE - margin:
			particle.acceleration.y -= boundary_force * (particle.position.y - (GRID_SIZE - margin)) / margin
		particle.velocity += particle.acceleration * delta
		particle.velocity *= 0.98
		particle.position += particle.velocity * delta
		if particle.position.x < 0: particle.position.x = GRID_SIZE
		if particle.position.x > GRID_SIZE: particle.position.x = 0
		if particle.position.y < 0: particle.position.y = GRID_SIZE
		if particle.position.y > GRID_SIZE: particle.position.y = 0
		var trail = velocity_trails[i]
		if trail.size() == 0 or trail[trail.size() - 1].distance_to(particle.position) > 5:
			trail.append(particle.position)
			if trail.size() > MAX_TRAIL_POINTS:
				trail.remove_at(0)

# Visualization drawing functions
func draw_intro_visualization(center_x, center_y):
	var grid_offset_x = center_x - GRID_SIZE / 2
	var grid_offset_y = center_y - GRID_SIZE / 2
	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	_draw_bg_grid(grid_offset_x, grid_offset_y)
	_draw_coord_axes(grid_offset_x, grid_offset_y)
	if particles.size() > 0:
		var particle = particles[0]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)
		var vel = particle.velocity
		if velocity_trails.size() > 0:
			var trail = velocity_trails[0]
			if trail.size() > 1:
				var points = PackedVector2Array()
				for point in trail:
					points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
				draw_polyline(points, COLOR_TERTIARY, 2)
		var origin_x = grid_offset_x + GRID_SIZE / 2
		var origin_y = grid_offset_y + GRID_SIZE / 2
		draw_line(Vector2(origin_x, origin_y), Vector2(pos.x, origin_y), COLOR_PRIMARY, 2)
		draw_line(Vector2(pos.x, origin_y), pos, COLOR_SECONDARY, 2)
		draw_vector(Vector2(origin_x, origin_y), pos - Vector2(origin_x, origin_y), COLOR_HIGHLIGHT, 3)
		draw_vector(pos, vel * 0.5, COLOR_PRIMARY, 2)
		draw_circle(pos, BALL_RADIUS, particle.color)
		draw_string_outlined(
			Vector2(origin_x + (pos.x - origin_x) / 2, origin_y - 20),
			"x: " + str(int(particle.position.x - GRID_SIZE / 2)),
			COLOR_PRIMARY, Color.BLACK, 1)
		draw_string_outlined(
			Vector2(pos.x + 10, origin_y + (pos.y - origin_y) / 2),
			"y: " + str(int(particle.position.y - GRID_SIZE / 2)),
			COLOR_SECONDARY, Color.BLACK, 1)
		draw_string_outlined(
			pos + Vector2(15, 0),
			"Velocity: (" + str(int(vel.x)) + ", " + str(int(vel.y)) + ")",
			COLOR_PRIMARY, Color.BLACK, 1)

func draw_addition_visualization(center_x, center_y):
	var grid_offset_x = center_x - GRID_SIZE / 2
	var grid_offset_y = center_y - GRID_SIZE / 2
	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	_draw_bg_grid(grid_offset_x, grid_offset_y)
	var origin = Vector2(grid_offset_x + GRID_SIZE * 0.3, grid_offset_y + GRID_SIZE * 0.7)
	var time_factor = animation_time * 0.5
	var angle1 = sin(time_factor) * 0.5 + 0.8
	var angle2 = cos(time_factor * 0.7) * 0.6 - 0.3
	var length1 = 80 + sin(time_factor * 1.3) * 20
	var length2 = 70 + cos(time_factor * 0.9) * 25
	var vector1 = Vector2(cos(angle1), sin(angle1)) * length1
	var vector2 = Vector2(cos(angle2), sin(angle2)) * length2
	var vector_sum = vector1 + vector2
	draw_vector(origin, vector1, COLOR_PRIMARY, 3)
	draw_vector(origin + vector1, vector2, COLOR_SECONDARY, 3)
	draw_vector(origin, vector_sum, COLOR_HIGHLIGHT, 3, true)
	var origin2 = Vector2(grid_offset_x + GRID_SIZE * 0.7, grid_offset_y + GRID_SIZE * 0.3)
	draw_vector(origin2, vector1, COLOR_PRIMARY, 3)
	draw_vector(origin2, vector2, COLOR_SECONDARY, 3)
	draw_line(origin2 + vector1, origin2 + vector1 + vector2, Color(1, 1, 1, 0.5), 1)
	draw_line(origin2 + vector2, origin2 + vector1 + vector2, Color(1, 1, 1, 0.5), 1)
	draw_vector(origin2, vector_sum, COLOR_HIGHLIGHT, 3, true)
	draw_string_outlined(origin + vector1 / 2 - Vector2(0, 15), "A", COLOR_PRIMARY, Color.BLACK, 1)
	draw_string_outlined(origin + vector1 + vector2 / 2 - Vector2(15, 0), "B", COLOR_SECONDARY, Color.BLACK, 1)
	draw_string_outlined(origin + vector_sum / 2 + Vector2(10, 10), "A + B", COLOR_HIGHLIGHT, Color.BLACK, 1)
	draw_string_outlined(origin2 + vector1 / 2 - Vector2(0, 15), "A", COLOR_PRIMARY, Color.BLACK, 1)
	draw_string_outlined(origin2 + vector2 / 2 - Vector2(15, 0), "B", COLOR_SECONDARY, Color.BLACK, 1)
	draw_string_outlined(origin2 + vector_sum / 2 + Vector2(10, 10), "A + B", COLOR_HIGHLIGHT, Color.BLACK, 1)
	draw_string_outlined(Vector2(origin.x, origin.y - 100), "Head-to-Tail Method", Color.WHITE, Color.BLACK, 1)
	draw_string_outlined(Vector2(origin2.x, origin2.y - 100), "Parallelogram Rule", Color.WHITE, Color.BLACK, 1)

func draw_multiplication_visualization(center_x, center_y):
	var grid_offset_x = center_x - GRID_SIZE / 2
	var grid_offset_y = center_y - GRID_SIZE / 2
	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	_draw_bg_grid(grid_offset_x, grid_offset_y)
	var origin = Vector2(grid_offset_x + GRID_SIZE * 0.2, grid_offset_y + GRID_SIZE * 0.5)
	var time_factor = animation_time * 0.3
	var angle = sin(time_factor) * 0.5 + 0.3
	var base_vector = Vector2(cos(angle), sin(angle)) * 60
	draw_vector(origin, base_vector, COLOR_PRIMARY, 3)
	var scale_factors = [0.5, 1.5, 2.0]
	var colors = [COLOR_SECONDARY, COLOR_TERTIARY, COLOR_HIGHLIGHT]
	for i in range(scale_factors.size()):
		var factor = scale_factors[i]
		var scaled_vector = base_vector * factor
		var color = colors[i]
		draw_vector(origin, scaled_vector, color, 2, true)
		draw_string_outlined(
			origin + scaled_vector + Vector2(10, -10 + i * 20),
			str(factor) + " x v", color, Color.BLACK, 1)
	var origin2 = Vector2(grid_offset_x + GRID_SIZE * 0.7, grid_offset_y + GRID_SIZE * 0.5)
	var angle2 = cos(time_factor * 0.7) * 0.8 + 0.6
	var length = 40 + sin(time_factor) * 30
	var vector_to_normalize = Vector2(cos(angle2), sin(angle2)) * length
	var normalized_vector = vector_to_normalize.normalized() * 40
	draw_vector(origin2, vector_to_normalize, COLOR_PRIMARY, 3)
	draw_vector(origin2, normalized_vector, COLOR_HIGHLIGHT, 2, true)
	draw_string_outlined(origin2 + vector_to_normalize / 2 + Vector2(10, 10), "v", COLOR_PRIMARY, Color.BLACK, 1)
	draw_string_outlined(origin2 + normalized_vector / 2 - Vector2(0, 15), "v.normalized()", COLOR_HIGHLIGHT, Color.BLACK, 1)
	draw_string_outlined(Vector2(origin.x, origin.y - 80), "Scalar Multiplication", Color.WHITE, Color.BLACK, 1)
	draw_string_outlined(Vector2(origin2.x, origin2.y - 80), "Normalization", Color.WHITE, Color.BLACK, 1)
	var dot_origin = Vector2(grid_offset_x + GRID_SIZE * 0.5, grid_offset_y + GRID_SIZE * 0.2)
	var angle_a = time_factor * 0.5
	var angle_b = angle_a + sin(time_factor) * PI * 0.4
	var vector_a = Vector2(cos(angle_a), sin(angle_a)) * 60
	var vector_b = Vector2(cos(angle_b), sin(angle_b)) * 60
	var dot_product = vector_a.dot(vector_b)
	var angle_between = acos(clamp(dot_product / (vector_a.length() * vector_b.length()), -1, 1))
	draw_vector(dot_origin, vector_a, COLOR_PRIMARY, 3)
	draw_vector(dot_origin, vector_b, COLOR_SECONDARY, 3)
	var radius = 30
	var start_angle = atan2(vector_a.y, vector_a.x)
	var end_angle = atan2(vector_b.y, vector_b.x)
	if abs(end_angle - start_angle) > PI:
		if end_angle > start_angle:
			end_angle -= 2 * PI
		else:
			start_angle -= 2 * PI
	draw_arc(dot_origin, radius, min(start_angle, end_angle), max(start_angle, end_angle), 32, Color(1, 1, 1, 0.5), 2)
	draw_string_outlined(dot_origin + vector_a / 2 - Vector2(0, 15), "A", COLOR_PRIMARY, Color.BLACK, 1)
	draw_string_outlined(dot_origin + vector_b / 2 + Vector2(15, 0), "B", COLOR_SECONDARY, Color.BLACK, 1)
	draw_string_outlined(dot_origin + Vector2(0, -40), "Dot Product: " + str(snapped(dot_product, 0.1)), COLOR_HIGHLIGHT, Color.BLACK, 1)
	draw_string_outlined(dot_origin + Vector2(0, -60), "Angle: " + str(snapped(rad_to_deg(angle_between), 0.1)) + " deg", COLOR_HIGHLIGHT, Color.BLACK, 1)

func draw_forces_visualization(center_x, center_y):
	var grid_offset_x = center_x - GRID_SIZE / 2
	var grid_offset_y = center_y - GRID_SIZE / 2
	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	_draw_bg_grid(grid_offset_x, grid_offset_y)
	for force in forces:
		var force_pos = Vector2(grid_offset_x + force.position.x, grid_offset_y + force.position.y)
		draw_circle(force_pos, 200, Color(force.color.r, force.color.g, force.color.b, 0.1))
		draw_circle(force_pos, 15, force.color)
		var label = "Attractor" if force.strength > 0 else "Repeller"
		draw_string_outlined(force_pos + Vector2(-30, -25), label, Color.WHITE, Color.BLACK, 1)
	for i in range(velocity_trails.size()):
		var trail = velocity_trails[i]
		if trail.size() > 1:
			var points = PackedVector2Array()
			for point in trail:
				points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
			var particle_color = particles[i].color
			draw_polyline(points, Color(particle_color.r, particle_color.g, particle_color.b, 0.5), 2)
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)
		if particle.velocity.length() > 1:
			draw_vector(pos, particle.velocity * 0.5, COLOR_PRIMARY, 2)
		if particle.acceleration.length() > 1:
			draw_vector(pos, particle.acceleration * 5, COLOR_SECONDARY, 2)
		draw_circle(pos, BALL_RADIUS * sqrt(particle.mass), particle.color)
	var legend_x = grid_offset_x + 20
	var legend_y = grid_offset_y + 20
	draw_line(Vector2(legend_x, legend_y), Vector2(legend_x + 30, legend_y), COLOR_PRIMARY, 2)
	draw_string_outlined(Vector2(legend_x + 40, legend_y + 5), "Velocity", COLOR_PRIMARY, Color.BLACK, 1)
	draw_line(Vector2(legend_x, legend_y + 25), Vector2(legend_x + 30, legend_y + 25), COLOR_SECONDARY, 2)
	draw_string_outlined(Vector2(legend_x + 40, legend_y + 30), "Acceleration", COLOR_SECONDARY, Color.BLACK, 1)
	draw_string_outlined(Vector2(grid_offset_x + GRID_SIZE / 2 - 70, grid_offset_y + 20), "Forces and Motion", Color.WHITE, Color.BLACK, 1)

func draw_fields_visualization(center_x, center_y):
	var grid_offset_x = center_x - GRID_SIZE / 2
	var grid_offset_y = center_y - GRID_SIZE / 2
	draw_rect(Rect2(grid_offset_x, grid_offset_y, GRID_SIZE, GRID_SIZE), BG_COLOR, true)
	var field_type = int(animation_time / 5) % 3
	var field_name = ""
	match field_type:
		0: field_name = "Circular Field"
		1: field_name = "Noise Field"
		2: field_name = "Sink/Source Field"
	draw_string_outlined(Vector2(grid_offset_x + GRID_SIZE / 2 - 70, grid_offset_y + 20), field_name, Color.WHITE, Color.BLACK, 1)
	for field_vec in field_vectors:
		var pos = Vector2(grid_offset_x + field_vec.position.x, grid_offset_y + field_vec.position.y)
		var vector = field_vec.vector
		if vector.length() > 1:
			var magnitude = clamp(vector.length() / 30, 0, 1)
			var color = COLOR_PRIMARY.lerp(COLOR_HIGHLIGHT, magnitude)
			draw_vector(pos, vector * 0.8, color, 1)
	for i in range(velocity_trails.size()):
		var trail = velocity_trails[i]
		if trail.size() > 1:
			var points = PackedVector2Array()
			for point in trail:
				points.append(Vector2(grid_offset_x + point.x, grid_offset_y + point.y))
			var particle_color = particles[i].color
			draw_polyline(points, Color(particle_color.r, particle_color.g, particle_color.b, 0.5), 2)
	for i in range(particles.size()):
		var particle = particles[i]
		var pos = Vector2(grid_offset_x + particle.position.x, grid_offset_y + particle.position.y)
		if particle.velocity.length() > 1:
			draw_vector(pos, particle.velocity * 0.5, COLOR_PRIMARY, 1)
		draw_circle(pos, BALL_RADIUS * sqrt(particle.mass), particle.color)

# Helper functions
func _draw_bg_grid(grid_offset_x, grid_offset_y):
	var grid_color = Color(1, 1, 1, 0.1)
	for x in range(0, GRID_SIZE + 1, 40):
		draw_line(Vector2(grid_offset_x + x, grid_offset_y), Vector2(grid_offset_x + x, grid_offset_y + GRID_SIZE), grid_color)
	for y in range(0, GRID_SIZE + 1, 40):
		draw_line(Vector2(grid_offset_x, grid_offset_y + y), Vector2(grid_offset_x + GRID_SIZE, grid_offset_y + y), grid_color)

func _draw_coord_axes(grid_offset_x, grid_offset_y):
	draw_line(
		Vector2(grid_offset_x, grid_offset_y + GRID_SIZE / 2),
		Vector2(grid_offset_x + GRID_SIZE, grid_offset_y + GRID_SIZE / 2),
		Color(1, 1, 1, 0.3), 2)
	draw_line(
		Vector2(grid_offset_x + GRID_SIZE / 2, grid_offset_y),
		Vector2(grid_offset_x + GRID_SIZE / 2, grid_offset_y + GRID_SIZE),
		Color(1, 1, 1, 0.3), 2)
	draw_string_outlined(
		Vector2(grid_offset_x + GRID_SIZE - 20, grid_offset_y + GRID_SIZE / 2 - 10),
		"x", Color.WHITE, Color.BLACK, 1)
	draw_string_outlined(
		Vector2(grid_offset_x + GRID_SIZE / 2 + 10, grid_offset_y + 20),
		"y", Color.WHITE, Color.BLACK, 1)

func draw_vector(start_pos, vector, color, width, dashed = false):
	if vector.length() < 0.1:
		return
	var end_pos = start_pos + vector
	if dashed:
		draw_dashed_line(start_pos, end_pos, color, width)
	else:
		draw_line(start_pos, end_pos, color, width)
	var arrow_size = max(5, width * 2)
	var direction = vector.normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var arrow_point1 = end_pos - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_point2 = end_pos - direction * arrow_size - perpendicular * arrow_size * 0.5
	var points = PackedVector2Array([end_pos, arrow_point1, arrow_point2])
	draw_colored_polygon(points, color)

func draw_string_outlined(position, text, text_color, outline_color, outline_size):
	for x_offset in range(-outline_size, outline_size + 1):
		for y_offset in range(-outline_size, outline_size + 1):
			if x_offset != 0 or y_offset != 0:
				draw_string(ThemeDB.fallback_font,
					Vector2(position.x + x_offset, position.y + y_offset),
					text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, outline_color)
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_color)
