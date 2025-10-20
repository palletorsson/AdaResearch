extends Node3D
 

var time: float = 0.0
var training_progress: float = 0.0
var accuracy: float = 0.0
var grid_size: int = 6
var layers: Array = []

func _ready():
	# Initialize CNN visualization
	print("Convolutional Neural Networks Visualization initialized")
	create_image_grids()
	create_kernels()
	create_feature_maps()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate training progress
	training_progress = min(1.0, time * 0.1)
	accuracy = training_progress * 0.9
	
	animate_image_grids(delta)
	animate_kernels(delta)
	animate_feature_maps(delta)
	update_training_metrics(delta)

func create_image_grids():
	# Create input image grid
	var input_grid = $InputImage/ImageGrid
	for i in range(grid_size):
		for j in range(grid_size):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.1
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.8, 0.8, 0.8, 1)
			
			var x = (i - grid_size/2) * 0.3
			var z = (j - grid_size/2) * 0.3
			pixel.position = Vector3(x, 0, z)
			input_grid.add_child(pixel)
	
	# Create convolutional layer 1 grid
	var conv1_grid = $ConvolutionalLayers/ConvLayer1/Conv1Grid
	for i in range(grid_size - 2):
		for j in range(grid_size - 2):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.1
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
			
			var x = (i - (grid_size-2)/2) * 0.3
			var z = (j - (grid_size-2)/2) * 0.3
			pixel.position = Vector3(x, 0, z)
			conv1_grid.add_child(pixel)
			layers.append(pixel)
	
	# Create convolutional layer 2 grid
	var conv2_grid = $ConvolutionalLayers/ConvLayer2/Conv2Grid
	for i in range(grid_size - 4):
		for j in range(grid_size - 4):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.1
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.2, 0.6, 0.8, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.2, 0.6, 0.8, 1) * 0.3
			
			var x = (i - (grid_size-4)/2.0) * 0.3
			var z = (j - (grid_size-4)/2.0) * 0.3
			pixel.position = Vector3(x, 0, z)
			conv2_grid.add_child(pixel)
			layers.append(pixel)
	
	# Create pooling layer grid
	var pool_grid = $PoolingLayers/PoolLayer1/Pool1Grid
	for i in range((grid_size - 4) / 2.0):
		for j in range((grid_size - 4) / 2.0):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.1
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.6, 0.2, 0.8, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.6, 0.2, 0.8, 1) * 0.3
			
			var x = (i - ((grid_size-4)/2.0)/2) * 0.6
			var z = (j - ((grid_size-4)/2.0)/2) * 0.6
			pixel.position = Vector3(x, 0, z)
			pool_grid.add_child(pixel)
			layers.append(pixel)
	
	# Create fully connected layer
	var fc_grid = $FullyConnected/FCNeurons
	for i in range(8):
		var neuron = CSGSphere3D.new()
		neuron.radius = 0.15
		neuron.material_override = StandardMaterial3D.new()
		neuron.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		neuron.material_override.emission_enabled = true
		neuron.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
		
		var y = (i - 4) * 0.4
		neuron.position = Vector3(0, y, 0)
		fc_grid.add_child(neuron)
		layers.append(neuron)

func create_kernels():
	# Create kernel 1
	var kernel1_grid = $Kernels/Kernel1/Kernel1Grid
	for i in range(3):
		for j in range(3):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.08
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
			
			var x = (i - 1) * 0.2
			var z = (j - 1) * 0.2
			pixel.position = Vector3(x, 0, z)
			kernel1_grid.add_child(pixel)
	
	# Create kernel 2
	var kernel2_grid = $Kernels/Kernel2/Kernel2Grid
	for i in range(3):
		for j in range(3):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.08
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
			
			var x = (i - 1) * 0.2
			var z = (j - 1) * 0.2
			pixel.position = Vector3(x, 0, z)
			kernel2_grid.add_child(pixel)

