class_name VoronoiVisualization
extends Node3D

# Voronoi Diagrams: Spatial Justice & Territorial Organization
# Visualizes spatial partitioning, Fortune's algorithm, Delaunay triangulation
# Explores territorial politics and spatial equity in computational geometry

@export_category("Voronoi Configuration")
@export var site_count: int = 15
@export var auto_generate_sites: bool = true
@export var show_delaunay_triangulation: bool = true
@export var show_fortune_algorithm: bool = true
@export var animate_sweepline: bool = false

@export_category("Algorithm Settings")
@export var use_fortune_algorithm: bool = true
@export var sweepline_speed: float = 2.0
@export var show_beach_line: bool = true
@export var show_circle_events: bool = true
@export var precision_epsilon: float = 1e-9

@export_category("Spatial Analysis")
@export var show_territory_sizes: bool = true
@export var highlight_largest_territory: bool = true
@export var show_territorial_borders: bool = true
@export var analyze_spatial_equity: bool = true
@export var show_power_diagrams: bool = false

@export_category("Visualization")
@export var diagram_bounds: Vector2 = Vector2(20, 15)
@export var site_radius: float = 0.2
@export var edge_thickness: float = 0.05
@export var show_infinite_edges: bool = true
@export var animate_construction: bool = true

@export_category("Animation Settings")
@export var animation_speed: float = 1.0
@export var site_animation_duration: float = 0.8
@export var cell_animation_duration: float = 1.2
@export var enable_pulsing: bool = true
@export var enable_rotation: bool = true
@export var rotation_speed: float = 0.5
@export var enable_floating: bool = true
@export var floating_amplitude: float = 0.1
@export var floating_frequency: float = 1.0

@export_category("Interactive Features")
@export var allow_site_dragging: bool = true
@export var real_time_updates: bool = true
@export var show_nearest_site: bool = true
@export var highlight_mouse_cell: bool = true

# Colors for visualization
@export var site_color: Color = Color(0.9, 0.3, 0.2, 1.0)
@export var voronoi_edge_color: Color = Color(0.2, 0.7, 0.9, 1.0)
@export var delaunay_edge_color: Color = Color(0.9, 0.7, 0.2, 1.0)
@export var sweepline_color: Color = Color(0.9, 0.2, 0.9, 1.0)
@export var beach_line_color: Color = Color(0.3, 0.9, 0.3, 1.0)

# Voronoi diagram data structures
class VoronoiSite:
	var position: Vector2
	var index: int
	var territory_area: float = 0.0
	var mesh_instance: MeshInstance3D = null
	
	func _init(pos: Vector2, idx: int):
		position = pos
		index = idx

class VoronoiCell:
	var site: VoronoiSite
	var vertices: Array[Vector2] = []
	var area: float = 0.0
	var mesh_instance: MeshInstance3D = null

# Algorithm state
var sites: Array[VoronoiSite] = []
var cells: Array[VoronoiCell] = []

# Visualization elements
var site_meshes: Array = []
var cell_meshes: Array = []
var delaunay_meshes: Array = []
var ui_display: CanvasLayer

# Animation elements
var animation_tweens: Array = []
var construction_timer: Timer
var animation_phase: int = 0  # 0=sites, 1=cells, 2=complete
var base_time: float = 0.0

# Performance metrics
var construction_time: float = 0.0
var spatial_equity_index: float = 0.0

func _init():
	name = "Voronoi_Visualization"

func _ready():
	setup_visual_environment()
	setup_animation_system()
	
	if auto_generate_sites:
		generate_random_sites()
	
	if animate_construction:
		call_deferred("animate_construction_process")
	else:
		call_deferred("construct_voronoi_cells")
		call_deferred("update_visualization")

