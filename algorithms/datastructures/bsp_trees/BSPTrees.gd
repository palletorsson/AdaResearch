extends Node3D

# BSP Trees (Binary Space Partitioning)
# Demonstrates recursive space subdivision for 3D scene management

var time := 0.0
var construction_step := 0
var max_depth := 4
var current_depth := 0

# BSP Tree structure
class BSPNode:
	var plane_normal: Vector3
	var plane_point: Vector3
	var front_child: BSPNode
	var back_child: BSPNode
	var polygons: Array
	var bounds: AABB
	var depth: int

var root_node: BSPNode
var partitioning_planes := []
var space_regions := []

func _ready():
	initialize_bsp_tree()
	create_initial_space()

func _process(delta):
	time += delta
	
	animate_construction_process()
	demonstrate_traversal()
	visualize_space_partitions()
	update_tree_structure()

func initialize_bsp_tree():
	root_node = BSPNode.new()
	root_node.bounds = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	root_node.depth = 0
	
	# Initialize with some test polygons
	root_node.polygons = create_test_polygons()

func create_test_polygons() -> Array:
	var polygons = []
	
	# Create some random polygons in 3D space
	for i in range(12):
		var polygon = {
			"vertices": [],
			"center": Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4)),
			"color": Color(randf(), randf(), randf())
		}
		
		# Create triangle vertices
		for j in range(3):
			var vertex = polygon.center + Vector3(
				randf_range(-0.5, 0.5),
				randf_range(-0.5, 0.5),
				randf_range(-0.5, 0.5)
			)
			polygon.vertices.append(vertex)
		
		polygons.append(polygon)
	
	return polygons

func create_initial_space():
	var container = $SpacePartitions
	
	# Create initial bounding box
	var initial_box = CSGBox3D.new()
	initial_box.size = Vector3(10, 10, 10)
	initial_box.position = Vector3(0, 0, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 1.0, 0.3)
	material.metallic = 0.1
	material.roughness = 0.8
	material.flags_transparent = true
	initial_box.material_override = material
	
	container.add_child(initial_box)

func animate_construction_process():
	var container = $ConstructionProcess
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	if int(time * 0.5) % 8 == 0:
		construction_step = (construction_step + 1) % max_depth
	
	# Show BSP construction step by step
	show_construction_step(container, construction_step)

func show_construction_step(container: Node3D, step: int):
	var current_bounds = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	
	for depth in range(step + 1):
		var divisions = 1 << depth  # 2^depth
		var region_size = 8.0 / divisions
		
		for i in range(divisions):
			for j in range(divisions):
				for k in range(divisions):
					var region = CSGBox3D.new()
					region.size = Vector3(region_size * 0.9, region_size * 0.9, region_size * 0.9)
					region.position = Vector3(
						-4 + region_size * i + region_size * 0.5,
						-4 + region_size * j + region_size * 0.5,
						-4 + region_size * k + region_size * 0.5
					)
					
					var material = StandardMaterial3D.new()
					var intensity = 1.0 - (float(depth) / max_depth) * 0.7
					material.albedo_color = Color(intensity, 0.5, 1.0 - intensity, 0.4)
					material.flags_transparent = true
					material.emission_enabled = true
					material.emission = Color(intensity, 0.5, 1.0 - intensity) * 0.2
					region.material_override = material
					
					container.add_child(region)

func demonstrate_traversal():
	var container = $TraversalDemo
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create a moving point that demonstrates BSP traversal
	var traversal_point = CSGSphere3D.new()
	traversal_point.radius = 0.3
	
	# Move point in a figure-8 pattern
	var t = time * 0.5
	traversal_point.position = Vector3(
		sin(t) * 3,
		cos(t * 2) * 2,
		sin(t * 0.7) * 3
	)
	
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color(1.0, 0.2, 0.2)
	point_material.emission_enabled = true
	point_material.emission = Color(1.0, 0.2, 0.2) * 0.6
	traversal_point.material_override = point_material
	
	container.add_child(traversal_point)
	
	# Show traversal path
	show_traversal_path(container, traversal_point.position)

