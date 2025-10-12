extends Node3D
 

@export var token_count: int = 6 : set = _set_token_count
@export_range(0.0, 1.0, 0.01) var base_attention: float = 0.0
@export_range(0.0, 2.0, 0.01) var attention_gain: float = 0.15
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
var attention_score: float = 0.0
var focus_intensity: float = 0.0

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
	attention_score = clamp(lerp(attention_score, base_attention + time * attention_gain, delta * 0.8), 0.0, 1.0)
	focus_intensity = clamp(attention_score * focus_gain, 0.0, 1.0)

	_animate_input_tokens(delta)
	_animate_qkv(delta)
	_animate_attention_matrix(delta)
	_animate_focus(delta)
	_update_training_metrics(delta)

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
	for i in range(token_count):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_sphere
		mi.material_override = _mat_input
		var x := (i - token_count / 2.0) * input_spacing
		mi.position = Vector3(x, 0, 0)
		_input_tokens.add_child(mi)

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
	for i in range(_input_tokens.get_child_count()):
		var tkn := _input_tokens.get_child(i) as MeshInstance3D
		if tkn:
			var pulse := 1.0 + sin(time * pulse_speed + float(i) * 0.5) * 0.2 * attention_score
			tkn.scale = Vector3.ONE * pulse
			tkn.rotate_y(delta * (rot_speed + float(i) * 0.15))
			var intensity := 0.3 + attention_score * 0.7
			var mat := tkn.material_override as StandardMaterial3D
			if mat:
				mat.emission = color_input * intensity

	for i in range(_output_tokens.get_child_count()):
		var tkn := _output_tokens.get_child(i) as MeshInstance3D
		if tkn:
			var pulse := 1.0 + sin(time * (pulse_speed * 0.9) + float(i) * 0.35) * 0.16 * attention_score
			tkn.scale = Vector3.ONE * pulse
			tkn.rotate_y(delta * (rot_speed * 0.85 + float(i) * 0.12))
			var mat := tkn.material_override as StandardMaterial3D
			if mat:
				mat.emission = color_output * (0.3 + attention_score * 0.6)

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
				mat.emission = color_qkv * (0.3 + attention_score * 0.7)

func _animate_attention_matrix(delta: float) -> void:
	if _matrix_mm == null:
		return

	var idx := 0
	for row in range(token_count):
		for col in range(token_count):
			var att := (sin(time * 1.5 + float(row) * 0.5) * 0.5 + 0.5)
			att *= (cos(time * 1.2 + float(col) * 0.35) * 0.5 + 0.5)
			att *= attention_score

			var x := (row - token_count / 2.0) * matrix_cell_spacing
			var z := (col - token_count / 2.0) * matrix_cell_spacing
			var sc := 0.5 + att * 0.55
			var t: Transform3D = Transform3D(Basis().scaled(Vector3.ONE * sc), Vector3(x, 0, z))
			_matrix_mm.set_instance_transform(idx, t)

			var g := 0.6 + att * 0.4
			var b := 0.6 + att * 0.4
			_matrix_mm.set_instance_color(idx, Color(0.6, g, b, 0.95))
			idx += 1

	if _lines_mm:
		for k in range(_lines_mm.instance_count):
			var fade := 0.4 + 0.6 * attention_score
			_lines_mm.set_instance_color(k, Color(0.4, 0.4, 0.8, fade))

func _animate_focus(delta: float) -> void:
	for i in range(_focus_spheres.get_child_count()):
		var sp := _focus_spheres.get_child(i) as MeshInstance3D
		if sp:
			var pulse := 1.0 + sin(time * 2.5 + float(i) * 0.3) * 0.3 * focus_intensity
			sp.scale = Vector3.ONE * pulse
			var y_off := sin(time * 1.8 + float(i) * 0.4) * 0.2 * focus_intensity
			var p: Vector3 = sp.position
			p.y = 1.5 + y_off
			sp.position = p

			var mat := sp.material_override as StandardMaterial3D
			if mat:
				mat.emission = color_focus * (0.3 + focus_intensity * 0.7)

func _update_training_metrics(delta: float) -> void:
	if _score_indicator:
		var target_x  = lerp(-4.0, 4.0, attention_score)
		var p: Vector3 = _score_indicator.position
		p.x = lerp(p.x, target_x, delta * 2.0)
		_score_indicator.position = p

		var green := 0.2 + 0.8 * attention_score
		var red := 0.8 - 0.6 * attention_score
		var mat := _score_indicator.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(red, green, 0.2, 1.0)

# ---------- API ----------

func set_attention_score(score: float) -> void:
	attention_score = clamp(score, 0.0, 1.0)

func set_focus_intensity(intensity: float) -> void:
	focus_intensity = clamp(intensity, 0.0, 1.0)

func get_attention_score() -> float:
	return attention_score

func get_focus_intensity() -> float:
	return focus_intensity

func reset_attention() -> void:
	time = 0.0
	attention_score = 0.0
	focus_intensity = 0.0

func _set_token_count(v: int) -> void:
	token_count = max(1, v)
	_create_input_tokens()
	_create_output_tokens()
	_create_attention_matrix_multimesh()
	_create_weight_lines_multimesh()
	_create_focus_indicators()

# ---------- UTIL ----------

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()