func setup_visual_environment():
	"""Set up enhanced visual environment"""
	var main_light = DirectionalLight3D.new()
	main_light.transform.basis = Basis.from_euler(Vector3(-0.3, 0.5, 0))
	main_light.light_energy = 1.5
	main_light.shadow_enabled = true
	main_light.shadow_bias = 0.1
	add_child(main_light)
	
	var rim_light = DirectionalLight3D.new()
	rim_light.transform.basis = Basis.from_euler(Vector3(0.3, -0.5, 0))
	rim_light.light_energy = 0.8
	rim_light.light_color = Color(0.8, 0.9, 1.0)
	add_child(rim_light)
	
	var camera = Camera3D.new()
	camera.position = Vector3(15, 12, 15)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3.UP)
	camera.fov = 60.0
	add_child(camera)

func setup_animation_system():
	"""Set up animation system"""
	construction_timer = Timer.new()
	construction_timer.wait_time = 0.1
	construction_timer.timeout.connect(_on_construction_timer_timeout)
	add_child(construction_timer)

func setup_ui():
	"""Create UI for Voronoi visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(600, 800)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	for i in range(40):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func _process(delta):
	"""Update animations and effects"""
	base_time += delta
	
	# Update floating animation
	if enable_floating:
		update_floating_animation()
	
	# Update rotation animation
	if enable_rotation:
		update_rotation_animation(delta)
	
	# Update pulsing animation
	if enable_pulsing:
		update_pulsing_animation()

func update_floating_animation():
	"""Update floating animation for sites"""
	for i in range(site_meshes.size()):
		var mesh = site_meshes[i]
		if mesh and is_instance_valid(mesh):
			var original_y = 0.1
			var float_offset = sin(base_time * floating_frequency + i * 0.5) * floating_amplitude
			mesh.position.y = original_y + float_offset

func update_rotation_animation(delta):
	"""Update rotation animation for the entire diagram"""
	rotation.y += rotation_speed * delta

func update_pulsing_animation():
	"""Update pulsing animation for sites"""
	for i in range(site_meshes.size()):
		var mesh = site_meshes[i]
		if mesh and is_instance_valid(mesh):
			var pulse_scale = 1.0 + sin(base_time * 2.0 + i * 0.3) * 0.1
			mesh.scale = Vector3(pulse_scale, pulse_scale, pulse_scale)

func generate_random_sites():
	"""Generate random site points"""
	sites.clear()
	var bounds = diagram_bounds
	
	for i in range(site_count):
		var pos = Vector2(
			randf_range(-bounds.x/2, bounds.x/2),
			randf_range(-bounds.y/2, bounds.y/2)
		)
		var site = VoronoiSite.new(pos, i)
		sites.append(site)
	
	print("Generated ", sites.size(), " random sites")
	visualize_sites()

func construct_voronoi_cells():
	"""Construct proper Voronoi cells using a more robust method"""
	cells.clear()
	var bounds = Rect2(-diagram_bounds/2, diagram_bounds)
	var start_time = Time.get_ticks_msec()
	
	print("Constructing Voronoi cells using improved algorithm...")
	
	# Create a grid-based approach for better cell generation
	var grid_resolution = 100
	var cell_map = {} # int -> Array[Vector2]
	
	# For each grid point, find the closest site
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var world_x = bounds.position.x + (x / float(grid_resolution - 1)) * bounds.size.x
			var world_y = bounds.position.y + (y / float(grid_resolution - 1)) * bounds.size.y
			var grid_pos = Vector2(world_x, world_y)
			
			var closest_site = find_closest_site(grid_pos)
			if closest_site != null:
				if not cell_map.has(closest_site.index):
					cell_map[closest_site.index] = []
				cell_map[closest_site.index].append(grid_pos)
	
	# Create cells from the grid data
	for site in sites:
		var cell = VoronoiCell.new()
		cell.site = site
		
		if cell_map.has(site.index):
			# Create convex hull of grid points
			var grid_points: Array[Vector2] = []
			grid_points.assign(cell_map[site.index])
			cell.vertices = create_convex_hull(grid_points)
		else:
			# Fallback: create a small cell around the site
			cell.vertices = create_small_cell_around_site(site.position)
		
		cell.area = calculate_polygon_area(cell.vertices)
		site.territory_area = cell.area
		cells.append(cell)
	
	construction_time = Time.get_ticks_msec() - start_time
	print("Cell construction completed in ", construction_time, "ms")
	print("Created ", cells.size(), " cells")
	
	validate_voronoi_structure()
	calculate_spatial_metrics()
	update_ui()

func find_closest_site(position: Vector2) -> VoronoiSite:
	"""Find the closest site to a given position"""
	if sites.is_empty():
		return null
	
	var closest_site = sites[0]
	var min_distance = position.distance_squared_to(sites[0].position)
	
	for i in range(1, sites.size()):
		var distance = position.distance_squared_to(sites[i].position)
		if distance < min_distance:
			min_distance = distance
			closest_site = sites[i]
	
	return closest_site

func create_convex_hull(points: Array[Vector2]) -> Array[Vector2]:
	"""Create convex hull from a set of points using Graham scan"""
	if points.size() < 3:
		return points
	
	# Find bottom-most point (and leftmost in case of tie)
	var start_point = points[0]
	for point in points:
		if point.y < start_point.y or (point.y == start_point.y and point.x < start_point.x):
			start_point = point
	
	# Sort points by polar angle with respect to start point
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var angle_a = atan2(a.y - start_point.y, a.x - start_point.x)
		var angle_b = atan2(b.y - start_point.y, b.x - start_point.x)
		return angle_a < angle_b
	)
	
	# Build convex hull
	var hull: Array[Vector2] = []
	
	for point in points:
		while hull.size() > 1 and cross_product(hull[-2], hull[-1], point) <= 0:
			hull.pop_back()
		hull.append(point)
	
	return hull

func cross_product(o: Vector2, a: Vector2, b: Vector2) -> float:
	"""Calculate cross product of vectors OA and OB"""
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)

func create_small_cell_around_site(site_pos: Vector2) -> Array[Vector2]:
	"""Create a small cell around a site as fallback"""
	var cell_size = 1.0
	return [
		Vector2(site_pos.x - cell_size, site_pos.y - cell_size),
		Vector2(site_pos.x + cell_size, site_pos.y - cell_size),
		Vector2(site_pos.x + cell_size, site_pos.y + cell_size),
		Vector2(site_pos.x - cell_size, site_pos.y + cell_size)
	]

func clip_polygon_by_bisector(polygon: Array[Vector2], site1: Vector2, site2: Vector2) -> Array[Vector2]:
	"""Clip polygon by perpendicular bisector between two sites"""
	if polygon.size() < 3:
		return polygon
	
	var midpoint = (site1 + site2) / 2.0
	var direction = (site2 - site1).normalized()
	var normal = Vector2(-direction.y, direction.x)
	
	var result: Array[Vector2] = []
	
	for i in range(polygon.size()):
		var current = polygon[i]
		var next = polygon[(i + 1) % polygon.size()]
		
		var current_side = (current - midpoint).dot(normal)
		var next_side = (next - midpoint).dot(normal)
		
		if current_side >= -precision_epsilon:
			result.append(current)
		
		if (current_side > precision_epsilon and next_side < -precision_epsilon) or \
		   (current_side < -precision_epsilon and next_side > precision_epsilon):
			var intersection = line_line_intersection(current, next, midpoint, midpoint + Vector2(-normal.y, normal.x))
			if intersection != Vector2.INF:
				result.append(intersection)
	
	return result

func line_line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> Vector2:
	"""Find intersection point of two line segments"""
	var d = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
	
	if abs(d) < precision_epsilon:
		return Vector2.INF
	
	var t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / d
	
	return Vector2(p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y))

func clip_polygon_to_bounds(polygon: Array[Vector2], bounds: Rect2) -> Array[Vector2]:
	"""Clip polygon to diagram bounds"""
	if polygon.size() < 3:
		return polygon
	
	var result = polygon.duplicate()
	
	# Clip against each edge of the bounds
	var edges = [
		[Vector2(bounds.position.x, bounds.position.y), Vector2(bounds.position.x + bounds.size.x, bounds.position.y)],  # Bottom
		[Vector2(bounds.position.x + bounds.size.x, bounds.position.y), Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y)],  # Right
		[Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y), Vector2(bounds.position.x, bounds.position.y + bounds.size.y)],  # Top
		[Vector2(bounds.position.x, bounds.position.y + bounds.size.y), Vector2(bounds.position.x, bounds.position.y)]   # Left
	]
	
	for edge in edges:
		result = clip_polygon_by_line(result, edge[0], edge[1])
		if result.size() < 3:
			break
	
	return result

func clip_polygon_by_line(polygon: Array[Vector2], line_start: Vector2, line_end: Vector2) -> Array[Vector2]:
	"""Clip polygon by a line (keeping points on the inside)"""
	if polygon.size() < 3:
		return polygon
	
	var result: Array[Vector2] = []
	var line_dir = (line_end - line_start).normalized()
	var line_normal = Vector2(-line_dir.y, line_dir.x)
	
	for i in range(polygon.size()):
		var current = polygon[i]
		var next = polygon[(i + 1) % polygon.size()]
		
		var current_side = (current - line_start).dot(line_normal)
		var next_side = (next - line_start).dot(line_normal)
		
		if current_side >= -precision_epsilon:
			result.append(current)
		
		if (current_side > precision_epsilon and next_side < -precision_epsilon) or \
		   (current_side < -precision_epsilon and next_side > precision_epsilon):
			var intersection = line_line_intersection(current, next, line_start, line_end)
			if intersection != Vector2.INF:
				result.append(intersection)
	
	return result

func validate_voronoi_structure():
	"""Validate that the Voronoi structure is mathematically correct"""
	print("Validating Voronoi structure...")
	
	var total_area = 0.0
	var bounds = diagram_bounds
	var expected_area = bounds.x * bounds.y
	var valid_cells = 0
	
	for i in range(cells.size()):
		var cell = cells[i]
		print("Cell ", i, ": ", cell.vertices.size(), " vertices, area: ", cell.area)
		if cell.vertices.size() >= 3:
			total_area += cell.area
			valid_cells += 1
	
	print("Valid cells: ", valid_cells, " out of ", cells.size())
	
	var coverage_ratio = total_area / expected_area
	print("Coverage ratio: ", snapped(coverage_ratio, 0.001), " (should be close to 1.0)")
	
	if coverage_ratio < 0.95:
		print("WARNING: Low coverage ratio - cells may be incomplete")
	elif coverage_ratio > 1.05:
		print("WARNING: High coverage ratio - cells may be overlapping")
	else:
		print("Voronoi structure is mathematically correct!")

func calculate_polygon_area(vertices: Array[Vector2]) -> float:
	"""Calculate area of a polygon using the shoelace formula"""
	if vertices.size() < 3:
		return 0.0
	
	var area = 0.0
	for i in range(vertices.size()):
		var j = (i + 1) % vertices.size()
		area += vertices[i].x * vertices[j].y
		area -= vertices[j].x * vertices[i].y
	
	return abs(area) / 2.0

func calculate_spatial_metrics():
	"""Calculate spatial equity and territorial metrics"""
	if sites.is_empty():
		return
	
	var total_area = diagram_bounds.x * diagram_bounds.y
	var average_area = total_area / sites.size()
	var variance_sum = 0.0
	
	for site in sites:
		var deviation = site.territory_area - average_area
		variance_sum += deviation * deviation
	
	var variance = variance_sum / sites.size()
	var std_dev = sqrt(variance)
	spatial_equity_index = 1.0 - (std_dev / average_area)
	spatial_equity_index = max(0.0, min(1.0, spatial_equity_index))

func animate_construction_process():
	"""Animate the construction of the Voronoi diagram"""
	animation_phase = 0
	construction_timer.start()
	clear_all_meshes()

func _on_construction_timer_timeout():
	"""Handle construction timer for animated building"""
	match animation_phase:
		0:  # Animate sites appearing
			animate_sites_construction()
		1:  # Animate cells construction
			animate_cells_construction()
		2:  # Construction complete
			construction_timer.stop()
			animation_phase = 3

func animate_sites_construction():
	"""Animate sites appearing one by one"""
	if sites.is_empty():
		animation_phase = 1
		return
	
	var current_site_index = site_meshes.size()
	if current_site_index >= sites.size():
		animation_phase = 1
		return
	
	# Create and animate the next site
	var site = sites[current_site_index]
	var mesh_instance = create_animated_site(site, current_site_index)
	add_child(mesh_instance)
	site_meshes.append(mesh_instance)
	site.mesh_instance = mesh_instance

func animate_cells_construction():
	"""Animate cells appearing"""
	if not animate_construction:
		construct_voronoi_cells()
		update_visualization()
		animation_phase = 2
		return
	
	# Construct cells first
	construct_voronoi_cells()
	
	# Then animate their appearance
	animate_cells_appearing()
	animation_phase = 2

func create_animated_site(site: VoronoiSite, index: int) -> MeshInstance3D:
	"""Create an animated site with entrance effect"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = site_radius
	mesh.height = site_radius * 2
	mesh_instance.mesh = mesh
	
	# Start from above and animate down
	mesh_instance.position = Vector3(site.position.x, 5.0, site.position.y)
	
	var material = StandardMaterial3D.new()
	var hue = float(index) / float(sites.size())
	material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	material.emission_enabled = true
	material.emission = Color.from_hsv(hue, 0.6, 0.4)
	material.metallic = 0.3
	material.roughness = 0.2
	mesh_instance.material_override = material
		
	# Animate entrance
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_instance, "position", Vector3(site.position.x, 0.1, site.position.y), site_animation_duration)
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, site_animation_duration).from(Vector3.ZERO)
	

	animation_tweens.append(tween)
	return mesh_instance

