@tool
extends Node3D

@export_group("Voronoi Settings")
@export var region_size: Vector3 = Vector3(10, 10, 10)
@export var num_seeds: int = 20
@export var seed_value: int = 0
@export_enum("Random", "Grid", "Poisson", "Spherical", "Layered") var seed_distribution: int = 0

@export_group("Surface Settings")
@export var render_mode_enum: int = 0:
	set(value):
		render_mode_enum = value
		if is_node_ready():
			visualize_samples()
@export_enum("Outer_Faces_Only", "All_Faces", "Wireframe", "Dual_Mesh") var render_mode: int = 0
@export var face_thickness: float = 0.05
@export var show_boundaries_only: bool = true
@export var cull_internal_faces: bool = true

@export_group("Visual")
@export var show_seeds: bool = true
@export var color_per_cell: bool = true
@export var cell_colors: Array[Color] = [
	Color(0.8, 0.4, 0.4),
	Color(0.4, 0.8, 0.4),
	Color(0.4, 0.4, 0.8),
	Color(0.8, 0.8, 0.4),
	Color(0.8, 0.4, 0.8),
	Color(0.4, 0.8, 0.8)
]

@export_group("Quality")
@export_range(16, 48) var resolution: int = 32
@export var smooth_normals: bool = true

@export var regenerate: bool = false:
	set(value):
		if value:
			generate_voronoi()
			regenerate = false

class VoronoiCell:
	var seed_point: Vector3
	var boundary_faces: Array[BoundaryFace] = []
	var color: Color
	var id: int
	
	func _init(seed: Vector3, cell_id: int):
		seed_point = seed
		id = cell_id

class BoundaryFace:
	var vertices: Array[Vector3] = []
	var normal: Vector3
	var neighbor_cell_id: int = -1
	var is_external: bool = false
	
	func _init(verts: Array[Vector3]):
		vertices = verts
		if vertices.size() >= 3:
			calculate_normal()
	
	func calculate_normal():
		var v1 = vertices[1] - vertices[0]
		var v2 = vertices[2] - vertices[0]
		normal = v1.cross(v2).normalized()
	
	func get_center() -> Vector3:
		var center = Vector3.ZERO
		for v in vertices:
			center += v
		return center / vertices.size()

var seed_points: Array[Vector3] = []
var voronoi_cells: Array[VoronoiCell] = []
var grid_resolution: Vector3i

func _ready():
	generate_voronoi()

func generate_voronoi():
	clear_structure()
	
	if seed_value != 0:
		seed(seed_value)
	
	generate_seeds()
	compute_voronoi_cells()
	detect_boundary_faces()
	visualize_samples()
	
	print("Generated ", voronoi_cells.size(), " Voronoi cells with boundary faces")

func generate_seeds():
	seed_points.clear()
	
	match seed_distribution:
		0: # Random
			for i in range(num_seeds):
				seed_points.append(random_point_in_region())
		1: # Grid
			var grid_size = ceili(pow(num_seeds, 1.0/3.0))
			for x in range(grid_size):
				for y in range(grid_size):
					for z in range(grid_size):
						if seed_points.size() >= num_seeds:
							break
						var point = Vector3(
							(float(x) / grid_size - 0.5) * region_size.x,
							(float(y) / grid_size - 0.5) * region_size.y,
							(float(z) / grid_size - 0.5) * region_size.z
						)
						seed_points.append(point)
		2: # Poisson
			generate_poisson_seeds()
		3: # Spherical
			for i in range(num_seeds):
				var theta = randf() * TAU
				var phi = acos(2.0 * randf() - 1.0)
				var r = pow(randf(), 1.0/3.0) * min(region_size.x, min(region_size.y, region_size.z)) / 2
				seed_points.append(Vector3(
					r * sin(phi) * cos(theta),
					r * sin(phi) * sin(theta),
					r * cos(phi)
				))
		4: # Layered
			var layers = ceili(sqrt(num_seeds))
			var per_layer = ceili(float(num_seeds) / layers)
			for layer in range(layers):
				var y = (float(layer) / layers - 0.5) * region_size.y
				for i in range(per_layer):
					if seed_points.size() >= num_seeds:
						break
					var angle = float(i) / per_layer * TAU
					var radius = randf() * region_size.x * 0.4
					seed_points.append(Vector3(
						cos(angle) * radius, y, sin(angle) * radius
					))

func generate_poisson_seeds():
	var min_distance = region_size.length() / pow(num_seeds, 1.0/3.0) * 0.8
	var active_list: Array[Vector3] = []
	var initial = random_point_in_region()
	seed_points.append(initial)
	active_list.append(initial)
	
	while active_list.size() > 0 and seed_points.size() < num_seeds:
		var idx = randi() % active_list.size()
		var point = active_list[idx]
		var found = false
		
		for _attempt in range(30):
			var new_point = point + random_direction() * randf_range(min_distance, min_distance * 2)
			if is_in_region(new_point) and is_far_enough(new_point, min_distance):
				seed_points.append(new_point)
				active_list.append(new_point)
				found = true
				break
		
		if not found:
			active_list.remove_at(idx)

