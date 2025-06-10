# DiscoGridAlgorithm.gd
# Array Learning Disco Floor - Educational grid animation using existing cubes
# Uses middle 8x8 region of the grid system with unique shader instances

class_name DiscoGridAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = "Array Learning Disco"
var algorithm_description: String = "Interactive disco floor showing array patterns"
var grid_reference = null
var max_steps: int = 8  # Number of lessons

# Disco grid properties - 8x8 region in middle of grid
@export var region_min_x: int =  1
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 0

# Animation settings
@export var disco_enabled: bool = true
@export var pattern_duration: float = 10.0
@export var animation_speed: float = 0.05
@export var auto_start: bool = true

# Disco state
var disco_cubes: Array[Node3D] = []
var disco_materials: Array[ShaderMaterial] = []
var current_lesson: int = 0
var lesson_time: float = 0.0
var animation_step: int = 0
var step_timer: float = 0.0

# Pattern timer
var timer: Timer
var is_running: bool = false

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

# Signals
signal algorithm_step_complete()
signal algorithm_finished()
signal lesson_changed(lesson_name: String)

func _init():
	algorithm_name = "Array Learning Disco (8x8 Grid)"
	algorithm_description = "Educational disco patterns using grid cubes"
	max_steps = ArrayLesson.size()

func _ready():
	print("🕺 DiscoGridAlgorithm: Initializing array learning disco system")
	
	# Create timer for lesson progression
	timer = Timer.new()
	timer.wait_time = pattern_duration
	timer.timeout.connect(_on_lesson_timer_timeout)
	add_child(timer)
	
	# Auto-connect to grid system
	call_deferred("_find_and_connect_grid")
	
	if auto_start:
		call_deferred("start_algorithm")

