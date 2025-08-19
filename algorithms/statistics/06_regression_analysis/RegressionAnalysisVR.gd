extends Node3D

# Interactive VR Regression Analysis - Predictive Modeling
# Demonstrates linear regression, correlation, and model evaluation

class_name RegressionAnalysisVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Regression Settings
@export_category("Regression Parameters")
@export var regression_type: RegressionType = RegressionType.LINEAR
@export var num_data_points: int = 50
@export var noise_level: float = 0.3
@export var true_slope: float = 2.0
@export var true_intercept: float = 1.0

# Visual Settings
@export_category("Visualization")
@export var show_residuals: bool = true
@export var show_confidence_intervals: bool = true
@export var auto_fit: bool = false

enum RegressionType {
	LINEAR,
	POLYNOMIAL,
	MULTIPLE,
	LOGISTIC,
	RIDGE,
	LASSO
}

# Internal variables
var data_points: Array[Vector2] = []
var regression_line_points: Array[Vector3] = []
var slope: float = 0.0
var intercept: float = 0.0
var r_squared: float = 0.0
var correlation: float = 0.0
var residuals: Array[float] = []

# Multiple regression variables (for 3D)
var data_points_3d: Array[Vector3] = []
var multiple_coefficients: Array[float] = []

# Logistic regression variables
var logistic_coefficients: Array[float] = []
var max_iterations: int = 1000
var learning_rate: float = 0.01
var convergence_threshold: float = 1e-6

# Regularization parameters
@export var regularization_lambda: float = 0.1
var regularized_coefficients: Array[float] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var scatter_plot: Node3D
var regression_line: Node3D
var residual_display: Node3D
var stats_display: Label3D
var equation_display: Label3D
var interactive_point: Node3D

# Interaction state
var is_adding_points: bool = false
var selected_point_index: int = -1

func _ready():
	setup_vr()
	setup_visualization()
	setup_info_displays()
	generate_sample_data()
	if auto_fit:
		fit_regression()

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
	# Scatter plot display
	scatter_plot = Node3D.new()
	add_child(scatter_plot)
	
	# Regression line display
	regression_line = Node3D.new()
	add_child(regression_line)
	
	# Residual lines display
	residual_display = Node3D.new()
	add_child(residual_display)
	
	# Interactive point for adding data
	interactive_point = Node3D.new()
	add_child(interactive_point)
	create_interactive_cursor()
	
	# Create coordinate axes
	create_coordinate_axes()

func create_coordinate_axes():
	"""Create 3D coordinate axes"""
	var axes = Node3D.new()
	add_child(axes)
	
	# X-axis (red)
	var x_axis = MeshInstance3D.new()
	var x_points = [Vector3(-2.0, 0, 0), Vector3(2.0, 0, 0)]
	create_line_mesh(x_axis, x_points, Color.RED)
	axes.add_child(x_axis)
	
	# Y-axis (green)
	var y_axis = MeshInstance3D.new()
	var y_points = [Vector3(0, -2.0, 0), Vector3(0, 2.0, 0)]
	create_line_mesh(y_axis, y_points, Color.GREEN)
	axes.add_child(y_axis)
	
	# Z-axis (blue) - for multiple regression
	if regression_type == RegressionType.MULTIPLE:
		var z_axis = MeshInstance3D.new()
		var z_points = [Vector3(0, 0, -2.0), Vector3(0, 0, 2.0)]
		create_line_mesh(z_axis, z_points, Color.BLUE)
		axes.add_child(z_axis)
	
	# Add axis labels
	add_axis_labels(axes)

func add_axis_labels(parent: Node3D):
	"""Add labels to coordinate axes"""
	var x_label = Label3D.new()
	x_label.text = "X"
	x_label.position = Vector3(2.2, 0, 0)
	x_label.font_size = 24
	x_label.modulate = Color.RED
	parent.add_child(x_label)
	
	var y_label = Label3D.new()
	y_label.text = "Y"
	y_label.position = Vector3(0, 2.2, 0)
	y_label.font_size = 24
	y_label.modulate = Color.GREEN
	parent.add_child(y_label)
	
	if regression_type == RegressionType.MULTIPLE:
		var z_label = Label3D.new()
		z_label.text = "Z"
		z_label.position = Vector3(0, 0, 2.2)
		z_label.font_size = 24
		z_label.modulate = Color.BLUE
		parent.add_child(z_label)

func create_interactive_cursor():
	"""Create cursor for interactive point placement"""
	var cursor = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	cursor.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission = Color.YELLOW * 0.5
	cursor.material_override = material
	
	interactive_point.add_child(cursor)
	interactive_point.visible = false

func setup_info_displays():
	"""Create information displays"""
	stats_display = Label3D.new()
	stats_display.position = Vector3(-2.5, 2.0, 0)
	stats_display.font_size = 20
	stats_display.modulate = Color.WHITE
	add_child(stats_display)
	
	equation_display = Label3D.new()
	equation_display.position = Vector3(2.5, 2.0, 0)
	equation_display.font_size = 24
	equation_display.modulate = Color.CYAN
	add_child(equation_display)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		if is_adding_points:
			add_data_point_at_cursor()
		else:
			fit_regression()
	elif button_name == "grip_click":
		toggle_point_adding_mode()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			fit_regression()
		elif event.keycode == KEY_A:
			toggle_point_adding_mode()
		elif event.keycode == KEY_R:
			reset_data()
		elif event.keycode == KEY_T:
			change_regression_type()

