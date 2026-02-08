extends Node3D

# TRNG vs PRNG Comparison
# Demonstrates true vs pseudo-random number generation

var time := 0.0
var sample_timer := 0.0

# Random number generators
var prng_seed := 12345
var prng_state := 0
var trng_buffer := []
var prng_buffer := []

# Statistical analysis
var trng_samples := []
var prng_samples := []
var entropy_history := []

@export var show_visual_frames := true
@export var frame_back_color := Color(0.06, 0.08, 0.12, 0.9)
@export var frame_border_color := Color(0.72, 0.8, 0.95, 1.0)
@export var frame_border_thickness := 0.08
@export var frame_depth := 0.03

func _ready():
	initialize_generators()
	_setup_visual_frames()

func _process(delta):
	time += delta
	sample_timer += delta
	
	if sample_timer > 0.1:
		sample_timer = 0.0
		collect_samples()
	
	visualize_true_random()
	visualize_pseudo_random()
	show_statistical_comparison()
	demonstrate_entropy_visualization()

func initialize_generators():
	prng_state = prng_seed
	trng_buffer.clear()
	prng_buffer.clear()
	trng_samples.clear()
	prng_samples.clear()

func collect_samples():
	# Collect TRNG sample (simulated)
	var trng_sample = simulate_true_random()
	trng_buffer.append(trng_sample)
	trng_samples.append(trng_sample)
	
	# Collect PRNG sample
	var prng_sample = generate_pseudo_random()
	prng_buffer.append(prng_sample)
	prng_samples.append(prng_sample)
	
	# Limit buffer sizes
	if trng_buffer.size() > 100:
		trng_buffer.remove_at(0)
	if prng_buffer.size() > 100:
		prng_buffer.remove_at(0)
	
	# Limit sample history
	if trng_samples.size() > 1000:
		trng_samples.remove_at(0)
	if prng_samples.size() > 1000:
		prng_samples.remove_at(0)

func simulate_true_random() -> float:
	# Simulate TRNG using multiple entropy sources
	var quantum_noise = quantum_fluctuation()
	var thermal_noise = thermal_fluctuation()
	var atmospheric_noise = atmospheric_fluctuation()
	var timing_jitter = system_timing_jitter()
	
	# Combine entropy sources
	var combined_entropy = (quantum_noise + thermal_noise + atmospheric_noise + timing_jitter) / 4.0
	return fmod(combined_entropy * 1000000.0, 1.0)

func quantum_fluctuation() -> float:
	# Simulate quantum randomness
	return randf()  # In reality, this would be from quantum measurement

func thermal_fluctuation() -> float:
	# Simulate thermal noise
	var thermal_energy = sin(time * 137.3) + cos(time * 241.7) + sin(time * 383.1)
	return fmod(abs(thermal_energy), 1.0)

func atmospheric_fluctuation() -> float:
	# Simulate atmospheric radio noise
	return fmod(sin(time * 1000.0 + randf() * 100.0), 1.0)

func system_timing_jitter() -> float:
	# Simulate system timing variations
	return fmod(Time.get_ticks_msec() * 0.001, 1.0)

func generate_pseudo_random() -> float:
	# Linear Congruential Generator (LCG)
	prng_state = (prng_state * 1664525 + 1013904223) % (2**32)
	return float(prng_state) / float(2**32)

