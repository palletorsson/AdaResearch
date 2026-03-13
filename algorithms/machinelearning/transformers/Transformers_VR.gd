extends Node3D

# VR-Reimagined Transformer Visualization
# Walk through token sequences with visible attention beams
# Interactive multi-head attention and positional encoding

@export_group("VR Scale")
@export var token_spacing: float = 1.2  # Distance between tokens
@export var token_size: float = 0.3  # Size of token spheres
@export var encoder_decoder_gap: float = 8.0  # Distance between encoder/decoder
@export var attention_beam_thickness: float = 0.03

@export_group("Architecture")
@export var sequence_length: int = 8  # Number of tokens in sequence
@export var num_attention_heads: int = 4  # Multi-head attention count
@export var num_encoder_layers: int = 3
@export var num_decoder_layers: int = 3

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.15
@export var show_attention_beams: bool = true
@export var show_positional_encoding: bool = true

@export_group("Interactive Elements")
@export var enable_token_grabbing: bool = true
@export var enable_head_switching: bool = true
@export var enable_query_manipulation: bool = true
@export var animate_attention_flow: bool = true

# Training state
var time: float = 0.0
var training_progress: float = 0.0
var loss: float = 1.0
var current_attention_head: int = 0

# Token arrays
var encoder_tokens: Array = []
var decoder_tokens: Array = []

# Attention structures
var attention_weights: Array = []  # [head][query_token][key_token]
var attention_beams: Array = []  # Visual beam objects
var positional_encodings: Array = []

# Query/Key/Value visualization
var qkv_visualizations: Array = []

func _ready() -> void:
	print("[Transformers_VR] Initializing transformer architecture")
	_initialize_attention()
	_create_encoder_sequence()
	_create_decoder_sequence()
	_create_attention_mechanism()
	_create_positional_encoding_viz()
	_create_qkv_visualization()
	_create_attention_head_selectors()
	_create_control_panel()
	_create_info_panels()

func _process(delta: float) -> void:
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		loss = max(0.05, 1.0 - training_progress * 0.85)

	_update_attention_weights(delta)
	_animate_tokens(delta)
	_animate_attention_beams(delta)
	if show_positional_encoding:
		_animate_positional_encoding(delta)
	_animate_qkv(delta)
	_update_control_panel()

func _initialize_attention() -> void:
	"""Initialize attention weight matrices"""
	for head in range(num_attention_heads):
		var head_weights = []
		for q_token in range(sequence_length):
			var token_weights = []
			for k_token in range(sequence_length):
				# Initialize with softmax-like distribution
				token_weights.append(randf())
			# Normalize to sum to 1.0
			var total = 0.0
			for w in token_weights:
				total += w
			for i in range(token_weights.size()):
				token_weights[i] /= max(0.001, total)
			head_weights.append(token_weights)
		attention_weights.append(head_weights)

func _create_encoder_sequence() -> void:
	"""Create encoder token sequence"""
	var encoder_container = Node3D.new()
	encoder_container.name = "EncoderSequence"
	encoder_container.position = Vector3(-encoder_decoder_gap / 2.0, 0, 0)
	add_child(encoder_container)

	# Create tokens
	for i in range(sequence_length):
		var token = _create_token(i, true)
		encoder_container.add_child(token)
		encoder_tokens.append(token)

	# Encoder label
	var label = Label3D.new()
	label.text = "ENCODER\nInput Sequence"
	label.font_size = 64
	label.outline_size = 14
	label.modulate = Color(0.3, 0.9, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	encoder_container.add_child(label)

	# Floor platform
	_create_sequence_platform(encoder_container, Color(0.3, 0.9, 0.5, 0.4))

func _create_decoder_sequence() -> void:
	"""Create decoder token sequence"""
	var decoder_container = Node3D.new()
	decoder_container.name = "DecoderSequence"
	decoder_container.position = Vector3(encoder_decoder_gap / 2.0, 0, 0)
	add_child(decoder_container)

	# Create tokens
	for i in range(sequence_length):
		var token = _create_token(i, false)
		decoder_container.add_child(token)
		decoder_tokens.append(token)

	# Decoder label
	var label = Label3D.new()
	label.text = "DECODER\nOutput Sequence"
	label.font_size = 64
	label.outline_size = 14
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	decoder_container.add_child(label)

	# Floor platform
	_create_sequence_platform(decoder_container, Color(0.9, 0.5, 0.3, 0.4))

func _create_token(index: int, is_encoder: bool) -> RigidBody3D:
	"""Create a single token sphere"""
	var body = RigidBody3D.new()
	body.name = "Token_%d" % index

	# Position vertically stacked
	var total_height = sequence_length * token_spacing
	var y = -total_height / 2.0 + index * token_spacing + token_spacing / 2.0
	body.position = Vector3(0, y, 0)

	body.gravity_scale = 0.0
	body.lock_rotation = true

	# Token mesh
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = token_size
	sphere.height = token_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	if is_encoder:
		mat.albedo_color = Color(0.3, 0.9, 0.5)
		mat.emission = Color(0.3, 0.9, 0.5)
	else:
		mat.albedo_color = Color(0.9, 0.5, 0.3)
		mat.emission = Color(0.9, 0.5, 0.3)

	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = token_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable
	if enable_token_grabbing:
		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	# Token label
	var label = Label3D.new()
	label.text = "T%d" % index
	label.font_size = 28
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, token_size + 0.25, 0)
	body.add_child(label)

	return body

