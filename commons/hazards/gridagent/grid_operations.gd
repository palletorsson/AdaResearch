# grid_operations.gd
# Implements grid manipulation operations for each evolution tier
extends RefCounted
class_name GridOperations

# ===== TIER 1: COPY =====
# Duplicate a single cube to a target position
static func copy_cube(grid: Node, source: Vector3i, target: Vector3i) -> bool:
	if not GridInterface.is_cell_occupied(grid, source):
		print("GridOperations.copy_cube: Source %s is empty" % [source])
		return false  # Nothing to copy
	
	if GridInterface.is_cell_occupied(grid, target):
		print("GridOperations.copy_cube: Target %s is occupied" % [target])
		return false  # Target occupied
	
	var cube_data = GridInterface.get_cube_at_cell(grid, source)
	print("GridOperations.copy_cube: Copying cube from %s to %s" % [source, target])
	var success = GridInterface.place_cube_at_cell(grid, target, cube_data.color)
	print("GridOperations.copy_cube: Result = %s" % [success])
	return success

# Copy a cube adjacent to source
static func copy_cube_adjacent(grid: Node, source: Vector3i, direction: Vector3i) -> bool:
	var target = source + direction
	return copy_cube(grid, source, target)

# ===== TIER 2: TRANSLATE =====
# Move a cube from one position to another
static func translate_cube(grid: Node, from: Vector3i, to: Vector3i) -> bool:
	if not GridInterface.is_cell_occupied(grid, from):
		return false  # Nothing to move
	
	if GridInterface.is_cell_occupied(grid, to):
		return false  # Target occupied
	
	var cube_data = GridInterface.get_cube_at_cell(grid, from)
	GridInterface.remove_cube_at_cell(grid, from)
	return GridInterface.place_cube_at_cell(grid, to, cube_data.color)

# Translate cube in a direction by N steps
static func translate_cube_direction(grid: Node, from: Vector3i, direction: Vector3i, distance: int = 1) -> bool:
	var to = from + (direction * distance)
	return translate_cube(grid, from, to)

# ===== TIER 3: ROTATE =====
# Rotate a structure 90° around an axis
static func rotate_structure_90(grid: Node, center: Vector3i, axis: Vector3i, radius: int = 3) -> bool:
	# Get all cubes in the rotation radius
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	print("GridOperations.rotate_structure_90: Found %d cubes around %s" % [cubes.size(), center])
	
	if cubes.size() == 0:
		return false
	
	# Store cube data before rotation
	var cube_states = {}
	var removed_count = 0
	for cube_pos in cubes:
		cube_states[cube_pos] = GridInterface.get_cube_at_cell(grid, cube_pos)
		if GridInterface.remove_cube_at_cell(grid, cube_pos):
			removed_count += 1
	
	print("GridOperations.rotate_structure_90: Removed %d cubes for rotation" % removed_count)
	
	# Rotate each cube's position
	var placed_count = 0
	for cube_pos in cubes:
		var rotated_pos = _rotate_point_90(cube_pos, center, axis)
		var cube_data = cube_states[cube_pos]
		if GridInterface.place_cube_at_cell(grid, rotated_pos, cube_data.color):
			placed_count += 1
	
	print("GridOperations.rotate_structure_90: Placed %d cubes at rotated positions" % placed_count)
	return true

# Helper: Rotate a point 90° around axis at center
static func _rotate_point_90(point: Vector3i, center: Vector3i, axis: Vector3i) -> Vector3i:
	var offset = point - center
	var rotated_offset = Vector3i.ZERO
	
	# Normalize axis to cardinal direction
	var normalized_axis = Vector3i(
		1 if abs(axis.x) > 0 else 0,
		1 if abs(axis.y) > 0 else 0,
		1 if abs(axis.z) > 0 else 0
	)
	
	# Rotate around Y-axis (vertical)
	if normalized_axis.y > 0:
		rotated_offset.x = -offset.z
		rotated_offset.y = offset.y
		rotated_offset.z = offset.x
	# Rotate around X-axis
	elif normalized_axis.x > 0:
		rotated_offset.x = offset.x
		rotated_offset.y = -offset.z
		rotated_offset.z = offset.y
	# Rotate around Z-axis
	elif normalized_axis.z > 0:
		rotated_offset.x = -offset.y
		rotated_offset.y = offset.x
		rotated_offset.z = offset.z
	
	return center + rotated_offset

