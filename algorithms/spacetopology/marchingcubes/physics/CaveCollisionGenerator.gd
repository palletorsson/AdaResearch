# CaveCollisionGenerator.gd
# Generates optimized collision meshes for cave systems
# Provides different LOD levels and collision shape options

extends RefCounted
class_name CaveCollisionGenerator

enum CollisionType {
	TRIMESH,        # Most accurate, slower
	CONVEX_HULL,    # Fast but approximate
	COMPOUND,       # Multiple convex shapes
	SIMPLIFIED      # Reduced triangle count
}

@export var collision_type: CollisionType = CollisionType.TRIMESH
@export var simplification_ratio: float = 0.5  # For simplified meshes
@export var convex_hull_segments: int = 8      # For compound shapes

# VR locomotion parameters
@export var tile_size: float = 1.0  # 1x1 meter tiles
@export var max_slope_angle: float = 30.0  # Maximum walkable slope in degrees
@export var min_surface_area: float = 0.5  # Minimum area for a walkable surface
@export var surface_detection_tolerance: float = 0.1  # Normal vector tolerance for floor detection

# Surface analysis
var walkable_surfaces: Array[Dictionary] = []
var collision_bodies: Array[StaticBody3D] = []

func generate_collision_shape(mesh: ArrayMesh, type: CollisionType = CollisionType.TRIMESH) -> Shape3D:
	"""Generate a collision shape from a mesh"""
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	
	match type:
		CollisionType.TRIMESH:
			return create_trimesh_collision(mesh)
		CollisionType.CONVEX_HULL:
			return create_convex_hull_collision(mesh)
		CollisionType.COMPOUND:
			return create_compound_collision(mesh)
		CollisionType.SIMPLIFIED:
			return create_simplified_collision(mesh)
		_:
			return create_trimesh_collision(mesh)

func create_trimesh_collision(mesh: ArrayMesh) -> ConcavePolygonShape3D:
	"""Create exact trimesh collision from mesh"""
	var shape = mesh.create_trimesh_shape()
	print("CaveCollision: Created trimesh with %d faces" % (shape.get_faces().size() / 3))
	return shape

func create_convex_hull_collision(mesh: ArrayMesh) -> ConvexPolygonShape3D:
	"""Create convex hull collision approximation"""
	var shape = mesh.create_convex_shape()
	if shape != null:
		print("CaveCollision: Created convex hull")
	return shape

func create_compound_collision(mesh: ArrayMesh) -> Shape3D:
	"""Create compound collision shape from multiple convex hulls"""
	var vertices = get_mesh_vertices(mesh)
	if vertices.is_empty():
		return create_convex_hull_collision(mesh)
	
	# Divide mesh into spatial regions
	var regions = divide_into_regions(vertices, convex_hull_segments)
	
	if regions.size() <= 1:
		return create_convex_hull_collision(mesh)
	
	# For Godot 4, we'll use the largest region as a single convex shape
	# CompoundShape3D doesn't exist in Godot 4, so we use the best single convex hull
	var largest_region = PackedVector3Array()
	for region in regions:
		if region.size() > largest_region.size():
			largest_region = region
	
	if largest_region.size() >= 4:
		var region_mesh = create_mesh_from_vertices(largest_region)
		var convex_shape = region_mesh.create_convex_shape()
		if convex_shape != null:
			print("CaveCollision: Created simplified convex shape from largest region")
			return convex_shape
	
	# Fallback to regular convex hull
	return create_convex_hull_collision(mesh)

func create_simplified_collision(mesh: ArrayMesh) -> Shape3D:
	"""Create simplified collision mesh with reduced triangle count"""
	var simplified_mesh = simplify_mesh(mesh, simplification_ratio)
	return create_trimesh_collision(simplified_mesh)

