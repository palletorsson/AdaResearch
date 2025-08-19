extends Node3D

# Interactive VR Central Limit Theorem - Sampling Distribution Demo
# Shows how sample means approach normal distribution regardless of population shape

class_name CentralLimitTheoremVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Population Settings
@export_category("Population Distribution")
@export var population_type: PopulationType = PopulationType.UNIFORM
@export var population_size: int = 10000
@export var population_min: float = 0.0
@export var population_max: float = 10.0

# Sampling Settings
@export_category("Sampling Parameters")
@export var sample_size: int = 30
@export var num_samples: int = 100
@export var auto_sample: bool = false

# Visual Settings
@export_category("Visualization")
@export var show_population: bool = true
@export var show_sample_means: bool = true
@export var animation_speed: float = 1.0

enum PopulationType {
	UNIFORM,
	EXPONENTIAL,
	BIMODAL,
	SKEWED,
	DISCRETE
}

# Internal variables
var population_data: Array[float] = []
var sample_means: Array[float] = []
var current_samples: Array[Array] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visualization
var population_display: Node3D
var sampling_display: Node3D
var sample_means_display: Node3D
var info_display: Label3D

# Animation
var sampling_tween: Tween

func _ready():
	setup_vr()
	generate_population()
	setup_displays()
	update_info_display()

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		var xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
		else:
			enable_vr = false
	
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		for hand in ["left_hand", "right_hand"]:
			var controller = XRController3D.new()
			controller.tracker = StringName(hand)
			controller.button_pressed.connect(_on_controller_button)
			xr_origin.add_child(controller)
			controllers.append(controller)

func generate_population():
	"""Generate population data based on selected distribution"""
	population_data.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(population_size):
		var value: float
		
		match population_type:
			PopulationType.UNIFORM:
				value = rng.randf_range(population_min, population_max)
			
			PopulationType.EXPONENTIAL:
				# Exponential distribution using inverse transform
				var u = rng.randf()
				value = -log(1.0 - u) * 2.0 + population_min
				
			PopulationType.BIMODAL:
				# Two peaks at 2 and 8
				if rng.randf() < 0.5:
					value = rng.randfn(2.0, 0.5)
				else:
					value = rng.randfn(8.0, 0.5)
			
			PopulationType.SKEWED:
				# Right-skewed distribution
				var normal_val = rng.randfn(0, 1)
				value = exp(normal_val) + population_min
			
			PopulationType.DISCRETE:
				# Discrete values 1-6 (like dice)
				value = float(rng.randi_range(1, 6))
		
		population_data.append(value)

func setup_displays():
	"""Create visual displays for population and samples"""
	# Population display
	population_display = Node3D.new()
	population_display.position = Vector3(-3.0, 1.0, 0)
	add_child(population_display)
	create_population_histogram()
	
	# Sampling process display
	sampling_display = Node3D.new()
	sampling_display.position = Vector3(0, 1.0, 0)
	add_child(sampling_display)
	
	# Sample means distribution display
	sample_means_display = Node3D.new()
	sample_means_display.position = Vector3(3.0, 1.0, 0)
	add_child(sample_means_display)
	
	# Info display
	info_display = Label3D.new()
	info_display.position = Vector3(0, 2.5, -1.0)
	info_display.font_size = 24
	info_display.modulate = Color.WHITE
	add_child(info_display)

func create_population_histogram():
	"""Create histogram of population distribution"""
	# Clear existing
	for child in population_display.get_children():
		child.queue_free()
	
	# Calculate bins
	var min_val = population_data.min()
	var max_val = population_data.max()
	var bin_count = 20
	var bin_width = (max_val - min_val) / float(bin_count)
	var bins = []
	bins.resize(bin_count)
	bins.fill(0)
	
	# Count values in bins
	for value in population_data:
		var bin_index = int((value - min_val) / bin_width)
		bin_index = clamp(bin_index, 0, bin_count - 1)
		bins[bin_index] += 1
	
	# Create histogram bars
	var max_count = bins.max()
	for i in range(bin_count):
		var height = float(bins[i]) / float(max_count) * 1.5
		var x_pos = (float(i) / float(bin_count) - 0.5) * 2.0
		
		create_histogram_bar(population_display, x_pos, height, Color.BLUE, "pop_bar_" + str(i))
	
	# Add label
	var label = Label3D.new()
	label.text = "Population\n" + get_distribution_name()
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 20
	population_display.add_child(label)

