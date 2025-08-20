# Neural Network Visualization: Learning & Adaptation in 3D Space
# This algorithm visualizes how neural networks learn through backpropagation,
# showing weight changes, activation flows, and emergent pattern recognition.
#
# Enhanced by Gemini:
# - Corrected 3D orientation for weight connections.
# - Added interactive orbit camera (Right-click + drag to orbit, Wheel to zoom).
# - Implemented a real-time 3D error graph.
# - Added selectable activation functions (Sigmoid, ReLU, Tanh).
# - Added a WorldEnvironment with a glow effect for better visuals.
# - Implemented true mini-batch gradient descent.
# - Fixed AmbientLight error for Godot 4 compatibility.

extends Node3D

# --- Configuration ---
@export_category("Network Configuration")
@export var input_layer_size: int = 4
@export var hidden_layer_sizes: Array[int] = [6, 4]
@export var output_layer_size: int = 2
@export var learning_rate: float = 0.1

enum ActivationType { SIGMOID, RELU, TANH }
@export var activation_function: ActivationType = ActivationType.SIGMOID

@export_category("Training")
@export var auto_train: bool = true
@export var training_iterations: int = 1000 # Total number of batches to process
@export var batch_size: int = 10
@export var training_speed: float = 1.0

@export_category("Visualization")
@export var neuron_size: float = 0.3
@export var layer_spacing: float = 3.0
@export var neuron_spacing: float = 1.5
@export var show_weights: bool = true
@export var show_activations: bool = true

# --- Network State ---
var layers = []  # Array of layer arrays containing neurons
var weights = []  # Weight matrices between layers
var biases = []  # Bias vectors for each layer
var activations = []  # Current activation values
var z_values = [] # Pre-activation values (needed for derivatives)

# --- Visual Components ---
var neuron_meshes = []  # 3D visual representations of neurons
var weight_lines = []  # Lines showing connections between neurons
var info_display: Label3D
var error_graph: Node3D
var error_history: Array[float] = []

# --- Training State ---
var current_epoch: int = 0
var current_error: float = 0.0
var training_data = []
var target_data = []
var is_training: bool = false

# --- Camera Control ---
var camera: Camera3D
var camera_pivot: Node3D
var camera_distance: float = 15.0
var camera_rotation: Vector2 = Vector2(-0.5, 0.5)

#=============================================================================
#  Engine Functions
#=============================================================================

func _ready():
	# Initialize random seed
	randomize()

	# Setup camera for interactive control
	setup_camera()
	
	# Build network architecture
	build_network()
	
	# Generate training data (XOR problem as example)
	generate_training_data()
	
	# Create 3D visualization
	create_visualization()
	
	# Add lighting and environment for glow effect
	setup_environment()
	
	# Setup training loop
	if auto_train:
		start_training()

func _input(event):
	# Handle interactive camera controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
			update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(50.0, camera_distance + 1.0)
			update_camera()
			
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation.x -= event.relative.y * 0.01
		camera_rotation.y -= event.relative.x * 0.01
		camera_rotation.x = clamp(camera_rotation.x, -PI / 2.1, PI / 2.1)
		update_camera()

	# Handle keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("Resetting network.")
				reset_network()
			KEY_T:
				if not is_training:
					print("Starting training.")
					start_training()
			KEY_SPACE:
				# Test with a random input
				var test_input = []
				for i in range(input_layer_size): test_input.append(randf())
				var result = test_network(test_input)
				print("Test Input: ", test_input)
				print("Network Output: ", result)

#=============================================================================
#  Initialization and Setup
#=============================================================================

func build_network():
	"""Initialize the neural network structure with random weights and biases."""
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	
	layers.clear()
	activations.clear()
	z_values.clear()
	weights.clear()
	biases.clear()
	
	for i in range(layer_sizes.size()):
		layers.append(Array())
		activations.append(PackedFloat32Array())
		z_values.append(PackedFloat32Array())
		activations[i].resize(layer_sizes[i])
		z_values[i].resize(layer_sizes[i])
	
	# Initialize weights (Xavier/Glorot initialization)
	for i in range(layer_sizes.size() - 1):
		var fan_in = float(layer_sizes[i])
		var fan_out = float(layer_sizes[i + 1])
		var limit = sqrt(6.0 / (fan_in + fan_out))
		var w_matrix = []
		for _j in range(layer_sizes[i]):
			var w_row = PackedFloat32Array()
			w_row.resize(layer_sizes[i+1])
			for k in range(layer_sizes[i+1]):
				w_row[k] = randf_range(-limit, limit)
			w_matrix.append(w_row)
		weights.append(w_matrix)

	# Initialize biases
	for i in range(1, layer_sizes.size()):
		var b_vector = PackedFloat32Array()
		b_vector.resize(layer_sizes[i])
		# Biases are often initialized to zero or a small constant
		b_vector.fill(0.0)
		biases.append(b_vector)

