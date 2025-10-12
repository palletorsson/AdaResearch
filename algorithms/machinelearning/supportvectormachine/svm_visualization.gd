extends Node3D

# Support Vector Machine: Mathematical Justice & Boundary Politics
# Visualizes the politics of classification boundaries and margin optimization
# Demonstrates how algorithms create separating hyperplanes in high-dimensional identity spaces

@export_category("SVM Configuration")
@export var kernel_type: String = "rbf"  # linear, polynomial, rbf, sigmoid
@export var C_parameter: float = 1.0  # Regularization parameter
@export var gamma: float = 1.0  # Kernel coefficient
@export var degree: int = 3  # Polynomial degree
@export var tolerance: float = 0.001  # Numerical tolerance

@export_category("Data Configuration")
@export var num_positive_samples: int = 50
@export var num_negative_samples: int = 50
@export var data_dimension: int = 2  # For visualization
@export var class_separation: float = 2.0
@export var data_noise: float = 0.5

@export_category("Visualization")
@export var show_support_vectors: bool = true
@export var show_decision_boundary: bool = true
@export var show_margin_lines: bool = true
@export var support_vector_size: float = 0.3
@export var positive_color: Color = Color(0.2, 0.9, 0.3)  # Green
@export var negative_color: Color = Color(0.9, 0.3, 0.2)  # Red
@export var support_vector_color: Color = Color(0.9, 0.9, 0.2)  # Yellow
@export var boundary_color: Color = Color(0.9, 0.2, 0.9)  # Magenta

@export_category("Algorithm Animation")
@export var auto_start: bool = true
@export var step_delay: float = 0.1
@export var show_optimization_steps: bool = true

# SVM Algorithm State
var training_data: Array = []
var training_labels: Array = []
var support_vectors: Array = []
var support_vector_labels: Array = []
var alphas: Array = []
var bias: float = 0.0
var is_trained: bool = false

# Optimization state
var is_training: bool = false
var current_iteration: int = 0
var max_iterations: int = 1000
var optimization_timer: Timer

# Visual elements
var data_points: Array = []
var boundary_mesh: MeshInstance3D
var margin_meshes: Array = []
var ui_display: CanvasLayer

# Algorithm signals
signal training_step_complete()
signal training_finished()
signal classification_changed()

func _init():
	name = "SVM_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	generate_training_data()
	
	if auto_start:
		call_deferred("start_training")

func setup_ui():
	"""Create comprehensive UI for SVM visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400, 600)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for SVM information
	for i in range(20):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for animation"""
	optimization_timer = Timer.new()
	optimization_timer.wait_time = step_delay
	optimization_timer.timeout.connect(_on_optimization_timer_timeout)
	add_child(optimization_timer)

func generate_training_data():
	"""Generate training data with clear class separation"""
	training_data.clear()
	training_labels.clear()
	
	# Generate positive class samples
	for i in range(num_positive_samples):
		var point = Vector2(
			randf_range(-2, 2) + class_separation/2,
			randf_range(-2, 2) + data_noise * randf_range(-1, 1)
		)
		training_data.append(point)
		training_labels.append(1)
	
	# Generate negative class samples
	for i in range(num_negative_samples):
		var point = Vector2(
			randf_range(-2, 2) - class_separation/2,
			randf_range(-2, 2) + data_noise * randf_range(-1, 1)
		)
		training_data.append(point)
		training_labels.append(-1)
	
	create_data_visualization()
	print("Generated ", training_data.size(), " training samples")

func create_data_visualization():
	"""Create 3D visualization of training data"""
	clear_previous_visualization()
	
	for i in range(training_data.size()):
		var point = training_data[i]
		var label = training_labels[i]
		
		var sphere = create_data_point(point, label)
		data_points.append(sphere)
		add_child(sphere)

