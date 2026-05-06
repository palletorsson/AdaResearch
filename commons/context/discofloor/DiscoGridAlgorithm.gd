# DiscoGridAlgorithm.gd
# Array Learning Disco Floor - Optimized following GridColorizer.gd pattern

class_name DiscoGridAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = "Array Learning Disco"
var grid_reference = null

# Disco grid properties
@export var region_min_x: int = 3
@export var region_max_x: int = 9
@export var region_min_z: int = 3
@export var region_max_z: int = 9
@export var target_y_level: int = 0

var ceiling_component = null
var grid_width: int = 7
var grid_depth: int = 7

# References from GridColorizer style search
var multimesh_instance_ref: MultiMeshInstance3D = null
var multimesh_ref: MultiMesh = null
var grid_structure: GridStructureComponent = null

# Animation settings
@export var disco_enabled: bool = true
@export var pattern_duration: float = 10.0
@export var animation_speed: float = 0.05
@export var auto_start: bool = true

# Disco state
var disco_indices: Array[int] = [] 
var disco_grid_map: Dictionary = {} 

var current_lesson: int = 0
var lesson_time: float = 0.0
var animation_step: int = 0
var step_timer: float = 0.0

var timer: Timer
var is_running: bool = false

enum ArrayLesson { CORNER_BLINK, ROW_LIGHTING, COLUMN_LIGHTING, SNAKE_PATTERN, SPIRAL_INWARD, PULSE_CENTER, WAVE_DIAGONAL, DISCO_CELEBRATION }

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

signal lesson_changed(lesson_name: String)
signal algorithm_finished()

func _ready():
	timer = Timer.new()
	timer.wait_time = pattern_duration
	timer.timeout.connect(_on_lesson_timer_timeout)
	add_child(timer)
	
	# Following GridColorizer: wait for generation to complete
	await get_tree().create_timer(1.0).timeout
	setup_disco_grid()
	
	if auto_start: 
		start_algorithm()

func _find_grid_resources():
	print("DiscoGrid: Searching for grid resources (GridColorizer style)...")

	# Search parent hierarchy first
	multimesh_instance_ref = _find_multimesh_recursive(get_parent())
	if multimesh_instance_ref:
		print("DiscoGrid: Found GridMultiMesh in parent hierarchy!")

	# If not found, search from scene root
	if not multimesh_instance_ref:
		var root = get_tree().current_scene
		multimesh_instance_ref = _find_multimesh_recursive(root)
		if multimesh_instance_ref:
			print("DiscoGrid: Found GridMultiMesh in scene root!")

	if multimesh_instance_ref:
		multimesh_ref = multimesh_instance_ref.multimesh
		print("DiscoGrid: MultiMesh resource: %s (instances: %d)" % [multimesh_ref, multimesh_ref.instance_count if multimesh_ref else 0])

		# CRITICAL: Adjust material to make instance colors visible
		var material = multimesh_instance_ref.material_override
		if material is ShaderMaterial:
			material.set_shader_parameter("modelColor", Color.WHITE)
			material.set_shader_parameter("show_interior", true)
			material.set_shader_parameter("wireframeOpacity", 0.3)
			print("DiscoGrid: Adjusted material (modelColor=WHITE, show_interior=true)")
		elif material == null:
			print("DiscoGrid: WARNING - material_override is null, shader parameters not set")
	else:
		print("DiscoGrid: ERROR - GridMultiMesh not found!")

	# Search for GridStructureComponent - parent first, then scene root
	grid_structure = _find_grid_structure(get_parent())
	if not grid_structure:
		grid_structure = _find_grid_structure(get_tree().current_scene)

	if grid_structure:
		print("DiscoGrid: Found GridStructureComponent! cube_positions.size() = %d" % grid_structure.cube_positions.size())
	else:
		print("DiscoGrid: WARNING - GridStructureComponent not found, will use fallback indexing")

