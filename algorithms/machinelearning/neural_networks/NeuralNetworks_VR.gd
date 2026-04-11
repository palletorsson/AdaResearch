extends Node3D

# @identity
# essence: layers of neurons connected by weighted edges; forward pass propagates signal, backward pass propagates error
# desire: walk through each layer as a physical room, throw data into the input, watch activations cascade and gradients flow back
# critical_parameter: learning_rate — controls how aggressively weights change during backpropagation
# triggers: auto_train drives forward/backward passes; backprop particles flow in reverse; data particles enter the network
# emerges: the spatial intuition that depth creates abstraction — each room transforms the signal further
# needs: grabbable neurons [has], throwable data [has], visible weight connections [has], backprop particle flow [has]
# relationships: depends on gradient_descent_visualization (training IS optimization); unlocks lstms_vr (adding memory) and convolutional_neural_networks_cnns_vr (adding spatial structure)
# truth: a neural network is not a brain — it is a differentiable function that learns by following its own error gradient

# VR-Reimagined Neural Network Visualization
# Walk through network layers as physical rooms
# Interactive forward/backward propagation with visible weights

@export_group("VR Scale")
@export var layer_spacing: float = 6.0  # Distance between layers
@export var neuron_size: float = 0.25  # Size of neuron spheres
@export var room_height: float = 8.0  # Height of layer rooms

@export_group("Network Architecture")
@export var layer_sizes: Array[int] = [5, 4, 3, 2]  # Neurons per layer
@export var enable_bias_neurons: bool = true
@export var activation_function: String = "ReLU"  # ReLU, Sigmoid, Tanh

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var learning_rate: float = 0.05
@export var training_speed: float = 0.2
@export var show_backprop: bool = true

@export_group("Interactive Elements")
@export var enable_neuron_grabbing: bool = true
@export var enable_data_throwing: bool = true
@export var show_weights: bool = true
@export var show_activations: bool = true
@export var weight_line_thickness: float = 0.02

# Training state
var time: float = 0.0
var training_progress: float = 0.0
var loss: float = 1.0
var epoch: int = 0

# Network structure
var layers: Array = []  # Each layer contains array of neuron nodes
var weights: Array = []  # Weight connections between layers
var activations: Array = []  # Current activation values
var gradients: Array = []  # Gradient values for backprop

# Particles
var forward_particles: Array = []
var backward_particles: Array = []
var input_data_particles: Array = []

# Visual elements
var weight_lines: Array = []

func _ready() -> void:
	print("[NeuralNetworks_VR] Initializing interactive neural network")
	_initialize_network()
	_create_network_layers()
	_create_weight_connections()
	_create_data_input_area()
	_create_activation_flow()
	_create_gradient_flow()
	_create_control_panel()
	_create_info_panels()

func _process(delta: float) -> void:
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		loss = max(0.05, 1.0 - training_progress * 0.9)

		# Simulate epochs
		if fmod(time, 2.0) < delta:
			epoch += 1

	_animate_neurons(delta)
	_animate_forward_prop(delta)
	if show_backprop:
		_animate_back_prop(delta)
	_animate_weights(delta)
	_update_control_panel()

func _initialize_network() -> void:
	"""Initialize network structure"""
	# Initialize activations for each layer
	for layer_size in layer_sizes:
		var layer_activations = []
		for i in range(layer_size):
			layer_activations.append(randf())
		activations.append(layer_activations)
		gradients.append(layer_activations.duplicate())

	# Initialize weights between layers
	for i in range(layer_sizes.size() - 1):
		var layer_weights = []
		for j in range(layer_sizes[i]):
			var neuron_weights = []
			for k in range(layer_sizes[i + 1]):
				neuron_weights.append(randf_range(-0.5, 0.5))
			layer_weights.append(neuron_weights)
		weights.append(layer_weights)

