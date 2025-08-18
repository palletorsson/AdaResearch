extends Node3D

var time = 0.0
var noise_points = []
var voronoi_cells = []
var distance_field = []
var grid_size = 20
var min_distance = 1.0
var max_attempts = 30
var active_list = []
var generation_timer = 0.0
var generation_interval = 0.1
var current_iteration = 0
var max_iterations = 100

func _ready():
	create_distance_field()
	setup_materials()
	start_poisson_disk_sampling()

func create_distance_field():
	var field_parent = $DistanceField
	
	for x in range(grid_size):
		distance_field.append([])
		for y in range(grid_size):
			var field_point = CSGSphere3D.new()
			field_point.radius = 0.02
			field_point.position = Vector3(
				-5 + x * 0.5,
				-5 + y * 0.5,
				-1
			)
			field_parent.add_child(field_point)
			distance_field[x].append(field_point)

func setup_materials():
	# Min distance material
	var min_dist_material = StandardMaterial3D.new()
	min_dist_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	min_dist_material.emission_enabled = true
	min_dist_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$MinDistance.material_override = min_dist_material
	
	# Iteration count material
	var iter_material = StandardMaterial3D.new()
	iter_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	iter_material.emission_enabled = true
	iter_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$IterationCount.material_override = iter_material
	
	# Distance field materials
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	field_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	field_material.emission_enabled = true
	field_material.emission = Color(0.1, 0.1, 0.1, 1.0)
	
	for row in distance_field:
		for point in row:
			point.material_override = field_material

func _process(delta):
	time += delta
	generation_timer += delta
	
	if generation_timer >= generation_interval and current_iteration < max_iterations:
		generation_timer = 0.0
		poisson_disk_step()
	elif current_iteration >= max_iterations:
		# Reset and start over
		if time > 5.0:  # Wait 5 seconds before reset
			reset_generation()
	
	animate_blue_noise()
	animate_indicators()

func start_poisson_disk_sampling():
	noise_points.clear()
	active_list.clear()
	current_iteration = 0
	
	# Clear existing visual points
	for child in $NoisePoints.get_children():
		child.queue_free()
	
	# Start with initial point
	var initial_point = Vector2(0, 0)
	add_sample_point(initial_point)

func poisson_disk_step():
	if active_list.size() == 0:
		current_iteration = max_iterations
		return
	
	# Pick random point from active list
	var random_index = randi() % active_list.size()
	var active_point = active_list[random_index]
	
	var point_added = false
	
	# Try to generate new points around this active point
	for attempt in range(max_attempts):
		var new_point = generate_point_around(active_point, min_distance)
		
		if is_valid_point(new_point):
			add_sample_point(new_point)
			point_added = true
			break
	
	# If no point was added, remove from active list
	if not point_added:
		active_list.remove_at(random_index)
	
	current_iteration += 1

func generate_point_around(center: Vector2, radius: float) -> Vector2:
	# Generate point in annulus between radius and 2*radius
	var angle = randf() * 2.0 * PI
	var distance = radius + randf() * radius
	
	return center + Vector2(cos(angle) * distance, sin(angle) * distance)

func is_valid_point(point: Vector2) -> bool:
	# Check bounds
	if abs(point.x) > 5 or abs(point.y) > 5:
		return false
	
	# Check minimum distance to existing points
	for existing_point in noise_points:
		if point.distance_to(existing_point) < min_distance:
			return false
	
	return true

func add_sample_point(point: Vector2):
	noise_points.append(point)
	active_list.append(point)
	
	# Create visual representation
	var visual_point = CSGSphere3D.new()
	visual_point.radius = 0.1
	visual_point.position = Vector3(point.x, point.y, 0)
	
	# Material based on generation order
	var point_material = StandardMaterial3D.new()
	var color_intensity = noise_points.size() / 50.0
	point_material.albedo_color = Color(
		0.2 + color_intensity * 0.8,
		0.8 - color_intensity * 0.4,
		1.0 - color_intensity * 0.5,
		1.0
	)
	point_material.emission_enabled = true
	point_material.emission = point_material.albedo_color * 0.5
	visual_point.material_override = point_material
	
	$NoisePoints.add_child(visual_point)
	
	# Update distance field
	update_distance_field()
	
	# Create Voronoi visualization
	if noise_points.size() % 5 == 0:  # Update every 5 points for performance
		update_voronoi_diagram()

