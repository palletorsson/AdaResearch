# ============================================================================
# Attention Mechanisms Visualization
# Interactive 3D visualization of self-attention with query/key/value
# computation, attention matrix heatmap, focus indicators, and score metrics.
# Supports live query index selection and attention falloff tuning.
# ============================================================================
extends Node3D
class_name AttentionMechanismsShowcase

# --- Token Settings ---
@export_category("Token Settings")
@export var token_count: int = 6 : set = _set_token_count

func _set_token_count(v: int) -> void:
	token_count = v
	if not is_node_ready():
		return
	_create_input_tokens()
	_create_output_tokens()
	_create_attention_matrix_multimesh()
	_create_weight_lines_multimesh()
	_create_focus_indicators()

# --- Animation Controls ---
@export_category("Animation")
@export_range(0.0, 2.0, 0.01) var focus_gain: float = 0.8
@export var pulse_speed: float = 2.0
@export var rot_speed: float = 0.7
@export var matrix_cell_spacing: float = 0.4
@export var input_spacing: float = 0.8

# --- Color Palette ---
@export_category("Colors")
@export var color_input := Color(1.0, 0.85, 0.2, 1.0)   # Gold for input tokens
@export var color_output := Color(0.3, 0.5, 0.9, 1.0)   # Blue for output tokens
@export var color_matrix_base := Color(0.6, 0.6, 0.6, 0.8)
@export var color_qkv := Color(0.3, 0.85, 0.4, 1.0)     # Green for QKV
@export var color_focus := Color(0.8, 0.3, 0.9, 1.0)     # Purple for focus

# --- Internal State ---
var time: float = 0.0
var focus_intensity: float = 0.0

# --- Attention Computation ---
@export_category("Attention")
@export var query_index: int = 0 : set = _set_query_index
@export_range(0.1, 5.0, 0.1) var attention_falloff: float = 1.5

var _query_token: Node3D
var _key_tokens: Array[Node3D] = []
var _attention_scores: Array[float] = []
var _stats_label: Label3D

@onready var _input_tokens: Node3D = $InputSequence/InputTokens
@onready var _output_tokens: Node3D = $OutputSequence/OutputTokens
@onready var _matrix: MultiMeshInstance3D = $AttentionWeights/AttentionMatrix
@onready var _weight_lines: MultiMeshInstance3D = $WeightVisualization/WeightLines
@onready var _focus_spheres: Node3D = $FocusIndicators/FocusSpheres
@onready var _score_indicator: MeshInstance3D = $TrainingMetrics/AttentionScore/ScoreIndicator
@onready var _score_base: MeshInstance3D = $TrainingMetrics/AttentionScore/ScoreBase

var _matrix_mm: MultiMesh
var _lines_mm: MultiMesh

var _mesh_sphere := SphereMesh.new()
var _mesh_box := BoxMesh.new()
var _mesh_cyl := CylinderMesh.new()

var _mat_input := StandardMaterial3D.new()
var _mat_output := StandardMaterial3D.new()
var _mat_matrix := StandardMaterial3D.new()
var _mat_focus := StandardMaterial3D.new()
var _mat_qkv := StandardMaterial3D.new()

func _ready() -> void:
	_setup_materials()
	_create_input_tokens()
	_create_output_tokens()
	_create_qkv_visuals()
	_create_attention_matrix_multimesh()
	_create_weight_lines_multimesh()
	_create_focus_indicators()
	_setup_training_metrics()
	_create_stats_label()
	print("Attention Mechanisms Visualization initialized")

func _process(delta: float) -> void:
	time += delta
	
	if _query_token:
		_calculate_attention_scores()

	_animate_input_tokens(delta)
	_animate_qkv(delta)
	_animate_attention_matrix(delta)
	_animate_focus(delta)
	_update_training_metrics(delta)
	_update_stats_label()

# ============================================================================
# Attention Score Computation — Softmax over inverse-distance scores
# ============================================================================

