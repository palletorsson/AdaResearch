# Slope Tangent Demo — derivative as instantaneous rate of change
#
# A curve y = sin(x) rendered as a strip; a moving point traces along it; at the moving
# point, a tangent line shows the local slope = dy/dx = cos(x). When the slope is steep
# the tangent line lifts/dips fast; at zero crossings the tangent is flat.
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

var _curve_strip: MeshInstance3D
var _tangent_strip: MeshInstance3D
var _marker: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_axes()
	_build_curve()
	_build_tangent()
	_build_marker()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("samples"):
		samples = int(config_data["samples"])
	if config_data.has("amplitude"):
		amplitude = float(config_data["amplitude"])
	if config_data.has("horizontal_span"):
		horizontal_span = float(config_data["horizontal_span"])


func _process(delta: float) -> void:
	_t += delta * 0.6
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


func _update_marker_and_tangent() -> void:
	# Animate the marker along the curve.
	var t_norm: float = fmod(_t * 0.2, 1.0)
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
	var x_curve: float = lerp(-x_range * 0.5, x_range * 0.5, t_norm)
	var y: float = sin(x_curve) * amplitude
	var slope: float = cos(x_curve) * amplitude  # dy/dx = cos(x) * amplitude (in curve units)
	# Map slope back into display coords.
	var dx_display: float = horizontal_span / x_range
	var slope_display: float = slope / dx_display
	_marker.position = Vector3(x, y, 0.0)
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
