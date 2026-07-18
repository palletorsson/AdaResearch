# FTC Bridge — the Fundamental Theorem of Calculus made spatial
#
# An arched bridge structure. On the left pillar: a derivative curve. On the right pillar:
# the original function. Across the arch span runs a thick beam labeled with the FTC
# statement: ∫ f'(x) dx = f(b) − f(a). A glowing pulse runs along the arch from left to
# right repeatedly, naming both endpoints in turn.
#
# This is the *capstone* of the change sequence — the unifying claim that derivative and
# integral are inverse operations. Sets up the entire QFEP rate-term Δ(S,t).
#
# @qfep_term: F at the boundary, pointing at Δ(S,t) as the bridge.
#
# @identity
# essence: an arched bridge with a derivative curve on the left pillar and its antiderivative on the right, a pulse running the span under the beam ∫f'(x)dx = f(b)−f(a)
# desire: to stage the Fundamental Theorem of Calculus as a spatial crossing — the two directions of change meeting over one arch
# critical_parameter: pulse_speed — the pace of the endpoint-naming pulse; it walks the eye from f(a) to f(b) and back at whatever tempo you set
# triggers: _ready() builds pillars, arch, pulse marker, and the FTC label; _process runs the pulse from the left endpoint to the right, naming both in turn
# emerges: derivative and integral shown as inverse operations — the capstone that unifies the whole change sequence
# needs: two pillars + arch [present]; running pulse marker [present]; FTC label [present]; class_name FTCBridge [present]; @identity [present, 2026-07-12]
# relationships: the synthesis of partial_derivative_terrain (slope) and riemann_pump (accumulation); points forward to QFEP's rate-term Δ(S,t); capstone of the change sequence
# truth: differentiation and integration are the same bridge walked in opposite directions — to accumulate a rate is to recover the thing that was changing.

extends Node3D
class_name FTCBridge

@export_category("Bridge Settings")
@export var pillar_color: Color = Color(0.5, 0.55, 0.7, 1.0)
@export var arch_color: Color = Color(0.95, 0.8, 0.45, 1.0)
@export var pulse_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var bridge_span: float = 3.0
@export var pillar_height: float = 1.6
@export var arch_segments: int = 24
@export var pulse_speed: float = 0.4

var _pulse_marker: MeshInstance3D
var _arch_segments_nodes: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_pillars()
	_build_arch()
	_build_pulse()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("bridge_span"):
		bridge_span = float(config_data["bridge_span"])
	if config_data.has("pillar_height"):
		pillar_height = float(config_data["pillar_height"])


func _process(delta: float) -> void:
	_t += delta * pulse_speed
	_update_pulse()


func _build_pillars() -> void:
	var offsets: Array[float] = [-bridge_span * 0.5, bridge_span * 0.5]
	for x_off in offsets:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, pillar_height, 0.25)
		pillar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = pillar_color
		mat.roughness = 0.6
		pillar.material_override = mat
		pillar.position = Vector3(x_off, pillar_height * 0.5, 0.0)
		add_child(pillar)


func _arch_point(t_norm: float) -> Vector3:
	# Parabolic arch from left pillar top to right pillar top.
	var x: float = lerp(-bridge_span * 0.5, bridge_span * 0.5, t_norm)
	var arch_h: float = 0.7
	var y: float = pillar_height + arch_h * (1.0 - pow(2.0 * t_norm - 1.0, 2.0))
	return Vector3(x, y, 0.0)


func _build_arch() -> void:
	# A series of small box segments approximating the arch.
	for i in arch_segments:
		var t0: float = float(i) / float(arch_segments)
		var t1: float = float(i + 1) / float(arch_segments)
		var p0 := _arch_point(t0)
		var p1 := _arch_point(t1)
		var center := (p0 + p1) * 0.5
		var length := (p1 - p0).length()
		var dir := (p1 - p0).normalized()
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.18, 0.18, length)
		seg.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = arch_color
		mat.emission_enabled = true
		mat.emission = arch_color
		mat.emission_energy_multiplier = 0.6
		seg.material_override = mat
		seg.position = center
		seg.transform.basis = Basis.looking_at(dir, Vector3.UP)
		add_child(seg)
		_arch_segments_nodes.append(seg)


func _build_pulse() -> void:
	_pulse_marker = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	_pulse_marker.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pulse_color
	mat.emission_enabled = true
	mat.emission = pulse_color
	mat.emission_energy_multiplier = 2.5
	_pulse_marker.material_override = mat
	add_child(_pulse_marker)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "∫ f'(x) dx  =  f(b) − f(a)"
	label.font_size = 36
	label.outline_size = 8
	label.modulate = arch_color
	label.position = Vector3(0, pillar_height + 1.05, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	# Endpoint labels at the pillars.
	var a := Label3D.new()
	a.text = "a"
	a.font_size = 28
	a.modulate = pillar_color
	a.position = Vector3(-bridge_span * 0.5, pillar_height + 0.15, 0.3)
	a.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(a)
	var b := Label3D.new()
	b.text = "b"
	b.font_size = 28
	b.modulate = pillar_color
	b.position = Vector3(bridge_span * 0.5, pillar_height + 0.15, 0.3)
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(b)


func _update_pulse() -> void:
	# Pulse runs left → right repeatedly. fmod handles wrap.
	var t_norm: float = fmod(_t, 1.0)
	_pulse_marker.position = _arch_point(t_norm)
	# As the pulse passes each segment, light it up briefly.
	for i in _arch_segments_nodes.size():
		var node: MeshInstance3D = _arch_segments_nodes[i]
		var mat := node.material_override as StandardMaterial3D
		if not mat:
			continue
		var seg_t: float = (float(i) + 0.5) / float(arch_segments)
		var d: float = abs(t_norm - seg_t)
		var energy: float = 0.6 + max(0.0, 1.5 - d * 12.0)
		mat.emission_energy_multiplier = energy
