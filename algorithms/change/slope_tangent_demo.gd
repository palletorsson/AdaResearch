# Slope Tangent Demo — derivative as instantaneous rate of change
#
# A curve y = sin(x) rendered as a strip; a moving point traces along it; at the moving
# point, a tangent line shows the local slope = dy/dx = cos(x). The tangent is FLAT AT THE
# PEAKS and STEEPEST AT THE ZERO CROSSINGS — this line used to say the opposite, and so did
# the registry description, which is the reason the `phase` axis below exists: the marker
# swept past all four stations in eight seconds and no still ever held one of them still
# long enough to catch the doc out.
#
# This is the headline artifact for the `change` sequence (order 4.5). It introduces
# *derivative as instantaneous rate* — what the math-density sieve called the "calculus
# shadow" across forces/wavefunctions.
#
# @identity
# essence: a point traces y=sin(x) while a tangent line at that point shows the local slope dy/dx=cos(x) — steep where the curve climbs, flat at the peaks
# desire: to let the player watch instantaneous rate appear alongside the thing changing, so "slope" stops being a static line and becomes a moving fact
# critical_parameter: amplitude — controls how steep the curve gets, and how dramatically the tangent tilts
# triggers: the marker advances every frame; the tangent recomputes cos(x) at the marker's x
# emerges: the tangent reads as the curve's mood — racing up, easing flat at the crest, plunging down — the rate made visible
# needs: animated marker + live tangent [has]; numeric slope readout [missing]; grabbable marker so the player chooses where to read the slope [missing]
# relationships: headline artifact of the change sequence (order 4.5); pairs with derivative_pair (rate as a full curve) and velocity_arrow (rate as motion); the calculus shadow under forces and wavefunctions
# truth: the slope at a point is the rate of change there — and a curve carries a different rate at every point it passes through
# @qfep_term: F (the function), with the derivative as the d/dt operator into Δ.

extends Node3D
class_name SlopeTangentDemo

@export_category("Curve Settings")
@export var curve_color: Color = Color(0.6, 0.85, 1.0, 1.0)  # cyan
@export var tangent_color: Color = Color(1.0, 0.55, 0.25, 1.0)  # orange
@export var marker_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var x_range: float = TAU
@export var samples: int = 96
@export var amplitude: float = 0.6
@export var horizontal_span: float = 3.6

## --- DNA (stage 2, promoted 2026-08-04) --------------------------------------------
## phase — WHERE ON THE CURVE the slope is being read. `traverse` is the shipped marker,
##   running the whole period on _process; the other three stop it at the places where the
##   derivative says something different, and they are the only places a sine HAS. Note
##   what is deliberately absent: `zero`, `steepest` and `inflection` would be three names
##   for one point on this curve — sin''(x) = −sin(x) vanishes exactly where |cos x| is
##   maximal — so declaring them would have shipped three identical stills under three
##   different words. One value, `steepest`, holds that point.
## evidence — how much of the working stands beside the moving point. Family word, taken
##   character for character (result | trace | longhand | axiom, 34 siblings). Default is
##   `trace`, the shipped state: the rate drawn at one point and nothing else.
@export_enum("traverse", "crest", "steepest", "trough") var phase: String = "traverse"
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "trace"

const PHASES := ["traverse", "crest", "steepest", "trough"]
const EVIDENCE := ["result", "trace", "longhand", "axiom"]
# t_norm of each station. x_curve = lerp(-PI, PI, t) over the strip, so the trough sits at
# a quarter, the steepest ascent dead centre, the crest at three quarters.
const PHASE_T := {"crest": 0.75, "steepest": 0.5, "trough": 0.25}

var _curve_strip: MeshInstance3D
var _tangent_strip: MeshInstance3D
var _marker: MeshInstance3D
var _deriv_strip: MeshInstance3D
var _rise_run: MeshInstance3D
var _readout: Label3D
var _axiom: Label3D
var _t: float = 0.0


func _ready() -> void:
	_build_axes()
	_build_curve()
	_build_tangent()
	_build_marker()
	_build_evidence()


func apply_grid_config(config_data: Dictionary) -> void:
	# The three numeric knobs keep their pre-promotion behaviour EXACTLY, including the
	# part of it that is broken: they are assigned, and only `amplitude` is ever read
	# again (by the per-frame tangent update), because the strip and the axes were built
	# during _ready. Nothing rebuilds for them here, because nothing rebuilt for them
	# before, and a map that has been quietly ignoring `samples` for a year should not
	# suddenly redraw when this file is touched.
	if config_data.has("samples"):
		samples = int(config_data["samples"])
	if config_data.has("amplitude"):
		amplitude = float(config_data["amplitude"])
	if config_data.has("horizontal_span"):
		horizontal_span = float(config_data["horizontal_span"])
	# phase is read fresh every frame, so it needs no rebuild at all.
	if config_data.has("phase"):
		var p: String = str(config_data["phase"])
		if PHASES.has(p):
			phase = p
	# evidence decides which nodes exist, so it does — but only when the word validates,
	# only when it actually differs, and only after _ready has built once.
	if config_data.has("evidence"):
		var e: String = str(config_data["evidence"])
		if EVIDENCE.has(e) and e != evidence:
			evidence = e
			if is_node_ready():
				_rebuild()


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_curve_strip = null
	_tangent_strip = null
	_marker = null
	_deriv_strip = null
	_rise_run = null
	_readout = null
	_axiom = null
	_build_axes()
	_build_curve()
	_build_tangent()
	_build_marker()
	_build_evidence()


func _process(delta: float) -> void:
	_t += delta * 0.6
	if _marker == null:
		return
	_update_marker_and_tangent()


