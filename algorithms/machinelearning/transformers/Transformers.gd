# ============================================================================
# Transformers Visualization
# Interactive 3D visualization of the Transformer architecture showing
# encoder/decoder layers, multi-head attention, positional encoding,
# and data flow with live training metrics.
# ============================================================================
extends Node3D

# --- Runtime UI Controls ---
@export_category("Sequence Settings")
@export_range(4, 16, 1) var sequence_length: int = 8 : set = _set_sequence_length
@export_range(2, 8, 1) var attention_heads: int = 4

@export_category("Animation")
@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export_range(0.5, 3.0, 0.1) var pulse_intensity: float = 1.0

@export_category("Training Simulation")
@export_range(0.01, 0.5, 0.01) var training_rate: float = 0.1
@export var auto_train: bool = true

@export_category("Colors")
@export var color_input_token := Color(1.0, 0.85, 0.2, 1.0)   # Gold for input tokens
@export var color_output_token := Color(0.3, 0.5, 0.9, 1.0)   # Blue for output tokens
@export var color_encoder := Color(0.3, 0.85, 0.4, 1.0)       # Green for encoder
@export var color_decoder := Color(0.9, 0.3, 0.3, 1.0)        # Red for decoder
@export var color_flow := Color(0.3, 0.5, 0.9, 1.0)           # Blue for data flow

# --- Internal State ---
var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0
var flow_particles: Array = []
var _stats_label: Label3D
var _epoch_label: Label3D

func _set_sequence_length(v: int) -> void:
	sequence_length = v
	if not is_node_ready():
		return
	_rebuild_tokens()

func _rebuild_tokens() -> void:
	# Clear and recreate token visuals when sequence length changes
	_clear_children($InputSequence/InputTokens)
	_clear_children($OutputSequence/OutputTokens)
	create_input_tokens()
	create_output_tokens()

func _ready() -> void:
	# Initialize Transformers visualization
	print("Transformers Visualization initialized")
	create_input_tokens()
	create_output_tokens()
	create_flow_particles()
	setup_training_metrics()
	_create_stats_labels()

func _process(delta: float) -> void:
	var scaled_delta = delta * animation_speed
	time += scaled_delta
	
	# Simulate training progress with configurable rate
	if auto_train:
		training_progress = min(1.0, time * training_rate)
		loss_value = max(0.1, 1.0 - training_progress * 0.8)
		accuracy = training_progress * 0.9
	
	animate_transformer_layers(scaled_delta)
	animate_attention_heads(scaled_delta)
	animate_positional_encoding(scaled_delta)
	animate_data_flow(scaled_delta)
	update_training_metrics(scaled_delta)
	_update_stats_labels()

func create_input_tokens() -> void:
	## Create input sequence tokens with gold metallic materials
	var input_tokens = $InputSequence/InputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_input_token
		mat.emission_enabled = true
		mat.emission = color_input_token * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.6
		mat.roughness = 0.3
		token.material_override = mat
		
		var x = (i - sequence_length / 2.0) * 0.6
		token.position = Vector3(x, 0, 0)
		# Animate entrance with a scale tween
		token.scale = Vector3.ZERO
		input_tokens.add_child(token)
		var tween = create_tween()
		tween.tween_property(token, "scale", Vector3.ONE, 0.3).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_output_tokens() -> void:
	## Create output sequence tokens with blue metallic materials
	var output_tokens = $OutputSequence/OutputTokens
	for i in range(sequence_length):
		var token = CSGSphere3D.new()
		token.radius = 0.15
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_output_token
		mat.emission_enabled = true
		mat.emission = color_output_token * 0.5
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.6
		mat.roughness = 0.3
		token.material_override = mat
		
		var x = (i - sequence_length / 2.0) * 0.6
		token.position = Vector3(x, 0, 0)
		# Animate entrance with a scale tween
		token.scale = Vector3.ZERO
		output_tokens.add_child(token)
		var tween = create_tween()
		tween.tween_property(token, "scale", Vector3.ONE, 0.3).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_flow_particles() -> void:
	## Create glowing data flow particles that travel through the transformer pipeline
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(20):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_flow
		mat.emission_enabled = true
		mat.emission = color_flow * 0.6
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		particle.material_override = mat
		
		# Position particles along the transformer flow path
		var progress = float(i) / 20
		var x = lerp(-12, 12, progress)
		var y = sin(progress * PI * 3) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_training_metrics() -> void:
	# Initialize loss and accuracy meters
	var loss_indicator = $TrainingMetrics/LossMeter/LossIndicator
	var accuracy_indicator = $TrainingMetrics/AccuracyMeter/AccuracyIndicator
	if loss_indicator:
		loss_indicator.position.x = 0  # Start at middle
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle

