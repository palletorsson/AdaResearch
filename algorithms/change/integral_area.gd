# Integral Area — area under a curve as integration
#
# A curve renders as a strip. Beneath it, the area is painted progressively as a series of
# vertical strips that accumulate left-to-right — this IS the definite integral, animated.
#
# Pairs with `riemann_pump` (left/right/midpoint sums) and `slope_tangent_demo` (derivative).
# Together they say: derivative is the rate, integral is the accumulation, both live at change.
#
# @identity
# essence: vertical strips fill the area under a curve left to right — the definite integral painted as it accumulates
# desire: to make accumulation felt as a growing quantity, the mirror image of the derivative's instantaneous rate
# critical_parameter: curve × tally — which f is being gathered, and what form the gathered amount is put in front of you as
# triggers: the sweep advances every frame (sweep_speed, offset by sweep_phase), revealing one more strip of accumulated area
# emerges: the filled region reads as a single number growing — the player sees "how much has happened so far" rather than "how fast"
# needs: animated area fill + sweep marker [has]; a choice of f [has]; accumulation shown as region / blocks / scalar / function [has]; running numeric area total [missing]; grabbable sweep so the player sets the integral's upper limit [missing]
# relationships: pairs with riemann_pump (left/right/midpoint sums) and derivative_pair (the inverse operation, sharing the `curve` axis word for word); the accumulation half of the change sequence
# truth: the integral is accumulation — where the derivative asks how fast, the integral asks how much has gathered under the curve
# @qfep_term: F at accumulation — pointing forward to φΔE(S,t).

extends Node3D
class_name IntegralArea

# ── the curve axis ─────────────────────────────────────────────────────
# Shared with derivative_pair character for character: same word, same five
# values, same five functions of u in [0,1]. The two halves of the change
# cluster can therefore be COMPARED rather than merely contrasted — run both at
# `ramp` and you see a constant rate against a signed area that cancels to zero.
#
# Until now this artifact gathered one shape and one only, and it was the single
# shape for which the question "what happens when f goes negative?" cannot come
# up: a rectified hump, positive everywhere by construction. Three of the five
# members dip below the axis, so accumulation stops being "how much area" and
# becomes "how much, signed" — the strips hang beneath the bar and take away.
#   wave   sin(cx) + 0.35 sin(2cx). Four lobes alternating sign; the running
#          total climbs and falls and ends near where it started.
#   hump   one arch over the whole span — the SHIPPED curve, positive
#          throughout, the pure "area under" reading.
#   ramp   a straight line from -A to +A. The area cancels exactly: half the
#          gathering is a debt. The flattest counter-example calculus offers.
#   spike  a narrow bell. Almost all of the total arrives in a tenth of the span
#          and the accumulation curve is a single step.
#   step   a smoothed step (atan). Negative half, then positive half.
const CURVES: PackedStringArray = ["wave", "hump", "ramp", "spike", "step"]

# ── the tally axis ─────────────────────────────────────────────────────
# WHAT FORM the gathered amount takes in front of you — which is the claim about
# what an integral IS. Not a rate: every value here is legible in one still.
#   strips         the shipped build. 80 thin lit strips: accumulation as a
#                  REGION, fine enough that the sum reads as a filled area.
#   blocks         ten wide left-endpoint rectangles. The tops overshoot and
#                  undershoot the curve, so the picture admits it is an
#                  APPROXIMATION and shows exactly where it is wrong.
#   column         no region at all. One bar off the right edge whose height is
#                  the running total: accumulation as a SCALAR, the number the
#                  region was always standing in for.
#   antiderivative no region either. F(x) is drawn as a second curve across the
#                  same panel with a marker riding it: accumulation as a
#                  FUNCTION — the fundamental theorem, and the exact mirror of
#                  derivative_pair's claim that the rate is a curve in its own
#                  right.
# There is no `sheet` value. Seamless-vs-seamed at this span is a 2 mm gap on a
# 45 mm strip and would measure as noise; the continuous limit is reachable by
# raising `samples` instead.
const TALLIES: PackedStringArray = ["strips", "blocks", "column", "antiderivative"]

@export_category("Integral Settings")
## Stage-2 DNA axis — which function is being gathered. Shared, word for word, with derivative_pair.
@export_enum("wave", "hump", "ramp", "spike", "step") var curve: String = "hump"
## Stage-2 DNA axis — what form the accumulated amount is shown as.
@export_enum("strips", "blocks", "column", "antiderivative") var tally: String = "strips"
@export var curve_color: Color = Color(0.6, 0.85, 1.0, 1.0)
@export var area_color: Color = Color(0.35, 0.7, 0.95, 0.4)
@export var sweep_color: Color = Color(1.0, 0.9, 0.3, 1.0)
## Only drawn at tally=column and tally=antiderivative, where the running total has its own body.
@export var total_color: Color = Color(0.55, 1.0, 0.7, 1.0)
@export var samples: int = 80
@export var horizontal_span: float = 3.6
@export var amplitude: float = 0.7
@export var sweep_speed: float = 0.18
## Where the sweep starts, in [0,1). 0.0 is the shipped build — the frame opens with nothing
## gathered yet. A still taken at boot is therefore empty at 0.0; a capture fixture pins this.
@export var sweep_phase: float = 0.0

