extends Node3D

# Enhanced K-Means Clustering Algorithm Visualization
# Educational tool with advanced features and interactive controls

@export_category("Algorithm Parameters")
@export var data_point_count: int = 100:
	set(value):
		data_point_count = max(10, min(500, value))
		if is_inside_tree():
			regenerate_data()

@export var cluster_count: int = 4:
	set(value):
		cluster_count = max(2, min(8, value))
		if is_inside_tree():
			restart_clustering()

@export var iteration_speed: float = 1.5:
	set(value):
		iteration_speed = max(0.1, min(5.0, value))

@export var convergence_threshold: float = 0.1

@export_category("Data Generation")
@export var data_space_size: float = 25.0
@export var generate_clustered_data: bool = true:
	set(value):
		generate_clustered_data = value
		if is_inside_tree():
			regenerate_data()

@export var natural_cluster_count: int = 3:
	set(value):
		natural_cluster_count = max(2, min(6, value))
		if is_inside_tree() and generate_clustered_data:
			regenerate_data()

@export var cluster_spread: float = 4.0
@export var noise_points_percentage: float = 0.1

@export_category("Visualization Controls")
@export var show_centroids: bool = true:
	set(value):
		show_centroids = value
		update_centroid_visibility()

@export var show_connections: bool = false:
	set(value):
		show_connections = value
		update_connection_visibility()

@export var show_voronoi_regions: bool = false:
	set(value):
		show_voronoi_regions = value
		update_voronoi_visibility()

@export var animate_clustering: bool = true
@export var show_iteration_stats: bool = true
@export var show_convergence_graph: bool = true
@export var point_size_scale: float = 1.0:
	set(value):
		point_size_scale = max(0.5, min(3.0, value))
		update_point_sizes()

@export_category("Educational Features")
@export var step_by_step_mode: bool = false
@export var highlight_moving_centroids: bool = true
@export var show_distance_calculations: bool = false
@export var pause_on_convergence: bool = true

# Algorithm state
var data_points: Array = []
var centroids: Array = []
var assignments: Array = []
var previous_assignments: Array = []
var iteration: int = 0
var converged: bool = false
var algorithm_timer: float = 0.0
var total_distance: float = 0.0
var distance_history: Array = []
var centroid_movement_history: Array = []

# Visual elements
var point_meshes: Array = []
var centroid_meshes: Array = []
var connection_lines: Array = []
var voronoi_planes: Array = []
var ui_container: Control
var iteration_label: Label
var distance_label: Label
var status_label: Label
var convergence_graph: Panel
var control_panel: VBoxContainer

# Interactive controls
var is_paused: bool = false
var manual_step: bool = false

# Enhanced cluster colors with better contrast
var cluster_colors: Array = [
	Color(1.0, 0.3, 0.3),  # Bright Red
	Color(0.3, 1.0, 0.3),  # Bright Green
	Color(0.3, 0.3, 1.0),  # Bright Blue
	Color(1.0, 1.0, 0.3),  # Bright Yellow
	Color(1.0, 0.3, 1.0),  # Bright Magenta
	Color(0.3, 1.0, 1.0),  # Bright Cyan
	Color(1.0, 0.6, 0.2),  # Orange
	Color(0.7, 0.3, 1.0)   # Purple
]

# Data structures
class DataPoint:
	var position: Vector3
	var cluster_id: int = -1
	var previous_cluster_id: int = -1
	var mesh_instance: MeshInstance3D
	var distance_to_centroid: float = 0.0
	
	func _init(pos: Vector3):
		position = pos

class Centroid:
	var position: Vector3
	var previous_position: Vector3
	var cluster_id: int
	var mesh_instance: MeshInstance3D
	var assigned_points: Array = []
	var movement_distance: float = 0.0
	
	func _init(pos: Vector3, id: int):
		position = pos
		previous_position = pos
		cluster_id = id

func _ready():
	setup_environment()
	setup_ui()
	generate_data()
	initialize_centroids()
	create_visuals()
	update_ui()
	
	if animate_clustering and not step_by_step_mode:
		start_clustering()