func create_feature_maps():
	# Create feature map 1
	var feature1_grid = $FeatureMaps/FeatureMap1/Feature1Grid
	for i in range(grid_size - 2):
		for j in range(grid_size - 2):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.08
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
			
			var x = (i - (grid_size-2)/2) * 0.3
			var z = (j - (grid_size-2)/2) * 0.3
			pixel.position = Vector3(x, 0, z)
			feature1_grid.add_child(pixel)
	
	# Create feature map 2
	var feature2_grid = $FeatureMaps/FeatureMap2/Feature2Grid
	for i in range(grid_size - 4):
		for j in range(grid_size - 4):
			var pixel = CSGSphere3D.new()
			pixel.radius = 0.08
			pixel.material_override = StandardMaterial3D.new()
			pixel.material_override.albedo_color = Color(0.2, 0.6, 0.8, 1)
			pixel.material_override.emission_enabled = true
			pixel.material_override.emission = Color(0.2, 0.6, 0.8, 1) * 0.3
			
			var x = (i - (grid_size-4)/2.0) * 0.3
			var z = (j - (grid_size-4)/2.0) * 0.3
			pixel.position = Vector3(x, 0, z)
			feature2_grid.add_child(pixel)

func setup_training_metrics():
	# Initialize accuracy meter
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		accuracy_indicator.position.x = -6  # Start at low accuracy

func animate_image_grids(delta):
	# Animate input image with some variation
	var input_grid = $InputImage/ImageGrid
	for i in range(input_grid.get_child_count()):
		var pixel = input_grid.get_child(i)
		if pixel:
			# Subtle pulsing effect
			var pulse = 1.0 + sin(time * 2.0 + i * 0.1) * 0.1
			pixel.scale = Vector3.ONE * pulse
			
			# Slight rotation
			pixel.rotation.y += delta * 0.5

func animate_kernels(delta):
	# Animate kernels with sliding motion
	var kernels = [$Kernels/Kernel1, $Kernels/Kernel2]
	for kernel_idx in range(kernels.size()):
		var kernel = kernels[kernel_idx]
		if kernel:
			# Slide kernels across the input
			var slide_offset = sin(time * 0.5 + kernel_idx * PI) * 2.0
			kernel.position.x = slide_offset
			
			# Rotate kernels
			kernel.rotation.y += delta * (1.0 + kernel_idx * 0.5)
			
			# Pulse effect
			var pulse = 1.0 + sin(time * 3.0 + kernel_idx * PI) * 0.2
			kernel.scale = Vector3.ONE * pulse

func animate_feature_maps(delta):
	# Animate feature maps with activation patterns
	var feature_maps = [$FeatureMaps/FeatureMap1, $FeatureMaps/FeatureMap2]
	for map_idx in range(feature_maps.size()):
		var feature_map = feature_maps[map_idx]
		if feature_map:
			var grid = feature_map.get_child(0)  # Get the grid node
			if grid:
				for i in range(grid.get_child_count()):
					var pixel = grid.get_child(i)
					if pixel:
						# Activation pattern based on training progress
						var activation = sin(time * 2.0 + i * 0.5) * 0.5 + 0.5
						activation *= training_progress
						
						# Scale based on activation
						var target_scale = 0.5 + activation * 0.5
						pixel.scale = Vector3.ONE * lerp(pixel.scale.x, target_scale, delta * 3.0)
						
						# Change emission intensity
						if pixel.material_override:
							var base_color = pixel.material_override.albedo_color
							var intensity = 0.3 + activation * 0.7
							pixel.material_override.emission = base_color * intensity

func update_training_metrics(delta):
	# Update accuracy meter
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-6, 6, accuracy)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy
		var red_component = 0.2 + 0.6 * (1.0 - accuracy)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_training_progress(progress: float):
	training_progress = clamp(progress, 0.0, 1.0)

func set_accuracy(acc: float):
	accuracy = clamp(acc, 0.0, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_accuracy() -> float:
	return accuracy

func reset_training():
	time = 0.0
	training_progress = 0.0
	accuracy = 0.0
	
	# Reset all layers to initial state
	for layer in layers:
		if layer:
			layer.scale = Vector3.ONE
			layer.rotation = Vector3.ZERO