func _create_network_layers() -> void:
	"""Create visual representation of all layers"""
	for layer_idx in range(layer_sizes.size()):
		var layer_container = Node3D.new()
		layer_container.name = "Layer_%d" % layer_idx
		layer_container.position = Vector3(layer_idx * layer_spacing, 0, 0)
		add_child(layer_container)

		var layer_neurons = []

		# Create neurons for this layer
		for neuron_idx in range(layer_sizes[layer_idx]):
			var neuron = _create_neuron(layer_idx, neuron_idx)
			layer_container.add_child(neuron)
			layer_neurons.append(neuron)

		layers.append(layer_neurons)

		# Layer room (transparent walls)
		_create_layer_room(layer_container, layer_idx)

		# Layer label
		_create_layer_label(layer_container, layer_idx)

func _create_neuron(layer_idx: int, neuron_idx: int) -> RigidBody3D:
	"""Create a single neuron as grabbable sphere"""
	var body = RigidBody3D.new()
	body.name = "Neuron_%d_%d" % [layer_idx, neuron_idx]

	# Vertical spacing
	var total_height = layer_sizes[layer_idx] * 1.2
	var y = -total_height / 2.0 + neuron_idx * 1.2 + 0.6

	body.position = Vector3(0, y, 0)
	body.gravity_scale = 0.0
	body.lock_rotation = true

	# Neuron sphere
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = neuron_size
	sphere.height = neuron_size * 2.0
	mesh.mesh = sphere

	# Color based on layer type
	var mat = StandardMaterial3D.new()
	if layer_idx == 0:
		# Input layer: blue
		mat.albedo_color = Color(0.3, 0.5, 0.9)
		mat.emission = Color(0.3, 0.5, 0.9)
	elif layer_idx == layer_sizes.size() - 1:
		# Output layer: red
		mat.albedo_color = Color(0.9, 0.3, 0.3)
		mat.emission = Color(0.9, 0.3, 0.3)
	else:
		# Hidden layers: green
		mat.albedo_color = Color(0.3, 0.9, 0.5)
		mat.emission = Color(0.3, 0.9, 0.5)

	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = neuron_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable if enabled
	if enable_neuron_grabbing:
		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	# Small label showing activation value
	var label = Label3D.new()
	label.text = "%.2f" % activations[layer_idx][neuron_idx]
	label.font_size = 20
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, neuron_size + 0.2, 0)
	body.add_child(label)

	return body

func _create_layer_room(layer_container: Node3D, layer_idx: int) -> void:
	"""Create transparent room for each layer"""
	# Floor
	var floor_mesh = MeshInstance3D.new()
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(4.0, 0.1, room_height)
	floor_mesh.mesh = floor_box

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.4, 0.3)
	floor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_mesh.material_override = floor_mat

	floor_mesh.position = Vector3(0, -room_height / 2.0 - 0.5, 0)
	layer_container.add_child(floor_mesh)

	# Ceiling
	var ceiling_mesh = MeshInstance3D.new()
	ceiling_mesh.mesh = floor_box
	ceiling_mesh.material_override = floor_mat
	ceiling_mesh.position = Vector3(0, room_height / 2.0 + 0.5, 0)
	layer_container.add_child(ceiling_mesh)

	# Grid lines on floor using MultiMesh
	var grid_cyl = CylinderMesh.new()
	grid_cyl.top_radius = 0.02
	grid_cyl.bottom_radius = 0.02
	grid_cyl.height = room_height

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.5, 0.5, 0.6, 0.4)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.5, 0.5, 0.6)
	line_mat.emission_energy_multiplier = 0.3
	grid_cyl.material = line_mat

	var grid_mm = MultiMesh.new()
	grid_mm.transform_format = MultiMesh.TRANSFORM_3D
	grid_mm.instance_count = 5
	grid_mm.mesh = grid_cyl

	for i in range(5):
		var t = Transform3D()
		t.basis = Basis(Vector3(1, 0, 0), PI / 2.0)
		t.origin = Vector3(float(i - 2), -room_height / 2.0 - 0.5, 0)
		grid_mm.set_instance_transform(i, t)

	var grid_mmi = MultiMeshInstance3D.new()
	grid_mmi.name = "GridLines_MM"
	grid_mmi.multimesh = grid_mm
	layer_container.add_child(grid_mmi)