func _find_multimesh_recursive(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D and node.name == "GridMultiMesh": return node
	for child in node.get_children():
		var res = _find_multimesh_recursive(child)
		if res: return res
	return null

func _find_grid_structure(node: Node) -> GridStructureComponent:
	# Use proper type checking like GridColorizer does
	if node is GridStructureComponent:
		return node
	for child in node.get_children():
		var res = _find_grid_structure(child)
		if res:
			return res
	return null

func apply_grid_config(data: Dictionary):
	print("DiscoGrid: Config received: %s" % data)
	if data.has("min_x"): region_min_x = int(data.min_x)
	if data.has("max_x"): region_max_x = int(data.max_x)
	if data.has("min_z"): region_min_z = int(data.min_z)
	if data.has("max_z"): region_max_z = int(data.max_z)
	if data.has("target_y"): target_y_level = int(data.target_y)
	setup_disco_grid()

func start_algorithm():
	if not multimesh_ref: 
		setup_disco_grid()
	if not multimesh_ref: return
	
	is_running = true
	current_lesson = 0
	animation_step = 0
	step_timer = 0.0
	timer.start()
	print("DiscoGrid: Algorithm started.")

func stop_algorithm():
	is_running = false
	timer.stop()
	_clear_all_cubes()

func setup_disco_grid():
	_find_grid_resources()
	if not multimesh_ref:
		print("DiscoGrid: ERROR - No multimesh_ref found!")
		return

	_clear_all_cubes()
	disco_indices.clear()
	disco_grid_map.clear()

	# Note: use_colors and use_custom_data are set by GridStructureComponent
	# They cannot be changed after instance_count > 0

	grid_width = region_max_x - region_min_x + 1
	grid_depth = region_max_z - region_min_z + 1

	print("DiscoGrid: Region bounds: x=[%d,%d], z=[%d,%d], y=%d" % [region_min_x, region_max_x, region_min_z, region_max_z, target_y_level])
	print("DiscoGrid: Grid dimensions: %dx%d" % [grid_width, grid_depth])

	# Mapping logic following GridColorizer
	var instance_count = multimesh_ref.instance_count
	print("DiscoGrid: MultiMesh instance_count = %d" % instance_count)

	# Use cube_positions from GridStructureComponent if available
	if grid_structure and grid_structure.cube_positions.size() > 0:
		var all_positions = grid_structure.cube_positions
		print("DiscoGrid: Found GridStructureComponent with %d cube positions" % all_positions.size())

		for i in range(all_positions.size()):
			var pos = all_positions[i]
			if pos.x >= region_min_x and pos.x <= region_max_x and \
			   pos.z >= region_min_z and pos.z <= region_max_z and \
			   pos.y == target_y_level:
				disco_indices.append(i)
				disco_grid_map[Vector2i(pos.x - region_min_x, pos.z - region_min_z)] = i

		print("DiscoGrid: Mapped %d cubes using cube_positions" % disco_indices.size())
	else:
		# Fallback to square grid logic from GridColorizer.gd
		print("DiscoGrid: WARNING - No GridStructureComponent, using fallback square grid logic")
		var g_size = int(sqrt(float(instance_count)))
		if g_size * g_size < instance_count:
			g_size += 1
		print("DiscoGrid: Fallback grid size = %d" % g_size)

		for i in range(instance_count):
			var z = i / g_size
			var x = i % g_size
			if x >= region_min_x and x <= region_max_x and z >= region_min_z and z <= region_max_z:
				disco_indices.append(i)
				disco_grid_map[Vector2i(x - region_min_x, z - region_min_z)] = i

		print("DiscoGrid: Mapped %d cubes using fallback" % disco_indices.size())

	print("DiscoGrid: Setup complete. %dx%d area, %d cubes mapped." % [grid_width, grid_depth, disco_indices.size()])
	if disco_indices.size() > 0:
		print("DiscoGrid: First 5 indices: %s" % str(disco_indices.slice(0, min(5, disco_indices.size()))))

func _process(delta):
	if not disco_enabled or not is_running: return
	lesson_time += delta
	step_timer += delta
	match current_lesson:
		ArrayLesson.CORNER_BLINK: _lesson_corner_blink()
		ArrayLesson.ROW_LIGHTING: _lesson_row_lighting()
		ArrayLesson.COLUMN_LIGHTING: _lesson_column_lighting()
		ArrayLesson.SNAKE_PATTERN: _lesson_snake_pattern()
		ArrayLesson.SPIRAL_INWARD: _lesson_spiral_inward()
		ArrayLesson.PULSE_CENTER: _lesson_pulse_center()
		ArrayLesson.WAVE_DIAGONAL: _lesson_wave_diagonal()
		ArrayLesson.DISCO_CELEBRATION: _lesson_disco_celebration()

func _on_lesson_timer_timeout():
	current_lesson = (current_lesson + 1) % ArrayLesson.size()
	lesson_time = 0.0
	animation_step = 0
	step_timer = 0.0
	_clear_all_cubes()
	lesson_changed.emit(ArrayLesson.keys()[current_lesson])

func _light_cube_at(row: int, col: int, color: Color):
	var coord = Vector2i(row, col)
	if not disco_grid_map.has(coord): return
	var index = disco_grid_map[coord]
	multimesh_ref.set_instance_color(index, color)
	if multimesh_ref.use_custom_data:
		multimesh_ref.set_instance_custom_data(index, color.inverted())

func _clear_all_cubes():
	if not multimesh_ref: return
	for index in disco_indices:
		multimesh_ref.set_instance_color(index, Color.BLACK)
		if multimesh_ref.use_custom_data:
			multimesh_ref.set_instance_custom_data(index, Color.BLACK)

# --- Lessons ---
func _lesson_corner_blink():
	if step_timer >= animation_speed * 10:
		step_timer = 0.0; _clear_all_cubes()
		var corners = [Vector2i(0,0), Vector2i(0, grid_depth-1), Vector2i(grid_width-1, 0), Vector2i(grid_width-1, grid_depth-1)]
		_light_cube_at(corners[animation_step % 4].x, corners[animation_step % 4].y, lesson_colors[0])
		animation_step += 1

func _lesson_row_lighting():
	if step_timer >= animation_speed:
		step_timer = 0.0; _light_cube_at(animation_step % grid_width, (animation_step / grid_width) % grid_depth, lesson_colors[1])
		animation_step += 1; if animation_step >= grid_width * grid_depth: animation_step = 0; _clear_all_cubes()

func _lesson_column_lighting():
	if step_timer >= animation_speed:
		step_timer = 0.0; _light_cube_at((animation_step / grid_depth) % grid_width, animation_step % grid_depth, lesson_colors[2])
		animation_step += 1; if animation_step >= grid_width * grid_depth: animation_step = 0; _clear_all_cubes()

func _lesson_snake_pattern():
	if step_timer >= animation_speed:
		step_timer = 0.0; _clear_all_cubes()
		var r = animation_step / grid_depth; var c = animation_step % grid_depth
		if r % 2 == 1: c = (grid_depth - 1) - c
		if r < grid_width: _light_cube_at(r, c, lesson_colors[3])
		animation_step = (animation_step + 1) % (grid_width * grid_depth)

func _lesson_spiral_inward():
	if step_timer >= animation_speed:
		step_timer = 0.0; _clear_all_cubes()
		_light_cube_at(int(lesson_time * 5) % grid_width, int(lesson_time * 3) % grid_depth, lesson_colors[4])

func _lesson_pulse_center():
	_clear_all_cubes()
	var cx = grid_width / 2.0; var cz = grid_depth / 2.0
	var radius = (sin(lesson_time * 4) + 1.0) * (grid_width / 2.0)
	for r in range(grid_width):
		for c in range(grid_depth):
			if abs(sqrt(pow(r-cx,2) + pow(c-cz,2)) - radius) < 1.0: _light_cube_at(r, c, lesson_colors[5])

func _lesson_wave_diagonal():
	_clear_all_cubes()
	for r in range(grid_width):
		for c in range(grid_depth):
			if sin(lesson_time * 3 + (r + c) * 0.5) > 0.7: _light_cube_at(r, c, lesson_colors[6])

func _lesson_disco_celebration():
	for i in range(5):
		_light_cube_at(randi() % grid_width, randi() % grid_depth, Color.from_hsv(randf(), 0.8, 1.0))

# === PUBLIC API (called by DiscoFloorController) ===

func toggle_disco():
	disco_enabled = not disco_enabled
	if not disco_enabled:
		_clear_all_cubes()

func next_lesson():
	_on_lesson_timer_timeout()

func restart_lessons():
	current_lesson = 0
	lesson_time = 0.0
	animation_step = 0
	step_timer = 0.0
	_clear_all_cubes()

func get_disco_info() -> Dictionary:
	return {
		"enabled": disco_enabled,
		"current_lesson": ArrayLesson.keys()[current_lesson],
		"disco_cubes": disco_indices.size(),
		"is_running": is_running
	}

func get_algorithm_info() -> Dictionary:
	return {
		"name": algorithm_name,
		"current_lesson": ArrayLesson.keys()[current_lesson],
		"disco_cubes": disco_indices.size(),
		"is_running": is_running,
		"region_bounds": {
			"min_x": region_min_x,
			"max_x": region_max_x,
			"min_z": region_min_z,
			"max_z": region_max_z,
			"target_y": target_y_level
		}
	}