func generate_sample_data():
	"""Generate sample data with known relationship"""
	data_points.clear()
	data_points_3d.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	match regression_type:
		RegressionType.LINEAR:
			generate_linear_data(rng)
		RegressionType.POLYNOMIAL:
			generate_polynomial_data(rng)
		RegressionType.MULTIPLE:
			generate_multiple_regression_data(rng)
		RegressionType.LOGISTIC:
			generate_logistic_data(rng)
		RegressionType.RIDGE, RegressionType.LASSO:
			generate_linear_data(rng)  # Use linear data for regularized methods
	
	update_scatter_plot()

func generate_linear_data(rng: RandomNumberGenerator):
	"""Generate linear relationship data"""
	for i in range(num_data_points):
		var x = rng.randf_range(-2.0, 2.0)
		var noise = rng.randfn(0.0, noise_level)
		var y = true_slope * x + true_intercept + noise
		data_points.append(Vector2(x, y))

func generate_polynomial_data(rng: RandomNumberGenerator):
	"""Generate polynomial relationship data"""
	for i in range(num_data_points):
		var x = rng.randf_range(-2.0, 2.0)
		var noise = rng.randfn(0.0, noise_level)
		var y = 0.5 * x * x + true_slope * x + true_intercept + noise
		data_points.append(Vector2(x, y))

func generate_multiple_regression_data(rng: RandomNumberGenerator):
	"""Generate multiple regression data (3D)"""
	for i in range(num_data_points):
		var x1 = rng.randf_range(-2.0, 2.0)
		var x2 = rng.randf_range(-2.0, 2.0)
		var noise = rng.randfn(0.0, noise_level)
		var y = true_slope * x1 + true_intercept * x2 + 1.0 + noise
		data_points_3d.append(Vector3(x1, y, x2))

func generate_logistic_data(rng: RandomNumberGenerator):
	"""Generate logistic regression data"""
	for i in range(num_data_points):
		var x = rng.randf_range(-3.0, 3.0)
		var linear_combination = true_slope * x + true_intercept
		var probability = 1.0 / (1.0 + exp(-linear_combination))
		var y = 1.0 if rng.randf() < probability else 0.0
		data_points.append(Vector2(x, y))

func update_scatter_plot():
	"""Update scatter plot visualization"""
	# Clear existing points
	for child in scatter_plot.get_children():
		child.queue_free()
	
	match regression_type:
		RegressionType.MULTIPLE:
			update_3d_scatter_plot()
		_:
			update_2d_scatter_plot()

func update_2d_scatter_plot():
	"""Update 2D scatter plot"""
	for i in range(data_points.size()):
		var point = data_points[i]
		var point_visual = create_data_point_visual(Vector3(point.x, point.y, 0), i)
		scatter_plot.add_child(point_visual)

func update_3d_scatter_plot():
	"""Update 3D scatter plot for multiple regression"""
	for i in range(data_points_3d.size()):
		var point = data_points_3d[i]
		var point_visual = create_data_point_visual(point, i)
		scatter_plot.add_child(point_visual)

func create_data_point_visual(position: Vector3, index: int) -> Node3D:
	"""Create visual representation of a data point"""
	var point_node = Node3D.new()
	point_node.position = position
	point_node.name = "data_point_" + str(index)
	
	var point_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.03
	point_mesh.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	material.emission = Color.BLUE * 0.3
	point_mesh.material_override = material
	
	point_node.add_child(point_mesh)
	return point_node

func toggle_point_adding_mode():
	"""Toggle interactive point adding mode"""
	is_adding_points = !is_adding_points
	interactive_point.visible = is_adding_points
	
	if is_adding_points:
		print("Point adding mode ON - move cursor and trigger to add points")
	else:
		print("Point adding mode OFF")

func add_data_point_at_cursor():
	"""Add data point at cursor position"""
	var cursor_pos = interactive_point.position
	
	match regression_type:
		RegressionType.MULTIPLE:
			data_points_3d.append(cursor_pos)
		_:
			data_points.append(Vector2(cursor_pos.x, cursor_pos.y))
	
	update_scatter_plot()
	
	if auto_fit:
		fit_regression()

func fit_regression():
	"""Fit regression model to current data"""
	match regression_type:
		RegressionType.LINEAR:
			fit_linear_regression()
		RegressionType.POLYNOMIAL:
			fit_polynomial_regression()
		RegressionType.MULTIPLE:
			fit_multiple_regression()
		RegressionType.LOGISTIC:
			fit_logistic_regression()
		RegressionType.RIDGE:
			fit_ridge_regression()
		RegressionType.LASSO:
			fit_lasso_regression()
	
	update_regression_visualization()
	update_info_displays()

func fit_linear_regression():
	"""Fit linear regression using least squares"""
	if data_points.size() < 2:
		return
	
	var n = data_points.size()
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	var sum_x2 = 0.0
	
	# Calculate sums
	for point in data_points:
		sum_x += point.x
		sum_y += point.y
		sum_xy += point.x * point.y
		sum_x2 += point.x * point.x
	
	# Calculate slope and intercept
	var denominator = n * sum_x2 - sum_x * sum_x
	if abs(denominator) > 1e-10:
		slope = (n * sum_xy - sum_x * sum_y) / denominator
		intercept = (sum_y - slope * sum_x) / n
	
	# Calculate R-squared
	calculate_r_squared()
	
	# Calculate residuals
	calculate_residuals()