func _create_sequence_platform(container: Node3D, color: Color) -> void:
	"""Create platform under sequence"""
	var platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.1, sequence_length * token_spacing + 1.0)
	platform.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.0
	mat.roughness = 1.0
	platform.material_override = mat

	platform.position = Vector3(0, -(sequence_length * token_spacing) / 2.0 - 0.5, 0)
	container.add_child(platform)

func _create_attention_mechanism() -> void:
	"""Create visual representation of attention"""
	if not show_attention_beams:
		return

	var attention_container = Node3D.new()
	attention_container.name = "AttentionBeams"
	add_child(attention_container)

	# Create beams for each attention head
	for head in range(num_attention_heads):
		var head_beams = []
		for q_idx in range(sequence_length):
			var query_beams = []
			for k_idx in range(sequence_length):
				# Create beam from encoder token to decoder token
				var beam = MeshInstance3D.new()
				var immediate_mesh = ImmediateMesh.new()
				beam.mesh = immediate_mesh
				beam.name = "Beam_H%d_Q%d_K%d" % [head, q_idx, k_idx]

				# Color per attention head
				var beam_mat = StandardMaterial3D.new()
				var head_hue = float(head) / num_attention_heads
				var beam_color = Color.from_hsv(head_hue, 0.8, 0.9, 0.5)
				beam_mat.albedo_color = beam_color
				beam_mat.emission = Color(beam_color.r, beam_color.g, beam_color.b)
				beam_mat.emission_enabled = true
				beam_mat.emission_energy_multiplier = 0.8
				beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				beam.material_override = beam_mat

				# Only show current head
				beam.visible = (head == current_attention_head)

				attention_container.add_child(beam)
				query_beams.append(beam)

			head_beams.append(query_beams)
		attention_beams.append(head_beams)

func _create_positional_encoding_viz() -> void:
	"""Create wave pattern showing positional encoding"""
	if not show_positional_encoding:
		return

	var encoding_container = Node3D.new()
	encoding_container.name = "PositionalEncoding"
	encoding_container.position = Vector3(0, -(sequence_length * token_spacing) / 2.0 - 2.0, 0)
	add_child(encoding_container)

	# Create sine wave visualization for each position
	for pos in range(sequence_length):
		var wave_particles = []
		for i in range(20):
			var particle = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.05
			sphere.height = 0.1
			particle.mesh = sphere

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.3, 0.9, 0.7)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.3, 0.9)
			mat.emission_energy_multiplier = 0.8
			mat.metallic = 0.0
			mat.roughness = 1.0
			particle.material_override = mat

			encoding_container.add_child(particle)
			wave_particles.append(particle)

		positional_encodings.append({
			"position": pos,
			"particles": wave_particles
		})

	# Label
	var label = Label3D.new()
	label.text = "POSITIONAL ENCODING\nSine/Cosine Waves"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.3, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.5, 0)
	encoding_container.add_child(label)

