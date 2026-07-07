extends Node3D
class_name TangentSlopeWorkbench

# @identity
# essence: an interactive tangent-slope workbench — the player turns a slider for x and watches the marker slide along f(x), the tangent line rotate at the slope f'(x), and the slope readout update. At local extrema the tangent goes horizontal; the player feels the maximum/minimum as a flat moment.
# desire: learner viscerally feels the derivative as the slope of the tangent — the rate of change at a point made geometric
# critical_parameter: x — drives marker position, tangent slope, readout
# triggers: _ready() builds slider + curve + tangent line + marker + readout; _on_slider_changed recomputes f(x), f'(x), rotates the tangent line, updates the marker
# emerges: derivative as local geometry — the slope of the line through the point and (point + dx) in the limit dx → 0
# needs: slider_horizontal [present]; ImmediateMesh for tangent line [present]; Label3D for readouts [present]
# relationships: paired with /tangent-slope-gallery (web cells frozen at 8 x-positions); sibling to riemann_sum_workbench (derivative pair to integral); the two together teach the Fundamental Theorem of Calculus made geometric
# truth: the derivative is the slope of the line you would draw if you zoomed in until the curve looked straight. The slider walks the zoom.

## A horizontal workbench for the derivative as tangent slope.
##
## One slider drives x ∈ [0, 5] continuously. As you move it:
##   • the tangent point (x, f(x)) slides along the curve
##     f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x)
##   • the tangent line through that point at slope f'(x) = 0.8·cos(2x) − 0.75·sin(5x)
##     extends ±0.6 in x from the contact, rotating to match the slope
##   • a derivative curve f'(x) draws above the main plot for context, with
##     its own moving marker tracking the slope value
##   • the readout updates with f(x), f'(x), and an up/down/flat sign cue
##   • a sign indicator arrow points up (green), down (red), or flat (white)
##
## The curve floats above the table; the tangent rotates beneath the
## player's hand. At local extrema the arrow flattens and the readout
## reads "horizontal" — the geometric moment of a maximum or minimum.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
## Tilt of the slider plate toward the player.
@export var plate_tilt_deg: float = -25.0
## Plate height above the artifact origin.
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Plot")
## Where the plot sits relative to plate origin.
@export var plot_offset: Vector3 = Vector3(0.0, 1.45, -0.20)
## Horizontal span of the curve (the x-axis, x ∈ [0, 5]).
@export var plot_width: float = 1.2
## Vertical scale: f(x) ≈ 1.0 maps to roughly this height.
@export var plot_height: float = 0.5
## Sample resolution of the curve polyline.
@export var curve_samples: int = 200
@export var curve_color: Color = Color(1.0, 0.97, 0.7)
## Tangent line color — bright gold to match the gallery captures.
@export var tangent_color: Color = Color(1.0, 0.78, 0.20)
## Marker dot color — contrast red, again matching the gallery.
@export var marker_color: Color = Color(0.98, 0.32, 0.28)
@export var marker_radius: float = 0.025

@export_group("Tangent Line")
## Half-length of the tangent line, measured in x-units of the curve domain.
## At ±0.6 the line spans ~1.2 / 5 = 24% of the curve.
@export var tangent_half_span_x: float = 0.6

@export_group("Derivative Subplot")
## Show the f'(x) curve on a small subplot above the main plot.
@export var show_derivative_subplot: bool = true
## Vertical offset of the subplot above the main plot baseline.
@export var derivative_subplot_y: float = 0.78
## Height of the f'(x) subplot. f' ∈ ~[-1.55, +1.55] is normalized to this.
@export var derivative_subplot_height: float = 0.25
## Color for the f'(x) curve and its marker.
@export var derivative_color: Color = Color(0.55, 0.85, 1.0)

@export_group("Sign Indicator")
## Where the sign indicator sits relative to the artifact origin (world space, not under the tilted plate).
@export var sign_indicator_x: float = 0.85
@export var sign_indicator_height: float = 1.05

