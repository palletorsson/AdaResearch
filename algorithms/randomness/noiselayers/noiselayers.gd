extends MeshInstance3D
class_name NoiseLayers

# === TERRAIN PARAMETERS ===
@export_group("Terrain Size")
@export var terrain_size: int = 100
@export var terrain_scale: float = 1.0
@export var height_scale: float = 10.0

# === NOISE LAYER CONFIGURATION ===
@export_group("Low Frequency (Base Terrain)")
@export var low_freq_noise: FastNoiseLite  
@export var low_freq_scale: float = 0.015  # Slower frequency for broader features
@export var low_freq_amplitude: float = 12.0  # Higher amplitude for major landscape features
@export var low_freq_octaves: int = 6  # More octaves for smoother transitions

@export_group("Medium Frequency (Mid-scale Features)")
@export var med_freq_noise: FastNoiseLite
@export var med_freq_scale: float = 0.04  # Balanced frequency for ridges and slopes
@export var med_freq_amplitude: float = 6.0  # Moderate amplitude for terrain variation
@export var med_freq_octaves: int = 4  # Fewer octaves for cleaner features

@export_group("High Frequency (Surface Detail)")
@export var high_freq_noise: FastNoiseLite
@export var high_freq_scale: float = 0.08  # Higher frequency for fine details
@export var high_freq_amplitude: float = 1.5  # Lower amplitude to avoid spiky terrain
@export var high_freq_octaves: int = 3  # Fewer octaves for performance

# === HUMAN MOVEMENT OPTIMIZATION ===
@export_group("Walkable Surface Settings")
@export var max_walkable_slope: float = 30.0  # Maximum walkable slope in degrees
@export var walkable_surface_threshold: float = 0.7  # Minimum surface area for walkability
@export var slope_smoothing: float = 0.8  # Smoothing factor for walkable areas

# === PERFORMANCE OPTIMIZATION ===
@export_group("Performance Settings")
@export var enable_lod: bool = true  # Enable Level of Detail system
@export var lod_distance_threshold: float = 50.0  # Distance to switch to low LOD
@export var chunk_size: int = 32  # Size of terrain chunks for LOD
@export var enable_collision_optimization: bool = true  # Optimize collision generation

# === TERRAIN QUALITY ===
@export_group("Terrain Quality")
@export var enable_erosion_simulation: bool = true  # Simulate natural erosion
@export var erosion_strength: float = 0.3  # Strength of erosion effect
@export var natural_feature_scale: float = 1.0  # Scale of natural features

# === LOD SYSTEM ===
var lod_levels: Array = []
var current_lod: int = 0
var player_position: Vector3 = Vector3.ZERO

func _ready():
	setup_noise()
	generate_terrain()
	setup_collision()
	
	# Initialize LOD system if enabled
	if enable_lod:
		setup_lod_system()

func _process(_delta):
	"""Update LOD based on player position"""
	if enable_lod:
		update_lod_level()

func setup_noise():
	"""Setup optimized three-layer noise system for realistic terrain generation"""
	var base_seed = randi()  # Use random seed for variety
	
	# Low frequency noise - Base terrain (hills, valleys, mountain ranges)
	if not low_freq_noise:
		low_freq_noise = FastNoiseLite.new()
		low_freq_noise.seed = base_seed
		low_freq_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  # Smoother than Perlin
		low_freq_noise.frequency = low_freq_scale
		low_freq_noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # Fractional Brownian Motion
		low_freq_noise.fractal_octaves = low_freq_octaves
		low_freq_noise.fractal_lacunarity = 2.0  # Controls frequency increase per octave
		low_freq_noise.fractal_gain = 0.5  # Controls amplitude decrease per octave
	
	# Medium frequency noise - Mid-scale features (ridges, slopes, formations)
	if not med_freq_noise:
		med_freq_noise = FastNoiseLite.new()
		med_freq_noise.seed = base_seed + 1000
		med_freq_noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Good for ridges
		med_freq_noise.frequency = med_freq_scale
		med_freq_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED  # Creates ridge-like features
		med_freq_noise.fractal_octaves = med_freq_octaves
		med_freq_noise.fractal_lacunarity = 2.0
		med_freq_noise.fractal_gain = 0.5
	
	# High frequency noise - Surface details (rocky bumps, small variations)
	if not high_freq_noise:
		high_freq_noise = FastNoiseLite.new()
		high_freq_noise.seed = base_seed + 2000
		high_freq_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  # Good for surface details
		high_freq_noise.frequency = high_freq_scale
		high_freq_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		high_freq_noise.fractal_octaves = high_freq_octaves
		high_freq_noise.fractal_lacunarity = 2.0
		high_freq_noise.fractal_gain = 0.5
	
	print("Noise layers configured - Seed: %d" % base_seed)