func animate_transformer_layers(delta) -> void:
	# --- Encoder Layers: green glow intensifies with training ---
	var encoder_layers = [$TransformerLayers/EncoderLayer1/EncoderCore1, $TransformerLayers/EncoderLayer2/EncoderCore2]
	for i in range(encoder_layers.size()):
		var layer = encoder_layers[i]
		if layer:
			layer.rotation.y += delta * (0.5 + i * 0.2)
			var pulse = 1.0 + sin(time * 2.0 + i * PI) * 0.1 * training_progress * pulse_intensity
			layer.scale = Vector3.ONE * pulse
			if layer.material_override:
				var intensity = 0.3 + training_progress * 0.7
				layer.material_override.emission = color_encoder * intensity
				layer.material_override.emission_energy_multiplier = 1.0 + training_progress
	
	# --- Decoder Layers: red glow intensifies with training ---
	var decoder_layers = [$TransformerLayers/DecoderLayer1/DecoderCore1, $TransformerLayers/DecoderLayer2/DecoderCore2]
	for i in range(decoder_layers.size()):
		var layer = decoder_layers[i]
		if layer:
			layer.rotation.y += delta * (0.6 + i * 0.3)
			var pulse = 1.0 + sin(time * 2.5 + i * PI) * 0.1 * training_progress * pulse_intensity
			layer.scale = Vector3.ONE * pulse
			if layer.material_override:
				var intensity = 0.3 + training_progress * 0.7
				layer.material_override.emission = color_decoder * intensity
				layer.material_override.emission_energy_multiplier = 1.0 + training_progress

func animate_attention_heads(delta) -> void:
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

func animate_positional_encoding(delta) -> void:
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

func animate_data_flow(delta) -> void:
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

func update_training_metrics(delta) -> void:
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

func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func set_loss_value(loss: float) -> void:
	loss_value = clamp(loss, 0.1, 1.0)

func set_accuracy(acc: float) -> void:
	accuracy = clamp(acc, 0.0, 1.0)

func get_training_progress() -> float:
	return training_progress

func get_loss_value() -> float:
	return loss_value

func get_accuracy() -> float:
	return accuracy

func reset_training() -> void:
	## Reset all training state and animate the reset with a tween
	time = 0.0
	training_progress = 0.0
	loss_value = 1.0
	accuracy = 0.0
	# Flash the stats label gold to indicate reset
	if _stats_label:
		var tween = create_tween()
		tween.tween_property(_stats_label, "modulate", Color(1.0, 0.85, 0.2), 0.15)
		tween.tween_property(_stats_label, "modulate", Color.WHITE, 0.3)

# ============================================================================
# Stats Labels — Live HUD showing training metrics in 3D space
# ============================================================================

func _create_stats_labels() -> void:
	## Create floating 3D labels for live training stats
	_stats_label = Label3D.new()
	_stats_label.text = "Loss: 1.000 | Acc: 0.0%"
	_stats_label.font_size = 28
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 4.5, 0)
	add_child(_stats_label)
	
	_epoch_label = Label3D.new()
	_epoch_label.text = "Transformer Architecture"
	_epoch_label.font_size = 22
	_epoch_label.outline_size = 3
	_epoch_label.modulate = Color(0.8, 0.8, 0.9)
	_epoch_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_epoch_label.position = Vector3(0, 5.2, 0)
	add_child(_epoch_label)

func _update_stats_labels() -> void:
	## Update the floating stats with current training metrics
	if _stats_label:
		_stats_label.text = "Loss: %.3f | Accuracy: %.1f%%" % [loss_value, accuracy * 100.0]
		# Color-code: green when good, red when bad
		var health = 1.0 - loss_value
		_stats_label.modulate = Color(
			0.9 - health * 0.6,   # Red fades out
			0.3 + health * 0.65,  # Green fades in
			0.2, 1.0
		)
	if _epoch_label:
		_epoch_label.text = "Transformer | Progress: %.0f%% | Heads: %d" % [training_progress * 100.0, attention_heads]

# ============================================================================
# Utility
# ============================================================================

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
