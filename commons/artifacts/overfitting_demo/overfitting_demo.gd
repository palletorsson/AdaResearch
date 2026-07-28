extends Node3D
class_name OverfittingDemo

# @identity
# essence: fifteen noisy samples scattered above a fixed ground-truth curve, a least-squares polynomial refitted to them at whatever degree the slider names, and a twin error trace where the training line falls to zero while the held-out line climbs away from it
# desire: to put the bias-variance trade-off under one hand — turn the knob until the fit stops describing the world and starts memorising the sample, and watch the second number tell on it
# critical_parameter: degree — 1 to 15 against 15 training points; below 4 the polynomial cannot bend enough to follow the truth, above 10 it has more coefficients than evidence and threads every sample by thrashing between them
# triggers: the slider_horizontal detents through 1..15; each detent solves the ridge-stabilised normal equations, redraws the ImmediateMesh fit, moves both markers on the error trace and rewrites the two readouts
# emerges: the divergence. The two error curves are drawn from the same fit at every degree, so they must agree at low degree and cannot at high degree — the gap between them is the model learning the noise, measured
# needs: slider_horizontal [present]; ImmediateMesh line strips [Godot built-in]; Grid.gdshader for the bench [present]; Label3D readouts [present]
# relationships: the measuring instrument the machinelearning sequence needs before any model claims accuracy; the held-out set is the same withholding that excluded_class_visualizer makes spatial
# truth: a model that fits its training data perfectly has told you nothing about the world and everything about the fifteen points you happened to collect. Training error going to zero is not success, it is the last thing you see before you stop learning anything.

## The overfitting bench for the machinelearning sequence.
##
## Left plate: the ground-truth curve (pale), 15 noisy training samples (red),
## 9 held-out samples (blue rings), and the current polynomial fit (gold).
## Right plate: train RMSE and held-out RMSE plotted against degree 1..15, with
## a marker on each at the degree the slider currently names. The two traces
## start together and separate — that separation is the whole artifact.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const SLIDER_SCENE_PATH := "res://commons/interactables/slider_horizontal.tscn"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ── Configuration ────────────────────────────────────────────────────

## The critical parameter. 1..15 against 15 training points.
@export_range(1, 15, 1) var degree: int = 3
@export var sample_count: int = 15
@export var holdout_count: int = 9
## Standard deviation of the measurement noise added to the truth.
@export var noise: float = 0.085
## Fixed so two builds are pixel-identical — a pixel critic diffs renders to
## decide whether an axis is real, and per-build scatter would fake motion.
@export var build_seed: int = 20260729

@export_group("Bench")
@export var deck_height: float = 0.90
@export var deck_width: float = 1.86
@export var deck_depth: float = 0.60

@export_group("Plot")
@export var plot_width: float = 1.04
@export var plot_height: float = 0.50
@export var err_width: float = 0.50
@export var err_height: float = 0.38
@export var curve_samples: int = 260

# ── Palette ──────────────────────────────────────────────────────────

const COL_TRUTH := Color(0.62, 0.68, 0.80)
const COL_FIT := Color(1.0, 0.78, 0.22)
const COL_TRAIN := Color(0.98, 0.34, 0.30)
const COL_TEST := Color(0.42, 0.78, 1.0)
const COL_AXIS := Color(0.38, 0.42, 0.52)

## Everything above this on the error plot is pinned to the ceiling. Held-out
## RMSE at degree 14 runs to whole numbers; a linear axis that fitted it would
## squash the entire interesting region into the bottom pixel row.
const ERR_CEIL := 0.50

# The domain is u ∈ [0, 1]; the Vandermonde is built on t = 2u − 1 ∈ [−1, 1],
# which is the only reason a degree-15 solve returns anything finite at all.
const RIDGE := 1.0e-9

# ── State ────────────────────────────────────────────────────────────

var _train_u: Array[float] = []
var _train_y: Array[float] = []
var _test_u: Array[float] = []
var _test_y: Array[float] = []

## err_train[d] / err_test[d] for d ∈ 1..15, computed once at build.
var _err_train: Array[float] = []
var _err_test: Array[float] = []

var _plot_root: Node3D
var _err_root: Node3D
var _fit_mesh: ImmediateMesh
var _train_marker: MeshInstance3D
var _test_marker: MeshInstance3D
var _readout_train: Label3D
var _readout_test: Label3D
var _readout_gap: Label3D
var _slider: Node