func generate_terrain():
	"""Generate optimized terrain with human movement considerations"""
	print("Generating terrain with %dx%d resolution..." % [terrain_size, terrain_size])
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()  # For terrain coloring based on height/slope
	
	# Pre-allocate arrays for better performance
	vertices.resize((terrain_size + 1) * (terrain_size + 1))
	uvs.resize((terrain_size + 1) * (terrain_size + 1))
	colors.resize((terrain_size + 1) * (terrain_size + 1))
	
	# Generate height field first for erosion simulation
	var height_field = generate_height_field()
	
	# Apply erosion simulation if enabled
	if enable_erosion_simulation:
		height_field = apply_erosion_simulation(height_field)
	
	# Generate vertices with optimized height calculation
	var vertex_index = 0
	for z in range(terrain_size + 1):
		for x in range(terrain_size + 1):
			var world_x = (x - terrain_size * 0.5) * terrain_scale
			var world_z = (z - terrain_size * 0.5) * terrain_scale
			
			# Get height from pre-calculated field
			var final_height = height_field[z][x] * height_scale
			
			vertices[vertex_index] = Vector3(world_x, final_height, world_z)
			uvs[vertex_index] = Vector2(float(x) / terrain_size, float(z) / terrain_size)
			
			# Generate terrain color based on height and slope
			colors[vertex_index] = generate_terrain_color(final_height, world_x, world_z)
			
			vertex_index += 1
	
	# Generate indices with walkable surface optimization
	indices = generate_optimized_indices(height_field)
	
	# Calculate normals with slope consideration
	normals = calculate_optimized_normals(vertices, indices, height_field)
	
	# Create mesh with all arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh
	
	print("Terrain generated with %d vertices and %d triangles" % [vertices.size(), indices.size() / 3])

func generate_height_field() -> Array:
	"""Generate height field using three-layer noise system"""
	var height_field = []
	height_field.resize(terrain_size + 1)
	
	for z in range(terrain_size + 1):
		height_field[z] = []
		height_field[z].resize(terrain_size + 1)
		
		for x in range(terrain_size + 1):
			var world_x = (x - terrain_size * 0.5) * terrain_scale
			var world_z = (z - terrain_size * 0.5) * terrain_scale
			
			# Sample noise layers with optimized parameters
			var low_freq_height = low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
			var med_freq_height = med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
			var high_freq_height = high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
			
			# Combine layers with natural blending
			var combined_height = low_freq_height + med_freq_height + high_freq_height
			
			# Apply natural feature scaling
			combined_height *= natural_feature_scale
			
			height_field[z][x] = combined_height
	
	return height_field

func apply_erosion_simulation(height_field: Array) -> Array:
	"""Apply simple erosion simulation for more natural terrain"""
	if not enable_erosion_simulation:
		return height_field
	
	print("Applying erosion simulation...")
	
	# Simple erosion: reduce height differences in steep areas
	for iteration in range(3):  # Multiple passes for better effect
		for z in range(1, terrain_size):
			for x in range(1, terrain_size):
				var current_height = height_field[z][x]
				
				# Calculate height differences with neighbors
				var height_diff_x = (height_field[z][x+1] - height_field[z][x-1]) * 0.5
				var height_diff_z = (height_field[z+1][x] - height_field[z-1][x]) * 0.5
				
				# Calculate slope magnitude
				var slope = sqrt(height_diff_x * height_diff_x + height_diff_z * height_diff_z)
				
				# Apply erosion based on slope
				if slope > 0.5:  # Steep areas get eroded more
					var erosion_amount = (slope - 0.5) * erosion_strength * 0.1
					height_field[z][x] -= erosion_amount
	
	return height_field

