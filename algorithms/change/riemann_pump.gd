# Riemann Pump — left, right, midpoint sums as accumulation strategies
#
# Three side-by-side strip displays of the same curve f(x) = (1 - cos(x))/2 over [0, π].
# All three accumulate vertical rectangles toward the total area, but each picks the
# rectangle's height differently:
#   - Left panel:   height = f(left edge of strip)
#   - Right panel:  height = f(right edge of strip)
#   - Mid panel:    height = f(midpoint of strip)
#
# Pumping the bar count up and down shows how all three converge to the same area as
# the partition becomes finer — but the *biases* differ at coarse resolution. This is
# the difference between a sum and an integral made visible.
#
# @identity: First map where the player sees that accumulation has a choice of strategy.
# @qfep_term: F at the cusp of Δ — accumulation as the inverse operation of slope.

extends Node3D
class_name RiemannPump

@export_category("Riemann Settings")
@export var left_color: Color = Color(0.95, 0.55, 0.55, 0.7)
@export var right_color: Color = Color(0.55, 0.95, 0.55, 0.7)
@export var mid_color: Color = Color(0.55, 0.65, 0.95, 0.7)
@export var curve_color: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var n_strips: int = 12
@export var panel_width: float = 1.4
@export var panel_height: float = 0.7
@export var panel_gap: float = 0.25
@export var pump_period: float = 6.0  # seconds for one slow cycle

var _t: float = 0.0
var _strip_parents := []  # [left_node, right_node, mid_node]
var _curve_parents := []  # the curve strips for each panel


func _ready() -> void:
	for i in 3:
		var parent := Node3D.new()
		var x_off: float = (float(i) - 1.0) * (panel_width + panel_gap)
		parent.position = Vector3(x_off, 0.0, 0.0)
		add_child(parent)
		_strip_parents.append(parent)
		_build_axes_for(parent)
		var curve := _build_curve_for(parent)
		_curve_parents.append(curve)
	_rebuild_strips(n_strips)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("n_strips"):
		n_strips = int(config_data["n_strips"])
		_rebuild_strips(n_strips)


func _process(delta: float) -> void:
	_t += delta
	# Animate n_strips between 4 and 32 with a slow sine.
	var phase: float = (sin(_t * TAU / pump_period) + 1.0) * 0.5
	var target: int = int(round(lerp(4.0, 32.0, phase)))
	if target != n_strips:
		n_strips = target
		_rebuild_strips(n_strips)


func _f(x: float) -> float:
	# x in [0, PI]; output in [0, panel_height].
	return (1.0 - cos(x)) * 0.5 * panel_height


func _build_axes_for(parent: Node3D) -> void:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_width, 0.015, 0.015)
	bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4, 1.0)
	bar.material_override = mat
	parent.add_child(bar)


func _build_curve_for(parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := 64
	for i in n + 1:
		var t_norm := float(i) / float(n)
		var x_panel: float = lerp(-panel_width * 0.5, panel_width * 0.5, t_norm)
		var x_fn: float = lerp(0.0, PI, t_norm)
		imm.surface_add_vertex(Vector3(x_panel, _f(x_fn), 0.0))
	imm.surface_end()
	mi.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = curve_color
	mat.emission_enabled = true
	mat.emission = curve_color
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _rebuild_strips(n: int) -> void:
	# Remove old strips (anything named "_strip_..." in each parent).
	for i in 3:
		var parent: Node3D = _strip_parents[i]
		for child in parent.get_children():
			if child.name.begins_with("_strip_"):
				child.queue_free()
		_emit_strips(parent, i, n)


func _emit_strips(parent: Node3D, panel_idx: int, n: int) -> void:
	var strip_width: float = panel_width / float(n)
	for k in n:
		var t0: float = float(k) / float(n)
		var t1: float = float(k + 1) / float(n)
		var sample_t: float = t0
		match panel_idx:
			0: sample_t = t0  # left
			1: sample_t = t1  # right
			2: sample_t = (t0 + t1) * 0.5  # midpoint
		var x_fn: float = sample_t * PI
		var height: float = _f(x_fn)
		var strip := MeshInstance3D.new()
		strip.name = "_strip_" + str(k)
		var box := BoxMesh.new()
		box.size = Vector3(strip_width * 0.95, max(height, 0.001), 0.02)
		strip.mesh = box
		var mat := StandardMaterial3D.new()
		var col: Color = [left_color, right_color, mid_color][panel_idx]
		mat.albedo_color = col
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.5
		strip.material_override = mat
		var x_panel: float = lerp(-panel_width * 0.5, panel_width * 0.5, (t0 + t1) * 0.5)
		strip.position = Vector3(x_panel, height * 0.5, -0.01)
		parent.add_child(strip)