func _calculate_attention_scores() -> void:
	_attention_scores.clear()
	if not _query_token or _key_tokens.is_empty():
		return

	var raw_scores: Array[float] = []
	var score_sum: float = 0.0

	# Include query token in key list for self-attention
	var all_tokens = _key_tokens + [_query_token]

	for key_token in all_tokens:
		var dist = _query_token.global_transform.origin.distance_to(key_token.global_transform.origin)
		var score = 1.0 / (1.0 + dist * attention_falloff)
		raw_scores.append(score)
		score_sum += score

	if score_sum > 0.0:
		for score in raw_scores:
			_attention_scores.append(score / score_sum)
	else:
		for i in range(all_tokens.size()):
			_attention_scores.append(0.0)

# ============================================================================
# Build / Setup — Materials, tokens, matrix, weight lines, focus indicators
# ============================================================================

func _setup_materials() -> void:
	## Configure shared materials with emission and metallic properties
	_mat_input.albedo_color = color_input
	_mat_input.emission_enabled = true
	_mat_input.emission = color_input * 0.5
	_mat_input.emission_energy_multiplier = 1.2
	_mat_input.metallic = 0.5
	_mat_input.roughness = 0.3

	_mat_output.albedo_color = color_output
	_mat_output.emission_enabled = true
	_mat_output.emission = color_output * 0.5
	_mat_output.emission_energy_multiplier = 1.2
	_mat_output.metallic = 0.5
	_mat_output.roughness = 0.3

	_mat_matrix.albedo_color = color_matrix_base
	_mat_matrix.emission_enabled = true
	_mat_matrix.emission = Color(color_matrix_base.r, color_matrix_base.g, color_matrix_base.b, 1.0) * 0.3

	_mat_focus.albedo_color = color_focus
	_mat_focus.emission_enabled = true
	_mat_focus.emission = color_focus * 0.5
	_mat_focus.emission_energy_multiplier = 1.8

	_mat_qkv.albedo_color = color_qkv
	_mat_qkv.emission_enabled = true
	_mat_qkv.emission = color_qkv * 0.5
	_mat_qkv.emission_energy_multiplier = 1.5
	_mat_qkv.metallic = 0.4
	_mat_qkv.roughness = 0.35

	_mesh_sphere.radius = 0.2
	_mesh_sphere.height = 0.4
	_mesh_cyl.top_radius = 0.01
	_mesh_cyl.bottom_radius = 0.01
	_mesh_cyl.height = 0.8

func _create_input_tokens() -> void:
	_clear_children(_input_tokens)
	_key_tokens.clear()
	for i in range(token_count):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_sphere
		mi.material_override = _mat_input.duplicate()
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 0, 0)
		# Staggered entrance animation
		mi.scale = Vector3.ZERO
		_input_tokens.add_child(mi)
		var tween = create_tween()
		tween.tween_property(mi, "scale", Vector3.ONE, 0.3).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_update_query_and_keys()

func _update_query_and_keys() -> void:
	if _input_tokens.get_child_count() == 0:
		return

	query_index = clamp(query_index, 0, _input_tokens.get_child_count() - 1)
	
	_key_tokens.clear()
	for i in range(_input_tokens.get_child_count()):
		var child = _input_tokens.get_child(i) as Node3D
		var mat = child.get_node(".").material_override as StandardMaterial3D
		
		if i == query_index:
			_query_token = child
			mat.albedo_color = color_qkv
			mat.emission = color_qkv * 1.0
			mat.emission_energy_multiplier = 2.0
		else:
			_key_tokens.append(child)
			mat.albedo_color = color_input
			mat.emission = color_input * 0.5

func _set_query_index(v: int) -> void:
	query_index = v
	if not is_node_ready():
		return
	_update_query_and_keys()

func _create_output_tokens() -> void:
	_clear_children(_output_tokens)
	for i in range(token_count):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_sphere
		mi.material_override = _mat_output
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 0, 0)
		_output_tokens.add_child(mi)

