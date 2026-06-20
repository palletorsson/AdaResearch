# Derivative Pair — a function and its derivative side-by-side
#
# Two stacked curve panels. Top: y = f(x). Bottom: y = f'(x). A shared vertical sweep line
# scrubs across both, showing that wherever f rises steeply, f' is positive; where f peaks,
# f' crosses zero; where f drops, f' is negative.
#
# Provides the *intuition* that derivative is not just a number at a point but a *function*
# in its own right. The shape of the rate is the shape of the change.
#
# @identity
# essence: two stacked panels, f(x) above and f'(x) below, scrubbed by one shared sweep line — the derivative shown as a curve, not a number
# desire: to make the player feel that the rate of change has its own shape — steep f means high f', a peak in f means f' crosses zero
# critical_parameter: amplitude — sets how dramatic the function's curvature is, and therefore how legible the derivative's swing
# triggers: the sweep line advances every frame (sweep_speed), re-reading f and f' at the moving x
# emerges: the player reads two curves as one statement — where the top rises steeply the bottom rides high, where the top peaks the bottom crosses zero
# needs: animated sweep + dual curves [has]; live numeric readout of f(x) and f'(x) [missing]; grabbable sweep line so the player scrubs by hand [missing]
# relationships: pairs with slope_tangent_demo (rate at a single point) and integral_area (the inverse operation); headline cluster of the change sequence
# truth: the derivative is not a number at a point — it is a function in its own right, and the shape of the rate is the shape of the change
# @qfep_term: F (the function), pointing forward to the d/dt operator.

extends Node3D
class_name DerivativePair

@export_category("Pair Settings")
@export var fn_color: Color = Color(0.55, 0.85, 1.0, 1.0)
@export var deriv_color: Color = Color(1.0, 0.55, 0.25, 1.0)
@export var sweep_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var samples: int = 96
@export var horizontal_span: float = 3.2
@export var amplitude: float = 0.5
@export var panel_gap: float = 0.9
@export var sweep_speed: float = 0.22

var _fn_strip: MeshInstance3D
var _deriv_strip: MeshInstance3D
var _fn_marker: MeshInstance3D
var _deriv_marker: MeshInstance3D
var _sweep_line: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_axes()
	_build_curves()
	_build_markers()
	_build_sweep_line()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("samples"):
		samples = int(config_data["samples"])
	if config_data.has("amplitude"):
		amplitude = float(config_data["amplitude"])


func _process(delta: float) -> void:
	_t += delta * sweep_speed
	var sweep_norm: float = fmod(_t, 1.0)
	_update_sweep(sweep_norm)


func _f(x: float) -> float:
	# A wavy curve so the derivative is dramatic.
	return sin(x) * amplitude + sin(x * 2.0) * amplitude * 0.35


func _df(x: float) -> float:
	# d/dx of f(x)
	return cos(x) * amplitude + cos(x * 2.0) * amplitude * 0.7


func _build_axes() -> void:
	for y_off in [panel_gap * 0.5, -panel_gap * 0.5]:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(horizontal_span + 0.2, 0.02, 0.02)
		bar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.4, 0.45, 1.0)
		bar.material_override = mat
		bar.position.y = y_off
		add_child(bar)


func _build_curves() -> void:
	_fn_strip = _make_curve_strip(true, fn_color, panel_gap * 0.5)
	_deriv_strip = _make_curve_strip(false, deriv_color, -panel_gap * 0.5)
	add_child(_fn_strip)
	add_child(_deriv_strip)


func _make_curve_strip(use_f: bool, color: Color, y_offset: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t_norm := float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
		var curve_x: float = lerp(-TAU, TAU, t_norm)
		var y: float = (_f(curve_x) if use_f else _df(curve_x)) * 0.4 + y_offset
		imm.surface_add_vertex(Vector3(x, y, 0.0))
	imm.surface_end()
	mi.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	return mi


func _build_markers() -> void:
	_fn_marker = _make_marker(fn_color)
	_deriv_marker = _make_marker(deriv_color)
	add_child(_fn_marker)
	add_child(_deriv_marker)


func _make_marker(c: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.07
	s.height = 0.14
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 1.6
	m.material_override = mat
	return m


func _build_sweep_line() -> void:
	_sweep_line = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.02, panel_gap + 0.6, 0.02)
	_sweep_line.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = sweep_color
	mat.emission_enabled = true
	mat.emission = sweep_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sweep_line.material_override = mat
	add_child(_sweep_line)


func _update_sweep(sweep_norm: float) -> void:
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, sweep_norm)
	var curve_x: float = lerp(-TAU, TAU, sweep_norm)
	_fn_marker.position = Vector3(x, _f(curve_x) * 0.4 + panel_gap * 0.5, 0.0)
	_deriv_marker.position = Vector3(x, _df(curve_x) * 0.4 - panel_gap * 0.5, 0.0)
	_sweep_line.position = Vector3(x, 0.0, 0.0)