func create_histogram_bar(parent: Node3D, x_pos: float, height: float, color: Color, name: String):
	"""Create a single histogram bar"""
	var bar = MeshInstance3D.new()
	bar.name = name
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.08, height, 0.05)
	bar.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.2
	bar.material_override = material
	
	bar.position = Vector3(x_pos, height/2, 0)
	parent.add_child(bar)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		start_sampling_animation()
	elif button_name == "grip_click":
		change_population_type()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_sampling_animation()
		elif event.keycode == KEY_C:
			change_population_type()
		elif event.keycode == KEY_R:
			reset_sampling()

func start_sampling_animation():
	"""Start animated sampling process"""
	if sampling_tween:
		sampling_tween.kill()
	
	sample_means.clear()
	current_samples.clear()
	
	# Clear existing sample means display
	for child in sample_means_display.get_children():
		child.queue_free()
	
	sampling_tween = create_tween()
	
	for i in range(num_samples):
		sampling_tween.tween_callback(take_animated_sample.bind(i))
		sampling_tween.tween_delay(0.1 / animation_speed)
	
	sampling_tween.tween_callback(create_sample_means_histogram)

func take_animated_sample(sample_index: int):
	"""Take a single sample with animation"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Take random sample from population
	var sample: Array[float] = []
	for i in range(sample_size):
		var random_index = rng.randi_range(0, population_data.size() - 1)
		sample.append(population_data[random_index])
	
	# Calculate sample mean
	var sample_mean = calculate_mean(sample)
	sample_means.append(sample_mean)
	current_samples.append(sample)
	
	# Visualize current sample
	show_current_sample(sample, sample_mean)
	
	update_info_display()

func show_current_sample(sample: Array[float], mean_value: float):
	"""Visualize the current sample being taken"""
	# Clear previous sample display
	for child in sampling_display.get_children():
		child.queue_free()
	
	# Show sample points
	for i in range(min(sample.size(), 30)):  # Limit display for performance
		var point = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.02
		point.mesh = sphere_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.YELLOW
		material.emission = Color.YELLOW * 0.3
		point.material_override = material
		
		var x_pos = (sample[i] - population_min) / (population_max - population_min) * 2.0 - 1.0
		var y_pos = float(i) / 30.0 * 0.5
		point.position = Vector3(x_pos, y_pos, 0)
		
		sampling_display.add_child(point)
	
	# Show sample mean as larger point
	var mean_point = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.04
	mean_point.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission = Color.RED * 0.5
	mean_point.material_override = material
	
	var mean_x = (mean_value - population_min) / (population_max - population_min) * 2.0 - 1.0
	mean_point.position = Vector3(mean_x, 0.8, 0)
	sampling_display.add_child(mean_point)
	
	# Add label
	var label = Label3D.new()
	label.text = "Current Sample\nMean: %.2f" % mean_value
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 18
	sampling_display.add_child(label)

func create_sample_means_histogram():
	"""Create histogram of sample means (demonstrates CLT)"""
	if sample_means.is_empty():
		return
	
	# Clear existing
	for child in sample_means_display.get_children():
		child.queue_free()
	
	# Calculate bins for sample means
	var min_mean = sample_means.min()
	var max_mean = sample_means.max()
	var bin_count = 15
	var bin_width = (max_mean - min_mean) / float(bin_count)
	var bins = []
	bins.resize(bin_count)
	bins.fill(0)
	
	# Count sample means in bins
	for mean_val in sample_means:
		var bin_index = int((mean_val - min_mean) / bin_width)
		bin_index = clamp(bin_index, 0, bin_count - 1)
		bins[bin_index] += 1
	
	# Create histogram bars
	var max_count = bins.max()
	for i in range(bin_count):
		var height = float(bins[i]) / float(max_count) * 1.5
		var x_pos = (float(i) / float(bin_count) - 0.5) * 2.0
		
		create_histogram_bar(sample_means_display, x_pos, height, Color.GREEN, "mean_bar_" + str(i))
	
	# Add theoretical normal curve overlay
	add_theoretical_normal_curve()
	
	# Add label
	var label = Label3D.new()
	label.text = "Sample Means\n(Approaching Normal)"
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 18
	sample_means_display.add_child(label)

func add_theoretical_normal_curve():
	"""Add theoretical normal distribution curve for sample means"""
	var pop_mean = calculate_mean(population_data)
	var pop_variance = calculate_variance(population_data)
	var sem = sqrt(pop_variance / float(sample_size))  # Standard error of mean
	
	# Create curve points
	var curve_points: Array[Vector3] = []
	for i in range(50):
		var x = pop_mean + (float(i) / 25.0 - 1.0) * 4 * sem
		var y = normal_pdf(x, pop_mean, sem) * 3.0  # Scale for visibility
		var world_x = (x - pop_mean) / (4 * sem)
		curve_points.append(Vector3(world_x, y, 0.01))
	
	# Create curve mesh
	var curve = MeshInstance3D.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = curve_points
	
	var indices: PackedInt32Array = []
	for i in range(curve_points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	curve.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission = Color.CYAN * 0.5
	material.flags_unshaded = true
	curve.material_override = material
	
	sample_means_display.add_child(curve)

func calculate_mean(data: Array) -> float:
	"""Calculate mean of array"""
	if data.is_empty():
		return 0.0
	var sum = 0.0
	for value in data:
		sum += value
	return sum / float(data.size())

func calculate_variance(data: Array) -> float:
	"""Calculate variance of array"""
	if data.size() < 2:
		return 0.0
	var mean = calculate_mean(data)
	var variance_sum = 0.0
	for value in data:
		variance_sum += pow(value - mean, 2)
	return variance_sum / float(data.size() - 1)

func normal_pdf(x: float, mu: float, sigma: float) -> float:
	"""Normal probability density function"""
	var coefficient = 1.0 / (sigma * sqrt(2.0 * PI))
	var exponent = -0.5 * pow((x - mu) / sigma, 2)
	return coefficient * exp(exponent)

func change_population_type():
	"""Cycle through different population distributions"""
	var current_index = population_type as int
	population_type = ((current_index + 1) % PopulationType.size()) as PopulationType
	
	generate_population()
	create_population_histogram()
	reset_sampling()
	update_info_display()

func reset_sampling():
	"""Reset all sampling data"""
	sample_means.clear()
	current_samples.clear()
	
	for child in sampling_display.get_children():
		child.queue_free()
	for child in sample_means_display.get_children():
		child.queue_free()

func get_distribution_name() -> String:
	"""Get display name for current distribution"""
	match population_type:
		PopulationType.UNIFORM:
			return "Uniform"
		PopulationType.EXPONENTIAL:
			return "Exponential"
		PopulationType.BIMODAL:
			return "Bimodal"
		PopulationType.SKEWED:
			return "Right Skewed"
		PopulationType.DISCRETE:
			return "Discrete (Dice)"
		_:
			return "Unknown"

func update_info_display():
	"""Update information display"""
	var text = "Central Limit Theorem Demo\n"
	text += "Population: %s\n" % get_distribution_name()
	text += "Sample Size: %d\n" % sample_size
	text += "Samples Taken: %d/%d\n\n" % [sample_means.size(), num_samples]
	
	if population_data.size() > 0:
		var pop_mean = calculate_mean(population_data)
		var pop_std = sqrt(calculate_variance(population_data))
		text += "Population μ: %.2f\n" % pop_mean
		text += "Population σ: %.2f\n\n" % pop_std
		
		if sample_means.size() > 0:
			var sample_mean_avg = calculate_mean(sample_means)
			var sample_mean_std = sqrt(calculate_variance(sample_means))
			var theoretical_sem = pop_std / sqrt(sample_size)
			
			text += "Sample Means μ: %.2f\n" % sample_mean_avg
			text += "Sample Means σ: %.2f\n" % sample_mean_std
			text += "Theoretical SEM: %.2f" % theoretical_sem
	
	info_display.text = text

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"population_type": get_distribution_name(),
		"population_size": population_data.size(),
		"sample_size": sample_size,
		"num_samples_taken": sample_means.size(),
		"population_mean": calculate_mean(population_data),
		"population_std": sqrt(calculate_variance(population_data)),
		"sample_means": sample_means.duplicate(),
		"sample_means_mean": calculate_mean(sample_means),
		"sample_means_std": sqrt(calculate_variance(sample_means))
	}