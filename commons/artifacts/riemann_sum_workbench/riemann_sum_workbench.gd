extends Node3D
class_name RiemannSumWorkbench

# @identity
# essence: an interactive Riemann sum workbench — the player turns a slider for N (rectangle count) and watches the rectangles' total area converge toward the integral of f(x). At N=4 the rectangles undershoot and overshoot wildly; at N=128 they trace the curve. The convergence is the calculus, made hand-held.
# desire: learner viscerally feels the calculus claim "integral = limit of Riemann sum as N → ∞" — the slider IS the limit
# critical_parameter: N — the only knob. Drives the rectangle count, the sum, the error
# triggers: _ready() builds slider + curve + rectangles + readout + error-bar; _on_slider_changed regenerates the rectangles and recomputes the sum
# emerges: O(h²) midpoint-rule convergence made tactile — each doubling of N quarters the error
# needs: slider_horizontal [present]; ImmediateMesh for curve+rectangles [present]; Label3D for readouts [present]; shannon_workbench as conceptual sibling [present]
# relationships: paired with /riemann-sum-gallery (web cells of this exact instrument frozen at 6 N-values); sibling to tangent_slope_workbench (integral pair to derivative); embodies the change sequence's truth "things change, change accumulates"
# truth: integration is the limit of a polygon. The polygon at N=4 is a coarse approximation; at N=128 it's perceptually smooth. The slider walks the limit.

## A horizontal workbench for the midpoint Riemann sum.
##
## One slider drives N (rectangle count), stepped through six tick stops
## [4, 8, 16, 32, 64, 128]. As N grows:
##   • the midpoint Riemann sum Σ f(x_k)·w is recomputed against the true
##     integral of f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) on [0, 5]
##   • the rectangles regenerate (a single ImmediateMesh of N quads, blue,
##     translucent) under the curve
##   • the readout updates with sum, true integral, error, N
##   • a small vertical error-bar on the side of the table shrinks
##
## The curve floats above the table — a literal landscape, and the
## rectangles are the polygon you're using to chase it.

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
@export var rect_color: Color = Color(0.35, 0.7, 1.0, 0.45)
@export var rect_edge_color: Color = Color(0.55, 0.85, 1.0, 0.85)

@export_group("Error Bar")
## How far to the right of the plot the error bar sits.
@export var error_bar_x: float = 0.85
## Maximum visual height of the error bar (at the worst N=4 case).
@export var error_bar_max_height: float = 0.4
## Reference error used to scale the bar's height (~the N=4 error).
@export var error_bar_ref: float = 0.05
@export var error_bar_color: Color = Color(1.0, 0.35, 0.25)

@export_group("Curve definition")
## Domain start of x.
@export var x_min: float = 0.0
## Domain end of x.
@export var x_max: float = 5.0

# ── Internal state ────────────────────────────────────────────────────

const SLIDER_SCENE_PATH: String = "res://commons/interactables/slider_horizontal.tscn"
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

# Six tick stops — a discrete-integer slider feels more honest for "count
# of rectangles." Each detent doubles N, which mirrors the convergence rate.
const N_STOPS: Array[int] = [4, 8, 16, 32, 64, 128]

# True integral computed via dense midpoint rule once at startup.
# For f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) on [0, 5] this is ≈ 2.86384375
# (analytically: 0.5·5 + 0.2·(1 - cos(10)) + 0.03·(sin(25))).
var _true_integral: float = 0.0

var _n_index: int = 2          # default to N=16 — already converged enough to read, coarse enough to see the polygon
var _n: int = 16

var _plate_root: Node3D
var _slider: Node               # SliderHorizontal instance
var _plate_readout: Label       # 2D-in-3D readout integrated on the console board

var _plot_root: Node3D

var _curve_mesh_inst: MeshInstance3D
var _curve_mesh: ImmediateMesh
var _curve_material: StandardMaterial3D

var _rects_mesh_inst: MeshInstance3D
var _rects_mesh: ImmediateMesh
var _rects_material: StandardMaterial3D

var _rect_edges_mesh_inst: MeshInstance3D
var _rect_edges_mesh: ImmediateMesh
var _rect_edges_material: StandardMaterial3D

var _readout_root: Node3D
var _readout_sum: Label3D
var _readout_true: Label3D
var _readout_error: Label3D
var _readout_n: Label3D

var _error_bar_inst: MeshInstance3D
var _error_bar_mesh: BoxMesh
var _error_bar_material: StandardMaterial3D


# ── Lifecycle ─────────────────────────────────────────────────────────

## Starting N — the critical parameter, settable as DNA (snapped to N_STOPS).
@export var initial_n: int = 16

