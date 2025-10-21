# RandomWalkVisualization.gd
# Visualization for Random Walk algorithm
extends AlgorithmVisualizationBase

# Random walk state
var walker_position: Vector2 = Vector2.ZERO
var trail_points: Array[Vector2] = []
var max_trail_length: int = 100
var step_size: float = 10.0
var grid_size: float = 20.0

# Visualization parameters
var show_grid: bool = true
var show_trail: bool = true
var trail_color: Color = Color(0.3, 0.8, 0.9, 1.0)
var walker_color: Color = Color(1.0, 0.5, 0.2, 1.0)
var walker_radius: float = 8.0

func on_reset() -> void:
	"""Reset random walk to center"""
	var center = get_center()
	walker_position = center
	trail_points.clear()
	trail_points.append(walker_position)

func on_periodic_update() -> void:
	"""Take a random walk step"""
	if not animation_playing:
		return

	# Random direction (-1, 0, 1 for x and y)
	var direction = Vector2(
		rng.randi_range(-1, 1),
		rng.randi_range(-1, 1)
	)

	# Move walker
	walker_position += direction * step_size

	# Keep within bounds with wrapping
	if walker_position.x < 0:
		walker_position.x = size.x
	elif walker_position.x > size.x:
		walker_position.x = 0

	if walker_position.y < 0:
		walker_position.y = size.y
	elif walker_position.y > size.y:
		walker_position.y = 0

	# Add to trail
	trail_points.append(walker_position)

	# Limit trail length
	if trail_points.size() > max_trail_length:
		trail_points.pop_front()

func draw_visualization() -> void:
	"""Draw the random walk visualization"""
	var center = get_center()

	# Draw grid
	if show_grid:
		draw_grid(grid_size, Color(0.15, 0.15, 0.2, 0.5))

	# Draw center point
	draw_circle(center, 3.0, Color(0.5, 0.5, 0.5, 0.5))

	# Draw trail
	if show_trail and trail_points.size() > 1:
		for i in range(trail_points.size() - 1):
			var alpha = float(i) / trail_points.size()
			var color = trail_color
			color.a = alpha * 0.7
			draw_line(trail_points[i], trail_points[i + 1], color, 2.0)

	# Draw walker
	draw_circle(walker_position, walker_radius, walker_color)
	draw_circle_outline(walker_position, walker_radius, walker_color.lightened(0.3), 16, 2.0)

	# Draw info
	draw_label("Steps: %d" % trail_points.size(), Vector2(10, 20), 14, Color.WHITE)
	draw_label("Position: (%.0f, %.0f)" % [walker_position.x, walker_position.y], Vector2(10, 40), 12, Color(0.8, 0.8, 0.8))

	# Draw distance from center
	var distance = walker_position.distance_to(center)
	draw_label("Distance from center: %.1f" % distance, Vector2(10, 60), 12, Color(0.8, 0.8, 0.8))