var _strip_nodes: Array = []
var _curve_strip: MeshInstance3D
var _sweep_marker: MeshInstance3D
var _total_bar: MeshInstance3D
var _total_marker: MeshInstance3D
var _t: float = 0.0

## Vertical extent of the curve, measured once per build so the sweep marker and
## the reference column never re-derive it.
var _lo: float = 0.0
var _hi: float = 0.0
var _mark_center: float = 0.0
## Cumulative area over the strip grid, and its peak magnitude, so column and
## antiderivative can be drawn at the same height as the curve itself.
var _cum: PackedFloat32Array = PackedFloat32Array()
var _cum_peak: float = 1.0

## True once _ready() has built once. apply_grid_config arrives AFTER _ready(),
## and must never rebuild before there is something to rebuild.
var _built: bool = false
## Every node THIS SCRIPT parented in. A rebuild frees exactly these — never
## get_children(), which would take the grid's own furniture with it.
var _created: Array[Node] = []


func _ready() -> void:
	curve = _pick(curve, CURVES, "hump")
	tally = _pick(tally, TALLIES, "strips")
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
	if config_data.has("tally"):
		var tl: String = _pick(str(config_data["tally"]), TALLIES, tally)
		if tl != tally:
			tally = tl
			changed = true
	if config_data.has("samples"):
		var s: int = maxi(2, int(config_data["samples"]))
		if s != samples:
			samples = s
			changed = true
	if config_data.has("horizontal_span"):
		var hs: float = float(config_data["horizontal_span"])
		if not is_equal_approx(hs, horizontal_span):
			horizontal_span = hs
			changed = true
	if config_data.has("amplitude"):
		var a: float = float(config_data["amplitude"])
		if not is_equal_approx(a, amplitude):
			amplitude = a
			changed = true
	if config_data.has("sweep_phase"):
		# Read live by _process — no rebuild needed, and none wanted.
		sweep_phase = float(config_data["sweep_phase"])
	if changed and _built:
		_rebuild_now()


func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta * sweep_speed
	var sweep_norm: float = fmod(_t + sweep_phase, 1.0)
	_update_strips(sweep_norm)
	_update_total(sweep_norm)
	_update_sweep_marker(sweep_norm)


# ── the curve family ───────────────────────────────────────────────────
# Copied from derivative_pair so the shared axis word means the shared shape.
# Everything is a function of u in [0,1]; members more naturally written against
# the swept coordinate map u to cx in [-TAU, TAU] first. `hump` is the shipped
# max(0, sin(u*PI)) * amplitude — the max() was a no-op on [0,1], so the default
# reproduces the old line exactly.

func _cx(u: float) -> float:
	return lerp(-TAU, TAU, u)


func _curve_y(u: float) -> float:
	var cx: float = _cx(u)
	match curve:
		"wave":
			return sin(cx) * amplitude + sin(cx * 2.0) * amplitude * 0.35
		"ramp":
			return amplitude * cx / TAU
		"spike":
			return amplitude * exp(-cx * cx * 0.5)
		"step":
			return amplitude * atan(cx * 2.5) * 0.6366198
		_:
			return sin(u * PI) * amplitude


# ── build ──────────────────────────────────────────────────────────────

func _build_all() -> void:
	_strip_nodes.clear()
	_curve_strip = null
	_sweep_marker = null
	_total_bar = null
	_total_marker = null
	_measure()
	_build_axes()
	_build_curve()
	if tally == "strips" or tally == "blocks":
		_build_area_strips()
	elif tally == "column":
		_build_total_column()
	elif tally == "antiderivative":
		_build_antiderivative()
	_build_sweep_marker()


## Vertical extent and running area, both over a grid dense enough that `hump`
## measures its analytic peak exactly (u = 0.5 is on the 241-sample grid), so the
## sweep marker keeps the shipped size of amplitude + 0.1 to the byte.
func _measure() -> void:
	_hi = -1.0e20
	_lo = 1.0e20
	for i in 241:
		var u_scan: float = float(i) / 240.0
		var y_scan: float = _curve_y(u_scan)
		_hi = maxf(_hi, y_scan)
		_lo = minf(_lo, y_scan)
	_cum = PackedFloat32Array()
	_cum.resize(samples + 1)
	_cum[0] = 0.0
	_cum_peak = 0.00001
	var run: float = 0.0
	var du: float = 1.0 / float(samples)
	for i in samples:
		var u_bin: float = (float(i) + 0.5) * du
		run += _curve_y(u_bin) * du
		_cum[i + 1] = run
		_cum_peak = maxf(_cum_peak, absf(run))


func _build_axes() -> void:
	var floor_bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(horizontal_span + 0.2, 0.02, 0.02)
	floor_bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4, 1.0)
	floor_bar.material_override = mat
	_own(floor_bar)


