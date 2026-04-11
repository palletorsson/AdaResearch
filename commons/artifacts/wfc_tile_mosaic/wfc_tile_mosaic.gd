extends Node3D
class_name WfcTileMosaic

## WFC Tile Mosaic — Floor panel showing a pre-generated Wave Function Collapse output.
##
## A grid of tiles where each cell respects adjacency constraints, solved via
## constraint propagation and backtracking. Like array_carpet but for WFC.

# --- Configuration ---

@export var mosaic_world_size: Vector2 = Vector2(0.8, 0.8)
@export var grid_size: int = 16
@export var pixel_scale: int = 4  ## Each tile rendered as NxN pixels for detail

# --- Tile definitions ---
# Each tile type has a color and a 2x2 pixel pattern.
# Adjacency rules: which tile types can be neighbors (up/right/down/left).

enum Tile { GROUND, WATER, SAND, GRASS, STONE, PATH }

var _tile_colors: Dictionary = {
	Tile.GROUND: Color(0.55, 0.45, 0.35),
	Tile.WATER:  Color(0.15, 0.35, 0.65),
	Tile.SAND:   Color(0.85, 0.78, 0.55),
	Tile.GRASS:  Color(0.25, 0.55, 0.2),
	Tile.STONE:  Color(0.5, 0.5, 0.55),
	Tile.PATH:   Color(0.7, 0.6, 0.45),
}

# 2x2 pixel micro-patterns per tile type (row-major)
var _tile_patterns: Dictionary = {
	Tile.GROUND: [Color(0.55, 0.45, 0.35), Color(0.5, 0.42, 0.32),
				  Color(0.52, 0.43, 0.34), Color(0.57, 0.47, 0.36)],
	Tile.WATER:  [Color(0.15, 0.35, 0.65), Color(0.2, 0.4, 0.7),
				  Color(0.18, 0.38, 0.68), Color(0.12, 0.32, 0.62)],
	Tile.SAND:   [Color(0.85, 0.78, 0.55), Color(0.82, 0.75, 0.52),
				  Color(0.88, 0.8, 0.58), Color(0.84, 0.76, 0.54)],
	Tile.GRASS:  [Color(0.25, 0.55, 0.2), Color(0.28, 0.58, 0.22),
				  Color(0.22, 0.52, 0.18), Color(0.26, 0.56, 0.21)],
	Tile.STONE:  [Color(0.5, 0.5, 0.55), Color(0.48, 0.48, 0.52),
				  Color(0.52, 0.52, 0.56), Color(0.46, 0.46, 0.5)],
	Tile.PATH:   [Color(0.7, 0.6, 0.45), Color(0.68, 0.58, 0.42),
				  Color(0.72, 0.62, 0.47), Color(0.66, 0.56, 0.4)],
}

# Adjacency rules: for each tile, which tiles may appear next to it.
# Symmetric — if A can neighbor B, B can neighbor A.
var _adjacency: Dictionary = {
	Tile.GROUND: [Tile.GROUND, Tile.SAND, Tile.GRASS, Tile.STONE, Tile.PATH],
	Tile.WATER:  [Tile.WATER, Tile.SAND],
	Tile.SAND:   [Tile.SAND, Tile.WATER, Tile.GROUND, Tile.PATH],
	Tile.GRASS:  [Tile.GRASS, Tile.GROUND, Tile.PATH],
	Tile.STONE:  [Tile.STONE, Tile.GROUND, Tile.PATH],
	Tile.PATH:   [Tile.PATH, Tile.GROUND, Tile.SAND, Tile.GRASS, Tile.STONE],
}

# --- Internal ---

var _mosaic_mesh: MeshInstance3D
var _mosaic_material: StandardMaterial3D
var _rng: RandomNumberGenerator
var _all_tiles: Array = [Tile.GROUND, Tile.WATER, Tile.SAND, Tile.GRASS, Tile.STONE, Tile.PATH]


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(str(global_position) + str(get_instance_id()))
	_create_mosaic_mesh()
	_generate_wfc()