# ===== TIER 4: SCALE =====
# Scale a structure (make larger or smaller)
static func scale_structure(grid: Node, center: Vector3i, scale_factor: float, radius: int = 3) -> bool:
	# Get all cubes in the region
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if cubes.size() == 0:
		return false
	
	# Store cube data
	var cube_states = {}
	for cube_pos in cubes:
		cube_states[cube_pos] = GridInterface.get_cube_at_cell(grid, cube_pos)
		GridInterface.remove_cube_at_cell(grid, cube_pos)
	
	# Scale each cube's position relative to center
	for cube_pos in cubes:
		var offset = cube_pos - center
		var scaled_offset = Vector3i(
			int(round(offset.x * scale_factor)),
			int(round(offset.y * scale_factor)),
			int(round(offset.z * scale_factor))
		)
		var new_pos = center + scaled_offset
		
		var cube_data = cube_states[cube_pos]
		GridInterface.place_cube_at_cell(grid, new_pos, cube_data.color)
	
	return true

# ===== MODIFIER EXTENSIONS: MIRROR / TWIST =====
# Mirror a structure across a center-aligned axis plane.
# Axis is one of: "x", "y", "z"
# keep_original=true behaves like a duplicate mirror modifier.
static func mirror_structure(grid: Node, center: Vector3i, axis: String = "x", radius: int = 3, keep_original: bool = true) -> bool:
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if cubes.is_empty():
		return false
	
	var axis_name = axis.strip_edges().to_lower()
	if axis_name != "x" and axis_name != "y" and axis_name != "z":
		axis_name = "x"
	
	var cube_states = {}
	for cube_pos in cubes:
		cube_states[cube_pos] = GridInterface.get_cube_at_cell(grid, cube_pos)
	
	# If we are performing a pure reflection, clear source first.
	if not keep_original:
		for cube_pos in cubes:
			GridInterface.remove_cube_at_cell(grid, cube_pos)
	
	var placed_count = 0
	for cube_pos in cubes:
		var mirrored_pos = _mirror_point(cube_pos, center, axis_name)
		var cube_data = cube_states[cube_pos]
		
		if not GridInterface.is_cell_occupied(grid, mirrored_pos):
			if GridInterface.place_cube_at_cell(grid, mirrored_pos, cube_data.color):
				placed_count += 1
	
	return placed_count > 0

# Twist structure by applying a rotation that increases along the chosen axis.
# This gives a voxel approximation of a twist deform.
static func twist_structure(grid: Node, center: Vector3i, angle_degrees: float = 15.0, radius: int = 3, axis: String = "y") -> bool:
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if cubes.is_empty():
		return false
	
	var axis_name = axis.strip_edges().to_lower()
	if axis_name != "x" and axis_name != "y" and axis_name != "z":
		axis_name = "y"
	
	# Snapshot and clear before re-placement.
	var cube_states = {}
	for cube_pos in cubes:
		cube_states[cube_pos] = GridInterface.get_cube_at_cell(grid, cube_pos)
		GridInterface.remove_cube_at_cell(grid, cube_pos)
	
	var placed_count = 0
	for cube_pos in cubes:
		var twisted_pos = _twist_point(cube_pos, center, angle_degrees, axis_name)
		var cube_data = cube_states[cube_pos]
		
		if not GridInterface.is_cell_occupied(grid, twisted_pos):
			if GridInterface.place_cube_at_cell(grid, twisted_pos, cube_data.color):
				placed_count += 1
	
	return placed_count > 0

