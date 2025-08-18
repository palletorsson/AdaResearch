extends Node3D

# Quadtrees and Octrees Visualization
# Demonstrates spatial data structures for efficient range queries

var time := 0.0
var insertion_timer := 0.0

# Quadtree structure (2D)
class QuadNode:
	var bounds: Rect2
	var points: Array
	var children: Array  # [NW, NE, SW, SE]
	var max_points := 4
	var is_divided := false

# Octree structure (3D)
class OctNode:
	var bounds: AABB
	var points: Array
	var children: Array  # 8 octants
	var max_points := 4
	var is_divided := false

var quadtree_root: QuadNode
var octree_root: OctNode
var query_region: Rect2
var query_volume: AABB

# Points for insertion
var quad_points := []
var oct_points := []

func _ready():
	initialize_structures()
	create_initial_points()

func _process(delta):
	time += delta
	insertion_timer += delta
	
	animate_quadtree()
	animate_octree()
	demonstrate_spatial_queries()
	show_dynamic_insertion()

func initialize_structures():
	# Initialize quadtree
	quadtree_root = QuadNode.new()
	quadtree_root.bounds = Rect2(-5, -5, 10, 10)
	quadtree_root.children = []
	quadtree_root.points = []
	
	# Initialize octree
	octree_root = OctNode.new()
	octree_root.bounds = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	octree_root.children = []
	octree_root.points = []
	
	# Initialize query regions
	query_region = Rect2(-2, -2, 4, 4)
	query_volume = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

func create_initial_points():
	# Create random points for quadtree
	for i in range(20):
		quad_points.append(Vector2(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5)))
	
	# Create random points for octree
	for i in range(30):
		oct_points.append(Vector3(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5), randf_range(-4.5, 4.5)))

func animate_quadtree():
	var container = $QuadtreeVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Rebuild quadtree with current points
	quadtree_root = QuadNode.new()
	quadtree_root.bounds = Rect2(-5, -5, 10, 10)
	quadtree_root.children = []
	quadtree_root.points = []
	
	# Insert points gradually
	var points_to_insert = min(int(time * 2), quad_points.size())
	for i in range(points_to_insert):
		insert_point_quad(quadtree_root, quad_points[i])
	
	# Visualize quadtree structure
	visualize_quadtree(container, quadtree_root, 0)
	
	# Visualize points
	for i in range(points_to_insert):
		var point_marker = CSGSphere3D.new()
		point_marker.radius = 0.1
		point_marker.position = Vector3(quad_points[i].x, 0, quad_points[i].y)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.2, 0.2)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.2, 0.2) * 0.5
		point_marker.material_override = material
		
		container.add_child(point_marker)

func animate_octree():
	var container = $OctreeVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Rebuild octree with current points
	octree_root = OctNode.new()
	octree_root.bounds = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	octree_root.children = []
	octree_root.points = []
	
	# Insert points gradually
	var points_to_insert = min(int(time * 1.5), oct_points.size())
	for i in range(points_to_insert):
		insert_point_oct(octree_root, oct_points[i])
	
	# Visualize octree structure
	visualize_octree(container, octree_root, 0)
	
	# Visualize points
	for i in range(points_to_insert):
		var point_marker = CSGSphere3D.new()
		point_marker.radius = 0.1
		point_marker.position = oct_points[i]
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 1.0, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.2, 1.0, 0.2) * 0.5
		point_marker.material_override = material
		
		container.add_child(point_marker)

func insert_point_quad(node: QuadNode, point: Vector2):
	if not node.bounds.has_point(point):
		return
	
	if node.points.size() < node.max_points and not node.is_divided:
		node.points.append(point)
		return
	
	if not node.is_divided:
		subdivide_quad(node)
	
	# Insert into appropriate child
	for child in node.children:
		if child.bounds.has_point(point):
			insert_point_quad(child, point)
			break

func subdivide_quad(node: QuadNode):
	var x = node.bounds.position.x
	var y = node.bounds.position.y
	var w = node.bounds.size.x / 2
	var h = node.bounds.size.y / 2
	
	# Create four children: NW, NE, SW, SE
	var nw = QuadNode.new()
	nw.bounds = Rect2(x, y, w, h)
	nw.children = []
	nw.points = []
	
	var ne = QuadNode.new()
	ne.bounds = Rect2(x + w, y, w, h)
	ne.children = []
	ne.points = []
	
	var sw = QuadNode.new()
	sw.bounds = Rect2(x, y + h, w, h)
	sw.children = []
	sw.points = []
	
	var se = QuadNode.new()
	se.bounds = Rect2(x + w, y + h, w, h)
	se.children = []
	se.points = []
	
	node.children = [nw, ne, sw, se]
	node.is_divided = true
	
	# Redistribute existing points
	for point in node.points:
		for child in node.children:
			if child.bounds.has_point(point):
				child.points.append(point)
				break
	
	node.points.clear()

func insert_point_oct(node: OctNode, point: Vector3):
	if not node.bounds.has_point(point):
		return
	
	if node.points.size() < node.max_points and not node.is_divided:
		node.points.append(point)
		return
	
	if not node.is_divided:
		subdivide_oct(node)
	
	# Insert into appropriate child
	for child in node.children:
		if child.bounds.has_point(point):
			insert_point_oct(child, point)
			break

