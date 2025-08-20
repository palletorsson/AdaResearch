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
@export var animate_sweepline: bool = true

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
@export var territory_colors: Array[Color] = [
	Color(0.8, 0.3, 0.3, 0.3), Color(0.3, 0.8, 0.3, 0.3), Color(0.3, 0.3, 0.8, 0.3),
	Color(0.8, 0.8, 0.3, 0.3), Color(0.8, 0.3, 0.8, 0.3), Color(0.3, 0.8, 0.8, 0.3)
]

# Voronoi diagram data structures
class VoronoiSite:
	var position: Vector2
	var index: int
	var territory_area: float = 0.0
	var mesh_instance: MeshInstance3D = null
	
	func _init(pos: Vector2, idx: int):
		position = pos
		index = idx

class VoronoiEdge:
	var start: Vector2
	var end: Vector2
	var site_left: VoronoiSite
	var site_right: VoronoiSite
	var is_infinite: bool = false
	var mesh_instance: MeshInstance3D = null

class VoronoiCell:
	var site: VoronoiSite
	var vertices: Array[Vector2] = []
	var edges: Array[VoronoiEdge] = []
	var area: float = 0.0
	var mesh_instance: MeshInstance3D = null

# Fortune's algorithm data structures
class BeachLineArc:
	var site: VoronoiSite
	var left_edge: VoronoiEdge = null
	var right_edge: VoronoiEdge = null

class CircleEvent:
	var center: Vector2
	var radius: float
	var y_coord: float
	var arc: BeachLineArc
	var is_valid: bool = true

# Algorithm state
var sites: Array[VoronoiSite] = []
var edges: Array[VoronoiEdge] = []
var cells: Array[VoronoiCell] = []
var beach_line: Array[BeachLineArc] = []
var event_queue: Array = []
var sweepline_y: float = 0.0

# Visualization elements
var site_meshes: Array = []
var edge_meshes: Array = []
var cell_meshes: Array = []
var delaunay_meshes: Array = []
var ui_display: CanvasLayer
var animation_timer: Timer

# Performance metrics
var algorithm_steps: int = 0
var construction_time: float = 0.0
var spatial_equity_index: float = 0.0

func _init():
	name = "Voronoi_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	
	if auto_generate_sites:
		generate_random_sites()
	
	if use_fortune_algorithm:
		call_deferred("start_fortune_algorithm")
	else:
		call_deferred("construct_voronoi_naive")

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
	
	for i in range(30):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup animation timer"""
	animation_timer = Timer.new()
	animation_timer.wait_time = 1.0 / sweepline_speed
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	add_child(animation_timer)

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

func start_fortune_algorithm():
	"""Start Fortune's sweepline algorithm"""
	print("Starting Fortune's sweepline algorithm...")
	var start_time = Time.get_ticks_msec()
	algorithm_steps = 0
	
	# Sort sites by y-coordinate
	sites.sort_custom(_compare_sites_y)
	
	# Initialize sweepline
	sweepline_y = diagram_bounds.y/2 + 2
	beach_line.clear()
	event_queue.clear()
	edges.clear()
	
	# Add site events to queue
	for site in sites:
		event_queue.append({"type": "site", "site": site, "y": site.position.y})
	
	if animate_sweepline:
		animation_timer.start()
	else:
		process_complete_algorithm()
	
	construction_time = Time.get_ticks_msec() - start_time

func _compare_sites_y(a: VoronoiSite, b: VoronoiSite) -> bool:
	return a.position.y > b.position.y

func _on_animation_timer_timeout():
	"""Process one step of Fortune's algorithm"""
	if event_queue.is_empty():
		animation_timer.stop()
		finalize_voronoi_diagram()
		return
	
	var next_event = event_queue[0]
	event_queue.remove_at(0)
	sweepline_y = next_event.y
	
	match next_event.type:
		"site":
			handle_site_event(next_event.site)
		"circle":
			if next_event.is_valid:
				handle_circle_event(next_event)
	
	algorithm_steps += 1
	update_sweepline_visualization()
	update_ui()