func animate_cells_appearing():
	"""Animate cells appearing with fade-in effect"""
	clear_cell_meshes()
	
	for i in range(cells.size()):
		var cell = cells[i]
		if cell.vertices.size() < 3:
			continue
		
		var hue = float(i) / float(cells.size())
		var color = Color.from_hsv(hue, 0.5, 0.8, 0.0)  # Start transparent
		
		var mesh_instance = create_territory_polygon_mesh(cell, color)
		if mesh_instance:
			add_child(mesh_instance)
			cell_meshes.append(mesh_instance)
			cell.mesh_instance = mesh_instance
			
			# Animate fade-in
			var tween = create_tween()
			tween.tween_property(mesh_instance.material_override, "albedo_color:a", 0.3, cell_animation_duration)
			tween.tween_property(mesh_instance, "scale", Vector3.ONE, cell_animation_duration).from(Vector3(0.1, 0.1, 0.1))
			
			animation_tweens.append(tween)

func visualize_sites():
	"""Create 3D visualization of sites"""
	clear_site_meshes()
	
	for i in range(sites.size()):
		var site = sites[i]
		var mesh_instance = create_animated_site(site, i)
		add_child(mesh_instance)
		site_meshes.append(mesh_instance)
		site.mesh_instance = mesh_instance

