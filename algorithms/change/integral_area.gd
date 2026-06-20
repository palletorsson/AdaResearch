# Integral Area — area under a curve as integration
#
# A curve y = max(0, sin(x)) (rectified for visual area) renders as a strip.
# Beneath it, the area is painted progressively as a series of vertical strips that
# accumulate left-to-right — this IS the definite integral, animated.
#
# Pairs with `riemann_pump` (left/right/midpoint sums) and `slope_tangent_demo` (derivative).
# Together they say: derivative is the rate, integral is the accumulation, both live at change.
#
# @identity
# essence: vertical strips fill the area under y=max(0,sin(x)) left to right — the definite integral painted as it accumulates
# desire: to make accumulation felt as a growing quantity, the mirror image of the derivative's instantaneous rate
# critical_parameter: samples — the number of strips, the discretisation between coarse Riemann blocks and a smooth filled area
# triggers: the sweep advances every frame (sweep_speed), revealing one more strip of accumulated area
# emerges: the filled region reads as a single number growing — the player sees "how much has happened so far" rather than "how fast"
# needs: animated area fill + sweep marker [has]; running numeric area total [missing]; grabbable sweep so the player sets the integral's upper limit [missing]
# relationships: pairs with riemann_pump (left/right/midpoint sums) and slope_tangent_demo (the inverse, derivative); the accumulation half of the change sequence
# truth: the integral is accumulation — where the derivative asks how fast, the integral asks how much has gathered under the curve
# @qfep_term: F at accumulation — pointing forward to φΔE(S,t).

extends Node3D
class_name IntegralArea

@export_category("Integral Settings")
@export var curve_color: Color = Color(0.6, 0.85, 1.0, 1.0)
@export var area_color: Color = Color(0.35, 0.7, 0.95, 0.4)
@export var sweep_color: Color = Color(1.0, 0.9, 0.3, 1.0)
@export var samples: int = 80
@export var horizontal_span: float = 3.6
@export var amplitude: float = 0.7
@export var sweep_speed: float = 0.18

var _strip_nodes: Array = []
var _curve_strip: MeshInstance3D
var _sweep_marker: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_axes()
	_build_curve()
	_build_area_strips()
	_build_sweep_marker()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("samples"):
		samples = int(config_data["samples"])
	if config_data.has("horizontal_span"):
		horizontal_span = float(config_data["horizontal_span"])
	if config_data.has("amplitude"):
		amplitude = float(config_data["amplitude"])


func _process(delta: float) -> void:
	_t += delta * sweep_speed
	var sweep_norm: float = fmod(_t, 1.0)
	_update_strips(sweep_norm)
	_update_sweep_marker(sweep_norm)


func _build_axes() -> void:
	var floor_bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(horizontal_span + 0.2, 0.02, 0.02)
	floor_bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4, 1.0)
	floor_bar.material_override = mat
	add_child(floor_bar)


func _build_curve() -> void:
	_curve_strip = MeshInstance3D.new()
	_curve_strip.name = "Curve"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t_norm := float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
		var y: float = max(0.0, sin(t_norm * PI)) * amplitude
		imm.surface_add_vertex(Vector3(x, y, 0.0))
	imm.surface_end()
	_curve_strip.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = curve_color
	mat.emission_enabled = true
	mat.emission = curve_color
	mat.emission_energy_multiplier = 1.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_curve_strip.material_override = mat
	add_child(_curve_strip)


func _build_area_strips() -> void:
	# Each strip is a vertical rectangle of width = horizontal_span/samples.
	var strip_width: float = horizontal_span / float(samples)
	for i in samples:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		var t_norm := (float(i) + 0.5) / float(samples)
		var height: float = max(0.0, sin(t_norm * PI)) * amplitude
		box.size = Vector3(strip_width * 0.95, max(height, 0.001), 0.02)
		strip.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = area_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = area_color
		mat.emission_energy_multiplier = 0.0  # invisible until swept
		strip.material_override = mat
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
		strip.position = Vector3(x, height * 0.5, -0.01)
		add_child(strip)
		_strip_nodes.append(strip)


func _build_sweep_marker() -> void:
	_sweep_marker = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.03, amplitude + 0.1, 0.05)
	_sweep_marker.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = sweep_color
	mat.emission_enabled = true
	mat.emission = sweep_color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sweep_marker.material_override = mat
	add_child(_sweep_marker)


func _update_strips(sweep_norm: float) -> void:
	var threshold_idx: int = int(sweep_norm * float(samples))
	for i in _strip_nodes.size():
		var strip: MeshInstance3D = _strip_nodes[i]
		var mat := strip.material_override as StandardMaterial3D
		if not mat:
			continue
		if i <= threshold_idx:
			mat.emission_energy_multiplier = 0.7
			mat.albedo_color = Color(area_color.r, area_color.g, area_color.b, 0.7)
		else:
			mat.emission_energy_multiplier = 0.0
			mat.albedo_color = Color(area_color.r, area_color.g, area_color.b, 0.05)


func _update_sweep_marker(sweep_norm: float) -> void:
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, sweep_norm)
	_sweep_marker.position = Vector3(x, amplitude * 0.5, 0.0)