func _process(delta):
	if animate_clustering and not converged and not is_paused and not step_by_step_mode:
		algorithm_timer += delta
		if algorithm_timer >= iteration_speed:
			perform_clustering_step()
			algorithm_timer = 0.0
	
	update_ui()
	handle_input()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		if step_by_step_mode or is_paused:
			manual_step = true
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		restart_clustering()
	elif event.is_action_pressed("ui_select"):  # Enter key
		is_paused = !is_paused

func handle_input():
	if manual_step:
		manual_step = false
		if not converged:
			perform_clustering_step()

func setup_environment():
	# Enhanced lighting setup
	var light = DirectionalLight3D.new()
	light.light_energy = 0.8
	light.rotation_degrees = Vector3(-30, 45, 0)
	light.shadow_enabled = true
	add_child(light)
	
	# Additional fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.light_energy = 0.3
	fill_light.rotation_degrees = Vector3(30, -45, 0)
	add_child(fill_light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	# Sky resource - fallback to color background if not available
	if ResourceLoader.exists("res://default_sky.tres"):
		environment.sky = load("res://default_sky.tres")
	else:
		environment.sky = null
	if not environment.sky:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.4, 0.5)
	environment.ambient_light_energy = 0.3
	env.environment = environment
	add_child(env)
	
	# Camera with better positioning
	var camera = Camera3D.new()
	camera.position = Vector3(0, 20, 30)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 65
	add_child(camera)

func setup_ui():
	# Create UI container
	ui_container = Control.new()
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(ui_container)
	add_child(canvas_layer)
	
	# Main stats panel
	var stats_panel = create_stats_panel()
	ui_container.add_child(stats_panel)
	
	# Control panel
	var controls_panel = create_control_panel()
	ui_container.add_child(controls_panel)
	
	# Convergence graph
	if show_convergence_graph:
		convergence_graph = create_convergence_graph()
		ui_container.add_child(convergence_graph)

func create_stats_panel() -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(280, 150)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.3)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(260, 130)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "K-Means Clustering"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	# Stats labels
	iteration_label = Label.new()
	iteration_label.text = "Iteration: 0"
	iteration_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(iteration_label)
	
	distance_label = Label.new()
	distance_label.text = "Total Distance: 0.0"
	distance_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(distance_label)
	
	status_label = Label.new()
	status_label.text = "Status: Initializing"
	status_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(status_label)
	
	var cluster_info = Label.new()
	cluster_info.text = "Clusters: " + str(cluster_count) + " | Points: " + str(data_point_count)
	cluster_info.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(cluster_info)
	
	return panel

func create_control_panel() -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(20, 190)
	panel.size = Vector2(280, 200)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.3)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	control_panel = VBoxContainer.new()
	control_panel.position = Vector2(10, 10)
	control_panel.size = Vector2(260, 180)
	panel.add_child(control_panel)
	
	# Controls title
	var title = Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	control_panel.add_child(title)
	
	# Control buttons
	var restart_btn = Button.new()
	restart_btn.text = "Restart (ESC)"
	restart_btn.pressed.connect(restart_clustering)
	control_panel.add_child(restart_btn)
	
	var pause_btn = Button.new()
	pause_btn.text = "Pause/Resume (ENTER)"
	pause_btn.pressed.connect(func(): is_paused = !is_paused)
	control_panel.add_child(pause_btn)
	
	var step_btn = Button.new()
	step_btn.text = "Step Forward (SPACE)"
	step_btn.pressed.connect(func(): manual_step = true)
	control_panel.add_child(step_btn)
	
	# Toggle switches
	var connections_toggle = CheckBox.new()
	connections_toggle.text = "Show Connections"
	connections_toggle.button_pressed = show_connections
	connections_toggle.toggled.connect(func(pressed): show_connections = pressed)
	control_panel.add_child(connections_toggle)
	
	var voronoi_toggle = CheckBox.new()
	voronoi_toggle.text = "Show Voronoi Regions"
	voronoi_toggle.button_pressed = show_voronoi_regions
	voronoi_toggle.toggled.connect(func(pressed): show_voronoi_regions = pressed)
	control_panel.add_child(voronoi_toggle)
	
	return panel

