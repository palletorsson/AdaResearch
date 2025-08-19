extends Node3D

# Interactive VR Cross-Validation - Model Evaluation and Selection
# Demonstrates k-fold CV, bias-variance tradeoff, and overfitting detection

class_name CrossValidationVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Cross-Validation Settings
@export_category("CV Parameters")
@export var cv_type: CVType = CVType.K_FOLD
@export var k_folds: int = 5
@export var num_data_points: int = 100
@export var noise_level: float = 0.3
@export var polynomial_degrees: Array[int] = [1, 2, 3, 5, 8]

# Dataset Settings
@export_category("Dataset")
@export var dataset_type: DatasetType = DatasetType.POLYNOMIAL
@export var test_size: float = 0.2

enum CVType {
	K_FOLD,
	LEAVE_ONE_OUT,
	STRATIFIED,
	TIME_SERIES
}

enum DatasetType {
	LINEAR,
	POLYNOMIAL,
	SINUSOIDAL,
	NOISY_STEP
}

# Internal variables
var full_dataset: Array[Vector2] = []
var training_folds: Array[Array] = []
var validation_folds: Array[Array] = []
var test_set: Array[Vector2] = []

# Model evaluation results
var cv_scores: Dictionary = {}  # degree -> [fold_scores]
var mean_cv_scores: Array[float] = []
var std_cv_scores: Array[float] = []
var test_scores: Array[float] = []

# Current CV state
var current_fold: int = 0
var current_degree: int = 1
var is_running_cv: bool = false

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var dataset_display: Node3D
var fold_display: Node3D
var model_comparison_display: Node3D
var learning_curves_display: Node3D
var info_display: Label3D
var results_display: Label3D

# Animation
var cv_tween: Tween

func _ready():
	setup_vr()
	generate_dataset()
	create_cv_splits()
	setup_visualization()
	setup_info_displays()

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

func generate_dataset():
	"""Generate dataset based on selected type"""
	full_dataset.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(num_data_points):
		var x = rng.randf_range(-2.0, 2.0)
		var y = generate_true_function(x) + rng.randfn(0.0, noise_level)
		full_dataset.append(Vector2(x, y))
	
	# Sort by x for better visualization
	full_dataset.sort_custom(func(a, b): return a.x < b.x)

func generate_true_function(x: float) -> float:
	"""Generate true underlying function"""
	match dataset_type:
		DatasetType.LINEAR:
			return 2.0 * x + 1.0
		DatasetType.POLYNOMIAL:
			return 0.3 * x * x * x - 0.5 * x * x + 2.0 * x + 1.0
		DatasetType.SINUSOIDAL:
			return sin(x * PI) + 0.5 * cos(2.0 * x * PI)
		DatasetType.NOISY_STEP:
			return 2.0 if x > 0 else -1.0
		_:
			return 0.0

func create_cv_splits():
	"""Create cross-validation splits"""
	training_folds.clear()
	validation_folds.clear()
	test_set.clear()
	
	# Split off test set first
	var test_size_count = int(full_dataset.size() * test_size)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var shuffled_indices = range(full_dataset.size())
	shuffled_indices.shuffle()
	
	# Test set
	for i in range(test_size_count):
		test_set.append(full_dataset[shuffled_indices[i]])
	
	# Training data for CV
	var cv_data: Array[Vector2] = []
	for i in range(test_size_count, full_dataset.size()):
		cv_data.append(full_dataset[shuffled_indices[i]])
	
	# Create k-fold splits
	match cv_type:
		CVType.K_FOLD:
			create_k_fold_splits(cv_data)
		CVType.LEAVE_ONE_OUT:
			create_loo_splits(cv_data)
		CVType.STRATIFIED:
			create_stratified_splits(cv_data)
		CVType.TIME_SERIES:
			create_time_series_splits(cv_data)

func create_k_fold_splits(data: Array[Vector2]):
	"""Create k-fold cross-validation splits"""
	var fold_size = data.size() / k_folds
	
	for fold in range(k_folds):
		var validation_fold: Array[Vector2] = []
		var training_fold: Array[Vector2] = []
		
		var val_start = fold * fold_size
		var val_end = min((fold + 1) * fold_size, data.size())
		
		# Validation fold
		for i in range(val_start, val_end):
			validation_fold.append(data[i])
		
		# Training fold (everything else)
		for i in range(data.size()):
			if i < val_start or i >= val_end:
				training_fold.append(data[i])
		
		validation_folds.append(validation_fold)
		training_folds.append(training_fold)