func generate_training_data():
	"""Generate XOR training data as a classic neural network problem."""
	training_data = [
		[0.0, 0.0, 0.0, 1.0],
		[0.0, 1.0, 1.0, 0.0],
		[1.0, 0.0, 1.0, 0.0],
		[1.0, 1.0, 0.0, 1.0]
	]
	target_data = [
		[1.0, 0.0],
		[0.0, 1.0],
		[0.0, 1.0],
		[1.0, 0.0]
	]

func create_visualization():
	"""Create 3D visualization of the neural network."""
	# Clear previous visuals
	for child in get_children():
		if child is MeshInstance3D or child.name == "ErrorGraph" or child is Label3D or child is WorldEnvironment or child is DirectionalLight3D or child.name == "CameraPivot":
			child.queue_free()
	neuron_meshes.clear()
	weight_lines.clear()

	# Create neurons
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	for layer_idx in range(layer_sizes.size()):
		var layer_meshes = []
		var num_neurons = layer_sizes[layer_idx]
		for neuron_idx in range(num_neurons):
			var neuron = create_neuron(layer_idx, neuron_idx, num_neurons)
			layer_meshes.append(neuron)
			add_child(neuron)
		neuron_meshes.append(layer_meshes)
	
	# Create weight connections
	if show_weights:
		create_weight_lines()
	
	create_info_display()
	create_error_graph()
	# Re-setup environment and camera after clearing
	setup_camera()
	setup_environment()

func setup_camera():
	"""Setup the camera pivot and initial position."""
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Create a pivot node at the center of the network for smooth rotation
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	var network_center_x = (layer_sizes.size() - 1) * layer_spacing / 2.0
	camera_pivot.position = Vector3(network_center_x, 0, 0)
	add_child(camera_pivot)
	
	# Parent the camera to the pivot
	if camera.get_parent() != camera_pivot:
		if camera.get_parent():
			camera.get_parent().remove_child(camera)
		camera_pivot.add_child(camera)
		
	update_camera()

func update_camera():
	"""Update camera position based on rotation and distance."""
	if not is_instance_valid(camera_pivot) or not is_instance_valid(camera): return
	camera_pivot.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0)
	camera.position = Vector3(0, 0, camera_distance)

func setup_environment():
	"""Add lighting and a WorldEnvironment for glow and ambient light."""
	# Add a WorldEnvironment node to enable glow and set ambient light
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	
	# Glow effect
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 1.0
	
	# Ambient light settings (replaces the old AmbientLight node)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.3)
	env.ambient_light_energy = 1.0

	world_env.environment = env
	add_child(world_env)
	
	# Add key light
	var light = DirectionalLight3D.new()
	light.transform.basis = Basis.from_euler(Vector3(-0.8, -0.6, 0))
	add_child(light)

#=============================================================================
#  3D Object Creation
#=============================================================================

func create_neuron(layer_idx: int, neuron_idx: int, layer_size: int) -> MeshInstance3D:
	"""Create a 3D sphere representing a neuron."""
	var neuron = MeshInstance3D.new()
	neuron.mesh = SphereMesh.new()
	neuron.mesh.radius = neuron_size
	neuron.mesh.height = neuron_size * 2
	
	var x = layer_idx * layer_spacing
	var y = (neuron_idx - (layer_size - 1) * 0.5) * neuron_spacing
	neuron.position = Vector3(x, y, 0)
	
	var material = StandardMaterial3D.new()
	if layer_idx == 0: material.albedo_color = Color.GREEN
	elif layer_idx == neuron_meshes.size() - 1: material.albedo_color = Color.RED
	else: material.albedo_color = Color.BLUE
	
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy = 0.5
	neuron.material_override = material
	
	return neuron