# ===== TIER 5: COLOR (Placeholder for future implementation) =====
# Change cube colors in a region
static func colorize_region(grid: Node, center: Vector3i, color: Color, radius: int = 3) -> bool:
	# Get all cubes in region
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if cubes.size() == 0:
		return false
	
	# Recolor each cube
	for cube_pos in cubes:
		GridInterface.remove_cube_at_cell(grid, cube_pos)
		GridInterface.place_cube_at_cell(grid, cube_pos, color)
	
	return true

# ===== TIER 6: ARRAY =====
# Create a linear array of a structure
static func array_linear(grid: Node, source_center: Vector3i, direction: Vector3i, count: int, spacing: int = 2, radius: int = 2) -> bool:
	# Get source structure
	var min_pos = source_center - Vector3i.ONE * radius
	var max_pos = source_center + Vector3i.ONE * radius
	var source_cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if source_cubes.size() == 0:
		return false
	
	# Normalize direction
	var dir_normalized = Vector3i(
		1 if direction.x != 0 else 0,
		1 if direction.y != 0 else 0,
		1 if direction.z != 0 else 0
	)
	
	# Copy structure multiple times along direction
	for i in range(1, count + 1):
		var offset = dir_normalized * (spacing * i)
		
		for cube_pos in source_cubes:
			var new_pos = cube_pos + offset
			var cube_data = GridInterface.get_cube_at_cell(grid, cube_pos)
			
			# Don't overwrite existing cubes
			if not GridInterface.is_cell_occupied(grid, new_pos):
				GridInterface.place_cube_at_cell(grid, new_pos, cube_data.color)
	
	return true

# ===== TIER 7: SINE =====
# Apply sine wave transformation to structure heights
static func apply_sine_wave(grid: Node, center: Vector3i, amplitude: float, frequency: float, radius: int = 5, axis: String = "x") -> bool:
	# Get all cubes in region
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	var cubes = GridInterface.get_occupied_cells_in_region(grid, min_pos, max_pos)
	
	if cubes.size() == 0:
		return false
	
	# Store cube data and remove cubes
	var cube_states = {}
	for cube_pos in cubes:
		cube_states[cube_pos] = GridInterface.get_cube_at_cell(grid, cube_pos)
		GridInterface.remove_cube_at_cell(grid, cube_pos)
	
	# Apply sine wave to heights
	for cube_pos in cubes:
		var wave_input = 0.0
		
		# Choose axis for wave propagation
		match axis.to_lower():
			"x":
				wave_input = float(cube_pos.x - center.x)
			"z":
				wave_input = float(cube_pos.z - center.z)
			_:
				wave_input = float(cube_pos.x - center.x)
		
		# Calculate sine wave offset
		var sine_value = sin(wave_input * frequency)
		var y_offset = int(round(sine_value * amplitude))
		
		# Apply offset
		var new_pos = Vector3i(cube_pos.x, cube_pos.y + y_offset, cube_pos.z)
		var cube_data = cube_states[cube_pos]
		GridInterface.place_cube_at_cell(grid, new_pos, cube_data.color)
	
	return true

# ===== TIER 8: RANDOM =====
# Add random variation to a structure
static func randomize_structure(grid: Node, center: Vector3i, probability: float, radius: int = 3) -> bool:
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	
	var changes_made = false
	
	# Randomly add or remove cubes
	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			for z in range(min_pos.z, max_pos.z + 1):
				var cell_pos = Vector3i(x, y, z)
				var is_occupied = GridInterface.is_cell_occupied(grid, cell_pos)
				
				if randf() < probability:
					if is_occupied:
						# Random removal
						GridInterface.remove_cube_at_cell(grid, cell_pos)
						changes_made = true
					else:
						# Random addition (with random color)
						var random_color = Color(randf(), randf(), randf())
						GridInterface.place_cube_at_cell(grid, cell_pos, random_color)
						changes_made = true
	
	return changes_made

