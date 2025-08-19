extends Node3D

# Interactive VR Hypothesis Testing - Statistical Significance
# Demonstrates t-tests, p-values, and Type I/II errors

class_name HypothesisTestingVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Test Settings
@export_category("Hypothesis Testing")
@export var test_type: TestType = TestType.ONE_SAMPLE_T_TEST
@export var null_hypothesis_mean: float = 100.0
@export var sample_size: int = 30
@export var alpha_level: float = 0.05
@export var true_population_mean: float = 105.0  # Hidden for simulation

# Visual Settings
@export_category("Visualization")
@export var show_null_distribution: bool = true
@export var show_sample_distribution: bool = true
@export var animate_sampling: bool = true

enum TestType {
	ONE_SAMPLE_T_TEST,
	TWO_SAMPLE_T_TEST,
	PAIRED_T_TEST,
	CHI_SQUARE_TEST
}

# Internal variables
var sample_data: Array[float] = []
var test_statistic: float = 0.0
var p_value: float = 0.0
var is_significant: bool = false
var sample_mean: float = 0.0
var sample_std: float = 0.0

# Second sample for two-sample tests
var sample_data_2: Array[float] = []
var sample_mean_2: float = 0.0
var sample_std_2: float = 0.0

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var null_distribution_display: Node3D
var sample_display: Node3D
var test_statistic_display: Node3D
var p_value_display: Node3D
var info_display: Label3D
var decision_display: Label3D

# Sampling animation
var sampling_tween: Tween

func _ready():
	setup_vr()
	setup_visualization()
	setup_info_displays()
	reset_test()

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

func setup_visualization():
	"""Create visualization elements"""
	# Null distribution display
	null_distribution_display = Node3D.new()
	null_distribution_display.position = Vector3(-2.0, 1.0, 0)
	add_child(null_distribution_display)
	
	# Sample data display
	sample_display = Node3D.new()
	sample_display.position = Vector3(0, 1.0, 0)
	add_child(sample_display)
	
	# Test statistic visualization
	test_statistic_display = Node3D.new()
	test_statistic_display.position = Vector3(2.0, 1.0, 0)
	add_child(test_statistic_display)
	
	# P-value visualization
	p_value_display = Node3D.new()
	p_value_display.position = Vector3(0, -0.5, 0)
	add_child(p_value_display)

func setup_info_displays():
	"""Create information displays"""
	info_display = Label3D.new()
	info_display.position = Vector3(-2.5, 2.5, 0)
	info_display.font_size = 20
	info_display.modulate = Color.WHITE
	add_child(info_display)
	
	decision_display = Label3D.new()
	decision_display.position = Vector3(2.5, 2.5, 0)
	decision_display.font_size = 24
	decision_display.modulate = Color.WHITE
	add_child(decision_display)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		collect_sample()
	elif button_name == "grip_click":
		change_test_type()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			collect_sample()
		elif event.keycode == KEY_T:
			change_test_type()
		elif event.keycode == KEY_R:
			reset_test()

func collect_sample():
	"""Collect sample data and perform hypothesis test"""
	generate_sample_data()
	
	if animate_sampling:
		animate_sampling_process()
	else:
		perform_hypothesis_test()