func handle_site_event(site: VoronoiSite):
	"""Handle site event in Fortune's algorithm"""
	if beach_line.is_empty():
		# First site
		var arc = BeachLineArc.new()
		arc.site = site
		beach_line.append(arc)
	else:
		# Find arc above new site
		var arc_index = find_arc_above_point(site.position)
		if arc_index >= 0:
			split_arc(arc_index, site)

func find_arc_above_point(point: Vector2) -> int:
	"""Find beach line arc above given point"""
	# Simplified arc finding for demonstration
	for i in range(beach_line.size()):
		var arc = beach_line[i]
		if abs(arc.site.position.x - point.x) < 1.0:
			return i
	return 0 if beach_line.size() > 0 else -1

func split_arc(arc_index: int, new_site: VoronoiSite):
	"""Split beach line arc with new site"""
	var old_arc = beach_line[arc_index]
	
	# Create new arcs
	var left_arc = BeachLineArc.new()
	left_arc.site = old_arc.site
	
	var middle_arc = BeachLineArc.new()
	middle_arc.site = new_site
	
	var right_arc = BeachLineArc.new()
	right_arc.site = old_arc.site
	
	# Create new edges
	var left_edge = VoronoiEdge.new()
	left_edge.site_left = old_arc.site
	left_edge.site_right = new_site
	
	var right_edge = VoronoiEdge.new()
	right_edge.site_left = new_site
	right_edge.site_right = old_arc.site
	
	edges.append(left_edge)
	edges.append(right_edge)
	
	# Update beach line
	beach_line[arc_index] = left_arc
	beach_line.insert(arc_index + 1, middle_arc)
	beach_line.insert(arc_index + 2, right_arc)
	
	# Check for circle events
	check_circle_events(arc_index, arc_index + 2)

func handle_circle_event(event: Dictionary):
	"""Handle circle event in Fortune's algorithm"""
	var arc = event.arc
	var arc_index = beach_line.find(arc)
	
	if arc_index < 0:
		return
	
	# Remove arc from beach line
	beach_line.remove_at(arc_index)
	
	# Create vertex at circle center
	var vertex = event.center
	
	# Update adjacent edges
	if arc_index > 0 and arc_index < beach_line.size():
		var new_edge = VoronoiEdge.new()
		new_edge.start = vertex
		new_edge.site_left = beach_line[arc_index - 1].site
		new_edge.site_right = beach_line[arc_index].site
		edges.append(new_edge)

func check_circle_events(left_arc_index: int, right_arc_index: int):
	"""Check for potential circle events"""
	if left_arc_index < 0 or right_arc_index >= beach_line.size():
		return
	
	# Simplified circle event detection
	var left_arc = beach_line[left_arc_index]
	var right_arc = beach_line[right_arc_index]
	
	if left_arc_index + 1 < beach_line.size():
		var middle_arc = beach_line[left_arc_index + 1]
		var circle_center = calculate_circumcenter(
			left_arc.site.position,
			middle_arc.site.position,
			right_arc.site.position
		)
		
		if circle_center != Vector2.INF:
			var radius = circle_center.distance_to(left_arc.site.position)
			var event_y = circle_center.y - radius
			
			var circle_event = {
				"type": "circle",
				"center": circle_center,
				"radius": radius,
				"y": event_y,
				"arc": middle_arc,
				"is_valid": true
			}
			
			# Insert into event queue (sorted)
			insert_event_sorted(circle_event)