func compute_voronoi_cells():
	voronoi_cells.clear()
	grid_resolution = Vector3i(resolution, resolution, resolution)
	
	# Create cells
	for i in range(seed_points.size()):
		var cell = VoronoiCell.new(seed_points[i], i)
		if color_per_cell:
			cell.color = cell_colors[i % cell_colors.size()]
		else:
			cell.color = Color(0.7, 0.7, 0.9)
		voronoi_cells.append(cell)

func detect_boundary_faces():
	# Sample the volume to find boundary faces between cells
	var step = region_size / Vector3(grid_resolution)
	var half_region = region_size / 2
	
	# Dictionary to store boundary information
	# Key: "cellA_cellB" Value: array of boundary points
	var boundary_points: Dictionary = {}
	
	# Sample grid
	for x in range(grid_resolution.x):
		for y in range(grid_resolution.y):
			for z in range(grid_resolution.z):
				var pos = Vector3(
					float(x) / grid_resolution.x * region_size.x - half_region.x,
					float(y) / grid_resolution.y * region_size.y - half_region.y,
					float(z) / grid_resolution.z * region_size.z - half_region.z
				)
				
				var nearest_idx = find_nearest_seed(pos)
				
				# Check neighbors to find boundaries
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						for dz in [-1, 0, 1]:
							if dx == 0 and dy == 0 and dz == 0:
								continue
							
							var neighbor_pos = pos + Vector3(dx, dy, dz) * step
							if not is_in_region(neighbor_pos):
								continue
							
							var neighbor_idx = find_nearest_seed(neighbor_pos)
							
							# Found boundary between two cells
							if neighbor_idx != nearest_idx:
								var key = get_boundary_key(nearest_idx, neighbor_idx)
								if not boundary_points.has(key):
									boundary_points[key] = []
								
								# Store midpoint between cells
								var midpoint = (pos + neighbor_pos) / 2
								boundary_points[key].append(midpoint)
	
	# Convert boundary points to faces
	for key in boundary_points:
		var points = boundary_points[key]
		if points.size() < 3:
			continue
		
		var cell_ids = key.split("_")
		var cell_a = int(cell_ids[0])
		var cell_b = int(cell_ids[1])
		
		# Create face from boundary points
		var face = create_boundary_face(points, cell_a, cell_b)
		if face:
			voronoi_cells[cell_a].boundary_faces.append(face)
			
			# Create mirrored face for other cell
			var face_b = create_boundary_face(points, cell_b, cell_a)
			if face_b:
				# Reverse normal for other side
				face_b.normal = -face_b.normal
				voronoi_cells[cell_b].boundary_faces.append(face_b)

func create_boundary_face(points: Array, cell_id: int, neighbor_id: int) -> BoundaryFace:
	if points.size() < 3:
		return null
	
	# Find center of points
	var center = Vector3.ZERO
	for p in points:
		center += p
	center /= points.size()
	
	# Sort points by angle around center to create proper face
	var sorted_points = sort_points_by_angle(points, center)
	
	# Create triangulated face
	var face_vertices: Array[Vector3] = []
	
	# Simple fan triangulation from center
	for i in range(sorted_points.size()):
		face_vertices.append(center)
		face_vertices.append(sorted_points[i])
		face_vertices.append(sorted_points[(i + 1) % sorted_points.size()])
	
	var face = BoundaryFace.new(face_vertices)
	face.neighbor_cell_id = neighbor_id
	face.is_external = (neighbor_id == -1)
	
	return face

