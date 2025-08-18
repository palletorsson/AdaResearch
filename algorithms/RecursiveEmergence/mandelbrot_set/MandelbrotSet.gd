extends Node3D

var time = 0.0
var resolution = 50
var max_iterations = 50
var zoom = 1.0
var center = Vector2(-0.5, 0.0)
var fractal_points = []

func _ready():
	generate_mandelbrot()
	setup_materials()

func generate_mandelbrot():
	var points_parent = $FractalPoints
	
	# Clear existing points
	for child in points_parent.get_children():
		child.queue_free()
	fractal_points.clear()
	
	for x in range(resolution):
		for y in range(resolution):
			var real = center.x + (x - resolution/2) * (4.0 / zoom) / resolution
			var imag = center.y + (y - resolution/2) * (4.0 / zoom) / resolution
			
			var iterations = mandelbrot_iterations(real, imag)
			var normalized_iter = float(iterations) / max_iterations
			
			var point = CSGSphere3D.new()
			point.radius = 0.03
			point.position = Vector3(
				(x - resolution/2) * 0.15,
				(y - resolution/2) * 0.15,
				normalized_iter * 2.0
			)
			
			points_parent.add_child(point)
			fractal_points.append({"object": point, "iterations": iterations})

func mandelbrot_iterations(c_real: float, c_imag: float) -> int:
	var z_real = 0.0
	var z_imag = 0.0
	var iterations = 0
	
	while iterations < max_iterations and (z_real * z_real + z_imag * z_imag) < 4.0:
		var new_real = z_real * z_real - z_imag * z_imag + c_real
		var new_imag = 2.0 * z_real * z_imag + c_imag
		z_real = new_real
		z_imag = new_imag
		iterations += 1
	
	return iterations

func setup_materials():
	update_fractal_colors()

func update_fractal_colors():
	for point_data in fractal_points:
		var material = StandardMaterial3D.new()
		var normalized_iter = float(point_data.iterations) / max_iterations
		
		if point_data.iterations >= max_iterations:
			# In the set - black
			material.albedo_color = Color(0.1, 0.1, 0.1, 1.0)
		else:
			# Outside the set - colorful gradient
			var hue = normalized_iter * 360.0
			material.albedo_color = Color.from_hsv(hue / 360.0, 0.8, 1.0)
		
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		point_data.object.material_override = material

func _process(delta):
	time += delta
	
	# Animate zoom
	zoom = 1.0 + sin(time * 0.5) * 0.8
	
	# Regenerate periodically for zoom animation
	if int(time * 2) % 2 == 0:
		generate_mandelbrot()
	
	animate_fractal()
	animate_indicators()

func animate_fractal():
	for i in range(fractal_points.size()):
		var point_data = fractal_points[i]
		var wave = sin(time * 3.0 + i * 0.01) * 0.1
		point_data.object.scale = Vector3.ONE * (1.0 + wave)

func animate_indicators():
	# Iteration control
	var iter_height = (max_iterations / 100.0) * 2.0 + 0.5
	$IterationControl.size.y = iter_height
	$IterationControl.position.y = -3 + iter_height/2
	
	# Zoom level
	var zoom_height = (zoom / 2.0) * 2.0 + 0.5
	$ZoomLevel.size.y = zoom_height
	$ZoomLevel.position.y = -3 + zoom_height/2