func _build_curve() -> void:
	_curve_strip = MeshInstance3D.new()
	_curve_strip.name = "Curve"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var t_norm: float = float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, t_norm)
		imm.surface_add_vertex(Vector3(x, _curve_y(t_norm), 0.0))
	imm.surface_end()
	_curve_strip.mesh = imm
	_curve_strip.material_override = _lit(curve_color, 1.3, true)
	_own(_curve_strip)


## The region. `strips` is the shipped comb of samples midpoint bars; `blocks` is
## a tenth as many, wider apart, sampled at the LEFT edge so the flat tops visibly
## miss the curve — the same picture with its approximation admitted.
func _build_area_strips() -> void:
	var count: int = samples
	var gap: float = 0.95
	var at_left: bool = false
	if tally == "blocks":
		count = maxi(3, samples / 8)
		gap = 0.88
		at_left = true
	var strip_width: float = horizontal_span / float(count)
	for i in count:
		var u_c: float = (float(i) + 0.5) / float(count)
		var u_h: float = u_c
		if at_left:
			u_h = float(i) / float(count)
		var height: float = _curve_y(u_h)
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(strip_width * gap, maxf(absf(height), 0.001), 0.02)
		strip.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = area_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = area_color
		mat.emission_energy_multiplier = 0.0  # invisible until swept
		strip.material_override = mat
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, u_c)
		strip.position = Vector3(x, height * 0.5, -0.01)
		_own(strip)
		_strip_nodes.append(strip)


## Accumulation as a scalar: one bar off the right edge, grown from the axis, read
## against a dim reference bar at the total over the whole span.
func _build_total_column() -> void:
	var full: float = _accum_y(1.0)
	var reference := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(0.26, maxf(absf(full), 0.001), 0.02)
	reference.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(total_color.r, total_color.g, total_color.b, 0.18)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	reference.material_override = rmat
	reference.position = Vector3(horizontal_span * 0.5 + 0.3, full * 0.5, -0.02)
	_own(reference)
	_total_bar = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 1.0, 0.12)
	_total_bar.mesh = box
	_total_bar.material_override = _lit(total_color, 1.0, false)
	_total_bar.position = Vector3(horizontal_span * 0.5 + 0.3, 0.0, 0.0)
	_total_bar.scale = Vector3(1.0, 0.001, 1.0)
	_own(_total_bar)


## Accumulation as a function: F(x) drawn across the same panel, scaled so its peak
## matches the curve's own amplitude, with a marker riding it at the sweep.
func _build_antiderivative() -> void:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in samples + 1:
		var u_f: float = float(i) / float(samples)
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, u_f)
		imm.surface_add_vertex(Vector3(x, _accum_y(u_f), 0.0))
	imm.surface_end()
	mi.mesh = imm
	mi.material_override = _lit(total_color, 1.3, true)
	_own(mi)
	_total_marker = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	_total_marker.mesh = sphere
	_total_marker.material_override = _lit(total_color, 1.6, false)
	_own(_total_marker)


func _build_sweep_marker() -> void:
	var lo_c: float = minf(_lo, 0.0)
	var hi_c: float = maxf(_hi, 0.0)
	_mark_center = (hi_c + lo_c) * 0.5
	_sweep_marker = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.03, (hi_c - lo_c) + 0.1, 0.05)
	_sweep_marker.mesh = box
	_sweep_marker.material_override = _lit(sweep_color, 2.0, true)
	_own(_sweep_marker)


# ── run ────────────────────────────────────────────────────────────────

func _update_strips(sweep_norm: float) -> void:
	var count: int = _strip_nodes.size()
	if count == 0:
		return
	var threshold_idx: int = int(sweep_norm * float(count))
	for i in count:
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


func _update_total(sweep_norm: float) -> void:
	var h: float = _accum_y(sweep_norm)
	if _total_bar != null:
		_total_bar.scale = Vector3(1.0, maxf(absf(h), 0.001), 1.0)
		_total_bar.position.y = h * 0.5
	if _total_marker != null:
		var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, sweep_norm)
		_total_marker.position = Vector3(x, h, 0.0)


func _update_sweep_marker(sweep_norm: float) -> void:
	var x: float = lerp(-horizontal_span * 0.5, horizontal_span * 0.5, sweep_norm)
	_sweep_marker.position = Vector3(x, _mark_center, 0.0)


## Running area at u, in drawing units: scaled so the largest magnitude the total
## ever reaches is one amplitude, the same height the curve itself is drawn at.
func _accum_y(u: float) -> float:
	if _cum.size() < 2:
		return 0.0
	var top: int = _cum.size() - 1
	var f: float = clampf(u, 0.0, 1.0) * float(top)
	var i0: int = clampi(int(f), 0, top)
	var i1: int = mini(i0 + 1, top)
	var v: float = lerpf(_cum[i0], _cum[i1], f - float(i0))
	return v / _cum_peak * amplitude


# ── housekeeping ───────────────────────────────────────────────────────

func _lit(c: Color, energy: float, unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


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