@export_group("Curve definition")
## Domain start of x.
@export var x_min: float = 0.0
## Domain end of x.
@export var x_max: float = 5.0
## Initial x position (player's first sample).
@export var initial_x: float = 1.0

# ── Internal state ────────────────────────────────────────────────────

const SLIDER_SCENE_PATH: String = "res://commons/interactables/slider_horizontal.tscn"
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

# f'(x) range on this curve is bounded by 0.8 + 0.75 = 1.55 in absolute value.
# We use a slightly larger margin so the subplot has headroom.
const DERIVATIVE_MAX_ABS: float = 1.6

var _x: float = 1.0  # current sample position

var _plate_root: Node3D
var _slider: Node               # SliderHorizontal instance
var _plate_readout: Label       # 2D-in-3D readout integrated on the console board

var _plot_root: Node3D

# Main curve (f).
var _curve_mesh_inst: MeshInstance3D
var _curve_mesh: ImmediateMesh
var _curve_material: StandardMaterial3D

# Tangent line — regenerated every slider tick.
var _tangent_mesh_inst: MeshInstance3D
var _tangent_mesh: ImmediateMesh
var _tangent_material: StandardMaterial3D

# Marker dot at (x, f(x)).
var _marker_inst: MeshInstance3D
var _marker_material: StandardMaterial3D

# Leader line: thin vertical from baseline to marker, anchors the dot.
var _marker_leader: MeshInstance3D

# Derivative subplot.
var _derivative_root: Node3D
var _derivative_curve_inst: MeshInstance3D
var _derivative_curve_mesh: ImmediateMesh
var _derivative_marker_inst: MeshInstance3D
var _derivative_marker_material: StandardMaterial3D

# Readout panel.
var _readout_root: Node3D
var _readout_dprime: Label3D    # big f'(x) = ...
var _readout_f: Label3D         # f(x) = ...
var _readout_state: Label3D     # rising / falling / horizontal
var _readout_x: Label3D         # x = ...

# Sign indicator — small horizontal arrow that rotates between up/flat/down.
var _sign_root: Node3D
var _sign_arrow_inst: MeshInstance3D
var _sign_arrow_mesh: ImmediateMesh
var _sign_arrow_material: StandardMaterial3D
var _sign_label: Label3D


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_x = clampf(initial_x, x_min, x_max)
	_build_plate_and_slider()
	_build_plot()
	_build_derivative_subplot()
	_build_sign_indicator()
	_build_axis_labels()
	_refresh_all()


# ── The function and its derivative ──────────────────────────────────

static func _f(x: float) -> float:
	# f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x)
	return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)


static func _df(x: float) -> float:
	# f'(x) = 0.8·cos(2x) − 0.75·sin(5x)
	return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)


# ── Slider mapping (continuous, no detents) ──────────────────────────

func _normalized_to_x(norm: float) -> float:
	return x_min + clampf(norm, 0.0, 1.0) * (x_max - x_min)


func _x_to_normalized(x: float) -> float:
	if x_max <= x_min:
		return 0.0
	return clampf((x - x_min) / (x_max - x_min), 0.0, 1.0)


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole — houses the plate (seated x slider) AND the
	# live readout as a 2D-in-3D screen on the board (replaces the floating card).
	_plate_root = InterfacePresets.build("workbench", "Tangent Slope", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)

	_plate_readout = _plate_root.add_readout("")

	_slider = _plate_root.add_slider("x — sample position", "x — sample position")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _x_to_normalized(_x))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var n_norm: Variant = _slider.call("get_normalized_value")
	var new_x: float = _normalized_to_x(float(n_norm))
	if absf(new_x - _x) < 0.0005:
		return
	_x = new_x
	# Throttled refresh — keep the grab loop free (see _process).
	_viz_dirty = true


var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Plot (curve + tangent + baseline + marker) ────────────────────────

