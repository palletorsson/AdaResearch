@tool
extends Node3D

@export_group("Target Shape")
@export var cube_size: Vector3 = Vector3(4, 4, 4)
@export var attraction_points_count: int = 500
@export var distribution_thickness: float = 2.0
@export_enum("Shell", "Volume", "Surface", "Corners") var distribution_type: int = 0

@export_group("Growth Settings")
@export var segment_length: float = 0.2
@export var influence_distance: float = 2.0
@export var kill_distance: float = 0.3
@export var max_iterations: int = 1000
@export var branch_thickness: float = 0.15
@export var thickness_decay: float = 0.9

@export_group("Starting Point")
@export var growth_origin: Vector3 = Vector3(0, -6, 0)
@export_enum("Single", "Multiple", "Ring", "Base") var origin_type: int = 0

@export_group("Visual Settings")
@export var show_attraction_points: bool = true
@export var show_cube_guide: bool = true
@export var show_growth_animation: bool = false
@export var branch_color: Color = Color(0.6, 0.4, 0.2)
@export var attraction_color: Color = Color(1, 0.3, 0.3, 0.5)

@export_group("Actions")
@export var regenerate: bool = false:
	set(value):
		if value:
			generate_structure()
			regenerate = false
@export var step_growth: bool = false:
	set(value):
		if value and is_growing:
			grow_iteration()
			step_growth = false
@export var toggle_animation: bool = false:
	set(value):
		if value:
			is_growing = !is_growing
			toggle_animation = false

class GrowthNode:
	var position: Vector3
	var parent: GrowthNode = null
	var children: Array[GrowthNode] = []
	var thickness: float = 1.0
	var growth_direction: Vector3 = Vector3.ZERO
	var influenced_by: int = 0
	
	func _init(pos: Vector3, par: GrowthNode = null, thick: float = 1.0):
		position = pos
		parent = par
		thickness = thick

var attraction_points: Array[Vector3] = []
var active_attraction_points: Array[Vector3] = []
var root_nodes: Array[GrowthNode] = []
var leaf_nodes: Array[GrowthNode] = []
var all_nodes: Array[GrowthNode] = []

var is_growing: bool = false
var current_iteration: int = 0
var growth_timer: float = 0.0

func _ready():
	generate_structure()

func _process(delta):
	if show_growth_animation and is_growing:
		growth_timer += delta * 5.0
		if growth_timer >= 0.05:
			growth_timer = 0.0
			if not grow_iteration():
				is_growing = false

func generate_structure():
	clear_structure()
	current_iteration = 0
	
	# Generate attraction points around cube
	generate_attraction_points()
	
	# Create initial growth nodes
	create_root_nodes()
	
	if not show_growth_animation:
		# Generate entire structure
		while grow_iteration() and current_iteration < max_iterations:
			pass
		print("Growth complete: ", current_iteration, " iterations, ", all_nodes.size(), " nodes")
	else:
		is_growing = true
	
	visualize_structure()

func generate_attraction_points():
	attraction_points.clear()
	active_attraction_points.clear()
	
	match distribution_type:
		0: # Shell - points around cube surface
			generate_shell_distribution()
		1: # Volume - points throughout volume around cube
			generate_volume_distribution()
		2: # Surface - points on cube surface
			generate_surface_distribution()
		3: # Corners - concentrated at corners
			generate_corner_distribution()
	
	active_attraction_points = attraction_points.duplicate()

func generate_shell_distribution():
	for i in range(attraction_points_count):
		# Random point on cube surface
		var face = randi() % 6
		var u = randf() * cube_size.x - cube_size.x / 2
		var v = randf() * cube_size.y - cube_size.y / 2
		
		var point: Vector3
		match face:
			0: point = Vector3(cube_size.x / 2, u, v)
			1: point = Vector3(-cube_size.x / 2, u, v)
			2: point = Vector3(u, cube_size.y / 2, v)
			3: point = Vector3(u, -cube_size.y / 2, v)
			4: point = Vector3(u, v, cube_size.z / 2)
			5: point = Vector3(u, v, -cube_size.z / 2)
		
		# Add random offset outward
		var normal = point.normalized()
		point += normal * randf_range(0, distribution_thickness)
		
		attraction_points.append(point)

