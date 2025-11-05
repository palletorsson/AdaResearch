extends Node3D

# VR-Reimagined Convolutional Neural Networks
# Walk through CNN layers as physical spatial architecture
# Interactive kernel design and feature map visualization

@export_group("VR Scale")
@export var layer_spacing: float = 8.0  # Distance between layers
@export var feature_map_size: float = 3.0  # Size of feature map planes
@export var kernel_size: float = 0.4  # Size of kernel visualization

@export_group("CNN Architecture")
@export var input_size: int = 28  # 28x28 input (like MNIST)
@export var num_conv_layers: int = 3
@export var num_filters_per_layer: Array[int] = [16, 32, 64]
@export var kernel_dimensions: int = 3  # 3x3 kernels
@export var num_dense_layers: int = 2

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.1
@export var show_activations: bool = true
@export var show_backprop: bool = true

@export_group("Interactive Elements")
@export var enable_kernel_editing: bool = true
@export var enable_feature_inspection: bool = true
@export var show_receptive_fields: bool = true
@export var animate_forward_pass: bool = true

# Network state
var time: float = 0.0
var training_progress: float = 0.0
var accuracy: float = 0.0

# Layer structure
var conv_layers: Array = []
var pooling_layers: Array = []
var dense_layers: Array = []

# Visualization elements
var input_plane: Node3D
var feature_maps: Array = []  # [layer][filter_idx]
var kernel_visualizations: Array = []
var activation_particles: Array = []

# Kernels (simplified, would be learned)
var kernel_weights: Array = []

func _ready():
	print("[CNNs_VR] Initializing CNN architecture walkthrough")
	_initialize_kernels()
	_create_input_layer()
	_create_convolutional_layers()
	_create_pooling_layers()
	_create_dense_layers()
	_create_output_layer()
	_create_activation_flow()
	_create_control_panel()
	_create_info_panels()

func _process(delta):
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		accuracy = training_progress * 0.95

	_animate_feature_maps(delta)
	_animate_kernels(delta)
	if animate_forward_pass:
		_animate_activations(delta)

func _initialize_kernels():
	"""Initialize random kernel weights"""
	for layer_idx in range(num_conv_layers):
		var layer_kernels = []
		var num_filters = num_filters_per_layer[layer_idx]
		for filter_idx in range(num_filters):
			var kernel = []
			for y in range(kernel_dimensions):
				var row = []
				for x in range(kernel_dimensions):
					row.append(randf_range(-1.0, 1.0))
				kernel.append(row)
			layer_kernels.append(kernel)
		kernel_weights.append(layer_kernels)

func _create_input_layer():
	"""Create input image plane"""
	input_plane = Node3D.new()
	input_plane.name = "InputLayer"
	input_plane.position = Vector3(0, 0, 0)
	add_child(input_plane)

	# Input plane mesh
	var plane = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(feature_map_size, feature_map_size)
	plane.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.9)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	plane.material_override = mat

	input_plane.add_child(plane)

	# Label
	var label = Label3D.new()
	label.text = "INPUT\n%dx%d" % [input_size, input_size]
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, feature_map_size / 2.0 + 1.0, 0)
	input_plane.add_child(label)

