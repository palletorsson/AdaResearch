extends Node3D

# Principal Component Analysis: Dimensional Reduction & Identity Compression
# Visualizes how high-dimensional data can be projected onto lower dimensions
# Explores the politics of dimensionality reduction and information loss

@export_category("PCA Configuration")
@export var num_dimensions: int = 4  # Original data dimensions
@export var target_dimensions: int = 2  # Reduced dimensions
@export var show_all_components: bool = true
@export var normalize_data: bool = true
@export var center_data: bool = true

@export_category("Data Generation")
@export var num_samples: int = 100
@export var data_spread: float = 2.0
@export var correlation_strength: float = 0.7
@export var noise_level: float = 0.3

@export_category("Visualization")
@export var show_original_data: bool = true
@export var show_projected_data: bool = true
@export var show_principal_components: bool = true
@export var show_variance_explained: bool = true
@export var component_line_length: float = 3.0
@export var data_point_size: float = 0.08

@export_category("Animation")
@export var auto_start: bool = true
@export var animation_speed: float = 1.0
@export var show_projection_process: bool = true
@export var step_delay: float = 0.5

# Colors for visualization
@export var original_data_color: Color = Color(0.3, 0.3, 0.9, 0.7)  # Blue
@export var projected_data_color: Color = Color(0.9, 0.3, 0.3, 0.9)  # Red
@export var pc1_color: Color = Color(0.9, 0.2, 0.9, 1.0)  # Magenta
@export var pc2_color: Color = Color(0.2, 0.9, 0.2, 1.0)  # Green
@export var pc3_color: Color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow

# Data structures
var original_data: Array = []
var centered_data: Array = []
var normalized_data: Array = []
var covariance_matrix: Array = []
var eigenvalues: Array = []
var eigenvectors: Array = []
var principal_components: Array = []
var projected_data: Array = []
var variance_explained: Array = []

# Algorithm state
var is_computing: bool = false
var computation_step: int = 0
var computation_complete: bool = false
var computation_timer: Timer

# Visualization elements
var original_points: Array = []
var projected_points: Array = []
var component_lines: Array = []
var data_container: Node3D
var ui_display: CanvasLayer

# Statistical measures
var total_variance: float = 0.0
var explained_variance_ratio: Array = []

# Animation state
var projection_animation_active: bool = false
var animation_progress: float = 0.0

func _init():
	name = "PCA_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	setup_data_container()
	generate_data()
	
	if auto_start:
		call_deferred("start_pca_computation")

func setup_ui():
	"""Create comprehensive UI for PCA visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(450, 800)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for PCA information
	for i in range(30):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for step-by-step computation"""
	computation_timer = Timer.new()
	computation_timer.wait_time = step_delay
	computation_timer.timeout.connect(_on_computation_timer_timeout)
	add_child(computation_timer)

func setup_data_container():
	"""Setup container for data visualization"""
	data_container = Node3D.new()
	data_container.name = "Data_Container"
	add_child(data_container)

func generate_data():
	"""Generate high-dimensional correlated data"""
	original_data.clear()
	
	# Generate correlated data in higher dimensions
	for i in range(num_samples):
		var sample = []
		
		# Create base variables
		var base1 = randf_range(-data_spread, data_spread)
		var base2 = randf_range(-data_spread, data_spread)
		
		# Create correlated features
		sample.append(base1 + randf_range(-noise_level, noise_level))
		sample.append(base1 * correlation_strength + base2 * (1.0 - correlation_strength) + randf_range(-noise_level, noise_level))
		
		# Additional dimensions with varying correlations
		for j in range(2, num_dimensions):
			var correlation = correlation_strength * pow(0.7, j - 1)  # Decreasing correlation
			var feature = base1 * correlation + base2 * (1.0 - correlation) + randf_range(-noise_level * 2, noise_level * 2)
			sample.append(feature)
		
		original_data.append(sample)
	
	create_original_data_visualization()
	print("Generated ", num_samples, " samples with ", num_dimensions, " dimensions")