func fit_polynomial_regression():
	"""Fit polynomial regression (degree 2)"""
	if data_points.size() < 3:
		return
	
	# Implement proper polynomial regression y = ax² + bx + c
	var n = data_points.size()
	
	# Set up matrix system for least squares: X'X * coeffs = X'y
	# Where X = [1, x, x²] for each data point
	var sum_1 = 0.0   # sum of 1
	var sum_x = 0.0   # sum of x
	var sum_x2 = 0.0  # sum of x²
	var sum_x3 = 0.0  # sum of x³
	var sum_x4 = 0.0  # sum of x⁴
	var sum_y = 0.0   # sum of y
	var sum_xy = 0.0  # sum of xy
	var sum_x2y = 0.0 # sum of x²y
	
	# Calculate sums for matrix system
	for point in data_points:
		var x = point.x
		var y = point.y
		var x2 = x * x
		var x3 = x2 * x
		var x4 = x3 * x
		
		sum_1 += 1.0
		sum_x += x
		sum_x2 += x2
		sum_x3 += x3
		sum_x4 += x4
		sum_y += y
		sum_xy += x * y
		sum_x2y += x2 * y
	
	# Solve 3x3 system using Cramer's rule
	# Matrix A = [[n, sum_x, sum_x2], [sum_x, sum_x2, sum_x3], [sum_x2, sum_x3, sum_x4]]
	# Vector b = [sum_y, sum_xy, sum_x2y]
	
	var det_a = sum_1 * (sum_x2 * sum_x4 - sum_x3 * sum_x3) - 
				sum_x * (sum_x * sum_x4 - sum_x2 * sum_x3) + 
				sum_x2 * (sum_x * sum_x3 - sum_x2 * sum_x2)
	
	if abs(det_a) < 1e-10:
		# Fallback to linear regression if singular
		fit_linear_regression()
		return
	
	# Calculate coefficients using Cramer's rule
	var det_c = sum_y * (sum_x2 * sum_x4 - sum_x3 * sum_x3) - 
				sum_xy * (sum_x * sum_x4 - sum_x2 * sum_x3) + 
				sum_x2y * (sum_x * sum_x3 - sum_x2 * sum_x2)
	
	var det_b = sum_1 * (sum_xy * sum_x4 - sum_x2y * sum_x3) - 
				sum_x * (sum_y * sum_x4 - sum_x2y * sum_x2) + 
				sum_x2 * (sum_y * sum_x3 - sum_xy * sum_x2)
	
	var det_a_coeff = sum_1 * (sum_x2 * sum_x2y - sum_x3 * sum_xy) - 
					  sum_x * (sum_x * sum_x2y - sum_x2 * sum_y) + 
					  sum_x2 * (sum_x * sum_xy - sum_x2 * sum_y)
	
	# Store polynomial coefficients [a, b, c] for y = ax² + bx + c
	var poly_a = det_a_coeff / det_a
	var poly_b = det_b / det_a
	var poly_c = det_c / det_a
	
	# Store in slope/intercept for compatibility (using linear approximation)
	slope = poly_b + 2 * poly_a * 0.0  # derivative at x=0
	intercept = poly_c
	
	# Store full polynomial coefficients for equation display
	multiple_coefficients = [poly_a, poly_b, poly_c]
	
	# Calculate R-squared for polynomial
	calculate_polynomial_r_squared()
	
	# Calculate residuals for polynomial
	calculate_polynomial_residuals()

func fit_multiple_regression():
	"""Fit multiple regression (3D plane)"""
	if data_points_3d.size() < 3:
		return
	
	# Fit plane y = β₀ + β₁x₁ + β₂x₂ using least squares
	var n = data_points_3d.size()
	
	# Set up normal equations: X'X * β = X'y
	# X matrix: [1, x1, x2] for each observation
	var sum_1 = 0.0
	var sum_x1 = 0.0
	var sum_x2 = 0.0
	var sum_x1_x1 = 0.0
	var sum_x2_x2 = 0.0
	var sum_x1_x2 = 0.0
	var sum_y = 0.0
	var sum_x1_y = 0.0
	var sum_x2_y = 0.0
	
	for point in data_points_3d:
		var x1 = point.x
		var x2 = point.z
		var y = point.y
		
		sum_1 += 1.0
		sum_x1 += x1
		sum_x2 += x2
		sum_x1_x1 += x1 * x1
		sum_x2_x2 += x2 * x2
		sum_x1_x2 += x1 * x2
		sum_y += y
		sum_x1_y += x1 * y
		sum_x2_y += x2 * y
	
	# Solve 3x3 system: [X'X] * β = [X'y]
	# Matrix: [[n, sum_x1, sum_x2], [sum_x1, sum_x1_x1, sum_x1_x2], [sum_x2, sum_x1_x2, sum_x2_x2]]
	# Vector: [sum_y, sum_x1_y, sum_x2_y]
	
	var det = sum_1 * (sum_x1_x1 * sum_x2_x2 - sum_x1_x2 * sum_x1_x2) -
			  sum_x1 * (sum_x1 * sum_x2_x2 - sum_x2 * sum_x1_x2) +
			  sum_x2 * (sum_x1 * sum_x1_x2 - sum_x1_x1 * sum_x2)
	
	if abs(det) < 1e-10:
		# Fallback if singular matrix
		multiple_coefficients = [1.0, 1.0, 0.0]
		return
	
	# Calculate coefficients using Cramer's rule
	var det_beta0 = sum_y * (sum_x1_x1 * sum_x2_x2 - sum_x1_x2 * sum_x1_x2) -
					sum_x1_y * (sum_x1 * sum_x2_x2 - sum_x2 * sum_x1_x2) +
					sum_x2_y * (sum_x1 * sum_x1_x2 - sum_x1_x1 * sum_x2)
	
	var det_beta1 = sum_1 * (sum_x1_y * sum_x2_x2 - sum_x2_y * sum_x1_x2) -
					sum_x1 * (sum_y * sum_x2_x2 - sum_x2_y * sum_x2) +
					sum_x2 * (sum_y * sum_x1_x2 - sum_x1_y * sum_x2)
	
	var det_beta2 = sum_1 * (sum_x1_x1 * sum_x2_y - sum_x1_x2 * sum_x1_y) -
					sum_x1 * (sum_x1 * sum_x2_y - sum_x2 * sum_y) +
					sum_x2 * (sum_x1 * sum_x1_y - sum_x1_x1 * sum_y)
	
	var beta0 = det_beta0 / det  # Intercept
	var beta1 = det_beta1 / det  # Coefficient for x1
	var beta2 = det_beta2 / det  # Coefficient for x2
	
	multiple_coefficients = [beta1, beta2, beta0]
	
	# Calculate R-squared for multiple regression
	calculate_multiple_r_squared()
	
	# Calculate residuals for multiple regression
	calculate_multiple_residuals()