var _created: Array[Node] = []
var _built := false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_sample_the_world()
	_precompute_errors()
	_build_bench()
	_build_plot()
	_build_error_plot()
	_build_slider()
	_build_plate()
	_refit()


## Parent a node we made, and remember we made it. The teardown walks this and
## nothing else — label plates and tags the grid adds after us are not ours.
func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


# ── The world, and what we managed to measure of it ──────────────────

## The ground truth. Fixed, smooth, and never redrawn — the fit chases it, the
## samples are a noisy report of it, and it does not care about either.
static func _truth(u: float) -> float:
	return 0.50 + 0.30 * sin(TAU * 0.85 * u + 0.55) - 0.14 * u


func _sample_the_world() -> void:
	_train_u.clear()
	_train_y.clear()
	_test_u.clear()
	_test_y.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = build_seed

	var n: int = maxi(4, sample_count)
	for i in range(n):
		# Jittered stratification: samples cover the domain but not evenly, the
		# way a real collection does. The gaps are where the high-degree fit
		# does its worst work.
		var base: float = (float(i) + 0.5) / float(n)
		var u: float = clampf(base + rng.randf_range(-0.32, 0.32) / float(n), 0.0, 1.0)
		_train_u.append(u)
		_train_y.append(_truth(u) + rng.randfn(0.0, noise))

	var m: int = maxi(2, holdout_count)
	for i in range(m):
		# Held out: drawn from the SAME process, never shown to the solver.
		var base2: float = (float(i) + 0.5) / float(m)
		var u2: float = clampf(base2 + rng.randf_range(-0.30, 0.30) / float(m), 0.0, 1.0)
		_test_u.append(u2)
		_test_y.append(_truth(u2) + rng.randfn(0.0, noise))


# ── The fit ──────────────────────────────────────────────────────────

## Least squares by normal equations, with a ridge so tiny it changes nothing
## a condition number would not have destroyed anyway. Its only job is to keep
## degree 15 on 15 points from returning NaN — the fit it returns still thrashes,
## which is the behaviour the artifact is here to show.
func _fit(us: Array[float], ys: Array[float], deg: int) -> Array[float]:
	var m: int = clampi(deg, 0, 15) + 1
	var a: Array = []
	var b: Array[float] = []
	for i in range(m):
		var row: Array[float] = []
		for j in range(m):
			row.append(0.0)
		a.append(row)
		b.append(0.0)

	for k in range(us.size()):
		var t: float = 2.0 * float(us[k]) - 1.0
		var powers: Array[float] = []
		var p: float = 1.0
		for i in range(2 * m):
			powers.append(p)
			p *= t
		for i in range(m):
			var row_i: Array = a[i]
			for j in range(m):
				row_i[j] = float(row_i[j]) + float(powers[i + j])
			b[i] = float(b[i]) + float(ys[k]) * float(powers[i])

	for i in range(m):
		var row_d: Array = a[i]
		row_d[i] = float(row_d[i]) + RIDGE

	return _solve(a, b, m)


## Gaussian elimination with partial pivoting. Written out rather than borrowed
## because the ridge above is the only thing standing between this and a
## singular matrix, and a library that silently regularises more would hide the
## thrashing the artifact exists to show.
func _solve(a: Array, b: Array[float], n: int) -> Array[float]:
	for col in range(n):
		var piv: int = col
		var best: float = absf(float((a[col] as Array)[col]))
		for r in range(col + 1, n):
			var v: float = absf(float((a[r] as Array)[col]))
			if v > best:
				best = v
				piv = r
		if best < 1.0e-20:
			continue
		if piv != col:
			var tmp_row: Array = a[piv]
			a[piv] = a[col]
			a[col] = tmp_row
			var tmp_b: float = b[piv]
			b[piv] = b[col]
			b[col] = tmp_b
		var pivot_row: Array = a[col]
		var d: float = float(pivot_row[col])
		for r in range(col + 1, n):
			var row_r: Array = a[r]
			var f: float = float(row_r[col]) / d
			if f == 0.0:
				continue
			for c in range(col, n):
				row_r[c] = float(row_r[c]) - f * float(pivot_row[c])
			b[r] = float(b[r]) - f * float(b[col])

	var out: Array[float] = []
	for i in range(n):
		out.append(0.0)
	for i in range(n - 1, -1, -1):
		var row_i: Array = a[i]
		var s: float = float(b[i])
		for j in range(i + 1, n):
			s -= float(row_i[j]) * float(out[j])
		var dd: float = float(row_i[i])
		out[i] = 0.0 if absf(dd) < 1.0e-20 else s / dd
	return out