func create_convergence_graph() -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(get_viewport().get_visible_rect().size.x - 320, 20)
	panel.size = Vector2(300, 200)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.3)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Graph will be drawn in _draw method
	return panel

func generate_data():
	clear_data()
	
	if generate_clustered_data:
		generate_clustered_dataset()
	else:
		generate_random_dataset()
	
	print("Generated ", data_points.size(), " data points")

func generate_clustered_dataset():
	var points_per_cluster = int(data_point_count * (1.0 - noise_points_percentage) / natural_cluster_count)
	
	# Generate natural clusters
	for cluster_idx in range(natural_cluster_count):
		var cluster_center = Vector3(
			randf_range(-data_space_size/3, data_space_size/3),
			randf_range(-3, 3),
			randf_range(-data_space_size/3, data_space_size/3)
		)
		
		for i in range(points_per_cluster):
			var angle = randf() * TAU
			var distance = randf_range(0, cluster_spread)
			var height_offset = randf_range(-cluster_spread/3, cluster_spread/3)
			
			var offset = Vector3(
				cos(angle) * distance,
				height_offset,
				sin(angle) * distance
			)
			
			var point = DataPoint.new(cluster_center + offset)
			data_points.append(point)
	
	# Add noise points
	var noise_count = data_point_count - data_points.size()
	for i in range(noise_count):
		var random_pos = Vector3(
			randf_range(-data_space_size/2, data_space_size/2),
			randf_range(-4, 4),
			randf_range(-data_space_size/2, data_space_size/2)
		)
		var point = DataPoint.new(random_pos)
		data_points.append(point)

func generate_random_dataset():
	for i in range(data_point_count):
		var random_pos = Vector3(
			randf_range(-data_space_size/2, data_space_size/2),
			randf_range(-4, 4),
			randf_range(-data_space_size/2, data_space_size/2)
		)
		var point = DataPoint.new(random_pos)
		data_points.append(point)

func initialize_centroids():
	clear_centroids()
	
	# K-means++ initialization for better initial centroid placement
	if data_points.size() > 0:
		# Choose first centroid randomly
		var first_centroid = Centroid.new(data_points[randi() % data_points.size()].position, 0)
		centroids.append(first_centroid)
		
		# Choose remaining centroids with probability proportional to squared distance
		for i in range(1, cluster_count):
			var distances: Array = []
			var total_distance = 0.0
			
			for point in data_points:
				var min_dist = INF
				for centroid in centroids:
					var dist = point.position.distance_squared_to(centroid.position)
					min_dist = min(min_dist, dist)
				distances.append(min_dist)
				total_distance += min_dist
			
			var random_value = randf() * total_distance
			var cumulative = 0.0
			
			for j in range(distances.size()):
				cumulative += distances[j]
				if cumulative >= random_value:
					var centroid = Centroid.new(data_points[j].position, i)
					centroids.append(centroid)
					break
	
	# Initialize assignments
	assignments.clear()
	previous_assignments.clear()
	for i in range(data_points.size()):
		assignments.append(-1)
		previous_assignments.append(-1)

func create_visuals():
	clear_visuals()
	
	# Create data point visuals
	for point in data_points:
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3 * point_size_scale
		sphere.height = 0.6 * point_size_scale
		mesh_instance.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.8, 0.8)
		material.metallic = 0.3
		material.roughness = 0.7
		mesh_instance.material_override = material
		mesh_instance.position = point.position
		
		point.mesh_instance = mesh_instance
		add_child(mesh_instance)
		point_meshes.append(mesh_instance)
	
	# Create centroid visuals
	for centroid in centroids:
		var mesh_instance = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.8
		cylinder.bottom_radius = 0.8
		cylinder.height = 0.4
		mesh_instance.mesh = cylinder
		
		var material = StandardMaterial3D.new()
		material.albedo_color = cluster_colors[centroid.cluster_id]
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.6
		material.metallic = 0.8
		material.roughness = 0.2
		mesh_instance.material_override = material
		mesh_instance.position = centroid.position
		
		centroid.mesh_instance = mesh_instance
		add_child(mesh_instance)
		centroid_meshes.append(mesh_instance)