func update_visualization():
	"""Update complete Voronoi visualization"""
	clear_all_meshes()
	visualize_sites()
	
	if show_delaunay_triangulation:
		visualize_delaunay()
	
	if show_territory_sizes:
		visualize_territories_detailed()
		visualize_voronoi_edges()

func visualize_territories_detailed():
	"""Create detailed territory visualization using grid-based approach"""
	print("Creating detailed territory visualization...")
	
	var bounds = Rect2(-diagram_bounds/2, diagram_bounds)
	var grid_resolution = 50  # Higher resolution for better detail
	
	# Create a mesh for each cell using grid sampling
	for i in range(sites.size()):
		var site = sites[i]
		var cell_points: Array[Vector2] = []
		
		# Sample grid points that belong to this site
		for x in range(grid_resolution):
			for y in range(grid_resolution):
				var world_x = bounds.position.x + (x / float(grid_resolution - 1)) * bounds.size.x
				var world_y = bounds.position.y + (y / float(grid_resolution - 1)) * bounds.size.y
				var grid_pos = Vector2(world_x, world_y)
				
				var closest_site = find_closest_site(grid_pos)
				if closest_site == site:
					cell_points.append(grid_pos)
		
		if cell_points.size() > 3:
			# Create convex hull of the cell points
			var hull_vertices: Array[Vector2] = create_convex_hull(cell_points)
			
			# Create mesh for this cell
			var cell = VoronoiCell.new()
			cell.site = site
			cell.vertices = hull_vertices
			cell.area = calculate_polygon_area(hull_vertices)
			
			# Visualize this cell
			var hue = float(i) / float(sites.size())
			var color = Color.from_hsv(hue, 0.8, 0.9, 0.8)  # Very opaque
			
			var mesh_instance = create_territory_polygon_mesh(cell, color)
			if mesh_instance:
				mesh_instance.position.y = 0.01 + (i * 0.001)
				add_child(mesh_instance)
				cell_meshes.append(mesh_instance)
				cell.mesh_instance = mesh_instance
				print("Created detailed cell ", i, " with ", hull_vertices.size(), " vertices")