func _ready() -> void:
	for i in N_STOPS.size():
		if N_STOPS[i] == initial_n:
			_n_index = i
			break
	_n = N_STOPS[_n_index]
	_true_integral = _compute_true_integral()
	_build_plate_and_slider()
	_build_plot()
	_build_error_bar()
	_build_axis_labels()
	_refresh_all()


# ── Curve f(x) ────────────────────────────────────────────────────────

static func _f(x: float) -> float:
	# f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x)
	return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)


# ── Slider stops ──────────────────────────────────────────────────────

func _normalized_to_n_index(norm: float) -> int:
	# Map [0,1] → index in N_STOPS via rounding to nearest detent.
	var stops: int = N_STOPS.size()
	var idx: int = int(round(norm * float(stops - 1)))
	return clampi(idx, 0, stops - 1)


func _n_index_to_normalized(idx: int) -> float:
	var stops: int = N_STOPS.size()
	return float(idx) / float(stops - 1)


# ── True integral (reference) ─────────────────────────────────────────

func _compute_true_integral() -> float:
	# Dense midpoint rule with 4096 sub-intervals — converges to ~10 decimals
	# on this smooth analytic curve, plenty for the readout.
	var n_ref: int = 4096
	var w: float = (x_max - x_min) / float(n_ref)
	var s: float = 0.0
	for k in range(n_ref):
		var xk: float = x_min + w * (float(k) + 0.5)
		s += _f(xk)
	return s * w


func _compute_riemann_sum(n_rects: int) -> float:
	var w: float = (x_max - x_min) / float(n_rects)
	var s: float = 0.0
	for k in range(n_rects):
		var xk: float = x_min + w * (float(k) + 0.5)
		s += _f(xk)
	return s * w


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole — houses the plate (seated N slider) AND the
	# live readout as a 2D-in-3D screen on the board (replaces the floating card).
	_plate_root = InterfacePresets.build("workbench", "Riemann Sum", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)

	_plate_readout = _plate_root.add_readout("")

	_slider = _plate_root.add_slider("N rectangles", "N rectangles")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _n_index_to_normalized(_n_index))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var n_norm: Variant = _slider.call("get_normalized_value")
	var new_idx: int = _normalized_to_n_index(float(n_norm))
	if new_idx == _n_index:
		return
	_n_index = new_idx
	_n = N_STOPS[_n_index]
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


# ── Plot (curve + rectangles + baseline) ──────────────────────────────

func _build_plot() -> void:
	_plot_root = Node3D.new()
	_plot_root.name = "Plot"
	_plot_root.position = plot_offset
	add_child(_plot_root)

	# Backplate behind the plot — gives the curve a dark stage to read against.
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

	# Baseline (y = 0) — horizontal floor of the plot.
	_emit_baseline()

	# Rectangles (filled) — TRIANGLES primitive, translucent blue.
	_rects_mesh = ImmediateMesh.new()
	_rects_mesh_inst = MeshInstance3D.new()
	_rects_mesh_inst.name = "Rectangles"
	_rects_mesh_inst.mesh = _rects_mesh
	_rects_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_rects_material = StandardMaterial3D.new()
	_rects_material.albedo_color = rect_color
	_rects_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rects_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rects_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rects_material.emission_enabled = true
	_rects_material.emission = Color(0.2, 0.55, 0.95)
	_rects_material.emission_energy_multiplier = 0.5
	_rects_mesh_inst.material_override = _rects_material
	_plot_root.add_child(_rects_mesh_inst)

	# Rectangle edges (outlines) — LINES primitive on the boundary of each rect,
	# brighter, fully opaque, so individual rectangles read at high N too.
	_rect_edges_mesh = ImmediateMesh.new()
	_rect_edges_mesh_inst = MeshInstance3D.new()
	_rect_edges_mesh_inst.name = "RectangleEdges"
	_rect_edges_mesh_inst.mesh = _rect_edges_mesh
	_rect_edges_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_rect_edges_material = StandardMaterial3D.new()
	_rect_edges_material.albedo_color = rect_edge_color
	_rect_edges_material.emission_enabled = true
	_rect_edges_material.emission = rect_edge_color
	_rect_edges_material.emission_energy_multiplier = 1.2
	_rect_edges_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rect_edges_mesh_inst.material_override = _rect_edges_material
	_plot_root.add_child(_rect_edges_mesh_inst)

	# Curve (line strip) — drawn AFTER the rectangles so it sits on top.
	_curve_mesh = ImmediateMesh.new()
	_curve_mesh_inst = MeshInstance3D.new()
	_curve_mesh_inst.name = "Curve"
	_curve_mesh_inst.mesh = _curve_mesh
	_curve_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_curve_material = StandardMaterial3D.new()
	_curve_material.albedo_color = curve_color
	_curve_material.emission_enabled = true
	_curve_material.emission = curve_color
	_curve_material.emission_energy_multiplier = 1.8
	_curve_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_curve_mesh_inst.material_override = _curve_material
	_plot_root.add_child(_curve_mesh_inst)

	_emit_curve()


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
	# Map f(x) ≈ [0, 1.05] → local plot y ∈ [0, plot_height].
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


