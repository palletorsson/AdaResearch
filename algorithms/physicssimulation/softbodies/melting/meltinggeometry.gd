# MeltingGeometry.gd
# Level Set Method implementation for melting geometry in Godot 4
extends Node3D

@export var resolution: int = 64
@export var melt_speed: float = 0.5
@export var heat_sources: Array[Vector3] = []
@export var ambient_temperature: float = 0.0
@export var melt_threshold: float = 0.5

var level_set_grid: Array = []
var temperature_grid: Array = []
var mesh_instance: MeshInstance3D
var bounds: AABB = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

func _ready():
	setup_grids()
	initialize_geometry()
	create_mesh_instance()
	update_mesh()

func setup_grids():
	level_set_grid.clear()
	temperature_grid.clear()
	
	# Initialize 3D grids
	for x in range(resolution):
		level_set_grid.append([])
		temperature_grid.append([])
		for y in range(resolution):
			level_set_grid[x].append([])
			temperature_grid[x].append([])
			for z in range(resolution):
				level_set_grid[x][y].append(0.0)
				temperature_grid[x][y].append(ambient_temperature)

func initialize_geometry():
	# Create initial geometry (sphere in this example)
	var center = Vector3(resolution/2, resolution/2, resolution/2)
	var radius = resolution * 0.3
	
	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				var pos = Vector3(x, y, z)
				var distance = pos.distance_to(center) - radius
				level_set_grid[x][y][z] = distance

func create_mesh_instance():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

func _process(delta):
	update_temperature(delta)
	apply_melting(delta)
	update_mesh()

func update_temperature(delta: float):
	# Heat diffusion using simple finite difference
	var new_temp_grid = temperature_grid.duplicate(true)
	var diffusion_rate = 0.1
	
	for x in range(1, resolution - 1):
		for y in range(1, resolution - 1):
			for z in range(1, resolution - 1):
				if level_set_grid[x][y][z] <= 0: # Inside object
					# Heat diffusion
					var neighbors = [
						temperature_grid[x-1][y][z],
						temperature_grid[x+1][y][z],
						temperature_grid[x][y-1][z],
						temperature_grid[x][y+1][z],
						temperature_grid[x][y][z-1],
						temperature_grid[x][y][z+1]
					]
					
					var avg_temp = 0.0
					for temp in neighbors:
						avg_temp += temp
					avg_temp /= neighbors.size()
					
					new_temp_grid[x][y][z] = temperature_grid[x][y][z] + diffusion_rate * delta * (avg_temp - temperature_grid[x][y][z])
	
	# Apply heat sources
	for heat_pos in heat_sources:
		var grid_pos = world_to_grid(heat_pos)
		apply_heat_source(new_temp_grid, grid_pos, 2.0, 3.0)
	
	temperature_grid = new_temp_grid

func apply_heat_source(temp_grid: Array, center: Vector3i, intensity: float, radius: float):
	var start_x = max(0, int(center.x - radius))
	var end_x = min(resolution - 1, int(center.x + radius))
	var start_y = max(0, int(center.y - radius))
	var end_y = min(resolution - 1, int(center.y + radius))
	var start_z = max(0, int(center.z - radius))
	var end_z = min(resolution - 1, int(center.z + radius))
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			for z in range(start_z, end_z + 1):
				var pos = Vector3(x, y, z)
				var distance = pos.distance_to(Vector3(center))
				if distance <= radius:
					var heat_factor = 1.0 - (distance / radius)
					temp_grid[x][y][z] += intensity * heat_factor

func apply_melting(delta: float):
	# Apply level set evolution based on temperature
	var new_level_set = level_set_grid.duplicate(true)
	
	for x in range(1, resolution - 1):
		for y in range(1, resolution - 1):
			for z in range(1, resolution - 1):
				if temperature_grid[x][y][z] > melt_threshold:
					# Calculate gradient magnitude for normal speed
					var gradient = calculate_gradient(level_set_grid, x, y, z)
					var gradient_magnitude = gradient.length()
					
					if gradient_magnitude > 0.01:
						# Melt at rate proportional to temperature excess
						var melt_rate = (temperature_grid[x][y][z] - melt_threshold) * melt_speed
						new_level_set[x][y][z] += melt_rate * delta * gradient_magnitude
	
	level_set_grid = new_level_set
	
	# Reinitialize level set to maintain signed distance property
	if Engine.get_process_frames() % 10 == 0: # Every 10 frames
		reinitialize_level_set()

func calculate_gradient(grid: Array, x: int, y: int, z: int) -> Vector3:
	var dx = (grid[x+1][y][z] - grid[x-1][y][z]) * 0.5
	var dy = (grid[x][y+1][z] - grid[x][y-1][z]) * 0.5
	var dz = (grid[x][y][z+1] - grid[x][y][z-1]) * 0.5
	return Vector3(dx, dy, dz)