func fit_logistic_regression():
	"""Fit logistic regression using gradient descent"""
	if data_points.size() < 2:
		return
	
	# Initialize coefficients [intercept, slope]
	logistic_coefficients = [0.0, 0.0]
	
	var n = data_points.size()
	
	# Gradient descent optimization
	for iteration in range(max_iterations):
		var gradient = [0.0, 0.0]
		var cost = 0.0
		
		# Calculate predictions and gradients
		for point in data_points:
			var x = point.x
			var y = point.y
			var linear_combination = logistic_coefficients[0] + logistic_coefficients[1] * x
			var predicted_prob = sigmoid(linear_combination)
			
			# Calculate cost (log-likelihood)
			if y > 0.5:  # y = 1
				cost -= log(max(predicted_prob, 1e-15))
			else:  # y = 0
				cost -= log(max(1.0 - predicted_prob, 1e-15))
			
			# Calculate gradients
			var error = predicted_prob - y
			gradient[0] += error  # gradient for intercept
			gradient[1] += error * x  # gradient for slope
		
		# Update coefficients using gradient descent
		var old_coefficients = logistic_coefficients.duplicate()
		logistic_coefficients[0] -= learning_rate * gradient[0] / n
		logistic_coefficients[1] -= learning_rate * gradient[1] / n
		
		# Check for convergence
		var change = abs(logistic_coefficients[0] - old_coefficients[0]) + abs(logistic_coefficients[1] - old_coefficients[1])
		if change < convergence_threshold:
			print("Logistic regression converged after %d iterations" % iteration)
			break
	
	# Store in slope/intercept for compatibility
	intercept = logistic_coefficients[0]
	slope = logistic_coefficients[1]
	
	# Calculate pseudo R-squared (McFadden's R²)
	calculate_logistic_r_squared()
	
	# Calculate residuals
	calculate_logistic_residuals()

func sigmoid(x: float) -> float:
	"""Sigmoid activation function"""
	return 1.0 / (1.0 + exp(-clamp(x, -500, 500)))

func fit_ridge_regression():
	"""Fit Ridge (L2 regularized) regression"""
	if data_points.size() < 2:
		return
	
	var n = data_points.size()
	var X: Array[Array] = []
	var y: Array[float] = []
	
	# Create design matrix [1, x] for each point
	for point in data_points:
		X.append([1.0, point.x])
		y.append(point.y)
	
	# Ridge regression: β = (X'X + λI)^(-1) X'y
	# For 2x2 matrix (intercept + slope), we can solve analytically
	var sum_1 = float(n)
	var sum_x = 0.0
	var sum_x2 = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	
	for point in data_points:
		sum_x += point.x
		sum_x2 += point.x * point.x
		sum_y += point.y
		sum_xy += point.x * point.y
	
	# Build X'X + λI matrix
	var a11 = sum_1 + regularization_lambda  # X'X[0,0] + λ
	var a12 = sum_x                           # X'X[0,1]
	var a21 = sum_x                           # X'X[1,0]
	var a22 = sum_x2 + regularization_lambda # X'X[1,1] + λ
	
	# Build X'y vector
	var b1 = sum_y
	var b2 = sum_xy
	
	# Solve 2x2 system using inverse
	var det = a11 * a22 - a12 * a21
	if abs(det) < 1e-10:
		fit_linear_regression()  # Fallback
		return
	
	intercept = (a22 * b1 - a12 * b2) / det
	slope = (-a21 * b1 + a11 * b2) / det
	
	regularized_coefficients = [intercept, slope]
	
	# Calculate R-squared and residuals
	calculate_r_squared()
	calculate_residuals()

