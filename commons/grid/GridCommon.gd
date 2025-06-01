# GridCommon.gd
extends RefCounted
class_name GridCommon

# Path constants
const MAPS_PATH = "res://adaresearch/Common/Data/Maps/"
const MAP_OBJECTS_PATH = "res://adaresearch/Common/Scenes/Objects/MapObjects/"
const ARTIFACT_DATA_PATH = "res://adaresearch/Common/Scripts/Managers/artifact_data.gd"

# Task marker visualization states
const TASK_STATE = {
	"default": {"color": Color(0, 0.7, 1, 1), "energy": 2.0},    # Cyan-blue
	"active": {"color": Color(1, 0.8, 0, 1), "energy": 2.0},     # Yellow-orange
	"completed": {"color": Color(0, 1, 0, 1), "energy": 2.0}     # Green
}

# Convert grid to world position
static func grid_to_world_position(grid_pos: Vector3i, cube_size: float, gutter: float) -> Vector3:
	var total_size = cube_size + gutter
	return Vector3(grid_pos.x, grid_pos.y, grid_pos.z) * total_size

# Convert world to grid position
static func world_to_grid_position(world_pos: Vector3, cube_size: float, gutter: float) -> Vector3i:
	var total_size = cube_size + gutter
	return Vector3i(
		int(round(world_pos.x / total_size)),
		int(round(world_pos.y / total_size)),
		int(round(world_pos.z / total_size))
	)

# Check if grid position is within bounds
static func is_within_bounds(grid_pos: Vector3i, grid_size: Vector3i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and \
		   grid_pos.y >= 0 and grid_pos.y < grid_size.y and \
		   grid_pos.z >= 0 and grid_pos.z < grid_size.z

# Get neighbors in grid
static func get_grid_neighbors(grid_pos: Vector3i, include_diagonals: bool = false) -> Array:
	var neighbors = []
	
	if include_diagonals:
		# All 26 neighbors in 3D
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					if dx == 0 and dy == 0 and dz == 0:
						continue
					neighbors.append(grid_pos + Vector3i(dx, dy, dz))
	else:
		# Only 6 direct neighbors (faces)
		neighbors = [
			grid_pos + Vector3i(1, 0, 0),   # Right
			grid_pos + Vector3i(-1, 0, 0),  # Left
			grid_pos + Vector3i(0, 1, 0),   # Up
			grid_pos + Vector3i(0, -1, 0),  # Down
			grid_pos + Vector3i(0, 0, 1),   # Forward
			grid_pos + Vector3i(0, 0, -1)   # Back
		]
	
	return neighbors

# Calculate grid bounds from layout data
static func calculate_grid_bounds(layout_data: Array) -> Vector3i:
	if layout_data.is_empty():
		return Vector3i.ZERO
	
	var max_z = layout_data.size()
	var max_x = 0
	var max_y = 0
	
	for row in layout_data:
		if row.size() > max_x:
			max_x = row.size()
		
		# For structure data, find max height
		for cell in row:
			if typeof(cell) == TYPE_INT and cell > max_y:
				max_y = cell
			elif typeof(cell) == TYPE_STRING:
				var cell_int = cell.to_int()
				if cell_int > max_y:
					max_y = cell_int
	
	return Vector3i(max_x, max(max_y, 1), max_z)

# Generate consistent material hash for objects
static func generate_material_hash(object_name: String, position: Vector3i) -> int:
	var hash_string = "%s_%d_%d_%d" % [object_name, position.x, position.y, position.z]
	return hash_string.hash()

# Check if grid position is within bounds (alternative signature)
static func is_position_in_bounds(x: int, y: int, z: int, grid_x: int, grid_y: int, grid_z: int) -> bool:
	return is_within_bounds(Vector3i(x, y, z), Vector3i(grid_x, grid_y, grid_z))

# Find highest occupied Y position at a given X,Z coordinate
static func find_highest_y_at(grid: Array, x: int, z: int, grid_y: int) -> int:
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1  # Return position above the highest occupied space
	return 0  # Default to ground level if no occupied space found
