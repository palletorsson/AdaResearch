@tool
extends MeshInstance3D
class_name DelaunayTriangulation3DCell

@export var generations: int = 7
@export var initial_points: int = 20
@export var subdivision_factor: float = 0.5
@export_range(0.0, 2.0) var randomness: float = 0.3
@export var cell_radius: float = 2.0
@export var regenerate: bool = false:
	set(value):
		if value:
			generate_cell_body()
			regenerate = false

func _ready():
	generate_cell_body()

func generate_cell_body():
	var points = generate_hierarchical_points()
	var mesh_data = create_delaunay_mesh(points)
	mesh = mesh_data

# Generate points with generational hierarchy
func generate_hierarchical_points() -> Array:
	var points = []
	
	# Generation 0: Initial points on sphere
	for i in range(initial_points):
		var theta = randf() * TAU
		var phi = acos(2.0 * randf() - 1.0)
		var r = cell_radius
		
		var point = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		points.append(point)
	
	# Subsequent generations: subdivide and add interior points
	for gen in range(1, generations):
		var gen_points = []
		var layer_radius = cell_radius * (1.0 - float(gen) / float(generations))
		var points_this_gen = int(initial_points * pow(subdivision_factor, gen))
		
		for i in range(points_this_gen):
			var theta = randf() * TAU
			var phi = acos(2.0 * randf() - 1.0)
			var r = layer_radius + randf_range(-randomness, randomness)
			
			var point = Vector3(
				r * sin(phi) * cos(theta),
				r * sin(phi) * sin(theta),
				r * cos(phi)
			)
			gen_points.append(point)
		
		points.append_array(gen_points)
	
	# Add center point
	points.append(Vector3.ZERO)
	
	return points

# Create mesh using simplified Delaunay approach
func create_delaunay_mesh(points: Array) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create convex hull and internal triangulation
	var triangles = triangulate_points(points)
	
	# Build mesh from triangles
	for tri in triangles:
		var p1 = points[tri[0]]
		var p2 = points[tri[1]]
		var p3 = points[tri[2]]
		
		var normal = (p2 - p1).cross(p3 - p1).normalized()
		
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p3)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

# Simplified triangulation using convex hull approach
func triangulate_points(points: Array) -> Array:
	var triangles = []
	var n = points.size()
	
	if n < 4:
		return triangles
	
	# Create triangulation using nearest neighbor approach
	for i in range(n):
		var neighbors = find_nearest_neighbors(i, points, 6)
		
		for j in range(neighbors.size() - 1):
			for k in range(j + 1, neighbors.size()):
				if is_valid_triangle(i, neighbors[j], neighbors[k], points):
					triangles.append([i, neighbors[j], neighbors[k]])
	
	# Remove duplicate triangles
	return remove_duplicate_triangles(triangles)

func find_nearest_neighbors(index: int, points: Array, count: int) -> Array:
	var distances = []
	var point = points[index]
	
	for i in range(points.size()):
		if i != index:
			var dist = point.distance_to(points[i])
			distances.append({"index": i, "distance": dist})
	
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	var neighbors = []
	for i in range(min(count, distances.size())):
		neighbors.append(distances[i].index)
	
	return neighbors

func is_valid_triangle(i1: int, i2: int, i3: int, points: Array) -> bool:
	var p1 = points[i1]
	var p2 = points[i2]
	var p3 = points[i3]
	
	# Check if triangle has reasonable area
	var edge1 = p2 - p1
	var edge2 = p3 - p1
	var area = edge1.cross(edge2).length()
	
	return area > 0.001

func remove_duplicate_triangles(triangles: Array) -> Array:
	var unique = []
	var seen = {}
	
	for tri in triangles:
		var sorted_tri = tri.duplicate()
		sorted_tri.sort()
		var key = str(sorted_tri)
		
		if not seen.has(key):
			seen[key] = true
			unique.append(tri)
	
	return unique