func _create_convolutional_layers():
	"""Create convolution layer rooms"""
	for layer_idx in range(num_conv_layers):
		var layer_container = Node3D.new()
		layer_container.name = "ConvLayer_%d" % layer_idx
		layer_container.position = Vector3((layer_idx + 1) * layer_spacing, 0, 0)
		add_child(layer_container)

		conv_layers.append(layer_container)

		# Create feature maps for this layer
		var num_filters = num_filters_per_layer[layer_idx]
		var layer_feature_maps = []

		# Arrange feature maps in a grid (stacked vertically)
		var maps_per_row = min(4, num_filters)
		var num_rows = ceil(float(num_filters) / maps_per_row)

		for filter_idx in range(num_filters):
			var row = filter_idx / maps_per_row
			var col = filter_idx % maps_per_row

			var feature_map = _create_feature_map(layer_idx, filter_idx)
			var x_offset = (col - maps_per_row / 2.0 + 0.5) * (feature_map_size + 0.5)
			var y_offset = (row - num_rows / 2.0 + 0.5) * (feature_map_size + 0.5)
			feature_map.position = Vector3(x_offset, y_offset, 0)

			layer_container.add_child(feature_map)
			layer_feature_maps.append(feature_map)

			# Create kernel visualization for this filter
			if layer_idx == 0:  # Only show kernels for first layer
				var kernel_viz = _create_kernel_viz(layer_idx, filter_idx)
				kernel_viz.position = Vector3(x_offset, y_offset, -0.8)
				layer_container.add_child(kernel_viz)
				kernel_visualizations.append(kernel_viz)

		feature_maps.append(layer_feature_maps)

		# Layer label
		var label = Label3D.new()
		label.text = "CONV LAYER %d\n%d filters (%dx%d)" % [
			layer_idx + 1, num_filters, kernel_dimensions, kernel_dimensions
		]
		label.font_size = 56
		label.outline_size = 14
		label.modulate = Color(0.3, 0.9, 0.5)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, feature_map_size * num_rows / 2.0 + 2.0, 0)
		layer_container.add_child(label)

func _create_feature_map(layer_idx: int, filter_idx: int) -> MeshInstance3D:
	"""Create a single feature map plane"""
	var map = MeshInstance3D.new()
	map.name = "FeatureMap_%d_%d" % [layer_idx, filter_idx]

	var quad = QuadMesh.new()
	var scale_factor = pow(0.5, layer_idx)  # Each layer smaller due to pooling
	quad.size = Vector2(feature_map_size * scale_factor, feature_map_size * scale_factor)
	map.mesh = quad

	var mat = StandardMaterial3D.new()
	var hue = float(filter_idx) / num_filters_per_layer[layer_idx]
	var color = Color.from_hsv(hue, 0.7, 0.9)
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	map.material_override = mat

	return map

func _create_kernel_viz(layer_idx: int, filter_idx: int) -> Node3D:
	"""Create 3x3 kernel weight visualization"""
	var kernel_container = Node3D.new()
	kernel_container.name = "Kernel_%d_%d" % [layer_idx, filter_idx]

	var kernel = kernel_weights[layer_idx][filter_idx]

	# Create 3x3 grid of cubes showing weights
	for ky in range(kernel_dimensions):
		for kx in range(kernel_dimensions):
			var weight = kernel[ky][kx]
			var cube = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3.ONE * kernel_size / 4.0
			cube.mesh = box

			var mat = StandardMaterial3D.new()
			if weight > 0:
				mat.albedo_color = Color(0, weight, 0)
				mat.emission = Color(0, weight, 0)
			else:
				mat.albedo_color = Color(-weight, 0, 0)
				mat.emission = Color(-weight, 0, 0)

			mat.emission_enabled = true
			mat.emission_energy_multiplier = 1.0
			mat.metallic = 0.0
			mat.roughness = 1.0
			cube.material_override = mat

			cube.position = Vector3(
				(kx - 1) * kernel_size / 3.5,
				(ky - 1) * kernel_size / 3.5,
				0
			)

			kernel_container.add_child(cube)

	# Make grabbable if editing enabled
	if enable_kernel_editing:
		var body = RigidBody3D.new()
		body.gravity_scale = 0.0
		kernel_container.add_child(body)

		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3.ONE * kernel_size
		collision.shape = shape
		body.add_child(collision)

		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	return kernel_container