func fit_lasso_regression():
	"""Fit Lasso (L1 regularized) regression using coordinate descent"""
	if data_points.size() < 2:
		return
	
	var n = data_points.size()
	
	# Initialize coefficients
	regularized_coefficients = [0.0, 0.0]  # [intercept, slope]
	
	# Standardize data for better convergence
	var mean_x = 0.0
	var mean_y = 0.0
	for point in data_points:
		mean_x += point.x
		mean_y += point.y
	mean_x /= n
	mean_y /= n
	
	var std_x = 0.0
	for point in data_points:
		std_x += pow(point.x - mean_x, 2)
	std_x = sqrt(std_x / (n - 1))
	
	if std_x < 1e-10:
		fit_linear_regression()  # Fallback
		return
	
	# Coordinate descent algorithm
	for iteration in range(max_iterations):
		var old_coefficients = regularized_coefficients.duplicate()
		
		# Update intercept (no regularization)
		var sum_residual = 0.0
		for point in data_points:
			var x_std = (point.x - mean_x) / std_x
			var predicted = regularized_coefficients[0] + regularized_coefficients[1] * x_std
			sum_residual += point.y - predicted + regularized_coefficients[0]
		regularized_coefficients[0] = sum_residual / n
		
		# Update slope with L1 regularization (soft thresholding)
		var numerator = 0.0
		var denominator = 0.0
		for point in data_points:
			var x_std = (point.x - mean_x) / std_x
			var predicted = regularized_coefficients[0] + regularized_coefficients[1] * x_std
			var residual = point.y - predicted + regularized_coefficients[1] * x_std
			numerator += x_std * residual
			denominator += x_std * x_std
		
		if denominator > 0:
			var temp = numerator / denominator
			# Soft thresholding for L1 regularization
			if temp > regularization_lambda / denominator:
				regularized_coefficients[1] = temp - regularization_lambda / denominator
			elif temp < -regularization_lambda / denominator:
				regularized_coefficients[1] = temp + regularization_lambda / denominator
			else:
				regularized_coefficients[1] = 0.0
		
		# Check convergence
		var change = abs(regularized_coefficients[0] - old_coefficients[0]) + abs(regularized_coefficients[1] - old_coefficients[1])
		if change < convergence_threshold:
			break
	
	# Convert back to original scale
	intercept = regularized_coefficients[0] - regularized_coefficients[1] * mean_x / std_x
	slope = regularized_coefficients[1] / std_x
	
	# Calculate R-squared and residuals
	calculate_r_squared()
	calculate_residuals()

func calculate_r_squared():
	"""Calculate coefficient of determination"""
	if data_points.size() < 2:
		r_squared = 0.0
		return
	
	var mean_y = 0.0
	for point in data_points:
		mean_y += point.y
	mean_y /= data_points.size()
	
	var ss_tot = 0.0  # Total sum of squares
	var ss_res = 0.0  # Residual sum of squares
	
	for point in data_points:
		var predicted_y = slope * point.x + intercept
		ss_tot += pow(point.y - mean_y, 2)
		ss_res += pow(point.y - predicted_y, 2)
	
	r_squared = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 0.0
	correlation = sqrt(abs(r_squared)) * sign(slope)

func calculate_residuals():
	"""Calculate residuals for current model"""
	residuals.clear()
	
	for point in data_points:
		var predicted_y = slope * point.x + intercept
		var residual = point.y - predicted_y
		residuals.append(residual)

func calculate_polynomial_r_squared():
	"""Calculate R-squared for polynomial regression"""
	if data_points.size() < 2 or multiple_coefficients.size() < 3:
		r_squared = 0.0
		return
	
	var mean_y = 0.0
	for point in data_points:
		mean_y += point.y
	mean_y /= data_points.size()
	
	var ss_tot = 0.0  # Total sum of squares
	var ss_res = 0.0  # Residual sum of squares
	
	var poly_a = multiple_coefficients[0]
	var poly_b = multiple_coefficients[1]
	var poly_c = multiple_coefficients[2]
	
	for point in data_points:
		var x = point.x
		var predicted_y = poly_a * x * x + poly_b * x + poly_c
		ss_tot += pow(point.y - mean_y, 2)
		ss_res += pow(point.y - predicted_y, 2)
	
	r_squared = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 0.0
	correlation = sqrt(abs(r_squared)) * sign(poly_b)  # Use linear term for sign

func calculate_polynomial_residuals():
	"""Calculate residuals for polynomial model"""
	residuals.clear()
	
	if multiple_coefficients.size() < 3:
		return
	
	var poly_a = multiple_coefficients[0]
	var poly_b = multiple_coefficients[1]
	var poly_c = multiple_coefficients[2]
	
	for point in data_points:
		var x = point.x
		var predicted_y = poly_a * x * x + poly_b * x + poly_c
		var residual = point.y - predicted_y
		residuals.append(residual)

func calculate_multiple_r_squared():
	"""Calculate R-squared for multiple regression"""
	if data_points_3d.size() < 2 or multiple_coefficients.size() < 3:
		r_squared = 0.0
		return
	
	var mean_y = 0.0
	for point in data_points_3d:
		mean_y += point.y
	mean_y /= data_points_3d.size()
	
	var ss_tot = 0.0  # Total sum of squares
	var ss_res = 0.0  # Residual sum of squares
	
	var beta1 = multiple_coefficients[0]
	var beta2 = multiple_coefficients[1]
	var beta0 = multiple_coefficients[2]
	
	for point in data_points_3d:
		var x1 = point.x
		var x2 = point.z
		var y = point.y
		var predicted_y = beta0 + beta1 * x1 + beta2 * x2
		
		ss_tot += pow(y - mean_y, 2)
		ss_res += pow(y - predicted_y, 2)
	
	r_squared = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 0.0
	# For multiple regression, correlation is approximated
	correlation = sqrt(abs(r_squared))

func calculate_multiple_residuals():
	"""Calculate residuals for multiple regression model"""
	residuals.clear()
	
	if multiple_coefficients.size() < 3:
		return
	
	var beta1 = multiple_coefficients[0]
	var beta2 = multiple_coefficients[1]
	var beta0 = multiple_coefficients[2]
	
	for point in data_points_3d:
		var x1 = point.x
		var x2 = point.z
		var y = point.y
		var predicted_y = beta0 + beta1 * x1 + beta2 * x2
		var residual = y - predicted_y
		residuals.append(residual)