func _create_qkv_visualization() -> void:
	"""Create Query/Key/Value triplet visualization"""
	var qkv_container = Node3D.new()
	qkv_container.name = "QKV_Visualization"
	qkv_container.position = Vector3(0, (sequence_length * token_spacing) / 2.0 + 3.0, 0)
	add_child(qkv_container)

	# Create Q, K, V for a sample token
	var sample_token = sequence_length / 2
	var qkv_labels = ["QUERY", "KEY", "VALUE"]
	var qkv_colors = [Color(0.9, 0.3, 0.3), Color(0.3, 0.9, 0.3), Color(0.3, 0.3, 0.9)]
	var qkv_positions = [Vector3(-2.5, 0, 0), Vector3(0, 0, 0), Vector3(2.5, 0, 0)]

	for i in range(3):
		var qkv_sphere = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.4
		sphere.height = 0.8
		qkv_sphere.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = qkv_colors[i]
		mat.emission_enabled = true
		mat.emission = qkv_colors[i]
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		qkv_sphere.material_override = mat

		qkv_sphere.position = qkv_positions[i]
		qkv_container.add_child(qkv_sphere)

		# Label
		var label = Label3D.new()
		label.text = qkv_labels[i]
		label.font_size = 36
		label.outline_size = 10
		label.modulate = qkv_colors[i]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = qkv_positions[i] + Vector3(0, 0.8, 0)
		qkv_container.add_child(label)

		qkv_visualizations.append(qkv_sphere)

	# Description
	var desc = Label3D.new()
	desc.text = "Self-Attention Computation:\nAttention(Q,K,V) = softmax(QK^T/âˆšd)V"
	desc.font_size = 32
	desc.outline_size = 8
	desc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	desc.position = Vector3(0, -1.2, 0)
	qkv_container.add_child(desc)

func _create_attention_head_selectors() -> void:
	"""Create buttons to switch between attention heads"""
	if not enable_head_switching:
		return

	var selector_container = Node3D.new()
	selector_container.name = "HeadSelectors"
	selector_container.position = Vector3(0, -(sequence_length * token_spacing) / 2.0 - 4.0, -3.0)
	add_child(selector_container)

	# Label
	var label = Label3D.new()
	label.text = "ATTENTION HEAD SELECTOR"
	label.font_size = 42
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.5, 0)
	selector_container.add_child(label)

	# Create selector button for each head
	for head in range(num_attention_heads):
		var button = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 0.8, 0.2)
		button.mesh = box

		var mat = StandardMaterial3D.new()
		var head_hue = float(head) / num_attention_heads
		var head_color = Color.from_hsv(head_hue, 0.8, 0.9)
		mat.albedo_color = head_color
		mat.emission_enabled = true
		mat.emission = head_color
		mat.emission_energy_multiplier = 0.6 if head == current_attention_head else 0.3
		mat.metallic = 0.2
		mat.roughness = 0.7
		button.material_override = mat

		var x = -3.0 + head * 2.0
		button.position = Vector3(x, 0, 0)
		selector_container.add_child(button)

		# Button label
		var btn_label = Label3D.new()
		btn_label.text = "H%d" % head
		btn_label.font_size = 32
		btn_label.outline_size = 8
		btn_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		btn_label.position = Vector3(x, -0.7, 0)
		selector_container.add_child(btn_label)

