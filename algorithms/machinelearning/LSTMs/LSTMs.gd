# ============================================================================
# LSTM Networks Visualization
# Interactive 3D visualization of Long Short-Term Memory networks showing
# cell state, gates (forget/input/output), hidden state, and memory flow
# with live training metrics.
# ============================================================================
extends Node3D
class_name LSTMShowcase

# --- Runtime UI Controls ---
@export_category("Sequence Settings")
@export_range(4, 16, 1) var sequence_length: int = 8 : set = _set_sequence_length

@export_category("Animation")
@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export_range(0.5, 3.0, 0.1) var pulse_intensity: float = 1.0
@export_range(0.1, 1.0, 0.05) var gate_responsiveness: float = 0.5

@export_category("Training Simulation")
@export_range(0.01, 0.5, 0.01) var training_rate: float = 0.1
@export var auto_train: bool = true

@export_category("Colors")
@export var color_input := Color(1.0, 0.85, 0.2, 1.0)      # Gold for input
@export var color_output := Color(0.3, 0.5, 0.9, 1.0)      # Blue for output
@export var color_cell := Color(0.3, 0.85, 0.4, 1.0)       # Green for cell core
@export var color_gate := Color(0.9, 0.3, 0.3, 1.0)        # Red for gates
@export var color_memory := Color(0.3, 0.5, 0.9, 1.0)      # Blue for memory flow
@export var color_activation := Color(0.3, 0.85, 0.85, 1.0) # Cyan for activations

# --- Internal State ---
var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0
var memory_particles: Array = []
var _stats_label: Label3D
var _gate_label: Label3D

func _set_sequence_length(v: int) -> void:
	sequence_length = v
	if not is_node_ready():
		return
	_clear_children($InputSequence/InputTokens)
	_clear_children($OutputSequence/OutputTokens)
	create_input_tokens()
	create_output_tokens()

func _ready():
	print("LSTM Networks Visualization initialized")
	create_input_tokens()
	create_output_tokens()
	create_memory_particles()
	create_gate_activations()
	setup_training_metrics()
	_create_stats_labels()

func _process(delta):
	var scaled_delta = delta * animation_speed
	time += scaled_delta
	
	# Simulate training progress with configurable rate
	if auto_train:
		training_progress = min(1.0, time * training_rate)
		loss_value = max(0.1, 1.0 - training_progress * 0.8)
		accuracy = training_progress * 0.9
	
	animate_lstm_cell(scaled_delta)
	animate_gates(scaled_delta)
	animate_memory_flow(scaled_delta)
	animate_gate_activations(scaled_delta)
	update_training_metrics(scaled_delta)
	_update_stats_labels()

# ============================================================================
# Token Creation — Input/Output sequence with metallic materials
# ============================================================================

func create_input_tokens():
	## Create input sequence tokens with gold metallic materials
	var input_tokens = $InputSequence/InputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_input
		mat.emission_enabled = true
		mat.emission = color_input * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.6
		mat.roughness = 0.3
		token.material_override = mat
		
		var x = (i - sequence_length / 2.0) * 0.6
		token.position = Vector3(x, 0, 0)
		token.scale = Vector3.ZERO
		input_tokens.add_child(token)
		# Staggered entrance animation
		var tween = create_tween()
		tween.tween_property(token, "scale", Vector3.ONE, 0.3).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_output_tokens():
	## Create output sequence tokens with blue metallic materials
	var output_tokens = $OutputSequence/OutputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_output
		mat.emission_enabled = true
		mat.emission = color_output * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.6
		mat.roughness = 0.3
		token.material_override = mat
		
		var x = (i - sequence_length / 2.0) * 0.6
		token.position = Vector3(x, 0, 0)
		token.scale = Vector3.ZERO
		output_tokens.add_child(token)
		var tween = create_tween()
		tween.tween_property(token, "scale", Vector3.ONE, 0.3).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ============================================================================
# Memory & Gate Particles
# ============================================================================

func create_memory_particles():
	## Create glowing memory flow particles with transparency
	var memory_particles_node = $MemoryFlow/MemoryParticles
	for i in range(15):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_memory
		mat.emission_enabled = true
		mat.emission = color_memory * 0.6
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		particle.material_override = mat
		
		# Position particles along the memory flow path
		var progress = float(i) / 15
		var x = lerp(-12, 12, progress)
		var y = sin(progress * PI * 2) * 1.5
		particle.position = Vector3(x, y, 0)
		
		memory_particles_node.add_child(particle)
		memory_particles.append(particle)