func start_clustering():
	iteration = 0
	converged = false
	is_paused = false
	distance_history.clear()
	centroid_movement_history.clear()
	
	print("Starting K-means clustering with ", cluster_count, " clusters")

func perform_clustering_step():
	if converged:
		return
	
	iteration += 1
	
	# Store previous assignments
	previous_assignments = assignments.duplicate()
	
	# Store previous centroid positions
	for centroid in centroids:
		centroid.previous_position = centroid.position
	
	# Assignment step
	total_distance = 0.0
	for i in range(data_points.size()):
		var point = data_points[i]
		var min_distance = INF
		var nearest_cluster = 0
		
		for j in range(centroids.size()):
			var distance = point.position.distance_to(centroids[j].position)
			if distance < min_distance:
				min_distance = distance
				nearest_cluster = j
		
		assignments[i] = nearest_cluster
		point.cluster_id = nearest_cluster
		point.distance_to_centroid = min_distance
		total_distance += min_distance
	
	# Update step
	var total_movement = 0.0
	for i in range(centroids.size()):
		var centroid = centroids[i]
		var sum_pos = Vector3.ZERO
		var count = 0
		centroid.assigned_points.clear()
		
		for j in range(data_points.size()):
			if assignments[j] == i:
				sum_pos += data_points[j].position
				count += 1
				centroid.assigned_points.append(data_points[j])
		
		if count > 0:
			var new_position = sum_pos / count
			centroid.movement_distance = centroid.position.distance_to(new_position)
			total_movement += centroid.movement_distance
			centroid.position = new_position
	
	# Record statistics
	distance_history.append(total_distance)
	centroid_movement_history.append(total_movement)
	
	# Check convergence
	if total_movement < convergence_threshold or iteration >= 50:
		converged = true
		if pause_on_convergence:
			is_paused = true
		print("Converged after ", iteration, " iterations")
	
	# Update visuals
	update_visuals()

func update_visuals():
	# Update point colors and highlight changes
	for i in range(data_points.size()):
		var point = data_points[i]
		var cluster_id = assignments[i]
		var changed = (previous_assignments[i] != cluster_id)
		
		if cluster_id >= 0 and cluster_id < cluster_colors.size():
			var material = point.mesh_instance.material_override
			material.albedo_color = cluster_colors[cluster_id]
			
			if changed and iteration > 1:
				# Highlight recently changed points
				material.emission_enabled = true
				material.emission = Color.WHITE * 0.5
				# Remove highlight after brief period
				create_tween().tween_callback(func(): 
					if material:
						material.emission_enabled = false
				).set_delay(0.3)
			else:
				material.emission_enabled = false
	
	# Update centroid positions with smooth animation
	for centroid in centroids:
		if centroid.mesh_instance:
			var tween = create_tween()
			tween.tween_property(centroid.mesh_instance, "position", centroid.position, 0.5)
			
			# Highlight moving centroids
			if highlight_moving_centroids and centroid.movement_distance > 0.1:
				var material = centroid.mesh_instance.material_override
				var original_emission = material.emission
				material.emission = Color.WHITE
				tween.tween_callback(func(): 
					if material:
						material.emission = original_emission
				).set_delay(0.5)
	
	# Update connections
	if show_connections:
		update_connection_lines()
	
	# Update voronoi regions
	if show_voronoi_regions:
		update_voronoi_regions()

func update_connection_lines():
	clear_connections()
	
	# Limit connections for performance
	var max_connections = min(50, data_points.size())
	for i in range(max_connections):
		var point = data_points[i]
		var cluster_id = assignments[i]
		
		if cluster_id >= 0 and cluster_id < centroids.size():
			var line = create_connection_line(
				point.position, 
				centroids[cluster_id].position, 
				cluster_colors[cluster_id]
			)
			connection_lines.append(line)

