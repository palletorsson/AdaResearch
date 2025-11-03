extends Node3D
 

@export var token_count: int = 6 : set = _set_token_count

@export_range(0.0, 2.0, 0.01) var focus_gain: float = 0.8
@export var pulse_speed: float = 2.0
@export var rot_speed: float = 0.7
@export var matrix_cell_spacing: float = 0.4
@export var input_spacing: float = 0.8

@export var color_input := Color(0.8, 0.8, 0.2, 1.0)
@export var color_output := Color(0.2, 0.8, 0.8, 1.0)
@export var color_matrix_base := Color(0.6, 0.6, 0.6, 0.8)
@export var color_qkv := Color(0.2, 0.8, 0.2, 1.0)
@export var color_focus := Color(0.8, 0.2, 0.8, 1.0)

var time: float = 0.0
# var attention_score: float = 0.0 # Deprecated
var focus_intensity: float = 0.0

# New variables for functional attention
@export var query_index: int = 0 : set = _set_query_index
@export_range(0.1, 5.0, 0.1) var attention_falloff: float = 1.5

var _query_token: Node3D
var _key_tokens: Array[Node3D] = []
var _attention_scores: Array[float] = []


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

func _calculate_attention_scores():
	_attention_scores.clear()
	if not _query_token or _key_tokens.is_empty():
		return

	var raw_scores: Array[float] = []
	var score_sum: float = 0.0

	# Add the query token to the list of keys for self-attention
	var all_tokens = _key_tokens + [_query_token]

	for key_token in all_tokens:
		var dist = _query_token.global_transform.origin.distance_to(key_token.global_transform.origin)
		# Inverse distance scoring, with falloff
		var score = 1.0 / (1.0 + dist * attention_falloff)
		raw_scores.append(score)
		score_sum += score

	if score_sum > 0.0:
		for score in raw_scores:
			_attention_scores.append(score / score_sum) # Normalize scores (softmax)
	else:
		for _ in all_tokens:
			_attention_scores.append(0.0)


# ---------- BUILD / SETUP ----------

func _setup_materials() -> void:
	_mat_input.albedo_color = color_input
	_mat_input.emission_enabled = true
	_mat_input.emission = color_input * 0.3

	_mat_output.albedo_color = color_output
	_mat_output.emission_enabled = true
	_mat_output.emission = color_output * 0.3

	_mat_matrix.albedo_color = color_matrix_base
	_mat_matrix.emission_enabled = true
	_mat_matrix.emission = Color(color_matrix_base.r, color_matrix_base.g, color_matrix_base.b, 1.0) * 0.2

	_mat_focus.albedo_color = color_focus
	_mat_focus.emission_enabled = true
	_mat_focus.emission = color_focus * 0.35

	_mat_qkv.albedo_color = color_qkv
	_mat_qkv.emission_enabled = true
	_mat_qkv.emission = color_qkv * 0.3

	_mesh_sphere.radius = 0.2
	_mesh_cyl.top_radius = 0.01
	_mesh_cyl.bottom_radius = 0.01
	_mesh_cyl.height = 0.8

func _create_input_tokens() -> void:
	_clear_children(_input_tokens)
	_key_tokens.clear()
	for i in range(token_count):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_sphere
		mi.material_override = _mat_input.duplicate() # Use duplicate materials for individual control
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 0, 0)
		_input_tokens.add_child(mi)
	
	_update_query_and_keys()

func _update_query_and_keys():
	if _input_tokens.get_child_count() == 0:
		return

	query_index = clamp(query_index, 0, _input_tokens.get_child_count() - 1)
	
	_key_tokens.clear()
	for i in range(_input_tokens.get_child_count()):
		var child = _input_tokens.get_child(i) as Node3D
		var mat = child.get_node(".").material_override as StandardMaterial3D
		
		if i == query_index:
			_query_token = child
			mat.albedo_color = color_qkv # Visually distinguish the query token
			mat.emission = color_qkv * 0.8
		else:
			_key_tokens.append(child)
			mat.albedo_color = color_input
			mat.emission = color_input * 0.3

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
			node.mesh = m
			node.material_override = _mat_qkv

func _create_attention_matrix_multimesh() -> void:
	_matrix_mm = MultiMesh.new()
	_matrix_mm.transform_format = MultiMesh.TRANSFORM_3D
	_matrix_mm.use_colors = true
	var s := SphereMesh.new()
	s.radius = 0.05
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
		mi.material_override = _mat_focus
		mi.scale = Vector3.ONE * 0.75
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 1.5, 0)
		_focus_spheres.add_child(mi)

func _setup_training_metrics() -> void:
	if _score_indicator:
		_score_indicator.position.x = -4.0

# ---------- ANIMATION ----------

func _animate_input_tokens(delta: float) -> void:
	if _attention_scores.size() != _input_tokens.get_child_count():
		return

	for i in range(_input_tokens.get_child_count()):
		var tkn := _input_tokens.get_child(i) as MeshInstance3D
		if tkn:
			var score = _attention_scores[i]
			var pulse := 1.0 + sin(time * pulse_speed + float(i) * 0.5) * 0.2 * score
			tkn.scale = Vector3.ONE * pulse
			tkn.rotate_y(delta * (rot_speed + float(i) * 0.15))
			
			var intensity := 0.3 + score * 0.7
			var mat = tkn.material_override as StandardMaterial3D
			if mat:
				if i != query_index: # Don't override the query token's special color
					mat.emission = color_input * intensity

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
				# Use the query's self-attention score to drive the QKV visuals
				var q_score = _attention_scores[query_index] if not _attention_scores.is_empty() else 0.0
				mat.emission = color_qkv * (0.3 + q_score * 0.7)

func _animate_attention_matrix(delta: float) -> void:
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
			var sc := 0.2 + score * 0.8
			var t: Transform3D = Transform3D(Basis().scaled(Vector3.ONE * sc), Vector3(x, 0, z))
			_matrix_mm.set_instance_transform(idx, t)

			var color = color_matrix_base.lerp(color_focus, score)
			_matrix_mm.set_instance_color(idx, color)
			idx += 1

	if _lines_mm:
		# This part needs a more complex rewrite to look good.
		# For now, let's just fade it based on the query's self-attention.
		var q_score = _attention_scores[query_index] if not _attention_scores.is_empty() else 0.0
		for k in range(_lines_mm.instance_count):
			var fade := 0.1 + 0.8 * q_score
			_lines_mm.set_instance_color(k, Color(0.4, 0.4, 0.8, fade))


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

		var green := 0.2 + 0.8 * avg_score
		var red := 0.8 - 0.6 * avg_score
		var mat := _score_indicator.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(red, green, 0.2, 1.0)

# ---------- API ----------



# ---------- UTIL ----------

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()
