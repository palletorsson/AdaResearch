extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var generation_interval = 0.4

var current_level = 0
var generation_timer = 0.0
var grid = {}  # Dictionary to store 3D grid: Vector3i -> 1/0

# Tree structure definition:
# Levels 0-7: 4x4 base
# Levels 8-10: expand to 5x5, 6x6, 7x7
# Levels 11-14: 4 levels up (maintain 7x7)
# Levels 15-18: shrink to 0 over 4 levels (7->5->3->1->0)

func _ready():
	print("Cellular Automata 3D Tree - Structured Form initialized")
	build_initial_base()

func _process(delta):
	generation_timer += delta
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		grow_next_level()

func build_initial_base():
	# Build the 4x4 base from level 0 to level 7
	for level in range(8):
		create_square_layer(level, 4)
	current_level = 8

func grow_next_level():
	# Expansion phase: levels 8-10 (5x5, 6x6, 7x7)
	if current_level >= 8 and current_level <= 10:
		var size = 5 + (current_level - 8)  # 5, 6, 7
		create_square_layer(current_level, size)
		apply_ca_pruning(current_level, size)
		current_level += 1
	# Maintain phase: levels 11-14 (keep 7x7)
	elif current_level >= 11 and current_level <= 14:
		create_square_layer(current_level, 7)
		apply_ca_pruning(current_level, 7)
		current_level += 1
	# Shrink phase: levels 15-18 (7->5->3->1)
	elif current_level >= 15 and current_level <= 18:
		var shrink_step = current_level - 15  # 0, 1, 2, 3
		var size = 7 - (shrink_step * 2)  # 7, 5, 3, 1
		if size > 0:
			create_square_layer(current_level, size)
			apply_ca_pruning(current_level, size)
		current_level += 1
	else:
		# Tree complete
		set_process(false)
		print("Tree growth complete at level: ", current_level)

func create_square_layer(level: int, size: int):
	# Create a square layer of cubes centered at this height level
	var half_size = size / 2.0

	for x in range(size):
		for z in range(size):
			var grid_pos = Vector3i(x, level, z)
			grid[grid_pos] = 1  # Mark as alive in grid

			var cell = CUBE_SCENE.instantiate()
			cell.name = "cell_L" + str(level) + "_" + str(x) + "_" + str(z)
			cell.scale = Vector3(0.5, 0.5, 0.5)

			# Position cubes in a square centered at origin
			var pos_x = (x - half_size + 0.5) * 0.55
			var pos_y = level * 0.55
			var pos_z = (z - half_size + 0.5) * 0.55

			cell.position = Vector3(pos_x, pos_y, pos_z)
			add_child(cell)

func apply_ca_pruning(level: int, size: int):
	# Apply cellular automata rules to remove some cubes for organic shape
	# Rules:
	# 1. Remove corner cubes (more exposed, less support)
	# 2. Remove cubes with too few neighbors (isolated)
	# 3. Random removal for organic variation

	var half_size = size / 2.0
	var cubes_to_remove = []

	for x in range(size):
		for z in range(size):
			var grid_pos = Vector3i(x, level, z)

			if not grid.has(grid_pos) or grid[grid_pos] == 0:
				continue

			# Calculate distance from center (for corner detection)
			var center_x = size / 2.0
			var center_z = size / 2.0
			var dist_from_center = Vector2(x - center_x, z - center_z).length()
			var max_dist = Vector2(center_x, center_z).length()
			var edge_factor = dist_from_center / max_dist

			# Count neighbors in same layer (8-connected)
			var neighbor_count = count_neighbors_2d(x, level, z, size)

			var should_remove = false

			# Rule 1: Higher chance to remove corners/edges (based on distance)
			if edge_factor > 0.7 and randf() < 0.4:
				should_remove = true

			# Rule 2: Remove isolated cubes (fewer than 3 neighbors)
			if neighbor_count < 3 and randf() < 0.5:
				should_remove = true

			# Rule 3: Random organic variation (10-20% removal)
			var removal_chance = 0.1 + (level / 20.0) * 0.1  # More removal at higher levels
			if randf() < removal_chance:
				should_remove = true

			# Don't remove if in center (keep structural integrity)
			if abs(x - center_x) < 1.0 and abs(z - center_z) < 1.0:
				should_remove = false

			if should_remove:
				cubes_to_remove.append(grid_pos)

	# Remove marked cubes
	for grid_pos in cubes_to_remove:
		grid[grid_pos] = 0
		var node_name = "cell_L" + str(grid_pos.y) + "_" + str(grid_pos.x) + "_" + str(grid_pos.z)
		var node = get_node_or_null(node_name)
		if node:
			node.queue_free()

func count_neighbors_2d(x: int, level: int, z: int, size: int) -> int:
	# Count neighbors in the same horizontal layer (2D, 8-connected)
	var count = 0
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue

			var nx = x + dx
			var nz = z + dz

			if nx >= 0 and nx < size and nz >= 0 and nz < size:
				var neighbor_pos = Vector3i(nx, level, nz)
				if grid.has(neighbor_pos) and grid[neighbor_pos] == 1:
					count += 1

	return count
