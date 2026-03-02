extends Node3D
class_name CaveGeneratorCA

## Cave Generator — cellular automaton cave generation with flood-fill connectivity.
## Classic roguelike technique: initialize ~45% walls, smooth with CA rules,
## flood-fill to find the largest connected region, fill the rest with walls.
## Entrance (green) and exit (red) placed at extremes of the largest region.

# --- Configuration ---
@export var display_size: float = 0.8
@export var grid_size: int = 64
@export var seed_value: int = 42
@export var wall_chance: float = 0.45
@export var smooth_passes: int = 5
@export var wall_threshold: int = 5

# --- Cell states ---
const FLOOR_CELL = 0
const WALL_CELL = 1

# --- Colors ---
const COLOR_FLOOR = Color(0.18, 0.12, 0.08)  # dark brown
const COLOR_WALL = Color(0.45, 0.45, 0.48)   # gray
const COLOR_ENTRANCE = Color(0.15, 0.75, 0.2) # green
const COLOR_EXIT = Color(0.85, 0.15, 0.1)     # red

# --- Internal ---
var _grid: PackedInt32Array
var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_build_floor_quad()
	_generate_cave()
	_add_title_label()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "CaveDisplay"

	var quad = QuadMesh.new()
	quad.size = Vector2(display_size, display_size)
	_mesh_inst.mesh = quad

	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.9
	_material.metallic = 0.0
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


func _generate_cave() -> void:
	# Step 1: Initialize grid with random walls
	_grid = PackedInt32Array()
	_grid.resize(grid_size * grid_size)
	_initialize_random()

	# Step 2: Apply CA smoothing passes
	for _pass in range(smooth_passes):
		_ca_smooth_step()

	# Step 3: Flood-fill to find all connected regions
	var regions = _find_all_regions()

	# Step 4: Keep only the largest region, fill rest with walls
	if regions.size() > 0:
		var largest_idx = 0
		var largest_size = 0
		for i in range(regions.size()):
			if regions[i].size() > largest_size:
				largest_size = regions[i].size()
				largest_idx = i

		# Fill all non-largest regions with walls
		for i in range(regions.size()):
			if i != largest_idx:
				for cell_idx_value in regions[i]:
					var cell_idx: int = int(cell_idx_value)
					_grid[cell_idx] = WALL_CELL

		# Step 5: Place entrance and exit at extremes of largest region
		var entrance_idx = _find_extreme(regions[largest_idx], true)
		var exit_idx = _find_extreme(regions[largest_idx], false)

		# Step 6: Render to image
		_render_to_texture(entrance_idx, exit_idx)
	else:
		_render_to_texture(-1, -1)


func _add_title_label() -> void:
	var title = Label3D.new()
	title.text = "Cave Generator (CA)"
	title.font_size = 28
	title.pixel_size = 0.001
	title.modulate = Color(0.7, 0.65, 0.55)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.rotation_degrees.x = -90
	title.position = Vector3(0, 0.006, display_size * 0.5 + 0.03)
	add_child(title)


func _initialize_random() -> void:
	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			# Border cells are always walls
			if x == 0 or x == grid_size - 1 or y == 0 or y == grid_size - 1:
				_grid[idx] = WALL_CELL
			else:
				_grid[idx] = WALL_CELL if _rng.randf() < wall_chance else FLOOR_CELL


func _ca_smooth_step() -> void:
	var next_grid = PackedInt32Array()
	next_grid.resize(grid_size * grid_size)

	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			# Border stays wall
			if x == 0 or x == grid_size - 1 or y == 0 or y == grid_size - 1:
				next_grid[idx] = WALL_CELL
				continue

			var wall_count = _count_wall_neighbors(x, y)
			if wall_count >= wall_threshold:
				next_grid[idx] = WALL_CELL
			else:
				next_grid[idx] = FLOOR_CELL

	_grid = next_grid


func _count_wall_neighbors(cx: int, cy: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = cx + dx
			var ny = cy + dy
			if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size:
				count += 1  # Out of bounds counts as wall
			elif _grid[ny * grid_size + nx] == WALL_CELL:
				count += 1
	return count


## Flood-fill to find all connected floor regions.
## Returns an array of arrays, where each inner array contains cell indices.
func _find_all_regions() -> Array:
	var visited = PackedByteArray()
	visited.resize(grid_size * grid_size)
	var regions: Array = []

	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			if _grid[idx] == FLOOR_CELL and visited[idx] == 0:
				var region = _flood_fill(x, y, visited)
				if region.size() > 0:
					regions.append(region)
	return regions


func _flood_fill(start_x: int, start_y: int, visited: PackedByteArray) -> Array:
	var region: Array = []
	var stack: Array = []
	stack.append(Vector2i(start_x, start_y))

	while stack.size() > 0:
		var pos: Vector2i = stack.pop_back() as Vector2i
		var px = pos.x
		var py = pos.y

		if px < 0 or px >= grid_size or py < 0 or py >= grid_size:
			continue

		var idx = py * grid_size + px
		if visited[idx] != 0:
			continue
		if _grid[idx] != FLOOR_CELL:
			continue

		visited[idx] = 1
		region.append(idx)

		# 4-directional flood fill
		stack.append(Vector2i(px + 1, py))
		stack.append(Vector2i(px - 1, py))
		stack.append(Vector2i(px, py + 1))
		stack.append(Vector2i(px, py - 1))

	return region


## Find the cell in a region closest to top-left (entrance) or bottom-right (exit).
func _find_extreme(region: Array, top_left: bool) -> int:
	var best_idx: int = int(region[0])
	var best_dist: float = INF

	for cell_idx_value in region:
		var cell_idx: int = int(cell_idx_value)
		var cx: int = cell_idx % grid_size
		var cy: int = int(cell_idx / grid_size)

		var target_x: float
		var target_y: float
		if top_left:
			target_x = 1.0
			target_y = 1.0
		else:
			target_x = float(grid_size - 2)
			target_y = float(grid_size - 2)

		var dx: float = float(cx) - target_x
		var dy: float = float(cy) - target_y
		var dist: float = dx * dx + dy * dy
		if dist < best_dist:
			best_dist = dist
			best_idx = cell_idx

	return best_idx


func _render_to_texture(entrance_idx: int, exit_idx: int) -> void:
	var image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBA8)

	for y in range(grid_size):
		for x in range(grid_size):
			var idx = y * grid_size + x
			if _grid[idx] == WALL_CELL:
				image.set_pixel(x, y, COLOR_WALL)
			else:
				image.set_pixel(x, y, COLOR_FLOOR)

	# Draw entrance and exit markers (3x3 dots)
	if entrance_idx >= 0:
		_draw_marker(image, entrance_idx, COLOR_ENTRANCE)
	if exit_idx >= 0:
		_draw_marker(image, exit_idx, COLOR_EXIT)

	var texture = ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


func _draw_marker(image: Image, cell_idx: int, color: Color) -> void:
	var cx: int = cell_idx % grid_size
	var cy: int = int(cell_idx / grid_size)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var px = cx + dx
			var py = cy + dy
			if px >= 0 and px < grid_size and py >= 0 and py < grid_size:
				image.set_pixel(px, py, color)


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"):
		seed_value = int(config_data["seed"])
	if config_data.has("wall_chance"):
		wall_chance = float(config_data["wall_chance"])
	if config_data.has("smooth_passes"):
		smooth_passes = int(config_data["smooth_passes"])
	if config_data.has("wall_threshold"):
		wall_threshold = int(config_data["wall_threshold"])
	_rng.seed = seed_value
	_generate_cave()