func create_data_point(point: Vector2, label: int) -> MeshInstance3D:
	"""Create a 3D sphere for a data point"""
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	sphere.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = positive_color if label == 1 else negative_color
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	sphere.material_override = material
	
	sphere.position = Vector3(point.x, point.y, 0)
	return sphere

func start_training():
	"""Start SVM training process"""
	if is_training:
		return
	
	is_training = true
	current_iteration = 0
	initialize_svm_parameters()
	
	if show_optimization_steps:
		optimization_timer.start()
	else:
		# Run full training immediately
		train_svm_full()
		create_decision_boundary()
	
	print("Starting SVM training with kernel: ", kernel_type)

func initialize_svm_parameters():
	"""Initialize SVM parameters"""
	alphas.clear()
	for i in range(training_data.size()):
		alphas.append(0.0)
	
	bias = 0.0
	support_vectors.clear()
	support_vector_labels.clear()

func _on_optimization_timer_timeout():
	"""Perform one step of SVM optimization"""
	if not is_training:
		return
	
	var converged = perform_smo_step()
	current_iteration += 1
	
	if converged or current_iteration >= max_iterations:
		is_training = false
		optimization_timer.stop()
		finalize_training()
		training_finished.emit()
	else:
		training_step_complete.emit()
	
	update_ui()

func perform_smo_step() -> bool:
	"""Perform one step of Sequential Minimal Optimization"""
	# Simplified SMO algorithm for educational purposes
	var num_changed = 0
	
	for i in range(training_data.size()):
		var Ei = calculate_error(i)
		
		if (training_labels[i] * Ei < -tolerance and alphas[i] < C_parameter) or \
		   (training_labels[i] * Ei > tolerance and alphas[i] > 0):
			
			# Select second alpha using heuristic
			var j = select_second_alpha(i, Ei)
			if j == -1:
				continue
			
			var Ej = calculate_error(j)
			
			# Update alphas
			if update_alphas(i, j, Ei, Ej):
				num_changed += 1
	
	return num_changed == 0

func calculate_error(i: int) -> float:
	"""Calculate prediction error for sample i"""
	var prediction = predict_sample(training_data[i])
	return prediction - training_labels[i]

func predict_sample(point: Vector2) -> float:
	"""Predict class for a single sample"""
	var result = bias
	
	for i in range(training_data.size()):
		if alphas[i] > 0:
			result += alphas[i] * training_labels[i] * kernel_function(training_data[i], point)
	
	return result

func kernel_function(x1: Vector2, x2: Vector2) -> float:
	"""Compute kernel function value"""
	match kernel_type:
		"linear":
			return x1.dot(x2)
		"polynomial":
			return pow(gamma * x1.dot(x2) + 1, degree)
		"rbf":
			var distance_sq = (x1 - x2).length_squared()
			return exp(-gamma * distance_sq)
		"sigmoid":
			return tanh(gamma * x1.dot(x2) + 1)
		_:
			return x1.dot(x2)  # Default to linear

func select_second_alpha(i: int, Ei: float) -> int:
	"""Select second alpha for SMO optimization"""
	var max_step = 0.0
	var best_j = -1
	
	for j in range(training_data.size()):
		if j == i:
			continue
		
		var Ej = calculate_error(j)
		var step = abs(Ei - Ej)
		
		if step > max_step:
			max_step = step
			best_j = j
	
	return best_j