func create_connection_line(from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	var line_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.03
	cylinder.height = 1.0
	line_mesh.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	line_mesh.material_override = material
	
	# Position and orient line
	var center = (from + to) / 2
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	
	line_mesh.position = center
	line_mesh.look_at(center + direction, Vector3.UP)
	line_mesh.rotate_object_local(Vector3(1, 0, 0), PI/2)
	line_mesh.scale.y = distance
	
	add_child(line_mesh)
	return line_mesh

func update_voronoi_regions():
	clear_voronoi()
	
	# Create simplified voronoi visualization using planes
	for i in range(centroids.size()):
		var centroid = centroids[i]
		var plane_mesh = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(data_space_size / 2, data_space_size / 2)
		plane_mesh.mesh = plane
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(cluster_colors[i].r, cluster_colors[i].g, cluster_colors[i].b, 0.1)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		plane_mesh.material_override = material
		
		plane_mesh.position = centroid.position
		add_child(plane_mesh)
		voronoi_planes.append(plane_mesh)

func update_ui():
	if not ui_container:
		return
	
	if iteration_label:
		iteration_label.text = "Iteration: " + str(iteration)
	
	if distance_label:
		distance_label.text = "Total Distance: " + str(snapped(total_distance, 0.1))
	
	if status_label:
		var status = ""
		if converged:
			status = "Status: Converged! ✓"
		elif is_paused:
			status = "Status: Paused"
		elif iteration >= 50:
			status = "Status: Max iterations reached"
		else:
			status = "Status: Clustering..."
		status_label.text = status

# Utility functions
func clear_data():
	data_points.clear()

func clear_centroids():
	centroids.clear()

func clear_visuals():
	for mesh in point_meshes:
		if mesh:
			mesh.queue_free()
	point_meshes.clear()
	
	for mesh in centroid_meshes:
		if mesh:
			mesh.queue_free()
	centroid_meshes.clear()
	
	clear_connections()
	clear_voronoi()

func clear_connections():
	for line in connection_lines:
		if line:
			line.queue_free()
	connection_lines.clear()

func clear_voronoi():
	for plane in voronoi_planes:
		if plane:
			plane.queue_free()
	voronoi_planes.clear()

func update_centroid_visibility():
	for mesh in centroid_meshes:
		if mesh:
			mesh.visible = show_centroids

func update_connection_visibility():
	for line in connection_lines:
		if line:
			line.visible = show_connections

func update_voronoi_visibility():
	for plane in voronoi_planes:
		if plane:
			plane.visible = show_voronoi_regions

func update_point_sizes():
	for point in data_points:
		if point.mesh_instance and point.mesh_instance.mesh:
			var sphere = point.mesh_instance.mesh as SphereMesh
			if sphere:
				sphere.radius = 0.3 * point_size_scale
				sphere.height = 0.6 * point_size_scale

func restart_clustering():
	clear_visuals()
	generate_data()
	initialize_centroids()
	create_visuals()
	start_clustering()

func regenerate_data():
	if not is_inside_tree():
		return
	clear_visuals()
	generate_data()
	initialize_centroids()
	create_visuals()
	if animate_clustering:
		start_clustering()

# Educational helper functions
func get_algorithm_explanation() -> String:
	return """
K-Means Clustering Algorithm:

1. Initialize: Place K centroids randomly in the data space
2. Assignment: Assign each data point to the nearest centroid
3. Update: Move each centroid to the center of its assigned points
4. Repeat: Continue steps 2-3 until convergence

Convergence occurs when centroids stop moving significantly
or when point assignments no longer change.

Controls:
- SPACE: Step forward (in step-by-step mode)
- ENTER: Pause/Resume
- ESC: Restart with new random initialization
"""

func get_current_stats() -> Dictionary:
	return {
		"iteration": iteration,
		"total_distance": total_distance,
		"converged": converged,
		"cluster_count": cluster_count,
		"data_point_count": data_point_count,
		"centroid_movement": centroid_movement_history[-1] if centroid_movement_history.size() > 0 else 0.0
	}

# Advanced educational features
func analyze_cluster_quality() -> Dictionary:
	if not converged or centroids.size() == 0:
		return {}
	
	var inertia = 0.0  # Within-cluster sum of squares
	var silhouette_scores = []
	var cluster_densities = []
	
	# Calculate inertia (WCSS - Within-Cluster Sum of Squares)
	for i in range(data_points.size()):
		var point = data_points[i]
		var cluster_id = assignments[i]
		if cluster_id >= 0 and cluster_id < centroids.size():
			var distance = point.position.distance_squared_to(centroids[cluster_id].position)
			inertia += distance
	
	# Calculate cluster densities
	for centroid in centroids:
		var points_in_cluster = centroid.assigned_points.size()
		var avg_distance = 0.0
		
		if points_in_cluster > 0:
			for point in centroid.assigned_points:
				avg_distance += point.distance_to_centroid
			avg_distance /= points_in_cluster
		
		cluster_densities.append({
			"cluster_id": centroid.cluster_id,
			"point_count": points_in_cluster,
			"avg_distance_to_centroid": avg_distance
		})
	
	return {
		"inertia": inertia,
		"cluster_densities": cluster_densities,
		"iterations_to_converge": iteration,
		"final_centroid_movement": centroid_movement_history[-1] if centroid_movement_history.size() > 0 else 0.0
	}

func export_clustering_data() -> Dictionary:
	var export_data = {
		"metadata": {
			"algorithm": "K-Means",
			"timestamp": Time.get_datetime_string_from_system(),
			"parameters": {
				"k": cluster_count,
				"data_points": data_point_count,
				"convergence_threshold": convergence_threshold,
				"max_iterations": 50
			}
		},
		"results": {
			"converged": converged,
			"iterations": iteration,
			"final_inertia": total_distance,
			"convergence_history": distance_history.duplicate(),
			"centroid_movement_history": centroid_movement_history.duplicate()
		},
		"data_points": [],
		"centroids": [],
		"cluster_assignments": assignments.duplicate()
	}
	
	# Export data point positions
	for point in data_points:
		export_data.data_points.append({
			"position": [point.position.x, point.position.y, point.position.z],
			"cluster_id": point.cluster_id
		})
	
	# Export final centroid positions
	for centroid in centroids:
		export_data.centroids.append({
			"position": [centroid.position.x, centroid.position.y, centroid.position.z],
			"cluster_id": centroid.cluster_id,
			"assigned_points": centroid.assigned_points.size()
		})
	
	return export_data

# Performance monitoring
var performance_metrics = {
	"frame_times": [],
	"update_times": [],
	"render_times": []
}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Clean up resources
		clear_visuals()
		get_tree().quit()

# Advanced visualization features
func create_3d_convergence_visualization():
	"""Create a 3D trail showing centroid movement over time"""
	if centroid_movement_history.size() < 2:
		return
	
	for i in range(centroids.size()):
		var centroid = centroids[i]
		# Store historical positions for trail rendering
		if not centroid.has_method("position_history"):
			centroid.set_meta("position_history", [])
		
		var history = centroid.get_meta("position_history", [])
		history.append(centroid.position)
		
		# Keep only last 10 positions
		if history.size() > 10:
			history.pop_front()
		
		centroid.set_meta("position_history", history)
		
		# Create trail visualization
		create_centroid_trail(centroid, history)

func create_centroid_trail(centroid: Centroid, positions: Array):
	if positions.size() < 2:
		return
	
	for i in range(positions.size() - 1):
		var from = positions[i]
		var to = positions[i + 1]
		
		var trail_line = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.05
		cylinder.bottom_radius = 0.05
		cylinder.height = 1.0
		trail_line.mesh = cylinder
		
		var material = StandardMaterial3D.new()
		var alpha = float(i) / float(positions.size() - 1) * 0.6
		material.albedo_color = Color(cluster_colors[centroid.cluster_id].r, 
									  cluster_colors[centroid.cluster_id].g, 
									  cluster_colors[centroid.cluster_id].b, alpha)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_line.material_override = material
		
		var center = (from + to) / 2
		var direction = (to - from).normalized()
		var distance = from.distance_to(to)
		
		trail_line.position = center
		trail_line.look_at(center + direction, Vector3.UP)
		trail_line.rotate_object_local(Vector3(1, 0, 0), PI/2)
		trail_line.scale.y = distance
		
		add_child(trail_line)
		
		# Auto-remove after some time
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.timeout.connect(func(): trail_line.queue_free())
		timer.one_shot = true
		add_child(timer)
		timer.start()

# Interactive features
func _on_data_point_clicked(point: DataPoint):
	"""Handle clicking on data points for detailed information"""
	show_point_info(point)

func show_point_info(point: DataPoint):
	var info_panel = create_info_panel(point)
	ui_container.add_child(info_panel)
	
	# Auto-remove after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.timeout.connect(func(): info_panel.queue_free())
	timer.one_shot = true
	add_child(timer)
	timer.start()

func create_info_panel(point: DataPoint) -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 150, 50)
	panel.size = Vector2(300, 120)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = cluster_colors[point.cluster_id] if point.cluster_id >= 0 else Color.WHITE
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 100)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Data Point Information"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	var position_label = Label.new()
	position_label.text = "Position: (%.1f, %.1f, %.1f)" % [point.position.x, point.position.y, point.position.z]
	position_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(position_label)
	
	var cluster_label = Label.new()
	cluster_label.text = "Cluster: " + str(point.cluster_id)
	cluster_label.add_theme_color_override("font_color", cluster_colors[point.cluster_id] if point.cluster_id >= 0 else Color.WHITE)
	vbox.add_child(cluster_label)
	
	var distance_label = Label.new()
	distance_label.text = "Distance to Centroid: %.2f" % point.distance_to_centroid
	distance_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(distance_label)
	
	return panel