func create_weight_lines():
	"""Create lines representing weights between neurons."""
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	for layer_idx in range(layer_sizes.size() - 1):
		for from_idx in range(layer_sizes[layer_idx]):
			for to_idx in range(layer_sizes[layer_idx + 1]):
				var line = create_weight_line(layer_idx, from_idx, layer_idx + 1, to_idx)
				weight_lines.append(line)
				add_child(line)

func create_weight_line(from_layer: int, from_neuron: int, to_layer: int, to_neuron: int) -> MeshInstance3D:
	"""Create a cylinder representing a weight, correctly oriented."""
	var from_pos = neuron_meshes[from_layer][from_neuron].position
	var to_pos = neuron_meshes[to_layer][to_neuron].position
	
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var direction = to_pos - from_pos
	var distance = direction.length()
	cylinder.height = distance
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	line.mesh = cylinder
	
	# --- Correct Rotation Logic ---
	# To orient the cylinder correctly, we construct a custom transform.
	# The CylinderMesh's height is aligned with its local Y-axis.
	# We need to create a rotation basis where the Y-axis points in the
	# direction of the connection (from_pos to to_pos).

	# 1. Define the new Y-axis as the normalized direction vector.
	var new_y = direction.normalized()
	
	# 2. Define the new X-axis. We get this by taking the cross product of a
	# world 'up' vector and our new Y-axis. This gives a vector that is
	# perpendicular to both, which is perfect for the X-axis.
	# We handle the edge case where the connection is perfectly vertical.
	var new_x
	if new_y.is_equal_approx(Vector3.UP) or new_y.is_equal_approx(Vector3.DOWN):
		# If vertical, use Forward vector for cross product
		new_x = Vector3.FORWARD.cross(new_y).normalized()
	else:
		new_x = Vector3.UP.cross(new_y).normalized()
	
	# 3. Define the new Z-axis by taking the cross product of Y and X.
	# This completes the right-handed coordinate system.
	var new_z = new_y.cross(new_x).normalized()
	
	# 4. Create the new basis and transform.
	var new_basis = Basis(new_x, new_y, new_z)
	var new_position = (from_pos + to_pos) / 2.0
	line.transform = Transform3D(new_basis, new_position)
	
	var material = StandardMaterial3D.new()
	var weight_value = weights[from_layer][from_neuron][to_neuron]
	var intensity = clamp(abs(weight_value), 0.0, 1.0)
	
	if weight_value > 0: material.albedo_color = Color.WHITE.lerp(Color.YELLOW, intensity)
	else: material.albedo_color = Color.WHITE.lerp(Color.MAGENTA, intensity)
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	line.material_override = material
	
	return line

func create_info_display():
	info_display = get_node_or_null("InfoLabel") as Label3D
	if not info_display:
		info_display = Label3D.new()
		info_display.name = "InfoLabel"
		info_display.font_size = 24
		info_display.outline_size = 3
		info_display.position = Vector3(0, neuron_spacing * 4, 0)
		info_display.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(info_display)
	update_info_display()

func create_error_graph():
	error_graph = get_node_or_null("ErrorGraph")
	if error_graph: error_graph.queue_free()
	error_graph = Node3D.new()
	error_graph.name = "ErrorGraph"
	var layer_sizes = [input_layer_size] + hidden_layer_sizes + [output_layer_size]
	error_graph.position = Vector3(layer_sizes.size() * layer_spacing, -3, -5)
	add_child(error_graph)
	error_history.clear()

#=============================================================================
#  Training Loop
#=============================================================================

func start_training():
	if is_training: return
	is_training = true
	var timer = Timer.new()
	timer.name = "TrainingTimer"
	timer.wait_time = 0.05 / training_speed
	timer.timeout.connect(_run_training_batch)
	add_child(timer)
	timer.start()