func _create_mosaic_mesh() -> void:
	_mosaic_mesh = MeshInstance3D.new()
	_mosaic_mesh.name = "MosaicMesh"

	var quad := QuadMesh.new()
	quad.size = mosaic_world_size
	_mosaic_mesh.mesh = quad

	# Lie flat on the floor
	_mosaic_mesh.rotation_degrees.x = -90
	_mosaic_mesh.position.y = 0.005

	# Material
	_mosaic_material = StandardMaterial3D.new()
	_mosaic_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mosaic_material.roughness = 0.85
	_mosaic_material.metallic = 0.0
	_mosaic_mesh.material_override = _mosaic_material

	add_child(_mosaic_mesh)


func _generate_wfc() -> void:
	var grid: Array = _solve_wfc()
	_render_grid(grid)


# --- WFC Solver ---

func _solve_wfc() -> Array:
	# Each cell holds an array of possible tile types (superposition).
	# We collapse one cell at a time, propagate constraints, backtrack on contradiction.
	var max_attempts := 10
	for _attempt in range(max_attempts):
		var result := _attempt_solve()
		if result.size() > 0:
			return result
		# Failed — retry with different seed
		_rng.seed = _rng.randi()
	# Fallback: return a simple checkerboard
	return _fallback_grid()


func _attempt_solve() -> Array:
	var possibilities: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(_all_tiles.duplicate())
		possibilities.append(row)

	var collapsed: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(-1)
		collapsed.append(row)

	# Track collapse history for backtracking
	var history: Array = []
	var cells_remaining := grid_size * grid_size
	var max_iterations := grid_size * grid_size * 20  # Safety cap
	var iteration := 0

	while cells_remaining > 0 and iteration < max_iterations:
		iteration += 1
		# Find cell with lowest entropy (fewest possibilities) among uncollapsed
		var min_entropy := 999
		var candidates: Array = []
		for y in range(grid_size):
			for x in range(grid_size):
				if collapsed[y][x] != -1:
					continue
				var entropy: int = possibilities[y][x].size()
				if entropy == 0:
					# Contradiction — try backtracking
					if not _backtrack(history, possibilities, collapsed):
						return []  # Cannot recover
					cells_remaining += 1
					min_entropy = 999
					candidates.clear()
					break
				if entropy < min_entropy:
					min_entropy = entropy
					candidates = [Vector2i(x, y)]
				elif entropy == min_entropy:
					candidates.append(Vector2i(x, y))
			if min_entropy == 999 and candidates.is_empty():
				break  # Restarting inner loop after backtrack

		if candidates.is_empty():
			continue

		# Pick a random candidate among those with lowest entropy
		var pick: Vector2i = candidates[_rng.randi() % candidates.size()]
		var px: int = pick.x
		var py: int = pick.y
		var opts: Array = possibilities[py][px]

		if opts.is_empty():
			if not _backtrack(history, possibilities, collapsed):
				return []
			cells_remaining += 1
			continue

		# Collapse: pick a weighted random tile
		var chosen: int = opts[_rng.randi() % opts.size()]

		# Save state for backtracking
		history.append({
			"pos": pick,
			"chosen": chosen,
			"old_possibilities": _deep_copy_possibilities(possibilities),
			"old_collapsed": _deep_copy_collapsed(collapsed),
		})
		# Limit history to prevent excessive memory use
		if history.size() > 200:
			history = history.slice(history.size() - 100)

		collapsed[py][px] = chosen
		possibilities[py][px] = [chosen]
		cells_remaining -= 1

		# Propagate constraints
		if not _propagate(possibilities, collapsed):
			if not _backtrack(history, possibilities, collapsed):
				return []
			cells_remaining = _count_remaining(collapsed)

	if iteration >= max_iterations:
		return []  # Exceeded iteration budget — signal failure
	return collapsed


func _propagate(possibilities: Array, collapsed: Array) -> bool:
	# Iteratively remove impossible tiles based on neighbor constraints
	var changed := true
	var iterations := 0
	while changed and iterations < 200:
		changed = false
		iterations += 1
		for y in range(grid_size):
			for x in range(grid_size):
				if collapsed[y][x] != -1:
					continue
				var current_opts: Array = possibilities[y][x]
				var new_opts: Array = []
				for tile in current_opts:
					if _is_compatible(tile, x, y, possibilities, collapsed):
						new_opts.append(tile)
				if new_opts.size() < current_opts.size():
					changed = true
					possibilities[y][x] = new_opts
					if new_opts.is_empty():
						return false  # Contradiction
	return true


