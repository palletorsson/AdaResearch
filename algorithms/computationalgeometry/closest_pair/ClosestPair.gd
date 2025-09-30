extends Node3D

var time = 0.0
var points = []
var point_objects = []
var distance_lines = []
var closest_pair = []
var min_distance = INF
var algorithm_step = 0
var step_timer = 0.0
var step_interval = 2.0
var point_count = 12
var step_labels = []
var current_comparison = []
var comparison_timer = 0.0
var comparison_interval = 0.3

# Algorithm visualization state
enum AlgorithmStep {
	GENERATE_POINTS,
	SORT_POINTS,
	DIVIDE,
	CONQUER_LEFT,
	CONQUER_RIGHT,
	COMPARE_DISTANCES,
	SHOW_RESULT
}

var step_names = [
	"1. Generate Random Points",
	"2. Sort Points by X-Coordinate", 
	"3. Divide Space at Median",
	"4. Find Closest in Left Half",
	"5. Find Closest in Right Half",
	"6. Compare Cross-Boundary Pairs",
	"7. Show Final Result"
]

func _ready():
	generate_random_points()
	setup_materials()
	setup_ui()
	create_coordinate_grid()

func generate_random_points():
	points.clear()
	for child in $Points.get_children():
		child.queue_free()
	point_objects.clear()
	
	# Generate random points in 2D space
	for i in range(point_count):
		var point = Vector2(
			randf_range(-5.0, 5.0),
			randf_range(-2.5, 2.5)
		)
		points.append(point)
		
		# Create visual representation with better visibility
		var point_sphere = CSGSphere3D.new()
		point_sphere.radius = 0.2
		point_sphere.position = Vector3(point.x, point.y, 0.1)
		$Points.add_child(point_sphere)
		point_objects.append(point_sphere)
		
		# Add point labels
		var label = Label3D.new()
		label.text = str(i)
		label.font_size = 24
		label.position = Vector3(point.x, point.y + 0.4, 0.1)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		$Points.add_child(label)

func setup_materials():
	# Point materials - more vibrant and visible
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
	point_material.emission_enabled = true
	point_material.emission = Color(0.1, 0.3, 0.5, 1.0)
	point_material.metallic = 0.3
	point_material.roughness = 0.2
	
	for point_obj in point_objects:
		point_obj.material_override = point_material
	
	# Division line material - more prominent
	var division_material = StandardMaterial3D.new()
	division_material.albedo_color = Color(1.0, 0.4, 0.0, 0.9)
	division_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	division_material.emission_enabled = true
	division_material.emission = Color(0.5, 0.2, 0.0, 1.0)
	$DivisionLine.material_override = division_material
	
	# Closest pair line material - more dramatic
	var closest_material = StandardMaterial3D.new()
	closest_material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
	closest_material.emission_enabled = true
	closest_material.emission = Color(0.8, 0.0, 0.0, 1.0)
	closest_material.metallic = 0.8
	$ClosestPairLine.material_override = closest_material
	
	# Indicator materials
	var step_material = StandardMaterial3D.new()
	step_material.albedo_color = Color(0.0, 1.0, 0.6, 1.0)
	step_material.emission_enabled = true
	step_material.emission = Color(0.0, 0.4, 0.2, 1.0)
	$AlgorithmStepIndicator.material_override = step_material
	
	var complexity_material = StandardMaterial3D.new()
	complexity_material.albedo_color = Color(1.0, 0.6, 0.0, 1.0)
	complexity_material.emission_enabled = true
	complexity_material.emission = Color(0.5, 0.3, 0.0, 1.0)
	$ComplexityIndicator.material_override = complexity_material

func setup_ui():
	# Create step label
	var step_label = Label3D.new()
	step_label.text = step_names[algorithm_step]
	step_label.font_size = 32
	step_label.position = Vector3(0, 4, 0)
	step_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(step_label)
	step_labels.append(step_label)
	
	# Create distance info label
	var distance_label = Label3D.new()
	distance_label.text = "Min Distance: --"
	distance_label.font_size = 24
	distance_label.position = Vector3(0, 3.5, 0)
	distance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(distance_label)
	step_labels.append(distance_label)