func create_original_data_visualization():
	"""Create 3D visualization of original data (first 3 dimensions)"""
	clear_visualizations()
	
	if not show_original_data:
		return
	
	for i in range(original_data.size()):
		var sample = original_data[i]
		
		# Use first 3 dimensions for 3D visualization
		var position = Vector3(
			sample[0] if sample.size() > 0 else 0,
			sample[1] if sample.size() > 1 else 0,
			sample[2] if sample.size() > 2 else 0
		)
		
		var point = create_data_point(position, original_data_color, data_point_size)
		original_points.append(point)
		data_container.add_child(point)

func create_data_point(position: Vector3, color: Color, size: float) -> MeshInstance3D:
	"""Create a 3D sphere for a data point"""
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2
	sphere.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = material
	
	sphere.position = position
	return sphere

func start_pca_computation():
	"""Start PCA computation process"""
	if is_computing:
		return
	
	is_computing = true
	computation_step = 0
	computation_complete = false
	
	if show_projection_process:
		computation_timer.start()
	else:
		compute_pca_full()
	
	print("Starting PCA computation...")

func _on_computation_timer_timeout():
	"""Handle computation timer timeout"""
	if not is_computing:
		return
	
	match computation_step:
		0:
			center_and_normalize_data()
			computation_step += 1
		1:
			compute_covariance_matrix()
			computation_step += 1
		2:
			compute_eigenvalues_vectors()
			computation_step += 1
		3:
			select_principal_components()
			computation_step += 1
		4:
			project_data()
			computation_step += 1
		5:
			finalize_pca()
			computation_step += 1
		_:
			computation_timer.stop()
			is_computing = false
			computation_complete = true
	
	update_ui()

func center_and_normalize_data():
	"""Center and optionally normalize the data"""
	centered_data.clear()
	normalized_data.clear()
	
	# Calculate means
	var means = []
	for i in range(num_dimensions):
		var sum = 0.0
		for sample in original_data:
			sum += sample[i]
		means.append(sum / original_data.size())
	
	# Center the data
	for sample in original_data:
		var centered_sample = []
		for i in range(num_dimensions):
			centered_sample.append(sample[i] - means[i])
		centered_data.append(centered_sample)
	
	# Normalize if requested
	if normalize_data:
		# Calculate standard deviations
		var std_devs = []
		for i in range(num_dimensions):
			var sum_sq = 0.0
			for sample in centered_data:
				sum_sq += sample[i] * sample[i]
			std_devs.append(sqrt(sum_sq / (centered_data.size() - 1)))
		
		# Normalize
		for sample in centered_data:
			var normalized_sample = []
			for i in range(num_dimensions):
				var normalized_value = sample[i] / std_devs[i] if std_devs[i] > 0 else 0
				normalized_sample.append(normalized_value)
			normalized_data.append(normalized_sample)
	else:
		normalized_data = centered_data.duplicate(true)
	
	print("Data centering and normalization complete")

func compute_covariance_matrix():
	"""Compute covariance matrix"""
	covariance_matrix.clear()
	
	var n = normalized_data.size()
	
	# Initialize covariance matrix
	for i in range(num_dimensions):
		var row = []
		for j in range(num_dimensions):
			row.append(0.0)
		covariance_matrix.append(row)
	
	# Calculate covariance
	for i in range(num_dimensions):
		for j in range(num_dimensions):
			var covariance = 0.0
			for sample in normalized_data:
				covariance += sample[i] * sample[j]
			covariance_matrix[i][j] = covariance / (n - 1)
	
	print("Covariance matrix computed")

func compute_eigenvalues_vectors():
	"""Compute eigenvalues and eigenvectors using power iteration method"""
	eigenvalues.clear()
	eigenvectors.clear()
	
	# Simplified eigenvalue/eigenvector computation using power iteration
	# This is educational - real implementations use more sophisticated methods
	
	var remaining_matrix = duplicate_matrix(covariance_matrix)
	
	for component in range(min(num_dimensions, target_dimensions + 1)):
		var result = power_iteration(remaining_matrix, 100)
		
		eigenvalues.append(result.eigenvalue)
		eigenvectors.append(result.eigenvector)
		
		# Deflate matrix (remove computed eigenvalue/eigenvector)
		remaining_matrix = deflate_matrix(remaining_matrix, result.eigenvalue, result.eigenvector)
	
	# Sort by eigenvalue (descending)
	sort_eigen_pairs()
	
	print("Eigenvalues computed: ", eigenvalues)