func simplify_mesh(mesh: ArrayMesh, ratio: float) -> ArrayMesh:
	"""Simplify mesh by reducing triangle count"""
	if mesh.get_surface_count() == 0:
		return mesh
	
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	if vertices.is_empty() or indices.is_empty():
		return mesh
	
	# Simple decimation - remove every nth triangle
	var target_triangles = int(indices.size() / 3 * ratio)
	var step = max(1, int(indices.size() / 3 / target_triangles))
	
	var new_indices = PackedInt32Array()
	for i in range(0, indices.size(), step * 3):
		if i + 2 < indices.size():
			new_indices.append(indices[i])
			new_indices.append(indices[i + 1])
			new_indices.append(indices[i + 2])
	
	# Create simplified mesh
	var simplified_mesh = ArrayMesh.new()
	var new_arrays = arrays.duplicate()
	new_arrays[Mesh.ARRAY_INDEX] = new_indices
	simplified_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	
	print("CaveCollision: Simplified mesh from %d to %d triangles" % [indices.size() / 3, new_indices.size() / 3])
	return simplified_mesh

func get_mesh_vertices(mesh: ArrayMesh) -> PackedVector3Array:
	"""Extract vertices from mesh"""
	if mesh.get_surface_count() == 0:
		return PackedVector3Array()
	
	var arrays = mesh.surface_get_arrays(0)
	return arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array

func divide_into_regions(vertices: PackedVector3Array, num_regions: int) -> Array[PackedVector3Array]:
	"""Divide vertices into spatial regions for compound collision"""
	if vertices.is_empty() or num_regions <= 1:
		return [vertices]
	
	# Calculate bounding box
	var min_bounds = vertices[0]
	var max_bounds = vertices[0]
	
	for vertex in vertices:
		min_bounds = min_bounds.min(vertex)
		max_bounds = max_bounds.max(vertex)
	
	var size = max_bounds - min_bounds
	var regions: Array[PackedVector3Array] = []
	
	# Simple grid-based division
	var grid_size = int(ceil(pow(num_regions, 1.0/3.0)))
	var cell_size = size / grid_size
	
	# Initialize regions
	for i in range(num_regions):
		regions.append(PackedVector3Array())
	
	# Assign vertices to regions
	for vertex in vertices:
		var relative_pos = vertex - min_bounds
		var grid_x = int(relative_pos.x / cell_size.x)
		var grid_y = int(relative_pos.y / cell_size.y)
		var grid_z = int(relative_pos.z / cell_size.z)
		
		grid_x = clamp(grid_x, 0, grid_size - 1)
		grid_y = clamp(grid_y, 0, grid_size - 1)
		grid_z = clamp(grid_z, 0, grid_size - 1)
		
		var region_index = grid_x + grid_y * grid_size + grid_z * grid_size * grid_size
		region_index = clamp(region_index, 0, regions.size() - 1)
		
		regions[region_index].append(vertex)
	
	# Remove empty regions
	var non_empty_regions: Array[PackedVector3Array] = []
	for region in regions:
		if region.size() >= 4:  # Minimum for convex hull
			non_empty_regions.append(region)
	
	return non_empty_regions

func create_mesh_from_vertices(vertices: PackedVector3Array) -> ArrayMesh:
	"""Create a simple mesh from vertices for convex hull generation"""
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# Generate simple indices (not optimal but works for convex hull)
	var indices = PackedInt32Array()
	for i in range(0, vertices.size() - 2, 3):
		if i + 2 < vertices.size():
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + 2)
	
	if not indices.is_empty():
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

func generate_multiple_lod_collision(mesh: ArrayMesh) -> Dictionary:
	"""Generate multiple LOD levels for collision"""
	var lod_shapes = {}
	
	# LOD 0 - Highest detail (trimesh)
	lod_shapes["lod0"] = create_trimesh_collision(mesh)
	
	# LOD 1 - Medium detail (simplified trimesh)
	var simplified_mesh = simplify_mesh(mesh, 0.5)
	lod_shapes["lod1"] = create_trimesh_collision(simplified_mesh)
	
	# LOD 2 - Low detail (convex hull)
	lod_shapes["lod2"] = create_convex_hull_collision(mesh)
	
	# LOD 3 - Lowest detail (compound convex)
	lod_shapes["lod3"] = create_compound_collision(mesh)
	
	print("CaveCollision: Generated %d LOD levels" % lod_shapes.size())
	return lod_shapes

