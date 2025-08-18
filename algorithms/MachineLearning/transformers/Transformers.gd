extends Node3D
class_name Transformers

var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0
var sequence_length: int = 8
var attention_heads: int = 4
var flow_particles: Array = []

func _ready():
	# Initialize Transformers visualization
	print("Transformers Visualization initialized")
	create_input_tokens()
	create_output_tokens()
	create_flow_particles()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate training progress
	training_progress = min(1.0, time * 0.1)
	loss_value = max(0.1, 1.0 - training_progress * 0.8)
	accuracy = training_progress * 0.9
	
	animate_transformer_layers(delta)
	animate_attention_heads(delta)
	animate_positional_encoding(delta)
	animate_data_flow(delta)
	update_training_metrics(delta)

func create_input_tokens():
	# Create input sequence tokens
	var input_tokens = $InputSequence/InputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		token.material_override = StandardMaterial3D.new()
		token.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		token.material_override.emission_enabled = true
		token.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		var x = (i - sequence_length/2) * 0.6
		token.position = Vector3(x, 0, 0)
		input_tokens.add_child(token)

func create_output_tokens():
	# Create output sequence tokens
	var output_tokens = $OutputSequence/OutputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		token.material_override = StandardMaterial3D.new()
		token.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		token.material_override.emission_enabled = true
		token.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		var x = (i - sequence_length/2) * 0.6
		token.position = Vector3(x, 0, 0)
		output_tokens.add_child(token)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(20):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles along the transformer flow path
		var progress = float(i) / 20
		var x = lerp(-12, 12, progress)
		var y = sin(progress * PI * 3) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_training_metrics():
	# Initialize loss and accuracy meters
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if loss_indicator:
		loss_indicator.position.x = 0  # Start at middle
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle

func animate_transformer_layers(delta):
	# Animate encoder layers
	var encoder_layers = [$TransformerLayers/EncoderLayer1/EncoderCore1, $TransformerLayers/EncoderLayer2/EncoderCore2]
	for i in range(encoder_layers.size()):
		var layer = encoder_layers[i]
		if layer:
			# Rotate encoder layers
			layer.rotation.y += delta * (0.5 + i * 0.2)
			
			# Pulse based on training progress
			var pulse = 1.0 + sin(time * 2.0 + i * PI) * 0.1 * training_progress
			layer.scale = Vector3.ONE * pulse
			
			# Change emission intensity based on training
			if layer.material_override:
				var intensity = 0.3 + training_progress * 0.7
				layer.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate decoder layers
	var decoder_layers = [$TransformerLayers/DecoderLayer1/DecoderCore1, $TransformerLayers/DecoderLayer2/DecoderCore2]
	for i in range(decoder_layers.size()):
		var layer = decoder_layers[i]
		if layer:
			# Rotate decoder layers
			layer.rotation.y += delta * (0.6 + i * 0.3)
			
			# Pulse based on training progress
			var pulse = 1.0 + sin(time * 2.5 + i * PI) * 0.1 * training_progress
			layer.scale = Vector3.ONE * pulse
			
			# Change emission intensity based on training
			if layer.material_override:
				var intensity = 0.3 + training_progress * 0.7
				layer.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_attention_heads(delta):
	# Animate multi-head attention core
	var attention_core = $AttentionHeads/MultiHeadAttention/AttentionCore
	if attention_core:
		# Rotate attention mechanism
		attention_core.rotation.y += delta * 0.8
		
		# Pulse based on attention activation
		var attention_activation = sin(time * 1.8) * 0.5 + 0.5
		attention_activation *= training_progress
		
		var pulse = 1.0 + attention_activation * 0.3
		attention_core.scale = Vector3.ONE * pulse
		
		# Change emission based on attention
		if attention_core.material_override:
			var intensity = 0.3 + attention_activation * 0.7
			attention_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_positional_encoding(delta):
	# Animate positional encoding core
	var encoding_core = $PositionalEncoding/EncodingCore
	if encoding_core:
		# Rotate encoding
		encoding_core.rotation.y += delta * 0.6
		
		# Pulse based on encoding effectiveness
		var encoding_effectiveness = cos(time * 1.5) * 0.5 + 0.5
		encoding_effectiveness *= training_progress
		
		var pulse = 1.0 + encoding_effectiveness * 0.2
		encoding_core.scale = Vector3.ONE * pulse
		
		# Change emission based on encoding
		if encoding_core.material_override:
			var intensity = 0.3 + encoding_effectiveness * 0.7
			encoding_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the transformer flow
			var progress = fmod(time * 0.3 + float(i) * 0.1, 1.0)
			var x = lerp(-12, 12, progress)
			var y = sin(progress * PI * 3) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and training progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on training
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress
			particle.scale = Vector3.ONE * pulse

func update_training_metrics(delta):
	# Update loss meter
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	if loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - loss_value)
		loss_indicator.position.x = lerp(loss_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on loss
		var green_component = 0.8 * (1.0 - loss_value)
		var red_component = 0.2 + 0.6 * loss_value
		loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update accuracy meter
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy
		var red_component = 0.2 + 0.6 * (1.0 - accuracy)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_training_progress(progress: float):
	training_progress = clamp(progress, 0.0, 1.0)

func set_loss_value(loss: float):
	loss_value = clamp(loss, 0.1, 1.0)

func set_accuracy(acc: float):
	accuracy = clamp(acc, 0.0, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_loss_value() -> float:
	return loss_value

func get_accuracy() -> float:
	return accuracy

func reset_training():
	time = 0.0
	training_progress = 0.0
	loss_value = 1.0
	accuracy = 0.0
