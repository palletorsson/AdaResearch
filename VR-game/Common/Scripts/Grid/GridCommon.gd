# GridCommon.gd
extends RefCounted
class_name GridCommon
# Path constants
const MAPS_PATH = "res://adaresearch/Common/Data/Maps/"
const MAP_OBJECTS_PATH = "res://adaresearch/Common/Scenes/Objects/MapObjects/"
const TASK_DATA_PATH = "res://adaresearch/Common/Scripts/Managers/task_data.gd"

# Utility type definitions with scene file names
const UTILITY_TYPES = {
	"l": {"name": "platform_lift", "file": "platform_lift_scene.tscn"},
	"w": {"name": "window", "file": "window_scene.tscn"},
	"d": {"name": "door", "file": "door_scene.tscn"},
	"t": {"name": "teleport", "file": "teleport_scene.tscn"},
	"a": {"name": "wall", "file": "wall_scene.tscn"},
	"b": {"name": "table", "file": "table_scene.tscn"},
	"p": {"name": "pick_up", "file": "pick_up_cube.tscn"},
	"x": {"name": "xp_label", "file": "xp_label.tscn"},
	"i": {"name": "xp_label", "file": "info_board.tscn"},
	"e": {"name": "explained", "file": "explain_board.tscn"},
	" ": {"name": "none", "file": ""}  # Empty space, no utility
}

# Empty space constant
const EMPTY_SPACE = " "

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
static func is_position_in_bounds(x: int, y: int, z: int, grid_x: int, grid_y: int, grid_z: int) -> bool:
	return x >= 0 and x < grid_x and y >= 0 and y < grid_y and z >= 0 and z < grid_z

# Find highest occupied Y position at a given X,Z coordinate
static func find_highest_y_at(grid: Array, x: int, z: int, grid_y: int) -> int:
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1  # Return position above the highest occupied space
	return 0  # Default to ground level if no occupied space found
