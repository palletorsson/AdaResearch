extends Node3D

@export var point_count: int = 15
@export var distribution_type: int = 1  # 0=Uniform, 1=Normal, 2=Clustered
@export var algorithm_type: int = 0  # 0=Graham Scan, 1=Jarvis March, 2=Quick Hull

var points: Array[Vector3] = []
var hull_points: Array[Vector3] = []
var point_spheres: Array[CSGSphere3D] = []
var hull_lines: Array[CSGBox3D] = []
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
			var clusters = 3
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

func graham_scan_3d() -> Array[Vector3]:
	# Simplified 3D Graham scan (projects to 2D for visualization)
	if points.size() < 3:
		return Array[Vector3]()
	
	# Find the lowest point (minimum y-coordinate)
	var lowest_point = points[0]
	for point in points:
		if point.y < lowest_point.y:
			lowest_point = point
	
	# Sort points by polar angle relative to lowest point
	var sorted_points = points.duplicate()
	sorted_points.sort_custom(Callable(self, "_compare_polar_angle").bind(lowest_point))
	
	# Graham scan
	var hull: Array[Vector3] = []
	hull.append(lowest_point)
	hull.append(sorted_points[1])
	
	for i in range(2, sorted_points.size()):
		while hull.size() > 1 and not is_left_turn(hull[-2], hull[-1], sorted_points[i]):
			hull.pop_back()
		hull.append(sorted_points[i])
	
	return hull

func jarvis_march_3d() -> Array[Vector3]:
	# Simplified 3D Jarvis march
	if points.size() < 3:
		return Array[Vector3]()
	
	var hull: Array[Vector3] = []
	var leftmost = points[0]
	for point in points:
		if point.x < leftmost.x:
			leftmost = point
	
	hull.append(leftmost)
	
	var current = leftmost
	var finished = false
	
	while not finished:
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

func quick_hull_3d() -> Array[Vector3]:
	# Simplified 3D Quick Hull
	if points.size() < 3:
		return Array[Vector3]()
	
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
	
	var hull: Array[Vector3] = []
	hull.append(min_x)
	hull.append(max_x)
	hull.append(min_y)
	hull.append(max_y)
	
	# Add points that are outside the current hull
	for point in points:
		if not is_point_in_hull(point, hull):
			hull.append(point)
	
	return hull

func get_polar_angle(v: Vector3) -> float:
	return atan2(v.z, v.x)

func _compare_polar_angle(a: Vector3, b: Vector3, lowest_point: Vector3) -> bool:
	return get_polar_angle(a - lowest_point) < get_polar_angle(b - lowest_point)

func is_left_turn(a: Vector3, b: Vector3, c: Vector3) -> bool:
	var ab = b - a
	var ac = c - a
	var cross = ab.cross(ac)
	return cross.y > 0

func is_point_in_hull(point: Vector3, hull: Array[Vector3]) -> bool:
	# Simple convex hull containment test
	if hull.size() < 3:
		return true
	
	for i in range(hull.size()):
		var a = hull[i]
		var b = hull[(i + 1) % hull.size()]
		var c = hull[(i + 2) % hull.size()]
		
		if not is_left_turn(a, b, c):
			return false
	
	return true

func create_hull_visuals():
	if hull_points.size() < 2:
		return
	
	# Create lines connecting hull points
	for i in range(hull_points.size()):
		var start = hull_points[i]
		var end = hull_points[(i + 1) % hull_points.size()]
		
		var line = CSGBox3D.new()
		var direction = end - start
		var distance = direction.length()
		
		line.size = Vector3(0.1, 0.1, distance)
		line.position = start + direction / 2
		line.look_at(end)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 0.4)
		material.metallic = 0.3
		material.roughness = 0.6
		line.material_override = material
		
		add_child(line)
		hull_lines.append(line)

func clear_hull_visuals():
	for line in hull_lines:
		line.queue_free()
	hull_lines.clear()
	hull_points.clear()

func clear_all():
	clear_hull_visuals()
	
	for sphere in point_spheres:
		sphere.queue_free()
	point_spheres.clear()
	points.clear()
