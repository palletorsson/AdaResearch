extends Node3D

# Digital Materiality & Glitch Visualization
# Demonstrates error as aesthetic and digital artifact generation

var time := 0.0
var glitch_timer := 0.0
var corruption_rate := 0.05

# Glitch parameters
var glitch_intensity := 0.3
var artifact_probability := 0.1
var error_propagation_speed := 2.0

# Digital structures
var data_grid := []
var corrupted_elements := []
var error_cascade := []

func _ready():
	initialize_digital_structures()

func _process(delta):
	time += delta
	glitch_timer += delta
	
	update_glitch_parameters()
	create_glitch_aesthetics()
	simulate_data_corruption()
	generate_digital_artifacts()
	show_error_propagation()

func initialize_digital_structures():
	# Initialize data grid
	data_grid.clear()
	for i in range(8):
		var row = []
		for j in range(8):
			row.append({"intact": true, "value": randi() % 256, "corruption_age": 0.0})
		data_grid.append(row)

func update_glitch_parameters():
	# Animate glitch parameters
	glitch_intensity = 0.2 + sin(time * 0.4) * 0.3
	artifact_probability = 0.05 + cos(time * 0.6) * 0.04
	error_propagation_speed = 1.5 + sin(time * 0.8) * 1.0

func create_glitch_aesthetics():
	var container = $GlitchAesthetics
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create glitch aesthetic elements
	var glitch_patterns = ["datamosh", "pixel_sort", "channel_shift", "compression"]
	
	for i in range(glitch_patterns.size()):
		var pattern_name = glitch_patterns[i]
		
		# Create glitch visualization for each pattern
		create_glitch_pattern(container, pattern_name, i)

func create_glitch_pattern(container: Node3D, pattern_name: String, index: int):
	var base_pos = Vector3(index * 3.0 - 6.0, 0, 0)
	
	match pattern_name:
		"datamosh":
			create_datamosh_effect(container, base_pos)
		"pixel_sort":
			create_pixel_sort_effect(container, base_pos)
		"channel_shift":
			create_channel_shift_effect(container, base_pos)
		"compression":
			create_compression_artifact_effect(container, base_pos)

func create_datamosh_effect(container: Node3D, base_pos: Vector3):
	# Datamoshing - motion vector corruption
	for i in range(16):
		var motion_vector = CSGCylinder3D.new()
		motion_vector.radius = 0.05
		
		motion_vector.height = randf_range(0.5, 2.0)
		
		var original_pos = base_pos + Vector3(
			(i % 4) * 0.4 - 0.6,
			0,
			(i / 4) * 0.4 - 0.6
		)
		
		# Apply glitch displacement
		var glitch_offset = Vector3(
			sin(time * 3 + i) * glitch_intensity,
			cos(time * 2 + i) * glitch_intensity,
			sin(time * 4 + i) * glitch_intensity * 0.5
		)
		
		motion_vector.position = original_pos + glitch_offset
		motion_vector.rotation = Vector3(
			randf() * PI,
			randf() * PI,
			randf() * PI
		)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.2, 0.8, 0.7)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.2, 0.8) * 0.5
		motion_vector.material_override = material
		
		container.add_child(motion_vector)

func create_pixel_sort_effect(container: Node3D, base_pos: Vector3):
	# Pixel sorting glitch
	var pixel_heights = []
	for i in range(12):
		pixel_heights.append(randf())
	
	# Sort some pixels randomly to create glitch effect
	if randf() < glitch_intensity:
		var start_idx = randi() % (pixel_heights.size() - 3)
		var end_idx = start_idx + 3
		var segment = pixel_heights.slice(start_idx, end_idx)
		segment.sort()
		for i in range(segment.size()):
			pixel_heights[start_idx + i] = segment[i]
	
	for i in range(pixel_heights.size()):
		var pixel = CSGBox3D.new()
		pixel.size = Vector3(0.2, pixel_heights[i] * 2.0, 0.2)
		pixel.position = base_pos + Vector3(
			i * 0.25 - 1.5,
			pixel_heights[i],
			0
		)
		
		var material = StandardMaterial3D.new()
		var sorted_color = pixel_heights[i]
		material.albedo_color = Color(sorted_color, 1.0 - sorted_color, 0.5)
		material.emission_enabled = true
		material.emission = Color(sorted_color, 1.0 - sorted_color, 0.5) * 0.3
		pixel.material_override = material
		
		container.add_child(pixel)