# Educational assessment features
func generate_learning_report() -> Dictionary:
	var quality_metrics = analyze_cluster_quality()
	
	var report = {
		"student_performance": {
			"understanding_level": "intermediate",  # Would be determined by interaction patterns
			"key_concepts_grasped": [
				"centroid_movement",
				"iterative_convergence",
				"cluster_assignment"
			],
			"areas_for_improvement": [
				"optimal_k_selection",
				"initialization_sensitivity"
			]
		},
		"algorithm_performance": quality_metrics,
		"recommendations": [
			"Try different values of K to see how it affects clustering",
			"Compare clustered vs random data generation",
			"Observe how initialization affects final results"
		]
	}
	
	return report

# Experiment modes for educational purposes
func run_k_comparison_experiment():
	"""Run clustering with different K values to demonstrate elbow method"""
	var k_values = [2, 3, 4, 5, 6, 7, 8]
	var inertias = []
	
	for k in k_values:
		var original_k = cluster_count
		cluster_count = k
		
		restart_clustering()
		
		# Run to convergence (simplified for demo)
		while not converged and iteration < 50:
			perform_clustering_step()
		
		var quality = analyze_cluster_quality()
		inertias.append(quality.get("inertia", 0.0))
		
		# Restore original K
		cluster_count = original_k
	
	# Display results
	show_elbow_analysis(k_values, inertias)

