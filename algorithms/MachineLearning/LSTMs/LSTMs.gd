extends Node3D
class_name LSTMs

var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0
var sequence_length: int = 8
var memory_particles: Array = []

func _ready():
	# Initialize LSTM visualization
	print("LSTM Networks Visualization initialized")
	create_input_tokens()
	create_output_tokens()
	create_memory_particles()
	create_gate_activations()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate training progress
	training_progress = min(1.0, time * 0.1)
	loss_value = max(0.1, 1.0 - training_progress * 0.8)
	accuracy = training_progress * 0.9
	
	animate_lstm_cell(delta)
	animate_gates(delta)
	animate_memory_flow(delta)
	animate_gate_activations(delta)
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

func create_memory_particles():
	# Create memory flow particles
	var memory_particles_node = $MemoryFlow/MemoryParticles
	for i in range(15):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles along the memory flow path
		var progress = float(i) / 15
		var x = lerp(-12, 12, progress)
		var y = sin(progress * PI * 2) * 1.5
		particle.position = Vector3(x, y, 0)
		
		memory_particles_node.add_child(particle)
		memory_particles.append(particle)

func create_gate_activations():
	# Create gate activation indicators
	var activation_indicators = $GateActivations/ActivationIndicators
	for i in range(6):
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.1
		indicator.material_override = StandardMaterial3D.new()
		indicator.material_override.albedo_color = Color(0.2, 0.8, 0.8, 0.8)
		indicator.material_override.emission_enabled = true
		indicator.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position indicators around the LSTM cell
		var angle = float(i) / 6 * PI * 2
		var radius = 5.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		indicator.position = Vector3(x, 0, z)
		
		activation_indicators.add_child(indicator)

func setup_training_metrics():
	# Initialize loss and accuracy meters
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if loss_indicator:
		loss_indicator.position.x = 0  # Start at middle
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle

func animate_lstm_cell(delta):
	# Animate LSTM cell core
	var cell_core = $LSTMCell/CellCore
	if cell_core:
		# Rotate cell
		cell_core.rotation.y += delta * 0.4
		
		# Pulse based on training progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * training_progress
		cell_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on training
		if cell_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			cell_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate cell state
	var state_core = $LSTMCell/CellState/StateCore
	if state_core:
		state_core.rotation.y += delta * 0.6
		state_core.scale = Vector3.ONE * (1.0 + sin(time * 1.8) * 0.15)
		
		# Change emission based on memory retention
		if state_core.material_override:
			var memory_retention = 0.5 + training_progress * 0.5
			var intensity = 0.3 + memory_retention * 0.7
			state_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate hidden state
	var hidden_core = $LSTMCell/HiddenState/HiddenCore
	if hidden_core:
		hidden_core.rotation.y += delta * 0.8
		hidden_core.scale = Vector3.ONE * (1.0 + sin(time * 2.2) * 0.15)
		
		# Change emission based on information flow
		if hidden_core.material_override:
			var info_flow = 0.3 + training_progress * 0.7
			var intensity = 0.3 + info_flow * 0.7
			hidden_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_gates(delta):
	# Animate forget gate
	var forget_core = $LSTMCell/Gates/ForgetGate/ForgetCore
	if forget_core:
		forget_core.rotation.y += delta * 1.2
		var forget_activation = sin(time * 1.5) * 0.5 + 0.5
		forget_activation *= training_progress
		
		# Scale based on activation
		var target_scale = 0.8 + forget_activation * 0.4
		forget_core.scale = Vector3.ONE * lerp(forget_core.scale.x, target_scale, delta * 3.0)
		
		# Change emission based on activation
		if forget_core.material_override:
			var intensity = 0.3 + forget_activation * 0.7
			forget_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	# Animate input gate
	var input_core = $LSTMCell/Gates/InputGate/InputCore
	if input_core:
		input_core.rotation.y += delta * 1.0
		var input_activation = cos(time * 1.8) * 0.5 + 0.5
		input_activation *= training_progress
		
		# Scale based on activation
		var target_scale = 0.8 + input_activation * 0.4
		input_core.scale = Vector3.ONE * lerp(input_core.scale.x, target_scale, delta * 3.0)
		
		# Change emission based on activation
		if input_core.material_override:
			var intensity = 0.3 + input_activation * 0.7
			input_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	# Animate output gate
	var output_core = $LSTMCell/Gates/OutputGate/OutputCore
	if output_core:
		output_core.rotation.y += delta * 1.4
		var output_activation = sin(time * 2.0) * 0.5 + 0.5
		output_activation *= training_progress
		
		# Scale based on activation
		var target_scale = 0.8 + output_activation * 0.4
		output_core.scale = Vector3.ONE * lerp(output_core.scale.x, target_scale, delta * 3.0)
		
		# Change emission based on activation
		if output_core.material_override:
			var intensity = 0.3 + output_activation * 0.7
			output_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_memory_flow(delta):
	# Animate memory particles
	for i in range(memory_particles.size()):
		var particle = memory_particles[i]
		if particle:
			# Move particles through the memory flow
			var progress = (time * 0.4 + float(i) * 0.1) % 1.0
			var x = lerp(-12, 12, progress)
			var y = sin(progress * PI * 2) * 1.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and training progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on training
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress
			particle.scale = Vector3.ONE * pulse

func animate_gate_activations(delta):
	# Animate gate activation indicators
	var activation_indicators = $GateActivations/ActivationIndicators
	for i in range(activation_indicators.get_child_count()):
		var indicator = activation_indicators.get_child(i)
		if indicator:
			# Pulse based on gate activation patterns
			var activation_pattern = sin(time * 1.5 + i * 0.5) * 0.5 + 0.5
			activation_pattern *= training_progress
			
			var pulse = 1.0 + activation_pattern * 0.3
			indicator.scale = Vector3.ONE * pulse
			
			# Move indicators up and down
			var y_offset = sin(time * 1.8 + i * 0.4) * 0.2 * activation_pattern
			indicator.position.y = y_offset
			
			# Change emission intensity
			if indicator.material_override:
				var intensity = 0.3 + activation_pattern * 0.7
				indicator.material_override.emission = Color(0.2, 0.8, 0.8, 1) * intensity

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