func update_alphas(i: int, j: int, Ei: float, Ej: float) -> bool:
	"""Update alpha values using SMO algorithm"""
	var old_alpha_i = alphas[i]
	var old_alpha_j = alphas[j]
	
	# Calculate bounds
	var L: float
	var H: float
	
	if training_labels[i] != training_labels[j]:
		L = max(0, alphas[j] - alphas[i])
		H = min(C_parameter, C_parameter + alphas[j] - alphas[i])
	else:
		L = max(0, alphas[i] + alphas[j] - C_parameter)
		H = min(C_parameter, alphas[i] + alphas[j])
	
	if L == H:
		return false
	
	# Calculate eta
	var eta = 2 * kernel_function(training_data[i], training_data[j]) - \
			  kernel_function(training_data[i], training_data[i]) - \
			  kernel_function(training_data[j], training_data[j])
	
	if eta >= 0:
		return false
	
	# Update alphas
	alphas[j] = old_alpha_j - training_labels[j] * (Ei - Ej) / eta
	alphas[j] = clamp(alphas[j], L, H)
	
	if abs(alphas[j] - old_alpha_j) < 1e-5:
		return false
	
	alphas[i] = old_alpha_i + training_labels[i] * training_labels[j] * (old_alpha_j - alphas[j])
	
	# Update bias
	update_bias(i, j, old_alpha_i, old_alpha_j, Ei, Ej)
	
	return true

func update_bias(i: int, j: int, old_alpha_i: float, old_alpha_j: float, Ei: float, Ej: float):
	"""Update bias term"""
	var b1 = bias - Ei - training_labels[i] * (alphas[i] - old_alpha_i) * kernel_function(training_data[i], training_data[i]) - \
			 training_labels[j] * (alphas[j] - old_alpha_j) * kernel_function(training_data[i], training_data[j])
	
	var b2 = bias - Ej - training_labels[i] * (alphas[i] - old_alpha_i) * kernel_function(training_data[i], training_data[j]) - \
			 training_labels[j] * (alphas[j] - old_alpha_j) * kernel_function(training_data[j], training_data[j])
	
	if 0 < alphas[i] and alphas[i] < C_parameter:
		bias = b1
	elif 0 < alphas[j] and alphas[j] < C_parameter:
		bias = b2
	else:
		bias = (b1 + b2) / 2

func train_svm_full():
	"""Train SVM without animation"""
	initialize_svm_parameters()
	
	for iteration in range(max_iterations):
		if perform_smo_step():
			break
	
	finalize_training()

func finalize_training():
	"""Finalize SVM training"""
	extract_support_vectors()
	create_decision_boundary()
	update_support_vector_visualization()
	is_trained = true
	
	print("SVM training completed")
	print("Support vectors found: ", support_vectors.size())

func extract_support_vectors():
	"""Extract support vectors from training data"""
	support_vectors.clear()
	support_vector_labels.clear()
	
	for i in range(training_data.size()):
		if alphas[i] > tolerance:
			support_vectors.append(training_data[i])
			support_vector_labels.append(training_labels[i])

func create_decision_boundary():
	"""Create visualization of decision boundary"""
	if boundary_mesh:
		boundary_mesh.queue_free()
	
	boundary_mesh = MeshInstance3D.new()
	var mesh = create_boundary_mesh()
	boundary_mesh.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = boundary_color
	material.emission_enabled = true
	material.emission = boundary_color * 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	boundary_mesh.material_override = material
	
	add_child(boundary_mesh)