func _find_and_connect_grid():
	"""Find and connect to the grid system"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		set_grid_reference(grid_system)
		print("DiscoGridAlgorithm: ✅ Connected to grid system")
	else:
		print("DiscoGridAlgorithm: ❌ WARNING - Could not find GridSystem!")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	return null

func start_algorithm():
	"""Start the disco algorithm"""
	if not grid_reference:
		print("DiscoGridAlgorithm: Cannot start - grid not ready")
		return
	
	setup_disco_grid()
	is_running = true
	current_lesson = 0
	lesson_time = 0.0
	timer.start()
	
	print("DiscoGridAlgorithm: 🎵 Disco started with %d cubes!" % disco_cubes.size())
	_print_current_lesson()

func stop_algorithm():
	"""Stop the disco algorithm"""
	is_running = false
	timer.stop()
	_clear_all_cubes()
	print("DiscoGridAlgorithm: Disco stopped")

func setup_disco_grid():
	"""Setup the 8x8 disco grid using existing cubes"""
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		print("DiscoGridAlgorithm: No structure component found")
		return
	
	disco_cubes.clear()
	disco_materials.clear()
	
	# Ensure cubes exist in the 8x8 region
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			# Ensure cube exists at target level
			if not structure_component.has_cube_at(x, target_y_level, z):
				_place_cube_at(x, target_y_level, z)
			
			# Get the cube and create unique material
			var cube = structure_component.get_cube_at(x, target_y_level, z)
			if cube:
				_setup_disco_cube(cube)
	
	print("DiscoGridAlgorithm: Setup complete - %d disco cubes ready" % disco_cubes.size())

func _setup_disco_cube(cube: Node3D):
	"""Setup a cube for disco with unique shader material"""
	disco_cubes.append(cube)
	
	# Raise the cube slightly for disco floor effect
	cube.position.y += 0.1
	
	# Find the mesh instance in the cube
	var mesh_instance = _find_mesh_instance_in_cube(cube)
	if not mesh_instance:
		print("DiscoGridAlgorithm: WARNING - No mesh instance found in cube")
		return
	
	# Create unique shader material for this cube
	var original_material = mesh_instance.material_override
	if original_material and original_material is ShaderMaterial:
		# Duplicate the material to make it unique
		var unique_material = original_material.duplicate() as ShaderMaterial
		mesh_instance.material_override = unique_material
		disco_materials.append(unique_material)
		
		# Set initial dark state with subtle base lighting
		unique_material.set_shader_parameter("modelColor", Color(0.3, 0.3, 0.35, 1.0))  # Subtle lit base
		unique_material.set_shader_parameter("emissionColor", Color.BLACK)
		unique_material.set_shader_parameter("emission_strength", 0.0)
	else:
		print("DiscoGridAlgorithm: WARNING - Cube doesn't have shader material")
		disco_materials.append(null)

func _find_mesh_instance_in_cube(cube: Node3D) -> MeshInstance3D:
	"""Find MeshInstance3D in cube hierarchy"""
	# Check if cube itself is a MeshInstance3D
	if cube is MeshInstance3D:
		return cube as MeshInstance3D
	
	# Search children recursively
	for child in cube.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		
		# Check grandchildren (for nested structures like StaticBody3D)
		var nested_mesh = _find_mesh_instance_in_cube(child)
		if nested_mesh:
			return nested_mesh
	
	return null

func _place_cube_at(x: int, y: int, z: int):
	"""Place a cube at specific coordinates using grid system"""
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Check if cube already exists
	if structure_component.has_cube_at(x, y, z):
		return
	
	# Create new cube using the grid system's method
	var total_size = structure_component.cube_size + structure_component.gutter
	structure_component._add_cube(x, y, z, total_size)

func _process(delta):
	"""Main disco animation loop"""
	if not disco_enabled or not is_running:
		return
	
	lesson_time += delta
	step_timer += delta
	
	# Run current lesson animation
	match current_lesson:
		ArrayLesson.CORNER_BLINK:
			_lesson_corner_blink()
		ArrayLesson.ROW_LIGHTING:
			_lesson_row_lighting()
		ArrayLesson.COLUMN_LIGHTING:
			_lesson_column_lighting()
		ArrayLesson.SNAKE_PATTERN:
			_lesson_snake_pattern()
		ArrayLesson.SPIRAL_INWARD:
			_lesson_spiral_inward()
		ArrayLesson.PULSE_CENTER:
			_lesson_pulse_center()
		ArrayLesson.WAVE_DIAGONAL:
			_lesson_wave_diagonal()
		ArrayLesson.DISCO_CELEBRATION:
			_lesson_disco_celebration()

func _on_lesson_timer_timeout():
	"""Move to next lesson"""
	current_lesson = (current_lesson + 1) % ArrayLesson.size()
	lesson_time = 0.0
	animation_step = 0
	step_timer = 0.0
	_clear_all_cubes()
	_print_current_lesson()
	lesson_changed.emit(ArrayLesson.keys()[current_lesson])

# === LESSON IMPLEMENTATIONS ===

func _lesson_corner_blink():
	"""Lesson 1: Array indexing - corner positions"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		_clear_all_cubes()
		
		var corners = [
			Vector2i(0, 0),    # disco_cubes[0][0]
			Vector2i(0, 7),    # disco_cubes[0][7]
			Vector2i(7, 0),    # disco_cubes[7][0]
			Vector2i(7, 7)     # disco_cubes[7][7]
		]
		
		var corner = corners[animation_step % corners.size()]
		_light_cube_at(corner.x, corner.y, lesson_colors[ArrayLesson.CORNER_BLINK])
		animation_step += 1

