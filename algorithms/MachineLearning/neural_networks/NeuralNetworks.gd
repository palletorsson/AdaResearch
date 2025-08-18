extends Node3D

var time = 0.0
var neurons = []
var connections = []
var training_loss = 1.0

func _ready():
	create_network()
	setup_materials()

func create_network():
	# Create simple 3-layer network visualization
	var layers = [4, 3, 2]  # Input, Hidden, Output
	
	for layer_idx in range(layers.size()):
		for neuron_idx in range(layers[layer_idx]):
			var neuron = CSGSphere3D.new()
			neuron.radius = 0.1
			var x = -4 + layer_idx * 4
			var y = -1 + neuron_idx * 1.0
			neuron.position = Vector3(x, y, 0)
			$NetworkLayers.add_child(neuron)
			neurons.append(neuron)

func setup_materials():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.3, 0.5)
	
	for neuron in neurons:
		neuron.material_override = material

func _process(delta):
	time += delta
	training_loss = exp(-time / 10.0) + 0.1
	
	# Animate neurons
	for i in range(neurons.size()):
		var pulse = 1.0 + sin(time * 4.0 + i) * 0.3
		neurons[i].scale = Vector3.ONE * pulse
	
	# Update loss indicator
	$TrainingLoss.size.y = training_loss * 2.0 + 0.5