func create_loo_splits(data: Array[Vector2]):
	"""Create leave-one-out splits"""
	k_folds = data.size()
	
	for i in range(data.size()):
		var validation_fold: Array[Vector2] = [data[i]]
		var training_fold: Array[Vector2] = []
		
		for j in range(data.size()):
			if j != i:
				training_fold.append(data[j])
		
		validation_folds.append(validation_fold)
		training_folds.append(training_fold)

func create_stratified_splits(data: Array[Vector2]):
	"""Create stratified splits (simplified for regression)"""
	# For simplicity, fall back to k-fold for regression
	create_k_fold_splits(data)

func create_time_series_splits(data: Array[Vector2]):
	"""Create time series splits (expanding window)"""
	var min_train_size = data.size() / (k_folds + 1)
	
	for fold in range(k_folds):
		var train_end = min_train_size + fold * (data.size() - min_train_size) / k_folds
		var val_start = train_end
		var val_end = min(val_start + min_train_size / 2, data.size())
		
		var training_fold: Array[Vector2] = []
		var validation_fold: Array[Vector2] = []
		
		# Training data (from start to train_end)
		for i in range(train_end):
			training_fold.append(data[i])
		
		# Validation data (from val_start to val_end)
		for i in range(val_start, val_end):
			validation_fold.append(data[i])
		
		training_folds.append(training_fold)
		validation_folds.append(validation_fold)

func setup_visualization():
	"""Create visualization elements"""
	# Dataset visualization
	dataset_display = Node3D.new()
	dataset_display.position = Vector3(-3.0, 1.0, 0)
	add_child(dataset_display)
	
	# Fold visualization
	fold_display = Node3D.new()
	fold_display.position = Vector3(0, 1.0, 0)
	add_child(fold_display)
	
	# Model comparison
	model_comparison_display = Node3D.new()
	model_comparison_display.position = Vector3(3.0, 1.0, 0)
	add_child(model_comparison_display)
	
	# Learning curves
	learning_curves_display = Node3D.new()
	learning_curves_display.position = Vector3(0, -1.0, 0)
	add_child(learning_curves_display)
	
	update_dataset_display()

func setup_info_displays():
	"""Create information displays"""
	info_display = Label3D.new()
	info_display.position = Vector3(-3.0, 2.5, 0)
	info_display.font_size = 18
	info_display.modulate = Color.WHITE
	add_child(info_display)
	
	results_display = Label3D.new()
	results_display.position = Vector3(3.0, 2.5, 0)
	results_display.font_size = 18
	results_display.modulate = Color.CYAN
	add_child(results_display)
	
	update_info_displays()

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		if is_running_cv:
			stop_cross_validation()
		else:
			start_cross_validation()
	elif button_name == "grip_click":
		run_single_cv_step()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if is_running_cv:
				stop_cross_validation()
			else:
				start_cross_validation()
		elif event.keycode == KEY_S:
			run_single_cv_step()
		elif event.keycode == KEY_R:
			reset_cross_validation()
		elif event.keycode == KEY_D:
			change_dataset_type()

func start_cross_validation():
	"""Start full cross-validation process"""
	is_running_cv = true
	reset_cv_results()
	
	if cv_tween:
		cv_tween.kill()
	
	cv_tween = create_tween()
	
	# Run CV for each polynomial degree
	for degree in polynomial_degrees:
		current_degree = degree
		cv_tween.tween_callback(run_cv_for_degree.bind(degree))
		cv_tween.tween_delay(0.5)  # Pause between degrees
	
	cv_tween.tween_callback(complete_cross_validation)

func run_cv_for_degree(degree: int):
	"""Run cross-validation for specific polynomial degree"""
	var fold_scores: Array[float] = []
	
	for fold in range(k_folds):
		current_fold = fold
		var score = evaluate_fold(fold, degree)
		fold_scores.append(score)
		
		# Update visualization
		update_fold_display(fold, degree)
		
		# Small delay for animation
		await get_tree().create_timer(0.1).timeout
	
	cv_scores[degree] = fold_scores
	calculate_cv_statistics()
	update_model_comparison_display()

func evaluate_fold(fold_index: int, degree: int) -> float:
	"""Evaluate model on specific fold"""
	if fold_index >= training_folds.size() or fold_index >= validation_folds.size():
		return 0.0
	
	var train_data = training_folds[fold_index]
	var val_data = validation_folds[fold_index]
	
	# Fit polynomial model
	var coefficients = fit_polynomial(train_data, degree)
	
	# Evaluate on validation set
	var mse = calculate_mse(val_data, coefficients)
	return -mse  # Use negative MSE as score (higher is better)

