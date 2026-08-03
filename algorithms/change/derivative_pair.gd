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
# critical_parameter: curve — which f is on the table, and therefore what its rate has to say
# triggers: the sweep line advances every frame (sweep_speed), re-reading f and f' at the moving x
# emerges: the player reads two curves as one statement — where the top rises steeply the bottom rides high, where the top peaks the bottom crosses zero
# needs: animated sweep + dual curves [has]; a choice of f [has]; live numeric readout of f(x) and f'(x) [missing]; grabbable sweep line so the player scrubs by hand [missing]
# relationships: pairs with slope_tangent_demo (rate at a single point) and integral_area (the inverse operation, sharing the `curve` axis word for word); headline cluster of the change sequence
# truth: the derivative is not a number at a point — it is a function in its own right, and the shape of the rate is the shape of the change
# @qfep_term: F (the function), pointing forward to the d/dt operator.

extends Node3D
class_name DerivativePair

# ── the curve axis ─────────────────────────────────────────────────────
# The artifact's whole sentence is "the shape of the rate is the shape of the
# change", and until now there was exactly one shape. `_f` was a private method
# holding a compound sine, so every one of this artifact's rooms made the claim
# about a single wiggly line and no player could ever see the claim tested.
#
# Five functions, chosen because their DERIVATIVES are five different arguments:
#   wave   sin(x) + 0.35 sin(2x) — the shipped curve. Busy: f' swings hard and
#          crosses zero four times, one crossing per turning point.
#   hump   one arch over the whole span. Gentle everywhere, so f' is a small
#          slow sine — a slow change really does have a small rate, and seeing
#          that at the SAME vertical scale as `step` is the lesson, not a fault.
#   ramp   a straight line. f' is a horizontal line: constant rate, the flattest
#          statement calculus makes and the one hardest to picture from words.
#   spike  a narrow bell. Almost all of the change happens in a tenth of the
#          span, and f' is the classic up-then-down pair of lobes.
#   step   a smoothed step (atan, so it is differentiable). f' is a single tall
#          pulse: the rate concentrates where the value jumps.
# integral_area carries this same axis with these same five values, so the two
# halves of the change cluster can be compared instead of merely contrasted.
const CURVES: PackedStringArray = ["wave", "hump", "ramp", "spike", "step"]

# ── the panels axis ────────────────────────────────────────────────────
# HOW the pair is put in front of you, which is the claim about what a
# derivative IS.
#   stacked   two panels, f above, f' below, one shared sweep. The shipped
#             arrangement: f' has its own axis, its own room — a function.
#   overlaid  both curves on one axis. Now they are commensurable and you read
#             the zero-crossings directly against the peaks, at the cost of the
#             separation that made f' look like a thing in its own right.
#   tower     three panels: f, f', f''. Differentiation is an operator you can
#             apply again, and again the answer is a curve.
#   phase     no x axis at all — the curve is plotted as (f, f'), the phase
#             portrait. The derivative stops being a graph and becomes a
#             coordinate; a closed loop means the motion repeats.
const PANELS: PackedStringArray = ["stacked", "overlaid", "tower", "phase"]

@export_category("Pair Settings")
## Stage-2 DNA axis — which function is on the table. Shared, word for word, with integral_area.
@export_enum("wave", "hump", "ramp", "spike", "step") var curve: String = "wave"
## Stage-2 DNA axis — how f and f' are arranged, which is the claim about what a derivative is.
@export_enum("stacked", "overlaid", "tower", "phase") var panels: String = "stacked"
@export var fn_color: Color = Color(0.55, 0.85, 1.0, 1.0)
@export var deriv_color: Color = Color(1.0, 0.55, 0.25, 1.0)
## Only drawn at panels=tower, where there is a second-derivative panel to colour.
@export var second_color: Color = Color(0.78, 0.5, 1.0, 1.0)
@export var sweep_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var samples: int = 96
@export var horizontal_span: float = 3.2
@export var amplitude: float = 0.5
@export var panel_gap: float = 0.9
@export var sweep_speed: float = 0.22

var _fn_strip: MeshInstance3D
var _deriv_strip: MeshInstance3D
var _second_strip: MeshInstance3D
var _fn_marker: MeshInstance3D
var _deriv_marker: MeshInstance3D
var _second_marker: MeshInstance3D
var _sweep_line: MeshInstance3D
var _t: float = 0.0

## Panel baselines, set by the build so _update_sweep never re-derives them.
var _fn_y: float = 0.0
var _deriv_y: float = 0.0
var _second_y: float = 0.0
## Phase-portrait fit, so any curve fills the same box.
var _phase_sx: float = 1.0
var _phase_sy: float = 1.0