func generate_sample_data():
	"""Generate sample data based on true population parameters"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	sample_data.clear()
	
	match test_type:
		TestType.ONE_SAMPLE_T_TEST:
			# Generate sample from population with true_population_mean
			for i in range(sample_size):
				var value = rng.randfn(true_population_mean, 15.0)  # σ = 15
				sample_data.append(value)
		
		TestType.TWO_SAMPLE_T_TEST:
			# Generate two independent samples
			sample_data_2.clear()
			for i in range(sample_size):
				var value1 = rng.randfn(true_population_mean, 15.0)
				var value2 = rng.randfn(true_population_mean + 3.0, 15.0)  # Slight difference
				sample_data.append(value1)
				sample_data_2.append(value2)
		
		TestType.PAIRED_T_TEST:
			# Generate paired data (before/after measurements)
			sample_data_2.clear()
			for i in range(sample_size):
				var before = rng.randfn(true_population_mean, 15.0)
				var after = before + rng.randfn(3.0, 5.0)  # Treatment effect
				sample_data.append(before)
				sample_data_2.append(after)

func animate_sampling_process():
	"""Animate the data collection process"""
	if sampling_tween:
		sampling_tween.kill()
	
	# Clear previous sample display
	for child in sample_display.get_children():
		child.queue_free()
	
	sampling_tween = create_tween()
	
	# Animate each data point appearing
	for i in range(sample_data.size()):
		sampling_tween.tween_callback(show_sample_point.bind(i))
		sampling_tween.tween_delay(0.05)
	
	sampling_tween.tween_callback(perform_hypothesis_test)

func show_sample_point(index: int):
	"""Show individual sample point"""
	if index >= sample_data.size():
		return
	
	var point = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.02
	point.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	material.emission = Color.BLUE * 0.3
	point.material_override = material
	
	# Position based on data value
	var normalized_value = (sample_data[index] - null_hypothesis_mean) / 30.0
	var x_pos = clamp(normalized_value, -1.0, 1.0)
	var y_pos = float(index % 10) * 0.05
	var z_pos = float(index / 10) * 0.05
	
	point.position = Vector3(x_pos, y_pos, z_pos)
	sample_display.add_child(point)

func perform_hypothesis_test():
	"""Perform the selected hypothesis test"""
	match test_type:
		TestType.ONE_SAMPLE_T_TEST:
			perform_one_sample_t_test()
		TestType.TWO_SAMPLE_T_TEST:
			perform_two_sample_t_test()
		TestType.PAIRED_T_TEST:
			perform_paired_t_test()
		TestType.CHI_SQUARE_TEST:
			perform_chi_square_test()
	
	update_all_displays()

func perform_one_sample_t_test():
	"""Perform one-sample t-test"""
	# Calculate sample statistics
	sample_mean = calculate_mean(sample_data)
	sample_std = calculate_std(sample_data)
	
	# Calculate t-statistic
	var standard_error = sample_std / sqrt(sample_data.size())
	test_statistic = (sample_mean - null_hypothesis_mean) / standard_error
	
	# Calculate p-value (two-tailed)
	var degrees_freedom = sample_data.size() - 1
	p_value = 2.0 * (1.0 - t_cdf(abs(test_statistic), degrees_freedom))
	
	# Make decision
	is_significant = p_value < alpha_level

func perform_two_sample_t_test():
	"""Perform independent two-sample t-test"""
	sample_mean = calculate_mean(sample_data)
	sample_std = calculate_std(sample_data)
	sample_mean_2 = calculate_mean(sample_data_2)
	sample_std_2 = calculate_std(sample_data_2)
	
	# Pooled standard error
	var n1 = sample_data.size()
	var n2 = sample_data_2.size()
	var pooled_variance = ((n1 - 1) * sample_std * sample_std + (n2 - 1) * sample_std_2 * sample_std_2) / (n1 + n2 - 2)
	var standard_error = sqrt(pooled_variance * (1.0/n1 + 1.0/n2))
	
	# t-statistic
	test_statistic = (sample_mean - sample_mean_2) / standard_error
	
	# p-value
	var degrees_freedom = n1 + n2 - 2
	p_value = 2.0 * (1.0 - t_cdf(abs(test_statistic), degrees_freedom))
	
	is_significant = p_value < alpha_level

func perform_paired_t_test():
	"""Perform paired t-test"""
	# Calculate differences
	var differences: Array[float] = []
	for i in range(sample_data.size()):
		differences.append(sample_data_2[i] - sample_data[i])
	
	# Perform one-sample t-test on differences
	var diff_mean = calculate_mean(differences)
	var diff_std = calculate_std(differences)
	var standard_error = diff_std / sqrt(differences.size())
	
	test_statistic = diff_mean / standard_error
	
	var degrees_freedom = differences.size() - 1
	p_value = 2.0 * (1.0 - t_cdf(abs(test_statistic), degrees_freedom))
	
	is_significant = p_value < alpha_level

func perform_chi_square_test():
	"""Perform chi-square goodness of fit test"""
	# Simplified chi-square test implementation
	pass

func update_all_displays():
	"""Update all visualization displays"""
	update_null_distribution()
	update_test_statistic_display()
	update_p_value_display()
	update_info_display_text()
	update_decision_display()

func update_null_distribution():
	"""Update null distribution visualization"""
	# Clear existing
	for child in null_distribution_display.get_children():
		child.queue_free()
	
	# Create t-distribution curve
	var degrees_freedom = sample_data.size() - 1
	var curve_points: Array[Vector3] = []
	
	for i in range(201):
		var t = float(i - 100) / 20.0  # Range from -5 to 5
		var density = t_pdf(t, degrees_freedom)
		var x = t / 5.0  # Scale to [-1, 1]
		var y = density * 2.0  # Scale for visibility
		curve_points.append(Vector3(x, y, 0))
	
	# Create curve mesh
	var curve_mesh = MeshInstance3D.new()
	create_line_mesh(curve_mesh, curve_points, Color.CYAN)
	null_distribution_display.add_child(curve_mesh)
	
	# Add critical regions
	var critical_t = t_quantile(1.0 - alpha_level/2.0, degrees_freedom)
	create_critical_regions(critical_t)
	
	# Add label
	var label = Label3D.new()
	label.text = "Null Distribution\nt(%d)" % degrees_freedom
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 18
	null_distribution_display.add_child(label)

func create_critical_regions(critical_t: float):
	"""Create shaded critical regions"""
	# Right tail
	var right_region = MeshInstance3D.new()
	var right_x = critical_t / 5.0
	create_shaded_region(right_region, right_x, 1.0, Color.RED)
	null_distribution_display.add_child(right_region)
	
	# Left tail
	var left_region = MeshInstance3D.new()
	var left_x = -critical_t / 5.0
	create_shaded_region(left_region, -1.0, left_x, Color.RED)
	null_distribution_display.add_child(left_region)

func create_shaded_region(mesh_instance: MeshInstance3D, x_start: float, x_end: float, color: Color):
	"""Create shaded region for critical area"""
	var box_mesh = BoxMesh.new()
	var width = x_end - x_start
	box_mesh.size = Vector3(width, 1.5, 0.01)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.flags_transparent = true
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3((x_start + x_end) / 2.0, 0.75, -0.01)

func update_test_statistic_display():
	"""Update test statistic visualization"""
	# Clear existing
	for child in test_statistic_display.get_children():
		child.queue_free()
	
	# Show test statistic as vertical line on null distribution
	var t_line = MeshInstance3D.new()
	var x_pos = clamp(test_statistic / 5.0, -1.0, 1.0)
	var line_points = [Vector3(x_pos, 0, 0.01), Vector3(x_pos, 1.5, 0.01)]
	create_line_mesh(t_line, line_points, Color.YELLOW)
	test_statistic_display.add_child(t_line)
	
	# Add label
	var label = Label3D.new()
	label.text = "Test Statistic\nt = %.3f" % test_statistic
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 18
	label.modulate = Color.YELLOW
	test_statistic_display.add_child(label)

func update_p_value_display():
	"""Update p-value visualization"""
	# Clear existing
	for child in p_value_display.get_children():
		child.queue_free()
	
	# Create p-value bar
	var p_bar = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.0 * p_value, 0.1, 0.05)
	p_bar.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	var color = Color.GREEN if p_value >= alpha_level else Color.RED
	material.albedo_color = color
	material.emission = color * 0.3
	p_bar.material_override = material
	
	p_bar.position = Vector3(p_value - 1.0, 0, 0)
	p_value_display.add_child(p_bar)
	
	# Add alpha level reference line
	var alpha_line = MeshInstance3D.new()
	var alpha_x = 2.0 * alpha_level - 1.0
	var alpha_points = [Vector3(alpha_x, -0.2, 0), Vector3(alpha_x, 0.2, 0)]
	create_line_mesh(alpha_line, alpha_points, Color.WHITE)
	p_value_display.add_child(alpha_line)
	
	# Add labels
	var p_label = Label3D.new()
	p_label.text = "p-value = %.4f" % p_value
	p_label.position = Vector3(0, 0.3, 0)
	p_label.font_size = 18
	p_value_display.add_child(p_label)
	
	var alpha_label = Label3D.new()
	alpha_label.text = "α = %.2f" % alpha_level
	alpha_label.position = Vector3(alpha_x, -0.4, 0)
	alpha_label.font_size = 16
	p_value_display.add_child(alpha_label)

func update_info_display_text():
	"""Update information display"""
	var text = "Hypothesis Testing\n\n"
	text += "Test: %s\n" % get_test_type_name()
	text += "Sample size: %d\n" % sample_data.size()
	text += "α level: %.3f\n\n" % alpha_level
	
	match test_type:
		TestType.ONE_SAMPLE_T_TEST:
			text += "H₀: μ = %.1f\n" % null_hypothesis_mean
			text += "H₁: μ ≠ %.1f\n\n" % null_hypothesis_mean
			text += "Sample mean: %.2f\n" % sample_mean
			text += "Sample SD: %.2f\n" % sample_std
		
		TestType.TWO_SAMPLE_T_TEST:
			text += "H₀: μ₁ = μ₂\n"
			text += "H₁: μ₁ ≠ μ₂\n\n"
			text += "Sample 1 mean: %.2f\n" % sample_mean
			text += "Sample 2 mean: %.2f\n" % sample_mean_2
	
	text += "\nTest statistic: %.3f\n" % test_statistic
	text += "p-value: %.4f" % p_value
	
	info_display.text = text

func update_decision_display():
	"""Update decision display"""
	var text = "DECISION\n\n"
	
	if is_significant:
		text += "REJECT H₀\n"
		text += "Result is SIGNIFICANT\n"
		text += "(p < α)\n\n"
		text += "Evidence against\nnull hypothesis"
		decision_display.modulate = Color.RED
	else:
		text += "FAIL TO REJECT H₀\n"
		text += "Result is NOT significant\n"
		text += "(p ≥ α)\n\n"
		text += "Insufficient evidence\nagainst null hypothesis"
		decision_display.modulate = Color.GREEN
	
	decision_display.text = text

# Statistical functions
func calculate_mean(data: Array) -> float:
	"""Calculate mean of array"""
	if data.is_empty():
		return 0.0
	var sum = 0.0
	for value in data:
		sum += value
	return sum / float(data.size())

func calculate_std(data: Array) -> float:
	"""Calculate standard deviation"""
	if data.size() < 2:
		return 0.0
	var mean = calculate_mean(data)
	var variance_sum = 0.0
	for value in data:
		variance_sum += pow(value - mean, 2)
	return sqrt(variance_sum / float(data.size() - 1))

func t_pdf(t: float, df: float) -> float:
	"""t-distribution probability density function"""
	var gamma_term = exp(log_gamma((df + 1.0) / 2.0) - log_gamma(df / 2.0))
	var coefficient = gamma_term / sqrt(PI * df)
	return coefficient * pow(1.0 + t * t / df, -(df + 1.0) / 2.0)

func t_cdf(t: float, df: float) -> float:
	"""t-distribution cumulative distribution function (approximation)"""
	# Simple approximation for demonstration
	if df > 30:
		return normal_cdf(t)
	else:
		# Very rough approximation
		return 0.5 + 0.5 * sign(t) * (1.0 - exp(-abs(t)))

func t_quantile(p: float, df: float) -> float:
	"""t-distribution quantile function (approximation)"""
	# Rough approximation for critical values
	if df > 30:
		return normal_quantile(p)
	else:
		# Common critical values approximation
		if p > 0.975:
			return 2.0 + 1.0 / df
		elif p < 0.025:
			return -(2.0 + 1.0 / df)
		else:
			return 0.0

func normal_cdf(z: float) -> float:
	"""Standard normal CDF approximation"""
	return 0.5 * (1.0 + sign(z) * sqrt(1.0 - exp(-2.0 * z * z / PI)))

func normal_quantile(p: float) -> float:
	"""Standard normal quantile approximation"""
	if p > 0.975:
		return 1.96
	elif p < 0.025:
		return -1.96
	else:
		return 0.0

func log_gamma(x: float) -> float:
	"""Log gamma function (Stirling's approximation)"""
	if x < 1.0:
		return log_gamma(x + 1.0) - log(x)
	return (x - 0.5) * log(x) - x + 0.5 * log(2.0 * PI)

func create_line_mesh(mesh_instance: MeshInstance3D, points: Array[Vector3], color: Color):
	"""Create line mesh from points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var indices: PackedInt32Array = []
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	material.flags_unshaded = true
	mesh_instance.material_override = material

func change_test_type():
	"""Change the type of hypothesis test"""
	var current_index = test_type as int
	test_type = ((current_index + 1) % TestType.size()) as TestType
	reset_test()

func reset_test():
	"""Reset test data and displays"""
	sample_data.clear()
	sample_data_2.clear()
	test_statistic = 0.0
	p_value = 0.0
	is_significant = false
	
	# Clear all displays
	for display in [null_distribution_display, sample_display, test_statistic_display, p_value_display]:
		for child in display.get_children():
			child.queue_free()
	
	update_info_display_text()
	update_decision_display()

func get_test_type_name() -> String:
	"""Get display name for current test type"""
	match test_type:
		TestType.ONE_SAMPLE_T_TEST:
			return "One-Sample t-test"
		TestType.TWO_SAMPLE_T_TEST:
			return "Two-Sample t-test"
		TestType.PAIRED_T_TEST:
			return "Paired t-test"
		TestType.CHI_SQUARE_TEST:
			return "Chi-Square test"
		_:
			return "Unknown"

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"test_type": get_test_type_name(),
		"sample_size": sample_data.size(),
		"null_hypothesis_mean": null_hypothesis_mean,
		"alpha_level": alpha_level,
		"sample_mean": sample_mean,
		"sample_std": sample_std,
		"test_statistic": test_statistic,
		"p_value": p_value,
		"is_significant": is_significant,
		"decision": "Reject H0" if is_significant else "Fail to reject H0"
	}