func generate_volume_distribution():
	for i in range(attraction_points_count):
		var point = Vector3(
			randf() * (cube_size.x + distribution_thickness * 2) - (cube_size.x / 2 + distribution_thickness),
			randf() * (cube_size.y + distribution_thickness * 2) - (cube_size.y / 2 + distribution_thickness),
			randf() * (cube_size.z + distribution_thickness * 2) - (cube_size.z / 2 + distribution_thickness)
		)
		
		# Check if point is outside cube but within shell
		var inside_outer = (abs(point.x) <= cube_size.x / 2 + distribution_thickness and
						   abs(point.y) <= cube_size.y / 2 + distribution_thickness and
						   abs(point.z) <= cube_size.z / 2 + distribution_thickness)
		
		var inside_inner = (abs(point.x) <= cube_size.x / 2 and
						   abs(point.y) <= cube_size.y / 2 and
						   abs(point.z) <= cube_size.z / 2)
		
		if inside_outer and not inside_inner:
			attraction_points.append(point)

func generate_surface_distribution():
	for i in range(attraction_points_count):
		var face = randi() % 6
		var u = randf() * cube_size.x - cube_size.x / 2
		var v = randf() * cube_size.y - cube_size.y / 2
		
		var point: Vector3
		match face:
			0: point = Vector3(cube_size.x / 2, u, v)
			1: point = Vector3(-cube_size.x / 2, u, v)
			2: point = Vector3(u, cube_size.y / 2, v)
			3: point = Vector3(u, -cube_size.y / 2, v)
			4: point = Vector3(u, v, cube_size.z / 2)
			5: point = Vector3(u, v, -cube_size.z / 2)
		
		attraction_points.append(point)

func generate_corner_distribution():
	var corners = [
		Vector3(1, 1, 1), Vector3(-1, 1, 1),
		Vector3(1, -1, 1), Vector3(-1, -1, 1),
		Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(1, -1, -1), Vector3(-1, -1, -1)
	]
	
	for i in range(attraction_points_count):
		var corner = corners[randi() % corners.size()]
		var base_pos = corner * cube_size / 2
		
		# Add random offset around corner
		var offset = Vector3(
			randf_range(-distribution_thickness, distribution_thickness),
			randf_range(-distribution_thickness, distribution_thickness),
			randf_range(-distribution_thickness, distribution_thickness)
		)
		
		attraction_points.append(base_pos + offset)

func create_root_nodes():
	root_nodes.clear()
	leaf_nodes.clear()
	all_nodes.clear()
	
	match origin_type:
		0: # Single origin
			var root = GrowthNode.new(growth_origin, null, branch_thickness)
			root_nodes.append(root)
			leaf_nodes.append(root)
			all_nodes.append(root)
		
		1: # Multiple origins
			for i in range(4):
				var angle = float(i) / 4.0 * TAU
				var offset = Vector3(cos(angle), 0, sin(angle)) * 2.0
				var root = GrowthNode.new(growth_origin + offset, null, branch_thickness)
				root_nodes.append(root)
				leaf_nodes.append(root)
				all_nodes.append(root)
		
		2: # Ring origin
			for i in range(8):
				var angle = float(i) / 8.0 * TAU
				var offset = Vector3(cos(angle), 0, sin(angle)) * 1.5
				var root = GrowthNode.new(growth_origin + offset, null, branch_thickness * 0.8)
				root_nodes.append(root)
				leaf_nodes.append(root)
				all_nodes.append(root)
		
		3: # Base platform
			for x in range(-2, 3):
				for z in range(-2, 3):
					var offset = Vector3(x * 0.5, 0, z * 0.5)
					var root = GrowthNode.new(growth_origin + offset, null, branch_thickness * 0.6)
					root_nodes.append(root)
					leaf_nodes.append(root)
					all_nodes.append(root)

func grow_iteration() -> bool:
	if active_attraction_points.size() == 0:
		return false
	
	# Reset influence counters
	for node in leaf_nodes:
		node.growth_direction = Vector3.ZERO
		node.influenced_by = 0
	
	# Find closest nodes for each attraction point
	var points_to_remove: Array[int] = []
	
	for i in range(active_attraction_points.size()):
		var attr_point = active_attraction_points[i]
		var closest_node: GrowthNode = null
		var closest_distance = INF
		
		# Find closest leaf node
		for node in leaf_nodes:
			var distance = node.position.distance_to(attr_point)
			
			if distance < influence_distance and distance < closest_distance:
				closest_distance = distance
				closest_node = node
		
		# If point is close enough, influence the node
		if closest_node != null:
			if closest_distance <= kill_distance:
				points_to_remove.append(i)
			else:
				var direction = (attr_point - closest_node.position).normalized()
				closest_node.growth_direction += direction
				closest_node.influenced_by += 1
	
	# Remove colonized points
	for i in range(points_to_remove.size() - 1, -1, -1):
		active_attraction_points.remove_at(points_to_remove[i])
	
	# Generate new nodes
	var new_leaf_nodes: Array[GrowthNode] = []
	var grew = false
	
	for node in leaf_nodes:
		if node.influenced_by > 0:
			# Normalize growth direction
			var growth_dir = node.growth_direction.normalized()
			
			# Create new node
			var new_position = node.position + growth_dir * segment_length
			var new_thickness = node.thickness * thickness_decay
			var new_node = GrowthNode.new(new_position, node, new_thickness)
			
			node.children.append(new_node)
			new_leaf_nodes.append(new_node)
			all_nodes.append(new_node)
			grew = true
		else:
			# Keep node as leaf if not influenced
			new_leaf_nodes.append(node)
	
	leaf_nodes = new_leaf_nodes
	current_iteration += 1
	
	if show_growth_animation:
		visualize_structure()
	
	return grew