func power_iteration(matrix: Array, max_iterations: int) -> Dictionary:
	"""Power iteration method for finding dominant eigenvalue/eigenvector"""
	var n = matrix.size()
	var vector = []
	
	# Initialize random vector
	for i in range(n):
		vector.append(randf_range(-1.0, 1.0))
	
	# Normalize initial vector
	vector = normalize_vector(vector)
	
	var eigenvalue = 0.0
	
	for iteration in range(max_iterations):
		# Multiply matrix by vector
		var new_vector = matrix_vector_multiply(matrix, vector)
		
		# Calculate eigenvalue (Rayleigh quotient)
		eigenvalue = dot_product(vector, new_vector)
		
		# Normalize
		new_vector = normalize_vector(new_vector)
		
		# Check convergence
		var diff = 0.0
		for i in range(n):
			diff += abs(new_vector[i] - vector[i])
		
		vector = new_vector
		
		if diff < 1e-6:
			break
	
	return {
		"eigenvalue": eigenvalue,
		"eigenvector": vector
	}

func matrix_vector_multiply(matrix: Array, vector: Array) -> Array:
	"""Multiply matrix by vector"""
	var result = []
	for i in range(matrix.size()):
		var sum = 0.0
		for j in range(vector.size()):
			sum += matrix[i][j] * vector[j]
		result.append(sum)
	return result

func normalize_vector(vector: Array) -> Array:
	"""Normalize vector to unit length"""
	var length = 0.0
	for component in vector:
		length += component * component
	length = sqrt(length)
	
	if length == 0:
		return vector
	
	var normalized = []
	for component in vector:
		normalized.append(component / length)
	return normalized

func dot_product(v1: Array, v2: Array) -> float:
	"""Calculate dot product of two vectors"""
	var result = 0.0
	for i in range(min(v1.size(), v2.size())):
		result += v1[i] * v2[i]
	return result

func duplicate_matrix(matrix: Array) -> Array:
	"""Create deep copy of matrix"""
	var result = []
	for row in matrix:
		result.append(row.duplicate())
	return result

func deflate_matrix(matrix: Array, eigenvalue: float, eigenvector: Array) -> Array:
	"""Remove eigenvalue/eigenvector from matrix"""
	var result = duplicate_matrix(matrix)
	var n = matrix.size()
	
	# Outer product of eigenvector with itself
	for i in range(n):
		for j in range(n):
			result[i][j] -= eigenvalue * eigenvector[i] * eigenvector[j]
	
	return result

func sort_eigen_pairs():
	"""Sort eigenvalues and eigenvectors by eigenvalue (descending)"""
	var pairs = []
	for i in range(eigenvalues.size()):
		pairs.append({"value": eigenvalues[i], "vector": eigenvectors[i]})
	
	# Simple bubble sort by eigenvalue
	for i in range(pairs.size()):
		for j in range(pairs.size() - 1 - i):
			if pairs[j].value < pairs[j + 1].value:
				var temp = pairs[j]
				pairs[j] = pairs[j + 1]
				pairs[j + 1] = temp
	
	# Extract sorted values and vectors
	eigenvalues.clear()
	eigenvectors.clear()
	
	for pair in pairs:
		eigenvalues.append(pair.value)
		eigenvectors.append(pair.vector)

func select_principal_components():
	"""Select the top principal components"""
	principal_components.clear()
	
	var num_components = min(target_dimensions, eigenvalues.size())
	
	for i in range(num_components):
		principal_components.append(eigenvectors[i])
	
	# Calculate variance explained
	total_variance = 0.0
	for eigenvalue in eigenvalues:
		total_variance += eigenvalue
	
	explained_variance_ratio.clear()
	for i in range(num_components):
		explained_variance_ratio.append(eigenvalues[i] / total_variance)
	
	print("Selected ", num_components, " principal components")
	print("Explained variance ratios: ", explained_variance_ratio)

func project_data():
	"""Project data onto principal components"""
	projected_data.clear()
	
	for sample in normalized_data:
		var projected_sample = []
		
		# Project onto each principal component
		for pc in principal_components:
			var projection = dot_product(sample, pc)
			projected_sample.append(projection)
		
		projected_data.append(projected_sample)
	
	# Create visualization of projected data
	create_projected_data_visualization()
	
	print("Data projection complete")

