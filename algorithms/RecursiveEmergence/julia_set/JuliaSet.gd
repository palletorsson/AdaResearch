extends Node3D

# Julia Set Visualization
# Parameter-space fractal variants of the Mandelbrot set

var time := 0.0
var c_real := -0.7
var c_imag := 0.27015
var max_iterations := 50
var escape_radius := 2.0
var zoom_level := 1.0
var grid_resolution := 40

func _ready():
	pass

func _process(delta):
	time += delta
	
	# Animate Julia set parameter
	c_real = -0.7 + sin(time * 0.3) * 0.3
	c_imag = 0.27015 + cos(time * 0.5) * 0.2
	
	zoom_level = 1.0 + sin(time * 0.2) * 0.5
	
	visualize_julia_set()
	show_parameter_space()
	display_iteration_count()
	analyze_escape_behavior()

func visualize_julia_set():
	var container = $JuliaVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Generate Julia set
	var bounds = 3.0 / zoom_level
	
	for i in range(grid_resolution):
		for j in range(grid_resolution):
			var x = (float(i) / grid_resolution - 0.5) * 2 * bounds
			var y = (float(j) / grid_resolution - 0.5) * 2 * bounds
			
			var iterations = julia_iterations(x, y, c_real, c_imag)
			var is_in_set = iterations >= max_iterations
			
			if is_in_set or iterations > 5:
				var point = CSGBox3D.new()
				point.size = Vector3(0.15, 0.15, 0.15)
				point.position = Vector3(x * 2, 0, y * 2)
				
				var material = StandardMaterial3D.new()
				
				if is_in_set:
					material.albedo_color = Color(0.0, 0.0, 0.0)
				else:
					var color_ratio = float(iterations) / max_iterations
					material.albedo_color = Color.from_hsv(color_ratio * 0.8, 0.8, 1.0)
					material.emission_enabled = true
					material.emission = Color.from_hsv(color_ratio * 0.8, 0.8, 1.0) * 0.3
				
				point.material_override = material
				container.add_child(point)

func julia_iterations(x: float, y: float, c_r: float, c_i: float) -> int:
	var z_real = x
	var z_imag = y
	var iteration = 0
	
	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag
		
		if z_real_sq + z_imag_sq > escape_radius * escape_radius:
			break
		
		var new_real = z_real_sq - z_imag_sq + c_r
		var new_imag = 2 * z_real * z_imag + c_i
		
		z_real = new_real
		z_imag = new_imag
		iteration += 1
	
	return iteration

func show_parameter_space():
	var container = $ParameterSpace
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Current parameter point
	var param_point = CSGSphere3D.new()
	param_point.radius = 0.2
	param_point.position = Vector3(c_real * 3, 0, c_imag * 3)
	
	var param_material = StandardMaterial3D.new()
	param_material.albedo_color = Color(1.0, 0.0, 0.0)
	param_material.emission_enabled = true
	param_material.emission = Color(1.0, 0.0, 0.0) * 0.8
	param_point.material_override = param_material
	
	container.add_child(param_point)
	
	# Parameter trajectory
	var trajectory_points = 20
	for i in range(trajectory_points):
		var t = time - float(i) * 0.1
		var trail_c_real = -0.7 + sin(t * 0.3) * 0.3
		var trail_c_imag = 0.27015 + cos(t * 0.5) * 0.2
		
		var trail_point = CSGSphere3D.new()
		trail_point.radius = 0.05 * (1.0 - float(i) / trajectory_points)
		trail_point.position = Vector3(trail_c_real * 3, 0, trail_c_imag * 3)
		
		var trail_material = StandardMaterial3D.new()
		var alpha = 1.0 - float(i) / trajectory_points
		trail_material.albedo_color = Color(1.0, 0.5, 0.0, alpha)
		trail_material.flags_transparent = true
		trail_point.material_override = trail_material
		
		container.add_child(trail_point)
	
	# Parameter space boundaries
	var boundary_ring = CSGCylinder3D.new()
	boundary_ring.top_radius = 3.0
	boundary_ring.bottom_radius = 2.8
	boundary_ring.height = 0.2
	boundary_ring.position = Vector3.ZERO
	
	var boundary_material = StandardMaterial3D.new()
	boundary_material.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
	boundary_material.flags_transparent = true
	boundary_ring.material_override = boundary_material
	
	container.add_child(boundary_ring)

func display_iteration_count():
	var container = $IterationDisplay
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Sample points for iteration analysis
	var sample_points = [
		Vector2(0.0, 0.0),
		Vector2(0.5, 0.0),
		Vector2(0.0, 0.5),
		Vector2(-0.5, 0.0),
		Vector2(0.0, -0.5)
	]
	
	for i in range(sample_points.size()):
		var point = sample_points[i]
		var iterations = julia_iterations(point.x, point.y, c_real, c_imag)
		
		var iter_tower = CSGBox3D.new()
		iter_tower.size = Vector3(0.4, float(iterations) * 0.1 + 0.1, 0.4)
		iter_tower.position = Vector3(
			point.x * 4,
			iter_tower.size.y * 0.5,
			point.y * 4
		)
		
		var material = StandardMaterial3D.new()
		var iter_ratio = float(iterations) / max_iterations
		material.albedo_color = Color(iter_ratio, 1.0 - iter_ratio, 0.5)
		material.emission_enabled = true
		material.emission = Color(iter_ratio, 1.0 - iter_ratio, 0.5) * 0.4
		iter_tower.material_override = material
		
		container.add_child(iter_tower)

func analyze_escape_behavior():
	var container = $EscapeAnalysis
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Analyze escape velocities at different points
	var analysis_grid = 8
	
	for i in range(analysis_grid):
		for j in range(analysis_grid):
			var x = (float(i) / analysis_grid - 0.5) * 4
			var y = (float(j) / analysis_grid - 0.5) * 4
			
			var escape_data = analyze_escape_velocity(x, y, c_real, c_imag)
			
			if escape_data.escaped:
				var escape_indicator = CSGCone3D.new()
				escape_indicator.radius_top = 0.0
				escape_indicator.radius_bottom = 0.2
				escape_indicator.height = escape_data.velocity * 2.0
				escape_indicator.position = Vector3(x, escape_indicator.height * 0.5, y)
				
				var material = StandardMaterial3D.new()
				var velocity_ratio = escape_data.velocity / 10.0
				material.albedo_color = Color(velocity_ratio, 0.5, 1.0 - velocity_ratio)
				material.emission_enabled = true
				material.emission = Color(velocity_ratio, 0.5, 1.0 - velocity_ratio) * 0.4
				escape_indicator.material_override = material
				
				container.add_child(escape_indicator)

func analyze_escape_velocity(x: float, y: float, c_r: float, c_i: float) -> Dictionary:
	var z_real = x
	var z_imag = y
	var iteration = 0
	var escape_velocity = 0.0
	var escaped = false
	
	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag
		var magnitude_sq = z_real_sq + z_imag_sq
		
		if magnitude_sq > escape_radius * escape_radius:
			# Calculate escape velocity
			escape_velocity = sqrt(magnitude_sq) - escape_radius
			escaped = true
			break
		
		var new_real = z_real_sq - z_imag_sq + c_r
		var new_imag = 2 * z_real * z_imag + c_i
		
		z_real = new_real
		z_imag = new_imag
		iteration += 1
	
	return {
		"escaped": escaped,
		"iterations": iteration,
		"velocity": escape_velocity
	}

