# grid_interface.gd
# Utility class for Grid Agents to interact with MultiMesh grid systems
extends RefCounted
class_name GridInterface

# Find nearest grid system at world position
static func get_grid_at_position(world_pos: Vector3) -> Node:
	# Search for grid systems in the scene tree
	# Priority order: GridStructureComponent > CellularAutomata3D > CAGrid
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	
	var root = tree.current_scene
	if not root:
		return null
	
	# Look for GridStructureComponent (from commons/grid/)
	var grid_systems = root.find_children("*", "GridStructureComponent", true, false)
	if grid_systems.size() > 0:
		# Find closest grid
		var closest_grid = null
		var min_distance = INF
		for grid in grid_systems:
			# GridStructureComponent is a Node, not Node3D
			# Use its parent_node's position if available
			var grid_pos = Vector3.ZERO
			if grid is Node3D:
				grid_pos = grid.global_position
			elif "parent_node" in grid and grid.parent_node is Node3D:
				grid_pos = grid.parent_node.global_position
			
			var distance = grid_pos.distance_to(world_pos)
			if distance < min_distance:
				min_distance = distance
				closest_grid = grid
		return closest_grid
	
	# Fallback: look for CA systems
	var ca_systems = root.find_children("*", "CellularAutomata3D", true, false)
	if ca_systems.size() > 0:
		return ca_systems[0]  # Return first CA system
	
	# Fallback: look for CAGrid
	var ca_grids = root.find_children("*", "CAGrid", true, false)
	if ca_grids.size() > 0:
		return ca_grids[0]
	
	return null

# Convert world position to grid cell coordinates
static func get_cell_at_position(grid: Node, world_pos: Vector3) -> Vector3i:
	if not grid:
		return Vector3i.ZERO
	
	# Get cell size from grid (different property names for different systems)
	var cell_size = 1.0
	if "cube_size" in grid:
		cell_size = grid.cube_size
	elif "cell_size" in grid:
		cell_size = grid.cell_size
	
	# Convert world position relative to grid origin
	var grid_origin = Vector3.ZERO
	if grid is Node3D:
		grid_origin = grid.global_position
	elif "parent_node" in grid and grid.parent_node is Node3D:
		# GridStructureComponent has a parent_node reference
		grid_origin = grid.parent_node.global_position
	
	var local_pos = world_pos - grid_origin
	
	# Quantize to grid coordinates
	var cell_x = int(round(local_pos.x / cell_size))
	var cell_y = int(round(local_pos.y / cell_size))
	var cell_z = int(round(local_pos.z / cell_size))
	
	return Vector3i(cell_x, cell_y, cell_z)

# Convert grid cell to world position (center of cell)
static func get_world_position_for_cell(grid: Node, cell_pos: Vector3i) -> Vector3:
	if not grid:
		return Vector3.ZERO
	
	var cell_size = 1.0
	if "cube_size" in grid:
		cell_size = grid.cube_size
	elif "cell_size" in grid:
		cell_size = grid.cell_size
	
	# Get grid origin
	var grid_origin = Vector3.ZERO
	if grid is Node3D:
		grid_origin = grid.global_position
	elif "parent_node" in grid and grid.parent_node is Node3D:
		# GridStructureComponent has a parent_node reference
		grid_origin = grid.parent_node.global_position
	
	var local_pos = Vector3(cell_pos) * cell_size
	return grid_origin + local_pos

# Check if cell has a cube (different methods for different grid types)
static func is_cell_occupied(grid: Node, cell_pos: Vector3i) -> bool:
	if not grid:
		return false
	
	# GridStructureComponent method (most common)
	if grid.has_method("has_cube_at"):
		return grid.has_cube_at(cell_pos.x, cell_pos.y, cell_pos.z)
	
	# CellularAutomata3D method
	if grid.has_method("is_alive"):
		return grid.is_alive(cell_pos.x, cell_pos.y, cell_pos.z)
	
	# CAGrid method
	if grid.has_method("get_cell"):
		var cell_state = grid.get_cell(cell_pos.x, cell_pos.y, cell_pos.z)
		return cell_state > 0
	
	return false

# Place cube at cell position
static func place_cube_at_cell(grid: Node, cell_pos: Vector3i, color: Color = Color.WHITE) -> bool:
	if not grid:
		return false
	
	# GridStructureComponent method (most common)
	if grid.has_method("add_cube_at"):
		return grid.add_cube_at(cell_pos.x, cell_pos.y, cell_pos.z)
	
	# CellularAutomata3D method
	if grid.has_method("set_cell_alive"):
		grid.set_cell_alive(cell_pos.x, cell_pos.y, cell_pos.z, true)
		return true
	
	# CAGrid method
	if grid.has_method("set_cell"):
		grid.set_cell(cell_pos.x, cell_pos.y, cell_pos.z, 1)
		return true
	
	return false

