extends Node3D

# Random Transformations Visualization
# Demonstrates stochastic geometric operations and random matrix applications

var time := 0.0
var transform_timer := 0.0

# Transformation objects
var base_objects := []
var transformed_objects := []

# Random transformation parameters
var rotation_variance := PI / 4
var scale_variance := 0.5
var translation_variance := 2.0
var noise_amplitude := 1.0

func _ready():
	initialize_base_objects()

func _process(delta):
	time += delta
	transform_timer += delta
	
	apply_geometric_transforms()
	demonstrate_stochastic_operations()
	show_random_matrices()
	create_noise_based_distortion()

func initialize_base_objects():
	# Create base geometric objects for transformation
	base_objects = [
		{"type": "box", "size": Vector3(1, 1, 1)},
		{"type": "sphere", "radius": 0.5},
		{"type": "cylinder", "radius": 0.4, "height": 1.0},
		{"type": "cone", "radius": 0.5, "height": 1.2}
	]

func apply_geometric_transforms():
	var container = get_node_or_null("GeometricTransforms")
	if container == null:
		return
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create original and transformed versions
	for i in range(base_objects.size()):
		var obj_data = base_objects[i]
		
		# Original object
		var original = create_object(obj_data)
		original.position = Vector3(i * 2.0 - base_objects.size(), 2, 0)
		
		var original_material = StandardMaterial3D.new()
		original_material.albedo_color = Color(0.3, 0.7, 1.0, 0.7)
		original_material.flags_transparent = true
		original.material_override = original_material
		
		container.add_child(original)
		
		# Randomly transformed object
		var transformed = create_object(obj_data)
		apply_random_transform(transformed, i)
		transformed.position = Vector3(i * 2.0 - base_objects.size(), -2, 0)
		
		var transform_material = StandardMaterial3D.new()
		transform_material.albedo_color = Color(1.0, 0.5, 0.2)
		transform_material.emission_enabled = true
		transform_material.emission = Color(1.0, 0.5, 0.2) * 0.3
		transformed.material_override = transform_material
		
		container.add_child(transformed)
		
		# Connection line showing transformation
		var connection = CSGCylinder3D.new()
		connection.radius = 0.02
		
		connection.height = 4.0
		connection.position = Vector3(i * 2.0 - base_objects.size(), 0, 0)
		
		var conn_material = StandardMaterial3D.new()
		conn_material.albedo_color = Color(0.8, 0.8, 0.8, 0.5)
		conn_material.flags_transparent = true
		connection.material_override = conn_material
		
		container.add_child(connection)

func create_object(obj_data: Dictionary) -> CSGPrimitive3D:
	match obj_data.type:
		"box":
			var box = CSGBox3D.new()
			box.size = obj_data.size
			return box
		"sphere":
			var sphere = CSGSphere3D.new()
			sphere.radius = obj_data.radius
			return sphere
		"cylinder":
			var cylinder = CSGCylinder3D.new()
			cylinder.radius = obj_data.radius
			cylinder.height = obj_data.height
			return cylinder
		"cone":
			var cone = CSGCylinder3D.new()
			#cone.radius = 0.0
			cone.radius = obj_data.radius
			cone.height = obj_data.height
			return cone
		_:
			return CSGBox3D.new()

func apply_random_transform(object: Node3D, seed_offset: int):
	# Seed random number generator for consistent but varied results
	var rng = RandomNumberGenerator.new()
	rng.seed = int(time * 10) + seed_offset
	
	# Random rotation
	object.rotation = Vector3(
		rng.randf_range(-rotation_variance, rotation_variance),
		rng.randf_range(-rotation_variance, rotation_variance),
		rng.randf_range(-rotation_variance, rotation_variance)
	)
	
	# Random scale
	var scale_factor = rng.randf_range(1.0 - scale_variance, 1.0 + scale_variance)
	object.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Random translation offset
	object.position += Vector3(
		rng.randf_range(-translation_variance, translation_variance),
		rng.randf_range(-translation_variance, translation_variance),
		rng.randf_range(-translation_variance, translation_variance)
	) * 0.3