func get_collision_complexity(shape: Shape3D) -> Dictionary:
	"""Analyze collision shape complexity for performance tuning"""
	var complexity = {
		"type": "unknown",
		"face_count": 0,
		"vertex_count": 0,
		"memory_estimate": 0
	}
	
	if shape is ConcavePolygonShape3D:
		var faces = shape.get_faces()
		complexity.type = "trimesh"
		complexity.face_count = faces.size() / 3
		complexity.vertex_count = faces.size()
		complexity.memory_estimate = faces.size() * 12  # 3 floats per vertex
		
	elif shape is ConvexPolygonShape3D:
		var points = shape.points
		complexity.type = "convex"
		complexity.vertex_count = points.size()
		complexity.memory_estimate = points.size() * 12
		
	# Removed CompoundShape3D reference as it doesn't exist in Godot 4
	
	return complexity

func generate_walkable_collision(cave_meshes: Array[MeshInstance3D], parent_node: Node3D) -> Array[StaticBody3D]:
	"""Generate VR-walkable collision surfaces from cave meshes"""
	print("CaveCollisionGenerator: Generating VR walkable surfaces...")
	
	collision_bodies.clear()
	walkable_surfaces.clear()
	
	for mesh_instance in cave_meshes:
		var walkable_collision = create_walkable_collision_for_mesh(mesh_instance, parent_node)
		if walkable_collision != null:
			collision_bodies.append(walkable_collision)
	
	print("CaveCollisionGenerator: Generated %d walkable collision bodies" % collision_bodies.size())
	return collision_bodies

func create_walkable_collision_for_mesh(mesh_instance: MeshInstance3D, parent_node: Node3D) -> StaticBody3D:
	"""Create walkable collision for a single mesh"""
	var mesh = mesh_instance.mesh as ArrayMesh
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	
	# Analyze mesh for walkable surfaces
	var surface_data = analyze_walkable_surfaces(mesh)
	if surface_data.walkable_triangles.size() == 0:
		return null
	
	# Create collision body
	var collision_body = StaticBody3D.new()
	collision_body.name = mesh_instance.name + "_VR_Collision"
	collision_body.transform = mesh_instance.transform
	
	# Create simplified collision mesh for walkable areas only
	var walkable_mesh = create_walkable_mesh(surface_data.walkable_triangles)
	if walkable_mesh != null:
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = walkable_mesh.create_trimesh_shape()
		collision_shape.name = "WalkableSurface"
		collision_body.add_child(collision_shape)
		
		# Add VR navigation metadata
		collision_body.set_meta("vr_walkable", true)
		collision_body.set_meta("tile_size", tile_size)
		collision_body.set_meta("surface_count", surface_data.surface_count)
		
		# Add to scene
		parent_node.add_child(collision_body)
		
		print("Created walkable collision with %d triangles" % surface_data.walkable_triangles.size())
		return collision_body
	
	return null