func visualize_true_random():
	var container = $TrueRandomGenerator
	
	# Clear previous visualization
	_clear_dynamic_children(container)
	
	# Show entropy sources
	var entropy_sources = ["Quantum", "Thermal", "Atmospheric", "Timing"]
	var entropy_values = [
		quantum_fluctuation(),
		thermal_fluctuation(),
		atmospheric_fluctuation(),
		system_timing_jitter()
	]
	
	for i in range(entropy_sources.size()):
		var source_sphere = CSGSphere3D.new()
		source_sphere.radius = 0.3 + entropy_values[i] * 0.3
		source_sphere.position = Vector3(
			cos(float(i) / entropy_sources.size() * TAU) * 2.0,
			sin(float(i) / entropy_sources.size() * TAU) * 2.0,
			0
		)
		
		var material = StandardMaterial3D.new()
		var hue = float(i) / entropy_sources.size()
		material.albedo_color = Color.from_hsv(hue, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(hue, 0.8, 1.0) * entropy_values[i]
		source_sphere.material_override = material
		
		container.add_child(source_sphere)
		
		# Connect to center (entropy combiner)
		var connection = CSGCylinder3D.new()
		connection.radius = 0.02
		
		connection.height = 2.0
		connection.position = source_sphere.position * 0.5
		var to_center: Vector3 = Vector3.ZERO - connection.position
		var up_axis: Vector3 = Vector3.UP
		if to_center.length() > 0.0001:
			var direction: Vector3 = to_center.normalized()
			if abs(direction.dot(Vector3.UP)) > 0.98:
				up_axis = Vector3.FORWARD
		connection.look_at_from_position(connection.position, Vector3.ZERO, up_axis)
		connection.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var conn_material = StandardMaterial3D.new()
		conn_material.albedo_color = Color(0.8, 0.8, 0.8, 0.5)
		conn_material.flags_transparent = true
		connection.material_override = conn_material
		
		container.add_child(connection)
	
	# Central entropy combiner
	var combiner = CSGSphere3D.new()
	combiner.radius = 0.4
	combiner.position = Vector3.ZERO
	
	var combiner_material = StandardMaterial3D.new()
	combiner_material.albedo_color = Color(1.0, 1.0, 1.0)
	combiner_material.emission_enabled = true
	combiner_material.emission = Color(1.0, 1.0, 1.0) * 0.5
	combiner.material_override = combiner_material
	
	container.add_child(combiner)
	
	# Show recent TRNG output
	show_random_output(container, trng_buffer, Vector3(0, -3, 0), Color.GREEN)

func visualize_pseudo_random():
	var container = $PseudoRandomGenerator
	
	# Clear previous visualization
	_clear_dynamic_children(container)
	
	# Show PRNG algorithm structure (LCG)
	var algorithm_steps = ["Seed", "Multiply", "Add", "Modulo", "Output"]
	
	for i in range(algorithm_steps.size()):
		var step_box = CSGBox3D.new()
		step_box.size = Vector3(1.0, 0.6, 0.6)
		step_box.position = Vector3(0, i * 1.0 - 2.0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		material.metallic = 0.3
		material.roughness = 0.4
		step_box.material_override = material
		
		container.add_child(step_box)
		
		# Arrow between steps
		if i < algorithm_steps.size() - 1:
			var arrow = CSGCylinder3D.new()
			arrow.radius = 0.0
			arrow.height = 0.3
			arrow.position = Vector3(0, i * 1.0 - 1.5, 0)
			arrow.rotation_degrees = Vector3(180, 0, 0)
			
			var arrow_material = StandardMaterial3D.new()
			arrow_material.albedo_color = Color(1.0, 0.5, 0.0)
			arrow.material_override = arrow_material
			
			container.add_child(arrow)
	
	# Show deterministic nature with state visualization
	var state_display = CSGSphere3D.new()
	state_display.radius = 0.3
	state_display.position = Vector3(2, 0, 0)
	
	var state_material = StandardMaterial3D.new()
	var state_ratio = float(prng_state % 1000) / 1000.0
	state_material.albedo_color = Color.from_hsv(state_ratio, 0.8, 1.0)
	state_material.emission_enabled = true
	state_material.emission = Color.from_hsv(state_ratio, 0.8, 1.0) * 0.4
	state_display.material_override = state_material
	
	container.add_child(state_display)
	
	# Show recent PRNG output
	show_random_output(container, prng_buffer, Vector3(0, -3, 0), Color.CYAN)

func show_random_output(container: Node3D, buffer: Array, base_pos: Vector3, color: Color):
	# Visualize recent random values
	for i in range(min(20, buffer.size())):
		var value = buffer[buffer.size() - 1 - i]
		
		var output_cube = CSGBox3D.new()
		output_cube.size = Vector3(0.15, value * 2.0 + 0.1, 0.15)
		output_cube.position = base_pos + Vector3(
			i * 0.2 - 2.0,
			output_cube.size.y * 0.5,
			0
		)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * value
		output_cube.material_override = material
		
		container.add_child(output_cube)

func show_statistical_comparison():
	var container = $StatisticalComparison
	
	# Clear previous visualization
	_clear_dynamic_children(container)
	
	if trng_samples.size() < 50 or prng_samples.size() < 50:
		return
	
	# Calculate statistics
	var trng_stats = calculate_statistics(trng_samples)
	var prng_stats = calculate_statistics(prng_samples)
	
	# Visualize statistical tests
	var tests = ["Mean", "Variance", "Chi-Square", "Runs Test"]
	var trng_results = [trng_stats.mean, trng_stats.variance, trng_stats.chi_square, trng_stats.runs_test]
	var prng_results = [prng_stats.mean, prng_stats.variance, prng_stats.chi_square, prng_stats.runs_test]
	
	for i in range(tests.size()):
		# TRNG result
		var trng_bar = CSGBox3D.new()
		trng_bar.size = Vector3(0.4, trng_results[i] * 3.0 + 0.1, 0.4)
		trng_bar.position = Vector3(i * 2.0 - 3.0, trng_bar.size.y * 0.5, -0.5)
		
		var trng_material = StandardMaterial3D.new()
		trng_material.albedo_color = Color(0.2, 1.0, 0.2)
		trng_material.emission_enabled = true
		trng_material.emission = Color(0.2, 1.0, 0.2) * 0.3
		trng_bar.material_override = trng_material
		
		container.add_child(trng_bar)
		
		# PRNG result
		var prng_bar = CSGBox3D.new()
		prng_bar.size = Vector3(0.4, prng_results[i] * 3.0 + 0.1, 0.4)
		prng_bar.position = Vector3(i * 2.0 - 3.0, prng_bar.size.y * 0.5, 0.5)
		
		var prng_material = StandardMaterial3D.new()
		prng_material.albedo_color = Color(0.2, 0.2, 1.0)
		prng_material.emission_enabled = true
		prng_material.emission = Color(0.2, 0.2, 1.0) * 0.3
		prng_bar.material_override = prng_material
		
		container.add_child(prng_bar)
		
		# Test label
		var label = CSGBox3D.new()
		label.size = Vector3(1.5, 0.2, 0.2)
		label.position = Vector3(i * 2.0 - 3.0, -1.0, 0)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label.material_override = label_material
		
		container.add_child(label)

func calculate_statistics(samples: Array) -> Dictionary:
	var stats = {}
	
	# Mean
	var sum = 0.0
	for sample in samples:
		sum += sample
	stats.mean = sum / samples.size()
	
	# Variance
	var variance_sum = 0.0
	for sample in samples:
		variance_sum += pow(sample - stats.mean, 2)
	stats.variance = variance_sum / samples.size()
	
	# Chi-square test (simplified)
	var bins = [0, 0, 0, 0, 0]
	for sample in samples:
		var bin_index = int(sample * bins.size())
		if bin_index >= bins.size():
			bin_index = bins.size() - 1
		bins[bin_index] += 1
	
	var expected = float(samples.size()) / bins.size()
	var chi_square = 0.0
	for observed in bins:
		chi_square += pow(observed - expected, 2) / expected
	stats.chi_square = chi_square / 10.0  # Normalize for visualization
	
	# Runs test (simplified)
	var runs = 0
	var above_median = false
	var prev_above_median = false
	
	for i in range(samples.size()):
		above_median = samples[i] > stats.mean
		if i > 0 and above_median != prev_above_median:
			runs += 1
		prev_above_median = above_median
	
	stats.runs_test = float(runs) / samples.size()
	
	return stats

func demonstrate_entropy_visualization():
	var container = $EntropyVisualization
	
	# Clear previous visualization
	_clear_dynamic_children(container)
	
	# Calculate entropy for both sources
	var trng_entropy = calculate_entropy(trng_samples)
	var prng_entropy = calculate_entropy(prng_samples)
	
	# Visualize entropy levels
	var entropy_sphere_trng = CSGSphere3D.new()
	entropy_sphere_trng.radius = trng_entropy + 0.1
	entropy_sphere_trng.position = Vector3(-2, 0, 0)
	
	var trng_entropy_material = StandardMaterial3D.new()
	trng_entropy_material.albedo_color = Color(0.2, 1.0, 0.2, 0.7)
	trng_entropy_material.flags_transparent = true
	trng_entropy_material.emission_enabled = true
	trng_entropy_material.emission = Color(0.2, 1.0, 0.2) * trng_entropy
	entropy_sphere_trng.material_override = trng_entropy_material
	
	container.add_child(entropy_sphere_trng)
	
	var entropy_sphere_prng = CSGSphere3D.new()
	entropy_sphere_prng.radius = prng_entropy + 0.1
	entropy_sphere_prng.position = Vector3(2, 0, 0)
	
	var prng_entropy_material = StandardMaterial3D.new()
	prng_entropy_material.albedo_color = Color(0.2, 0.2, 1.0, 0.7)
	prng_entropy_material.flags_transparent = true
	prng_entropy_material.emission_enabled = true
	prng_entropy_material.emission = Color(0.2, 0.2, 1.0) * prng_entropy
	entropy_sphere_prng.material_override = prng_entropy_material
	
	container.add_child(entropy_sphere_prng)
	
	# Show entropy history
	entropy_history.append({"trng": trng_entropy, "prng": prng_entropy})
	if entropy_history.size() > 50:
		entropy_history.remove_at(0)
	
	# Visualize entropy history
	for i in range(entropy_history.size() - 1):
		var history_data = entropy_history[i]
		
		# TRNG entropy line
		var trng_segment = CSGCylinder3D.new()
		trng_segment.radius = 0.02
		
		trng_segment.height = 0.1
		trng_segment.position = Vector3(
			i * 0.1 - entropy_history.size() * 0.05,
			history_data.trng * 2.0 - 3.0,
			-1.0
		)
		
		var trng_segment_material = StandardMaterial3D.new()
		trng_segment_material.albedo_color = Color(0.2, 1.0, 0.2)
		trng_segment.material_override = trng_segment_material
		
		container.add_child(trng_segment)
		
		# PRNG entropy line
		var prng_segment = CSGCylinder3D.new()
		prng_segment.radius = 0.02
		
		prng_segment.height = 0.1
		prng_segment.position = Vector3(
			i * 0.1 - entropy_history.size() * 0.05,
			history_data.prng * 2.0 - 3.0,
			1.0
		)
		
		var prng_segment_material = StandardMaterial3D.new()
		prng_segment_material.albedo_color = Color(0.2, 0.2, 1.0)
		prng_segment.material_override = prng_segment_material
		
		container.add_child(prng_segment)

func calculate_entropy(samples: Array) -> float:
	if samples.size() < 10:
		return 0.0
	
	# Simple entropy calculation using binning
	var bins = {}
	var bin_count = 10
	
	for sample in samples:
		var bin = int(sample * bin_count)
		if bin >= bin_count:
			bin = bin_count - 1
		
		if bin in bins:
			bins[bin] += 1
		else:
			bins[bin] = 1
	
	# Calculate entropy
	var entropy = 0.0
	var total_samples = samples.size()
	
	for bin in bins:
		var probability = float(bins[bin]) / total_samples
		if probability > 0:
			entropy -= probability * log(probability) / log(2)
	
	return entropy / log(bin_count) / log(2)  # Normalize to 0-1

func _clear_dynamic_children(container: Node3D) -> void:
	for child in container.get_children():
		if child.get_meta("persistent_frame", false):
			continue
		child.queue_free()

func _setup_visual_frames() -> void:
	if not show_visual_frames:
		return
	_create_panel_frame($TrueRandomGenerator, "TrueRandomFrame", Vector3(0, -0.4, -0.18), Vector2(6.4, 6.8))
	_create_panel_frame($PseudoRandomGenerator, "PseudoRandomFrame", Vector3(0, -0.4, -0.18), Vector2(6.0, 6.8))

func _create_panel_frame(parent: Node3D, root_name: String, center: Vector3, panel_size: Vector2) -> void:
	if parent.get_node_or_null(root_name):
		return

	var root := Node3D.new()
	root.name = root_name
	root.set_meta("persistent_frame", true)
	parent.add_child(root)

	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = frame_back_color
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = frame_border_color
	border_mat.emission_enabled = true
	border_mat.emission = frame_border_color * 0.25
	border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var half_w := panel_size.x * 0.5
	var half_h := panel_size.y * 0.5
	var half_t := frame_border_thickness * 0.5

	_add_frame_piece(
		root,
		"Back",
		center,
		Vector3(panel_size.x, panel_size.y, frame_depth),
		back_mat
	)
	_add_frame_piece(
		root,
		"Top",
		center + Vector3(0, half_h - half_t, 0),
		Vector3(panel_size.x, frame_border_thickness, frame_depth),
		border_mat
	)
	_add_frame_piece(
		root,
		"Bottom",
		center + Vector3(0, -half_h + half_t, 0),
		Vector3(panel_size.x, frame_border_thickness, frame_depth),
		border_mat
	)
	_add_frame_piece(
		root,
		"Left",
		center + Vector3(-half_w + half_t, 0, 0),
		Vector3(frame_border_thickness, panel_size.y, frame_depth),
		border_mat
	)
	_add_frame_piece(
		root,
		"Right",
		center + Vector3(half_w - half_t, 0, 0),
		Vector3(frame_border_thickness, panel_size.y, frame_depth),
		border_mat
	)

func _add_frame_piece(parent: Node3D, name: String, position: Vector3, size_vec: Vector3, material: Material) -> void:
	var piece := MeshInstance3D.new()
	piece.name = name
	var mesh := BoxMesh.new()
	mesh.size = size_vec
	piece.mesh = mesh
	piece.material_override = material
	piece.position = position
	piece.set_meta("persistent_frame", true)
	parent.add_child(piece)
