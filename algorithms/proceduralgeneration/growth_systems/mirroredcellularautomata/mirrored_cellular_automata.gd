extends Node3D

# @identity
# essence: Life-like CA with forced quad/octant/rotational symmetry — pattern = rule + mirror
# desire: To tile the floor with living kaleidoscope patterns that breathe between order and dissolution
# critical_parameter: symmetry_type — quad, eight-way, or rotational mirror fundamentally changes the visual grammar
# triggers: Switching symmetry mode transforms the same rules into radically different visual languages
# emerges: Mandala-like forms from stochastic birth/death plus symmetry enforcement — no mandala was coded
# needs: VR symmetry selector [missing], birth/death probability sliders [missing], Label3D [has]
# relationships: Contrasts with persian_rug (deterministic symmetry vs stochastic). Feeds into CA_GameOfLife.
# truth: Symmetry is not decoration — it is a second rule system layered on the first.

# Mirrored Cellular Automata — 3D floor display
# Creates symmetrical patterns that evolve according to cellular automata rules

@export_category("Grid Settings")
@export var grid_size: int = 21  # Use odd number for center symmetry
@export var update_interval: float = 0.2
@export var auto_evolve: bool = true

@export_category("Pattern Settings")
@export_enum("Quad Mirror", "Eight-Way Mirror", "Rotational") var symmetry_type: int = 0
@export_range(0.0, 1.0) var random_fill_percent: float = 0.3
@export_range(0.0, 1.0) var birth_probability: float = 0.2
@export_range(0.0, 1.0) var death_probability: float = 0.1
@export var fixed_border: bool = true

# Internal variables
var grid = []
var half_size: int
var update_timer: float = 0.0
var mesh_instance: MeshInstance3D = null
var cell_material: StandardMaterial3D = null

# Display fits within 0.8 x 0.8 meters on XZ plane
var display_size: float = 0.8
var cell_world_size: float = 0.0

# Colors for alive cells — cycle through for visual interest
var alive_colors = [
	Color(0.1, 0.9, 0.4),
	Color(0.2, 0.6, 1.0),
	Color(1.0, 0.4, 0.2),
	Color(0.9, 0.8, 0.1),
]
var generation: int = 0

func _ready() -> void:
	randomize()
	half_size = grid_size / 2
	cell_world_size = display_size / float(grid_size)

	# Create material — unshaded with vertex colors
	cell_material = StandardMaterial3D.new()
	cell_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cell_material.vertex_color_use_as_albedo = true
	cell_material.emission_enabled = true
	cell_material.emission = Color.WHITE
	cell_material.emission_energy_multiplier = 0.5

	# Mesh instance for alive-cell quads
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "CAMesh"
	add_child(mesh_instance)

	# Label
	var label = Label3D.new()
	label.text = "Mirrored Cellular Automata"
	label.font_size = 48
	label.pixel_size = 0.001
	label.position = Vector3(0.0, 0.0, -display_size * 0.5 - 0.04)
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.modulate = Color.WHITE
	add_child(label)

	initialize_grid()
	generate_initial_pattern()
	_rebuild_mesh()

func _process(delta: float) -> void:
	if auto_evolve:
		update_timer += delta
		if update_timer >= update_interval:
			update_timer = 0.0
			update_grid()
			generation += 1
			_rebuild_mesh()

func _rebuild_mesh() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, cell_material)

	var half_display = display_size * 0.5
	var color_idx = generation % alive_colors.size()
	var base_color = alive_colors[color_idx]

	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] != 1:
				continue

			# Map grid cell to world XZ coordinates, centred on origin
			var wx = -half_display + x * cell_world_size
			var wz = -half_display + y * cell_world_size
			var wy = 0.01  # Slightly above floor

			# Slight colour variation per cell
			var c = base_color
			c = c.lerp(Color.WHITE, float(x + y) / float(grid_size * 2) * 0.3)

			# Two triangles forming a quad
			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx, wy, wz))
			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx + cell_world_size, wy, wz))
			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx + cell_world_size, wy, wz + cell_world_size))

			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx, wy, wz))
			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx + cell_world_size, wy, wz + cell_world_size))
			im.surface_set_color(c)
			im.surface_add_vertex(Vector3(wx, wy, wz + cell_world_size))

	im.surface_end()
	mesh_instance.mesh = im

func initialize_grid() -> void:
	grid = []
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			row.append(0)
		grid.append(row)

func generate_initial_pattern() -> void:
	match symmetry_type:
		0:
			generate_quadrant_pattern()
		1:
			generate_octant_pattern()
		2:
			generate_rotational_pattern()

func generate_quadrant_pattern() -> void:
	for y in range(half_size):
		for x in range(half_size):
			if randf() <= random_fill_percent:
				set_cell_with_symmetry(x, y, 1)

