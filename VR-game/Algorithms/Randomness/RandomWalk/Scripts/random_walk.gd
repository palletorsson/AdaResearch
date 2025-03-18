extends Node
class_name RandomWalk

# ===========================
# ENUM FOR RANDOM WALK TYPES
# ===========================
enum WalkType {
	SIMPLE,
	DIAGONAL,
	BROWNIAN,
	FRACTAL,
	FIBONACCI_SPIRAL,
	SELF_AVOIDING,
	LEVY_FLIGHT
}

# ===========================
# MAIN FUNCTION
# ===========================
static func perform_random_walk(
	img: Image,
	current_position: Vector2,
	area_size: int,
	width: int,
	height: int,
	walk_type: WalkType,
	visited_positions: Dictionary = {},
	pixel_color: Color = Color.PINK
) -> Vector2:
	var old_position = current_position

	# Choose the appropriate random walk function
	match walk_type:
		WalkType.SIMPLE:
			current_position = _simple_random_walk(current_position, area_size, width, height)
		WalkType.DIAGONAL:
			current_position = _diagonal_random_walk(current_position, area_size, width, height)
		WalkType.BROWNIAN:
			current_position = _brownian_motion(current_position, area_size, width, height)
		WalkType.FRACTAL:
			current_position = _fractal_walk(img, current_position, area_size, width, height)
		WalkType.FIBONACCI_SPIRAL:
			current_position = _fibonacci_spiral_walk(current_position, area_size, width, height)
		WalkType.SELF_AVOIDING:
			current_position = _self_avoiding_walk(current_position, area_size, width, height, visited_positions)
		WalkType.LEVY_FLIGHT:
			current_position = _levy_flight_walk(current_position, area_size, width, height)

	# Draw a line from the old position to the new position
	_draw_line_on_image(img, old_position, current_position, pixel_color)

	return current_position

# ===========================
# RANDOM WALK IMPLEMENTATIONS
# ===========================

# 1. Simple Random Walk (Cardinal Directions)
static func _simple_random_walk(pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var direction = directions[randi() % directions.size()]
	return _update_position(pos, direction * area_size, width, height)

# 2. Diagonal Random Walk (Includes Diagonal Moves)
static func _diagonal_random_walk(pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	var directions = [
		Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)
	]
	var direction = directions[randi() % directions.size()]
	return _update_position(pos, direction * area_size, width, height)

# 3. Brownian Motion (Random Angle, Continuous Steps)
static func _brownian_motion(pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	var angle = randf() * TAU
	var step_size = randf_range(0.5, area_size)
	var direction = Vector2(cos(angle), sin(angle)) * step_size
	return _update_position(pos, direction, width, height)

# 4. Fractal Walk (Branching, Like a Tree)
static func _fractal_walk(img: Image, pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	if randf() < 0.3:  # 30% chance to branch
		for i in range(2):  # Create two branches
			var new_pos = pos + directions[randi() % directions.size()] * area_size
			perform_random_walk(img, new_pos, area_size, width, height, WalkType.FRACTAL)
	else:
		pos += directions[randi() % directions.size()] * area_size
	return _update_position(pos, Vector2.ZERO, width, height)

# 5. Fibonacci Spiral Walk (Golden Ratio Expansion)
static var fib_index := 0
static var fib_sequence := [1, 1]  # Start Fibonacci sequence

static func _fibonacci_spiral_walk(pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	if fib_index >= fib_sequence.size():
		fib_sequence.append(fib_sequence[-1] + fib_sequence[-2])
	var step_size = fib_sequence[fib_index] * area_size
	fib_index += 1
	var golden_angle = 137.5 * PI / 180.0
	var direction = Vector2(cos(golden_angle * fib_index), sin(golden_angle * fib_index)) * step_size
	return _update_position(pos, direction, width, height)

# 6. Self-Avoiding Walk
static func _self_avoiding_walk(pos: Vector2, area_size: int, width: int, height: int, visited_positions: Dictionary) -> Vector2:
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()
	var available_moves = []
	for direction in directions:
		var new_pos = pos + direction * area_size
		new_pos.x = clamp(new_pos.x, 0, width - 1)
		new_pos.y = clamp(new_pos.y, 0, height - 1)
		var key = str(int(new_pos.x)) + "_" + str(int(new_pos.y))
		if not visited_positions.has(key):
			available_moves.append(direction)

	if available_moves.size() > 0:
		var chosen_direction = available_moves[randi() % available_moves.size()]
		pos = _update_position(pos, chosen_direction * area_size, width, height)
	else:
		# If no available move, fallback to a simple random walk
		pos = _simple_random_walk(pos, area_size, width, height)

	# Mark new position as visited
	var pos_key = str(int(pos.x)) + "_" + str(int(pos.y))
	visited_positions[pos_key] = true
	return pos

# 7. Lévy Flight Walk
static func _levy_flight_walk(pos: Vector2, area_size: int, width: int, height: int) -> Vector2:
	var beta = 1.5  # Lévy exponent (typical range: 1 < beta < 3)
	var min_step = float(area_size)
	var max_step = float(area_size * 10)

	var u = randf()
	# Inverse transform sampling for a power-law distribution
	var step_size = min_step / pow(u, 1.0 / (beta - 1.0))
	step_size = clamp(step_size, min_step, max_step)

	var angle = randf() * TAU
	var direction = Vector2(cos(angle), sin(angle)) * step_size
	return _update_position(pos, direction, width, height)

# ===========================
# HELPER FUNCTION TO UPDATE POSITION
# ===========================
static func _update_position(old_pos: Vector2, movement: Vector2, width: int, height: int) -> Vector2:
	var new_pos = old_pos + movement
	new_pos.x = clamp(new_pos.x, 0, width - 1)
	new_pos.y = clamp(new_pos.y, 0, height - 1)
	return new_pos

# ===========================
# BRESENHAM LINE-DRAWING
# ===========================
static func _draw_line_on_image(img: Image, start: Vector2, end: Vector2, color: Color) -> void:
	var x0 = int(start.x)
	var y0 = int(start.y)
	var x1 = int(end.x)
	var y1 = int(end.y)

	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		img.set_pixel(x0, y0, color)

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