func sort_points_by_angle(points: Array, center: Vector3) -> Array[Vector3]:
	# Project points to 2D plane and sort by angle
	if points.size() < 3:
		return points
	
	# Find average normal direction
	var normal = Vector3.ZERO
	for i in range(points.size()):
		var p1 = points[i] - center
		var p2 = points[(i + 1) % points.size()] - center
		normal += p1.cross(p2)
	normal = normal.normalized()
	
	# Create basis vectors for 2D projection
	var tangent = Vector3.UP if abs(normal.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var u = normal.cross(tangent).normalized()
	var v = u.cross(normal).normalized()
	
	# Sort by angle
	var point_angles: Array = []
	for point in points:
		var relative = point - center
		var angle = atan2(relative.dot(v), relative.dot(u))
		point_angles.append({"point": point, "angle": angle})
	
	point_angles.sort_custom(func(a, b): return a.angle < b.angle)
	
	var sorted: Array[Vector3] = []
	for item in point_angles:
		sorted.append(item.point)
	
	return sorted

func visualize_samples():
	clear_visualization()
	
	match render_mode:
		0: # Outer faces only
			draw_outer_faces_only()
		1: # All faces
			draw_all_faces()
		2: # Wireframe
			draw_wireframe()
		3: # Dual mesh
			draw_dual_mesh()
	
	if show_seeds:
		visualize_seeds()

func draw_outer_faces_only():
	# Draw only the boundary faces of each cell
	for cell in voronoi_cells:
		if cell.boundary_faces.size() == 0:
			continue
		
		var mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
		
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		for face in cell.boundary_faces:
			# Draw triangles for this face
			for i in range(0, face.vertices.size(), 3):
				if i + 2 < face.vertices.size():
					var v1 = face.vertices[i]
					var v2 = face.vertices[i + 1]
					var v3 = face.vertices[i + 2]
					
					# Calculate face normal
					var normal = (v2 - v1).cross(v3 - v1).normalized()
					
					surface_tool.set_normal(normal)
					surface_tool.add_vertex(v1)
					surface_tool.set_normal(normal)
					surface_tool.add_vertex(v2)
					surface_tool.set_normal(normal)
					surface_tool.add_vertex(v3)
		
		if smooth_normals:
			surface_tool.generate_normals()
		
		mesh_instance.mesh = surface_tool.commit()
		
		# Material
		var material = StandardMaterial3D.new()
		material.albedo_color = cell.color
		material.metallic = 0.1
		material.roughness = 0.8
		material.cull_mode = BaseMaterial3D.CULL_BACK
		mesh_instance.material_override = material

func draw_all_faces():
	# Similar to outer faces but includes all detected faces
	draw_outer_faces_only()  # For now, same implementation

func draw_wireframe():
	# Draw edges of boundary faces
	for cell in voronoi_cells:
		for face in cell.boundary_faces:
			if face.vertices.size() < 3:
				continue
			
			var mesh_instance = MeshInstance3D.new()
			add_child(mesh_instance)
			
			var surface_tool = SurfaceTool.new()
			surface_tool.begin(Mesh.PRIMITIVE_LINES)
			
			# Draw edges
			for i in range(0, face.vertices.size(), 3):
				if i + 2 < face.vertices.size():
					surface_tool.add_vertex(face.vertices[i])
					surface_tool.add_vertex(face.vertices[i + 1])
					
					surface_tool.add_vertex(face.vertices[i + 1])
					surface_tool.add_vertex(face.vertices[i + 2])
					
					surface_tool.add_vertex(face.vertices[i + 2])
					surface_tool.add_vertex(face.vertices[i])
			
			mesh_instance.mesh = surface_tool.commit()
			
			var material = StandardMaterial3D.new()
			material.albedo_color = cell.color
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh_instance.material_override = material

func draw_dual_mesh():
	# Draw lines connecting seed points through boundary faces
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	for cell in voronoi_cells:
		for face in cell.boundary_faces:
			if face.neighbor_cell_id >= 0 and face.neighbor_cell_id < voronoi_cells.size():
				var neighbor = voronoi_cells[face.neighbor_cell_id]
				surface_tool.add_vertex(cell.seed_point)
				surface_tool.add_vertex(neighbor.seed_point)
	
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

func visualize_seeds():
	for seed in seed_points:
		var sphere = MeshInstance3D.new()
		add_child(sphere)
		
		var mesh = SphereMesh.new()
		mesh.radius = 0.15
		sphere.mesh = mesh
		sphere.position = seed
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0.3, 0.3)
		material.emission_enabled = true
		material.emission = Color(1, 0.3, 0.3)
		material.emission_energy_multiplier = 2.0
		sphere.material_override = material

func get_boundary_key(cell_a: int, cell_b: int) -> String:
	var min_id = min(cell_a, cell_b)
	var max_id = max(cell_a, cell_b)
	return "%d_%d" % [min_id, max_id]

func find_nearest_seed(point: Vector3) -> int:
	var nearest_idx = 0
	var min_dist = INF
	
	for i in range(seed_points.size()):
		var dist = point.distance_to(seed_points[i])
		if dist < min_dist:
			min_dist = dist
			nearest_idx = i
	
	return nearest_idx

func random_point_in_region() -> Vector3:
	return Vector3(
		randf() * region_size.x - region_size.x / 2,
		randf() * region_size.y - region_size.y / 2,
		randf() * region_size.z - region_size.z / 2
	)

func random_direction() -> Vector3:
	var theta = randf() * TAU
	var phi = acos(2.0 * randf() - 1.0)
	return Vector3(
		sin(phi) * cos(theta),
		sin(phi) * sin(theta),
		cos(phi)
	)

func is_in_region(point: Vector3) -> bool:
	return abs(point.x) <= region_size.x / 2 and \
		   abs(point.y) <= region_size.y / 2 and \
		   abs(point.z) <= region_size.z / 2

func is_far_enough(point: Vector3, min_dist: float) -> bool:
	for seed in seed_points:
		if point.distance_to(seed) < min_dist:
			return false
	return true

func clear_structure():
	seed_points.clear()
	voronoi_cells.clear()
	clear_visualization()

func clear_visualization():
	for child in get_children():
		child.queue_free()