func _build_plot() -> void:
	_plot_root = Node3D.new()
	_plot_root.name = "Plot"
	_plot_root.position = plot_offset
	add_child(_plot_root)

	# Backplate behind the plot — dark stage for the curve.
	var back := MeshInstance3D.new()
	back.name = "PlotBackplate"
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(plot_width + 0.06, plot_height + 0.16)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.02, 0.04)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(0.0, plot_height * 0.5, -0.01)
	_plot_root.add_child(back)

	# Baseline (y = 0).
	_emit_baseline()

	# Curve (line strip) — pale white-gold.
	_curve_mesh = ImmediateMesh.new()
	_curve_mesh_inst = MeshInstance3D.new()
	_curve_mesh_inst.name = "Curve"
	_curve_mesh_inst.mesh = _curve_mesh
	_curve_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_curve_material = StandardMaterial3D.new()
	_curve_material.albedo_color = curve_color
	_curve_material.emission_enabled = true
	_curve_material.emission = curve_color
	_curve_material.emission_energy_multiplier = 1.6
	_curve_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_curve_mesh_inst.material_override = _curve_material
	_plot_root.add_child(_curve_mesh_inst)

	_emit_curve()

	# Tangent line — bright gold, regenerated per slider change.
	_tangent_mesh = ImmediateMesh.new()
	_tangent_mesh_inst = MeshInstance3D.new()
	_tangent_mesh_inst.name = "TangentLine"
	_tangent_mesh_inst.mesh = _tangent_mesh
	_tangent_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_tangent_material = StandardMaterial3D.new()
	_tangent_material.albedo_color = tangent_color
	_tangent_material.emission_enabled = true
	_tangent_material.emission = tangent_color
	_tangent_material.emission_energy_multiplier = 2.2
	_tangent_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tangent_mesh_inst.material_override = _tangent_material
	_plot_root.add_child(_tangent_mesh_inst)

	# Marker dot at (x, f(x)).
	_marker_inst = MeshInstance3D.new()
	_marker_inst.name = "Marker"
	var sphere := SphereMesh.new()
	sphere.radius = marker_radius
	sphere.height = marker_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_marker_inst.mesh = sphere
	_marker_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = marker_color
	_marker_material.emission_enabled = true
	_marker_material.emission = marker_color
	_marker_material.emission_energy_multiplier = 2.5
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_inst.material_override = _marker_material
	_plot_root.add_child(_marker_inst)

	# Marker leader — thin vertical from baseline to marker, gives the dot a
	# floor reference like in shannon_workbench.
	_marker_leader = MeshInstance3D.new()
	_marker_leader.name = "MarkerLeader"
	var leader_cyl := CylinderMesh.new()
	leader_cyl.top_radius = 0.004
	leader_cyl.bottom_radius = 0.004
	leader_cyl.height = 1.0  # rescaled per refresh
	leader_cyl.radial_segments = 6
	_marker_leader.mesh = leader_cyl
	_marker_leader.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var leader_mat := StandardMaterial3D.new()
	leader_mat.albedo_color = Color(marker_color.r, marker_color.g, marker_color.b, 0.55)
	leader_mat.emission_enabled = true
	leader_mat.emission = marker_color
	leader_mat.emission_energy_multiplier = 0.7
	leader_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leader_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_leader.material_override = leader_mat
	_plot_root.add_child(_marker_leader)


func _emit_baseline() -> void:
	var base_mesh := ImmediateMesh.new()
	base_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	base_mesh.surface_add_vertex(Vector3(-plot_width * 0.5, 0.0, 0.0))
	base_mesh.surface_add_vertex(Vector3(plot_width * 0.5, 0.0, 0.0))
	base_mesh.surface_end()

	var base_inst := MeshInstance3D.new()
	base_inst.name = "Baseline"
	base_inst.mesh = base_mesh
	base_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.45, 0.55)
	base_mat.emission_enabled = true
	base_mat.emission = Color(0.4, 0.45, 0.55)
	base_mat.emission_energy_multiplier = 0.6
	base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_inst.material_override = base_mat
	_plot_root.add_child(base_inst)