func calculate_logistic_r_squared():
	"""Calculate McFadden's pseudo R-squared for logistic regression"""
	if data_points.size() < 2 or logistic_coefficients.size() < 2:
		r_squared = 0.0
		return
	
	var log_likelihood_full = 0.0
	var log_likelihood_null = 0.0
	
	# Calculate proportion of 1s for null model
	var p_null = 0.0
	for point in data_points:
		if point.y > 0.5:
			p_null += 1.0
	p_null /= data_points.size()
	p_null = clamp(p_null, 1e-15, 1.0 - 1e-15)
	
	# Calculate log-likelihoods
	for point in data_points:
		var x = point.x
		var y = point.y
		
		# Full model likelihood
		var linear_combination = logistic_coefficients[0] + logistic_coefficients[1] * x
		var predicted_prob = sigmoid(linear_combination)
		predicted_prob = clamp(predicted_prob, 1e-15, 1.0 - 1e-15)
		
		if y > 0.5:  # y = 1
			log_likelihood_full += log(predicted_prob)
			log_likelihood_null += log(p_null)
		else:  # y = 0
			log_likelihood_full += log(1.0 - predicted_prob)
			log_likelihood_null += log(1.0 - p_null)
	
	# McFadden's pseudo R-squared
	r_squared = 1.0 - (log_likelihood_full / log_likelihood_null) if log_likelihood_null != 0 else 0.0
	r_squared = clamp(r_squared, 0.0, 1.0)
	
	# Approximate correlation for display
	correlation = sqrt(abs(r_squared)) * sign(logistic_coefficients[1])

func calculate_logistic_residuals():
	"""Calculate deviance residuals for logistic regression"""
	residuals.clear()
	
	if logistic_coefficients.size() < 2:
		return
	
	for point in data_points:
		var x = point.x
		var y = point.y
		var linear_combination = logistic_coefficients[0] + logistic_coefficients[1] * x
		var predicted_prob = sigmoid(linear_combination)
		predicted_prob = clamp(predicted_prob, 1e-15, 1.0 - 1e-15)
		
		# Deviance residual
		var deviance_component = 0.0
		if y > 0.5:  # y = 1
			deviance_component = -2.0 * log(predicted_prob)
		else:  # y = 0
			deviance_component = -2.0 * log(1.0 - predicted_prob)
		
		var deviance_residual = sign(y - predicted_prob) * sqrt(abs(deviance_component))
		residuals.append(deviance_residual)

func update_regression_visualization():
	"""Update regression line and related visualizations"""
	# Clear existing regression line
	for child in regression_line.get_children():
		child.queue_free()
	
	match regression_type:
		RegressionType.LINEAR, RegressionType.POLYNOMIAL, RegressionType.LOGISTIC, RegressionType.RIDGE, RegressionType.LASSO:
			create_regression_line()
		RegressionType.MULTIPLE:
			create_regression_plane()
	
	if show_residuals:
		update_residual_display()
	
	if show_confidence_intervals:
		update_confidence_intervals()

func create_regression_line():
	"""Create visual regression line"""
	match regression_type:
		RegressionType.POLYNOMIAL:
			if multiple_coefficients.size() >= 3:
				create_polynomial_curve()
			else:
				create_linear_line()
		RegressionType.LOGISTIC:
			create_logistic_curve()
		_:
			create_linear_line()

func create_linear_line():
	"""Create linear regression line"""
	if abs(slope) < 1e-10 and abs(intercept) < 1e-10:
		return
	
	var line_mesh = MeshInstance3D.new()
	var x_min = -2.0
	var x_max = 2.0
	var y_min = slope * x_min + intercept
	var y_max = slope * x_max + intercept
	
	var line_points = [Vector3(x_min, y_min, 0), Vector3(x_max, y_max, 0)]
	create_line_mesh(line_mesh, line_points, Color.RED)
	regression_line.add_child(line_mesh)

func create_polynomial_curve():
	"""Create polynomial regression curve"""
	var poly_a = multiple_coefficients[0]
	var poly_b = multiple_coefficients[1]
	var poly_c = multiple_coefficients[2]
	
	# Create curved line with multiple segments
	var line_points: Array[Vector3] = []
	var x_min = -2.0
	var x_max = 2.0
	var num_segments = 50
	var step = (x_max - x_min) / num_segments
	
	for i in range(num_segments + 1):
		var x = x_min + i * step
		var y = poly_a * x * x + poly_b * x + poly_c
		line_points.append(Vector3(x, y, 0))
	
	var curve_mesh = MeshInstance3D.new()
	create_curve_mesh(curve_mesh, line_points, Color.RED)
	regression_line.add_child(curve_mesh)

func create_logistic_curve():
	"""Create logistic regression sigmoid curve"""
	if logistic_coefficients.size() < 2:
		return
	
	var intercept_coeff = logistic_coefficients[0]
	var slope_coeff = logistic_coefficients[1]
	
	# Create sigmoid curve with multiple segments
	var line_points: Array[Vector3] = []
	var x_min = -3.0
	var x_max = 3.0
	var num_segments = 100
	var step = (x_max - x_min) / num_segments
	
	for i in range(num_segments + 1):
		var x = x_min + i * step
		var linear_combination = intercept_coeff + slope_coeff * x
		var y = sigmoid(linear_combination)
		line_points.append(Vector3(x, y, 0))
	
	var curve_mesh = MeshInstance3D.new()
	create_curve_mesh(curve_mesh, line_points, Color.RED)
	regression_line.add_child(curve_mesh)