func _process(delta):
	time += delta
	step_timer += delta
	comparison_timer += delta
	
	if step_timer >= step_interval:
		step_timer = 0.0
		advance_algorithm_step()
	
	# Handle comparison animations during COMPARE_DISTANCES step
	if algorithm_step == AlgorithmStep.COMPARE_DISTANCES and comparison_timer >= comparison_interval:
		comparison_timer = 0.0
		animate_distance_comparison()
	
	animate_algorithm_visualization()
	animate_indicators()
	update_ui()

func advance_algorithm_step():
	algorithm_step = (algorithm_step + 1) % AlgorithmStep.size()
	
	match algorithm_step:
		AlgorithmStep.GENERATE_POINTS:
			generate_random_points()
			setup_materials()
			clear_distance_lines()
			reset_point_colors()
		
		AlgorithmStep.SORT_POINTS:
			sort_points_by_x()
		
		AlgorithmStep.DIVIDE:
			show_division()
		
		AlgorithmStep.CONQUER_LEFT:
			highlight_left_half()
		
		AlgorithmStep.CONQUER_RIGHT:
			highlight_right_half()
		
		AlgorithmStep.COMPARE_DISTANCES:
			start_distance_comparison()
		
		AlgorithmStep.SHOW_RESULT:
			highlight_closest_pair()

func sort_points_by_x():
	# Sort points by x-coordinate
	points.sort_custom(func(a, b): return a.x < b.x)
	
	# Animate points moving to sorted positions
	for i in range(point_objects.size()):
		var target_pos = Vector3(points[i].x, points[i].y, 0.1)
		point_objects[i].position = target_pos

func reset_point_colors():
	# Reset all points to default color
	for point_obj in point_objects:
		var material = point_obj.material_override as StandardMaterial3D
		material.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
		material.emission = Color(0.1, 0.3, 0.5, 1.0)

func start_distance_comparison():
	# Reset point colors
	reset_point_colors()
	
	# Find closest pair using brute force for visualization
	min_distance = INF
	closest_pair.clear()
	
	# Start the comparison process
	current_comparison = [0, 1]
	comparison_timer = 0.0

func animate_distance_comparison():
	if current_comparison.size() < 2:
		return
	
	var i = current_comparison[0]
	var j = current_comparison[1]
	
	# Highlight current comparison points
	for idx in range(point_objects.size()):
		var material = point_objects[idx].material_override as StandardMaterial3D
		if idx == i or idx == j:
			material.albedo_color = Color(1.0, 1.0, 0.0, 1.0)
			material.emission = Color(0.5, 0.5, 0.0, 1.0)
		else:
			material.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
			material.emission = Color(0.1, 0.3, 0.5, 1.0)
	
	# Calculate and show distance
	var distance = points[i].distance_to(points[j])
	if distance < min_distance:
		min_distance = distance
		closest_pair = [i, j]
	
	# Create temporary distance line
	create_temporary_distance_line(i, j, distance)
	
	# Move to next comparison
	j += 1
	if j >= points.size():
		i += 1
		j = i + 1
	
	if i >= points.size() - 1:
		# All comparisons done, move to result
		algorithm_step = AlgorithmStep.SHOW_RESULT
		step_timer = 0.0
	else:
		current_comparison = [i, j]

func create_temporary_distance_line(i: int, j: int, distance: float):
	# Remove old temporary lines
	for child in $DistanceLines.get_children():
		child.queue_free()
	
	# Create new temporary line
	var line = CSGCylinder3D.new()
	line.radius = 0.05
	line.height = distance
	
	var point1 = points[i]
	var point2 = points[j]
	var line_center = Vector3((point1.x + point2.x) * 0.5, (point1.y + point2.y) * 0.5, 0.05)
	
	line.position = line_center
	
	# Orient line between points
	var direction = Vector3(point2.x - point1.x, point2.y - point1.y, 0).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		line.transform.basis = Basis(axis, angle)
	
	# Material for temporary line
	var temp_material = StandardMaterial3D.new()
	temp_material.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
	temp_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	temp_material.emission_enabled = true
	temp_material.emission = Color(0.5, 0.5, 0.0, 1.0)
	line.material_override = temp_material
	
	$DistanceLines.add_child(line)

func update_ui():
	if step_labels.size() >= 2:
		step_labels[0].text = step_names[algorithm_step]
		if min_distance != INF:
			step_labels[1].text = "Min Distance: %.2f" % min_distance
		else:
			step_labels[1].text = "Min Distance: --"