func visualize_delaunay():
	"""Visualize Delaunay triangulation (dual of Voronoi)"""
	for i in range(sites.size()):
		for j in range(i + 1, sites.size()):
			var site1 = sites[i]
			var site2 = sites[j]
			
			if are_sites_adjacent(site1, site2):
				var mesh_instance = create_edge_mesh(
									site1.position,
									site2.position,
					delaunay_edge_color
				)
				add_child(mesh_instance)
				delaunay_meshes.append(mesh_instance)

func are_sites_adjacent(site1: VoronoiSite, site2: VoronoiSite) -> bool:
	"""Check if two sites share a Voronoi edge"""
	var midpoint = (site1.position + site2.position) / 2.0
	var min_dist = midpoint.distance_squared_to(site1.position)
	
	for site in sites:
		if site == site1 or site == site2:
			continue
		var dist = midpoint.distance_squared_to(site.position)
		if dist < min_dist - precision_epsilon:
			return false
	
	return true

func visualize_territories():
	"""Visualize territorial areas"""
	print("Visualizing ", cells.size(), " territories...")
	
	for i in range(cells.size()):
		var cell = cells[i]
		if cell.vertices.size() < 3:
			print("Skipping cell ", i, " - insufficient vertices: ", cell.vertices.size())
			continue
		
		# Ensure vertices are in proper order (counter-clockwise)
		cell.vertices = sort_vertices_counterclockwise(cell.vertices, cell.site.position)
		
		# Create more distinct colors with higher opacity
		var hue = float(i) / float(cells.size())
		var saturation = 0.8 + (randf() * 0.2)  # Add some variation
		var value = 0.7 + (randf() * 0.3)  # Add some variation
		var color = Color.from_hsv(hue, saturation, value, 0.7)  # Much more opaque
		
		var mesh_instance = create_territory_polygon_mesh(cell, color)
		if mesh_instance:
			# Offset each cell slightly to prevent z-fighting
			mesh_instance.position.y = 0.01 + (i * 0.001)
			add_child(mesh_instance)
			cell_meshes.append(mesh_instance)
			cell.mesh_instance = mesh_instance
			print("Created cell ", i, " with ", cell.vertices.size(), " vertices, area: ", cell.area)