func _run_training_batch():
	"""Perform one batch of training."""
	if not is_training or current_epoch >= training_iterations:
		is_training = false
		get_node_or_null("TrainingTimer").queue_free()
		print("Training finished.")
		return

	var batch_inputs = []
	var batch_targets = []
	for _i in range(batch_size):
		var sample_idx = randi() % training_data.size()
		batch_inputs.append(training_data[sample_idx])
		batch_targets.append(target_data[sample_idx])

	var total_error = 0.0
	var cumulative_weight_deltas = deep_copy(weights)
	var cumulative_bias_deltas = deep_copy(biases)
	# Zero out the cumulative deltas
	for m in cumulative_weight_deltas:
		for r in m: r.fill(0.0)
	for v in cumulative_bias_deltas: v.fill(0.0)

	# --- Process Batch ---
	for i in range(batch_size):
		var inputs = batch_inputs[i]
		var targets = batch_targets[i]
		
		# Forward pass
		var outputs = forward_pass(inputs)
		total_error += calculate_error(outputs, targets)
		
		# Backward pass (calculate gradients)
		var gradients = backward_pass(targets)
		var weight_deltas = gradients[0]
		var bias_deltas = gradients[1]

		# Accumulate deltas
		for l in range(weights.size()):
			for j in range(weights[l].size()):
				for k in range(weights[l][j].size()):
					cumulative_weight_deltas[l][j][k] += weight_deltas[l][j][k]
		for l in range(biases.size()):
			for j in range(biases[l].size()):
				cumulative_bias_deltas[l][j] += bias_deltas[l][j]

	# --- Update Weights and Biases ---
	var lr_batch = learning_rate / batch_size
	for l in range(weights.size()):
		for j in range(weights[l].size()):
			for k in range(weights[l][j].size()):
				weights[l][j][k] += lr_batch * cumulative_weight_deltas[l][j][k]
	for l in range(biases.size()):
		for j in range(biases[l].size()):
			biases[l][j] += lr_batch * cumulative_bias_deltas[l][j]

	current_error = total_error / batch_size
	error_history.append(current_error)
	
	update_visualization()
	current_epoch += 1

func forward_pass(inputs: Array) -> Array:
	"""Perform forward propagation through the network."""
	activations[0] = inputs
	
	for l in range(1, activations.size()):
		for j in range(activations[l].size()):
			var weighted_sum = biases[l-1][j]
			for i in range(activations[l-1].size()):
				weighted_sum += activations[l-1][i] * weights[l-1][i][j]
			z_values[l][j] = weighted_sum
			activations[l][j] = activate(weighted_sum)
			
	return activations[-1]

func backward_pass(targets: Array) -> Array:
	"""Perform backpropagation and return weight/bias deltas for one sample."""
	var weight_deltas = deep_copy(weights)
	var bias_deltas = deep_copy(biases)
	for m in weight_deltas:
		for r in m: r.fill(0.0)
	for v in bias_deltas: v.fill(0.0)

	# --- Calculate Gradients (Deltas) ---
	# Output layer error
	var output_deltas = []
	var output_layer_idx = activations.size() - 1
	for j in range(activations[output_layer_idx].size()):
		var error = targets[j] - activations[output_layer_idx][j]
		var delta = error * activate_derivative(z_values[output_layer_idx][j])
		output_deltas.append(delta)

	var next_layer_deltas = output_deltas
	
	# --- Backpropagate Error ---
	for l in range(output_layer_idx - 1, -1, -1):
		var current_layer_deltas = []
		for i in range(activations[l].size()):
			var error = 0.0
			for j in range(activations[l+1].size()):
				error += weights[l][i][j] * next_layer_deltas[j]
			
			var delta = error * activate_derivative(z_values[l][i])
			current_layer_deltas.append(delta)
		
		# --- Calculate Weight and Bias Deltas for layer l -> l+1 ---
		for j in range(activations[l+1].size()):
			bias_deltas[l][j] = next_layer_deltas[j]
			for i in range(activations[l].size()):
				weight_deltas[l][i][j] = activations[l][i] * next_layer_deltas[j]
		
		next_layer_deltas = current_layer_deltas

	return [weight_deltas, bias_deltas]

#=============================================================================
#  Mathematical and Utility Functions
#=============================================================================

func activate(x: float) -> float:
	match activation_function:
		ActivationType.SIGMOID: return 1.0 / (1.0 + exp(-x))
		ActivationType.RELU: return max(0.0, x)
		ActivationType.TANH: return tanh(x)
	return 0.0

func activate_derivative(x: float) -> float:
	match activation_function:
		ActivationType.SIGMOID:
			var s = activate(x)
			return s * (1.0 - s)
		ActivationType.RELU:
			return 1.0 if x > 0.0 else 0.0
		ActivationType.TANH:
			var t = activate(x)
			return 1.0 - t * t
	return 0.0

