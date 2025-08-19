extends Node3D

# Interactive VR Normal Distribution - Continuous Probability
# Demonstrates Gaussian distributions, standard deviation, and the 68-95-99.7 rule

class_name NormalDistributionVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Distribution Settings
@export_category("Distribution Parameters")
@export var mean: float = 0.0
@export var std_dev: float = 1.0
@export var sample_size: int = 1000
@export var auto_generate: bool = false

# Visual Settings
@export_category("Visualization")
@export var bell_curve_resolution: int = 100
@export var histogram_bins: int = 20
@export var curve_height: float = 2.0
@export var curve_width: float = 4.0

# Animation Settings
@export_category("Animation")
@export var particle_speed: float = 2.0
@export var generation_rate: float = 5.0
@export var show_falling_samples: bool = true

# Box-Muller transform static variables
var spare_ready: bool = false
var spare_value: float = 0.0

# Internal variables
var samples: Array[float] = []
var histogram_data: Array[int] = []
var theoretical_curve: Node3D
var empirical_histogram: Node3D
var sample_particles: Array[Node3D] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# UI Elements
var stats_display: Label3D
var parameter_controls: Node3D
var standard_deviation_markers: Node3D

# Random number generator
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	setup_vr()
	setup_ui()
	create_theoretical_curve()
	setup_parameter_controls()
	create_std_dev_markers()
	
	if auto_generate:
		generate_samples()

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

func setup_ui():
	"""Create statistical information display"""
	stats_display = Label3D.new()
	stats_display.position = Vector3(-3.0, 2.0, -1.0)
	stats_display.font_size = 28
	stats_display.modulate = Color.WHITE
	update_stats_display()
	add_child(stats_display)

func create_theoretical_curve():
	"""Create the theoretical normal distribution curve"""
	theoretical_curve = Node3D.new()
	theoretical_curve.position = Vector3(0, 1.0, 0)
	add_child(theoretical_curve)
	
	# Create smooth curve using line segments
	var curve_points: Array[Vector3] = []
	var x_min = mean - 4 * std_dev
	var x_max = mean + 4 * std_dev
	
	for i in range(bell_curve_resolution + 1):
		var x = x_min + float(i) / float(bell_curve_resolution) * (x_max - x_min)
		var y = normal_pdf(x, mean, std_dev) * curve_height
		var world_x = (x - mean) / (4 * std_dev) * curve_width
		curve_points.append(Vector3(world_x, y, 0))
	
	# Create curve mesh
	create_curve_mesh(curve_points)

func create_curve_mesh(points: Array[Vector3]):
	"""Create 3D mesh for the normal curve"""
	var curve_mesh = MeshInstance3D.new()
	
	# Create line strip mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	# Create indices for line strips
	var indices: PackedInt32Array = []
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	curve_mesh.mesh = mesh
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission = Color.CYAN * 0.5
	material.flags_unshaded = true
	curve_mesh.material_override = material
	
	theoretical_curve.add_child(curve_mesh)

func setup_parameter_controls():
	"""Create interactive controls for distribution parameters"""
	parameter_controls = Node3D.new()
	parameter_controls.position = Vector3(3.0, 1.5, -1.0)
	add_child(parameter_controls)
	
	# Mean control slider
	create_parameter_slider("Mean", mean, -3.0, 3.0, Vector3(0, 0.5, 0))
	
	# Standard deviation control slider  
	create_parameter_slider("Std Dev", std_dev, 0.1, 3.0, Vector3(0, 0, 0))

func create_parameter_slider(name: String, value: float, min_val: float, max_val: float, position: Vector3):
	"""Create an interactive slider for parameter adjustment"""
	var slider_group = Node3D.new()
	slider_group.position = position
	
	# Label
	var label = Label3D.new()
	label.text = name + ": %.2f" % value
	label.position = Vector3(0, 0.2, 0)
	label.font_size = 24
	slider_group.add_child(label)
	
	# Slider track
	var track = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 0.02, 0.02)
	track.mesh = box_mesh
	
	var track_material = StandardMaterial3D.new()
	track_material.albedo_color = Color.GRAY
	track.material_override = track_material
	slider_group.add_child(track)
	
	# Slider handle
	var handle = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.03
	handle.mesh = sphere_mesh
	
	var handle_material = StandardMaterial3D.new()
	handle_material.albedo_color = Color.YELLOW
	handle.material_override = handle_material
	
	var handle_x = (value - min_val) / (max_val - min_val) - 0.5
	handle.position = Vector3(handle_x, 0, 0)
	slider_group.add_child(handle)
	
	parameter_controls.add_child(slider_group)