## True once _ready() has built once. apply_grid_config arrives AFTER _ready(),
## and must never rebuild before there is something to rebuild.
var _built: bool = false
## Every node THIS SCRIPT parented in. A rebuild frees exactly these — never
## get_children(), which would take the grid's own furniture with it.
var _created: Array[Node] = []


func _ready() -> void:
	curve = _pick(curve, CURVES, "wave")
	panels = _pick(panels, PANELS, "stacked")
	_build_all()
	_built = true


## Map tokens and the DNA sweep both arrive here, after _ready has built once.
## Nothing rebuilds unless a value actually changed, so a placement that passes
## keys this artifact does not own (layout:, with_wall: ...) is untouched.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("curve"):
		var c: String = _pick(str(config_data["curve"]), CURVES, curve)
		if c != curve:
			curve = c
			changed = true
	if config_data.has("panels"):
		var p: String = _pick(str(config_data["panels"]), PANELS, panels)
		if p != panels:
			panels = p
			changed = true
	if config_data.has("samples"):
		var s: int = maxi(2, int(config_data["samples"]))
		if s != samples:
			samples = s
			changed = true
	if config_data.has("amplitude"):
		var a: float = float(config_data["amplitude"])
		if not is_equal_approx(a, amplitude):
			amplitude = a
			changed = true
	if changed and _built:
		_rebuild_now()


func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta * sweep_speed
	var sweep_norm: float = fmod(_t, 1.0)
	_update_sweep(sweep_norm)


# ── the curve family ───────────────────────────────────────────────────
# Everything is a function of u in [0,1], the position along the panel. Where a
# family member is more naturally written against the swept coordinate, u is
# mapped to cx in [-TAU, TAU] first — which is exactly the mapping the shipped
# build already used, so `wave` reproduces the old _f/_df line for line.

func _cx(u: float) -> float:
	return lerp(-TAU, TAU, u)


func _curve_y(u: float) -> float:
	var cx: float = _cx(u)
	match curve:
		"hump":
			return sin(u * PI) * amplitude
		"ramp":
			return amplitude * cx / TAU
		"spike":
			return amplitude * exp(-cx * cx * 0.5)
		"step":
			return amplitude * atan(cx * 2.5) * 0.6366198
		_:
			return sin(cx) * amplitude + sin(cx * 2.0) * amplitude * 0.35


## d/dcx of _curve_y — the derivative against the same swept coordinate the top
## panel is drawn in, so the two panels share one horizontal scale.
func _curve_dy(u: float) -> float:
	var cx: float = _cx(u)
	match curve:
		"hump":
			return amplitude * 0.25 * cos(u * PI)
		"ramp":
			return amplitude / TAU
		"spike":
			return -amplitude * cx * exp(-cx * cx * 0.5)
		"step":
			return amplitude * 0.6366198 * 2.5 / (1.0 + 6.25 * cx * cx)
		_:
			return cos(cx) * amplitude + cos(cx * 2.0) * amplitude * 0.7


## d2/dcx2 of _curve_y. Only the tower needs it.
func _curve_ddy(u: float) -> float:
	var cx: float = _cx(u)
	match curve:
		"hump":
			return -amplitude * 0.0625 * sin(u * PI)
		"ramp":
			return 0.0
		"spike":
			return amplitude * (cx * cx - 1.0) * exp(-cx * cx * 0.5)
		"step":
			var d: float = 1.0 + 6.25 * cx * cx
			return -amplitude * 0.6366198 * 2.5 * 12.5 * cx / (d * d)
		_:
			return -sin(cx) * amplitude - sin(cx * 2.0) * amplitude * 1.4


func _sample(order: int, u: float) -> float:
	if order == 1:
		return _curve_dy(u)
	if order == 2:
		return _curve_ddy(u)
	return _curve_y(u)


# ── build ──────────────────────────────────────────────────────────────

func _build_all() -> void:
	_fn_strip = null
	_deriv_strip = null
	_second_strip = null
	_fn_marker = null
	_deriv_marker = null
	_second_marker = null
	_sweep_line = null
	match panels:
		"overlaid":
			_fn_y = 0.0
			_deriv_y = 0.0
			_second_y = 0.0
		"tower":
			_fn_y = panel_gap
			_deriv_y = 0.0
			_second_y = -panel_gap
		_:
			_fn_y = panel_gap * 0.5
			_deriv_y = -panel_gap * 0.5
			_second_y = 0.0
	if panels == "phase":
		_build_phase()
		return
	_build_axes()
	_build_curves()
	_build_markers()
	_build_sweep_line()