func calculate_error(outputs: Array, targets: Array) -> float:
	"""Calculate mean squared error."""
	var total_error = 0.0
	for i in range(outputs.size()):
		var diff = targets[i] - outputs[i]
		total_error += diff * diff
	return total_error / outputs.size()

func deep_copy(data):
	"""Utility to deep copy nested arrays for gradient accumulation."""
	var new_data = []
	if data is Array:
		for item in data:
			new_data.append(deep_copy(item))
	else:
		return data
	return new_data

#=============================================================================
#  Visualization Updates
#=============================================================================

func update_visualization():
	"""Update the 3D visualization based on current network state."""
	# Update neuron colors/size based on activation levels
	if show_activations:
		for l in range(neuron_meshes.size()):
			for n in range(neuron_meshes[l].size()):
				var neuron = neuron_meshes[l][n]
				var activation = activations[l][n]
				var material = neuron.material_override as StandardMaterial3D
				material.emission_energy = activation * 2.0
				var scale = 1.0 + activation * 0.5
				neuron.scale = Vector3(scale, scale, scale)
	
	# Update weight line colors/thickness
	if show_weights:
		var line_idx = 0
		for l in range(weights.size()):
			for from_n in range(weights[l].size()):
				for to_n in range(weights[l][from_n].size()):
					if line_idx < weight_lines.size():
						var line = weight_lines[line_idx]
						var weight_val = weights[l][from_n][to_n]
						var material = line.material_override as StandardMaterial3D
						var intensity = clamp(abs(weight_val) * 0.5, 0.0, 1.0)
						if weight_val > 0: material.albedo_color = Color.WHITE.lerp(Color.YELLOW, intensity)
						else: material.albedo_color = Color.WHITE.lerp(Color.MAGENTA, intensity)
						
						var cylinder = line.mesh as CylinderMesh
						cylinder.top_radius = max(0.005, intensity * 0.05)
						cylinder.bottom_radius = cylinder.top_radius
					line_idx += 1
	
	update_info_display()
	update_error_graph()

func update_info_display():
	if info_display:
		info_display.text = "Epoch: %d / %d\n" % [current_epoch, training_iterations]
		info_display.text += "Error: %.5f\n" % current_error
		info_display.text += "Activation: %s" % [ "Sigmoid", "ReLU", "Tanh" ][activation_function]

func update_error_graph():
	"""Draws a 3D line graph of the error history."""
	if not is_instance_valid(error_graph): return
	
	# Clear previous graph points
	for child in error_graph.get_children():
		child.queue_free()
		
	var max_history = 200
	var start_index = max(0, error_history.size() - max_history)
	
	var graph_scale = Vector3(0.02, 5.0, 1.0) # x, y, z scale
	var last_pos: Vector3
	
	for i in range(start_index, error_history.size()):
		var error_val = error_history[i]
		var pos = Vector3((i - start_index) * graph_scale.x, -error_val * graph_scale.y, 0)
		
		# Draw a point for the error value
		var point_mesh = MeshInstance3D.new()
		point_mesh.mesh = BoxMesh.new()
		point_mesh.mesh.size = Vector3(0.05, 0.05, 0.05)
		point_mesh.position = pos
		error_graph.add_child(point_mesh)
		
		# Draw a line from the last point
		if i > start_index:
			var line_mesh = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			var dir = pos - last_pos
			cyl.height = dir.length()
			cyl.top_radius = 0.01
			cyl.bottom_radius = 0.01
			line_mesh.mesh = cyl
			line_mesh.position = (pos + last_pos) / 2.0
			error_graph.add_child(line_mesh)
			line_mesh.look_at(pos, Vector3.UP)
			line_mesh.rotate_object_local(Vector3.RIGHT, PI/2)
			
		last_pos = pos

#=============================================================================
#  Public API / Control
#=============================================================================

func test_network(inputs: Array) -> Array:
	"""Test the trained network with new inputs."""
	return forward_pass(inputs)

func reset_network():
	"""Reset the network to initial random state."""
	if is_training:
		is_training = false
		if get_node_or_null("TrainingTimer"):
			get_node("TrainingTimer").queue_free()
	
	current_epoch = 0
	current_error = 0.0
	build_network()
	create_visualization() # Re-create all visual elements
	update_visualization()
	if auto_train:
		start_training()