func analyze_walkable_surfaces(mesh: ArrayMesh) -> Dictionary:
	"""Analyze mesh to identify walkable surfaces"""
	var surface_data = {
		"walkable_triangles": [],
		"surface_count": 0,
		"total_walkable_area": 0.0
	}
	
	# Get mesh arrays
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	if vertices.size() == 0 or indices.size() == 0:
		return surface_data
	
	# Analyze each triangle
	for i in range(0, indices.size(), 3):
		var idx1 = indices[i]
		var idx2 = indices[i + 1]
		var idx3 = indices[i + 2]
		
		if idx1 >= vertices.size() or idx2 >= vertices.size() or idx3 >= vertices.size():
			continue
		
		var v1 = vertices[idx1]
		var v2 = vertices[idx2]
		var v3 = vertices[idx3]
		
		# Calculate triangle normal
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var cross_product = edge1.cross(edge2)
		
		# Skip degenerate triangles
		if cross_product.length_squared() < 0.000001:
			continue
			
		var triangle_normal = cross_product.normalized()
		
		# Check if surface is walkable (roughly horizontal)
		var angle_from_up = rad_to_deg(triangle_normal.angle_to(Vector3.UP))
		
		# DEBUG: Show angle analysis for first few triangles
		if surface_data.surface_count < 5:
			print("Triangle %d: normal %v, angle from up: %.1f°" % [surface_data.surface_count, triangle_normal, angle_from_up])
		
		# RELAXED: More permissive slope detection for voxel terrain
		if angle_from_up <= 60.0:  # Increased from 30° to 60° for marching cubes terrain
			# Calculate triangle area
			var area = edge1.cross(edge2).length() * 0.5
			
			# RELAXED: Lower minimum area requirement for voxel-based terrain  
			if area >= 0.1:  # Reduced from 0.5 to 0.1 for finer terrain detection
				var triangle_data = {
					"vertices": [v1, v2, v3],
					"normal": triangle_normal,
					"area": area,
					"center": (v1 + v2 + v3) / 3.0,
					"indices": [idx1, idx2, idx3]
				}
				
				surface_data.walkable_triangles.append(triangle_data)
				surface_data.total_walkable_area += area
				surface_data.surface_count += 1
	
	print("DEBUG: Analyzed %d total triangles, found %d walkable (%.1f%%) with total area %.2f m²" % 
		[indices.size() / 3, surface_data.walkable_triangles.size(), 
		(surface_data.walkable_triangles.size() * 100.0) / max(1, indices.size() / 3),
		surface_data.total_walkable_area])
	
	return surface_data

func create_walkable_mesh(walkable_triangles: Array) -> ArrayMesh:
	"""Create a simplified mesh containing only walkable surfaces"""
	if walkable_triangles.size() == 0:
		return null
	
	var walkable_vertices = PackedVector3Array()
	var walkable_normals = PackedVector3Array()
	var walkable_indices = PackedInt32Array()
	
	# Build simplified mesh with only walkable triangles
	for triangle_data in walkable_triangles:
		var start_index = walkable_vertices.size()
		
		# Add vertices and normals
		for vertex in triangle_data.vertices:
			walkable_vertices.append(vertex)
			walkable_normals.append(triangle_data.normal)
		
		# Add indices
		walkable_indices.append(start_index)
		walkable_indices.append(start_index + 1)
		walkable_indices.append(start_index + 2)
	
	# Create mesh
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = walkable_vertices
	arrays[Mesh.ARRAY_NORMAL] = walkable_normals
	arrays[Mesh.ARRAY_INDEX] = walkable_indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func generate_navigation_tiles(walkable_triangles: Array, parent_node: Node3D) -> Array[Area3D]:
	"""Generate 1x1 meter navigation tiles for VR teleportation"""
	var navigation_tiles: Array[Area3D] = []
	
	print("CaveCollisionGenerator: Generating 1x1m navigation tiles...")
	
	# Group triangles into 1x1 meter grid cells
	var tile_grid = create_tile_grid(walkable_triangles)
	
	for grid_pos in tile_grid.keys():
		var tile_triangles = tile_grid[grid_pos]
		if tile_triangles.size() > 0:
			var tile_area = create_navigation_tile(grid_pos, tile_triangles, parent_node)
			if tile_area != null:
				navigation_tiles.append(tile_area)
	
	print("Created %d navigation tiles" % navigation_tiles.size())
	return navigation_tiles

func create_tile_grid(walkable_triangles: Array) -> Dictionary:
	"""Organize walkable triangles into a 1x1 meter grid"""
	var tile_grid = {}
	
	for triangle_data in walkable_triangles:
		var center = triangle_data.center
		
		# Convert world position to grid coordinates
		var grid_x = int(floor(center.x / tile_size))
		var grid_z = int(floor(center.z / tile_size))
		var grid_pos = Vector2i(grid_x, grid_z)
		
		if not tile_grid.has(grid_pos):
			tile_grid[grid_pos] = []
		
		tile_grid[grid_pos].append(triangle_data)
	
	return tile_grid