func generate_terrain_color(height: float, x: float, z: float) -> Color:
	"""Generate terrain color based on height and position"""
	# Base color based on height
	var height_factor = clamp((height + 5.0) / 10.0, 0.0, 1.0)  # Normalize height
	
	# Color zones
	var grass_color = Color(0.2, 0.6, 0.2)  # Green for low areas
	var rock_color = Color(0.4, 0.4, 0.4)  # Gray for high areas
	var snow_color = Color(0.9, 0.9, 0.95)  # White for very high areas
	
	var base_color: Color
	if height_factor < 0.3:
		base_color = grass_color
	elif height_factor < 0.7:
		base_color = grass_color.lerp(rock_color, (height_factor - 0.3) / 0.4)
	else:
		base_color = rock_color.lerp(snow_color, (height_factor - 0.7) / 0.3)
	
	# Add some variation based on position
	var variation = sin(x * 0.1) * cos(z * 0.1) * 0.1
	base_color = base_color.lerp(Color.WHITE, variation)
	
	return base_color

func generate_optimized_indices(height_field: Array) -> PackedInt32Array:
	"""Generate triangle indices with walkable surface optimization"""
	var indices = PackedInt32Array()
	
	for z in range(terrain_size):
		for x in range(terrain_size):
			var i = z * (terrain_size + 1) + x
			
			# Calculate slope for this quad
			var slope = calculate_quad_slope(height_field, x, z)
			
			# Only create triangles for walkable areas or if slope smoothing is disabled
			if slope <= max_walkable_slope or slope_smoothing < 1.0:
				# First triangle
				indices.append(i)
				indices.append(i + terrain_size + 1)
				indices.append(i + 1)
				
				# Second triangle
				indices.append(i + 1)
				indices.append(i + terrain_size + 1)
				indices.append(i + terrain_size + 2)
	
	return indices

func calculate_quad_slope(height_field: Array, x: int, z: int) -> float:
	"""Calculate the maximum slope of a terrain quad"""
	if x >= terrain_size or z >= terrain_size:
		return 0.0
	
	var h00 = height_field[z][x]
	var h01 = height_field[z][x + 1]
	var h10 = height_field[z + 1][x]
	var h11 = height_field[z + 1][x + 1]
	
	# Calculate slopes for both triangles
	var slope1 = abs(h01 - h00) / terrain_scale
	var slope2 = abs(h10 - h00) / terrain_scale
	var slope3 = abs(h11 - h01) / terrain_scale
	var slope4 = abs(h11 - h10) / terrain_scale
	
	return max(slope1, slope2, slope3, slope4) * 57.2958  # Convert to degrees

func calculate_optimized_normals(vertices: PackedVector3Array, indices: PackedInt32Array, height_field: Array) -> PackedVector3Array:
	"""Calculate normals with walkable surface consideration"""
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)
	
	# Calculate face normals and accumulate
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]
		
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		var face_normal = (v1 - v0).cross(v2 - v0).normalized()
		
		# Apply slope smoothing for walkable surfaces
		var slope = face_normal.angle_to(Vector3.UP) * 57.2958  # Convert to degrees
		if slope <= max_walkable_slope:
			face_normal = face_normal.lerp(Vector3.UP, slope_smoothing * 0.3)
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize all normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	return normals

func calculate_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)
	
	# Calculate face normals and accumulate
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]
		
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		var face_normal = (v1 - v0).cross(v2 - v0).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize all normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	return normals