func demonstrate_stochastic_operations():
	var container = get_node_or_null("StochasticOperations")
	if container == null:
		return
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show different types of random operations
	var operations = ["Uniform", "Gaussian", "Exponential", "Poisson"]
	
	for i in range(operations.size()):
		var op_name = operations[i]
		
		# Create visualization for each distribution
		for j in range(20):
			var value = 0.0
			
			match op_name:
				"Uniform":
					value = randf()
				"Gaussian":
					value = gaussian_random()
				"Exponential":
					value = exponential_random(2.0)
				"Poisson":
					value = float(poisson_random(3.0)) / 10.0
			
			var sample_sphere = CSGSphere3D.new()
			sample_sphere.radius = 0.1
			sample_sphere.position = Vector3(
				i * 3.0 - operations.size() * 1.5,
				value * 4.0 - 2.0,
				(j - 10) * 0.2
			)
			
			var material = StandardMaterial3D.new()
			var color_hue = float(i) / operations.size()
			material.albedo_color = Color.from_hsv(color_hue, 0.8, 1.0)
			material.emission_enabled = true
			material.emission = Color.from_hsv(color_hue, 0.8, 1.0) * 0.4
			sample_sphere.material_override = material
			
			container.add_child(sample_sphere)
		
		# Operation label
		var label_box = CSGBox3D.new()
		label_box.size = Vector3(2.0, 0.3, 0.3)
		label_box.position = Vector3(i * 3.0 - operations.size() * 1.5, -3, 0)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label_box.material_override = label_material
		
		container.add_child(label_box)

func gaussian_random() -> float:
	# Box-Muller transform for Gaussian distribution
	var has_spare = false
	var spare = 0.0
	
	if has_spare:
		has_spare = false
		return spare
	
	has_spare = true
	var u = randf()
	var v = randf()
	var magnitude = sqrt(-2.0 * log(u))
	spare = magnitude * cos(2.0 * PI * v)
	return magnitude * sin(2.0 * PI * v)

func exponential_random(lambda: float) -> float:
	return -log(1.0 - randf()) / lambda

func poisson_random(lambda: float) -> int:
	var L = exp(-lambda)
	var k = 0
	var p = 1.0
	
	while p > L:
		k += 1
		p *= randf()
	
	return k - 1

func show_random_matrices():
	var container = get_node_or_null("RandomMatrices")
	if container == null:
		return
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create random matrix transformations
	var matrix_size = 4
	
	for i in range(matrix_size):
		for j in range(matrix_size):
			var element_value = randf_range(-1.0, 1.0)
			
			var matrix_element = CSGBox3D.new()
			matrix_element.size = Vector3(0.6, abs(element_value) * 2.0 + 0.1, 0.6)
			matrix_element.position = Vector3(
				i * 0.8 - matrix_size * 0.4,
				element_value,
				j * 0.8 - matrix_size * 0.4
			)
			
			var material = StandardMaterial3D.new()
			if element_value > 0:
				material.albedo_color = Color(0.2, 1.0, 0.2)
				material.emission_enabled = true
				material.emission = Color(0.2, 1.0, 0.2) * element_value
			else:
				material.albedo_color = Color(1.0, 0.2, 0.2)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.2, 0.2) * abs(element_value)
			
			matrix_element.material_override = material
			container.add_child(matrix_element)
	
	# Show matrix determinant visualization
	var det_indicator = CSGSphere3D.new()
	det_indicator.radius = 0.5 + sin(time * 2) * 0.2
	det_indicator.position = Vector3(0, 3, 0)
	
	var det_material = StandardMaterial3D.new()
	det_material.albedo_color = Color(1.0, 1.0, 0.0)
	det_material.emission_enabled = true
	det_material.emission = Color(1.0, 1.0, 0.0) * 0.6
	det_indicator.material_override = det_material
	
	container.add_child(det_indicator)