# ===== TIER 9: CA (Cellular Automata) =====
# Apply CA rules (using existing CA systems)
static func apply_ca_step(grid: Node, center: Vector3i, rule_type: String, radius: int = 5) -> bool:
	# For now, apply simple rules manually
	# Later: integrate with CellularAutomata3D rules
	
	match rule_type:
		"growth":
			return _apply_crystal_growth(grid, center, radius)
		"erosion":
			return _apply_erosion(grid, center, radius)
		_:
			print("GridOperations: Unknown CA rule '%s'" % rule_type)
			return false

# Simple crystal growth rule: cell becomes alive if it has 2-4 neighbors
static func _apply_crystal_growth(grid: Node, center: Vector3i, radius: int) -> bool:
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	
	# Calculate new states (don't modify grid yet)
	var cells_to_add = []
	
	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			for z in range(min_pos.z, max_pos.z + 1):
				var cell_pos = Vector3i(x, y, z)
				var is_alive = GridInterface.is_cell_occupied(grid, cell_pos)
				var neighbor_count = GridInterface.count_occupied_neighbors_von_neumann(grid, cell_pos)
				
				# Rule: Empty cells with 2-4 neighbors become alive
				if not is_alive and neighbor_count >= 2 and neighbor_count <= 4:
					cells_to_add.append(cell_pos)
	
	# Apply changes
	for cell_pos in cells_to_add:
		GridInterface.place_cube_at_cell(grid, cell_pos, Color.CYAN)
	
	return cells_to_add.size() > 0

# Simple erosion rule: cell dies if it has < 2 neighbors
static func _apply_erosion(grid: Node, center: Vector3i, radius: int) -> bool:
	var min_pos = center - Vector3i.ONE * radius
	var max_pos = center + Vector3i.ONE * radius
	
	# Calculate new states
	var cells_to_remove = []
	
	for x in range(min_pos.x, max_pos.x + 1):
		for y in range(min_pos.y, max_pos.y + 1):
			for z in range(min_pos.z, max_pos.z + 1):
				var cell_pos = Vector3i(x, y, z)
				var is_alive = GridInterface.is_cell_occupied(grid, cell_pos)
				var neighbor_count = GridInterface.count_occupied_neighbors_von_neumann(grid, cell_pos)
				
				# Rule: Alive cells with < 2 neighbors die
				if is_alive and neighbor_count < 2:
					cells_to_remove.append(cell_pos)
	
	# Apply changes
	for cell_pos in cells_to_remove:
		GridInterface.remove_cube_at_cell(grid, cell_pos)
	
	return cells_to_remove.size() > 0

# ===== TRANSFORM DISTORTIONS =====
# These manipulate multimesh transforms directly (visual glitch effects).
# They only work on GridStructureComponent since it owns the MultiMesh.

## Snapshot transforms for later restoration.
static func snapshot_transforms(grid: Node) -> bool:
	if grid.has_method("snapshot_transforms"):
		grid.snapshot_transforms()
		return true
	return false

## Restore previously-snapshotted transforms.
static func restore_transforms(grid: Node) -> bool:
	if grid.has_method("restore_transforms"):
		grid.restore_transforms()
		return true
	return false

## Explode cubes outward from center — the "laser wireframe" effect.
static func distort_explode(grid: Node, center: Vector3i, radius: int = 5, strength: float = 3.0) -> bool:
	if grid.has_method("distort_explode"):
		return grid.distort_explode(center, radius, strength)
	return false

## Twist transforms around an axis — spiral deformation.
static func distort_twist(grid: Node, center: Vector3i, radius: int = 5, angle_per_unit: float = 15.0, axis: String = "y") -> bool:
	if grid.has_method("distort_twist"):
		return grid.distort_twist(center, radius, angle_per_unit, axis)
	return false

