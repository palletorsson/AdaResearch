extends Node3D
class_name SimpleDiscoFloor

# Simple Disco Floor Creator - VISUAL ONLY
# Creates a clean 9x9 grid of cubes floating above the existing scene
# No music - just pure visual array learning patterns

@export var disco_enabled: bool = true
@export var pattern_duration: float = 10.0
@export var animation_speed: float = 0.05
@export var grid_size: int = 9
@export var cube_size: float = 1.0
@export var floor_height: float = -0.3
@export var cube_spacing: float = 1.0

# Our clean disco grid
var disco_cubes: Array[Node3D] = []
var disco_grid: Array[Array] = []  # 2D array [row][col]

# Game state
var current_lesson: int = 0
var lesson_time: float = 0.0
var animation_step: int = 0
var step_timer: float = 0.0

# Learning sequence
enum ArrayLesson {
	CORNER_BLINK,
	ROW_LIGHTING,
	COLUMN_LIGHTING,
	SNAKE_PATTERN,
	SPIRAL_INWARD,
	PULSE_CENTER,
	WAVE_DIAGONAL,
	DISCO_CELEBRATION
}

# Colors for each lesson
var lesson_colors: Dictionary = {
	ArrayLesson.CORNER_BLINK: Color.YELLOW,
	ArrayLesson.ROW_LIGHTING: Color.CYAN,
	ArrayLesson.COLUMN_LIGHTING: Color.MAGENTA,
	ArrayLesson.SNAKE_PATTERN: Color.GREEN,
	ArrayLesson.SPIRAL_INWARD: Color.ORANGE,
	ArrayLesson.PULSE_CENTER: Color.RED,
	ArrayLesson.WAVE_DIAGONAL: Color.BLUE,
	ArrayLesson.DISCO_CELEBRATION: Color.WHITE
}

func _ready():
	print("🕺 Creating Simple Disco Floor - Visual Only! 💃")
	
	# Ensure this node has no rotation
	self.rotation = Vector3.ZERO
	
	create_disco_floor()
	print_game_info()
	
	print("🔧 Disco floor positioned at height: ", floor_height)
	print("🔧 Grid centered at: ", self.position)

func create_disco_floor():
	"""Create a clean 9x9 grid of cubes floating above the scene"""
	disco_cubes.clear()
	disco_grid.clear()
	
	# Initialize 2D array
	disco_grid.resize(grid_size)
	for row in range(grid_size):
		disco_grid[row] = []
		disco_grid[row].resize(grid_size)
	
	# Create cubes in a perfect 9x9 grid
	for row in range(grid_size):
		for col in range(grid_size):
			var cube = create_disco_cube(row, col)
			disco_cubes.append(cube)
			disco_grid[row][col] = cube
			self.add_child(cube)
	
	print("✨ Created ", disco_cubes.size(), " disco cubes in perfect 9x9 grid!")

func create_disco_cube(row: int, col: int) -> Node3D:
	"""Create a single disco cube at grid position"""
	var cube_node = Node3D.new()
	cube_node.name = "DiscoCube_%d_%d" % [row, col]
	
	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(cube_size * 0.9, cube_size * 0.1, cube_size * 0.9)  # Thin like floor tiles
	mesh_instance.mesh = box_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK  # Start dark
	material.metallic = 0.3
	material.roughness = 0.7
	material.emission_enabled = true
	material.emission = Color.BLACK
	mesh_instance.material_override = material
	
	cube_node.add_child(mesh_instance)
	
	# Position in FLAT grid (fixed coordinate system)
	# Row = Z axis (forward/back), Col = X axis (left/right)
	var offset = (grid_size - 1) * 0.5 * cube_spacing
	var x_pos = (col * cube_spacing) - offset  # Columns go left-right (X)
	var z_pos = (row * cube_spacing) - offset  # Rows go forward-back (Z)
	var y_pos = floor_height  # Fixed height
	
	cube_node.position = Vector3(x_pos, y_pos, z_pos)
	
	# Ensure no rotation is applied
	cube_node.rotation = Vector3.ZERO
	
	return cube_node

func _process(delta):
	if not disco_enabled:
		return
	
	lesson_time += delta
	step_timer += delta
	
	# Switch lessons
	if lesson_time >= pattern_duration:
		lesson_time = 0.0
		current_lesson = (current_lesson + 1) % ArrayLesson.size()
		animation_step = 0
		step_timer = 0.0
		clear_all_cubes()
		print_current_lesson()
	
	# Run current lesson
	match current_lesson:
		ArrayLesson.CORNER_BLINK:
			lesson_corner_blink()
		ArrayLesson.ROW_LIGHTING:
			lesson_row_lighting()
		ArrayLesson.COLUMN_LIGHTING:
			lesson_column_lighting()
		ArrayLesson.SNAKE_PATTERN:
			lesson_snake_pattern()
		ArrayLesson.SPIRAL_INWARD:
			lesson_spiral_inward()
		ArrayLesson.PULSE_CENTER:
			lesson_pulse_center()
		ArrayLesson.WAVE_DIAGONAL:
			lesson_wave_diagonal()
		ArrayLesson.DISCO_CELEBRATION:
			lesson_disco_celebration()