func _build_axes() -> void:
	if panels == "overlaid":
		_axis_bar(0.0)
	elif panels == "tower":
		_axis_bar(_fn_y)
		_axis_bar(_deriv_y)
		_axis_bar(_second_y)
	else:
		_axis_bar(panel_gap * 0.5)
		_axis_bar(-panel_gap * 0.5)


func _axis_bar(y_off: float) -> void:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(horizontal_span + 0.2, 0.02, 0.02)
	bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.45, 1.0)
	bar.material_override = mat
	bar.position.y = y_off
	_own(bar)


func _build_curves() -> void:
	_fn_strip = _make_curve_strip(0, fn_color, _fn_y)
	_deriv_strip = _make_curve_strip(1, deriv_color, _deriv_y)
	_own(_fn_strip)
	_own(_deriv_strip)
	if panels == "tower":
		_second_strip = _make_curve_strip(2, second_color, _second_y)
		_own(_second_strip)


func _make_curve_strip(order: int, color: Color, y_offset: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t_norm := float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
		var y: float = _sample(order, t_norm) * 0.4 + y_offset
		imm.surface_add_vertex(Vector3(x, y, 0.0))
	imm.surface_end()
	mi.mesh = imm
	mi.material_override = _line_material(color, 1.2)
	return mi


func _line_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _build_markers() -> void:
	_fn_marker = _make_marker(fn_color)
	_deriv_marker = _make_marker(deriv_color)
	_own(_fn_marker)
	_own(_deriv_marker)
	if panels == "tower":
		_second_marker = _make_marker(second_color)
		_own(_second_marker)


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
	var height: float = panel_gap + 0.6
	if panels == "overlaid":
		height = panel_gap * 0.5 + 0.4
	elif panels == "tower":
		height = panel_gap * 2.0 + 0.6
	_sweep_line = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.02, height, 0.02)
	_sweep_line.mesh = box
	_sweep_line.material_override = _line_material(sweep_color, 1.5)
	_own(_sweep_line)


## The phase portrait: no x axis, no sweep line. The curve is the set of points
## (f, f') and the marker rides it. A closed loop means the motion repeats.
func _build_phase() -> void:
	var peak_f: float = 0.00001
	var peak_d: float = 0.00001
	for i in 241:
		var u := float(i) / 240.0
		peak_f = maxf(peak_f, absf(_curve_y(u)))
		peak_d = maxf(peak_d, absf(_curve_dy(u)))
	_phase_sx = horizontal_span * 0.42 / peak_f
	_phase_sy = panel_gap * 0.62 / peak_d
	_axis_bar(0.0)
	var upright := MeshInstance3D.new()
	var ubox := BoxMesh.new()
	ubox.size = Vector3(0.02, panel_gap * 1.4, 0.02)
	upright.mesh = ubox
	var umat := StandardMaterial3D.new()
	umat.albedo_color = Color(0.4, 0.4, 0.45, 1.0)
	upright.material_override = umat
	_own(upright)
	_fn_strip = MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t_norm := float(i) / float(samples)
		imm.surface_add_vertex(Vector3(
			_curve_y(t_norm) * _phase_sx, _curve_dy(t_norm) * _phase_sy, 0.0))
	imm.surface_end()
	_fn_strip.mesh = imm
	_fn_strip.material_override = _line_material(deriv_color, 1.2)
	_own(_fn_strip)
	_fn_marker = _make_marker(fn_color)
	_own(_fn_marker)


# ── run ────────────────────────────────────────────────────────────────

func _update_sweep(sweep_norm: float) -> void:
	if panels == "phase":
		if _fn_marker != null:
			_fn_marker.position = Vector3(
				_curve_y(sweep_norm) * _phase_sx, _curve_dy(sweep_norm) * _phase_sy, 0.0)
		return
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, sweep_norm)
	if _fn_marker != null:
		_fn_marker.position = Vector3(x, _curve_y(sweep_norm) * 0.4 + _fn_y, 0.0)
	if _deriv_marker != null:
		_deriv_marker.position = Vector3(x, _curve_dy(sweep_norm) * 0.4 + _deriv_y, 0.0)
	if _second_marker != null:
		_second_marker.position = Vector3(x, _curve_ddy(sweep_norm) * 0.4 + _second_y, 0.0)
	if _sweep_line != null:
		_sweep_line.position = Vector3(x, 0.0, 0.0)


# ── housekeeping ───────────────────────────────────────────────────────

func _own(n: Node) -> Node:
	add_child(n)
	_created.append(n)
	return n


func _rebuild_now() -> void:
	for c in _created:
		if not is_instance_valid(c):
			continue
		var p: Node = c.get_parent()
		if p != null:
			p.remove_child(c)
		c.queue_free()
	_created.clear()
	_build_all()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	return value if allowed.has(value) else fallback