func create_regression_plane():
	"""Create regression plane for multiple regression"""
	# Create a mesh representing the regression plane
	var plane_mesh = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(4.0, 4.0)
	plane_mesh.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.3)
	material.flags_transparent = true
	plane_mesh.material_override = material
	
	# Position plane based on regression coefficients
	if multiple_coefficients.size() >= 3:
		plane_mesh.position = Vector3(0, multiple_coefficients[2], 0)
	
	regression_line.add_child(plane_mesh)

func update_residual_display():
	"""Update residual lines visualization"""
	# Clear existing residuals
	for child in residual_display.get_children():
		child.queue_free()
	
	for i in range(min(data_points.size(), residuals.size())):
		var point = data_points[i]
		var predicted_y = slope * point.x + intercept
		var residual_line = MeshInstance3D.new()
		
		var line_points = [
			Vector3(point.x, point.y, 0.01),
			Vector3(point.x, predicted_y, 0.01)
		]
		
		var color = Color.GREEN if residuals[i] >= 0 else Color.ORANGE
		create_line_mesh(residual_line, line_points, color)
		residual_display.add_child(residual_line)

func update_confidence_intervals():
	"""Update confidence interval visualization"""
	# Clear existing confidence intervals
	var confidence_display = get_node_or_null("ConfidenceDisplay")
	if confidence_display:
		confidence_display.queue_free()
	
	confidence_display = Node3D.new()
	confidence_display.name = "ConfidenceDisplay"
	add_child(confidence_display)
	
	# Calculate 95% confidence intervals
	var confidence_level = 0.95
	var alpha = 1.0 - confidence_level
	var t_critical = 1.96  # Approximate for large samples
	
	# Standard error calculation
	var rmse = calculate_rmse()
	var n = data_points.size()
	
	if n < 3 or rmse == 0:
		return
	
	match regression_type:
		RegressionType.LINEAR:
			create_linear_confidence_bands(confidence_display, t_critical, rmse, n)
		RegressionType.POLYNOMIAL:
			create_polynomial_confidence_bands(confidence_display, t_critical, rmse, n)

func create_linear_confidence_bands(parent: Node3D, t_critical: float, rmse: float, n: int):
	"""Create confidence bands for linear regression"""
	var sum_x = 0.0
	var sum_x2 = 0.0
	
	for point in data_points:
		sum_x += point.x
		sum_x2 += point.x * point.x
	
	var mean_x = sum_x / n
	var sxx = sum_x2 - sum_x * sum_x / n
	
	if sxx <= 0:
		return
	
	# Create confidence band points
	var upper_points: Array[Vector3] = []
	var lower_points: Array[Vector3] = []
	var x_min = -2.0
	var x_max = 2.0
	var num_points = 50
	var step = (x_max - x_min) / num_points
	
	for i in range(num_points + 1):
		var x = x_min + i * step
		var predicted_y = slope * x + intercept
		
		# Standard error for prediction at x
		var se = rmse * sqrt(1.0/n + pow(x - mean_x, 2) / sxx)
		var margin = t_critical * se
		
		upper_points.append(Vector3(x, predicted_y + margin, 0.01))
		lower_points.append(Vector3(x, predicted_y - margin, 0.01))
	
	# Create upper confidence line
	var upper_mesh = MeshInstance3D.new()
	create_curve_mesh(upper_mesh, upper_points, Color(1, 0, 0, 0.3))
	parent.add_child(upper_mesh)
	
	# Create lower confidence line
	var lower_mesh = MeshInstance3D.new()
	create_curve_mesh(lower_mesh, lower_points, Color(1, 0, 0, 0.3))
	parent.add_child(lower_mesh)

func create_polynomial_confidence_bands(parent: Node3D, t_critical: float, rmse: float, n: int):
	"""Create confidence bands for polynomial regression"""
	if multiple_coefficients.size() < 3:
		return
	
	var poly_a = multiple_coefficients[0]
	var poly_b = multiple_coefficients[1]
	var poly_c = multiple_coefficients[2]
	
	# Simplified confidence intervals for polynomial (approximate)
	var upper_points: Array[Vector3] = []
	var lower_points: Array[Vector3] = []
	var x_min = -2.0
	var x_max = 2.0
	var num_points = 50
	var step = (x_max - x_min) / num_points
	
	# Simple approximation: larger margin for polynomial due to increased uncertainty
	var base_margin = t_critical * rmse * sqrt(3.0/n)  # Factor of 3 for 3 parameters
	
	for i in range(num_points + 1):
		var x = x_min + i * step
		var predicted_y = poly_a * x * x + poly_b * x + poly_c
		
		# Increase margin at extremes where polynomial uncertainty is higher
		var distance_factor = 1.0 + abs(x) * 0.5
		var margin = base_margin * distance_factor
		
		upper_points.append(Vector3(x, predicted_y + margin, 0.01))
		lower_points.append(Vector3(x, predicted_y - margin, 0.01))
	
	# Create upper confidence line
	var upper_mesh = MeshInstance3D.new()
	create_curve_mesh(upper_mesh, upper_points, Color(1, 0, 0, 0.3))
	parent.add_child(upper_mesh)
	
	# Create lower confidence line
	var lower_mesh = MeshInstance3D.new()
	create_curve_mesh(lower_mesh, lower_points, Color(1, 0, 0, 0.3))
	parent.add_child(lower_mesh)