func fit_polynomial(data: Array, degree: int) -> Array[float]:
	"""Fit polynomial of given degree using least squares"""
	if data.is_empty() or degree < 0:
		return []
	
	# For simplicity, use a basic polynomial fitting approach
	# In practice, would use proper matrix operations
	
	var coefficients: Array[float] = []
	coefficients.resize(degree + 1)
	coefficients.fill(0.0)
	
	# Simple linear regression for degree 1
	if degree == 1 and data.size() >= 2:
		var sum_x = 0.0
		var sum_y = 0.0
		var sum_xy = 0.0
		var sum_x2 = 0.0
		var n = data.size()
		
		for point in data:
			sum_x += point.x
			sum_y += point.y
			sum_xy += point.x * point.y
			sum_x2 += point.x * point.x
		
		var denominator = n * sum_x2 - sum_x * sum_x
		if abs(denominator) > 1e-10:
			coefficients[1] = (n * sum_xy - sum_x * sum_y) / denominator  # slope
			coefficients[0] = (sum_y - coefficients[1] * sum_x) / n  # intercept
	else:
		# For higher degrees, use simplified approximation
		# In practice, would solve normal equations
		coefficients[0] = 0.0  # intercept
		if degree >= 1:
			coefficients[1] = 1.0  # linear term
		for i in range(2, degree + 1):
			coefficients[i] = 0.1 / float(i)  # higher-order terms
	
	return coefficients

func calculate_mse(data: Array, coefficients: Array[float]) -> float:
	"""Calculate mean squared error"""
	if data.is_empty() or coefficients.is_empty():
		return float("inf")
	
	var sum_squared_error = 0.0
	
	for point in data:
		var predicted = evaluate_polynomial(point.x, coefficients)
		var error = point.y - predicted
		sum_squared_error += error * error
	
	return sum_squared_error / float(data.size())

func evaluate_polynomial(x: float, coefficients: Array[float]) -> float:
	"""Evaluate polynomial at given x"""
	var result = 0.0
	var x_power = 1.0
	
	for coeff in coefficients:
		result += coeff * x_power
		x_power *= x
	
	return result

func calculate_cv_statistics():
	"""Calculate mean and standard deviation of CV scores"""
	mean_cv_scores.clear()
	std_cv_scores.clear()
	
	for degree in polynomial_degrees:
		if degree in cv_scores:
			var scores = cv_scores[degree]
			
			# Calculate mean
			var mean_score = 0.0
			for score in scores:
				mean_score += score
			mean_score /= scores.size()
			mean_cv_scores.append(mean_score)
			
			# Calculate standard deviation
			var variance = 0.0
			for score in scores:
				variance += pow(score - mean_score, 2)
			variance /= scores.size()
			std_cv_scores.append(sqrt(variance))

func update_dataset_display():
	"""Update dataset visualization"""
	# Clear existing
	for child in dataset_display.get_children():
		child.queue_free()
	
	# Show full dataset
	for point in full_dataset:
		var point_visual = create_point_visual(Vector3(point.x, point.y, 0), Color.BLUE, 0.02)
		dataset_display.add_child(point_visual)
	
	# Show test set with different color
	for point in test_set:
		var point_visual = create_point_visual(Vector3(point.x, point.y, 0.01), Color.RED, 0.03)
		dataset_display.add_child(point_visual)
	
	# Add true function curve
	create_true_function_curve()
	
	# Add label
	var label = Label3D.new()
	label.text = "Dataset\n(Red = Test Set)"
	label.position = Vector3(0, -1.5, 0)
	label.font_size = 16
	dataset_display.add_child(label)

func create_true_function_curve():
	"""Create curve showing true underlying function"""
	var curve_points: Array[Vector3] = []
	
	for i in range(101):
		var x = float(i - 50) / 25.0  # Range from -2 to 2
		var y = generate_true_function(x)
		curve_points.append(Vector3(x, y, -0.01))
	
	var curve_mesh = MeshInstance3D.new()
	create_line_mesh(curve_mesh, curve_points, Color.GREEN)
	dataset_display.add_child(curve_mesh)