func setup_collision():
	"""Setup optimized collision for human movement"""
	if not enable_collision_optimization:
		setup_basic_collision()
		return
	
	print("Setting up optimized collision for human movement...")
	
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	add_child(static_body)
	
	# Always create basic terrain collision first to prevent falling through
	var terrain_collision = generate_terrain_collision()
	if terrain_collision:
		static_body.add_child(terrain_collision)
		print("Added basic terrain collision")
	
	# Generate walkable surface collision as additional layer
	var walkable_collision = generate_walkable_collision()
	if walkable_collision:
		static_body.add_child(walkable_collision)
		static_body.set_meta("walkable_surface", true)
		static_body.set_meta("max_slope", max_walkable_slope)
		print("Added walkable surface collision")
	else:
		print("Warning: No walkable surfaces found, using basic collision only")
	
	print("Collision setup complete")

func setup_basic_collision():
	"""Setup basic collision without optimization"""
	var static_body = StaticBody3D.new()
	add_child(static_body)
	
	var collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	collision_shape.shape = mesh.create_trimesh_shape()

func generate_walkable_collision() -> CollisionShape3D:
	"""Generate collision shape optimized for walkable surfaces"""
	var walkable_shape = CollisionShape3D.new()
	walkable_shape.name = "WalkableSurface"
	
	# Create simplified collision mesh for walkable areas only
	var walkable_mesh = create_walkable_mesh()
	if walkable_mesh:
		walkable_shape.shape = walkable_mesh.create_trimesh_shape()
		print("Generated walkable collision with %d faces" % (walkable_mesh.get_faces().size() / 3))
		return walkable_shape
	
	return null

func generate_terrain_collision() -> CollisionShape3D:
	"""Generate collision shape for general terrain"""
	var terrain_shape = CollisionShape3D.new()
	terrain_shape.name = "TerrainSurface"
	terrain_shape.shape = mesh.create_trimesh_shape()
	return terrain_shape

func create_walkable_mesh() -> ArrayMesh:
	"""Create simplified mesh containing only walkable surfaces"""
	var walkable_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Get original mesh data
	var arrays = mesh.surface_get_arrays(0)
	var original_vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var original_indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	if original_vertices.size() == 0 or original_indices.size() == 0:
		print("Warning: No mesh data available for walkable surface generation")
		return null
	
	print("Processing %d triangles for walkable surface detection..." % (original_indices.size() / 3))
	
	# Filter triangles based on walkability
	var walkable_triangles = []
	var total_triangles = original_indices.size() / 3
	var walkable_count = 0
	
	for i in range(0, original_indices.size(), 3):
		var i0 = original_indices[i]
		var i1 = original_indices[i + 1]
		var i2 = original_indices[i + 2]
		
		# Bounds check
		if i0 >= original_vertices.size() or i1 >= original_vertices.size() or i2 >= original_vertices.size():
			continue
		
		var v0 = original_vertices[i0]
		var v1 = original_vertices[i1]
		var v2 = original_vertices[i2]
		
		# Calculate triangle normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var cross_product = edge1.cross(edge2)
		
		# Skip degenerate triangles
		if cross_product.length_squared() < 0.000001:
			continue
			
		var normal = cross_product.normalized()
		
		# Check if surface is walkable (roughly horizontal)
		var angle_from_up = rad_to_deg(normal.angle_to(Vector3.UP))
		
		# More permissive walkable surface detection
		if angle_from_up <= max_walkable_slope:
			walkable_triangles.append([v0, v1, v2])
			walkable_count += 1
	
	print("Found %d walkable triangles out of %d total (%.1f%%)" % [
		walkable_count, 
		total_triangles, 
		(float(walkable_count) / total_triangles) * 100.0
	])
	
	# If no walkable triangles found, create a fallback flat surface
	if walkable_triangles.size() == 0:
		print("No walkable triangles found, creating fallback flat surface")
		return create_fallback_walkable_mesh()
	
	# Build walkable mesh
	var vertex_map = {}
	var vertex_index = 0
	
	for triangle in walkable_triangles:
		for vertex in triangle:
			var vertex_key = str(vertex)
			if not vertex_map.has(vertex_key):
				vertex_map[vertex_key] = vertex_index
				vertices.append(vertex)
				vertex_index += 1
			
			indices.append(vertex_map[vertex_key])
	
	if vertices.size() > 0:
		var walkable_arrays = []
		walkable_arrays.resize(Mesh.ARRAY_MAX)
		walkable_arrays[Mesh.ARRAY_VERTEX] = vertices
		walkable_arrays[Mesh.ARRAY_INDEX] = indices
		
		walkable_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, walkable_arrays)
		print("Created walkable mesh with %d vertices and %d triangles" % [vertices.size(), indices.size() / 3])
		return walkable_mesh
	
	return null