func create_std_dev_markers():
	"""Create visual markers for standard deviation ranges"""
	standard_deviation_markers = Node3D.new()
	standard_deviation_markers.position = Vector3(0, 1.0, -0.1)
	add_child(standard_deviation_markers)
	
	# 68-95-99.7 rule markers
	var std_ranges = [1, 2, 3]
	var colors = [Color.GREEN, Color.YELLOW, Color.RED]
	var alphas = [0.3, 0.2, 0.1]
	
	for i in range(std_ranges.size()):
		var std_range = std_ranges[i]
		create_std_dev_region(std_range, colors[i], alphas[i])

func create_std_dev_region(std_multiplier: int, color: Color, alpha: float):
	"""Create shaded region for standard deviation range"""
	var region = MeshInstance3D.new()
	region.name = "std_region_" + str(std_multiplier)
	
	var box_mesh = BoxMesh.new()
	var width = 2.0 * std_multiplier * std_dev / (4 * std_dev) * curve_width
	box_mesh.size = Vector3(width, curve_height, 0.01)
	region.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.flags_transparent = true
	region.material_override = material
	
	standard_deviation_markers.add_child(region)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		generate_samples()
	elif button_name == "grip_click":
		clear_samples()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			generate_samples()
		elif event.keycode == KEY_C:
			clear_samples()
		elif event.keycode == KEY_R:
			reset_parameters()

func generate_samples():
	"""Generate random samples from normal distribution"""
	clear_samples()
	
	samples.clear()
	for i in range(sample_size):
		var sample = generate_normal_sample()
		samples.append(sample)
		
		if show_falling_samples:
			create_falling_particle(sample)
	
	create_empirical_histogram()
	update_stats_display()

func generate_normal_sample() -> float:
	"""Generate a single sample from normal distribution using Box-Muller transform"""
	# Box-Muller transform for normal distribution
	
	if spare_ready:
		spare_ready = false
		return spare_value * std_dev + mean
	
	spare_ready = true
	var u = rng.randf()
	var v = rng.randf()
	var mag = std_dev * sqrt(-2.0 * log(u))
	spare_value = mag * cos(2.0 * PI * v)
	return mag * sin(2.0 * PI * v) + mean

func create_falling_particle(value: float):
	"""Create a particle that falls to represent a sample"""
	var particle = MeshInstance3D.new()
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	particle.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission = Color.WHITE * 0.3
	particle.material_override = material
	
	# Position based on value
	var x_pos = (value - mean) / (4 * std_dev) * curve_width
	particle.position = Vector3(x_pos, 3.0, 0)
	
	add_child(particle)
	sample_particles.append(particle)
	
	# Animate falling
	var tween = create_tween()
	tween.tween_property(particle, "position:y", 0.1, 1.0 / particle_speed)
	tween.tween_callback(func(): particle.queue_free())

func create_empirical_histogram():
	"""Create histogram from generated samples"""
	if empirical_histogram:
		empirical_histogram.queue_free()
	
	empirical_histogram = Node3D.new()
	empirical_histogram.position = Vector3(0, 0.1, 0.2)
	add_child(empirical_histogram)
	
	# Calculate histogram bins
	var x_min = mean - 4 * std_dev
	var x_max = mean + 4 * std_dev
	var bin_width = (x_max - x_min) / float(histogram_bins)
	
	histogram_data.clear()
	histogram_data.resize(histogram_bins)
	histogram_data.fill(0)
	
	# Count samples in each bin
	for sample in samples:
		if sample >= x_min and sample <= x_max:
			var bin_index = int((sample - x_min) / bin_width)
			bin_index = clamp(bin_index, 0, histogram_bins - 1)
			histogram_data[bin_index] += 1
	
	# Create histogram bars
	var max_count = histogram_data.max()
	if max_count > 0:
		for i in range(histogram_bins):
			var count = histogram_data[i]
			var height = float(count) / float(max_count) * curve_height * 0.8
			var x_pos = (float(i) / float(histogram_bins) - 0.5) * curve_width
			
			create_histogram_bar(i, height, x_pos, bin_width)