func create_gate_activations():
	## Create gate activation indicators with cyan glow
	var activation_indicators = $GateActivations/ActivationIndicators
	for i in range(6):
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.1
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_activation
		mat.emission_enabled = true
		mat.emission = color_activation * 0.5
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.4
		mat.roughness = 0.4
		indicator.material_override = mat
		
		# Position indicators in a ring around the LSTM cell
		var angle = float(i) / 6 * PI * 2
		var radius = 5.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		indicator.position = Vector3(x, 0, z)
		
		activation_indicators.add_child(indicator)

func setup_training_metrics():
	## Initialize loss and accuracy meter positions
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if loss_indicator:
		loss_indicator.position.x = 0
	if accuracy_indicator:
		accuracy_indicator.position.x = 0

# ============================================================================
# Animation — LSTM Cell, Gates, Memory Flow
# ============================================================================

func animate_lstm_cell(delta):
	## Animate LSTM cell core — green glow intensifies with training
	var cell_core = $LSTMCell/CellCore
	if cell_core:
		cell_core.rotation.y += delta * 0.4
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * training_progress * pulse_intensity
		cell_core.scale = Vector3.ONE * pulse
		if cell_core.material_override:
			var intensity = 0.3 + training_progress * 0.7
			cell_core.material_override.emission = color_cell * intensity
			cell_core.material_override.emission_energy_multiplier = 1.0 + training_progress
	
	## Animate cell state — represents long-term memory retention
	var state_core = $LSTMCell/CellState/StateCore
	if state_core:
		state_core.rotation.y += delta * 0.6
		state_core.scale = Vector3.ONE * (1.0 + sin(time * 1.8) * 0.15 * pulse_intensity)
		if state_core.material_override:
			var memory_retention = 0.5 + training_progress * 0.5
			var intensity = 0.3 + memory_retention * 0.7
			state_core.material_override.emission = color_cell * intensity
			state_core.material_override.emission_energy_multiplier = 1.0 + memory_retention * 0.5
	
	## Animate hidden state — represents information output
	var hidden_core = $LSTMCell/HiddenState/HiddenCore
	if hidden_core:
		hidden_core.rotation.y += delta * 0.8
		hidden_core.scale = Vector3.ONE * (1.0 + sin(time * 2.2) * 0.15 * pulse_intensity)
		if hidden_core.material_override:
			var info_flow = 0.3 + training_progress * 0.7
			var intensity = 0.3 + info_flow * 0.7
			hidden_core.material_override.emission = color_cell * intensity

func animate_gates(delta):
	## Animate forget gate — controls what to discard from cell state
	var forget_core = $LSTMCell/Gates/ForgetGate/ForgetCore
	var forget_val := 0.0
	if forget_core:
		forget_core.rotation.y += delta * 1.2
		var forget_activation = sin(time * 1.5 * gate_responsiveness) * 0.5 + 0.5
		forget_activation *= training_progress
		forget_val = forget_activation
		var target_scale = 0.8 + forget_activation * 0.4
		forget_core.scale = Vector3.ONE * lerp(forget_core.scale.x, target_scale, delta * 3.0)
		if forget_core.material_override:
			var intensity = 0.3 + forget_activation * 0.7
			forget_core.material_override.emission = color_gate * intensity
			forget_core.material_override.emission_energy_multiplier = 1.0 + forget_activation
	
	## Animate input gate — controls what new info to store
	var input_core = $LSTMCell/Gates/InputGate/InputCore
	var input_val := 0.0
	if input_core:
		input_core.rotation.y += delta * 1.0
		var input_activation = cos(time * 1.8 * gate_responsiveness) * 0.5 + 0.5
		input_activation *= training_progress
		input_val = input_activation
		var target_scale = 0.8 + input_activation * 0.4
		input_core.scale = Vector3.ONE * lerp(input_core.scale.x, target_scale, delta * 3.0)
		if input_core.material_override:
			var intensity = 0.3 + input_activation * 0.7
			input_core.material_override.emission = color_gate * intensity
			input_core.material_override.emission_energy_multiplier = 1.0 + input_activation
	
	## Animate output gate — controls what to output from cell state
	var output_core = $LSTMCell/Gates/OutputGate/OutputCore
	var output_val := 0.0
	if output_core:
		output_core.rotation.y += delta * 1.4
		var output_activation = sin(time * 2.0 * gate_responsiveness) * 0.5 + 0.5
		output_activation *= training_progress
		output_val = output_activation
		var target_scale = 0.8 + output_activation * 0.4
		output_core.scale = Vector3.ONE * lerp(output_core.scale.x, target_scale, delta * 3.0)
		if output_core.material_override:
			var intensity = 0.3 + output_activation * 0.7
			output_core.material_override.emission = color_gate * intensity
			output_core.material_override.emission_energy_multiplier = 1.0 + output_activation
	
	# Update gate label with live values
	if _gate_label:
		_gate_label.text = "Forget: %.2f | Input: %.2f | Output: %.2f" % [forget_val, input_val, output_val]

