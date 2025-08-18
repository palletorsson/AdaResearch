extends Node3D

@export var point_count: int = 15
@export var distribution_type: int = 1  # 0=Uniform, 1=Normal, 2=Clustered
@export var algorithm_type: int = 0  # 0=Graham Scan, 1=Jarvis March, 2=Quick Hull

var points: Array = []
var hull_points: Array = []
var point_spheres: Array = []
var hull_lines: Array = []
var bounds = 10.0

func _ready():
	generate_points()

func generate_points():
	clear_all()
	
	# Generate points based on distribution type
	match distribution_type:
		0:  # Uniform distribution
			for i in range(point_count):
				var point = Vector3(
					randf_range(-bounds, bounds),
					randf_range(-bounds, bounds),
					randf_range(-bounds, bounds)
				)
				points.append(point)
		1:  # Normal distribution
			for i in range(point_count):
				var point = Vector3(
					randfn(0, bounds/3),
					randfn(0, bounds/3),
					randfn(0, bounds/3)
				)
				point = point.clamp(Vector3(-bounds, -bounds, -bounds), Vector3(bounds, bounds, bounds))
				points.append(point)
		2:  # Clustered distribution
			for i in range(point_count):
				var cluster_center = Vector3(
					randf_range(-bounds/2, bounds/2),
					randf_range(-bounds/2, bounds/2),
					randf_range(-bounds/2, bounds/2)
				)
				var point = cluster_center + Vector3(
					randf_range(-bounds/4, bounds/4),
					randf_range(-bounds/4, bounds/4),
					randf_range(-bounds/4, bounds/4)
				)
				point = point.clamp(Vector3(-bounds, -bounds, -bounds), Vector3(bounds, bounds, bounds))
				points.append(point)
	
	# Create visual representations
	create_point_visuals()

func create_point_visuals():
	for point in points:
		var sphere = CSGSphere3D.new()
		sphere.radius = 0.3
		sphere.position = point
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.4, 0.2)
		material.metallic = 0.1
		material.roughness = 0.8
		sphere.material_override = material
		
		add_child(sphere)
		point_spheres.append(sphere)

func compute_convex_hull():
	# Clear previous hull
	clear_hull_visuals()
	
	match algorithm_type:
		0:  # Graham Scan
			hull_points = graham_scan_3d()
		1:  # Jarvis March
			hull_points = jarvis_march_3d()
		2:  # Quick Hull
			hull_points = quick_hull_3d()
	
	# Create hull visualization
	create_hull_visuals()

func graham_scan_3d() -> Array:
	if points.size() < 3:
		return []
	
	# Find the lowest point (minimum y-coordinate)
	var lowest_point = points[0]
	for point in points:
		if point.y < lowest_point.y:
			lowest_point = point
	
	# Sort points by polar angle using manual sorting
	var sorted_points = []
	for point in points:
		if point != lowest_point:
			sorted_points.append(point)
	
	# Manual bubble sort by polar angle
	for i in range(sorted_points.size()):
		for j in range(i + 1, sorted_points.size()):
			if not compare_polar_angle(sorted_points[i], sorted_points[j], lowest_point):
				var temp = sorted_points[i]
				sorted_points[i] = sorted_points[j]
				sorted_points[j] = temp
	
	# Add lowest point at the beginning
	sorted_points.insert(0, lowest_point)
	
	# Graham scan algorithm
	var hull = []
	hull.append(lowest_point)
	
	if sorted_points.size() < 2:
		return hull
	
	hull.append(sorted_points[1])
	
	for i in range(2, sorted_points.size()):
		while hull.size() > 1 and not is_left_turn(hull[-2], hull[-1], sorted_points[i]):
			hull.pop_back()
		hull.append(sorted_points[i])
	
	return hull

func jarvis_march_3d() -> Array:
	if points.size() < 3:
		return []
	
	var hull = []
	var leftmost = points[0]
	
	# Find leftmost point
	for point in points:
		if point.x < leftmost.x:
			leftmost = point
	
	hull.append(leftmost)
	var current = leftmost
	var finished = false
	var iterations = 0
	var max_iterations = points.size()
	
	while not finished and iterations < max_iterations:
		iterations += 1
		var next = points[0]
		
		for point in points:
			if point == current:
				continue
			if next == current or is_left_turn(current, next, point):
				next = point
		
		if next == leftmost:
			finished = true
		else:
			hull.append(next)
			current = next
	
	return hull