func create_fallback_walkable_mesh() -> ArrayMesh:
	"""Create a simple flat walkable surface as fallback"""
	var fallback_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create a simple flat plane at y=0
	var size = terrain_size * terrain_scale * 0.5
	vertices.append(Vector3(-size, 0, -size))
	vertices.append(Vector3(size, 0, -size))
	vertices.append(Vector3(size, 0, size))
	vertices.append(Vector3(-size, 0, size))
	
	# Create two triangles
	indices.append(0)
	indices.append(1)
	indices.append(2)
	
	indices.append(0)
	indices.append(2)
	indices.append(3)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	fallback_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	print("Created fallback walkable mesh")
	return fallback_mesh

# === UTILITY FUNCTIONS ===

func regenerate_terrain():
	"""Regenerate terrain with current settings"""
	print("Regenerating terrain...")
	setup_noise()
	generate_terrain()
	
	# Update collision if needed
	var static_body = get_child(0) as StaticBody3D
	if static_body:
		static_body.queue_free()  # Remove old collision
		setup_collision()  # Create new optimized collision
	
	print("Terrain regeneration complete")

func get_walkable_surfaces() -> Array:
	"""Get information about walkable surfaces for pathfinding"""
	var walkable_surfaces = []
	var static_body = get_child(0) as StaticBody3D
	
	if static_body and static_body.has_meta("walkable_surface"):
		# This is a simplified version - in a real implementation,
		# you'd analyze the actual walkable mesh
		walkable_surfaces.append({
			"body": static_body,
			"max_slope": static_body.get_meta("max_slope"),
			"area": calculate_walkable_area()
		})
	
	return walkable_surfaces

func calculate_walkable_area() -> float:
	"""Calculate total walkable area in square units"""
	# This is a simplified calculation
	# In a real implementation, you'd analyze the actual walkable mesh
	var total_area = 0.0
	var quad_area = terrain_scale * terrain_scale
	
	for z in range(terrain_size):
		for x in range(terrain_size):
			# This is a placeholder - you'd need to calculate actual slope
			# and determine if the quad is walkable
			total_area += quad_area * 0.7  # Assume 70% walkable
	
	return total_area

func is_position_walkable(world_position: Vector3) -> bool:
	"""Check if a world position is on a walkable surface"""
	# Cast ray downward to check for walkable collision
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		world_position + Vector3.UP * 2.0,
		world_position + Vector3.DOWN * 2.0
	)
	
	var result = space_state.intersect_ray(query)
	if result.has("collider"):
		var collider = result.collider
		return collider.has_meta("walkable_surface")
	
	return false

func get_terrain_height_at_position(world_x: float, world_z: float) -> float:
	"""Get terrain height at a specific world position"""
	# Convert world coordinates to terrain grid coordinates
	var grid_x = int((world_x / terrain_scale) + terrain_size * 0.5)
	var grid_z = int((world_z / terrain_scale) + terrain_size * 0.5)
	
	# Clamp to valid range
	grid_x = clamp(grid_x, 0, terrain_size)
	grid_z = clamp(grid_z, 0, terrain_size)
	
	# Sample noise at this position
	var low_freq_height = low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
	var med_freq_height = med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
	var high_freq_height = high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
	
	var combined_height = (low_freq_height + med_freq_height + high_freq_height) * natural_feature_scale
	return combined_height * height_scale