func _poly_eval(coef: Array[float], u: float) -> float:
	var t: float = 2.0 * u - 1.0
	var acc: float = 0.0
	for i in range(coef.size() - 1, -1, -1):
		acc = acc * t + float(coef[i])
	return acc


func _rmse(coef: Array[float], us: Array[float], ys: Array[float]) -> float:
	if us.is_empty():
		return 0.0
	var s: float = 0.0
	for k in range(us.size()):
		var e: float = _poly_eval(coef, float(us[k])) - float(ys[k])
		s += e * e
	var v: float = sqrt(s / float(us.size()))
	return v if is_finite(v) else ERR_CEIL * 4.0


## Both error curves, every degree, once. The whole trade-off is a build-time
## fact about these 24 points — the slider only chooses where to stand on it.
func _precompute_errors() -> void:
	_err_train.clear()
	_err_test.clear()
	_err_train.append(0.0)   # index 0 unused; degrees are 1-based
	_err_test.append(0.0)
	for d in range(1, 16):
		var coef: Array[float] = _fit(_train_u, _train_y, d)
		_err_train.append(_rmse(coef, _train_u, _train_y))
		_err_test.append(_rmse(coef, _test_u, _test_y))


# ── Bench ────────────────────────────────────────────────────────────

func _build_bench() -> void:
	var body := _grid_material(Color(0.30, 0.32, 0.38), Color(0.45, 0.50, 0.60), 0.5)
	var deck := MeshInstance3D.new()
	deck.name = "Deck"
	var dbox := BoxMesh.new()
	dbox.size = Vector3(deck_width, 0.06, deck_depth)
	deck.mesh = dbox
	deck.position = Vector3(0.0, deck_height - 0.03, 0.0)
	deck.material_override = body
	_own(deck)

	var leg_h: float = maxf(0.05, deck_height - 0.06)
	for xi in range(2):
		for zi in range(2):
			var lx: float = (-1.0 if xi == 0 else 1.0) * (deck_width * 0.5 - 0.10)
			var lz: float = (-1.0 if zi == 0 else 1.0) * (deck_depth * 0.5 - 0.09)
			var leg := MeshInstance3D.new()
			var lbox := BoxMesh.new()
			lbox.size = Vector3(0.07, leg_h, 0.07)
			leg.mesh = lbox
			leg.position = Vector3(lx, leg_h * 0.5, lz)
			leg.material_override = body
			_own(leg)


## A dark backplate the size of a plot, standing at the rear of the deck.
func _backplate(w: float, h: float) -> MeshInstance3D:
	var back := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w + 0.06, h + 0.10)
	back.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.035, 0.05)
	mat.roughness = 0.95
	back.material_override = mat
	back.position = Vector3(0.0, h * 0.5 + 0.01, -0.012)
	return back