func create_projected_data_visualization():
	"""Create visualization of projected data"""
	if not show_projected_data:
		return
	
	# Clear existing projected points
	for point in projected_points:
		point.queue_free()
	projected_points.clear()
	
	for i in range(projected_data.size()):
		var sample = projected_data[i]
		
		# Position based on projected dimensions
		var position = Vector3(
			sample[0] * 2.0 if sample.size() > 0 else 0,
			sample[1] * 2.0 if sample.size() > 1 else 0,
			0  # Projected data is typically 2D
		)
		
		# Offset projected data for better visualization
		position.z = -4.0
		
		var point = create_data_point(position, projected_data_color, data_point_size * 1.2)
		projected_points.append(point)
		data_container.add_child(point)

func create_principal_component_visualization():
	"""Create visualization of principal component vectors"""
	if not show_principal_components:
		return
	
	# Clear existing component lines
	for line in component_lines:
		line.queue_free()
	component_lines.clear()
	
	var colors = [pc1_color, pc2_color, pc3_color]
	
	for i in range(min(principal_components.size(), 3)):
		var pc = principal_components[i]
		var color = colors[i % colors.size()]
		
		# Create line representing principal component
		var line = create_component_line(pc, color, i)
		component_lines.append(line)
		data_container.add_child(line)