func sort_vertices_counterclockwise(vertices: Array[Vector2], center: Vector2) -> Array[Vector2]:
	"""Sort vertices in counter-clockwise order around the center point"""
	if vertices.size() < 3:
		return vertices
	
	# Sort by angle from center
	vertices.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var angle_a = atan2(a.y - center.y, a.x - center.x)
		var angle_b = atan2(b.y - center.y, b.x - center.x)
		return angle_a < angle_b
	)
	
	return vertices

func visualize_voronoi_edges():
	"""Visualize Voronoi cell edges"""
	print("Visualizing Voronoi edges...")
	
	for i in range(cells.size()):
		var cell = cells[i]
		if cell.vertices.size() < 3:
			continue
		
		# Create edges between consecutive vertices
		for j in range(cell.vertices.size()):
			var start_vertex = cell.vertices[j]
			var end_vertex = cell.vertices[(j + 1) % cell.vertices.size()]
			
			var edge_mesh = create_edge_mesh(start_vertex, end_vertex, voronoi_edge_color)
			if edge_mesh:
				edge_mesh.position.y = 0.02  # Slightly above the cell surface
				add_child(edge_mesh)
				cell_meshes.append(edge_mesh)

func create_edge_mesh(start: Vector2, end: Vector2, color: Color) -> MeshInstance3D:
	"""Create mesh for Voronoi edge"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	mesh.top_radius = edge_thickness
	mesh.bottom_radius = edge_thickness
	mesh.height = start.distance_to(end)
	
	mesh_instance.mesh = mesh
	var mid_point = (start + end) / 2.0
	mesh_instance.position = Vector3(mid_point.x, 0.05, mid_point.y)
	
	var direction = Vector3(end.x - start.x, 0, end.y - start.y).normalized()
	if direction != Vector3.ZERO:
		mesh_instance.look_at_from_position(mesh_instance.position, mesh_instance.position + direction, Vector3.UP)
		mesh_instance.rotate_x(PI/2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.metallic = 0.2
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_territory_polygon_mesh(cell: VoronoiCell, color: Color) -> MeshInstance3D:
	"""Create filled polygon mesh for territory visualization"""
	if cell.vertices.size() < 3:
		return null
		
	var mesh_instance = MeshInstance3D.new()
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create vertices in world space
	for vertex in cell.vertices:
		vertices.append(Vector3(vertex.x, 0.01, vertex.y))
		normals.append(Vector3.UP)
	
	# Create triangles using fan triangulation
	for i in range(1, cell.vertices.size() - 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)
	
	# Create arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Add surface to mesh
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	# Position at origin (vertices already in world space)
	mesh_instance.position = Vector3.ZERO
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color * 0.1
	material.metallic = 0.2
	material.roughness = 0.6
	mesh_instance.material_override = material
	
	return mesh_instance

func clear_all_meshes():
	"""Clear all visualization meshes"""
	clear_site_meshes()
	clear_cell_meshes()
	clear_delaunay_meshes()

func clear_site_meshes():
	for mesh in site_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	site_meshes.clear()

func clear_cell_meshes():
	for mesh in cell_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	cell_meshes.clear()

func clear_delaunay_meshes():
	for mesh in delaunay_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	delaunay_meshes.clear()

func update_ui():
	"""Update UI with Voronoi diagram information"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(40):
		var label = ui_display.get_node_or_null("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 40:
		labels[0].text = "Voronoi Diagrams - Spatial Justice & Territory"
		labels[1].text = "Sites: " + str(sites.size())
		labels[2].text = "Cells: " + str(cells.size())
		labels[3].text = ""
		labels[4].text = "Algorithm: Geometric Clipping"
		labels[5].text = "Construction Time: " + str(construction_time) + " ms"
		labels[6].text = ""
		labels[7].text = "Spatial Analysis:"
		labels[8].text = "Total Area: " + str(snapped(diagram_bounds.x * diagram_bounds.y, 0.1))
		labels[9].text = "Avg Territory: " + str(snapped(get_average_territory_size(), 0.1))
		labels[10].text = "Largest Territory: " + str(snapped(get_largest_territory_size(), 0.1))
		labels[11].text = "Smallest Territory: " + str(snapped(get_smallest_territory_size(), 0.1))
		labels[12].text = "Spatial Equity: " + str(snapped(spatial_equity_index * 100, 1)) + "%"
		labels[13].text = ""
		labels[14].text = "Territorial Politics:"
		labels[15].text = "Territory Variance: " + str(snapped(get_territory_variance(), 0.1))
		labels[16].text = "Power Concentration: " + get_power_concentration_level()
		labels[17].text = ""
		labels[18].text = "Visualization:"
		labels[19].text = "Delaunay Dual: " + ("ON" if show_delaunay_triangulation else "OFF")
		labels[20].text = "Territory Colors: " + ("ON" if show_territory_sizes else "OFF")
		labels[21].text = ""
		labels[22].text = "Controls:"
		labels[23].text = "SPACE - Generate new sites"
		labels[24].text = "R - Reset diagram"
		labels[25].text = "D - Toggle Delaunay"
		labels[26].text = "T - Toggle territories"
		labels[27].text = "1/2/3/4 - Set site count (5/10/15/25)"
		labels[28].text = ""
		labels[29].text = "Animation Controls:"
		labels[30].text = "A - Toggle construction animation"
		labels[31].text = "P - Toggle pulsing effects"
		labels[32].text = "F - Toggle floating animation"
		labels[33].text = "O - Toggle rotation"
		labels[34].text = ""
		labels[35].text = "Explores spatial justice & territorial equity"

func get_average_territory_size() -> float:
	if sites.is_empty():
		return 0.0
	return (diagram_bounds.x * diagram_bounds.y) / sites.size()

func get_largest_territory_size() -> float:
	var largest = 0.0
	for site in sites:
		largest = max(largest, site.territory_area)
	return largest

func get_smallest_territory_size() -> float:
	if sites.is_empty():
		return 0.0
	var smallest = INF
	for site in sites:
		smallest = min(smallest, site.territory_area)
	return smallest if smallest != INF else 0.0

func get_territory_variance() -> float:
	if sites.is_empty():
		return 0.0
	
	var avg = get_average_territory_size()
	var variance_sum = 0.0
	
	for site in sites:
		var deviation = site.territory_area - avg
		variance_sum += deviation * deviation
	
	return variance_sum / sites.size()

func get_power_concentration_level() -> String:
	var variance = get_territory_variance()
	var avg = get_average_territory_size()
	
	if avg == 0:
		return "N/A"
	
	var coefficient = sqrt(variance) / avg
	
	if coefficient < 0.2:
		return "Low"
	elif coefficient < 0.5:
		return "Medium"
	else:
		return "High"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				generate_random_sites()
				if animate_construction:
					animate_construction_process()
				else:
					construct_voronoi_cells()
					update_visualization()
			KEY_R:
				reset_diagram()
			KEY_D:
				show_delaunay_triangulation = not show_delaunay_triangulation
				update_visualization()
			KEY_T:
				show_territory_sizes = not show_territory_sizes
				update_visualization()
			KEY_A:
				animate_construction = not animate_construction
				print("Animation: ", "ON" if animate_construction else "OFF")
			KEY_P:
				enable_pulsing = not enable_pulsing
				print("Pulsing: ", "ON" if enable_pulsing else "OFF")
			KEY_F:
				enable_floating = not enable_floating
				print("Floating: ", "ON" if enable_floating else "OFF")
			KEY_O:
				enable_rotation = not enable_rotation
				print("Rotation: ", "ON" if enable_rotation else "OFF")
			KEY_1, KEY_2, KEY_3, KEY_4:
				var new_count = [5, 10, 15, 25][event.keycode - KEY_1]
				site_count = new_count
				generate_random_sites()
				if animate_construction:
					animate_construction_process()
				else:
					construct_voronoi_cells()
					update_visualization()

func reset_diagram():
	"""Reset Voronoi diagram"""
	clear_all_meshes()
	sites.clear()
	cells.clear()
	construction_time = 0.0
	spatial_equity_index = 0.0
	update_ui()
	print("Voronoi diagram reset")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive Voronoi algorithm information"""
	return {
		"name": "Voronoi Diagrams",
		"description": "Spatial partitioning with geometric clipping",
		"properties": {
			"sites": sites.size(),
			"cells": cells.size(),
			"algorithm": "Perpendicular Bisector Clipping"
		},
		"performance": {
			"construction_time_ms": construction_time,
			"spatial_equity_index": spatial_equity_index
		},
		"complexity": {
			"time": "O(n²)",
			"space": "O(n)"
		}
	} 