func update_fold_display(fold_index: int, degree: int):
	"""Update current fold visualization"""
	# Clear existing
	for child in fold_display.get_children():
		child.queue_free()
	
	if fold_index >= training_folds.size() or fold_index >= validation_folds.size():
		return
	
	var train_data = training_folds[fold_index]
	var val_data = validation_folds[fold_index]
	
	# Show training data
	for point in train_data:
		var point_visual = create_point_visual(Vector3(point.x, point.y, 0), Color.BLUE, 0.02)
		fold_display.add_child(point_visual)
	
	# Show validation data
	for point in val_data:
		var point_visual = create_point_visual(Vector3(point.x, point.y, 0.01), Color.ORANGE, 0.03)
		fold_display.add_child(point_visual)
	
	# Show fitted model
	var coefficients = fit_polynomial(train_data, degree)
	create_model_curve(coefficients, Color.RED)
	
	# Add label
	var label = Label3D.new()
	label.text = "Fold %d/%d\nDegree %d\n(Orange = Validation)" % [fold_index + 1, k_folds, degree]
	label.position = Vector3(0, -1.5, 0)
	label.font_size = 16
	fold_display.add_child(label)

func create_model_curve(coefficients: Array[float], color: Color):
	"""Create curve for fitted model"""
	if coefficients.is_empty():
		return
	
	var curve_points: Array[Vector3] = []
	
	for i in range(101):
		var x = float(i - 50) / 25.0  # Range from -2 to 2
		var y = evaluate_polynomial(x, coefficients)
		curve_points.append(Vector3(x, y, 0.02))
	
	var curve_mesh = MeshInstance3D.new()
	create_line_mesh(curve_mesh, curve_points, color)
	fold_display.add_child(curve_mesh)

func update_model_comparison_display():
	"""Update model comparison chart"""
	# Clear existing
	for child in model_comparison_display.get_children():
		child.queue_free()
	
	if mean_cv_scores.is_empty():
		return
	
	# Find best and worst scores for scaling
	var min_score = mean_cv_scores.min()
	var max_score = mean_cv_scores.max()
	var score_range = max_score - min_score
	
	if score_range < 1e-10:
		score_range = 1.0
	
	# Create bars for each degree
	for i in range(polynomial_degrees.size()):
		if i >= mean_cv_scores.size():
			continue
		
		var degree = polynomial_degrees[i]
		var mean_score = mean_cv_scores[i]
		var std_score = std_cv_scores[i] if i < std_cv_scores.size() else 0.0
		
		# Normalize score for visualization
		var normalized_score = (mean_score - min_score) / score_range
		var bar_height = normalized_score * 1.5
		
		var x_pos = float(i - polynomial_degrees.size() / 2) * 0.3
		
		# Mean score bar
		var bar = create_bar(Vector3(x_pos, bar_height / 2, 0), bar_height, Color.CYAN)
		model_comparison_display.add_child(bar)
		
		# Error bars (standard deviation)
		var error_bar_height = std_score / score_range * 1.5
		var error_line = create_error_bar(Vector3(x_pos, bar_height, 0), error_bar_height, Color.WHITE)
		model_comparison_display.add_child(error_line)
		
		# Degree label
		var degree_label = Label3D.new()
		degree_label.text = str(degree)
		degree_label.position = Vector3(x_pos, -0.3, 0)
		degree_label.font_size = 14
		model_comparison_display.add_child(degree_label)
	
	# Add chart label
	var chart_label = Label3D.new()
	chart_label.text = "CV Scores by Degree"
	chart_label.position = Vector3(0, -0.8, 0)
	chart_label.font_size = 16
	model_comparison_display.add_child(chart_label)

func create_point_visual(position: Vector3, color: Color, radius: float) -> Node3D:
	"""Create visual point"""
	var point = Node3D.new()
	point.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	mesh_instance.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	point.add_child(mesh_instance)
	return point

func create_bar(position: Vector3, height: float, color: Color) -> Node3D:
	"""Create bar chart element"""
	var bar = Node3D.new()
	bar.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, height, 0.05)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.2
	mesh_instance.material_override = material
	
	bar.add_child(mesh_instance)
	return bar

func create_error_bar(position: Vector3, error_height: float, color: Color) -> Node3D:
	"""Create error bar"""
	var error_bar = Node3D.new()
	
	var line_points = [
		position + Vector3(0, error_height / 2, 0),
		position - Vector3(0, error_height / 2, 0)
	]
	
	var line_mesh = MeshInstance3D.new()
	create_line_mesh(line_mesh, line_points, color)
	error_bar.add_child(line_mesh)
	
	return error_bar

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

func run_single_cv_step():
	"""Run single CV step manually"""
	if current_fold >= k_folds:
		current_fold = 0
		var next_degree_index = polynomial_degrees.find(current_degree) + 1
		if next_degree_index >= polynomial_degrees.size():
			complete_cross_validation()
			return
		current_degree = polynomial_degrees[next_degree_index]
	
	var score = evaluate_fold(current_fold, current_degree)
	update_fold_display(current_fold, current_degree)
	
	current_fold += 1