func animate_memory_flow(delta):
	## Animate memory particles flowing through the LSTM pipeline
	for i in range(memory_particles.size()):
		var particle = memory_particles[i]
		if particle:
			var progress = fmod(time * 0.4 + float(i) * 0.1, 1.0)
			var x = lerp(-12, 12, progress)
			var y = sin(progress * PI * 2) * 1.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Gradient color shift along the flow path
			var color_progress = fmod((progress + 0.5), 1.0)
			var flow_color = color_memory.lerp(color_gate, color_progress)
			particle.material_override.albedo_color = Color(flow_color.r, flow_color.g, flow_color.b, 0.85)
			particle.material_override.emission = flow_color * 0.6
			
			# Pulse particles based on training
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * training_progress * pulse_intensity
			particle.scale = Vector3.ONE * pulse

func animate_gate_activations(_delta):
	## Animate gate activation indicator ring
	var activation_indicators = $GateActivations/ActivationIndicators
	for i in range(activation_indicators.get_child_count()):
		var indicator = activation_indicators.get_child(i)
		if indicator:
			var activation_pattern = sin(time * 1.5 + i * 0.5) * 0.5 + 0.5
			activation_pattern *= training_progress
			
			var pulse = 1.0 + activation_pattern * 0.3 * pulse_intensity
			indicator.scale = Vector3.ONE * pulse
			
			# Float up and down
			var y_offset = sin(time * 1.8 + i * 0.4) * 0.2 * activation_pattern
			indicator.position.y = y_offset
			
			if indicator.material_override:
				var intensity = 0.3 + activation_pattern * 0.7
				indicator.material_override.emission = color_activation * intensity
				indicator.material_override.emission_energy_multiplier = 1.0 + activation_pattern

# ============================================================================
# Training Metrics — Loss and accuracy meters
# ============================================================================

func update_training_metrics(delta):
	## Update loss meter position and color
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	if loss_indicator:
		var target_x = lerp(-2, 2, 1.0 - loss_value)
		loss_indicator.position.x = lerp(loss_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * (1.0 - loss_value)
		var red_component = 0.2 + 0.6 * loss_value
		loss_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	## Update accuracy meter position and color
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		var green_component = 0.8 * accuracy
		var red_component = 0.2 + 0.6 * (1.0 - accuracy)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

# ============================================================================
# Public API
# ============================================================================

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
	## Reset all training state with visual feedback
	time = 0.0
	training_progress = 0.0
	loss_value = 1.0
	accuracy = 0.0
	if _stats_label:
		var tween = create_tween()
		tween.tween_property(_stats_label, "modulate", Color(1.0, 0.85, 0.2), 0.15)
		tween.tween_property(_stats_label, "modulate", Color.WHITE, 0.3)

# ============================================================================
# Stats Labels — Live HUD in 3D space
# ============================================================================

func _create_stats_labels() -> void:
	_stats_label = Label3D.new()
	_stats_label.text = "Loss: 1.000 | Acc: 0.0%"
	_stats_label.font_size = 28
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 4.5, 0)
	add_child(_stats_label)
	
	_gate_label = Label3D.new()
	_gate_label.text = "Forget: 0.00 | Input: 0.00 | Output: 0.00"
	_gate_label.font_size = 22
	_gate_label.outline_size = 3
	_gate_label.modulate = Color(0.9, 0.7, 0.7)
	_gate_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_gate_label.position = Vector3(0, 5.2, 0)
	add_child(_gate_label)

func _update_stats_labels() -> void:
	if _stats_label:
		_stats_label.text = "Loss: %.3f | Accuracy: %.1f%%" % [loss_value, accuracy * 100.0]
		var health = 1.0 - loss_value
		_stats_label.modulate = Color(
			0.9 - health * 0.6,
			0.3 + health * 0.65,
			0.2, 1.0
		)

# ============================================================================
# Utility
# ============================================================================

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()
