extends Node3D
 

var time: float = 0.0
var processing_progress: float = 0.0
var accuracy_score: float = 0.0
var map_score: float = 0.0
var particle_count: int = 32
var flow_particles: Array = []
var image_pixels: Array = []
var feature_particles: Array = []
var bounding_boxes: Array = []

func _ready():
	# Initialize Computer Vision visualization
	print("Computer Vision Visualization initialized")
	create_image_pixels()
	create_feature_particles()
	create_bounding_boxes()
	create_flow_particles()
	setup_vision_metrics()

func _process(delta):
	time += delta
	
	# Simulate processing progress
	processing_progress = min(1.0, time * 0.1)
	accuracy_score = processing_progress * 0.9
	map_score = processing_progress * 0.85
	
	animate_input_image(delta)
	animate_convolutional_network(delta)
	animate_feature_extraction(delta)
	animate_object_detection(delta)
	animate_data_flow(delta)
	update_vision_metrics(delta)

func create_image_pixels():
	# Create image pixel particles representing input image
	var image_pixels_node = $InputImage/ImagePixels
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles in a grid representing image pixels
		var grid_size = 6
		var row = i / grid_size
		var col = i % grid_size
		var x = (col - grid_size/2.0 + 0.5) * 0.4
		var y = (row - grid_size/2.0 + 0.5) * 0.4
		var z = randf_range(-0.2, 0.2)
		particle.position = Vector3(x, y, z)
		
		image_pixels_node.add_child(particle)
		image_pixels.append(particle)

func create_feature_particles():
	# Create feature extraction particles
	var feature_particles_node = $FeatureExtraction/FeatureParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position particles in feature map arrangement
		var row = i / 5
		var col = i % 5
		var x = (col - 2) * 0.6
		var y = (row - 2) * 0.6
		var z = randf_range(-0.3, 0.3)
		particle.position = Vector3(x, y, z)
		
		feature_particles_node.add_child(particle)
		feature_particles.append(particle)

func create_bounding_boxes():
	# Create bounding box particles for object detection
	var bounding_boxes_node = $ObjectDetection/BoundingBoxes
	for i in range(8):
		var particle = CSGBox3D.new()
		particle.size = Vector3(0.8, 0.8, 0.1)
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.3)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.2
		particle.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position bounding boxes in detection space
		var angle = float(i) / 8.0 * PI * 2
		var radius = 2.0
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.1, 0.1)
		particle.position = Vector3(x, y, z)
		
		bounding_boxes_node.add_child(particle)
		bounding_boxes.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(40):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the processing flow path
		var progress = float(i) / 40
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 6) * 2.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_vision_metrics():
	# Initialize vision metrics
	var accuracy_indicator = $VisionMetrics/AccuracyMeter/AccuracyIndicator
	var map_indicator = $VisionMetrics/mAPMeter/mAPIndicator
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle
	if map_indicator:
		map_indicator.position.x = 0  # Start at middle

func animate_input_image(delta):
	# Animate image pixel particles
	for i in range(image_pixels.size()):
		var particle = image_pixels[i]
		if particle:
			# Move particles in a subtle image scanning pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.8 + i * 0.1) * 0.05
			var move_y = base_pos.y + cos(time * 1.0 + i * 0.12) * 0.05
			var move_z = base_pos.z + sin(time * 1.2 + i * 0.08) * 0.03
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on processing progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * processing_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on image processing
			var rgb_channels = Vector3(
				0.8 * (0.5 + sin(time * 1.0 + i * 0.1) * 0.5),
				0.8 * (0.5 + sin(time * 1.2 + i * 0.15) * 0.5),
				0.8 * (0.5 + sin(time * 1.4 + i * 0.2) * 0.5)
			)
			particle.material_override.albedo_color = Color(rgb_channels.x, rgb_channels.y, rgb_channels.z, 1)