func _line_material(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


# ── The main plot ────────────────────────────────────────────────────

func _u_to_local(u: float) -> float:
	return -plot_width * 0.5 + u * plot_width


func _v_to_local(v: float) -> float:
	return v * plot_height


func _build_plot() -> void:
	_plot_root = Node3D.new()
	_plot_root.name = "FitPlot"
	_plot_root.position = Vector3(-deck_width * 0.5 + plot_width * 0.5 + 0.10,
		deck_height + 0.04, -deck_depth * 0.5 + 0.05)
	_own(_plot_root)
	_plot_root.add_child(_backplate(plot_width, plot_height))

	# Baseline.
	var base := ImmediateMesh.new()
	base.surface_begin(Mesh.PRIMITIVE_LINES)
	base.surface_add_vertex(Vector3(-plot_width * 0.5, 0.0, 0.0))
	base.surface_add_vertex(Vector3(plot_width * 0.5, 0.0, 0.0))
	base.surface_end()
	var base_mi := MeshInstance3D.new()
	base_mi.mesh = base
	base_mi.material_override = _line_material(COL_AXIS, 0.6)
	_plot_root.add_child(base_mi)

	# Ground truth — never redrawn.
	var truth_mesh := ImmediateMesh.new()
	truth_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(curve_samples + 1):
		var u: float = float(i) / float(curve_samples)
		truth_mesh.surface_add_vertex(Vector3(_u_to_local(u), _v_to_local(_truth(u)), 0.001))
	truth_mesh.surface_end()
	var truth_mi := MeshInstance3D.new()
	truth_mi.name = "GroundTruth"
	truth_mi.mesh = truth_mesh
	truth_mi.material_override = _line_material(COL_TRUTH, 1.0)
	_plot_root.add_child(truth_mi)

	# Training samples — solid dots.
	for k in range(_train_u.size()):
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.016
		sm.height = 0.032
		sm.radial_segments = 10
		sm.rings = 6
		dot.mesh = sm
		dot.material_override = _line_material(COL_TRAIN, 2.4)
		dot.position = Vector3(_u_to_local(float(_train_u[k])),
			_v_to_local(float(_train_y[k])), 0.012)
		_plot_root.add_child(dot)

	# Held-out samples — flat rings, so the eye reads them as a different kind
	# of evidence and not as more of the same scatter.
	for k in range(_test_u.size()):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.013
		tm.outer_radius = 0.021
		tm.rings = 12
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = _line_material(COL_TEST, 2.0)
		ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		ring.position = Vector3(_u_to_local(float(_test_u[k])),
			_v_to_local(float(_test_y[k])), 0.014)
		_plot_root.add_child(ring)

	# The fit itself — the one thing the slider moves.
	_fit_mesh = ImmediateMesh.new()
	var fit_mi := MeshInstance3D.new()
	fit_mi.name = "Fit"
	fit_mi.mesh = _fit_mesh
	fit_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fit_mi.material_override = _line_material(COL_FIT, 2.6)
	_plot_root.add_child(fit_mi)

	_plot_root.add_child(_axis_label("15 samples · noisy · the only evidence there is",
		COL_TRUTH, 20, Vector3(-plot_width * 0.5, plot_height + 0.035, 0.0),
		HORIZONTAL_ALIGNMENT_LEFT))


func _emit_fit() -> void:
	if _fit_mesh == null:
		return
	var coef: Array[float] = _fit(_train_u, _train_y, degree)
	_fit_mesh.clear_surfaces()
	_fit_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(curve_samples + 1):
		var u: float = float(i) / float(curve_samples)
		var raw: float = _poly_eval(coef, u)
		if not is_finite(raw):
			raw = 0.0
		# Clamped a good way OUTSIDE the backplate, so an excursion leaves the
		# dark plate and reads as off-scale instead of drawing a flat ceiling.
		var v: float = clampf(raw, -0.32, 1.32)
		_fit_mesh.surface_add_vertex(Vector3(_u_to_local(u), _v_to_local(v), 0.008))
	_fit_mesh.surface_end()


# ── The error plot — where the concept actually lives ────────────────

func _deg_to_err_x(d: int) -> float:
	var t: float = (float(d) - 1.0) / 14.0
	return -err_width * 0.5 + t * err_width


func _err_to_y(e: float) -> float:
	return clampf(e / ERR_CEIL, 0.0, 1.0) * err_height


func _build_error_plot() -> void:
	_err_root = Node3D.new()
	_err_root.name = "ErrorPlot"
	_err_root.position = Vector3(deck_width * 0.5 - err_width * 0.5 - 0.12,
		deck_height + 0.10, -deck_depth * 0.5 + 0.05)
	_own(_err_root)
	_err_root.add_child(_backplate(err_width, err_height))

	# Frame: degree axis along the bottom, error axis up the left.
	var frame := ImmediateMesh.new()
	frame.surface_begin(Mesh.PRIMITIVE_LINES)
	frame.surface_add_vertex(Vector3(-err_width * 0.5, 0.0, 0.0))
	frame.surface_add_vertex(Vector3(err_width * 0.5, 0.0, 0.0))
	frame.surface_add_vertex(Vector3(-err_width * 0.5, 0.0, 0.0))
	frame.surface_add_vertex(Vector3(-err_width * 0.5, err_height, 0.0))
	frame.surface_end()
	var frame_mi := MeshInstance3D.new()
	frame_mi.mesh = frame
	frame_mi.material_override = _line_material(COL_AXIS, 0.6)
	_err_root.add_child(frame_mi)

	_err_root.add_child(_trace(_err_train, COL_TRAIN))
	_err_root.add_child(_trace(_err_test, COL_TEST))

	_train_marker = _err_marker(COL_TRAIN)
	_err_root.add_child(_train_marker)
	_test_marker = _err_marker(COL_TEST)
	_err_root.add_child(_test_marker)

	_err_root.add_child(_axis_label("error vs degree", Color(0.72, 0.78, 0.88), 18,
		Vector3(-err_width * 0.5, err_height + 0.030, 0.0), HORIZONTAL_ALIGNMENT_LEFT))
	# The ceiling is named, so a trace pinned to the top reads as "off this
	# chart" rather than as an error that politely stopped rising.
	_err_root.add_child(_axis_label("%.2f+" % ERR_CEIL, COL_AXIS, 15,
		Vector3(-err_width * 0.5 - 0.012, err_height - 0.012, 0.0), HORIZONTAL_ALIGNMENT_RIGHT))
	_err_root.add_child(_axis_label("0", COL_AXIS, 15,
		Vector3(-err_width * 0.5 - 0.012, -0.010, 0.0), HORIZONTAL_ALIGNMENT_RIGHT))
	_err_root.add_child(_axis_label("1", COL_AXIS, 16,
		Vector3(-err_width * 0.5, -0.035, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	_err_root.add_child(_axis_label("degree", COL_AXIS, 16,
		Vector3(0.0, -0.035, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	_err_root.add_child(_axis_label("15", COL_AXIS, 16,
		Vector3(err_width * 0.5, -0.035, 0.0), HORIZONTAL_ALIGNMENT_CENTER))

	# The two live figures, stacked beside the trace they belong to.
	_readout_train = _axis_label("", COL_TRAIN, 26,
		Vector3(err_width * 0.5 + 0.03, err_height * 0.62, 0.0), HORIZONTAL_ALIGNMENT_LEFT)
	_err_root.add_child(_readout_train)
	_readout_test = _axis_label("", COL_TEST, 26,
		Vector3(err_width * 0.5 + 0.03, err_height * 0.40, 0.0), HORIZONTAL_ALIGNMENT_LEFT)
	_err_root.add_child(_readout_test)
	_readout_gap = _axis_label("", COL_FIT, 22,
		Vector3(err_width * 0.5 + 0.03, err_height * 0.18, 0.0), HORIZONTAL_ALIGNMENT_LEFT)
	_err_root.add_child(_readout_gap)


func _trace(series: Array[float], c: Color) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for d in range(1, 16):
		im.surface_add_vertex(Vector3(_deg_to_err_x(d), _err_to_y(float(series[d])), 0.002))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _line_material(c, 1.8)
	return mi


func _err_marker(c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.014
	sm.height = 0.028
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _line_material(c, 3.0)
	return mi


func _axis_label(s: String, c: Color, size: int, pos: Vector3, align: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = s
	lbl.font_size = size
	lbl.outline_size = 3
	lbl.pixel_size = 0.001
	lbl.horizontal_alignment = align
	lbl.modulate = c
	lbl.position = pos
	return lbl


# ── Slider ───────────────────────────────────────────────────────────

func _build_slider() -> void:
	var scene: PackedScene = load(SLIDER_SCENE_PATH)
	if scene == null:
		return
	var s: Node3D = scene.instantiate()
	s.name = "DegreeSlider"
	s.position = Vector3(-deck_width * 0.5 + 0.34, deck_height + 0.055, deck_depth * 0.5 - 0.14)
	s.rotation_degrees = Vector3(-62.0, 0.0, 0.0)
	s.scale = Vector3(1.15, 1.15, 1.15)
	_own(s)
	_slider = s
	# In-tree first: SliderHorizontal resolves its own child nodes @onready, so
	# every setter below is a no-op if it is called before add_child.
	if s.has_method("set_param_name"):
		s.call("set_param_name", "DEGREE")
	if s.has_method("set_choices"):
		var names: Array = []
		for d in range(1, 16):
			names.append(str(d))
		s.call("set_choices", names)
	if s.has_method("set_normalized_value"):
		s.call("set_normalized_value", _degree_to_norm(degree))
	if s.has_signal("slider_moved"):
		s.connect("slider_moved", Callable(self, "_on_slider_moved"))


func _degree_to_norm(d: int) -> float:
	return clampf((float(d) - 1.0) / 14.0, 0.0, 1.0)


func _on_slider_moved(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var n: float = float(_slider.call("get_normalized_value"))
	var d: int = clampi(1 + int(round(n * 14.0)), 1, 15)
	if d == degree:
		return
	degree = d
	_refit()


# ── Plate ────────────────────────────────────────────────────────────

func _build_plate() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when
	# already in-tree, so driving them after the add costs one rebuild each.
	var ts := TextScreenScript.new()
	ts.name = "BenchPlate"
	ts.mode = 2                      # Mode.PAD
	ts.width_m = 0.34
	ts.position = Vector3(deck_width * 0.5 - 0.30, deck_height + 0.03, deck_depth * 0.5 - 0.13)
	if ts.has_method("set_text"):
		ts.call("set_text", "OVERFITTING", "the second number is the honest one")
	_own(ts)


# ── Refresh ──────────────────────────────────────────────────────────

func _refit() -> void:
	_emit_fit()
	var d: int = clampi(degree, 1, 15)
	var e_tr: float = float(_err_train[d]) if _err_train.size() > d else 0.0
	var e_te: float = float(_err_test[d]) if _err_test.size() > d else 0.0
	if _train_marker != null and is_instance_valid(_train_marker):
		_train_marker.position = Vector3(_deg_to_err_x(d), _err_to_y(e_tr), 0.010)
	if _test_marker != null and is_instance_valid(_test_marker):
		_test_marker.position = Vector3(_deg_to_err_x(d), _err_to_y(e_te), 0.010)
	if _readout_train != null and is_instance_valid(_readout_train):
		_readout_train.text = "train  %.3f" % e_tr
	if _readout_test != null and is_instance_valid(_readout_test):
		_readout_test.text = "held-out  %.3f" % _display_err(e_te)
	if _readout_gap != null and is_instance_valid(_readout_gap):
		_readout_gap.text = "deg %d  ·  gap %.3f" % [d, maxf(0.0, _display_err(e_te) - e_tr)]


## Held-out RMSE at the top degrees runs past any sane field width. The figure
## is capped at four characters so the readout never reflows; the trace beside
## it is already pinned to a labelled ceiling, so nothing is being hidden — the
## reader can see the number stopped and the divergence did not.
func _display_err(e: float) -> float:
	return minf(e, 9.999)


# ── Material ─────────────────────────────────────────────────────────

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


# ── Rebuild / grid config ────────────────────────────────────────────

## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and auto-grounds the artifact immediately after add_child, and a
## deferred rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_slider = null
	_fit_mesh = null
	_train_marker = null
	_test_marker = null
	_readout_train = null
	_readout_test = null
	_readout_gap = null
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_samples: int = sample_count
	var before_holdout: int = holdout_count
	var before_noise: float = noise
	var before_seed: int = build_seed
	var before_degree: int = degree

	if config_data.has("degree"):
		degree = clampi(int(config_data["degree"]), 1, 15)
	if config_data.has("samples"):
		sample_count = clampi(int(config_data["samples"]), 4, 60)
	if config_data.has("holdout"):
		holdout_count = clampi(int(config_data["holdout"]), 2, 40)
	if config_data.has("noise"):
		noise = clampf(float(config_data["noise"]), 0.0, 0.4)
	if config_data.has("seed"):
		build_seed = int(config_data["seed"])

	if not _built:
		return   # _ready has not run yet; it will build with these values.

	var world_changed: bool = (sample_count != before_samples
		or holdout_count != before_holdout
		or not is_equal_approx(noise, before_noise)
		or build_seed != before_seed)
	if world_changed:
		_rebuild_now()
		print("[OverfittingDemo] Config applied — rebuilt: samples=%d degree=%d" % [
			sample_count, degree])
		return
	if degree != before_degree:
		if _slider != null and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _degree_to_norm(degree))
		_refit()
