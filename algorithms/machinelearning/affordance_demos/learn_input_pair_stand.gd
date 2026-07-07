# Learn Input-Pair Stand — the `learn` catalyst affordance for machinelearning
#
# Two pillars side by side: the left labeled "input," the right "output." On a tray at
# the front, the player places input-output sample pairs (each represented as a colored
# token). A glowing thread connects each input token to its paired output token, with
# the threads colored by their similarity. The bracelet "learns" the mapping over time —
# a moving glyph above the tray slowly drifts from random noise toward the mean output
# of the placed pairs.
#
# This is the ML affordance: the bracelet doesn't just place objects, it *fits* a
# mapping. Foreshadows gradient descent: the glyph is a parameter point converging on
# the data's gravity.
#
# @identity: First map where the player teaches the bracelet a relation.
# @qfep_term: Integration (settling toward a target).

extends Node3D
class_name LearnInputPairStand

@export_category("Stand Settings")
@export var input_color: Color = Color(0.6, 0.85, 1.0, 1.0)
@export var output_color: Color = Color(0.95, 0.55, 0.4, 1.0)
@export var connection_color: Color = Color(0.9, 0.9, 0.5, 1.0)
@export var glyph_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var n_pairs: int = 5
@export var pillar_spacing: float = 1.4
@export var learn_rate: float = 0.06

# Each pair: input_value, output_value (both Vector3 for demo).
var _input_tokens: Array = []
var _output_tokens: Array = []
var _glyph: MeshInstance3D
var _glyph_position: Vector3
var _t: float = 0.0


func _ready() -> void:
	_build_pillars()
	_build_pairs()
	_build_glyph()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("n_pairs"):
		n_pairs = int(config_data["n_pairs"])
	if config_data.has("learn_rate"):
		learn_rate = float(config_data["learn_rate"])


func _process(delta: float) -> void:
	_t += delta
	_learn_step(delta)
	_redraw_connections()


func _build_pillars() -> void:
	for x_off in [-pillar_spacing * 0.5, pillar_spacing * 0.5]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.2, 1.5, 0.2)
		pillar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.4, 0.5, 1.0)
		mat.roughness = 0.7
		pillar.material_override = mat
		pillar.position = Vector3(x_off, 0.75, 0.0)
		add_child(pillar)
	# Pillar labels.
	var label_in := Label3D.new()
	label_in.text = "input"
	label_in.font_size = 30
	label_in.modulate = input_color
	label_in.position = Vector3(-pillar_spacing * 0.5, 1.65, 0.0)
	label_in.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label_in)
	var label_out := Label3D.new()
	label_out.text = "output"
	label_out.font_size = 30
	label_out.modulate = output_color
	label_out.position = Vector3(pillar_spacing * 0.5, 1.65, 0.0)
	label_out.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label_out)


func _build_pairs() -> void:
	for i in n_pairs:
		var t_norm: float = float(i) / float(max(1, n_pairs - 1))
		var y: float = 0.4 + t_norm * 0.9
		var in_token := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.08
		s.height = 0.16
		in_token.mesh = s
		var mat_in := StandardMaterial3D.new()
		mat_in.albedo_color = input_color
		mat_in.emission_enabled = true
		mat_in.emission = input_color
		mat_in.emission_energy_multiplier = 1.5
		in_token.material_override = mat_in
		in_token.position = Vector3(-pillar_spacing * 0.5 - 0.18, y, 0.0)
		add_child(in_token)
		_input_tokens.append(in_token)

		var out_token := MeshInstance3D.new()
		out_token.mesh = s
		var mat_out := StandardMaterial3D.new()
		mat_out.albedo_color = output_color
		mat_out.emission_enabled = true
		mat_out.emission = output_color
		mat_out.emission_energy_multiplier = 1.5
		out_token.material_override = mat_out
		# Outputs scatter slightly to create something the bracelet can learn the mean of.
		out_token.position = Vector3(pillar_spacing * 0.5 + 0.18, y + sin(t_norm * 6.0) * 0.15, sin(t_norm * 9.0) * 0.1)
		add_child(out_token)
		_output_tokens.append(out_token)


func _build_glyph() -> void:
	_glyph = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.11
	s.height = 0.22
	_glyph.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glyph_color
	mat.emission_enabled = true
	mat.emission = glyph_color
	mat.emission_energy_multiplier = 2.0
	_glyph.material_override = mat
	_glyph_position = Vector3(0.0, 1.85, 0.5)  # starts near average input pile, will drift
	_glyph.position = _glyph_position
	add_child(_glyph)


func _mean_output() -> Vector3:
	if _output_tokens.is_empty():
		return Vector3.ZERO
	var sum := Vector3.ZERO
	for t in _output_tokens:
		sum += (t as MeshInstance3D).position
	return sum / float(_output_tokens.size())


func _learn_step(delta: float) -> void:
	# Glyph descends toward the mean output position — gradient-descent-flavored animation.
	var target := _mean_output() + Vector3(0, 0.4, 0)
	_glyph_position = _glyph_position.lerp(target, clamp(learn_rate * delta * 30.0, 0.0, 1.0))
	# A small jitter to suggest noise in the learning step.
	_glyph_position += Vector3(sin(_t * 5.0) * 0.005, cos(_t * 6.0) * 0.005, sin(_t * 4.0) * 0.005)
	_glyph.position = _glyph_position


func _redraw_connections() -> void:
	# Remove old connection lines.
	for child in get_children():
		if child.name.begins_with("_conn_"):
			child.queue_free()
	for i in min(_input_tokens.size(), _output_tokens.size()):
		var in_p: Vector3 = (_input_tokens[i] as MeshInstance3D).position
		var out_p: Vector3 = (_output_tokens[i] as MeshInstance3D).position
		var line := MeshInstance3D.new()
		line.name = "_conn_" + str(i)
		var imm := ImmediateMesh.new()
		imm.clear_surfaces()
		imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		imm.surface_add_vertex(in_p)
		imm.surface_add_vertex(out_p)
		imm.surface_end()
		line.mesh = imm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = connection_color
		mat.emission_enabled = true
		mat.emission = connection_color
		mat.emission_energy_multiplier = 0.9
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line.material_override = mat
		add_child(line)
