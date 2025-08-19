extends Node3D
class_name ProceduralTerrain

# Terrain parameters
@export var terrain_size: Vector2 = Vector2(50.0, 50.0)
@export var resolution: int = 100
@export var height_scale: float = 5.0
@export var base_noise_scale: float = 3.0
@export var detail_noise_scale: float = 12.0
@export var terrain_seed: int = 42
@export var water_height: float = 0.0
@export var erosion_iterations: int = 0

# Terrain textures
@export var grass_texture: Texture
@export var rock_texture: Texture
@export var sand_texture: Texture
@export var snow_texture: Texture

# Generated mesh
var terrain_mesh: MeshInstance3D
var noise: FastNoiseLite
var height_map: Array = []

func _ready():
	# Initialize noise generator
	initialize_noise()
	
	# Generate terrain
	generate_terrain()
	
	# Apply materials
	apply_materials()

# Initialize the noise generator
func initialize_noise():
	noise = FastNoiseLite.new()
	noise.seed = terrain_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.01

# Generate terrain mesh
func generate_terrain():
	# Create a plane mesh with specified resolution
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = terrain_size
	plane_mesh.subdivide_width = resolution
	plane_mesh.subdivide_depth = resolution
	
	# Convert to ArrayMesh for editing vertices
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_mesh.get_mesh_arrays())
	
	# Get vertex array for modification
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)
	
	# Initialize height map
	height_map = []
	for x in range(resolution + 1):
		var row = []
		for z in range(resolution + 1):
			row.append(0.0)
		height_map.append(row)
	
	# Apply height to vertices
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		
		# Calculate position in normalized coordinates (0-1)
		var x_norm = (vertex.x + terrain_size.x/2) / terrain_size.x
		var z_norm = (vertex.z + terrain_size.y/2) / terrain_size.y
		
		# Generate height using multiple noise layers
		var height = generate_height(x_norm, z_norm)
		
		# Apply height to vertex
		vertex.y = height
		mesh_data_tool.set_vertex(i, vertex)
		
		# Store in height map (approximate mapping)
		var x_idx = int(x_norm * resolution)
		var z_idx = int(z_norm * resolution)
		if x_idx >= 0 and x_idx <= resolution and z_idx >= 0 and z_idx <= resolution:
			height_map[x_idx][z_idx] = height
	
	# Apply erosion if iterations > 0
	if erosion_iterations > 0:
		apply_hydraulic_erosion()
		
		# Update mesh with eroded heightmap
		for i in range(mesh_data_tool.get_vertex_count()):
			var vertex = mesh_data_tool.get_vertex(i)
			
			# Calculate position in normalized coordinates (0-1)
			var x_norm = (vertex.x + terrain_size.x/2) / terrain_size.x
			var z_norm = (vertex.z + terrain_size.y/2) / terrain_size.y
			
			# Map to height map indices
			var x_idx = int(x_norm * resolution)
			var z_idx = int(z_norm * resolution)
			
			# Get height from eroded height map
			if x_idx >= 0 and x_idx <= resolution and z_idx >= 0 and z_idx <= resolution:
				vertex.y = height_map[x_idx][z_idx]
				mesh_data_tool.set_vertex(i, vertex)
	
	# Update normals for proper lighting
	# We need to manually recalculate normals for each face and then average for vertices
	# First, reset all normals
	for i in range(mesh_data_tool.get_vertex_count()):
		mesh_data_tool.set_vertex_normal(i, Vector3.ZERO)
	
	# Then calculate face normals and add to vertex normals
	for i in range(mesh_data_tool.get_face_count()):
		# Get the three vertices of this face
		var a_idx = mesh_data_tool.get_face_vertex(i, 0)
		var b_idx = mesh_data_tool.get_face_vertex(i, 1)
		var c_idx = mesh_data_tool.get_face_vertex(i, 2)
		
		var a = mesh_data_tool.get_vertex(a_idx)
		var b = mesh_data_tool.get_vertex(b_idx)
		var c = mesh_data_tool.get_vertex(c_idx)
		
		# Calculate face normal using cross product
		var face_normal = (b - a).cross(c - a).normalized()
		
		# Add the face normal to each vertex normal
		for j in range(3):
			var idx = mesh_data_tool.get_face_vertex(i, j)
			var current = mesh_data_tool.get_vertex_normal(idx)
			mesh_data_tool.set_vertex_normal(idx, current + face_normal)
	
	# Finally, normalize all vertex normals
	for i in range(mesh_data_tool.get_vertex_count()):
		var normal = mesh_data_tool.get_vertex_normal(i)
		if normal.length_squared() > 0:
			mesh_data_tool.set_vertex_normal(i, normal.normalized())
	
	# Commit changes back to mesh
	mesh_data_tool.commit_to_surface(array_mesh)
	
	# Create mesh instance
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = array_mesh
	add_child(terrain_mesh)