func update_info_displays():
	"""Update statistical information displays"""
	# Statistics display
	var stats_text = "Regression Statistics\n\n"
	stats_text += "Data points: %d\n" % data_points.size()
	stats_text += "R² = %.4f\n" % r_squared
	stats_text += "Correlation = %.4f\n\n" % correlation
	
	if residuals.size() > 0:
		var rmse = calculate_rmse()
		var adj_r_squared = calculate_adjusted_r_squared()
		var aic = calculate_aic()
		var bic = calculate_bic()
		
		stats_text += "RMSE = %.4f\n" % rmse
		stats_text += "Adj. R² = %.4f\n" % adj_r_squared
		stats_text += "AIC = %.2f\n" % aic
		stats_text += "BIC = %.2f\n" % bic
		stats_text += "Mean residual = %.4f" % calculate_mean_residual()
	
	stats_display.text = stats_text
	
	# Equation display
	var equation_text = ""
	match regression_type:
		RegressionType.LINEAR, RegressionType.LOGISTIC:
			equation_text = "y = %.3fx + %.3f" % [slope, intercept]
		RegressionType.RIDGE:
			equation_text = "y = %.3fx + %.3f (λ=%.3f)" % [slope, intercept, regularization_lambda]
		RegressionType.LASSO:
			equation_text = "y = %.3fx + %.3f (λ=%.3f)" % [slope, intercept, regularization_lambda]
		RegressionType.POLYNOMIAL:
			if multiple_coefficients.size() >= 3:
				equation_text = "y = %.3fx² + %.3fx + %.3f" % [
					multiple_coefficients[0], 
					multiple_coefficients[1], 
					multiple_coefficients[2]
				]
			else:
				equation_text = "y = %.3fx + %.3f" % [slope, intercept]
		RegressionType.MULTIPLE:
			if multiple_coefficients.size() >= 3:
				equation_text = "y = %.3fx₁ + %.3fx₂ + %.3f" % [
					multiple_coefficients[0], 
					multiple_coefficients[1], 
					multiple_coefficients[2]
				]
	
	equation_display.text = equation_text

func calculate_rmse() -> float:
	"""Calculate root mean square error"""
	if residuals.is_empty():
		return 0.0
	
	var sum_squared_residuals = 0.0
	for residual in residuals:
		sum_squared_residuals += residual * residual
	
	return sqrt(sum_squared_residuals / residuals.size())

func calculate_mean_residual() -> float:
	"""Calculate mean residual"""
	if residuals.is_empty():
		return 0.0
	
	var sum_residuals = 0.0
	for residual in residuals:
		sum_residuals += residual
	
	return sum_residuals / residuals.size()

func calculate_adjusted_r_squared() -> float:
	"""Calculate adjusted R-squared"""
	var n = data_points.size() if regression_type != RegressionType.MULTIPLE else data_points_3d.size()
	var p = get_number_of_parameters()
	
	if n <= p or r_squared >= 1.0:
		return 0.0
	
	return 1.0 - (1.0 - r_squared) * (n - 1) / (n - p - 1)

func calculate_aic() -> float:
	"""Calculate Akaike Information Criterion"""
	var n = data_points.size() if regression_type != RegressionType.MULTIPLE else data_points_3d.size()
	var p = get_number_of_parameters()
	var mse = pow(calculate_rmse(), 2)
	
	if mse <= 0:
		return 0.0
	
	return n * log(mse) + 2 * p

func calculate_bic() -> float:
	"""Calculate Bayesian Information Criterion"""
	var n = data_points.size() if regression_type != RegressionType.MULTIPLE else data_points_3d.size()
	var p = get_number_of_parameters()
	var mse = pow(calculate_rmse(), 2)
	
	if mse <= 0:
		return 0.0
	
	return n * log(mse) + p * log(n)

func get_number_of_parameters() -> int:
	"""Get number of parameters for current regression type"""
	match regression_type:
		RegressionType.LINEAR, RegressionType.LOGISTIC:
			return 2  # slope + intercept
		RegressionType.POLYNOMIAL:
			return 3  # a + b + c for quadratic
		RegressionType.MULTIPLE:
			return 3  # β₀ + β₁ + β₂
		_:
			return 2

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

func create_curve_mesh(mesh_instance: MeshInstance3D, points: Array[Vector3], color: Color):
	"""Create curved line mesh from points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var indices: PackedInt32Array = []
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	material.flags_unshaded = true
	material.vertex_color_use_as_albedo = true
	mesh_instance.material_override = material

func change_regression_type():
	"""Change the type of regression analysis"""
	var current_index = regression_type as int
	regression_type = ((current_index + 1) % RegressionType.size()) as RegressionType
	
	reset_data()
	generate_sample_data()

func reset_data():
	"""Reset all data and visualizations"""
	data_points.clear()
	data_points_3d.clear()
	residuals.clear()
	slope = 0.0
	intercept = 0.0
	r_squared = 0.0
	correlation = 0.0
	
	# Clear visualizations
	for display in [scatter_plot, regression_line, residual_display]:
		for child in display.get_children():
			child.queue_free()
	
	update_info_displays()

func get_regression_type_name() -> String:
	"""Get display name for current regression type"""
	match regression_type:
		RegressionType.LINEAR:
			return "Linear Regression"
		RegressionType.POLYNOMIAL:
			return "Polynomial Regression"
		RegressionType.MULTIPLE:
			return "Multiple Regression"
		RegressionType.LOGISTIC:
			return "Logistic Regression"
		RegressionType.RIDGE:
			return "Ridge Regression"
		RegressionType.LASSO:
			return "Lasso Regression"
		_:
			return "Unknown"

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"regression_type": get_regression_type_name(),
		"num_data_points": data_points.size(),
		"slope": slope,
		"intercept": intercept,
		"r_squared": r_squared,
		"correlation": correlation,
		"rmse": calculate_rmse(),
		"mean_residual": calculate_mean_residual(),
		"residuals": residuals.duplicate()
	}