func show_elbow_analysis(k_values: Array, inertias: Array):
	print("Elbow Method Analysis:")
	for i in range(k_values.size()):
		print("K=%d: Inertia=%.2f" % [k_values[i], inertias[i]])

# Advanced initialization methods
func initialize_centroids_plus_plus():
	"""K-means++ initialization - already implemented in initialize_centroids()"""
	pass

func initialize_centroids_random():
	"""Pure random initialization"""
	clear_centroids()
	
	for i in range(cluster_count):
		var random_pos = Vector3(
			randf_range(-data_space_size/2, data_space_size/2),
			randf_range(-4, 4),
			randf_range(-data_space_size/2, data_space_size/2)
		)
		var centroid = Centroid.new(random_pos, i)
		centroids.append(centroid)
	
	# Initialize assignments
	assignments.clear()
	previous_assignments.clear()
	for i in range(data_points.size()):
		assignments.append(-1)
		previous_assignments.append(-1)

func initialize_centroids_data_points():
	"""Initialize centroids at random data point positions"""
	clear_centroids()
	
	if data_points.size() >= cluster_count:
		var selected_indices = []
		
		for i in range(cluster_count):
			var random_index = randi() % data_points.size()
			while random_index in selected_indices:
				random_index = randi() % data_points.size()
			
			selected_indices.append(random_index)
			var centroid = Centroid.new(data_points[random_index].position, i)
			centroids.append(centroid)
	
	# Initialize assignments
	assignments.clear()
	previous_assignments.clear()
	for i in range(data_points.size()):
		assignments.append(-1)
		previous_assignments.append(-1)