func animate_convolutional_network(delta):
	# Animate convolutional network core
	var network_core = $ConvolutionalNetwork/NetworkCore
	if network_core:
		# Rotate network
		network_core.rotation.y += delta * 0.5
		
		# Pulse based on processing progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * processing_progress
		network_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on processing
		if network_core.material_override:
			var intensity = 0.3 + processing_progress * 0.7
			network_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate processing layer cores
	var convolution_core = $ConvolutionalNetwork/ProcessingLayers/ConvolutionCore
	if convolution_core:
		convolution_core.rotation.y += delta * 0.8
		var convolution_activation = sin(time * 1.5) * 0.5 + 0.5
		convolution_activation *= processing_progress
		
		var pulse = 1.0 + convolution_activation * 0.3
		convolution_core.scale = Vector3.ONE * pulse
		
		if convolution_core.material_override:
			var intensity = 0.3 + convolution_activation * 0.7
			convolution_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var pooling_core = $ConvolutionalNetwork/ProcessingLayers/PoolingCore
	if pooling_core:
		pooling_core.rotation.y += delta * 1.0
		var pooling_activation = cos(time * 1.8) * 0.5 + 0.5
		pooling_activation *= processing_progress
		
		var pulse = 1.0 + pooling_activation * 0.3
		pooling_core.scale = Vector3.ONE * pulse
		
		if pooling_core.material_override:
			var intensity = 0.3 + pooling_activation * 0.7
			pooling_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var activation_core = $ConvolutionalNetwork/ProcessingLayers/ActivationCore
	if activation_core:
		activation_core.rotation.y += delta * 1.2
		var activation_activation = sin(time * 2.0) * 0.5 + 0.5
		activation_activation *= processing_progress
		
		var pulse = 1.0 + activation_activation * 0.3
		activation_core.scale = Vector3.ONE * pulse
		
		if activation_core.material_override:
			var intensity = 0.3 + activation_activation * 0.7
			activation_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var batchnorm_core = $ConvolutionalNetwork/ProcessingLayers/BatchNormCore
	if batchnorm_core:
		batchnorm_core.rotation.y += delta * 0.9
		var batchnorm_activation = cos(time * 1.6) * 0.5 + 0.5
		batchnorm_activation *= processing_progress
		
		var pulse = 1.0 + batchnorm_activation * 0.3
		batchnorm_core.scale = Vector3.ONE * pulse
		
		if batchnorm_core.material_override:
			var intensity = 0.3 + batchnorm_activation * 0.7
			batchnorm_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var dropout_core = $ConvolutionalNetwork/ProcessingLayers/DropoutCore
	if dropout_core:
		dropout_core.rotation.y += delta * 1.1
		var dropout_activation = sin(time * 1.7) * 0.5 + 0.5
		dropout_activation *= processing_progress
		
		var pulse = 1.0 + dropout_activation * 0.3
		dropout_core.scale = Vector3.ONE * pulse
		
		if dropout_core.material_override:
			var intensity = 0.3 + dropout_activation * 0.7
			dropout_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_feature_extraction(delta):
	# Animate feature particles
	for i in range(feature_particles.size()):
		var particle = feature_particles[i]
		if particle:
			# Move particles in a feature activation pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.6 + i * 0.2) * 0.2
			var move_y = base_pos.y + cos(time * 0.8 + i * 0.25) * 0.2
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.15) * 0.1
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on processing progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.3) * 0.3 * processing_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on feature activation
			var activation = fmod(processing_progress + sin(time * 1.5 + i * 0.25) * 0.3, 1.0)
			var green_component = 0.8 * activation
			var blue_component = 0.8 * (1.0 - activation)
			particle.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)

func animate_object_detection(delta):
	# Animate object detection core
	var detection_core = $ObjectDetection/DetectionCore
	if detection_core:
		# Rotate detection system
		detection_core.rotation.y += delta * 0.3
		
		# Pulse based on processing progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * processing_progress
		detection_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on processing
		if detection_core.material_override:
			var intensity = 0.3 + processing_progress * 0.7
			detection_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate bounding boxes
	for i in range(bounding_boxes.size()):
		var box = bounding_boxes[i]
		if box:
			# Move bounding boxes in detection pattern
			var base_pos = box.position
			var detection_confidence = sin(time * 1.0 + i * 0.5) * 0.5 + 0.5
			detection_confidence *= processing_progress
			
			var move_scale = 1.0 + detection_confidence * 0.3
			box.scale = Vector3.ONE * move_scale
			
			# Rotate boxes slightly
			box.rotation.y += delta * (0.2 + i * 0.1)
			
			# Change color based on detection confidence
			var confidence_color = Color(0.8, 0.8, 0.2, 0.3 + detection_confidence * 0.4)
			box.material_override.albedo_color = confidence_color
			box.material_override.emission = Color(0.8, 0.8, 0.2, 1) * detection_confidence * 0.5

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the processing flow
			var progress = fmod(time * 0.25 + float(i) * 0.06, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 6) * 2.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and processing progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on processing
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * processing_progress
			particle.scale = Vector3.ONE * pulse

func update_vision_metrics(delta):
	# Update accuracy meter
	var accuracy_indicator = $VisionMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy_score)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy_score
		var red_component = 0.2 + 0.6 * (1.0 - accuracy_score)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update mAP meter
	var map_indicator = $VisionMetrics/mAPMeter/mAPIndicator
	if map_indicator:
		var target_x = lerp(-2, 2, map_score)
		map_indicator.position.x = lerp(map_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on mAP score
		var green_component = 0.8 * map_score
		var red_component = 0.2 + 0.6 * (1.0 - map_score)
		map_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_processing_progress(progress: float):
	processing_progress = clamp(progress, 0.0, 1.0)

func set_accuracy_score(accuracy: float):
	accuracy_score = clamp(accuracy, 0.0, 1.0)

func set_map_score(map: float):
	map_score = clamp(map, 0.0, 1.0)

func get_processing_progress() -> float:
	return processing_progress

func get_accuracy_score() -> float:
	return accuracy_score

func get_map_score() -> float:
	return map_score

func reset_processing():
	time = 0.0
	processing_progress = 0.0
	accuracy_score = 0.0
	map_score = 0.0