# Generate terrain height using layered noise
func generate_height(x: float, z: float) -> float:
	# Base terrain layer
	var base_height = noise.get_noise_2d(x * base_noise_scale, z * base_noise_scale)
	
	# Add medium details
	var medium_details = noise.get_noise_2d(x * base_noise_scale * 2, z * base_noise_scale * 2) * 0.5
	
	# Add small details
	var small_details = noise.get_noise_2d(x * detail_noise_scale, z * detail_noise_scale) * 0.25
	
	# Combine layers
	var combined = (base_height + medium_details + small_details) * height_scale
	
	# Apply water level cutoff
	combined = max(combined, water_height)
	
	return combined

# Apply hydraulic erosion to simulate water flow
func apply_hydraulic_erosion():
	# Erosion parameters
	var rainfall = 0.01
	var evaporation = 0.5
	var capacity = 4.0
	var deposition = 0.1
	
	# For each erosion iteration
	for iter in range(erosion_iterations):
		# Create water and sediment maps
		var water_map = []
		var sediment_map = []
		
		for x in range(resolution + 1):
			var water_row = []
			var sediment_row = []
			for z in range(resolution + 1):
				water_row.append(0.0)
				sediment_row.append(0.0)
			water_map.append(water_row)
			sediment_map.append(sediment_row)
		
		# Add rainfall
		for x in range(resolution + 1):
			for z in range(resolution + 1):
				water_map[x][z] += rainfall
		
		# Simulate water flow
		for x in range(1, resolution):
			for z in range(1, resolution):
				# Get current cell and neighbors
				var current_height = height_map[x][z]
				var water = water_map[x][z]
				
				if water <= 0.01:  # Minimal water threshold
					continue
				
				# Calculate flow to neighbors
				var total_flow = 0.0
				var flow = []
				
				# Check each neighbor
				var neighbors = [[x-1, z], [x+1, z], [x, z-1], [x, z+1]]
				for n in neighbors:
					var nx = n[0]
					var nz = n[1]
					
					# Skip if out of bounds
					if nx < 0 or nx > resolution or nz < 0 or nz > resolution:
						continue
					
					# Calculate height difference including water
					var neighbor_height = height_map[nx][nz] + water_map[nx][nz]
					var current_total_height = current_height + water
					
					if current_total_height > neighbor_height:
						# Flow from higher to lower
						var flow_amount = min(water, current_total_height - neighbor_height)
						flow.append({"x": nx, "z": nz, "amount": flow_amount})
						total_flow += flow_amount
					
				# Distribute water and sediment
				if total_flow > 0:
					var sediment_capacity = water * capacity
					var current_sediment = sediment_map[x][z]
					
					# Erode or deposit sediment
					if current_sediment > sediment_capacity:
						# Deposit excess sediment
						var deposit_amount = (current_sediment - sediment_capacity) * deposition
						height_map[x][z] += deposit_amount
						sediment_map[x][z] -= deposit_amount
					else:
						# Erode soil
						var erosion_amount = min(0.1, sediment_capacity - current_sediment)
						height_map[x][z] -= erosion_amount
						sediment_map[x][z] += erosion_amount
					
					# Distribute water and sediment to neighbors
					for f in flow:
						var nx = f.x
						var nz = f.z
						var flow_ratio = f.amount / total_flow
						
						# Transfer water
						var transfer_water = water * flow_ratio
						water_map[nx][nz] += transfer_water
						water_map[x][z] -= transfer_water
						
						# Transfer sediment
						var transfer_sediment = sediment_map[x][z] * flow_ratio
						sediment_map[nx][nz] += transfer_sediment
						sediment_map[x][z] -= transfer_sediment
				
				# Evaporation
				water_map[x][z] *= (1.0 - evaporation)
		
		# Update terrain height with sediment
		for x in range(resolution + 1):
			for z in range(resolution + 1):
				height_map[x][z] += sediment_map[x][z]