func update_distance_field():
	# Update distance field visualization
	for x in range(grid_size):
		for y in range(grid_size):
			var field_point = distance_field[x][y]
			var world_pos = Vector2(-5 + x * 0.5, -5 + y * 0.5)
			
			# Find distance to nearest sample point
			var min_dist = INF
			for sample_point in noise_points:
				var dist = world_pos.distance_to(sample_point)
				min_dist = min(min_dist, dist)
			
			# Normalize distance for visualization
			var normalized_dist = clamp(min_dist / (min_distance * 2.0), 0.0, 1.0)
			
			# Update field point
			var scale = 0.2 + normalized_dist * 0.8
			field_point.scale = Vector3.ONE * scale
			
			# Update color
			var material = field_point.material_override as StandardMaterial3D
			if material:
				material.albedo_color = Color(
					normalized_dist,
					1.0 - normalized_dist,
					0.5,
					0.3 + normalized_dist * 0.4
				)
				material.emission = material.albedo_color * 0.3

func update_voronoi_diagram():
	# Clear existing voronoi cells
	for cell in voronoi_cells:
		cell.queue_free()
	voronoi_cells.clear()
	
	# Create simplified Voronoi diagram
	var cell_parent = $VoronoiCells
	
	for i in range(noise_points.size()):
		var center = noise_points[i]
		
		# Create approximate Voronoi cell boundary
		var boundary_points = []
		var angle_step = PI / 6  # 12 points around circle
		
		for angle_idx in range(12):
			var angle = angle_idx * angle_step
			var test_radius = 0.3
			var test_point = center + Vector2(cos(angle) * test_radius, sin(angle) * test_radius)
			
			# Find actual boundary by checking nearest neighbor
			var nearest_dist = center.distance_to(test_point)
			for other_point in noise_points:
				if other_point != center:
					var other_dist = other_point.distance_to(test_point)
					if other_dist < nearest_dist:
						# Adjust point towards boundary
						var boundary_point = (center + other_point) * 0.5
						test_point = center + (boundary_point - center).normalized() * test_radius
						break
			
			boundary_points.append(test_point)
		
		# Create boundary visualization
		for j in range(boundary_points.size()):
			var start_point = boundary_points[j]
			var end_point = boundary_points[(j + 1) % boundary_points.size()]
			
			create_voronoi_edge(start_point, end_point)

func create_voronoi_edge(start: Vector2, end: Vector2):
	var edge = CSGCylinder3D.new()
	var length = start.distance_to(end)
	
	edge.height = length
	edge.top_radius = 0.01
	edge.bottom_radius = 0.01
	
	# Position and orient
	var mid_point = (start + end) * 0.5
	edge.position = Vector3(mid_point.x, mid_point.y, 0.2)
	
	# Orient edge
	var direction = (Vector3(end.x, end.y, 0) - Vector3(start.x, start.y, 0)).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		edge.transform.basis = Basis(axis, angle)
	
	# Edge material
	var edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(1.0, 1.0, 0.2, 0.7)
	edge_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.3, 0.3, 0.05, 1.0)
	edge.material_override = edge_material
	
	$VoronoiCells.add_child(edge)
	voronoi_cells.append(edge)

func reset_generation():
	start_poisson_disk_sampling()
	time = 0.0

func animate_blue_noise():
	# Animate noise points
	for i in range($NoisePoints.get_child_count()):
		var point = $NoisePoints.get_child(i)
		var pulse = 1.0 + sin(time * 4.0 + i * 0.3) * 0.2
		point.scale = Vector3.ONE * pulse
	
	# Animate Voronoi edges
	for edge in voronoi_cells:
		var edge_pulse = 1.0 + sin(time * 3.0 + edge.position.x) * 0.3
		edge.scale = Vector3(edge_pulse, 1.0, edge_pulse)
	
	# Animate distance field
	for row in distance_field:
		for point in row:
			var wave = sin(time * 2.0 + point.position.x * 0.5 + point.position.y * 0.3) * 0.1
			point.position.z = -1 + wave

func animate_indicators():
	# Min distance indicator
	var min_dist_height = min_distance * 1.5 + 0.5
	$MinDistance.size.y = min_dist_height
	$MinDistance.position.y = -3 + min_dist_height/2
	
	# Iteration count indicator
	var iter_progress = current_iteration / float(max_iterations)
	var iter_height = iter_progress * 2.0 + 0.5
	$IterationCount.size.y = iter_height
	$IterationCount.position.y = -3 + iter_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$MinDistance.scale.x = pulse
	$IterationCount.scale.x = pulse
	
	# Update min distance over time
	min_distance = 0.8 + sin(time * 0.2) * 0.4