func create_histogram_bar(index: int, height: float, x_pos: float, bin_width: float):
	"""Create a single histogram bar"""
	var bar = MeshInstance3D.new()
	bar.name = "histogram_bar_" + str(index)
	
	var box_mesh = BoxMesh.new()
	var bar_width = curve_width / float(histogram_bins) * 0.8
	box_mesh.size = Vector3(bar_width, height, 0.05)
	bar.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	material.emission = Color.ORANGE * 0.2
	bar.material_override = material
	
	bar.position = Vector3(x_pos, height/2, 0)
	empirical_histogram.add_child(bar)

func normal_pdf(x: float, mu: float, sigma: float) -> float:
	"""Calculate normal probability density function"""
	var coefficient = 1.0 / (sigma * sqrt(2.0 * PI))
	var exponent = -0.5 * pow((x - mu) / sigma, 2)
	return coefficient * exp(exponent)

func update_stats_display():
	"""Update statistical information display"""
	var text = "Normal Distribution\n"
	text += "μ (mean): %.2f\n" % mean
	text += "σ (std dev): %.2f\n" % std_dev
	text += "Sample size: %d\n\n" % sample_size
	
	if samples.size() > 0:
		var sample_mean = calculate_sample_mean()
		var sample_std = calculate_sample_std()
		
		text += "Sample Statistics:\n"
		text += "Sample mean: %.2f\n" % sample_mean
		text += "Sample std: %.2f\n\n" % sample_std
		
		text += "68-95-99.7 Rule:\n"
		text += "±1σ: %.1f%% (expected 68%%)\n" % calculate_percentage_in_range(1)
		text += "±2σ: %.1f%% (expected 95%%)\n" % calculate_percentage_in_range(2)
		text += "±3σ: %.1f%% (expected 99.7%%)" % calculate_percentage_in_range(3)
	
	stats_display.text = text

func calculate_sample_mean() -> float:
	"""Calculate mean of generated samples"""
	if samples.is_empty():
		return 0.0
	
	var sum = 0.0
	for sample in samples:
		sum += sample
	return sum / float(samples.size())

func calculate_sample_std() -> float:
	"""Calculate standard deviation of generated samples"""
	if samples.size() < 2:
		return 0.0
	
	var sample_mean = calculate_sample_mean()
	var variance_sum = 0.0
	
	for sample in samples:
		variance_sum += pow(sample - sample_mean, 2)
	
	return sqrt(variance_sum / float(samples.size() - 1))

func calculate_percentage_in_range(std_multiplier: int) -> float:
	"""Calculate percentage of samples within std_multiplier standard deviations"""
	if samples.is_empty():
		return 0.0
	
	var lower_bound = mean - std_multiplier * std_dev
	var upper_bound = mean + std_multiplier * std_dev
	var count_in_range = 0
	
	for sample in samples:
		if sample >= lower_bound and sample <= upper_bound:
			count_in_range += 1
	
	return float(count_in_range) / float(samples.size()) * 100.0

func clear_samples():
	"""Clear all generated samples and visualizations"""
	samples.clear()
	
	# Clear particles
	for particle in sample_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	sample_particles.clear()
	
	# Clear histogram
	if empirical_histogram:
		empirical_histogram.queue_free()
	
	update_stats_display()

func reset_parameters():
	"""Reset distribution parameters to defaults"""
	mean = 0.0
	std_dev = 1.0
	create_theoretical_curve()
	update_stats_display()

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"theoretical_mean": mean,
		"theoretical_std": std_dev,
		"sample_size": samples.size(),
		"sample_mean": calculate_sample_mean(),
		"sample_std": calculate_sample_std(),
		"samples": samples.duplicate(),
		"histogram_data": histogram_data.duplicate(),
		"percentages_in_std_ranges": {
			"one_std": calculate_percentage_in_range(1),
			"two_std": calculate_percentage_in_range(2),
			"three_std": calculate_percentage_in_range(3)
		}
	}