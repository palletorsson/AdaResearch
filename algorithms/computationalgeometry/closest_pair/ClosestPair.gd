extends Node3D

var time = 0.0
var points = []
var point_objects = []
var distance_lines = []
var closest_pair = []
var min_distance = INF
var algorithm_step = 0
var step_timer = 0.0
var step_interval = 1.5
var point_count = 16

# Algorithm visualization state
enum AlgorithmStep {
	GENERATE_POINTS,
	SORT_POINTS,
	DIVIDE,
	CONQUER_LEFT,
	CONQUER_RIGHT,
	COMBINE,
	SHOW_RESULT
}

func _ready():
	generate_random_points()
	setup_materials()

func generate_random_points():
	points.clear()
	for child in $Points.get_children():
		child.queue_free()
	point_objects.clear()
	
	# Generate random points in 2D space
	for i in range(point_count):
		var point = Vector2(
			randf_range(-6.0, 6.0),
			randf_range(-3.0, 3.0)
		)
		points.append(point)
		
		# Create visual representation
		var point_sphere = CSGSphere3D.new()
		point_sphere.radius = 0.15
		point_sphere.position = Vector3(point.x, point.y, 0)
		$Points.add_child(point_sphere)
		point_objects.append(point_sphere)

func setup_materials():
	# Point materials
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color(0.8, 0.8, 1.0, 1.0)
	point_material.emission_enabled = true
	point_material.emission = Color(0.2, 0.2, 0.3, 1.0)
	
	for point_obj in point_objects:
		point_obj.material_override = point_material
	
	# Division line material
	var division_material = StandardMaterial3D.new()
	division_material.albedo_color = Color(1.0, 0.8, 0.2, 0.7)
	division_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	division_material.emission_enabled = true
	division_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$DivisionLine.material_override = division_material
	
	# Closest pair line material
	var closest_material = StandardMaterial3D.new()
	closest_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	closest_material.emission_enabled = true
	closest_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$ClosestPairLine.material_override = closest_material
	
	# Indicator materials
	var step_material = StandardMaterial3D.new()
	step_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	step_material.emission_enabled = true
	step_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$AlgorithmStepIndicator.material_override = step_material
	
	var complexity_material = StandardMaterial3D.new()
	complexity_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	complexity_material.emission_enabled = true
	complexity_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$ComplexityIndicator.material_override = complexity_material

func _process(delta):
	time += delta
	step_timer += delta
	
	if step_timer >= step_interval:
		step_timer = 0.0
		advance_algorithm_step()
	
	animate_algorithm_visualization()
	animate_indicators()

func advance_algorithm_step():
	algorithm_step = (algorithm_step + 1) % AlgorithmStep.size()
	
	match algorithm_step:
		AlgorithmStep.GENERATE_POINTS:
			generate_random_points()
			setup_materials()
			clear_distance_lines()
		
		AlgorithmStep.SORT_POINTS:
			sort_points_by_x()
		
		AlgorithmStep.DIVIDE:
			show_division()
		
		AlgorithmStep.CONQUER_LEFT:
			highlight_left_half()
		
		AlgorithmStep.CONQUER_RIGHT:
			highlight_right_half()
		
		AlgorithmStep.COMBINE:
			find_closest_pair_brute_force()
		
		AlgorithmStep.SHOW_RESULT:
			highlight_closest_pair()

func sort_points_by_x():
	# Sort points by x-coordinate
	points.sort_custom(func(a, b): return a.x < b.x)
	
	# Animate points moving to sorted positions
	for i in range(point_objects.size()):
		var target_pos = Vector3(points[i].x, points[i].y, 0)
		point_objects[i].position = target_pos

func show_division():
	# Show division line at median x-coordinate
	var median_x = points[points.size() / 2].x
	$DivisionLine.position.x = median_x
	$DivisionLine.visible = true