func _x_to_local(x: float) -> float:
	# Map x ∈ [x_min, x_max] → local plot x ∈ [-plot_width/2, +plot_width/2].
	var t: float = (x - x_min) / (x_max - x_min)
	return -plot_width * 0.5 + t * plot_width


func _f_to_local(y: float) -> float:
	# Map f(x) ≈ [0, ~1.05] → local plot y ∈ [0, plot_height].
	return y * plot_height


func _emit_curve() -> void:
	_curve_mesh.clear_surfaces()
	_curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(curve_samples + 1):
		var t: float = float(i) / float(curve_samples)
		var x: float = x_min + t * (x_max - x_min)
		var pt := Vector3(_x_to_local(x), _f_to_local(_f(x)), 0.001)
		_curve_mesh.surface_add_vertex(pt)
	_curve_mesh.surface_end()


func _emit_tangent() -> void:
	# Tangent at x0: y = f(x0) + m·(x − x0), drawn from x = x0 - h to x0 + h
	# where h = tangent_half_span_x. We clip both endpoints to the curve
	# domain so the tangent never extends beyond the plot.
	_tangent_mesh.clear_surfaces()
	var x0: float = _x
	var y0: float = _f(x0)
	var m: float = _df(x0)
	var h: float = tangent_half_span_x
	var xa: float = clampf(x0 - h, x_min, x_max)
	var xb: float = clampf(x0 + h, x_min, x_max)
	var ya: float = y0 + m * (xa - x0)
	var yb: float = y0 + m * (xb - x0)

	# Slightly in front of the curve so the gold line reads on top of the white curve.
	var z: float = 0.003
	_tangent_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_tangent_mesh.surface_add_vertex(Vector3(_x_to_local(xa), _f_to_local(ya), z))
	_tangent_mesh.surface_add_vertex(Vector3(_x_to_local(xb), _f_to_local(yb), z))
	_tangent_mesh.surface_end()


func _refresh_marker() -> void:
	if _marker_inst == null:
		return
	var lx: float = _x_to_local(_x)
	var ly: float = _f_to_local(_f(_x))
	# Slightly above the tangent line so the marker reads as ON the curve, not behind it.
	_marker_inst.position = Vector3(lx, ly, 0.005)

	if _marker_leader and _marker_leader.mesh is CylinderMesh:
		var h: float = max(0.001, ly)
		(_marker_leader.mesh as CylinderMesh).height = h
		_marker_leader.position = Vector3(lx, h * 0.5, 0.0)


# ── Derivative subplot ────────────────────────────────────────────────