func lesson_corner_blink():
	"""Lesson 1: Array indexing - corner positions"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		clear_all_cubes()
		
		var corners = [
			Vector2i(0, 0),                    # array[0][0]
			Vector2i(0, grid_size - 1),        # array[0][8]
			Vector2i(grid_size - 1, 0),        # array[8][0]
			Vector2i(grid_size - 1, grid_size - 1)  # array[8][8]
		]
		
		var corner = corners[animation_step % corners.size()]
		light_cube_at(corner.x, corner.y, lesson_colors[ArrayLesson.CORNER_BLINK])
		animation_step += 1

func lesson_row_lighting():
	"""Lesson 2: Row-wise array traversal"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		var current_row = animation_step % grid_size
		var current_col = (animation_step / grid_size) % grid_size
		
		light_cube_at(current_row, current_col, lesson_colors[ArrayLesson.ROW_LIGHTING])
		animation_step += 1
		
		if animation_step >= grid_size * grid_size:
			animation_step = 0
			clear_all_cubes()

func lesson_column_lighting():
	"""Lesson 3: Column-wise array traversal"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		var current_col = animation_step % grid_size
		var current_row = (animation_step / grid_size) % grid_size
		
		light_cube_at(current_row, current_col, lesson_colors[ArrayLesson.COLUMN_LIGHTING])
		animation_step += 1
		
		if animation_step >= grid_size * grid_size:
			animation_step = 0
			clear_all_cubes()

func lesson_snake_pattern():
	"""Lesson 4: Snake/zigzag traversal"""
	if step_timer >= animation_speed * 0.5:
		step_timer = 0.0
		clear_all_cubes()
		
		var snake_positions = generate_snake_pattern()
		if animation_step < snake_positions.size():
			var pos = snake_positions[animation_step]
			light_cube_at(pos.x, pos.y, lesson_colors[ArrayLesson.SNAKE_PATTERN])
			
			# Light trail behind
			for i in range(max(0, animation_step - 3), animation_step):
				var trail_pos = snake_positions[i]
				var fade = float(i - max(0, animation_step - 3)) / 3.0
				var trail_color = lesson_colors[ArrayLesson.SNAKE_PATTERN] * fade
				light_cube_at(trail_pos.x, trail_pos.y, trail_color)
		
		animation_step += 1
		if animation_step >= snake_positions.size():
			animation_step = 0

func lesson_spiral_inward():
	"""Lesson 5: Spiral traversal"""
	if step_timer >= animation_speed * 0.7:
		step_timer = 0.0
		clear_all_cubes()
		
		var spiral_positions = generate_spiral_pattern()
		if animation_step < spiral_positions.size():
			var pos = spiral_positions[animation_step]
			light_cube_at(pos.x, pos.y, lesson_colors[ArrayLesson.SPIRAL_INWARD])
		
		animation_step += 1
		if animation_step >= spiral_positions.size():
			animation_step = 0

func lesson_pulse_center():
	"""Lesson 6: Radial pulse from center"""
	var center = Vector2(grid_size / 2, grid_size / 2)
	var max_distance = center.distance_to(Vector2(0, 0))
	var pulse_radius = sin(lesson_time * 3.0) * max_distance
	
	clear_all_cubes()
	
	for row in range(grid_size):
		for col in range(grid_size):
			var distance = Vector2(row, col).distance_to(center)
			if abs(distance - pulse_radius) < 1.5:
				var intensity = 1.0 - abs(distance - pulse_radius) / 1.5
				var color = lesson_colors[ArrayLesson.PULSE_CENTER] * intensity
				light_cube_at(row, col, color)

func lesson_wave_diagonal():
	"""Lesson 7: Diagonal wave patterns"""
	clear_all_cubes()
	
	for row in range(grid_size):
		for col in range(grid_size):
			var wave_value = sin(lesson_time * 2.0 + (row + col) * 0.5)
			if wave_value > 0.5:
				var intensity = (wave_value - 0.5) * 2.0
				var color = lesson_colors[ArrayLesson.WAVE_DIAGONAL] * intensity
				light_cube_at(row, col, color)

func lesson_disco_celebration():
	"""Lesson 8: Disco celebration"""
	var disco_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	
	for row in range(grid_size):
		for col in range(grid_size):
			var time_offset = lesson_time + row * 0.3 + col * 0.2
			var color_index = int(time_offset * 2) % disco_colors.size()
			var pulse = sin(time_offset * 4.0) * 0.5 + 0.5
			var color = disco_colors[color_index] * pulse
			light_cube_at(row, col, color)

func generate_snake_pattern() -> Array[Vector2i]:
	"""Generate snake pattern positions"""
	var positions: Array[Vector2i] = []
	
	for row in range(grid_size):
		if row % 2 == 0:
			# Left to right
			for col in range(grid_size):
				positions.append(Vector2i(row, col))
		else:
			# Right to left
			for col in range(grid_size - 1, -1, -1):
				positions.append(Vector2i(row, col))
	
	return positions

func generate_spiral_pattern() -> Array[Vector2i]:
	"""Generate spiral pattern from outside to inside"""
	var positions: Array[Vector2i] = []
	var top = 0
	var bottom = grid_size - 1
	var left = 0
	var right = grid_size - 1
	
	while top <= bottom and left <= right:
		# Top row
		for col in range(left, right + 1):
			positions.append(Vector2i(top, col))
		top += 1
		
		# Right column
		for row in range(top, bottom + 1):
			positions.append(Vector2i(row, right))
		right -= 1
		
		# Bottom row
		if top <= bottom:
			for col in range(right, left - 1, -1):
				positions.append(Vector2i(bottom, col))
			bottom -= 1
		
		# Left column
		if left <= right:
			for row in range(bottom, top - 1, -1):
				positions.append(Vector2i(row, left))
			left += 1
	
	return positions

func light_cube_at(row: int, col: int, color: Color):
	"""Light up a specific cube"""
	if row >= 0 and row < grid_size and col >= 0 and col < grid_size:
		var cube = disco_grid[row][col]
		if cube and is_instance_valid(cube):
			set_cube_color(cube, color)

func clear_all_cubes():
	"""Turn off all cubes"""
	for cube in disco_cubes:
		if is_instance_valid(cube):
			set_cube_color(cube, Color.BLACK)

func set_cube_color(cube: Node3D, color: Color):
	"""Set cube color"""
	var mesh_instance = cube.get_child(0) as MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		material.albedo_color = color
		material.emission = color * 0.8

func print_current_lesson():
	"""Print lesson information"""
	var lesson_name = ArrayLesson.keys()[current_lesson]
	print("🎓 ARRAY LESSON ", current_lesson + 1, ": ", lesson_name)
	
	match current_lesson:
		ArrayLesson.CORNER_BLINK:
			print("   Learning: Array indexing - array[0][0], array[0][8], array[8][0], array[8][8]")
		ArrayLesson.ROW_LIGHTING:
			print("   Learning: Row-wise traversal - for row in range(9): for col in range(9)")
		ArrayLesson.COLUMN_LIGHTING:
			print("   Learning: Column-wise traversal - for col in range(9): for row in range(9)")
		ArrayLesson.SNAKE_PATTERN:
			print("   Learning: Zigzag traversal - alternating directions")
		ArrayLesson.SPIRAL_INWARD:
			print("   Learning: Spiral algorithm - outside to inside")
		ArrayLesson.PULSE_CENTER:
			print("   Learning: Radial distance calculations")
		ArrayLesson.WAVE_DIAGONAL:
			print("   Learning: Mathematical wave patterns")
		ArrayLesson.DISCO_CELEBRATION:
			print("   Learning: Complex multi-pattern algorithms")

func print_game_info():
	"""Print setup information"""
	print("=== SIMPLE DISCO FLOOR INFO ===")
	print("Grid size: ", grid_size, "x", grid_size)
	print("Floor height: ", floor_height, " units above scene")
	print("Cube size: ", cube_size)
	print("Total disco cubes: ", disco_cubes.size())
	print("===============================")

# Public API
func toggle_disco():
	"""Toggle disco on/off"""
	disco_enabled = !disco_enabled
	if not disco_enabled:
		clear_all_cubes()
	print("🕺 Simple Disco Floor: ", "ON" if disco_enabled else "OFF")

func set_floor_height(height: float):
	"""Move the entire disco floor to a new height"""
	floor_height = height
	for row in range(grid_size):
		for col in range(grid_size):
			var cube = disco_grid[row][col]
			if cube:
				cube.position.y = floor_height
	print("🔧 Disco floor moved to height: ", floor_height)

func center_floor_at_position(center_pos: Vector3):
	"""Move the entire disco floor to center at a specific position"""
	self.position = center_pos
	print("🔧 Disco floor centered at: ", self.position)

func next_lesson():
	"""Skip to next lesson"""
	lesson_time = pattern_duration

func restart_lessons():
	"""Restart from first lesson"""
	current_lesson = 0
	lesson_time = 0.0
	animation_step = 0
	clear_all_cubes()

func debug_floor_position():
	"""Debug function to check floor positioning"""
	print("=== DISCO FLOOR DEBUG ===")
	print("Floor height: ", floor_height)
	print("Floor position: ", self.position)
	print("Floor rotation: ", self.rotation)
	print("Grid size: ", grid_size)
	print("Cube spacing: ", cube_spacing)
	if disco_cubes.size() > 0:
		print("First cube position: ", disco_cubes[0].position)
		print("Last cube position: ", disco_cubes[-1].position)
	print("=========================")

func get_disco_info() -> Dictionary:
	"""Get current disco state"""
	return {
		"enabled": disco_enabled,
		"current_lesson": ArrayLesson.keys()[current_lesson],
		"grid_size": grid_size,
		"floor_height": floor_height,
		"total_cubes": disco_cubes.size()
	}