func get_terrain_slope_at_position(world_x: float, world_z: float) -> float:
	"""Get terrain slope at a specific world position in degrees"""
	var sample_distance = terrain_scale * 0.5
	
	# Sample heights around the position
	var center_height = get_terrain_height_at_position(world_x, world_z)
	var right_height = get_terrain_height_at_position(world_x + sample_distance, world_z)
	var forward_height = get_terrain_height_at_position(world_x, world_z + sample_distance)
	
	# Calculate gradients
	var gradient_x = (right_height - center_height) / sample_distance
	var gradient_z = (forward_height - center_height) / sample_distance
	
	# Calculate slope magnitude
	var slope = sqrt(gradient_x * gradient_x + gradient_z * gradient_z)
	return atan(slope) * 57.2958  # Convert to degrees

# === DEBUG FUNCTIONS ===

func debug_show_walkable_areas():
	"""Debug function to visualize walkable areas"""
	var static_body = get_child(0) as StaticBody3D
	if static_body and static_body.has_meta("walkable_surface"):
		print("Walkable surface detected with max slope: %.1f°" % static_body.get_meta("max_slope"))
		print("Total walkable area: %.2f square units" % calculate_walkable_area())
	else:
		print("No walkable surface collision found")

func debug_terrain_info():
	"""Debug function to show terrain information"""
	print("=== TERRAIN DEBUG INFO ===")
	print("Terrain size: %dx%d" % [terrain_size, terrain_size])
	print("Terrain scale: %.2f" % terrain_scale)
	print("Height scale: %.2f" % height_scale)
	print("Max walkable slope: %.1f°" % max_walkable_slope)
	print("Erosion simulation: %s" % ("Enabled" if enable_erosion_simulation else "Disabled"))
	print("Collision optimization: %s" % ("Enabled" if enable_collision_optimization else "Disabled"))
	print("=========================")

func debug_collision_info():
	"""Debug function to show collision information"""
	print("=== COLLISION DEBUG INFO ===")
	var static_body = get_child(0) as StaticBody3D
	if static_body:
		print("StaticBody3D found: %s" % static_body.name)
		print("Number of collision shapes: %d" % static_body.get_child_count())
		
		for i in range(static_body.get_child_count()):
			var child = static_body.get_child(i)
			if child is CollisionShape3D:
				var shape = child.shape
				print("CollisionShape %d: %s" % [i, child.name])
				if shape:
					print("  - Shape type: %s" % shape.get_class())
					if shape.has_method("get_faces"):
						var faces = shape.get_faces()
						print("  - Number of faces: %d" % (faces.size() / 3))
				else:
					print("  - No shape assigned!")
	else:
		print("No StaticBody3D found!")
	print("=============================")

func fix_collision_issues():
	"""Fix common collision issues by regenerating with basic collision"""
	print("Fixing collision issues...")
	
	# Remove existing collision
	var static_body = get_child(0) as StaticBody3D
	if static_body:
		static_body.queue_free()
	
	# Temporarily disable collision optimization
	var old_optimization = enable_collision_optimization
	enable_collision_optimization = false
	
	# Regenerate with basic collision
	setup_collision()
	
	# Restore original setting
	enable_collision_optimization = old_optimization
	
	print("Collision issues fixed - using basic collision mode")

# === LOD SYSTEM FUNCTIONS ===

func setup_lod_system():
	"""Initialize Level of Detail system"""
	print("Setting up LOD system...")
	
	# Create LOD levels with different resolutions
	lod_levels = [
		{"resolution": 1, "distance": 0.0, "mesh": null},      # Full detail
		{"resolution": 2, "distance": 25.0, "mesh": null},     # Half resolution
		{"resolution": 4, "distance": 50.0, "mesh": null},     # Quarter resolution
		{"resolution": 8, "distance": 100.0, "mesh": null}     # Eighth resolution
	]
	
	# Generate LOD meshes
	for i in range(lod_levels.size()):
		generate_lod_mesh(i)
	
	print("LOD system setup complete with %d levels" % lod_levels.size())

