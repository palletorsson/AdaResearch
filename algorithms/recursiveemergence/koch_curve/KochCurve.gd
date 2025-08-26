extends Node3D

var time = 0.0
var current_iteration = 0
var max_iterations = 4
var iteration_timer = 0.0
var iteration_interval = 3.0
var fractal_segments = []
var total_segments = 0
var animation_stopped = false  # New: flag to stop animation

# Koch curve generation
var points = []

func _ready():
	setup_materials()
	initialize_koch_curve()

func setup_materials():
	# Iteration control material
	var iter_material = StandardMaterial3D.new()
	iter_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	iter_material.emission_enabled = true
	iter_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$IterationControl.material_override = iter_material
	
	# Complexity indicator material
	var complexity_material = StandardMaterial3D.new()
	complexity_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	complexity_material.emission_enabled = true
	complexity_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$ComplexityIndicator.material_override = complexity_material

func initialize_koch_curve():
	# Start with equilateral triangle
	points.clear()
	var triangle_size = 4.0
	var height = triangle_size * sqrt(3) / 2.0
	
	# Three vertices of equilateral triangle
	points.append(Vector2(-triangle_size/2, -height/3))
	points.append(Vector2(triangle_size/2, -height/3))
	points.append(Vector2(0, 2*height/3))
	points.append(Vector2(-triangle_size/2, -height/3))  # Close the triangle
	
	current_iteration = 0
	animation_stopped = false  # Reset animation flag
	generate_koch_curve()

func _process(delta):
	time += delta
	iteration_timer += delta
	
	# Only advance iteration if animation hasn't stopped
	if not animation_stopped and iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		current_iteration = (current_iteration + 1) % (max_iterations + 1)
		
		# Stop progression after iteration 2 to prevent VR crashes
		if current_iteration > 2:
			animation_stopped = true
			current_iteration = 2  # Stay at safe iteration 2
			generate_koch_curve()
		elif current_iteration == 0:
			initialize_koch_curve()
		else:
			generate_koch_curve()

func generate_koch_curve():
	# Apply Koch transformation for current iteration
	for iter in range(current_iteration):
		apply_koch_transformation()
	
	update_visual_representation()

func apply_koch_transformation():
	var new_points = []
	
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		
		# Apply Koch curve rule: replace each line segment with Koch curve
		var koch_points = generate_koch_segment(start, end)
		
		# Add all points except the last one (to avoid duplication)
		for j in range(koch_points.size() - 1):
			new_points.append(koch_points[j])
	
	# Add the final point
	new_points.append(points[-1])
	points = new_points

func generate_koch_segment(start: Vector2, end: Vector2) -> Array:
	# Koch curve rule: divide segment into thirds, create equilateral triangle
	var direction = end - start
	var length = direction.length()
	var unit_dir = direction.normalized()
	
	# Calculate the four points of Koch segment
	var p1 = start
	var p2 = start + unit_dir * (length / 3.0)
	var p4 = start + unit_dir * (2.0 * length / 3.0)
	var p5 = end
	
	# Calculate the peak of the equilateral triangle
	var perpendicular = Vector2(-unit_dir.y, unit_dir.x)  # Rotate 90 degrees
	var triangle_height = (length / 3.0) * sqrt(3) / 2.0
	var p3 = p2 + perpendicular * triangle_height
	
	return [p1, p2, p3, p4, p5]

func update_visual_representation():
	# Clear existing segments
	for segment in fractal_segments:
		segment.queue_free()
	fractal_segments.clear()
	
	# Create visual segments
	total_segments = points.size() - 1
	
	for i in range(points.size() - 1):
		create_segment(points[i], points[i + 1], i)

func create_segment(start: Vector2, end: Vector2, index: int):
	var segment = CSGCylinder3D.new()
	var length = start.distance_to(end)
	
	segment.height = length
	segment.radius = 0.02
	
	
	# Position at midpoint
	var midpoint = (start + end) * 0.5
	segment.position = Vector3(midpoint.x, midpoint.y, 0)
	
	# Orient segment
	var direction = (end - start).normalized()
	var angle = atan2(direction.y, direction.x)
	segment.rotation_degrees = Vector3(0, 0, angle * 180.0 / PI - 90)
	
	# Material based on iteration and position
	var segment_material = StandardMaterial3D.new()
	var color_intensity = float(index) / total_segments
	var iteration_intensity = float(current_iteration) / max_iterations
	
	segment_material.albedo_color = Color(
		0.2 + iteration_intensity * 0.8,
		0.8 - color_intensity * 0.4,
		0.3 + color_intensity * 0.7,
		1.0
	)
	segment_material.emission_enabled = true
	segment_material.emission = segment_material.albedo_color * 0.5
	segment.material_override = segment_material
	
	$FractalSegments.add_child(segment)
	fractal_segments.append(segment)

func animate_koch_curve():
	# Animate segments with wave effect
	for i in range(fractal_segments.size()):
		var segment = fractal_segments[i]
		var wave_phase = time * 4.0 + i * 0.1
		var wave_intensity = sin(wave_phase) * 0.3 + 1.0
		segment.scale = Vector3.ONE * wave_intensity
		
		# Update emission based on wave
		var material = segment.material_override as StandardMaterial3D
		if material:
			var base_emission = material.albedo_color * 0.5
			material.emission = base_emission * wave_intensity

func animate_indicators():
	# Iteration control
	var iter_height = (current_iteration + 1) * 0.4 + 0.5
	$IterationControl.height = iter_height
	$IterationControl.position.y = -3 + iter_height/2
	
	# Complexity indicator (number of segments)
	var complexity = total_segments
	var max_complexity = pow(4, max_iterations) * 3  # Theoretical maximum
	var complexity_height = (float(complexity) / max_complexity) * 3.0 + 0.5
	var complexityindicator = get_node_or_null("ComplexityIndicator")
	if complexityindicator and complexityindicator is CSGCylinder3D:
		complexityindicator.height = complexity_height
		complexityindicator.position.y = -3 + complexity_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$IterationControl.scale.x = pulse
	$ComplexityIndicator.scale.x = pulse
	
	# Update colors based on iteration
	var iter_material = $IterationControl.material_override as StandardMaterial3D
	if iter_material:
		var intensity = float(current_iteration) / max_iterations
		iter_material.albedo_color = Color(
			1.0,
			0.3 + intensity * 0.7,
			0.3,
			1.0
		)
		iter_material.emission = iter_material.albedo_color * 0.5

func get_fractal_info() -> Dictionary:
	return {
		"iteration": current_iteration,
		"segments": total_segments,
		"theoretical_length": pow(4.0/3.0, current_iteration) * 12.0,  # Length grows by 4/3 each iteration
		"animation_stopped": animation_stopped
	}