func _create_pooling_layers():
	"""Create max pooling visualizations"""
	for layer_idx in range(num_conv_layers):
		var pool_container = Node3D.new()
		pool_container.name = "PoolLayer_%d" % layer_idx
		pool_container.position = Vector3((layer_idx + 1) * layer_spacing + layer_spacing / 2.0, 0, 0)
		add_child(pool_container)

		pooling_layers.append(pool_container)

		# Pooling visualization (downward arrows)
		var arrow = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.5
		cone.height = 1.0
		arrow.mesh = cone

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.5, 0.3)
		mat.emission_energy_multiplier = 0.8
		mat.metallic = 0.0
		mat.roughness = 1.0
		arrow.material_override = mat

		arrow.rotation.z = PI
		pool_container.add_child(arrow)

		# Label
		var label = Label3D.new()
		label.text = "MAX POOL\n2x2 → ½ size"
		label.font_size = 42
		label.outline_size = 10
		label.modulate = Color(0.9, 0.5, 0.3)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 2.0, 0)
		pool_container.add_child(label)

func _create_dense_layers():
	"""Create fully connected layers"""
	var dense_start_x = (num_conv_layers + 1) * layer_spacing

	for layer_idx in range(num_dense_layers):
		var dense_container = Node3D.new()
		dense_container.name = "DenseLayer_%d" % layer_idx
		dense_container.position = Vector3(dense_start_x + layer_idx * layer_spacing / 2.0, 0, 0)
		add_child(dense_container)

		dense_layers.append(dense_container)

		# Number of neurons
		var num_neurons = 128 / pow(2, layer_idx)

		# Create neuron spheres in vertical column
		for n in range(min(16, int(num_neurons))):  # Show max 16 visually
			var neuron = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.2
			neuron.mesh = sphere

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.7, 0.3)
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.7, 0.3)
			mat.emission_energy_multiplier = 0.8
			mat.metallic = 0.0
			mat.roughness = 1.0
			neuron.material_override = mat

			neuron.position = Vector3(0, (n - 8) * 0.5, 0)
			dense_container.add_child(neuron)

		# Label
		var label = Label3D.new()
		label.text = "DENSE LAYER %d\n%d neurons" % [layer_idx + 1, num_neurons]
		label.font_size = 48
		label.outline_size = 12
		label.modulate = Color(0.9, 0.7, 0.3)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 5.0, 0)
		dense_container.add_child(label)

func _create_output_layer():
	"""Create output layer (classification)"""
	var output_container = Node3D.new()
	output_container.name = "OutputLayer"
	var output_x = (num_conv_layers + 1) * layer_spacing + num_dense_layers * layer_spacing / 2.0 + layer_spacing / 2.0
	output_container.position = Vector3(output_x, 0, 0)
	add_child(output_container)

	# Create 10 output neurons (for 10 classes like MNIST)
	for i in range(10):
		var neuron = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.25
		neuron.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.9)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		neuron.material_override = mat

		neuron.position = Vector3(0, (i - 4.5) * 0.7, 0)
		output_container.add_child(neuron)

		# Class label
		var label = Label3D.new()
		label.text = "Class %d" % i
		label.font_size = 24
		label.outline_size = 8
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.6, (i - 4.5) * 0.7, 0)
		output_container.add_child(label)

	# Layer label
	var layer_label = Label3D.new()
	layer_label.text = "OUTPUT\n10 classes"
	layer_label.font_size = 56
	layer_label.outline_size = 14
	layer_label.modulate = Color(0.3, 0.9, 0.9)
	layer_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	layer_label.position = Vector3(0, 4.5, 0)
	output_container.add_child(layer_label)

func _create_activation_flow():
	"""Create particles showing forward propagation"""
	if not animate_forward_pass:
		return

	var flow_container = Node3D.new()
	flow_container.name = "ActivationFlow"
	add_child(flow_container)

	for i in range(30):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.08
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.9, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.9, 0.9)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		flow_container.add_child(particle)
		activation_particles.append({
			"node": particle,
			"progress": randf()
		})