func generate_lod_mesh(lod_index: int):
	"""Generate mesh for specific LOD level"""
	var lod_data = lod_levels[lod_index]
	var resolution = lod_data.resolution
	
	# Calculate LOD terrain size
	var lod_terrain_size = terrain_size / resolution
	if lod_terrain_size < 4:  # Minimum resolution
		lod_terrain_size = 4
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Pre-allocate arrays
	vertices.resize((lod_terrain_size + 1) * (lod_terrain_size + 1))
	uvs.resize((lod_terrain_size + 1) * (lod_terrain_size + 1))
	colors.resize((lod_terrain_size + 1) * (lod_terrain_size + 1))
	
	# Generate vertices with reduced resolution
	var vertex_index = 0
	for z in range(lod_terrain_size + 1):
		for x in range(lod_terrain_size + 1):
			var world_x = (x - lod_terrain_size * 0.5) * terrain_scale * resolution
			var world_z = (z - lod_terrain_size * 0.5) * terrain_scale * resolution
			
			# Sample noise at lower resolution
			var height = get_terrain_height_at_position(world_x, world_z)
			
			vertices[vertex_index] = Vector3(world_x, height, world_z)
			uvs[vertex_index] = Vector2(float(x) / lod_terrain_size, float(z) / lod_terrain_size)
			colors[vertex_index] = generate_terrain_color(height / height_scale, world_x, world_z)
			
			vertex_index += 1
	
	# Generate indices
	for z in range(lod_terrain_size):
		for x in range(lod_terrain_size):
			var i = z * (lod_terrain_size + 1) + x
			
			# First triangle
			indices.append(i)
			indices.append(i + lod_terrain_size + 1)
			indices.append(i + 1)
			
			# Second triangle
			indices.append(i + 1)
			indices.append(i + lod_terrain_size + 1)
			indices.append(i + lod_terrain_size + 2)
	
	# Calculate normals
	normals = calculate_normals(vertices, indices)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	lod_data.mesh = array_mesh
	
	print("Generated LOD %d with %dx%d resolution (%d vertices)" % [lod_index, lod_terrain_size, lod_terrain_size, vertices.size()])

func update_lod_level():
	"""Update LOD level based on player distance"""
	if lod_levels.size() == 0:
		return
	
	# Calculate distance from player to terrain center
	var terrain_center = global_position
	var distance = player_position.distance_to(terrain_center)
	
	# Find appropriate LOD level
	var new_lod = 0
	for i in range(lod_levels.size()):
		if distance >= lod_levels[i].distance:
			new_lod = i
		else:
			break
	
	# Switch to new LOD if different
	if new_lod != current_lod:
		switch_to_lod(new_lod)

func switch_to_lod(lod_index: int):
	"""Switch to specific LOD level"""
	if lod_index < 0 or lod_index >= lod_levels.size():
		return
	
	var lod_data = lod_levels[lod_index]
	if lod_data.mesh == null:
		return
	
	# Update mesh
	mesh = lod_data.mesh
	current_lod = lod_index
	
	# Update collision if needed
	if enable_collision_optimization:
		update_collision_for_lod(lod_index)
	
	print("Switched to LOD level %d" % lod_index)

func update_collision_for_lod(lod_index: int):
	"""Update collision shape for LOD level"""
	var static_body = get_child(0) as StaticBody3D
	if not static_body:
		return
	
		# For LOD levels > 0, use simplified collision
		if lod_index > 0:
			var lod_data = lod_levels[lod_index]
			if lod_data.mesh:
				# Find terrain collision shape
				for child in static_body.get_children():
					if child.name == "TerrainSurface":
						var collision_shape = child as CollisionShape3D
						if collision_shape:
							collision_shape.shape = lod_data.mesh.create_trimesh_shape()
							break

func set_player_position(position: Vector3):
	"""Set player position for LOD calculations"""
	player_position = position

func get_current_lod_info() -> Dictionary:
	"""Get information about current LOD level"""
	if current_lod < lod_levels.size():
		var lod_data = lod_levels[current_lod]
		return {
			"level": current_lod,
			"resolution": lod_data.resolution,
			"distance": lod_data.distance,
			"vertex_count": lod_data.mesh.get_faces().size() if lod_data.mesh else 0
		}
	return {}