func _emit_rectangles() -> void:
	_rects_mesh.clear_surfaces()
	_rect_edges_mesh.clear_surfaces()

	if _n <= 0:
		return

	var w: float = (x_max - x_min) / float(_n)

	_rects_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_rect_edges_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for k in range(_n):
		var x_left: float = x_min + w * float(k)
		var x_right: float = x_min + w * float(k + 1)
		var x_mid: float = x_min + w * (float(k) + 0.5)
		var height: float = _f(x_mid)

		var lx: float = _x_to_local(x_left)
		var rx: float = _x_to_local(x_right)
		var top: float = _f_to_local(height)
		# Slightly behind the curve so the curve always reads on top.
		var z: float = -0.001

		# Two triangles per rectangle (CCW from front).
		var p_bl := Vector3(lx, 0.0, z)
		var p_br := Vector3(rx, 0.0, z)
		var p_tr := Vector3(rx, top, z)
		var p_tl := Vector3(lx, top, z)

		_rects_mesh.surface_add_vertex(p_bl)
		_rects_mesh.surface_add_vertex(p_br)
		_rects_mesh.surface_add_vertex(p_tr)

		_rects_mesh.surface_add_vertex(p_bl)
		_rects_mesh.surface_add_vertex(p_tr)
		_rects_mesh.surface_add_vertex(p_tl)

		# Edges — four sides of the rectangle.
		var ez: float = 0.0  # edges slightly in front of fill
		var e_bl := Vector3(lx, 0.0, ez)
		var e_br := Vector3(rx, 0.0, ez)
		var e_tr := Vector3(rx, top, ez)
		var e_tl := Vector3(lx, top, ez)
		_rect_edges_mesh.surface_add_vertex(e_bl); _rect_edges_mesh.surface_add_vertex(e_tl)  # left
		_rect_edges_mesh.surface_add_vertex(e_tl); _rect_edges_mesh.surface_add_vertex(e_tr)  # top
		_rect_edges_mesh.surface_add_vertex(e_tr); _rect_edges_mesh.surface_add_vertex(e_br)  # right
		# (bottom omitted — it's the baseline anyway)

	_rects_mesh.surface_end()
	_rect_edges_mesh.surface_end()


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
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

	# Big Σ readout — the headline number.
	_readout_sum = Label3D.new()
	_readout_sum.name = "ReadoutSum"
	_readout_sum.font_size = 44
	_readout_sum.outline_size = 5
	_readout_sum.pixel_size = 0.001
	_readout_sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_sum.modulate = Color(0.55, 0.85, 1.0)
	_readout_sum.position = Vector3(0.02, 0.115, 0.0)
	_readout_root.add_child(_readout_sum)

	# True integral.
	_readout_true = Label3D.new()
	_readout_true.name = "ReadoutTrue"
	_readout_true.font_size = 22
	_readout_true.outline_size = 3
	_readout_true.pixel_size = 0.001
	_readout_true.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_true.modulate = Color(1.0, 0.97, 0.7)
	_readout_true.position = Vector3(0.02, 0.04, 0.0)
	_readout_root.add_child(_readout_true)

	# Error.
	_readout_error = Label3D.new()
	_readout_error.name = "ReadoutError"
	_readout_error.font_size = 22
	_readout_error.outline_size = 3
	_readout_error.pixel_size = 0.001
	_readout_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_error.modulate = Color(1.0, 0.5, 0.45)
	_readout_error.position = Vector3(0.02, -0.02, 0.0)
	_readout_root.add_child(_readout_error)

	# N — the slider's value, echoed here for the legend.
	_readout_n = Label3D.new()
	_readout_n.name = "ReadoutN"
	_readout_n.font_size = 22
	_readout_n.outline_size = 3
	_readout_n.pixel_size = 0.001
	_readout_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_n.modulate = Color(0.7, 0.85, 1.0)
	_readout_n.position = Vector3(0.02, -0.08, 0.0)
	_readout_root.add_child(_readout_n)


func _refresh_readout() -> void:
	if _plate_readout == null:
		return
	var approx: float = _compute_riemann_sum(_n)
	var err: float = approx - _true_integral
	var line2: String
	if abs(err) < 0.0001:
		line2 = "∫ %.4f · converged · N=%d" % [_true_integral, _n]
	else:
		line2 = "∫ %.4f · err %+.4f · N=%d" % [_true_integral, err, _n]
	_plate_readout.text = "Σ = %.4f\n%s" % [approx, line2]