# Save/Load functionality
func save_clustering_session(filename: String):
	var save_data = export_clustering_data()
	var file = FileAccess.open("user://clustering_sessions/" + filename + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Session saved to: ", filename)

func load_clustering_session(filename: String) -> bool:
	var file = FileAccess.open("user://clustering_sessions/" + filename + ".json", FileAccess.READ)
	if not file:
		print("Could not load session: ", filename)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing session file")
		return false
	
	var data = json.data
	
	# Restore parameters
	cluster_count = data.metadata.parameters.k
	data_point_count = data.metadata.parameters.data_points
	convergence_threshold = data.metadata.parameters.convergence_threshold
	
	# Restore state
	converged = data.results.converged
	iteration = data.results.iterations
	distance_history = data.results.convergence_history
	centroid_movement_history = data.results.centroid_movement_history
	assignments = data.cluster_assignments
	
	print("Session loaded: ", filename)
	return true

# Performance optimization
func optimize_rendering_for_large_datasets():
	"""Implement LOD (Level of Detail) for large datasets"""
	var camera_pos = get_viewport().get_camera_3d().global_position
	
	for i in range(data_points.size()):
		var point = data_points[i]
		var distance = point.position.distance_to(camera_pos)
		
		if distance > 50:
			# Use lower detail mesh or hide completely
			point.mesh_instance.visible = false
		elif distance > 25:
			# Use medium detail
			point.mesh_instance.visible = true
			point.mesh_instance.scale = Vector3(0.5, 0.5, 0.5)
		else:
			# Use full detail
			point.mesh_instance.visible = true
			point.mesh_instance.scale = Vector3(1.0, 1.0, 1.0)

# Additional utility functions
func get_cluster_statistics() -> Array:
	var stats = []
	
	for centroid in centroids:
		var cluster_stats = {
			"cluster_id": centroid.cluster_id,
			"centroid_position": centroid.position,
			"point_count": centroid.assigned_points.size(),
			"average_distance": 0.0,
			"variance": 0.0
		}
		
		if centroid.assigned_points.size() > 0:
			var total_distance = 0.0
			for point in centroid.assigned_points:
				total_distance += point.distance_to_centroid
			cluster_stats.average_distance = total_distance / centroid.assigned_points.size()
			
			# Calculate variance
			var variance_sum = 0.0
			for point in centroid.assigned_points:
				var diff = point.distance_to_centroid - cluster_stats.average_distance
				variance_sum += diff * diff
			cluster_stats.variance = variance_sum / centroid.assigned_points.size()
		
		stats.append(cluster_stats)
	
	return stats

func print_algorithm_summary():
	print("\n=== K-Means Clustering Summary ===")
	print("Clusters: ", cluster_count)
	print("Data Points: ", data_point_count)
	print("Iterations: ", iteration)
	print("Converged: ", converged)
	print("Final Inertia: ", snapped(total_distance, 0.01))
	print("================================\n")