func subdivide_oct(node: OctNode):
	var pos = node.bounds.position
	var size = node.bounds.size / 2
	
	# Create 8 children octants
	node.children = []
	for i in range(8):
		var child = OctNode.new()
		child.children = []
		child.points = []
		
		var offset = Vector3(
			(i & 1) * size.x,
			((i >> 1) & 1) * size.y,
			((i >> 2) & 1) * size.z
		)
		
		child.bounds = AABB(pos + offset, size)
		node.children.append(child)
	
	node.is_divided = true
	
	# Redistribute existing points
	for point in node.points:
		for child in node.children:
			if child.bounds.has_point(point):
				child.points.append(point)
				break
	
	node.points.clear()

func visualize_quadtree(container: Node3D, node: QuadNode, depth: int):
	if not node:
		return
	
	# Create boundary visualization
	var boundary = CSGBox3D.new()
	boundary.size = Vector3(node.bounds.size.x, 0.1, node.bounds.size.y)
	boundary.position = Vector3(
		node.bounds.position.x + node.bounds.size.x / 2,
		depth * 0.2,
		node.bounds.position.y + node.bounds.size.y / 2
	)
	
	var material = StandardMaterial3D.new()
	var depth_ratio = min(float(depth) / 4.0, 1.0)
	material.albedo_color = Color(0.3 + depth_ratio * 0.7, 0.7, 1.0 - depth_ratio * 0.5, 0.6)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = Color(0.3 + depth_ratio * 0.7, 0.7, 1.0 - depth_ratio * 0.5) * 0.2
	boundary.material_override = material
	
	container.add_child(boundary)
	
	# Recursively visualize children
	if node.is_divided:
		for child in node.children:
			visualize_quadtree(container, child, depth + 1)

func visualize_octree(container: Node3D, node: OctNode, depth: int):
	if not node:
		return
	
	# Create boundary visualization
	var boundary = CSGBox3D.new()
	boundary.size = node.bounds.size * 0.95  # Slightly smaller to show subdivision
	boundary.position = node.bounds.position + node.bounds.size / 2
	
	var material = StandardMaterial3D.new()
	var depth_ratio = min(float(depth) / 3.0, 1.0)
	material.albedo_color = Color(1.0 - depth_ratio * 0.5, 0.3 + depth_ratio * 0.7, 0.7, 0.3)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = Color(1.0 - depth_ratio * 0.5, 0.3 + depth_ratio * 0.7, 0.7) * 0.15
	boundary.material_override = material
	
	container.add_child(boundary)
	
	# Recursively visualize children
	if node.is_divided:
		for child in node.children:
			visualize_octree(container, child, depth + 1)

func demonstrate_spatial_queries():
	var container = $SpatialQueries
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create animated query region
	var query_size = 3.0 + sin(time) * 1.0
	var query_center = Vector3(sin(time * 0.5) * 2, 0, cos(time * 0.5) * 2)
	
	# Visualize 2D query region
	var query_2d = CSGBox3D.new()
	query_2d.size = Vector3(query_size, 0.3, query_size)
	query_2d.position = query_center + Vector3(0, 1, 0)
	
	var query_material = StandardMaterial3D.new()
	query_material.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
	query_material.flags_transparent = true
	query_material.emission_enabled = true
	query_material.emission = Color(1.0, 1.0, 0.0) * 0.4
	query_2d.material_override = query_material
	
	container.add_child(query_2d)
	
	# Visualize 3D query region
	var query_3d = CSGBox3D.new()
	query_3d.size = Vector3(query_size, query_size, query_size)
	query_3d.position = query_center + Vector3(0, -6, 0)
	
	var query_material_3d = StandardMaterial3D.new()
	query_material_3d.albedo_color = Color(1.0, 0.5, 0.0, 0.5)
	query_material_3d.flags_transparent = true
	query_material_3d.emission_enabled = true
	query_material_3d.emission = Color(1.0, 0.5, 0.0) * 0.3
	query_3d.material_override = query_material_3d
	
	container.add_child(query_3d)

func show_dynamic_insertion():
	var container = $DynamicInsertion
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show insertion process with animated points
	if insertion_timer > 0.5:
		insertion_timer = 0.0
		
		# Add new random point to quadtree points
		if quad_points.size() < 50:
			quad_points.append(Vector2(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5)))
		
		# Add new random point to octree points
		if oct_points.size() < 75:
			oct_points.append(Vector3(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5), randf_range(-4.5, 4.5)))
	
	# Show insertion animation
	var insertion_point = Vector3(
		sin(time * 3) * 4,
		cos(time * 2) * 2,
		sin(time * 1.5) * 4
	)
	
	var inserting_point = CSGSphere3D.new()
	inserting_point.radius = 0.2
	inserting_point.position = insertion_point
	
	var insert_material = StandardMaterial3D.new()
	insert_material.albedo_color = Color(1.0, 0.0, 1.0)
	insert_material.emission_enabled = true
	insert_material.emission = Color(1.0, 0.0, 1.0) * 0.8
	inserting_point.material_override = insert_material
	
	container.add_child(inserting_point)
	
	# Show trail
	for i in range(5):
		var trail_point = CSGSphere3D.new()
		trail_point.radius = 0.1 * (1.0 - float(i) / 5.0)
		trail_point.position = insertion_point - Vector3(
			sin(time * 3 - i * 0.2) * 4,
			cos(time * 2 - i * 0.2) * 2,
			sin(time * 1.5 - i * 0.2) * 4
		) * 0.2
		
		var trail_material = StandardMaterial3D.new()
		var alpha = 1.0 - float(i) / 5.0
		trail_material.albedo_color = Color(1.0, 0.0, 1.0, alpha * 0.5)
		trail_material.flags_transparent = true
		trail_point.material_override = trail_material
		
		container.add_child(trail_point)