func _create_layer_label(layer_container: Node3D, layer_idx: int) -> void:
	"""Create floating label for layer"""
	var label = Label3D.new()

	if layer_idx == 0:
		label.text = "INPUT LAYER\n%d neurons" % layer_sizes[layer_idx]
		label.modulate = Color(0.3, 0.5, 0.9)
	elif layer_idx == layer_sizes.size() - 1:
		label.text = "OUTPUT LAYER\n%d neurons" % layer_sizes[layer_idx]
		label.modulate = Color(0.9, 0.3, 0.3)
	else:
		label.text = "HIDDEN LAYER %d\n%d neurons" % [layer_idx, layer_sizes[layer_idx]]
		label.modulate = Color(0.3, 0.9, 0.5)

	label.font_size = 48
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, room_height / 2.0 + 1.5, 0)
	layer_container.add_child(label)

func _create_weight_connections() -> void:
	"""Create visual lines showing weights between neurons"""
	if not show_weights:
		return

	var weights_container = Node3D.new()
	weights_container.name = "WeightConnections"
	add_child(weights_container)

	# Create lines between each pair of connected neurons
	for layer_idx in range(layers.size() - 1):
		var layer_lines = []
		for src_idx in range(layers[layer_idx].size()):
			var src_neuron = layers[layer_idx][src_idx]
			for dst_idx in range(layers[layer_idx + 1].size()):
				var dst_neuron = layers[layer_idx + 1][dst_idx]

				# Create line using ImmediateMesh
				var line = MeshInstance3D.new()
				var immediate_mesh = ImmediateMesh.new()
				line.mesh = immediate_mesh
				line.name = "Weight_%d_%d_to_%d" % [layer_idx, src_idx, dst_idx]

				var weight_mat = StandardMaterial3D.new()
				var weight_value = weights[layer_idx][src_idx][dst_idx]
				# Color based on weight: red negative, green positive
				if weight_value > 0:
					weight_mat.albedo_color = Color(0.3, 0.9, 0.3, 0.5)
					weight_mat.emission = Color(0.3, 0.9, 0.3)
				else:
					weight_mat.albedo_color = Color(0.9, 0.3, 0.3, 0.5)
					weight_mat.emission = Color(0.9, 0.3, 0.3)

				weight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				weight_mat.emission_enabled = true
				weight_mat.emission_energy_multiplier = abs(weight_value) * 0.5
				weight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				line.material_override = weight_mat

				weights_container.add_child(line)
				layer_lines.append({
					"line": line,
					"src": src_neuron,
					"dst": dst_neuron,
					"weight": weight_value
				})

		weight_lines.append(layer_lines)

func _create_data_input_area() -> void:
	"""Create area with throwable data particles"""
	if not enable_data_throwing:
		return

	# Input platform
	var platform = MeshInstance3D.new()
	platform.name = "InputPlatform"
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 0.2, 3.0)
	platform.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.7
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	platform.position = Vector3(-3.0, -room_height / 2.0, 0)
	add_child(platform)

	# Label
	var label = Label3D.new()
	label.text = "TRAINING DATA\nThrow into network"
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(-3.0, 0, 0)
	add_child(label)

	# Create throwable data particles
	for i in range(10):
		var data = _create_data_particle(
			Vector3(
				-3.0 + randf_range(-1.2, 1.2),
				-room_height / 2.0 + 0.3 + i * 0.15,
				randf_range(-1.2, 1.2)
			)
		)
		add_child(data)
		input_data_particles.append(data)

func _create_data_particle(pos: Vector3) -> RigidBody3D:
	"""Create throwable data particle"""
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 0.1

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.2
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.15
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable and throwable
	body.collision_layer = 1 | (1 << 20)
	body.collision_mask = 1

	return body