## Scatter cubes randomly — chaotic dissolution.
static func distort_scatter(grid: Node, center: Vector3i, radius: int = 5, scatter_strength: float = 2.0, rotation_strength: float = 45.0) -> bool:
	if grid.has_method("distort_scatter"):
		return grid.distort_scatter(center, radius, scatter_strength, rotation_strength)
	return false

## Sine wave displacement across all transforms.
static func distort_wave(grid: Node, amplitude: float = 1.5, frequency: float = 0.5, phase: float = 0.0, axis: String = "y") -> bool:
	if grid.has_method("distort_wave"):
		return grid.distort_wave(amplitude, frequency, phase, axis)
	return false

# ===== UTILITY FUNCTIONS =====

static func _mirror_point(point: Vector3i, center: Vector3i, axis: String) -> Vector3i:
	var mirrored := point
	match axis:
		"x":
			mirrored.x = center.x - (point.x - center.x)
		"y":
			mirrored.y = center.y - (point.y - center.y)
		"z":
			mirrored.z = center.z - (point.z - center.z)
		_:
			mirrored.x = center.x - (point.x - center.x)
	return mirrored

static func _twist_point(point: Vector3i, center: Vector3i, angle_degrees: float, axis: String) -> Vector3i:
	var offset = point - center
	var angle_rad = 0.0
	var x = float(offset.x)
	var y = float(offset.y)
	var z = float(offset.z)
	var nx = x
	var ny = y
	var nz = z
	
	match axis:
		# Twist around Y by amount proportional to vertical offset.
		"y":
			angle_rad = deg_to_rad(angle_degrees * y)
			nx = x * cos(angle_rad) - z * sin(angle_rad)
			nz = x * sin(angle_rad) + z * cos(angle_rad)
		# Twist around X by amount proportional to x offset.
		"x":
			angle_rad = deg_to_rad(angle_degrees * x)
			ny = y * cos(angle_rad) - z * sin(angle_rad)
			nz = y * sin(angle_rad) + z * cos(angle_rad)
		# Twist around Z by amount proportional to z offset.
		"z":
			angle_rad = deg_to_rad(angle_degrees * z)
			nx = x * cos(angle_rad) - y * sin(angle_rad)
			ny = x * sin(angle_rad) + y * cos(angle_rad)
		_:
			angle_rad = deg_to_rad(angle_degrees * y)
			nx = x * cos(angle_rad) - z * sin(angle_rad)
			nz = x * sin(angle_rad) + z * cos(angle_rad)
	
	return center + Vector3i(int(round(nx)), int(round(ny)), int(round(nz)))

# Get a random adjacent direction (for wandering/random operations)
static func get_random_direction() -> Vector3i:
	var directions = [
		Vector3i(1, 0, 0),   # East
		Vector3i(-1, 0, 0),  # West
		Vector3i(0, 1, 0),   # Up
		Vector3i(0, -1, 0),  # Down
		Vector3i(0, 0, 1),   # North
		Vector3i(0, 0, -1)   # South
	]
	return directions[randi() % directions.size()]

# Check if operation is valid (enough space, no collisions)
static func can_perform_operation(grid: Node, center: Vector3i, operation_radius: int) -> bool:
	# Simple check: is center within grid bounds?
	var bounds = GridInterface.get_grid_bounds(grid)
	
	if bounds.size == Vector3i.ZERO:
		return true  # No bounds info, assume valid
	
	var min_check = center - Vector3i.ONE * operation_radius
	var max_check = center + Vector3i.ONE * operation_radius
	
	return (min_check.x >= bounds.min.x and max_check.x <= bounds.max.x and
	        min_check.y >= bounds.min.y and max_check.y <= bounds.max.y and
	        min_check.z >= bounds.min.z and max_check.z <= bounds.max.z)