func create_channel_shift_effect(container: Node3D, base_pos: Vector3):
	# RGB channel separation glitch
	var channels = ["R", "G", "B"]
	var offsets = [
		Vector3(0.1, 0, 0) * glitch_intensity,
		Vector3(0, 0, 0),
		Vector3(-0.1, 0, 0) * glitch_intensity
	]
	
	for channel_idx in range(channels.size()):
		for i in range(9):
			var channel_cube = CSGBox3D.new()
			channel_cube.size = Vector3(0.15, 0.15, 0.15)
			channel_cube.position = base_pos + Vector3(
				(i % 3) * 0.3 - 0.3,
				(i / 3) * 0.3 - 0.3,
				channel_idx * 0.1 - 0.1
			) + offsets[channel_idx]
			
			var material = StandardMaterial3D.new()
			match channels[channel_idx]:
				"R":
					material.albedo_color = Color(1.0, 0.0, 0.0, 0.8)
				"G":
					material.albedo_color = Color(0.0, 1.0, 0.0, 0.8)
				"B":
					material.albedo_color = Color(0.0, 0.0, 1.0, 0.8)
			
			material.flags_transparent = true
			material.emission_enabled = true
			material.emission = material.albedo_color * 0.4
			channel_cube.material_override = material
			
			container.add_child(channel_cube)

func create_compression_artifact_effect(container: Node3D, base_pos: Vector3):
	# Compression artifacts - blocky patterns
	var block_size = 4
	
	for i in range(block_size):
		for j in range(block_size):
			var compression_block = CSGBox3D.new()
			compression_block.size = Vector3(0.4, 0.4, 0.4)
			compression_block.position = base_pos + Vector3(
				i * 0.5 - 0.75,
				0,
				j * 0.5 - 0.75
			)
			
			# Add compression artifacts
			var artifact_intensity = 0.0
			if randf() < artifact_probability:
				artifact_intensity = 1.0
				compression_block.scale *= 1.0 + glitch_intensity
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(
				0.5 + artifact_intensity * 0.5,
				0.5,
				0.5 + artifact_intensity * 0.5
			)
			
			if artifact_intensity > 0:
				material.emission_enabled = true
				material.emission = Color(1.0, 0.0, 1.0) * 0.6
			
			compression_block.material_override = material
			container.add_child(compression_block)

func simulate_data_corruption():
	var container = $DataCorruption
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update data corruption
	if glitch_timer > 0.1:
		glitch_timer = 0.0
		propagate_corruption()
	
	# Visualize data grid with corruption
	for i in range(data_grid.size()):
		for j in range(data_grid[i].size()):
			var cell_data = data_grid[i][j]
			
			var data_cube = CSGBox3D.new()
			data_cube.size = Vector3(0.4, 0.4, 0.4)
			data_cube.position = Vector3(
				i * 0.5 - data_grid.size() * 0.25,
				0,
				j * 0.5 - data_grid[i].size() * 0.25
			)
			
			var material = StandardMaterial3D.new()
			
			if cell_data.intact:
				# Intact data
				var value_ratio = float(cell_data.value) / 255.0
				material.albedo_color = Color(0.2, value_ratio, 0.8)
			else:
				# Corrupted data
				var corruption_age = cell_data.corruption_age
				material.albedo_color = Color(1.0, 0.2, 0.2)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.2, 0.2) * (1.0 - corruption_age * 0.1)
				
				# Add glitch effects
				data_cube.scale *= 1.0 + sin(time * 10 + i + j) * 0.2
				data_cube.rotation = Vector3(
					sin(time * 5 + i) * 0.5,
					cos(time * 7 + j) * 0.5,
					sin(time * 3 + i + j) * 0.3
				)
			
			data_cube.material_override = material
			container.add_child(data_cube)

func propagate_corruption():
	# Randomly corrupt data elements
	for i in range(data_grid.size()):
		for j in range(data_grid[i].size()):
			var cell = data_grid[i][j]
			
			if cell.intact and randf() < corruption_rate * glitch_intensity:
				cell.intact = false
				cell.corruption_age = 0.0
				corrupted_elements.append(Vector2(i, j))
			
			if not cell.intact:
				cell.corruption_age += 0.1

func generate_digital_artifacts():
	var container = $DigitalArtifacts
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create various digital artifacts
	create_scan_lines(container)
	create_chromatic_aberration(container)
	create_digital_noise(container)
	create_buffer_overflow_artifacts(container)

func create_scan_lines(container: Node3D):
	# Retro scan line effect
	for i in range(20):
		var scan_line = CSGBox3D.new()
		scan_line.size = Vector3(8.0, 0.05, 0.1)
		scan_line.position = Vector3(0, i * 0.2 - 2.0, -2.0)
		
		var material = StandardMaterial3D.new()
		var alpha = 0.3 + sin(time * 10 + i) * 0.2
		material.albedo_color = Color(0.0, 1.0, 0.0, alpha)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(0.0, 1.0, 0.0) * alpha * 0.5
		scan_line.material_override = material
		
		container.add_child(scan_line)