func _build_derivative_subplot() -> void:
	if not show_derivative_subplot:
		return
	_derivative_root = Node3D.new()
	_derivative_root.name = "DerivativeSubplot"
	# Sits above the main plot in the plot's local frame.
	_derivative_root.position = Vector3(0.0, derivative_subplot_y, 0.0)
	_plot_root.add_child(_derivative_root)

	# Backplate for the subplot.
	var back := MeshInstance3D.new()
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(plot_width + 0.06, derivative_subplot_height + 0.06)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.025, 0.04)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(0.0, 0.0, -0.012)
	_derivative_root.add_child(back)

	# Zero-line for f'(x) — horizontal mid-line so positive/negative slope reads as above/below.
	var zero_mesh := ImmediateMesh.new()
	zero_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	zero_mesh.surface_add_vertex(Vector3(-plot_width * 0.5, 0.0, 0.0))
	zero_mesh.surface_add_vertex(Vector3(plot_width * 0.5, 0.0, 0.0))
	zero_mesh.surface_end()
	var zero_inst := MeshInstance3D.new()
	zero_inst.mesh = zero_mesh
	zero_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var zero_mat := StandardMaterial3D.new()
	zero_mat.albedo_color = Color(0.4, 0.45, 0.55)
	zero_mat.emission_enabled = true
	zero_mat.emission = Color(0.4, 0.45, 0.55)
	zero_mat.emission_energy_multiplier = 0.5
	zero_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	zero_inst.material_override = zero_mat
	_derivative_root.add_child(zero_inst)

	# Subplot curve f'(x).
	_derivative_curve_mesh = ImmediateMesh.new()
	_derivative_curve_inst = MeshInstance3D.new()
	_derivative_curve_inst.name = "DerivativeCurve"
	_derivative_curve_inst.mesh = _derivative_curve_mesh
	_derivative_curve_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = derivative_color
	dmat.emission_enabled = true
	dmat.emission = derivative_color
	dmat.emission_energy_multiplier = 1.5
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_derivative_curve_inst.material_override = dmat
	_derivative_root.add_child(_derivative_curve_inst)

	_emit_derivative_curve()

	# Marker on the derivative subplot — same x as the main marker, y = f'(x).
	_derivative_marker_inst = MeshInstance3D.new()
	_derivative_marker_inst.name = "DerivativeMarker"
	var s := SphereMesh.new()
	s.radius = marker_radius * 0.7
	s.height = marker_radius * 1.4
	s.radial_segments = 12
	s.rings = 6
	_derivative_marker_inst.mesh = s
	_derivative_marker_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_derivative_marker_material = StandardMaterial3D.new()
	_derivative_marker_material.albedo_color = derivative_color
	_derivative_marker_material.emission_enabled = true
	_derivative_marker_material.emission = derivative_color
	_derivative_marker_material.emission_energy_multiplier = 2.5
	_derivative_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_derivative_marker_inst.material_override = _derivative_marker_material
	_derivative_root.add_child(_derivative_marker_inst)

	# Subplot label.
	var dlabel := Label3D.new()
	dlabel.text = "f'(x) = 0.8·cos(2x) − 0.75·sin(5x)"
	dlabel.font_size = 20
	dlabel.outline_size = 3
	dlabel.pixel_size = 0.001
	dlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dlabel.modulate = derivative_color
	dlabel.position = Vector3(-plot_width * 0.5, derivative_subplot_height * 0.5 + 0.02, 0.0)
	_derivative_root.add_child(dlabel)


func _df_to_local_y(d: float) -> float:
	# Map f'(x) ∈ [-DERIVATIVE_MAX_ABS, +DERIVATIVE_MAX_ABS] →
	# local y ∈ [-derivative_subplot_height/2, +derivative_subplot_height/2].
	var t: float = clampf(d / DERIVATIVE_MAX_ABS, -1.0, 1.0)
	return t * derivative_subplot_height * 0.5


func _emit_derivative_curve() -> void:
	if not show_derivative_subplot or _derivative_curve_mesh == null:
		return
	_derivative_curve_mesh.clear_surfaces()
	_derivative_curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(curve_samples + 1):
		var t: float = float(i) / float(curve_samples)
		var x: float = x_min + t * (x_max - x_min)
		var pt := Vector3(_x_to_local(x), _df_to_local_y(_df(x)), 0.001)
		_derivative_curve_mesh.surface_add_vertex(pt)
	_derivative_curve_mesh.surface_end()