func create_boundary_mesh() -> ArrayMesh:
	"""Create mesh for decision boundary"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var resolution = 50
	var size = 8.0
	
	# Create grid of points and evaluate decision function
	for i in range(resolution):
		for j in range(resolution):
			var x = (i / float(resolution - 1)) * size - size/2
			var y = (j / float(resolution - 1)) * size - size/2
			var point = Vector2(x, y)
			
			var decision_value = predict_sample(point)
			
			# Create vertices near the decision boundary
			if abs(decision_value) < 0.1:  # Near boundary
				vertices.append(Vector3(x, y, 0))
				normals.append(Vector3(0, 0, 1))
				uvs.append(Vector2(i / float(resolution), j / float(resolution)))
	
	# Create simple point cloud for boundary
	for i in range(vertices.size()):
		indices.append(i)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	
	return array_mesh

func update_support_vector_visualization():
	"""Update visualization of support vectors"""
	if not show_support_vectors:
		return
	
	# Highlight support vectors
	for i in range(training_data.size()):
		if alphas[i] > tolerance and i < data_points.size():
			var material = data_points[i].material_override as StandardMaterial3D
			material.albedo_color = support_vector_color
			material.emission = support_vector_color * 0.5
			
			# Make support vectors larger
			var scale = Vector3.ONE * (1.0 + support_vector_size)
			data_points[i].scale = scale

func classify_new_point(point: Vector2) -> Dictionary:
	"""Classify a new point and return detailed results"""
	if not is_trained:
		return {"error": "SVM not trained"}
	
	var prediction = predict_sample(point)
	var class_label = 1 if prediction > 0 else -1
	var confidence = abs(prediction)
	
	return {
		"prediction": prediction,
		"class": class_label,
		"confidence": confidence,
		"distance_to_boundary": abs(prediction)
	}

func clear_previous_visualization():
	"""Clear previous visualization elements"""
	for point in data_points:
		point.queue_free()
	data_points.clear()
	
	if boundary_mesh:
		boundary_mesh.queue_free()
	
	for margin_mesh in margin_meshes:
		margin_mesh.queue_free()
	margin_meshes.clear()

func update_ui():
	"""Update UI with current SVM state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(20):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 20:
		labels[0].text = "🧠 Support Vector Machine - Boundary Politics"
		labels[1].text = "Kernel: " + kernel_type.capitalize()
		labels[2].text = "C Parameter: " + str(C_parameter)
		labels[3].text = "Gamma: " + str(gamma)
		labels[4].text = ""
		labels[5].text = "Training Status: " + ("Training..." if is_training else "Trained" if is_trained else "Not Started")
		labels[6].text = "Iteration: " + str(current_iteration) + "/" + str(max_iterations)
		labels[7].text = "Training Samples: " + str(training_data.size())
		labels[8].text = "Support Vectors: " + str(support_vectors.size())
		labels[9].text = "Bias: " + str(bias).pad_decimals(3)
		labels[10].text = ""
		labels[11].text = "Controls:"
		labels[12].text = "SPACE - Start/Stop Training"
		labels[13].text = "R - Reset Data"
		labels[14].text = "1-4 - Change Kernel"
		labels[15].text = "↑/↓ - Adjust C Parameter"
		labels[16].text = ""
		labels[17].text = "🏳️‍🌈 Algorithmic Justice Framework:"
		labels[18].text = "Examines how classification boundaries"
		labels[19].text = "separate identities in high-dimensional space"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_training:
					stop_training()
				else:
					start_training()
			KEY_R:
				reset_svm()
			KEY_1:
				change_kernel("linear")
			KEY_2:
				change_kernel("polynomial")
			KEY_3:
				change_kernel("rbf")
			KEY_4:
				change_kernel("sigmoid")
			KEY_UP:
				C_parameter = min(C_parameter * 1.5, 10.0)
				reset_svm()
			KEY_DOWN:
				C_parameter = max(C_parameter / 1.5, 0.1)
				reset_svm()

func stop_training():
	"""Stop SVM training"""
	is_training = false
	optimization_timer.stop()

func reset_svm():
	"""Reset SVM and regenerate data"""
	stop_training()
	is_trained = false
	generate_training_data()

func change_kernel(new_kernel: String):
	"""Change kernel type and retrain"""
	kernel_type = new_kernel
	reset_svm()
	print("Changed kernel to: ", kernel_type)

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Support Vector Machine",
		"description": "Classification with maximum margin hyperplane",
		"kernel": kernel_type,
		"parameters": {
			"C": C_parameter,
			"gamma": gamma,
			"degree": degree,
			"tolerance": tolerance
		},
		"training_status": {
			"is_training": is_training,
			"is_trained": is_trained,
			"iteration": current_iteration,
			"max_iterations": max_iterations
		},
		"model_info": {
			"support_vectors": support_vectors.size(),
			"bias": bias,
			"training_samples": training_data.size()
		}
	} 