func _lesson_row_lighting():
	"""Lesson 2: Row-wise array traversal"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		var current_row = animation_step % 8
		var current_col = (animation_step / 8) % 8
		
		_light_cube_at(current_row, current_col, lesson_colors[ArrayLesson.ROW_LIGHTING])
		animation_step += 1
		
		if animation_step >= 64:  # 8x8 = 64
			animation_step = 0
			_clear_all_cubes()

func _lesson_column_lighting():
	"""Lesson 3: Column-wise array traversal"""
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		var current_col = animation_step % 8
		var current_row = (animation_step / 8) % 8
		
		_light_cube_at(current_row, current_col, lesson_colors[ArrayLesson.COLUMN_LIGHTING])
		animation_step += 1
		
		if animation_step >= 64:
			animation_step = 0
			_clear_all_cubes()

func _lesson_snake_pattern():
	"""Lesson 4: Snake/zigzag traversal"""
	if step_timer >= (animation_speed * 0.5):
		step_timer = 0.0
		_clear_all_cubes()
		
		var snake_positions = _generate_snake_pattern()
		if animation_step < snake_positions.size():
			var pos = snake_positions[animation_step]
			_light_cube_at(pos.x, pos.y, lesson_colors[ArrayLesson.SNAKE_PATTERN])
			
			# Light trail behind
			for i in range(max(0, animation_step - 3), animation_step):
				var trail_pos = snake_positions[i]
				var fade = float(i - max(0, animation_step - 3)) / 3.0
				var trail_color = lesson_colors[ArrayLesson.SNAKE_PATTERN] * fade
				_light_cube_at(trail_pos.x, trail_pos.y, trail_color)
		
		animation_step += 1
		if animation_step >= snake_positions.size():
			animation_step = 0

func _lesson_spiral_inward():
	"""Lesson 5: Spiral traversal"""
	if step_timer >= (animation_speed * 0.7):
		step_timer = 0.0
		_clear_all_cubes()
		
		var spiral_positions = _generate_spiral_pattern()
		if animation_step < spiral_positions.size():
			var pos = spiral_positions[animation_step]
			_light_cube_at(pos.x, pos.y, lesson_colors[ArrayLesson.SPIRAL_INWARD])
		
		animation_step += 1
		if animation_step >= spiral_positions.size():
			animation_step = 0

func _lesson_pulse_center():
	"""Lesson 6: Radial pulse from center"""
	var center = Vector2(3.5, 3.5)  # Center of 8x8 grid
	var max_distance = center.distance_to(Vector2(0, 0))
	var pulse_radius = sin(lesson_time * 3.0) * max_distance
	
	_clear_all_cubes()
	
	for row in range(8):
		for col in range(8):
			var distance = Vector2(row, col).distance_to(center)
			if abs(distance - pulse_radius) < 1.5:
				var intensity = 1.0 - abs(distance - pulse_radius) / 1.5
				var color = lesson_colors[ArrayLesson.PULSE_CENTER] * intensity
				_light_cube_at(row, col, color)

func _lesson_wave_diagonal():
	"""Lesson 7: Diagonal wave patterns"""
	_clear_all_cubes()
	
	for row in range(8):
		for col in range(8):
			var wave_value = sin(lesson_time * 2.0 + (row + col) * 0.5)
			if wave_value > 0.5:
				var intensity = (wave_value - 0.5) * 2.0
				var color = lesson_colors[ArrayLesson.WAVE_DIAGONAL] * intensity
				_light_cube_at(row, col, color)

func _lesson_disco_celebration():
	"""Lesson 8: Disco celebration"""
	var disco_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	
	for row in range(8):
		for col in range(8):
			var time_offset = lesson_time + row * 0.3 + col * 0.2
			var color_index = int(time_offset * 2) % disco_colors.size()
			var pulse = sin(time_offset * 4.0) * 0.5 + 0.5
			var color = disco_colors[color_index] * pulse
			_light_cube_at(row, col, color)

# === PATTERN GENERATORS ===

func _generate_snake_pattern() -> Array[Vector2i]:
	"""Generate snake pattern positions for 8x8 grid"""
	var positions: Array[Vector2i] = []
	
	for row in range(8):
		if row % 2 == 0:
			# Left to right
			for col in range(8):
				positions.append(Vector2i(row, col))
		else:
			# Right to left
			for col in range(7, -1, -1):
				positions.append(Vector2i(row, col))
	
	return positions

func _generate_spiral_pattern() -> Array[Vector2i]:
	"""Generate spiral pattern from outside to inside for 8x8 grid"""
	var positions: Array[Vector2i] = []
	var top = 0
	var bottom = 7
	var left = 0
	var right = 7
	
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

# === CUBE LIGHTING ===

func _light_cube_at(row: int, col: int, color: Color):
	"""Light up a specific cube in the 8x8 grid"""
	if row < 0 or row >= 8 or col < 0 or col >= 8:
		return
	
	var cube_index = row * 8 + col
	if cube_index >= disco_cubes.size() or cube_index >= disco_materials.size():
		return
	
	var material = disco_materials[cube_index]
	if material:
		_set_cube_material_color(material, color)

func _clear_all_cubes():
	"""Turn off all cubes"""
	for material in disco_materials:
		if material:
			_set_cube_material_color(material, Color.BLACK)

func _set_cube_material_color(material: ShaderMaterial, color: Color):
	"""Set cube color via shader material"""
	if material:
		if color == Color.BLACK:
			# Dark state - subtle base lighting
			material.set_shader_parameter("modelColor", Color(0.3, 0.3, 0.35, 1.0))  # Subtle lit base
			material.set_shader_parameter("emissionColor", Color.BLACK)
			material.set_shader_parameter("emission_strength", 0.0)
		else:
			# Lit state - bright model color + emission
			var lit_model_color = color * 0.7  # Slightly darker than emission for contrast
			material.set_shader_parameter("modelColor", lit_model_color)
			material.set_shader_parameter("emissionColor", color)
			material.set_shader_parameter("emission_strength", 3.0)  # Strong emission for disco effect

# === LESSON INFO ===

func _print_current_lesson():
	"""Print lesson information"""
	var lesson_name = ArrayLesson.keys()[current_lesson]
	print("🎓 ARRAY LESSON %d: %s" % [current_lesson + 1, lesson_name])
	
	match current_lesson:
		ArrayLesson.CORNER_BLINK:
			print("   Learning: Array indexing - grid[0][0], grid[0][7], grid[7][0], grid[7][7]")
		ArrayLesson.ROW_LIGHTING:
			print("   Learning: Row-wise traversal - for row in range(8): for col in range(8)")
		ArrayLesson.COLUMN_LIGHTING:
			print("   Learning: Column-wise traversal - for col in range(8): for row in range(8)")
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

# === PUBLIC API ===

func set_grid_reference(grid_ref):
	"""Set grid reference for the algorithm to work with"""
	grid_reference = grid_ref

func toggle_disco():
	"""Toggle disco on/off"""
	disco_enabled = !disco_enabled
	if not disco_enabled:
		_clear_all_cubes()
	print("🕺 Disco Grid: %s" % ("ON" if disco_enabled else "OFF"))

func next_lesson():
	"""Skip to next lesson"""
	_on_lesson_timer_timeout()

func restart_lessons():
	"""Restart from first lesson"""
	current_lesson = 0
	lesson_time = 0.0
	animation_step = 0
	_clear_all_cubes()
	_print_current_lesson()

func get_region_bounds() -> Dictionary:
	"""Get current region bounds for external access"""
	return {
		"min_x": region_min_x,
		"max_x": region_max_x,
		"min_z": region_min_z,
		"max_z": region_max_z,
		"center_x": (region_min_x + region_max_x) / 2,
		"center_z": (region_min_z + region_max_z) / 2
	}

func get_algorithm_info() -> Dictionary:
	"""Get algorithm information"""
	return {
		"name": algorithm_name,
		"description": algorithm_description,
		"max_steps": max_steps,
		"current_lesson": ArrayLesson.keys()[current_lesson],
		"disco_cubes": disco_cubes.size(),
		"region_bounds": get_region_bounds(),
		"disco_enabled": disco_enabled,
		"is_running": is_running
	}

func get_disco_info() -> Dictionary:
	"""Get current disco state"""
	return {
		"enabled": disco_enabled,
		"current_lesson": ArrayLesson.keys()[current_lesson],
		"grid_size": "8x8",
		"total_cubes": disco_cubes.size(),
		"is_running": is_running
	}