func _create_control_panel() -> void:
	"""Create VR-accessible control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(encoder_decoder_gap / 2.0 + 4.0, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.5, 4.0, 0.1)
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
	title.text = "TRANSFORMER\nARCHITECTURE"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.6, 0.1)
	controls.add_child(title)

	# Architecture info
	var arch_label = Label3D.new()
	arch_label.text = "Seq Length: %d\nHeads: %d\nEnc Layers: %d\nDec Layers: %d" % [
		sequence_length, num_attention_heads, num_encoder_layers, num_decoder_layers
	]
	arch_label.font_size = 32
	arch_label.outline_size = 8
	arch_label.position = Vector3(0, 0.3, 0.1)
	controls.add_child(arch_label)

	# Metrics
	var metrics = Label3D.new()
	metrics.name = "MetricsLabel"
	metrics.text = "Loss: 1.00\nHead: 0/%d" % (num_attention_heads - 1)
	metrics.font_size = 36
	metrics.outline_size = 8
	metrics.position = Vector3(0, -0.9, 0.1)
	controls.add_child(metrics)

func _create_info_panels() -> void:
	"""Create educational info panels"""
	# Self-attention explanation
	_create_info_panel(
		Vector3(-encoder_decoder_gap / 2.0, (sequence_length * token_spacing) / 2.0 + 2.0, 3.0),
		"SELF-ATTENTION\nEach token attends to\nall other tokens\nWeights learned during training",
		Color(0.3, 0.9, 0.5)
	)

	# Multi-head explanation
	_create_info_panel(
		Vector3(0, (sequence_length * token_spacing) / 2.0 + 5.5, 0),
		"MULTI-HEAD ATTENTION\nMultiple attention patterns\nCapture different relationships\nParallel processing",
		Color(0.9, 0.7, 0.3)
	)

	# Positional encoding
	if show_positional_encoding:
		_create_info_panel(
			Vector3(0, -(sequence_length * token_spacing) / 2.0 - 3.5, -3.0),
			"POSITIONAL ENCODING\nAdds sequence position info\nSine/cosine functions\nof different frequencies",
			Color(0.9, 0.3, 0.9)
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

func _update_attention_weights(delta) -> void:
	"""Simulate changing attention patterns"""
	# Slowly shift attention weights during training
	for head in range(num_attention_heads):
		for q_idx in range(sequence_length):
			for k_idx in range(sequence_length):
				# Add small random changes
				attention_weights[head][q_idx][k_idx] += randf_range(-0.01, 0.01) * delta * training_progress

			# Renormalize
			var total = 0.0
			for w in attention_weights[head][q_idx]:
				total += max(0.0, w)
			for k_idx in range(sequence_length):
				attention_weights[head][q_idx][k_idx] = max(0.0, attention_weights[head][q_idx][k_idx]) / max(0.001, total)

func _animate_tokens(_delta) -> void:
	"""Animate token spheres"""
	for i in range(encoder_tokens.size()):
		var token = encoder_tokens[i]
		var pulse = 1.0 + sin(time * 2.0 + i * 0.3) * 0.15 * training_progress
		token.scale = Vector3.ONE * pulse

	for i in range(decoder_tokens.size()):
		var token = decoder_tokens[i]
		var pulse = 1.0 + cos(time * 2.2 + i * 0.4) * 0.15 * training_progress
		token.scale = Vector3.ONE * pulse

func _animate_attention_beams(_delta) -> void:
	"""Update attention beam visualizations"""
	if not show_attention_beams:
		return

	var head = current_attention_head
	for q_idx in range(sequence_length):
		var query_token = decoder_tokens[q_idx]
		for k_idx in range(sequence_length):
			var key_token = encoder_tokens[k_idx]
			var beam = attention_beams[head][q_idx][k_idx]

			if beam.visible:
				# Update beam geometry
				var immediate_mesh = beam.mesh as ImmediateMesh
				immediate_mesh.clear_surfaces()
				immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

				immediate_mesh.surface_add_vertex(query_token.global_position)
				immediate_mesh.surface_add_vertex(key_token.global_position)

				immediate_mesh.surface_end()

				# Update intensity based on attention weight
				var weight = attention_weights[head][q_idx][k_idx]
				beam.material_override.emission_energy_multiplier = weight * 2.0

func _animate_positional_encoding(_delta) -> void:
	"""Animate positional encoding waves"""
	for encoding_data in positional_encodings:
		var pos = encoding_data.position
		var particles = encoding_data.particles

		for i in range(particles.size()):
			var particle = particles[i]
			var t = float(i) / particles.size()

			# Sine wave pattern
			var freq = 1.0 / pow(10000.0, 2.0 * float(pos) / sequence_length)
			var x = -encoder_decoder_gap / 2.0 + t * encoder_decoder_gap
			var y = sin(time * 2.0 + t * TAU * 2.0 + pos * 0.5) * 0.5
			var z = -(sequence_length * token_spacing) / 2.0 + pos * token_spacing

			particle.position = Vector3(x, y, z)

func _animate_qkv(_delta) -> void:
	"""Animate Query/Key/Value spheres"""
	for i in range(qkv_visualizations.size()):
		var qkv = qkv_visualizations[i]
		var pulse = 1.0 + sin(time * 2.0 + i * TAU / 3.0) * 0.2
		qkv.scale = Vector3.ONE * pulse

func _update_control_panel() -> void:
	"""Update control panel displays"""
	var controls = get_node_or_null("ControlPanel")
	if not controls:
		return

	var metrics = controls.get_node_or_null("MetricsLabel")
	if metrics:
		metrics.text = "Loss: %.3f\nHead: %d/%d" % [loss, current_attention_head, num_attention_heads - 1]

# Public API
func switch_attention_head(head: int) -> void:
	"""Switch to different attention head"""
	if head < 0 or head >= num_attention_heads:
		return

	# Hide current head beams
	for q_idx in range(sequence_length):
		for k_idx in range(sequence_length):
			attention_beams[current_attention_head][q_idx][k_idx].visible = false

	current_attention_head = head

	# Show new head beams
	for q_idx in range(sequence_length):
		for k_idx in range(sequence_length):
			attention_beams[current_attention_head][q_idx][k_idx].visible = true

func reset_training() -> void:
	training_progress = 0.0
	loss = 1.0
	time = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

