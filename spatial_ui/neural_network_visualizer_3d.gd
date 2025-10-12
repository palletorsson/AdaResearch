class_name NeuralNetworkVisualizer3D
extends Node3D

## 3D Neural Network Visualization
## Displays neurons as glowing pink spheres with connections

@export var network: NeuralNetwork
@export var layer_spacing: float = 0.15  # Distance between layers
@export var neuron_spacing: float = 0.08  # Distance between neurons in same layer

# Visual settings
var neuron_radius: float = 0.015
var connection_width: float = 0.002
var inactive_color: Color = Color(0.9, 0.5, 0.8, 0.5)  # Medium pink, transparent
var active_color: Color = Color(1.0, 0.6, 1.0, 1.0)    # Bright pink, opaque

# Neuron spheres
var input_neurons: Array[MeshInstance3D] = []
var hidden_neurons: Array[MeshInstance3D] = []
var output_neurons: Array[MeshInstance3D] = []

# Connection lines
var connections_ih: Array = []  # Input to hidden
var connections_ho: Array = []  # Hidden to output

# Activation values (for visualization)
var hidden_activations: Array[float] = []
var output_activations: Array[float] = []

func _ready():
	if network:
		create_visualization()

func create_visualization():
	"""Create 3D visualization of the neural network"""
	clear_visualization()

	create_layer(input_neurons, network.input_nodes, Vector3(-layer_spacing, 0, 0))
	create_layer(hidden_neurons, network.hidden_nodes, Vector3(0, 0, 0))
	create_layer(output_neurons, network.output_nodes, Vector3(layer_spacing, 0, 0))

	create_connections()

func create_layer(neuron_array: Array, count: int, center_pos: Vector3):
	"""Create a layer of neurons"""
	var start_y = -(count - 1) * neuron_spacing / 2.0

	for i in range(count):
		var neuron = create_neuron()
		var y_pos = start_y + i * neuron_spacing
		neuron.position = center_pos + Vector3(0, y_pos, 0)
		add_child(neuron)
		neuron_array.append(neuron)

func create_neuron() -> MeshInstance3D:
	"""Create a single neuron sphere"""
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = neuron_radius
	sphere.height = neuron_radius * 2.0
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = inactive_color
	material.emission_enabled = true
	material.emission = inactive_color * 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	return mesh_instance

func create_connections():
	"""Create connection lines between layers"""
	# Input to hidden
	for i in range(input_neurons.size()):
		for h in range(hidden_neurons.size()):
			var weight = network.weights_ih[h][i]
			var line = create_connection_line(
				input_neurons[i].position,
				hidden_neurons[h].position,
				weight
			)
			connections_ih.append(line)
			add_child(line)

	# Hidden to output
	for h in range(hidden_neurons.size()):
		for o in range(output_neurons.size()):
			var weight = network.weights_ho[o][h]
			var line = create_connection_line(
				hidden_neurons[h].position,
				output_neurons[o].position,
				weight
			)
			connections_ho.append(line)
			add_child(line)

func create_connection_line(from: Vector3, to: Vector3, weight: float) -> MeshInstance3D:
	"""Create a line representing a connection with thickness based on weight"""
	var mesh_instance = MeshInstance3D.new()

	# Create cylinder between two points
	var direction = to - from
	var distance = direction.length()
	var midpoint = from + direction / 2.0

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = connection_width * abs(weight)
	cylinder.bottom_radius = connection_width * abs(weight)
	cylinder.height = distance

	mesh_instance.mesh = cylinder
	mesh_instance.position = midpoint

	# Orient cylinder to connect neurons
	if direction.length() > 0:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.RIGHT
		mesh_instance.look_at(to, up)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Color based on weight sign
	var material = StandardMaterial3D.new()
	if weight > 0:
		material.albedo_color = Color(1.0, 0.7, 0.9, 0.3)  # Pink for positive
	else:
		material.albedo_color = Color(0.5, 0.5, 0.9, 0.3)  # Blue for negative

	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	return mesh_instance

func visualize_forward_pass(inputs: Array):
	"""Visualize a forward pass through the network"""
	if not network:
		return

	# Get activations
	var hidden = network.matrix_multiply(network.weights_ih, inputs)
	hidden = network.array_add(hidden, network.bias_h)
	hidden_activations = network.array_map(hidden, network.sigmoid)

	var outputs = network.matrix_multiply(network.weights_ho, hidden_activations)
	outputs = network.array_add(outputs, network.bias_o)
	output_activations = network.array_map(outputs, network.sigmoid)

	# Update visual representation
	update_neuron_activations(input_neurons, inputs)
	update_neuron_activations(hidden_neurons, hidden_activations)
	update_neuron_activations(output_neurons, output_activations)

func update_neuron_activations(neurons: Array, activations: Array):
	"""Update neuron colors based on activation values"""
	for i in range(min(neurons.size(), activations.size())):
		var neuron = neurons[i]
		var activation = activations[i]

		# Interpolate color based on activation
		var color = inactive_color.lerp(active_color, activation)

		if neuron.material_override is StandardMaterial3D:
			var mat = neuron.material_override as StandardMaterial3D
			mat.albedo_color = color
			mat.emission = color * (0.5 + activation * 0.5)
			mat.emission_energy_multiplier = 0.5 + activation * 1.5

func clear_visualization():
	"""Clear all visual elements"""
	for neuron in input_neurons:
		neuron.queue_free()
	for neuron in hidden_neurons:
		neuron.queue_free()
	for neuron in output_neurons:
		neuron.queue_free()
	for connection in connections_ih:
		connection.queue_free()
	for connection in connections_ho:
		connection.queue_free()

	input_neurons.clear()
	hidden_neurons.clear()
	output_neurons.clear()
	connections_ih.clear()
	connections_ho.clear()

func set_network(nn: NeuralNetwork):
	"""Set the neural network to visualize"""
	network = nn
	create_visualization()

func animate_signal_propagation(inputs: Array, duration: float = 0.5):
	"""Animate signals propagating through the network"""
	# TODO: Implement tween-based animation showing signals traveling
	# from input -> hidden -> output over time
	visualize_forward_pass(inputs)