func highlight_left_half():
	var median_x = points[points.size() / 2].x
	
	for i in range(point_objects.size()):
		var point_obj = point_objects[i]
		var material = point_obj.material_override as StandardMaterial3D
		
		if points[i].x < median_x:
			material.albedo_color = Color(1.0, 0.6, 0.6, 1.0)
			material.emission = Color(0.3, 0.1, 0.1, 1.0)
		else:
			material.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
			material.emission = Color(0.1, 0.1, 0.1, 1.0)

func highlight_right_half():
	var median_x = points[points.size() / 2].x
	
	for i in range(point_objects.size()):
		var point_obj = point_objects[i]
		var material = point_obj.material_override as StandardMaterial3D
		
		if points[i].x >= median_x:
			material.albedo_color = Color(0.6, 0.6, 1.0, 1.0)
			material.emission = Color(0.1, 0.1, 0.3, 1.0)
		else:
			material.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
			material.emission = Color(0.1, 0.1, 0.1, 1.0)

func find_closest_pair_brute_force():
	# Reset point colors
	for point_obj in point_objects:
		var material = point_obj.material_override as StandardMaterial3D
		material.albedo_color = Color(0.8, 0.8, 1.0, 1.0)
		material.emission = Color(0.2, 0.2, 0.3, 1.0)
	
	# Find closest pair using brute force for visualization
	min_distance = INF
	closest_pair.clear()
	
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var distance = points[i].distance_to(points[j])
			if distance < min_distance:
				min_distance = distance
				closest_pair = [i, j]

func highlight_closest_pair():
	if closest_pair.size() == 2:
		var point1 = points[closest_pair[0]]
		var point2 = points[closest_pair[1]]
		
		# Highlight the closest pair points
		for i in [closest_pair[0], closest_pair[1]]:
			var material = point_objects[i].material_override as StandardMaterial3D
			material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
			material.emission = Color(0.5, 0.1, 0.1, 1.0)
		
		# Show connecting line
		var line_center = Vector3((point1.x + point2.x) * 0.5, (point1.y + point2.y) * 0.5, 0)
		var line_length = point1.distance_to(point2)
		
		$ClosestPairLine.position = line_center
		$ClosestPairLine.height = line_length
		
		# Orient line between points
		var direction = Vector3(point2.x - point1.x, point2.y - point1.y, 0).normalized()
		if direction != Vector3.UP:
			var axis = Vector3.UP.cross(direction).normalized()
			var angle = acos(Vector3.UP.dot(direction))
			$ClosestPairLine.transform.basis = Basis(axis, angle)
		
		$ClosestPairLine.visible = true

func clear_distance_lines():
	for child in $DistanceLines.get_children():
		child.queue_free()
	distance_lines.clear()
	$ClosestPairLine.visible = false
	$DivisionLine.visible = false

func animate_algorithm_visualization():
	# Animate division line
	if $DivisionLine.visible:
		var pulse = 1.0 + sin(time * 4.0) * 0.1
		$DivisionLine.scale.y = pulse
	
	# Animate closest pair line
	if $ClosestPairLine.visible:
		var pulse = 1.0 + sin(time * 5.0) * 0.2
		$ClosestPairLine.scale = Vector3(pulse, 1.0, pulse)
	
	# Gentle floating animation for points
	for i in range(point_objects.size()):
		var point_obj = point_objects[i]
		var float_offset = sin(time * 2.0 + i * 0.5) * 0.05
		point_obj.position.z = float_offset

func animate_indicators():
	# Algorithm step indicator
	var step_height = (algorithm_step + 1) * 0.3
	$AlgorithmStepIndicator.size.y = step_height
	$AlgorithmStepIndicator.position.y = -4 + step_height/2
	
	# Complexity indicator (O(n log n))
	var complexity_height = log(point_count) * 0.5
	$ComplexityIndicator.size.y = complexity_height
	$ComplexityIndicator.position.y = -4 + complexity_height/2
	
	# Pulsing effect
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$AlgorithmStepIndicator.scale.x = pulse
	$ComplexityIndicator.scale.x = pulse