func _refresh_derivative_marker() -> void:
	if not show_derivative_subplot or _derivative_marker_inst == null:
		return
	var lx: float = _x_to_local(_x)
	var ly: float = _df_to_local_y(_df(_x))
	_derivative_marker_inst.position = Vector3(lx, ly, 0.003)


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	# To the right of the plot, in world space (so it doesn't tilt with the plate).
	_readout_root.position = Vector3(plot_width * 0.5 + 0.12, plate_height + 0.55, plate_offset_z + 0.05)
	add_child(_readout_root)

	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.48, 0.32)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.24, 0.0, -0.005)
	_readout_root.add_child(card)

	# Big f'(x) readout — the headline.
	_readout_dprime = Label3D.new()
	_readout_dprime.name = "ReadoutDPrime"
	_readout_dprime.font_size = 44
	_readout_dprime.outline_size = 5
	_readout_dprime.pixel_size = 0.001
	_readout_dprime.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_dprime.modulate = tangent_color
	_readout_dprime.position = Vector3(0.02, 0.115, 0.0)
	_readout_root.add_child(_readout_dprime)

	# f(x).
	_readout_f = Label3D.new()
	_readout_f.name = "ReadoutF"
	_readout_f.font_size = 22
	_readout_f.outline_size = 3
	_readout_f.pixel_size = 0.001
	_readout_f.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_f.modulate = curve_color
	_readout_f.position = Vector3(0.02, 0.04, 0.0)
	_readout_root.add_child(_readout_f)

	# Sign-of-slope text — rising / falling / horizontal.
	_readout_state = Label3D.new()
	_readout_state.name = "ReadoutState"
	_readout_state.font_size = 22
	_readout_state.outline_size = 3
	_readout_state.pixel_size = 0.001
	_readout_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_state.modulate = Color(0.85, 0.95, 1.0)
	_readout_state.position = Vector3(0.02, -0.02, 0.0)
	_readout_root.add_child(_readout_state)

	# x value.
	_readout_x = Label3D.new()
	_readout_x.name = "ReadoutX"
	_readout_x.font_size = 22
	_readout_x.outline_size = 3
	_readout_x.pixel_size = 0.001
	_readout_x.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_x.modulate = Color(0.7, 0.85, 1.0)
	_readout_x.position = Vector3(0.02, -0.08, 0.0)
	_readout_root.add_child(_readout_x)


func _refresh_readout() -> void:
	if _plate_readout == null:
		return
	var fx: float = _f(_x)
	var dx: float = _df(_x)
	_plate_readout.text = "f'(%.2f) = %+.2f\nf %.2f · %s" % [_x, dx, fx, _slope_word(dx)]


static func _slope_word(d: float) -> String:
	# Threshold for "horizontal" — anything within ~0.05 reads visually flat.
	if absf(d) < 0.05:
		return "horizontal"
	if d > 0.0:
		return "rising"
	return "falling"


# ── Sign indicator ────────────────────────────────────────────────────

func _build_sign_indicator() -> void:
	# A small arrow in world space (off the tilted plate), rendered as
	# ImmediateMesh lines so we can repaint it per refresh with a different
	# rotation and color.
	_sign_root = Node3D.new()
	_sign_root.name = "SignIndicator"
	_sign_root.position = Vector3(sign_indicator_x, sign_indicator_height, plate_offset_z + 0.0)
	add_child(_sign_root)

	# Backing card.
	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.22, 0.22)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.04, 0.06, 0.09)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.0, 0.0, -0.01)
	_sign_root.add_child(card)

	_sign_arrow_mesh = ImmediateMesh.new()
	_sign_arrow_inst = MeshInstance3D.new()
	_sign_arrow_inst.name = "SignArrow"
	_sign_arrow_inst.mesh = _sign_arrow_mesh
	_sign_arrow_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_sign_arrow_material = StandardMaterial3D.new()
	_sign_arrow_material.albedo_color = Color.WHITE
	_sign_arrow_material.emission_enabled = true
	_sign_arrow_material.emission = Color.WHITE
	_sign_arrow_material.emission_energy_multiplier = 2.0
	_sign_arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sign_arrow_inst.material_override = _sign_arrow_material
	_sign_root.add_child(_sign_arrow_inst)

	# Caption under the arrow.
	_sign_label = Label3D.new()
	_sign_label.text = "slope sign"
	_sign_label.font_size = 22
	_sign_label.outline_size = 3
	_sign_label.pixel_size = 0.001
	_sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sign_label.modulate = Color(0.75, 0.8, 0.9)
	_sign_label.position = Vector3(0.0, -0.13, 0.0)
	_sign_root.add_child(_sign_label)