func _create_activation_flow() -> void:
	"""Create particles showing forward propagation using MultiMesh"""
	if not show_activations:
		return

	var flow_container = Node3D.new()
	flow_container.name = "ForwardPropagation"
	add_child(flow_container)

	var fwd_count = 25
	var sphere = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.9)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	sphere.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = fwd_count
	mm.mesh = sphere

	for i in range(fwd_count):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3.ZERO))
		forward_particles.append({"index": i, "progress": randf()})

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "ForwardParticles_MM"
	mmi.multimesh = mm
	flow_container.add_child(mmi)

	# Store ref for animation
	flow_container.set_meta("multimesh", mm)

func _create_gradient_flow() -> void:
	"""Create particles showing backpropagation using MultiMesh"""
	if not show_backprop:
		return

	var gradient_container = Node3D.new()
	gradient_container.name = "Backpropagation"
	add_child(gradient_container)

	var bwd_count = 20
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.9, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.9)
	mat.emission_energy_multiplier = 0.9
	mat.metallic = 0.0
	mat.roughness = 1.0
	sphere.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = bwd_count
	mm.mesh = sphere

	for i in range(bwd_count):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3.ZERO))
		backward_particles.append({"index": i, "progress": randf()})

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "BackwardParticles_MM"
	mmi.multimesh = mm
	gradient_container.add_child(mmi)

	gradient_container.set_meta("multimesh", mm)