func create_coordinate_grid():
	# Clear existing grid
	for child in $CoordinateGrid/GridLines.get_children():
		child.queue_free()
	
	# Create grid material
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.3, 0.3, 0.3, 0.3)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.1, 0.1, 0.1, 1.0)
	
	# Create vertical grid lines
	for i in range(-5, 6):
		var line = CSGBox3D.new()
		line.size = Vector3(0.02, 6, 0.02)
		line.position = Vector3(i, 0, -0.1)
		line.material_override = grid_material
		$CoordinateGrid/GridLines.add_child(line)
	
	# Create horizontal grid lines
	for i in range(-3, 4):
		var line = CSGBox3D.new()
		line.size = Vector3(10, 0.02, 0.02)
		line.position = Vector3(0, i, -0.1)
		line.material_override = grid_material
		$CoordinateGrid/GridLines.add_child(line)

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
			material.albedo_color = Color(1.0, 0.4, 0.4, 1.0)
			material.emission = Color(0.4, 0.1, 0.1, 1.0)
		else:
			material.albedo_color = Color(0.3, 0.3, 0.3, 0.6)
			material.emission = Color(0.05, 0.05, 0.05, 1.0)

func highlight_right_half():
	var median_x = points[points.size() / 2].x
	
	for i in range(point_objects.size()):
		var point_obj = point_objects[i]
		var material = point_obj.material_override as StandardMaterial3D
		
		if points[i].x >= median_x:
			material.albedo_color = Color(0.4, 0.4, 1.0, 1.0)
			material.emission = Color(0.1, 0.1, 0.4, 1.0)
		else:
			material.albedo_color = Color(0.3, 0.3, 0.3, 0.6)
			material.emission = Color(0.05, 0.05, 0.05, 1.0)


func highlight_closest_pair():
	# Clear temporary distance lines
	for child in $DistanceLines.get_children():
		child.queue_free()
	
	# Reset all points to default color first
	reset_point_colors()
	
	if closest_pair.size() == 2:
		var point1 = points[closest_pair[0]]
		var point2 = points[closest_pair[1]]
		
		# Highlight the closest pair points with dramatic effect
		for i in [closest_pair[0], closest_pair[1]]:
			var material = point_objects[i].material_override as StandardMaterial3D
			material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
			material.emission = Color(1.0, 0.2, 0.2, 1.0)
			material.metallic = 0.9
			material.roughness = 0.1
		
		# Dim all other points
		for i in range(point_objects.size()):
			if i not in closest_pair:
				var material = point_objects[i].material_override as StandardMaterial3D
				material.albedo_color = Color(0.2, 0.2, 0.2, 0.4)
				material.emission = Color(0.0, 0.0, 0.0, 1.0)
		
		# Show connecting line with enhanced visibility
		var line_center = Vector3((point1.x + point2.x) * 0.5, (point1.y + point2.y) * 0.5, 0.1)
		var line_length = point1.distance_to(point2)
		
		$ClosestPairLine.position = line_center
		$ClosestPairLine.height = line_length
		$ClosestPairLine.radius = 0.15  # Make line thicker
		
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
	# Animate division line with more prominent effect
	if $DivisionLine.visible:
		var pulse = 1.0 + sin(time * 6.0) * 0.2
		$DivisionLine.scale.y = pulse
		# Add slight rotation for more visual interest
		$DivisionLine.rotation.z = sin(time * 2.0) * 0.1
	
	# Animate closest pair line with dramatic pulsing
	if $ClosestPairLine.visible:
		var pulse = 1.0 + sin(time * 8.0) * 0.3
		$ClosestPairLine.scale = Vector3(pulse, 1.0, pulse)
		# Add glow effect
		var material = $ClosestPairLine.material_override as StandardMaterial3D
		material.emission = Color(0.8, 0.0, 0.0, 1.0) * (1.0 + sin(time * 10.0) * 0.5)
	
	# Enhanced floating animation for points
	for i in range(point_objects.size()):
		var point_obj = point_objects[i]
		var float_offset = sin(time * 2.0 + i * 0.5) * 0.08
		point_obj.position.z = 0.1 + float_offset
		
		# Add subtle rotation for active points
		if algorithm_step == AlgorithmStep.COMPARE_DISTANCES and i in current_comparison:
			point_obj.rotation.y = time * 2.0

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