func show_traversal_path(container: Node3D, query_point: Vector3):
	# Simulate BSP tree traversal path
	var current_region = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	
	for depth in range(3):
		# Choose splitting plane (alternating X, Y, Z)
		var axis = depth % 3
		var split_pos = current_region.position[axis] + current_region.size[axis] * 0.5
		
		# Determine which side of the plane the query point is on
		var on_positive_side = query_point[axis] > split_pos
		
		# Create splitting plane visualization
		var plane = CSGBox3D.new()
		if axis == 0:  # X-axis split
			plane.size = Vector3(0.1, current_region.size.y, current_region.size.z)
			plane.position = Vector3(split_pos, current_region.position.y + current_region.size.y * 0.5, current_region.position.z + current_region.size.z * 0.5)
		elif axis == 1:  # Y-axis split
			plane.size = Vector3(current_region.size.x, 0.1, current_region.size.z)
			plane.position = Vector3(current_region.position.x + current_region.size.x * 0.5, split_pos, current_region.position.z + current_region.size.z * 0.5)
		else:  # Z-axis split
			plane.size = Vector3(current_region.size.x, current_region.size.y, 0.1)
			plane.position = Vector3(current_region.position.x + current_region.size.x * 0.5, current_region.position.y + current_region.size.y * 0.5, split_pos)
		
		var plane_material = StandardMaterial3D.new()
		plane_material.albedo_color = Color(1.0, 1.0, 0.0, 0.6)
		plane_material.flags_transparent = true
		plane_material.emission_enabled = true
		plane_material.emission = Color(1.0, 1.0, 0.0) * 0.3
		plane.material_override = plane_material
		
		container.add_child(plane)
		
		# Update current region based on traversal
		if on_positive_side:
			current_region.position[axis] = split_pos
			current_region.size[axis] *= 0.5
		else:
			current_region.size[axis] *= 0.5

func visualize_space_partitions():
	var container = $SpacePartitions
	
	# Clear old partitions except the first (base) box
	var children = container.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	
	# Add animated partitioning planes
	var num_planes = int(time * 0.3) % 6 + 1
	
	for i in range(num_planes):
		var plane = CSGBox3D.new()
		var axis = i % 3
		
		if axis == 0:  # X-axis partition
			plane.size = Vector3(0.2, 10, 10)
			plane.position = Vector3(sin(time + i) * 3, 0, 0)
		elif axis == 1:  # Y-axis partition
			plane.size = Vector3(10, 0.2, 10)
			plane.position = Vector3(0, sin(time * 1.2 + i) * 3, 0)
		else:  # Z-axis partition
			plane.size = Vector3(10, 10, 0.2)
			plane.position = Vector3(0, 0, sin(time * 0.8 + i) * 3)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.2, 0.5)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.2) * 0.2
		plane.material_override = material
		
		container.add_child(plane)

func update_tree_structure():
	var container = $BSPTreeStructure
	
	# Clear previous tree visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize BSP tree structure as a hierarchy
	var tree_depth = int(time * 0.2) % 4 + 1
	create_tree_nodes(container, Vector3(0, 5, 0), tree_depth, 0, 4.0)

func create_tree_nodes(container: Node3D, position: Vector3, max_depth: int, current_depth: int, spacing: float):
	if current_depth >= max_depth:
		return
	
	# Create node
	var node = CSGSphere3D.new()
	node.radius = 0.3
	node.position = position
	
	var material = StandardMaterial3D.new()
	var depth_ratio = float(current_depth) / max_depth
	material.albedo_color = Color(1.0 - depth_ratio, depth_ratio, 0.5)
	material.emission_enabled = true
	material.emission = Color(1.0 - depth_ratio, depth_ratio, 0.5) * 0.3
	node.material_override = material
	
	container.add_child(node)
	
	# Create children
	if current_depth < max_depth - 1:
		var child_spacing = spacing * 0.6
		var left_pos = position + Vector3(-child_spacing, -1.5, 0)
		var right_pos = position + Vector3(child_spacing, -1.5, 0)
		
		# Create connections
		create_connection(container, position, left_pos)
		create_connection(container, position, right_pos)
		
		# Recursively create child nodes
		create_tree_nodes(container, left_pos, max_depth, current_depth + 1, child_spacing)
		create_tree_nodes(container, right_pos, max_depth, current_depth + 1, child_spacing)

func create_connection(container: Node3D, from: Vector3, to: Vector3):
	var connection = CSGCylinder3D.new()
	connection.top_radius = 0.05
	connection.bottom_radius = 0.05
	connection.height = from.distance_to(to)
	
	# Position and orient the cylinder
	connection.position = (from + to) * 0.5
	connection.look_at(to, Vector3.UP)
	connection.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8)
	connection.material_override = material
	
	container.add_child(connection)