func create_chromatic_aberration(container: Node3D):
	# Chromatic aberration effect
	var aberration_strength = glitch_intensity * 0.5
	
	for color_idx in range(3):
		var color_layer = CSGSphere3D.new()
		color_layer.radius = 1.0
		
		var offset = Vector3(
			(color_idx - 1) * aberration_strength,
			0,
			0
		)
		color_layer.position = Vector3(0, 0, 2) + offset
		
		var material = StandardMaterial3D.new()
		match color_idx:
			0:
				material.albedo_color = Color(1.0, 0.0, 0.0, 0.4)
			1:
				material.albedo_color = Color(0.0, 1.0, 0.0, 0.4)
			2:
				material.albedo_color = Color(0.0, 0.0, 1.0, 0.4)
		
		material.flags_transparent = true
		color_layer.material_override = material
		
		container.add_child(color_layer)

func create_digital_noise(container: Node3D):
	# Random digital noise particles
	for i in range(50):
		if randf() < artifact_probability:
			var noise_particle = CSGBox3D.new()
			noise_particle.size = Vector3(0.1, 0.1, 0.1)
			noise_particle.position = Vector3(
				randf_range(-4, 4),
				randf_range(-2, 2),
				randf_range(-1, 1)
			)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(
				randf(),
				randf(),
				randf(),
				randf_range(0.5, 1.0)
			)
			material.flags_transparent = true
			material.emission_enabled = true
			material.emission = material.albedo_color * 0.8
			noise_particle.material_override = material
			
			container.add_child(noise_particle)

func create_buffer_overflow_artifacts(container: Node3D):
	# Buffer overflow visualization
	var overflow_height = 3.0 + glitch_intensity * 2.0
	
	for i in range(10):
		var overflow_bar = CSGBox3D.new()
		overflow_bar.size = Vector3(0.3, overflow_height * randf(), 0.3)
		overflow_bar.position = Vector3(
			i * 0.4 - 2.0,
			overflow_bar.size.y * 0.5,
			3.0
		)
		
		var material = StandardMaterial3D.new()
		if overflow_bar.size.y > 2.0:
			# Overflow condition
			material.albedo_color = Color(1.0, 0.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.0, 0.0) * 0.8
		else:
			material.albedo_color = Color(0.2, 0.8, 0.2)
		
		overflow_bar.material_override = material
		container.add_child(overflow_bar)

func show_error_propagation():
	var container = $ErrorPropagation
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Simulate cascading errors
	create_error_cascade(container)
	
	# Show error propagation waves
	for i in range(5):
		var wave_radius = fmod(time * error_propagation_speed + i * 0.5, 4.0)
		
		var error_wave = CSGCylinder3D.new()
		error_wave.radius = wave_radius + 0.2
		error_wave.height = 0.1
		error_wave.position = Vector3(0, 0, 0)
		
		var material = StandardMaterial3D.new()
		var alpha = 1.0 - (wave_radius / 4.0)
		material.albedo_color = Color(1.0, 0.5, 0.0, alpha * 0.6)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.0) * alpha * 0.5
		error_wave.material_override = material
		
		container.add_child(error_wave)

func create_error_cascade(container: Node3D):
	# Error cascade visualization
	error_cascade.clear()
	
	# Start with initial error
	if error_cascade.is_empty():
		error_cascade.append({"pos": Vector3.ZERO, "age": 0.0, "intensity": 1.0})
	
	# Propagate errors
	var new_errors = []
	for error in error_cascade:
		error.age += 0.1
		error.intensity *= 0.95
		
		# Spawn new errors
		if error.age < 2.0 and randf() < 0.1:
			new_errors.append({
				"pos": error.pos + Vector3(
					randf_range(-1, 1),
					randf_range(-1, 1),
					randf_range(-1, 1)
				),
				"age": 0.0,
				"intensity": error.intensity * 0.8
			})
	
	error_cascade.append_array(new_errors)
	
	# Remove old errors
	error_cascade = error_cascade.filter(func(error): return error.age < 3.0)
	
	# Visualize error cascade
	for error in error_cascade:
		var error_sphere = CSGSphere3D.new()
		error_sphere.radius = 0.2 * error.intensity
		error_sphere.position = error.pos
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.0, 0.0, error.intensity)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.0, 0.0) * error.intensity * 0.8
		error_sphere.material_override = material
		
		container.add_child(error_sphere)