func create_noise_based_distortion():
	var container = get_node_or_null("NoiseBasedDistortion")
	if container == null:
		return
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create grid of objects with noise-based distortion
	var grid_size = 8
	var noise_scale = 0.1
	
	for i in range(grid_size):
		for j in range(grid_size):
			var base_pos = Vector3(
				i - grid_size * 0.5,
				0,
				j - grid_size * 0.5
			)
			
			# Apply various noise functions
			var perlin_offset = Vector3(
				noise_perlin(base_pos.x * noise_scale, base_pos.z * noise_scale, time * 0.5),
				noise_perlin(base_pos.x * noise_scale + 100, base_pos.z * noise_scale + 100, time * 0.5),
				noise_perlin(base_pos.x * noise_scale + 200, base_pos.z * noise_scale + 200, time * 0.5)
			) * noise_amplitude
			
			var distorted_pos = base_pos + perlin_offset
			
			var noise_cube = CSGBox3D.new()
			noise_cube.size = Vector3(0.3, 0.3, 0.3)
			noise_cube.position = distorted_pos
			
			var material = StandardMaterial3D.new()
			var distortion_magnitude = perlin_offset.length()
			material.albedo_color = Color.from_hsv(distortion_magnitude * 0.5, 0.8, 1.0)
			material.emission_enabled = true
			material.emission = Color.from_hsv(distortion_magnitude * 0.5, 0.8, 1.0) * 0.3
			noise_cube.material_override = material
			
			container.add_child(noise_cube)
			
			# Show displacement vector
			if perlin_offset.length() > 0.1:
				var displacement_line = CSGCylinder3D.new()
				displacement_line.radius = 0.02
				
				displacement_line.height = perlin_offset.length()
				
				displacement_line.position = base_pos + perlin_offset * 0.5
				displacement_line.look_at(base_pos + perlin_offset, Vector3.UP)
				displacement_line.rotate_object_local(Vector3.RIGHT, PI / 2)
				
				var line_material = StandardMaterial3D.new()
				line_material.albedo_color = Color(1.0, 0.5, 0.0, 0.7)
				line_material.flags_transparent = true
				displacement_line.material_override = line_material
				
				container.add_child(displacement_line)

func noise_perlin(x: float, y: float, z: float) -> float:
	# Simplified Perlin noise implementation
	var xi = int(x) & 255
	var yi = int(y) & 255
	var zi = int(z) & 255
	
	var xf = x - floor(x)
	var yf = y - floor(y)
	var zf = z - floor(z)
	
	var u = fade(xf)
	var v = fade(yf)
	var w = fade(zf)
	
	var aaa = hash3d(xi, yi, zi)
	var aba = hash3d(xi, yi + 1, zi)
	var aab = hash3d(xi, yi, zi + 1)
	var abb = hash3d(xi, yi + 1, zi + 1)
	var baa = hash3d(xi + 1, yi, zi)
	var bba = hash3d(xi + 1, yi + 1, zi)
	var bab = hash3d(xi + 1, yi, zi + 1)
	var bbb = hash3d(xi + 1, yi + 1, zi + 1)
	
	var x1 = lerp(grad3d(aaa, xf, yf, zf), grad3d(baa, xf - 1, yf, zf), u)
	var x2 = lerp(grad3d(aba, xf, yf - 1, zf), grad3d(bba, xf - 1, yf - 1, zf), u)
	var y1 = lerp(x1, x2, v)
	
	x1 = lerp(grad3d(aab, xf, yf, zf - 1), grad3d(bab, xf - 1, yf, zf - 1), u)
	x2 = lerp(grad3d(abb, xf, yf - 1, zf - 1), grad3d(bbb, xf - 1, yf - 1, zf - 1), u)
	var y2 = lerp(x1, x2, v)
	
	return lerp(y1, y2, w)

func fade(t: float) -> float:
	return t * t * t * (t * (t * 6 - 15) + 10)

func hash3d(x: int, y: int, z: int) -> int:
	var hash = x + y * 57 + z * 123
	hash = (hash << 13) ^ hash
	return (hash * (hash * hash * 15731 + 789221) + 1376312589) & 0x7fffffff

func grad3d(hash: int, x: float, y: float, z: float) -> float:
	var h = hash & 15
	var u = x if h < 8 else y
	var v = y if h < 4 else (x if h == 12 or h == 14 else z)
	return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)