func create_navigation_tile(grid_pos: Vector2i, tile_triangles: Array, parent_node: Node3D) -> Area3D:
	"""Create a single 1x1 meter navigation tile"""
	if tile_triangles.size() == 0:
		return null
	
	# Calculate average height and normal for this tile
	var average_height = 0.0
	var average_normal = Vector3.ZERO
	var total_area = 0.0
	
	for triangle_data in tile_triangles:
		var weight = triangle_data.area
		average_height += triangle_data.center.y * weight
		average_normal += triangle_data.normal * weight
		total_area += weight
	
	if total_area <= 0.0:
		return null
	
	average_height /= total_area
	average_normal = (average_normal / total_area).normalized()
	
	# Create navigation area
	var nav_area = Area3D.new()
	nav_area.name = "NavTile_%d_%d" % [grid_pos.x, grid_pos.y]
	
	# Position at grid center
	var world_x = grid_pos.x * tile_size + tile_size * 0.5
	var world_z = grid_pos.y * tile_size + tile_size * 0.5
	nav_area.position = Vector3(world_x, average_height, world_z)
	
	# Create collision shape (flat 1x1 meter area)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(tile_size, 0.1, tile_size)  # Very thin box
	collision_shape.shape = box_shape
	nav_area.add_child(collision_shape)
	
	# Add VR teleportation metadata
	nav_area.set_meta("vr_teleport_target", true)
	nav_area.set_meta("grid_position", grid_pos)
	nav_area.set_meta("surface_normal", average_normal)
	nav_area.set_meta("walkable_area", total_area)
	nav_area.set_meta("tile_size", tile_size)
	
	# Set collision layers for VR detection
	nav_area.collision_layer = 4  # Layer 3 for VR navigation
	nav_area.collision_mask = 0   # Don't detect anything
	
	parent_node.add_child(nav_area)
	return nav_area

func create_vr_teleport_markers(navigation_tiles: Array[Area3D], parent_node: Node3D):
	"""Create visual markers for VR teleportation targets"""
	print("CaveCollisionGenerator: Creating VR teleport markers...")
	
	for nav_tile in navigation_tiles:
		var marker = create_teleport_marker(nav_tile)
		if marker != null:
			nav_tile.add_child(marker)

func create_teleport_marker(nav_tile: Area3D) -> MeshInstance3D:
	"""Create a visual marker for a teleport target"""
	var marker = MeshInstance3D.new()
	marker.name = "TeleportMarker"
	
	# Create circular platform mesh
	var mesh = create_platform_mesh()
	marker.mesh = mesh
	
	# Create glowing material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN
	material.emission_energy = 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	marker.set_surface_override_material(0, material)
	
	# Position slightly above the surface
	marker.position.y = 0.05
	
	return marker

func create_platform_mesh() -> ArrayMesh:
	"""Create a circular platform mesh for teleport markers"""
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var radius = tile_size * 0.4  # 40% of tile size
	var segments = 16
	
	# Center vertex
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	
	# Circle vertices
	for i in range(segments):
		var angle = i * TAU / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		vertices.append(Vector3(x, 0, z))
		normals.append(Vector3.UP)
		uvs.append(Vector2(x / radius * 0.5 + 0.5, z / radius * 0.5 + 0.5))
	
	# Create triangles
	for i in range(segments):
		var next_i = (i + 1) % segments
		
		indices.append(0)  # Center
		indices.append(i + 1)  # Current
		indices.append(next_i + 1)  # Next
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func get_walkable_area_at_position(position: Vector3) -> Area3D:
	"""Find the closest walkable navigation tile to a position"""
	var closest_tile: Area3D = null
	var closest_distance = INF
	
	for body in collision_bodies:
		if body.has_meta("vr_walkable"):
			var distance = body.global_position.distance_to(position)
			if distance < closest_distance:
				closest_distance = distance
				# Would need to access the navigation tiles created for this body
	
	return closest_tile

func is_position_walkable(position: Vector3) -> bool:
	"""Check if a position is on a walkable surface"""
	# Cast ray downward to check for walkable collision
	var space_state = Engine.get_main_loop().current_scene.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		position + Vector3.UP,
		position + Vector3.DOWN * 2.0
	)
	query.collision_mask = 4  # VR navigation layer
	
	var result = space_state.intersect_ray(query)
	if result.has("collider"):
		var collider = result.collider
		return collider.has_meta("vr_walkable")
	
	return false 