func calculate_circumcenter(p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	"""Calculate circumcenter of three points"""
	var d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
	
	if abs(d) < precision_epsilon:
		return Vector2.INF
	
	var ux = ((p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) + 
			  (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) + 
			  (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y)) / d
	
	var uy = ((p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) + 
			  (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) + 
			  (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x)) / d
	
	return Vector2(ux, uy)

func insert_event_sorted(event: Dictionary):
	"""Insert event into sorted queue"""
	for i in range(event_queue.size()):
		if event.y > event_queue[i].y:
			event_queue.insert(i, event)
			return
	event_queue.append(event)

func process_complete_algorithm():
	"""Process complete Fortune's algorithm without animation"""
	while not event_queue.is_empty():
		var next_event = event_queue[0]
		event_queue.remove_at(0)
		sweepline_y = next_event.y
		
		match next_event.type:
			"site":
				handle_site_event(next_event.site)
			"circle":
				if next_event.is_valid:
					handle_circle_event(next_event)
		
		algorithm_steps += 1
	
	finalize_voronoi_diagram()

func finalize_voronoi_diagram():
	"""Finalize Voronoi diagram construction"""
	clip_edges_to_bounds()
	construct_cells()
	calculate_spatial_metrics()
	
	update_visualization()
	update_ui()
	
	print("Fortune's algorithm completed in ", algorithm_steps, " steps")

func clip_edges_to_bounds():
	"""Clip infinite edges to diagram bounds"""
	var bounds = Rect2(-diagram_bounds/2, diagram_bounds)
	
	for edge in edges:
		if edge.is_infinite or edge.start == Vector2.INF or edge.end == Vector2.INF:
			# Calculate intersection with bounds
			clip_edge_to_rectangle(edge, bounds)

func clip_edge_to_rectangle(edge: VoronoiEdge, bounds: Rect2):
	"""Clip edge to rectangle bounds"""
	# Simplified edge clipping
	if edge.start == Vector2.INF:
		edge.start = Vector2(bounds.position.x, bounds.position.y)
	if edge.end == Vector2.INF:
		edge.end = Vector2(bounds.position.x + bounds.size.x, bounds.position.y + bounds.size.y)
	
	# Ensure edge points are within bounds
	edge.start.x = clamp(edge.start.x, bounds.position.x, bounds.position.x + bounds.size.x)
	edge.start.y = clamp(edge.start.y, bounds.position.y, bounds.position.y + bounds.size.y)
	edge.end.x = clamp(edge.end.x, bounds.position.x, bounds.position.x + bounds.size.x)
	edge.end.y = clamp(edge.end.y, bounds.position.y, bounds.position.y + bounds.size.y)

func construct_cells():
	"""Construct Voronoi cells from edges"""
	cells.clear()
	
	for site in sites:
		var cell = VoronoiCell.new()
		cell.site = site
		
		# Find edges belonging to this cell
		for edge in edges:
			if edge.site_left == site or edge.site_right == site:
				cell.edges.append(edge)
		
		# Calculate cell area (simplified)
		cell.area = calculate_cell_area(cell)
		site.territory_area = cell.area
		
		cells.append(cell)

func calculate_cell_area(cell: VoronoiCell) -> float:
	"""Calculate area of Voronoi cell"""
	# Simplified area calculation
	var bounds = diagram_bounds
	return (bounds.x * bounds.y) / sites.size()  # Average area approximation

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

func construct_voronoi_naive():
	"""Construct Voronoi diagram using naive approach"""
	print("Constructing Voronoi diagram using naive approach...")
	var start_time = Time.get_ticks_msec()
	
	# Generate grid points and assign to nearest site
	var resolution = 100
	var bounds = diagram_bounds
	edges.clear()
	
	for x in range(resolution):
		for y in range(resolution):
			var point = Vector2(
				-bounds.x/2 + (x * bounds.x / resolution),
				-bounds.y/2 + (y * bounds.y / resolution)
			)
			
			var nearest_site = find_nearest_site(point)
			# Process point for edge detection...
	
	construction_time = Time.get_ticks_msec() - start_time
	finalize_voronoi_diagram()

func find_nearest_site(point: Vector2) -> VoronoiSite:
	"""Find nearest site to given point"""
	var nearest = sites[0]
	var min_distance = point.distance_squared_to(nearest.position)
	
	for site in sites:
		var distance = point.distance_squared_to(site.position)
		if distance < min_distance:
			min_distance = distance
			nearest = site
	
	return nearest

func visualize_sites():
	"""Create 3D visualization of sites"""
	clear_site_meshes()
	
	for site in sites:
		var mesh_instance = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = site_radius
		mesh_instance.mesh = mesh
		
		mesh_instance.position = Vector3(site.position.x, 0, site.position.y)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = site_color
		material.emission_enabled = true
		material.emission = site_color * 0.4
		mesh_instance.material_override = material
		
		add_child(mesh_instance)
		site_meshes.append(mesh_instance)
		site.mesh_instance = mesh_instance

func update_visualization():
	"""Update complete Voronoi visualization"""
	clear_all_meshes()
	visualize_sites()
	visualize_edges()
	
	if show_delaunay_triangulation:
		visualize_delaunay()
	
	if show_territory_sizes:
		visualize_territories()

func visualize_edges():
	"""Visualize Voronoi edges"""
	for edge in edges:
		if edge.start == Vector2.INF or edge.end == Vector2.INF:
			continue
		
		var mesh_instance = create_edge_mesh(edge.start, edge.end, voronoi_edge_color)
		add_child(mesh_instance)
		edge_meshes.append(mesh_instance)
		edge.mesh_instance = mesh_instance

func visualize_delaunay():
	"""Visualize Delaunay triangulation (dual of Voronoi)"""
	# Create Delaunay edges between adjacent Voronoi sites
	for edge in edges:
		if edge.site_left and edge.site_right:
			var mesh_instance = create_edge_mesh(
				edge.site_left.position,
				edge.site_right.position,
				delaunay_edge_color
			)
			add_child(mesh_instance)
			delaunay_meshes.append(mesh_instance)

func visualize_territories():
	"""Visualize territorial areas"""
	for i in range(cells.size()):
		var cell = cells[i]
		var color = territory_colors[i % territory_colors.size()]
		
		# Create territory visualization
		var mesh_instance = create_territory_mesh(cell, color)
		if mesh_instance:
			add_child(mesh_instance)
			cell_meshes.append(mesh_instance)
			cell.mesh_instance = mesh_instance

func create_edge_mesh(start: Vector2, end: Vector2, color: Color) -> MeshInstance3D:
	"""Create mesh for Voronoi edge"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	mesh.top_radius = edge_thickness
	mesh.bottom_radius = edge_thickness
	mesh.height = start.distance_to(end)
	
	mesh_instance.mesh = mesh
	var mid_point = (start + end) / 2.0
	mesh_instance.position = Vector3(mid_point.x, 0, mid_point.y)
	
	var direction = Vector3(end.x - start.x, 0, end.y - start.y).normalized()
	if direction != Vector3.ZERO:
		mesh_instance.look_at(mesh_instance.position + direction, Vector3.UP)
		mesh_instance.rotate_x(PI/2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_territory_mesh(cell: VoronoiCell, color: Color) -> MeshInstance3D:
	"""Create mesh for territory visualization"""
	# Simplified territory visualization as plane
	var mesh_instance = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(1, 1)
	
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(cell.site.position.x, -0.1, cell.site.position.y)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	return mesh_instance

func update_sweepline_visualization():
	"""Update sweepline visualization during animation"""
	# Clear previous sweepline
	for child in get_children():
		if child.name == "Sweepline":
			child.queue_free()
	
	# Create new sweepline
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Sweepline"
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(diagram_bounds.x, 0.1)
	
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0, 0, sweepline_y)
	mesh_instance.rotate_x(PI/2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = sweepline_color
	material.emission_enabled = true
	material.emission = sweepline_color * 0.5
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func clear_all_meshes():
	"""Clear all visualization meshes"""
	clear_site_meshes()
	clear_edge_meshes()
	clear_cell_meshes()
	clear_delaunay_meshes()

func clear_site_meshes():
	for mesh in site_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	site_meshes.clear()

func clear_edge_meshes():
	for mesh in edge_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	edge_meshes.clear()

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
	for i in range(30):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 30:
		labels[0].text = "🗺️ Voronoi Diagrams - Spatial Justice & Territory"
		labels[1].text = "Sites: " + str(sites.size())
		labels[2].text = "Edges: " + str(edges.size())
		labels[3].text = "Cells: " + str(cells.size())
		labels[4].text = ""
		labels[5].text = "Algorithm: " + ("Fortune's" if use_fortune_algorithm else "Naive")
		labels[6].text = "Steps: " + str(algorithm_steps)
		labels[7].text = "Construction Time: " + str(construction_time) + " ms"
		labels[8].text = "Sweepline Y: " + str(snapped(sweepline_y, 0.01))
		labels[9].text = ""
		labels[10].text = "Spatial Analysis:"
		labels[11].text = "Total Area: " + str(snapped(diagram_bounds.x * diagram_bounds.y, 0.1))
		labels[12].text = "Avg Territory: " + str(snapped(get_average_territory_size(), 0.1))
		labels[13].text = "Largest Territory: " + str(snapped(get_largest_territory_size(), 0.1))
		labels[14].text = "Spatial Equity: " + str(snapped(spatial_equity_index * 100, 1)) + "%"
		labels[15].text = ""
		labels[16].text = "Territorial Politics:"
		labels[17].text = "Border Length: " + str(snapped(get_total_border_length(), 1))
		labels[18].text = "Territory Variance: " + str(snapped(get_territory_variance(), 0.1))
		labels[19].text = "Power Concentration: " + get_power_concentration_level()
		labels[20].text = ""
		labels[21].text = "Visualization:"
		labels[22].text = "Delaunay Dual: " + ("ON" if show_delaunay_triangulation else "OFF")
		labels[23].text = "Territory Colors: " + ("ON" if show_territory_sizes else "OFF")
		labels[24].text = "Sweepline: " + ("ON" if animate_sweepline else "OFF")
		labels[25].text = ""
		labels[26].text = "Controls:"
		labels[27].text = "SPACE - Generate new sites, R - Reset"
		labels[28].text = "F - Toggle Fortune's algorithm"
		labels[29].text = "🏳️‍🌈 Explores spatial justice & territorial equity"

func get_average_territory_size() -> float:
	if sites.is_empty():
		return 0.0
	return (diagram_bounds.x * diagram_bounds.y) / sites.size()

func get_largest_territory_size() -> float:
	var largest = 0.0
	for site in sites:
		largest = max(largest, site.territory_area)
	return largest

func get_total_border_length() -> float:
	var total = 0.0
	for edge in edges:
		if edge.start != Vector2.INF and edge.end != Vector2.INF:
			total += edge.start.distance_to(edge.end)
	return total

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
				if use_fortune_algorithm:
					start_fortune_algorithm()
				else:
					construct_voronoi_naive()
			KEY_R:
				reset_diagram()
			KEY_F:
				use_fortune_algorithm = not use_fortune_algorithm
				print("Fortune's algorithm: ", use_fortune_algorithm)
			KEY_D:
				show_delaunay_triangulation = not show_delaunay_triangulation
				update_visualization()
			KEY_T:
				show_territory_sizes = not show_territory_sizes
				update_visualization()
			KEY_1, KEY_2, KEY_3, KEY_4:
				var new_count = [5, 10, 15, 25][event.keycode - KEY_1]
				site_count = new_count
				generate_random_sites()
				if use_fortune_algorithm:
					start_fortune_algorithm()

func reset_diagram():
	"""Reset Voronoi diagram"""
	animation_timer.stop()
	clear_all_meshes()
	sites.clear()
	edges.clear()
	cells.clear()
	beach_line.clear()
	event_queue.clear()
	algorithm_steps = 0
	construction_time = 0.0
	spatial_equity_index = 0.0
	update_ui()
	print("Voronoi diagram reset")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive Voronoi algorithm information"""
	return {
		"name": "Voronoi Diagrams",
		"description": "Spatial partitioning with Fortune's sweepline algorithm",
		"properties": {
			"sites": sites.size(),
			"edges": edges.size(),
			"cells": cells.size(),
			"algorithm": "Fortune's" if use_fortune_algorithm else "Naive"
		},
		"performance": {
			"construction_time_ms": construction_time,
			"algorithm_steps": algorithm_steps,
			"spatial_equity_index": spatial_equity_index
		},
		"complexity": {
			"time": "O(n log n)" if use_fortune_algorithm else "O(n²)",
			"space": "O(n)"
		}
	} 