# ── Error bar ─────────────────────────────────────────────────────────

func _build_error_bar() -> void:
	# A small upright bar to the right of the plot. Its visual height is
	# proportional to |error| relative to error_bar_ref (the N=4 case),
	# clamped to error_bar_max_height. At N=128 it's near-zero.
	#
	# The bar lives in world space at the artifact origin, not under the
	# plate (which is tilted), so it reads as an instrument off the table.
	var bar_root := Node3D.new()
	bar_root.name = "ErrorBar"
	bar_root.position = Vector3(error_bar_x, plate_height, plate_offset_z + 0.0)
	add_child(bar_root)

	# Backplate column (the "track" the indicator slides in).
	var col := MeshInstance3D.new()
	col.name = "Column"
	var col_mesh := BoxMesh.new()
	col_mesh.size = Vector3(0.03, error_bar_max_height + 0.04, 0.005)
	col.mesh = col_mesh
	var col_mat := StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.05, 0.07, 0.1)
	col_mat.roughness = 0.8
	col.material_override = col_mat
	col.position = Vector3(0.0, (error_bar_max_height + 0.04) * 0.5, -0.003)
	bar_root.add_child(col)

	# The bar itself — its size.y will be rewritten per refresh.
	_error_bar_mesh = BoxMesh.new()
	_error_bar_mesh.size = Vector3(0.05, 0.001, 0.012)
	_error_bar_inst = MeshInstance3D.new()
	_error_bar_inst.name = "Bar"
	_error_bar_inst.mesh = _error_bar_mesh
	_error_bar_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_error_bar_material = StandardMaterial3D.new()
	_error_bar_material.albedo_color = error_bar_color
	_error_bar_material.emission_enabled = true
	_error_bar_material.emission = error_bar_color
	_error_bar_material.emission_energy_multiplier = 1.6
	_error_bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_error_bar_inst.material_override = _error_bar_material
	_error_bar_inst.position = Vector3(0.0, 0.0005, 0.0)
	bar_root.add_child(_error_bar_inst)

	# Caption under the bar.
	var caption := Label3D.new()
	caption.text = "|error|"
	caption.font_size = 22
	caption.outline_size = 3
	caption.pixel_size = 0.001
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.modulate = Color(0.95, 0.6, 0.55)
	caption.position = Vector3(0.0, -0.06, 0.0)
	bar_root.add_child(caption)

	# Reference top tick — marks the N=4 height (full bar).
	var top_tick := Label3D.new()
	top_tick.text = "  ≈ %.3f  (N=4)" % error_bar_ref
	top_tick.font_size = 18
	top_tick.outline_size = 3
	top_tick.pixel_size = 0.001
	top_tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_tick.modulate = Color(0.7, 0.7, 0.78)
	top_tick.position = Vector3(0.04, error_bar_max_height, 0.0)
	bar_root.add_child(top_tick)


func _refresh_error_bar() -> void:
	if _error_bar_inst == null or _error_bar_mesh == null:
		return
	var approx: float = _compute_riemann_sum(_n)
	var abs_err: float = abs(approx - _true_integral)
	var t: float = clampf(abs_err / max(error_bar_ref, 0.00001), 0.0, 1.0)
	var bar_h: float = max(0.002, t * error_bar_max_height)
	_error_bar_mesh.size = Vector3(0.05, bar_h, 0.012)
	# Anchor at base; the BoxMesh is centered, so push the bar up by half its height.
	_error_bar_inst.position = Vector3(0.0, bar_h * 0.5, 0.0)

	# Dim toward green as the error shrinks (visual reinforcement of
	# "you've converged").
	var c := error_bar_color.lerp(Color(0.4, 1.0, 0.5), 1.0 - t)
	_error_bar_material.albedo_color = c
	_error_bar_material.emission = c


# ── Axis labels ───────────────────────────────────────────────────────

func _build_axis_labels() -> void:
	# x-axis ticks at 0 and 5.
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

	# y-axis: the curve label.
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
	_emit_rectangles()
	_refresh_readout()
	_refresh_error_bar()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_n"):
		var requested_n: int = int(config_data["initial_n"])
		# Snap to nearest detent.
		var best_idx: int = 0
		var best_d: int = 99999
		for i in range(N_STOPS.size()):
			var d: int = abs(N_STOPS[i] - requested_n)
			if d < best_d:
				best_d = d
				best_idx = i
		_n_index = best_idx
		_n = N_STOPS[_n_index]
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _n_index_to_normalized(_n_index))
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("plot_height"):
		plot_height = float(config_data["plot_height"])
		if _curve_mesh:
			_emit_curve()
		_emit_rectangles()