func reinitialize_level_set():
	# Simple fast marching method for reinitialization
	var new_grid = level_set_grid.duplicate(true)
	var iterations = 5
	var dt = 0.1
	
	for iter in range(iterations):
		var temp_grid = new_grid.duplicate(true)
		
		for x in range(1, resolution - 1):
			for y in range(1, resolution - 1):
				for z in range(1, resolution - 1):
					var phi = new_grid[x][y][z]
					var sign_phi = sign(phi)
					
					# Calculate upwind differences
					var grad_x = calculate_upwind_diff(new_grid, x, y, z, Vector3i(1, 0, 0), sign_phi)
					var grad_y = calculate_upwind_diff(new_grid, x, y, z, Vector3i(0, 1, 0), sign_phi)
					var grad_z = calculate_upwind_diff(new_grid, x, y, z, Vector3i(0, 0, 1), sign_phi)
					
					var grad_magnitude = sqrt(grad_x*grad_x + grad_y*grad_y + grad_z*grad_z)
					
					temp_grid[x][y][z] = phi - dt * sign_phi * (grad_magnitude - 1.0)
		
		new_grid = temp_grid
	
	level_set_grid = new_grid

func calculate_upwind_diff(grid: Array, x: int, y: int, z: int, direction: Vector3i, sign_phi: float) -> float:
	var pos_diff = grid[x + direction.x][y + direction.y][z + direction.z] - grid[x][y][z]
	var neg_diff = grid[x][y][z] - grid[x - direction.x][y - direction.y][z - direction.z]
	
	if sign_phi > 0:
		return max(-neg_diff, 0.0) if neg_diff < 0 else min(pos_diff, 0.0)
	else:
		return max(pos_diff, 0.0) if pos_diff > 0 else min(-neg_diff, 0.0)

func update_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Marching cubes implementation
	for x in range(resolution - 1):
		for y in range(resolution - 1):
			for z in range(resolution - 1):
				march_cube(surface_tool, x, y, z)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh

func march_cube(surface_tool: SurfaceTool, x: int, y: int, z: int):
	# Get the 8 corner values
	var corners = []
	var positions = []
	
	for i in range(8):
		var dx = i & 1
		var dy = (i >> 1) & 1
		var dz = (i >> 2) & 1
		
		corners.append(level_set_grid[x + dx][y + dy][z + dz])
		positions.append(grid_to_world(Vector3(x + dx, y + dy, z + dz)))
	
	# Create cube configuration
	var cube_config = 0
	for i in range(8):
		if corners[i] <= 0:
			cube_config |= (1 << i)
	
	# Simplified marching cubes - just create triangles for basic cases
	if cube_config > 0 and cube_config < 255:
		create_triangles_for_config(surface_tool, positions, corners, cube_config)

func create_triangles_for_config(surface_tool: SurfaceTool, positions: Array, corners: Array, config: int):
	# Simplified triangle creation - this would be expanded with full marching cubes tables
	if config == 1 or config == 254: # Single corner cases
		var edge_vertices = []
		
		# Find edge intersections (simplified)
		if abs(corners[0]) + abs(corners[1]) > 0:
			var t = abs(corners[0]) / (abs(corners[0]) + abs(corners[1]))
			edge_vertices.append(positions[0].lerp(positions[1], t))
		
		if abs(corners[0]) + abs(corners[4]) > 0:
			var t = abs(corners[0]) / (abs(corners[0]) + abs(corners[4]))
			edge_vertices.append(positions[0].lerp(positions[4], t))
		
		if abs(corners[0]) + abs(corners[2]) > 0:
			var t = abs(corners[0]) / (abs(corners[0]) + abs(corners[2]))
			edge_vertices.append(positions[0].lerp(positions[2], t))
		
		# Create triangle if we have 3 edge vertices
		if edge_vertices.size() >= 3:
			for vertex in edge_vertices.slice(0, 3):
				surface_tool.add_vertex(vertex)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	var relative_pos = (world_pos - bounds.position) / bounds.size
	return Vector3i(
		int(relative_pos.x * resolution),
		int(relative_pos.y * resolution),
		int(relative_pos.z * resolution)
	)

func grid_to_world(grid_pos: Vector3) -> Vector3:
	var normalized_pos = grid_pos / resolution
	return bounds.position + normalized_pos * bounds.size

# Public methods for interaction
func add_heat_source(world_position: Vector3):
	heat_sources.append(world_position)

func remove_heat_source(world_position: Vector3):
	heat_sources.erase(world_position)

func set_melt_speed(speed: float):
	melt_speed = speed

func set_melt_threshold(threshold: float):
	melt_threshold = threshold