func _is_compatible(tile: int, x: int, y: int, possibilities: Array, collapsed: Array) -> bool:
	var neighbors := [
		Vector2i(x, y - 1),  # up
		Vector2i(x + 1, y),  # right
		Vector2i(x, y + 1),  # down
		Vector2i(x - 1, y),  # left
	]
	var allowed: Array = _adjacency[tile]
	for n_pos in neighbors:
		if n_pos.x < 0 or n_pos.x >= grid_size or n_pos.y < 0 or n_pos.y >= grid_size:
			continue
		# Check if at least one possibility of the neighbor is allowed
		var n_opts: Array
		if collapsed[n_pos.y][n_pos.x] != -1:
			n_opts = [collapsed[n_pos.y][n_pos.x]]
		else:
			n_opts = possibilities[n_pos.y][n_pos.x]
		var any_allowed := false
		for n_tile in n_opts:
			if n_tile in allowed:
				any_allowed = true
				break
		if not any_allowed:
			return false
	return true


func _backtrack(history: Array, possibilities: Array, collapsed: Array) -> bool:
	if history.is_empty():
		return false
	var last: Dictionary = history.pop_back()
	# Restore state
	var old_p: Array = last["old_possibilities"]
	var old_c: Array = last["old_collapsed"]
	for y in range(grid_size):
		for x in range(grid_size):
			possibilities[y][x] = old_p[y][x]
			collapsed[y][x] = old_c[y][x]
	# Remove the failed choice from possibilities
	var pos: Vector2i = last["pos"]
	var failed_tile: int = last["chosen"]
	possibilities[pos.y][pos.x].erase(failed_tile)
	return possibilities[pos.y][pos.x].size() > 0


func _count_remaining(collapsed: Array) -> int:
	var count := 0
	for y in range(grid_size):
		for x in range(grid_size):
			if collapsed[y][x] == -1:
				count += 1
	return count


func _deep_copy_possibilities(p: Array) -> Array:
	var copy: Array = []
	for y in range(p.size()):
		var row: Array = []
		for x in range(p[y].size()):
			row.append(p[y][x].duplicate())
		copy.append(row)
	return copy


func _deep_copy_collapsed(c: Array) -> Array:
	var copy: Array = []
	for y in range(c.size()):
		copy.append(c[y].duplicate())
	return copy


func _fallback_grid() -> Array:
	var grid: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(((x + y) % 2) * 3)  # Alternating GROUND/GRASS
		grid.append(row)
	return grid


# --- Rendering ---

func _render_grid(grid: Array) -> void:
	var tex_size := grid_size * pixel_scale
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)

	for gy in range(grid_size):
		for gx in range(grid_size):
			var tile_type: int = grid[gy][gx]
			if tile_type < 0:
				tile_type = Tile.GROUND
			var pattern: Array = _tile_patterns.get(tile_type, _tile_patterns[Tile.GROUND])
			# Draw each tile as pixel_scale x pixel_scale block with 2x2 micro-pattern
			for py in range(pixel_scale):
				for px in range(pixel_scale):
					var pi: int = (py % 2) * 2 + (px % 2)
					var color: Color = pattern[pi]
					image.set_pixel(gx * pixel_scale + px, gy * pixel_scale + py, color)

	# Add subtle grid lines between tiles
	var line_color := Color(0.0, 0.0, 0.0, 0.15)
	for g in range(grid_size + 1):
		var pixel_pos := g * pixel_scale
		if pixel_pos >= tex_size:
			pixel_pos = tex_size - 1
		for i in range(tex_size):
			if pixel_pos < tex_size:
				var existing := image.get_pixel(clampi(pixel_pos, 0, tex_size - 1), i)
				image.set_pixel(clampi(pixel_pos, 0, tex_size - 1), i, existing.lerp(line_color, 0.3))
				existing = image.get_pixel(i, clampi(pixel_pos, 0, tex_size - 1))
				image.set_pixel(i, clampi(pixel_pos, 0, tex_size - 1), existing.lerp(line_color, 0.3))

	var texture := ImageTexture.create_from_image(image)
	_mosaic_material.albedo_texture = texture


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_size"):
		grid_size = int(config_data["grid_size"])
	if config_data.has("pixel_scale"):
		pixel_scale = int(config_data["pixel_scale"])
	# Re-generate with new configuration
	_rng.seed = hash(str(global_position) + str(get_instance_id()))
	_generate_wfc()