func _create_control_panel() -> void:
	"""Create VR-accessible control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	var total_width = (layer_sizes.size() - 1) * layer_spacing
	controls.position = Vector3(total_width + 3.0, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.5, 4.5, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "NEURAL NETWORK\nTRAINING"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.8, 0.1)
	controls.add_child(title)

	# Architecture info
	var arch_text = "Architecture:\n"
	for i in range(layer_sizes.size()):
		arch_text += str(layer_sizes[i])
		if i < layer_sizes.size() - 1:
			arch_text += " â†’ "
	var arch_label = Label3D.new()
	arch_label.text = arch_text
	arch_label.font_size = 32
	arch_label.outline_size = 8
	arch_label.position = Vector3(0, 0.8, 0.1)
	controls.add_child(arch_label)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Loss: 1.00\nEpoch: 0\nLR: %.3f" % learning_rate
	metrics.font_size = 36
	metrics.outline_size = 8
	metrics.position = Vector3(0, -0.5, 0.1)
	controls.add_child(metrics)

	# Activation function
	var act_label = Label3D.new()
	act_label.text = "Activation: %s" % activation_function
	act_label.font_size = 28
	act_label.outline_size = 7
	act_label.position = Vector3(0, -1.5, 0.1)
	controls.add_child(act_label)

func _create_info_panels() -> void:
	"""Create educational info panels"""
	# Forward propagation
	_create_info_panel(
		Vector3(layer_spacing, room_height / 2.0 + 2.5, -4.0),
		"FORWARD PROPAGATION\nData flows left to right\nEach neuron computes:\nweighted sum + bias",
		Color(0.3, 0.9, 0.9)
	)

	# Backpropagation
	if show_backprop:
		_create_info_panel(
			Vector3(layer_spacing * 2, room_height / 2.0 + 2.5, -4.0),
			"BACKPROPAGATION\nGradients flow right to left\nWeights updated by:\nw -= learning_rate * gradient",
			Color(0.9, 0.3, 0.9)
		)

	# Weight connections
	if show_weights:
		_create_info_panel(
			Vector3(layer_spacing / 2.0, -room_height / 2.0 - 2.0, 0),
			"WEIGHT CONNECTIONS\nGreen: positive weights\nRed: negative weights\nBrightness: magnitude",
			Color(0.6, 0.9, 0.6)
		)

func _create_info_panel(pos: Vector3, text: String, color: Color) -> void:
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _animate_neurons(_delta) -> void:
	"""Animate neurons based on activation"""
	for layer_idx in range(layers.size()):
		for neuron_idx in range(layers[layer_idx].size()):
			var neuron = layers[layer_idx][neuron_idx]
			var activation = activations[layer_idx][neuron_idx]

			# Pulse based on activation
			var pulse = 1.0 + activation * 0.3 * sin(time * 3.0 + layer_idx + neuron_idx)
			neuron.scale = Vector3.ONE * pulse

			# Update activation label
			var label = neuron.get_node_or_null("Label3D")
			if label:
				label.text = "%.2f" % activation

			# Update emission based on activation
			var mesh_instance = neuron.get_node_or_null("MeshInstance3D")
			if mesh_instance and mesh_instance.material_override:
				mesh_instance.material_override.emission_energy_multiplier = 0.3 + activation * 1.5

func _animate_forward_prop(delta) -> void:
	"""Animate forward propagation particles via MultiMesh"""
	var total_width = (layer_sizes.size() - 1) * layer_spacing

	var flow_container = get_node_or_null("ForwardPropagation")
	if not flow_container or not flow_container.has_meta("multimesh"):
		return
	var mm: MultiMesh = flow_container.get_meta("multimesh")

	for particle_data in forward_particles:
		var idx = particle_data.index
		var progress = particle_data.progress

		progress = fmod(progress + delta * 0.25, 1.0)
		particle_data.progress = progress

		var x = progress * total_width
		var y = sin(progress * PI * 3.0) * 1.5
		var z = cos(progress * PI * 2.0) * 1.0

		mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))

func _animate_back_prop(delta) -> void:
	"""Animate backpropagation particles via MultiMesh"""
	var total_width = (layer_sizes.size() - 1) * layer_spacing

	var gradient_container = get_node_or_null("Backpropagation")
	if not gradient_container or not gradient_container.has_meta("multimesh"):
		return
	var mm: MultiMesh = gradient_container.get_meta("multimesh")

	for particle_data in backward_particles:
		var idx = particle_data.index
		var progress = particle_data.progress

		progress = fmod(progress + delta * 0.2, 1.0)
		particle_data.progress = progress

		var x = total_width - (progress * total_width)
		var y = sin(progress * PI * 2.5 + PI) * 1.2
		var z = cos(progress * PI * 1.8) * 0.8

		mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))

func _animate_weights(_delta) -> void:
	"""Update weight line visualizations"""
	if not show_weights:
		return

	for layer_idx in range(weight_lines.size()):
		for weight_data in weight_lines[layer_idx]:
			var line = weight_data.line
			var src = weight_data.src
			var dst = weight_data.dst

			# Update line geometry
			var immediate_mesh = line.mesh as ImmediateMesh
			immediate_mesh.clear_surfaces()
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

			immediate_mesh.surface_add_vertex(src.global_position)
			immediate_mesh.surface_add_vertex(dst.global_position)

			immediate_mesh.surface_end()

func _update_control_panel() -> void:
	"""Update control panel displays"""
	var controls = get_node_or_null("ControlPanel")
	if not controls:
		return

	var metrics = controls.get_node_or_null("MetricsLabel")
	if metrics:
		metrics.text = "Loss: %.3f\nEpoch: %d\nLR: %.3f" % [loss, epoch, learning_rate]

# Public API
func forward_propagation() -> void:
	"""Simulate one forward pass"""
	# Simple simulation
	for layer_idx in range(1, layer_sizes.size()):
		for neuron_idx in range(layer_sizes[layer_idx]):
			var weighted_sum = 0.0
			for prev_idx in range(layer_sizes[layer_idx - 1]):
				weighted_sum += activations[layer_idx - 1][prev_idx] * weights[layer_idx - 1][prev_idx][neuron_idx]
			# Apply activation function
			activations[layer_idx][neuron_idx] = _apply_activation(weighted_sum)

func _apply_activation(x: float) -> float:
	"""Apply activation function"""
	match activation_function:
		"ReLU":
			return max(0.0, x)
		"Sigmoid":
			return 1.0 / (1.0 + exp(-x))
		"Tanh":
			return tanh(x)
		_:
			return x

func set_learning_rate(lr: float) -> void:
	learning_rate = clamp(lr, 0.001, 1.0)

func reset_training() -> void:
	training_progress = 0.0
	loss = 1.0
	epoch = 0
	time = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