func _build_axes() -> void:
	for axis_data in [
		{"size": Vector3(horizontal_span + 0.2, 0.02, 0.02), "pos": Vector3.ZERO},
		{"size": Vector3(0.02, 2.0 * amplitude + 0.2, 0.02), "pos": Vector3(-horizontal_span * 0.5, 0.0, 0.0)},
	]:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = axis_data["size"]
		bar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.4, 0.45, 1.0)
		bar.material_override = mat
		bar.position = axis_data["pos"]
		add_child(bar)


func _build_curve() -> void:
	_curve_strip = MeshInstance3D.new()
	_curve_strip.name = "Curve"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t: float = float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t)
		var x_curve: float = lerp(-x_range * 0.5, x_range * 0.5, t)
		var y: float = sin(x_curve) * amplitude
		imm.surface_add_vertex(Vector3(x, y, 0.0))
	imm.surface_end()
	_curve_strip.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = curve_color
	mat.emission_enabled = true
	mat.emission = curve_color
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_curve_strip.material_override = mat
	add_child(_curve_strip)


func _build_tangent() -> void:
	# `result` withholds the rate entirely — the thing changing, without the thing that
	# says how fast. `axiom` withholds the drawing and states the derivative instead.
	if evidence == "result" or evidence == "axiom":
		return
	_tangent_strip = MeshInstance3D.new()
	_tangent_strip.name = "TangentLine"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tangent_color
	mat.emission_enabled = true
	mat.emission = tangent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tangent_strip.material_override = mat
	add_child(_tangent_strip)


func _build_marker() -> void:
	_marker = MeshInstance3D.new()
	_marker.name = "Marker"
	var s := SphereMesh.new()
	s.radius = 0.06
	s.height = 0.12
	_marker.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.emission_enabled = true
	mat.emission = marker_color
	mat.emission_energy_multiplier = 1.2
	_marker.material_override = mat
	add_child(_marker)


# The evidence tiers above `trace`. Nothing here runs at the shipped default.
func _build_evidence() -> void:
	if evidence == "axiom":
		# The claim stated instead of drawn: the textbook line, with no tangent under it.
		_axiom = _plot_label(Color(1.0, 0.72, 0.45, 1.0))
		_axiom.text = "d/dx  sin x  =  cos x"
		_axiom.position = Vector3(0.0, amplitude + 0.42, 0.0)
		add_child(_axiom)
		return
	if evidence != "longhand":
		return
	# The whole derivative, drawn: cos over the same strip, dimmer than the tangent it
	# explains. Every point of this curve is the slope the tangent is showing at that x.
	_deriv_strip = MeshInstance3D.new()
	_deriv_strip.name = "DerivativeCurve"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t: float = float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t)
		var x_curve: float = lerp(-x_range * 0.5, x_range * 0.5, t)
		var dy: float = cos(x_curve) * amplitude
		imm.surface_add_vertex(Vector3(x, dy, 0.0))
	imm.surface_end()
	_deriv_strip.mesh = imm
	_deriv_strip.material_override = _line_mat(Color(tangent_color.r, tangent_color.g, tangent_color.b, 1.0), 0.7)
	add_child(_deriv_strip)
	# The slope as arithmetic — run and rise, rebuilt with the marker.
	_rise_run = MeshInstance3D.new()
	_rise_run.name = "RiseRun"
	_rise_run.material_override = _line_mat(Color(0.85, 0.85, 0.9, 1.0), 0.8)
	add_child(_rise_run)
	# The numeric readout the @identity has listed as missing since this file was written.
	_readout = _plot_label(Color(1.0, 0.72, 0.45, 1.0))
	add_child(_readout)


func _line_mat(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _plot_label(c: Color) -> Label3D:
	var l := Label3D.new()
	l.font_size = 40
	l.pixel_size = 0.0016
	l.modulate = c
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l


func _update_marker_and_tangent() -> void:
	# Animate the marker along the curve — unless a station has been named, in which case
	# it stands at that one place and the still can be read.
	var t_norm: float = fmod(_t * 0.2, 1.0)
	if phase != "traverse":
		t_norm = float(PHASE_T.get(phase, t_norm))
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
	var x_curve: float = lerp(-x_range * 0.5, x_range * 0.5, t_norm)
	var y: float = sin(x_curve) * amplitude
	var slope: float = cos(x_curve) * amplitude  # dy/dx = cos(x) * amplitude (in curve units)
	# Map slope back into display coords.
	var dx_display: float = horizontal_span / x_range
	var slope_display: float = slope / dx_display
	_marker.position = Vector3(x, y, 0.0)
	if _tangent_strip == null:
		return
	# Build tangent as a line in immediate mesh.
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var half_len := 0.55
	var p0 := Vector3(x - half_len, y - slope_display * half_len, 0.0)
	var p1 := Vector3(x + half_len, y + slope_display * half_len, 0.0)
	imm.surface_add_vertex(p0)
	imm.surface_add_vertex(p1)
	imm.surface_end()
	_tangent_strip.mesh = imm
	if _rise_run != null:
		# The same slope as arithmetic: run out to p1's x, then rise to p1.
		var tri := ImmediateMesh.new()
		tri.clear_surfaces()
		tri.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		tri.surface_add_vertex(p0)
		tri.surface_add_vertex(Vector3(p1.x, p0.y, 0.0))
		tri.surface_add_vertex(p1)
		tri.surface_end()
		_rise_run.mesh = tri
	if _readout != null:
		_readout.text = "dy/dx = %+.2f" % slope_display
		_readout.position = Vector3(x, y + 0.3, 0.0)