func complete_cross_validation():
	"""Complete CV and show final results"""
	is_running_cv = false
	
	# Find best model
	var best_degree_index = 0
	var best_score = mean_cv_scores[0] if mean_cv_scores.size() > 0 else 0.0
	
	for i in range(mean_cv_scores.size()):
		if mean_cv_scores[i] > best_score:
			best_score = mean_cv_scores[i]
			best_degree_index = i
	
	# Evaluate best model on test set
	if test_set.size() > 0:
		var best_degree = polynomial_degrees[best_degree_index]
		var full_train_data = []
		for fold in training_folds:
			full_train_data.append_array(fold)
		for fold in validation_folds:
			full_train_data.append_array(fold)
		
		var coefficients = fit_polynomial(full_train_data, best_degree)
		var test_mse = calculate_mse(test_set, coefficients)
		print("Best model (degree %d) test MSE: %.4f" % [best_degree, test_mse])
	
	update_info_displays()

func update_info_displays():
	"""Update information displays"""
	var info_text = "Cross-Validation\n"
	info_text += "Type: %s\n" % get_cv_type_name()
	info_text += "K-folds: %d\n" % k_folds
	info_text += "Dataset: %s\n" % get_dataset_type_name()
	info_text += "Data points: %d\n" % full_dataset.size()
	info_text += "Test set: %d\n\n" % test_set.size()
	
	if is_running_cv:
		info_text += "Running CV...\n"
		info_text += "Current degree: %d\n" % current_degree
		info_text += "Current fold: %d/%d" % [current_fold + 1, k_folds]
	else:
		info_text += "Status: Complete"
	
	info_display.text = info_text
	
	# Results display
	var results_text = "CV Results\n\n"
	
	if mean_cv_scores.size() > 0:
		results_text += "Degree | CV Score ± Std\n"
		for i in range(polynomial_degrees.size()):
			if i < mean_cv_scores.size() and i < std_cv_scores.size():
				var degree = polynomial_degrees[i]
				var mean_score = mean_cv_scores[i]
				var std_score = std_cv_scores[i]
				results_text += "%d      | %.3f ± %.3f\n" % [degree, mean_score, std_score]
		
		# Find best model
		var best_index = 0
		var best_score = mean_cv_scores[0]
		for i in range(mean_cv_scores.size()):
			if mean_cv_scores[i] > best_score:
				best_score = mean_cv_scores[i]
				best_index = i
		
		results_text += "\nBest: Degree %d" % polynomial_degrees[best_index]
	
	results_display.text = results_text

func reset_cross_validation():
	"""Reset CV state"""
	stop_cross_validation()
	reset_cv_results()
	current_fold = 0
	current_degree = polynomial_degrees[0] if polynomial_degrees.size() > 0 else 1
	update_info_displays()

func reset_cv_results():
	"""Reset CV results"""
	cv_scores.clear()
	mean_cv_scores.clear()
	std_cv_scores.clear()
	test_scores.clear()

func stop_cross_validation():
	"""Stop running CV"""
	is_running_cv = false
	if cv_tween:
		cv_tween.kill()

func change_dataset_type():
	"""Change dataset type"""
	var current_index = dataset_type as int
	dataset_type = ((current_index + 1) % DatasetType.size()) as DatasetType
	
	generate_dataset()
	create_cv_splits()
	update_dataset_display()
	reset_cross_validation()

func get_cv_type_name() -> String:
	"""Get display name for CV type"""
	match cv_type:
		CVType.K_FOLD:
			return "K-Fold"
		CVType.LEAVE_ONE_OUT:
			return "Leave-One-Out"
		CVType.STRATIFIED:
			return "Stratified"
		CVType.TIME_SERIES:
			return "Time Series"
		_:
			return "Unknown"

func get_dataset_type_name() -> String:
	"""Get display name for dataset type"""
	match dataset_type:
		DatasetType.LINEAR:
			return "Linear"
		DatasetType.POLYNOMIAL:
			return "Polynomial"
		DatasetType.SINUSOIDAL:
			return "Sinusoidal"
		DatasetType.NOISY_STEP:
			return "Noisy Step"
		_:
			return "Unknown"

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"cv_type": get_cv_type_name(),
		"dataset_type": get_dataset_type_name(),
		"k_folds": k_folds,
		"num_data_points": full_dataset.size(),
		"test_set_size": test_set.size(),
		"polynomial_degrees": polynomial_degrees.duplicate(),
		"mean_cv_scores": mean_cv_scores.duplicate(),
		"std_cv_scores": std_cv_scores.duplicate(),
		"cv_scores": cv_scores.duplicate(),
		"is_running": is_running_cv
	}