func _create_qkv_visuals() -> void:
	for n in ["QueryCore", "KeyCore", "ValueCore"]:
		var node := get_node_or_null("QueryKeyValue/%s" % n) as MeshInstance3D
		if node:
			var m := SphereMesh.new()
			m.radius = 0.8
			m.height = 1.6
			node.mesh = m
			node.material_override = _mat_qkv

func _create_attention_matrix_multimesh() -> void:
	_matrix_mm = MultiMesh.new()
	_matrix_mm.transform_format = MultiMesh.TRANSFORM_3D
	_matrix_mm.use_colors = true
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	_matrix_mm.mesh = s
	_matrix_mm.instance_count = token_count * token_count

	var idx := 0
	for i in range(token_count):
		for j in range(token_count):
			var x := (i - token_count / 2.0) * matrix_cell_spacing
			var z := (j - token_count / 2.0) * matrix_cell_spacing
			var t: Transform3D = Transform3D(Basis(), Vector3(x, 0, z))
			_matrix_mm.set_instance_transform(idx, t)
			_matrix_mm.set_instance_color(idx, color_matrix_base)
			idx += 1

	_matrix.multimesh = _matrix_mm
	_matrix.material_override = _mat_matrix

func _create_weight_lines_multimesh() -> void:
	_lines_mm = MultiMesh.new()
	_lines_mm.transform_format = MultiMesh.TRANSFORM_3D
	_lines_mm.use_colors = true
	_lines_mm.mesh = _mesh_cyl
	_lines_mm.instance_count = token_count * token_count

	var idx := 0
	for i in range(token_count):
		for j in range(token_count):
			var start_x := (i - token_count / 2.0) * input_spacing
			var end_x := (j - token_count / 2.0) * matrix_cell_spacing
			var mid_x  = lerp(start_x, end_x, 0.5)
			var mid_z := (j - token_count / 2.0) * matrix_cell_spacing * 0.5
			var xform: Transform3D = Transform3D()
			xform.origin = Vector3(mid_x * 0.5, 0.0, mid_z)
			_lines_mm.set_instance_transform(idx, xform)
			_lines_mm.set_instance_color(idx, Color(0.4, 0.4, 0.8, 0.6))
			idx += 1

	_weight_lines.multimesh = _lines_mm

func _create_focus_indicators() -> void:
	_clear_children(_focus_spheres)
	for i in range(token_count):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_sphere
		mi.material_override = _mat_focus.duplicate()
		mi.scale = Vector3.ONE * 0.75
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 1.5, 0)
		_focus_spheres.add_child(mi)

func _setup_training_metrics() -> void:
	if _score_indicator:
		_score_indicator.position.x = -4.0

# ============================================================================
# Animation — Tokens, QKV, Matrix, Focus, Metrics
# ============================================================================

func _animate_input_tokens(delta: float) -> void:
	if _attention_scores.size() != _input_tokens.get_child_count():
		return

	for i in range(_input_tokens.get_child_count()):
		var tkn := _input_tokens.get_child(i) as MeshInstance3D
		if tkn:
			var score: float = _attention_scores[i]
			var pulse: float = 1.0 + sin(time * pulse_speed + float(i) * 0.5) * 0.2 * score
			tkn.scale = Vector3.ONE * pulse
			tkn.rotate_y(delta * (rot_speed + float(i) * 0.15))
			
			var intensity: float = 0.3 + score * 0.7
			var mat = tkn.material_override as StandardMaterial3D
			if mat:
				if i == query_index:
					# Query token pulses with special highlight
					mat.emission_energy_multiplier = 1.5 + sin(time * 3.0) * 0.5
				else:
					mat.emission = color_input * intensity
					mat.emission_energy_multiplier = 1.0 + score

func _animate_qkv(delta: float) -> void:
	var nodes := [
		$QueryKeyValue/QueryCore,
		$QueryKeyValue/KeyCore,
		$QueryKeyValue/ValueCore
	]
	var speeds := [1.0, 0.8, 1.2]
	for i in range(nodes.size()):
		var mi := nodes[i] as MeshInstance3D
		if mi:
			mi.rotate_y(delta * speeds[i])
			mi.scale = Vector3.ONE * (1.0 + sin(time * (2.0 + 0.5 * float(i))) * 0.15)
			var mat := mi.material_override as StandardMaterial3D
			if mat:
				var q_score = _attention_scores[query_index] if not _attention_scores.is_empty() else 0.0
				mat.emission = color_qkv * (0.3 + q_score * 0.7)
				mat.emission_energy_multiplier = 1.0 + q_score