func quick_hull_3d() -> Array:
	if points.size() < 3:
		return []
	
	# Find extreme points
	var min_x = points[0]
	var max_x = points[0]
	var min_y = points[0]
	var max_y = points[0]
	
	for point in points:
		if point.x < min_x.x:
			min_x = point
		if point.x > max_x.x:
			max_x = point
		if point.y < min_y.y:
			min_y = point
		if point.y > max_y.y:
			max_y = point
	
	var hull = []
	var extreme_points = [min_x, max_x, min_y, max_y]
	
	# Add unique extreme points
	for point in extreme_points:
		if point not in hull:
			hull.append(point)
	
	# Add points that are outside the current hull
	for point in points:
		if not is_point_in_hull(point, hull) and point not in hull:
			hull.append(point)
	
	return hull

func get_polar_angle(v: Vector3) -> float:
	return atan2(v.z, v.x)

func compare_polar_angle(a: Vector3, b: Vector3, lowest_point: Vector3) -> bool:
	var angle_a = get_polar_angle(a - lowest_point)
	var angle_b = get_polar_angle(b - lowest_point)
	
	# If angles are equal, sort by distance
	if abs(angle_a - angle_b) < 0.001:
		return a.distance_to(lowest_point) < b.distance_to(lowest_point)
	
	return angle_a < angle_b

func is_left_turn(a: Vector3, b: Vector3, c: Vector3) -> bool:
	var ab = b - a
	var ac = c - a
	var cross = ab.cross(ac)
	return cross.y > 0

func is_point_in_hull(point: Vector3, hull: Array) -> bool:
	if hull.size() < 3:
		return false
	
	# Check if point is one of the hull vertices
	for hull_point in hull:
		if point.distance_to(hull_point) < 0.001:
			return true
	
	# Simple containment test
	for i in range(hull.size()):
		var a = hull[i]
		var b = hull[(i + 1) % hull.size()]
		
		if not is_left_turn(a, b, point):
			return false
	
	return true

func create_hull_visuals():
	if hull_points.size() < 2:
		return
	
	# Create lines connecting hull points
	for i in range(hull_points.size()):
		var start = hull_points[i]
		var end = hull_points[(i + 1) % hull_points.size()]
		
		# Skip if points are too close
		if start.distance_to(end) < 0.001:
			continue
		
		var line = CSGBox3D.new()
		var direction = end - start
		var distance = direction.length()
		
		line.size = Vector3(0.1, 0.1, distance)
		line.position = start + direction / 2
		
		if distance > 0.001:
			line.look_at(start + direction, Vector3.UP)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 0.4)
		material.emission_enabled = true
		material.emission = Color(0.05, 0.2, 0.1)
		material.emission_energy = 1.0
		material.metallic = 0.3
		material.roughness = 0.6
		line.material_override = material
		
		add_child(line)
		hull_lines.append(line)
	
	# Highlight hull points
	highlight_hull_points()

func highlight_hull_points():
	for i in range(point_spheres.size()):
		var sphere = point_spheres[i]
		var point = points[i]
		var material = sphere.material_override as StandardMaterial3D
		
		if point in hull_points:
			# Hull point - make it glow
			material.albedo_color = Color(0.2, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.1, 0.5, 0.1)
			material.emission_energy = 1.0
		else:
			# Regular point
			material.albedo_color = Color(0.9, 0.4, 0.2)
			material.emission_enabled = false

func clear_hull_visuals():
	for line in hull_lines:
		if is_instance_valid(line):
			line.queue_free()
	hull_lines.clear()
	hull_points.clear()

func clear_all():
	clear_hull_visuals()
	
	for sphere in point_spheres:
		if is_instance_valid(sphere):
			sphere.queue_free()
	point_spheres.clear()
	points.clear()

# Public interface functions
func set_point_count(count: int):
	point_count = max(3, count)
	generate_points()

func set_distribution_type(type: int):
	distribution_type = clamp(type, 0, 2)
	generate_points()

func set_algorithm_type(type: int):
	algorithm_type = clamp(type, 0, 2)
	if hull_points.size() > 0:
		compute_convex_hull()

func get_algorithm_name() -> String:
	match algorithm_type:
		0: return "Graham Scan"
		1: return "Jarvis March"
		2: return "Quick Hull"
		_: return "Unknown"

func get_hull_info() -> Dictionary:
	return {
		"algorithm": get_algorithm_name(),
		"total_points": points.size(),
		"hull_points": hull_points.size(),
		"hull_percentage": (float(hull_points.size()) / points.size()) * 100.0 if points.size() > 0 else 0.0
	}

func animate_hull_computation():
	clear_hull_visuals()
	var tween = create_tween()
	tween.tween_delay(0.5)
	tween.tween_callback(compute_convex_hull)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				compute_convex_hull()
			KEY_R:
				generate_points()
			KEY_1:
				set_algorithm_type(0)
			KEY_2:
				set_algorithm_type(1)
			KEY_3:
				set_algorithm_type(2)