# Apply materials based on height and slope
func apply_materials():
	if not terrain_mesh:
		return
	
	# Create material
	var material = StandardMaterial3D.new()
	
	# If textures are provided, use them
	if grass_texture and rock_texture and sand_texture and snow_texture:
		# Create splatmap-based terrain shader
		# (In a real implementation, this would use a custom shader)
		material.albedo_color = Color(0.3, 0.5, 0.2)  # Grass-like base color
	else:
		# Simple height-based coloring
		material.albedo_color = Color(0.3, 0.5, 0.2)  # Green base
	
	material.metallic_specular = 0.1
	material.roughness = 0.9
	
	terrain_mesh.set_surface_override_material(0, material)

# Get height at a specific world position
func get_height_at(world_x: float, world_z: float) -> float:
	# Convert world coordinates to normalized
	var x_norm = (world_x + terrain_size.x/2) / terrain_size.x
	var z_norm = (world_z + terrain_size.y/2) / terrain_size.y
	
	# Map to height map indices
	var x_idx = int(x_norm * resolution)
	var z_idx = int(z_norm * resolution)
	
	# Clamp to valid range
	x_idx = clamp(x_idx, 0, resolution)
	z_idx = clamp(z_idx, 0, resolution)
	
	# Return height from map
	return height_map[x_idx][z_idx]

# Get normal at a specific world position
func get_normal_at(world_x: float, world_z: float) -> Vector3:
	# Convert world coordinates to normalized
	var x_norm = (world_x + terrain_size.x/2) / terrain_size.x
	var z_norm = (world_z + terrain_size.y/2) / terrain_size.y
	
	# Map to height map indices
	var x_idx = int(x_norm * resolution)
	var z_idx = int(z_norm * resolution)
	
	# Clamp to valid range
	x_idx = clamp(x_idx, 0, resolution)
	z_idx = clamp(z_idx, 0, resolution)
	
	# Get heights of neighbors
	var step = 1
	var left = height_map[max(0, x_idx - step)][z_idx] if x_idx > 0 else height_map[x_idx][z_idx]
	var right = height_map[min(resolution, x_idx + step)][z_idx] if x_idx < resolution else height_map[x_idx][z_idx]
	var up = height_map[x_idx][max(0, z_idx - step)] if z_idx > 0 else height_map[x_idx][z_idx]
	var down = height_map[x_idx][min(resolution, z_idx + step)] if z_idx < resolution else height_map[x_idx][z_idx]
	
	# Calculate normal using central differences
	var normal = Vector3(
		(left - right) / (2.0 * step),
		2.0,  # Exaggerate vertical component for better visual
		(up - down) / (2.0 * step)
	)
	
	return normal.normalized()

# Generate a path map (for AI navigation)
func generate_navigation_map():
	var path_map = []
	
	for x in range(resolution + 1):
		var row = []
		for z in range(resolution + 1):
			# Check terrain slope
			var normal = get_normal_at(
				x * terrain_size.x / resolution - terrain_size.x/2,
				z * terrain_size.y / resolution - terrain_size.y/2
			)
			
			# Define walkable surface based on slope
			var walkable = normal.y > 0.7  # Slope less than ~45 degrees
			
			# Check height (avoid water)
			if height_map[x][z] <= water_height + 0.1:
				walkable = false
				
			row.append(walkable)
		path_map.append(row)
	
	return path_map