func _animate_focus(delta: float) -> void:
	if _focus_spheres.get_child_count() != token_count:
		return

	focus_intensity = lerp(focus_intensity, 1.0 if _attention_scores.size() > 0 else 0.0, delta * 5.0)

	for i in range(token_count):
		var sphere := _focus_spheres.get_child(i) as MeshInstance3D
		if sphere:
			var score = 0.0
			if i < _attention_scores.size():
				score = _attention_scores[i]
			
			var target_scale: Vector3 = Vector3.ONE * (0.1 + score * 1.5) * focus_intensity
			sphere.scale = sphere.scale.lerp(target_scale, delta * 8.0)
			
			var mat := sphere.material_override as StandardMaterial3D
			if mat:
				mat.emission = color_focus * (0.2 + score * 0.8) * focus_intensity
				mat.emission_energy_multiplier = 1.0 + score * 2.0 * focus_intensity

func _animate_attention_matrix(_delta: float) -> void:
	if _matrix_mm == null or _attention_scores.is_empty():
		return

	var idx := 0
	for row in range(token_count):
		for col in range(token_count):
			var score = 0.0
			if row == query_index and col < _attention_scores.size():
				score = _attention_scores[col]
			
			var x := (row - token_count / 2.0) * matrix_cell_spacing
			var z := (col - token_count / 2.0) * matrix_cell_spacing
			var sc: float = 0.2 + score * 0.8
			var t: Transform3D = Transform3D(Basis().scaled(Vector3.ONE * sc), Vector3(x, 0, z))
			_matrix_mm.set_instance_transform(idx, t)

			var color = color_matrix_base.lerp(color_focus, score)
			_matrix_mm.set_instance_color(idx, color)
			idx += 1

	if _lines_mm:
		# Fade weight lines based on query's self-attention score
		var q_score = _attention_scores[query_index] if not _attention_scores.is_empty() else 0.0
		for k in range(_lines_mm.instance_count):
			var col_idx = k % token_count
			var line_score = _attention_scores[col_idx] if col_idx < _attention_scores.size() else 0.0
			var fade: float = 0.05 + 0.9 * line_score
			_lines_mm.set_instance_color(k, Color(0.3, 0.3, 0.9, fade))

# ============================================================================
# Training Metrics & Stats
# ============================================================================

func _update_training_metrics(delta: float) -> void:
	if _score_indicator and not _attention_scores.is_empty():
		var avg_score = 0.0
		for s in _attention_scores:
			avg_score += s
		avg_score /= _attention_scores.size()

		var target_x  = lerp(-4.0, 4.0, avg_score)
		var p: Vector3 = _score_indicator.position
		p.x = lerp(p.x, target_x, delta * 2.0)
		_score_indicator.position = p

		var green: float = 0.2 + 0.8 * avg_score
		var red: float = 0.8 - 0.6 * avg_score
		var mat := _score_indicator.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(red, green, 0.2, 1.0)

func _create_stats_label() -> void:
	## Live stats label showing attention scores
	_stats_label = Label3D.new()
	_stats_label.text = "Attention Scores"
	_stats_label.font_size = 26
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 3.5, 0)
	add_child(_stats_label)

func _update_stats_label() -> void:
	if not _stats_label or _attention_scores.is_empty():
		return
	# Show top attention score and query info
	var max_score := 0.0
	var max_idx := 0
	for i in range(_attention_scores.size()):
		if _attention_scores[i] > max_score:
			max_score = _attention_scores[i]
			max_idx = i
	_stats_label.text = "Query: Token %d | Max Attention: %.2f (→ Token %d) | Falloff: %.1f" % [
		query_index, max_score, max_idx, attention_falloff
	]

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