func create_component_line(component: Array, color: Color, index: int) -> MeshInstance3D:
	"""Create a line representing a principal component"""
	var line = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	
	# Use first 3 dimensions for visualization
	var direction = Vector3(
		component[0] if component.size() > 0 else 0,
		component[1] if component.size() > 1 else 0,
		component[2] if component.size() > 2 else 0
	)
	
	var length = component_line_length
	mesh.size = Vector3(0.05, 0.05, length)
	line.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	line.material_override = material
	
	# Position and orient the line
	line.position = Vector3.ZERO
	line.look_at(direction * length, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Add label
	var label = Label3D.new()
	label.text = "PC" + str(index + 1) + "\n" + str(explained_variance_ratio[index] * 100).pad_decimals(1) + "%"
	label.font_size = 20
	label.position = direction * length * 0.6
	line.add_child(label)
	
	return line

func finalize_pca():
	"""Finalize PCA computation"""
	create_principal_component_visualization()
	
	if show_projection_process:
		start_projection_animation()
	
	computation_complete = true
	print("PCA computation complete")

func start_projection_animation():
	"""Start animation showing projection process"""
	projection_animation_active = true
	animation_progress = 0.0
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.tween_property(self, "animation_progress", 1.0, 2.0)
	tween.tween_callback(func(): projection_animation_active = false)

func compute_pca_full():
	"""Compute full PCA without animation"""
	center_and_normalize_data()
	compute_covariance_matrix()
	compute_eigenvalues_vectors()
	select_principal_components()
	project_data()
	finalize_pca()

func get_reconstruction_error() -> float:
	"""Calculate reconstruction error"""
	if not computation_complete:
		return 0.0
	
	var total_error = 0.0
	
	for i in range(original_data.size()):
		var original = normalized_data[i]
		var projected = projected_data[i]
		
		# Reconstruct from projected data
		var reconstructed = []
		for j in range(num_dimensions):
			reconstructed.append(0.0)
		
		for pc_idx in range(principal_components.size()):
			var pc = principal_components[pc_idx]
			var projection_value = projected[pc_idx]
			
			for j in range(num_dimensions):
				reconstructed[j] += projection_value * pc[j]
		
		# Calculate error
		var error = 0.0
		for j in range(num_dimensions):
			error += (original[j] - reconstructed[j]) * (original[j] - reconstructed[j])
		
		total_error += sqrt(error)
	
	return total_error / original_data.size()

func clear_visualizations():
	"""Clear all visualization elements"""
	for point in original_points:
		point.queue_free()
	original_points.clear()
	
	for point in projected_points:
		point.queue_free()
	projected_points.clear()
	
	for line in component_lines:
		line.queue_free()
	component_lines.clear()

func update_ui():
	"""Update UI with current PCA state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(30):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 30:
		labels[0].text = "📊 PCA - Dimensional Reduction Politics"
		labels[1].text = "Original Dimensions: " + str(num_dimensions)
		labels[2].text = "Target Dimensions: " + str(target_dimensions)
		labels[3].text = "Samples: " + str(num_samples)
		labels[4].text = "Normalize Data: " + ("Yes" if normalize_data else "No")
		labels[5].text = ""
		labels[6].text = "Computation Status: " + ("Computing..." if is_computing else "Complete" if computation_complete else "Not Started")
		labels[7].text = "Step: " + str(computation_step + 1) + "/6"
		labels[8].text = ""
		
		if eigenvalues.size() > 0:
			labels[9].text = "Eigenvalues:"
			for i in range(min(eigenvalues.size(), 4)):
				labels[10 + i].text = "  λ" + str(i + 1) + ": " + str(eigenvalues[i]).pad_decimals(3)
		else:
			labels[9].text = "Eigenvalues: Not computed"
		
		labels[14].text = ""
		
		if explained_variance_ratio.size() > 0:
			labels[15].text = "Variance Explained:"
			var cumulative = 0.0
			for i in range(min(explained_variance_ratio.size(), 4)):
				cumulative += explained_variance_ratio[i]
				labels[16 + i].text = "  PC" + str(i + 1) + ": " + str(explained_variance_ratio[i] * 100).pad_decimals(1) + "% (Cum: " + str(cumulative * 100).pad_decimals(1) + "%)"
		else:
			labels[15].text = "Variance Explained: Not computed"
		
		labels[20].text = ""
		if computation_complete:
			labels[21].text = "Reconstruction Error: " + str(get_reconstruction_error()).pad_decimals(4)
		else:
			labels[21].text = "Reconstruction Error: Not available"
		
		labels[22].text = ""
		labels[23].text = "Visualization:"
		labels[24].text = "Original Data: " + ("Blue spheres" if show_original_data else "Hidden")
		labels[25].text = "Projected Data: " + ("Red spheres" if show_projected_data else "Hidden")
		labels[26].text = "Principal Components: " + ("Colored lines" if show_principal_components else "Hidden")
		labels[27].text = ""
		labels[28].text = "Controls: SPACE=Start, R=Reset, 1-3=Toggle views"
		labels[29].text = "🏳️‍🌈 Explores information loss & compression"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_computing:
					stop_computation()
				else:
					start_pca_computation()
			KEY_R:
				reset_pca()
			KEY_1:
				toggle_original_data()
			KEY_2:
				toggle_projected_data()
			KEY_3:
				toggle_principal_components()

func stop_computation():
	"""Stop PCA computation"""
	is_computing = false
	computation_timer.stop()

func reset_pca():
	"""Reset PCA and regenerate data"""
	stop_computation()
	computation_complete = false
	computation_step = 0
	
	# Clear data
	eigenvalues.clear()
	eigenvectors.clear()
	principal_components.clear()
	projected_data.clear()
	explained_variance_ratio.clear()
	
	clear_visualizations()
	generate_data()

func toggle_original_data():
	"""Toggle original data display"""
	show_original_data = !show_original_data
	if show_original_data:
		create_original_data_visualization()
	else:
		for point in original_points:
			point.queue_free()
		original_points.clear()

func toggle_projected_data():
	"""Toggle projected data display"""
	show_projected_data = !show_projected_data
	if show_projected_data and computation_complete:
		create_projected_data_visualization()
	else:
		for point in projected_points:
			point.queue_free()
		projected_points.clear()

func toggle_principal_components():
	"""Toggle principal component display"""
	show_principal_components = !show_principal_components
	if show_principal_components and computation_complete:
		create_principal_component_visualization()
	else:
		for line in component_lines:
			line.queue_free()
		component_lines.clear()

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Principal Component Analysis",
		"description": "Dimensionality reduction through eigenvalue decomposition",
		"parameters": {
			"original_dimensions": num_dimensions,
			"target_dimensions": target_dimensions,
			"normalize_data": normalize_data,
			"center_data": center_data,
			"num_samples": num_samples
		},
		"computation_status": {
			"is_computing": is_computing,
			"computation_complete": computation_complete,
			"current_step": computation_step
		},
		"results": {
			"eigenvalues": eigenvalues,
			"explained_variance_ratio": explained_variance_ratio,
			"reconstruction_error": get_reconstruction_error() if computation_complete else 0.0
		}
	} 