func generate_octant_pattern() -> void:
	for y in range(half_size):
		for x in range(y + 1):
			if randf() <= random_fill_percent:
				set_cell_with_symmetry(x, y, 1)

func generate_rotational_pattern() -> void:
	var pattern_size = min(5, half_size)

	var pattern = []
	for y in range(pattern_size):
		var row = []
		for x in range(pattern_size):
			row.append(1 if randf() <= random_fill_percent else 0)
		pattern.append(row)

	for y in range(grid_size):
		for x in range(grid_size):
			var pattern_x = abs(x - half_size) % pattern_size
			var pattern_y = abs(y - half_size) % pattern_size
			grid[y][x] = pattern[pattern_y][pattern_x]

func set_cell_with_symmetry(x: int, y: int, value: int) -> void:
	match symmetry_type:
		0:
			grid[y][x] = value
			grid[y][grid_size - 1 - x] = value
			grid[grid_size - 1 - y][x] = value
			grid[grid_size - 1 - y][grid_size - 1 - x] = value
		1:
			grid[y][x] = value
			grid[y][grid_size - 1 - x] = value
			grid[grid_size - 1 - y][x] = value
			grid[grid_size - 1 - y][grid_size - 1 - x] = value
			grid[x][y] = value
			grid[x][grid_size - 1 - y] = value
			grid[grid_size - 1 - x][y] = value
			grid[grid_size - 1 - x][grid_size - 1 - y] = value
		2:
			var center_x = half_size
			var center_y = half_size
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			var angle = atan2(dy, dx)

			for rot in range(4):
				var new_angle = angle + rot * PI / 2
				var new_x = center_x + int(cos(new_angle) * distance)
				var new_y = center_y + int(sin(new_angle) * distance)

				if new_x >= 0 and new_x < grid_size and new_y >= 0 and new_y < grid_size:
					grid[new_y][new_x] = value

func update_grid() -> void:
	var new_grid = []
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			row.append(grid[y][x])
		new_grid.append(row)

	for y in range(grid_size):
		for x in range(grid_size):
			if fixed_border and (x == 0 or y == 0 or x == grid_size - 1 or y == grid_size - 1):
				continue

			var live_neighbors = count_live_neighbors(x, y)

			if grid[y][x] == 1:
				if live_neighbors < 2 or live_neighbors > 3:
					if randf() <= death_probability:
						new_grid[y][x] = 0
			else:
				if live_neighbors == 3:
					if randf() <= birth_probability:
						new_grid[y][x] = 1

	if symmetry_type == 0:
		apply_quad_symmetry(new_grid)
	elif symmetry_type == 1:
		apply_eight_way_symmetry(new_grid)
	elif symmetry_type == 2:
		apply_rotational_symmetry(new_grid)

	grid = new_grid

func count_live_neighbors(x: int, y: int) -> int:
	var count = 0
	for ny in range(max(0, y - 1), min(grid_size, y + 2)):
		for nx in range(max(0, x - 1), min(grid_size, x + 2)):
			if nx == x and ny == y:
				continue
			if grid[ny][nx] == 1:
				count += 1
	return count

func apply_quad_symmetry(new_grid: Array) -> void:
	for y in range(half_size):
		for x in range(half_size):
			var value = new_grid[y][x]
			new_grid[y][grid_size - 1 - x] = value
			new_grid[grid_size - 1 - y][x] = value
			new_grid[grid_size - 1 - y][grid_size - 1 - x] = value

func apply_eight_way_symmetry(new_grid: Array) -> void:
	for y in range(half_size):
		for x in range(y + 1):
			var value = new_grid[y][x]
			new_grid[y][grid_size - 1 - x] = value
			new_grid[grid_size - 1 - y][x] = value
			new_grid[grid_size - 1 - y][grid_size - 1 - x] = value
			new_grid[x][y] = value
			new_grid[x][grid_size - 1 - y] = value
			new_grid[grid_size - 1 - x][y] = value
			new_grid[grid_size - 1 - x][grid_size - 1 - y] = value

func apply_rotational_symmetry(new_grid: Array) -> void:
	var center_x = half_size
	var center_y = half_size

	for y in range(center_y + 1):
		for x in range(center_x + 1):
			if x == center_x and y == center_y:
				continue

			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			var angle = atan2(dy, dx)

			var value = new_grid[y][x]

			for rot in range(1, 4):
				var new_angle = angle + rot * PI / 2
				var new_x = center_x + int(cos(new_angle) * distance)
				var new_y = center_y + int(sin(new_angle) * distance)

				if new_x >= 0 and new_x < grid_size and new_y >= 0 and new_y < grid_size:
					new_grid[new_y][new_x] = value

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