func _refresh_sign_indicator() -> void:
	if _sign_arrow_mesh == null:
		return
	var d: float = _df(_x)
	# Map slope magnitude to a tilt angle, clamped so steep slopes don't run off the card.
	# We use a soft normalization so the visual tilt is dramatic at moderate slope
	# but levels off near the curve's max slope (~1.55 in absolute value).
	var t: float = clampf(d / 1.0, -1.5, 1.5)
	var angle: float = atan(t)  # ∈ ~(-1.0, +1.0) rad

	# Color: green for rising, red for falling, white for horizontal.
	var color: Color
	if absf(d) < 0.05:
		color = Color(0.95, 0.97, 1.0)
		angle = 0.0
	elif d > 0.0:
		color = Color(0.35, 0.95, 0.45)
	else:
		color = Color(0.98, 0.32, 0.28)
	_sign_arrow_material.albedo_color = color
	_sign_arrow_material.emission = color

	# Re-emit a horizontal arrow (shaft + two tip lines), then rotate the instance.
	_sign_arrow_mesh.clear_surfaces()
	var L: float = 0.08
	var head_len: float = 0.025
	var head_off: float = 0.018
	_sign_arrow_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Shaft.
	_sign_arrow_mesh.surface_add_vertex(Vector3(-L, 0.0, 0.0))
	_sign_arrow_mesh.surface_add_vertex(Vector3(L, 0.0, 0.0))
	# Head — two short lines from tip backward.
	_sign_arrow_mesh.surface_add_vertex(Vector3(L, 0.0, 0.0))
	_sign_arrow_mesh.surface_add_vertex(Vector3(L - head_len, head_off, 0.0))
	_sign_arrow_mesh.surface_add_vertex(Vector3(L, 0.0, 0.0))
	_sign_arrow_mesh.surface_add_vertex(Vector3(L - head_len, -head_off, 0.0))
	_sign_arrow_mesh.surface_end()

	# Rotate the instance to match the slope angle.
	_sign_arrow_inst.rotation = Vector3(0.0, 0.0, angle)

	# Update caption to mirror the state.
	if absf(d) < 0.05:
		_sign_label.text = "horizontal  ·  extremum"
	elif d > 0.0:
		_sign_label.text = "rising  ·  f' > 0"
	else:
		_sign_label.text = "falling  ·  f' < 0"


# ── Axis labels ───────────────────────────────────────────────────────

func _build_axis_labels() -> void:
	var label_color := Color(0.65, 0.7, 0.8)

	var l0 := _mk_axis_label("x = 0", Color(0.55, 0.6, 0.7))
	l0.position = Vector3(_x_to_local(x_min), -0.05, 0.0)
	_plot_root.add_child(l0)

	var l_mid := _mk_axis_label("x", label_color)
	l_mid.position = Vector3(0.0, -0.1, 0.0)
	_plot_root.add_child(l_mid)

	var l5 := _mk_axis_label("x = %s" % String.num(x_max, 1), Color(0.55, 0.6, 0.7))
	l5.position = Vector3(_x_to_local(x_max), -0.05, 0.0)
	_plot_root.add_child(l5)

	# y-axis: the curve label, top-left of the main plot.
	var y_label := _mk_axis_label("f(x) = ½ + 0.4·sin(2x) + 0.15·cos(5x)", curve_color)
	y_label.font_size = 22
	y_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	y_label.position = Vector3(-plot_width * 0.5, plot_height + 0.05, 0.0)
	_plot_root.add_child(y_label)


func _mk_axis_label(s: String, c: Color) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = s
	lbl.font_size = 26
	lbl.outline_size = 3
	lbl.pixel_size = 0.001
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = c
	return lbl


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_emit_tangent()
	_refresh_marker()
	_refresh_derivative_marker()
	_refresh_readout()
	_refresh_sign_indicator()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_x"):
		_x = clampf(float(config_data["initial_x"]), x_min, x_max)
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _x_to_normalized(_x))
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("plot_height"):
		plot_height = float(config_data["plot_height"])
		if _curve_mesh:
			_emit_curve()
		_refresh_all()
	if config_data.has("tangent_half_span_x"):
		tangent_half_span_x = float(config_data["tangent_half_span_x"])
		_emit_tangent()