# Remove cube from cell
static func remove_cube_at_cell(grid: Node, cell_pos: Vector3i) -> bool:
	if not grid:
		return false
	
	# GridStructureComponent method (now supported!)
	if grid.has_method("remove_cube_at"):
		return grid.remove_cube_at(cell_pos.x, cell_pos.y, cell_pos.z)
	
	# CellularAutomata3D method
	if grid.has_method("set_cell_alive"):
		grid.set_cell_alive(cell_pos.x, cell_pos.y, cell_pos.z, false)
		return true
	
	# CAGrid method
	if grid.has_method("set_cell"):
		grid.set_cell(cell_pos.x, cell_pos.y, cell_pos.z, 0)
		return true
	
	return false

# Get cube data (color, state, etc.)
static func get_cube_at_cell(grid: Node, cell_pos: Vector3i) -> Dictionary:
	var result = {
		"exists": false,
		"color": Color.WHITE,
		"state": 0
	}
	
	if not grid:
		return result
	
	result.exists = is_cell_occupied(grid, cell_pos)
	
	# Try to get color if available
	if grid.has_method("get_cube_color"):
		result.color = grid.get_cube_color(cell_pos.x, cell_pos.y, cell_pos.z)
	
	# Try to get state if available
	if grid.has_method("get_cell"):
		result.state = grid.get_cell(cell_pos.x, cell_pos.y, cell_pos.z)
	
	return result

# Get 26 neighboring cells (3D Moore neighborhood)
static func get_neighbors_moore(cell_pos: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				# Skip center cell
				if dx == 0 and dy == 0 and dz == 0:
					continue
				
				neighbors.append(cell_pos + Vector3i(dx, dy, dz))
	
	return neighbors

# Get 6 neighboring cells (3D Von Neumann neighborhood)
static func get_neighbors_von_neumann(cell_pos: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	
	# Six cardinal directions
	neighbors.append(cell_pos + Vector3i(1, 0, 0))   # East
	neighbors.append(cell_pos + Vector3i(-1, 0, 0))  # West
	neighbors.append(cell_pos + Vector3i(0, 1, 0))   # Up
	neighbors.append(cell_pos + Vector3i(0, -1, 0))  # Down
	neighbors.append(cell_pos + Vector3i(0, 0, 1))   # North
	neighbors.append(cell_pos + Vector3i(0, 0, -1))  # South
	
	return neighbors

# Count occupied neighbors (Moore neighborhood)
static func count_occupied_neighbors_moore(grid: Node, cell_pos: Vector3i) -> int:
	var count = 0
	var neighbors = get_neighbors_moore(cell_pos)
	
	for neighbor in neighbors:
		if is_cell_occupied(grid, neighbor):
			count += 1
	
	return count

# Count occupied neighbors (Von Neumann neighborhood)
static func count_occupied_neighbors_von_neumann(grid: Node, cell_pos: Vector3i) -> int:
	var count = 0
	var neighbors = get_neighbors_von_neumann(cell_pos)
	
	for neighbor in neighbors:
		if is_cell_occupied(grid, neighbor):
			count += 1
	
	return count

# Get all occupied cells in a region (bounding box)
static func get_occupied_cells_in_region(grid: Node, min_pos: Vector3i, max_pos: Vector3i) -> Array[Vector3i]:
	var occupied: Array[Vector3i] = []
	
	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			for z in range(min_pos.z, max_pos.z + 1):
				var cell_pos = Vector3i(x, y, z)
				if is_cell_occupied(grid, cell_pos):
					occupied.append(cell_pos)
	
	return occupied

# Find nearest occupied cell to a given position
static func find_nearest_occupied_cell(grid: Node, start_pos: Vector3i, max_search_radius: int = 10) -> Vector3i:
	# Breadth-first search outward from start position
	for radius in range(1, max_search_radius + 1):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				for z in range(-radius, radius + 1):
					# Only check cells on the current radius shell
					if abs(x) == radius or abs(y) == radius or abs(z) == radius:
						var cell_pos = start_pos + Vector3i(x, y, z)
						if is_cell_occupied(grid, cell_pos):
							return cell_pos
	
	return start_pos  # Return start if nothing found

# Get grid dimensions (if available)
static func get_grid_bounds(grid: Node) -> Dictionary:
	var bounds = {
		"min": Vector3i.ZERO,
		"max": Vector3i.ZERO,
		"size": Vector3i.ZERO
	}
	
	if not grid:
		return bounds
	
	# GridStructureComponent method
	if grid.has_method("get_grid_dimensions"):
		var dims = grid.get_grid_dimensions()
		bounds.size = Vector3i(dims.x, dims.y, dims.z)
		bounds.max = bounds.size - Vector3i.ONE
		return bounds
	
	# CellularAutomata3D properties
	if "grid_size" in grid:
		var size = grid.grid_size
		bounds.size = Vector3i(size.x, size.y, size.z)
		bounds.max = bounds.size - Vector3i.ONE
		return bounds
	
	return bounds