func _create_control_panel():
	"""Create VR control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	var panel_x = (num_conv_layers + 1) * layer_spacing + num_dense_layers * layer_spacing / 2.0 + layer_spacing
	controls.position = Vector3(panel_x, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.5, 0.1)
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
	title.text = "CNN\nARCHITECTURE"
	title.font_size = 64
	title.outline_size = 14
	title.position = Vector3(0, 1.8, 0.1)
	controls.add_child(title)

	# Architecture summary
	var arch_text = "Input: %dx%d\n" % [input_size, input_size]
	for i in range(num_conv_layers):
		arch_text += "Conv%d: %d filters\n" % [i + 1, num_filters_per_layer[i]]
	arch_text += "Dense: %d layers\nOutput: 10 classes" % num_dense_layers

	var arch_label = Label3D.new()
	arch_label.text = arch_text
	arch_label.font_size = 28
	arch_label.outline_size = 8
	arch_label.position = Vector3(0, -0.2, 0.1)
	controls.add_child(arch_label)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Accuracy: 0%%"
	metrics.font_size = 36
	metrics.outline_size = 8
	metrics.position = Vector3(0, -1.8, 0.1)
	controls.add_child(metrics)

func _create_info_panels():
	"""Create educational info panels"""
	# Convolution explanation
	_create_info_panel(
		Vector3(layer_spacing / 2.0, 6.0, -3.0),
		"CONVOLUTION\nLocal connectivity\nParameter sharing\nTranslation invariance",
		Color(0.3, 0.9, 0.5)
	)

	# Pooling explanation
	_create_info_panel(
		Vector3(layer_spacing * 1.5, 6.0, -3.0),
		"POOLING\nDownsampling\nSpatial invariance\nReduces parameters",
		Color(0.9, 0.5, 0.3)
	)

	# Dense explanation
	var dense_x = (num_conv_layers + 1) * layer_spacing
	_create_info_panel(
		Vector3(dense_x, 6.0, -3.0),
		"DENSE LAYERS\nFully connected\nHigh-level reasoning\nClassification",
		Color(0.9, 0.7, 0.3)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color):
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

func _animate_feature_maps(delta):
	"""Animate feature map planes"""
	for layer_idx in range(feature_maps.size()):
		for filter_idx in range(feature_maps[layer_idx].size()):
			var map = feature_maps[layer_idx][filter_idx]
			var pulse = 1.0 + sin(time * 2.0 + layer_idx + filter_idx * 0.5) * 0.1 * training_progress
			map.scale = Vector3(pulse, pulse, 1.0)

			# Update emission based on "activation"
			var activation = 0.6 + sin(time * 1.5 + filter_idx) * 0.3 * training_progress
			map.material_override.emission_energy_multiplier = activation

func _animate_kernels(delta):
	"""Animate kernel visualizations"""
	for kernel_viz in kernel_visualizations:
		kernel_viz.rotation.z += delta * 0.2

func _animate_activations(delta):
	"""Animate forward propagation particles"""
	var total_width = (num_conv_layers + 1) * layer_spacing + num_dense_layers * layer_spacing / 2.0 + layer_spacing / 2.0

	for particle_data in activation_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress
		progress = fmod(progress + delta * 0.15, 1.0)
		particle_data.progress = progress

		# Position along CNN
		var x = progress * total_width
		var y = sin(progress * PI * 4.0) * 2.0
		var z = cos(progress * PI * 3.0) * 1.0

		particle.position = Vector3(x, y, z)

# Public API
func set_kernel_weight(layer: int, filter: int, x: int, y: int, value: float):
	"""Set a kernel weight value"""
	if layer >= 0 and layer < kernel_weights.size():
		if filter >= 0 and filter < kernel_weights[layer].size():
			if y >= 0 and y < kernel_dimensions and x >= 0 and x < kernel_dimensions:
				kernel_weights[layer][filter][y][x] = clamp(value, -1.0, 1.0)

func inspect_feature_map(layer: int, filter: int):
	"""Highlight and inspect a specific feature map"""
	print("[CNN] Inspecting layer %d, filter %d" % [layer, filter])