func visualize_structure():
	clear_visualization()
	
	# Draw cube guide
	if show_cube_guide:
		create_cube_guide()
	
	# Draw attraction points
	if show_attraction_points:
		draw_attraction_points()
	
	# Draw growth structure
	draw_branches()

func create_cube_guide():
	var cube_mesh = MeshInstance3D.new()
	add_child(cube_mesh)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	
	var half = cube_size / 2
	var corners = [
		Vector3(-half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z)
	]
	
	var edges = [
		[0,1], [1,2], [2,3], [3,0],
		[4,5], [5,6], [6,7], [7,4],
		[0,4], [1,5], [2,6], [3,7]
	]
	
	for edge in edges:
		surface_tool.add_vertex(corners[edge[0]])
		surface_tool.add_vertex(corners[edge[1]])
	
	cube_mesh.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_mesh.material_override = material

func draw_attraction_points():
	# Draw active points
	for point in active_attraction_points:
		var sphere = MeshInstance3D.new()
		add_child(sphere)
		
		var mesh = SphereMesh.new()
		mesh.radius = 0.05
		mesh.height = mesh.radius
		sphere.mesh = mesh
		sphere.position = point
		
		var material = StandardMaterial3D.new()
		material.albedo_color = attraction_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere.material_override = material
	
	# Draw colonized points (darker)
	var colonized_count = attraction_points.size() - active_attraction_points.size()
	if colonized_count > 0:
		var sample_size = min(colonized_count, 50)
		for i in range(sample_size):
			var idx = randi() % attraction_points.size()
			if attraction_points[idx] not in active_attraction_points:
				var sphere = MeshInstance3D.new()
				add_child(sphere)
				
				var mesh = SphereMesh.new()
				mesh.radius = 0.03
				mesh.height = mesh.radius
				sphere.mesh = mesh
				sphere.position = attraction_points[idx]
				
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(0.2, 0.2, 0.2, 0.3)
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				sphere.material_override = material

func draw_branches():
	for node in all_nodes:
		if node.parent != null:
			create_branch_segment(node)

func create_branch_segment(node: GrowthNode):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var mesh = create_cylinder_between(
		node.parent.position,
		node.position,
		node.parent.thickness * 0.1,
		node.thickness * 0.1
	)
	
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	# Color based on depth/distance from root
	var depth_factor = clamp(node.position.distance_to(growth_origin) / 10.0, 0.0, 1.0)
	material.albedo_color = branch_color.lerp(Color(0.3, 0.6, 0.3), depth_factor)
	material.roughness = 0.8
	mesh_instance.material_override = material

func create_cylinder_between(start: Vector3, end: Vector3, start_radius: float, end_radius: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	var segments = 6
	
	# Create perpendicular vectors
	var tangent = Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right = direction.cross(tangent).normalized()
	var up = right.cross(direction).normalized()
	
	# Create cylinder
	for i in range(segments + 1):
		var angle = float(i) / segments * TAU
		var perpendicular = right * cos(angle) + up * sin(angle)
		
		var start_point = start + perpendicular * start_radius
		var end_point = end + perpendicular * end_radius
		
		if i < segments:
			var next_angle = float(i + 1) / segments * TAU
			var next_perp = right * cos(next_angle) + up * sin(next_angle)
			
			var start_next = start + next_perp * start_radius
			var end_next = end + next_perp * end_radius
			
			# Create quad
			surface_tool.add_vertex(start_point)
			surface_tool.add_vertex(end_point)
			surface_tool.add_vertex(start_next)
			
			surface_tool.add_vertex(start_next)
			surface_tool.add_vertex(end_point)
			surface_tool.add_vertex(end_next)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func clear_structure():
	attraction_points.clear()
	active_attraction_points.clear()
	root_nodes.clear()
	leaf_nodes.clear()
	all_nodes.clear()
	clear_visualization()

func clear_visualization():
	for child in get_children():
		child.queue_free()
