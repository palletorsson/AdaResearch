# FTC Bridge — the Fundamental Theorem of Calculus made spatial
#
# An arched bridge structure. The deck IS the antiderivative f: its two ends rest on the
# pillars at a and b, so the height difference between the pillar tops is literally
# f(b) − f(a). Across the span runs the beam label ∫ f'(x) dx = f(b) − f(a), and a glowing
# pulse runs the deck from a to b repeatedly.
#
# This is the *capstone* of the change sequence — the unifying claim that derivative and
# integral are inverse operations. Sets up the entire QFEP rate-term Δ(S,t).
#
# @qfep_term: F at the boundary, pointing at Δ(S,t) as the bridge.
#
# @identity
# essence: an arched deck whose shape is the antiderivative f, standing on pillars at a and b whose height difference is f(b) − f(a), with the rate f' and its signed area drawn underneath
# desire: to stage the Fundamental Theorem of Calculus as a spatial crossing — the two directions of change meeting over one arch
# critical_parameter: curve — which antiderivative the deck traces, and therefore whether the theorem this bridge is labelled with says anything at all
# triggers: _ready() builds pillars, deck, pulse marker, the FTC label and whatever evidence is asked for; _process runs the pulse from a to b, naming both in turn
# emerges: derivative and integral shown as inverse operations — the capstone that unifies the whole change sequence
# needs: two pillars + arch [present]; running pulse marker [present]; FTC label [present]; class_name FTCBridge [present]; @identity [present, 2026-07-12]
# relationships: the synthesis of partial_derivative_terrain (slope) and riemann_pump (accumulation); shares the `curve` axis word for word with integral_area and derivative_pair, so the same f can be met three times across the sequence; points forward to QFEP's rate-term Δ(S,t)
# truth: differentiation and integration are the same bridge walked in opposite directions — to accumulate a rate is to recover the thing that was changing.

extends Node3D
class_name FTCBridge

## ── the curve axis ────────────────────────────────────────────────────────────────────
## WHICH ANTIDERIVATIVE THE DECK IS. The word and its five values are taken character for
## character from integral_area and derivative_pair, the two artifacts this one is the
## capstone of, and the five shapes are the same five functions of u in [0,1] — so a player
## can meet `ramp` as a rate in one room, as an accumulation in the next, and as a bridge
## here. Every member is smooth on [0,1], including `step`, which is an atan and not a jump;
## a genuinely discontinuous f would be a counter-example to the theorem this deck carries,
## not an instance of it, and the family does not offer one.
##
## THE FINDING THAT MADE THIS AXIS NECESSARY. The shipped deck is a symmetric parabola, so
## its two ends sit at the SAME height: f(a) = f(b), and the right-hand side of the equation
## painted on the beam is exactly zero. This bridge has been labelled with a theorem that,
## on its own geometry, reads 0 = 0. `hump` keeps that case, because it is the shipped one
## and 26 maps are standing on it — but `ramp` and `step` are decks whose ends are at
## different heights, and only there does the beam say something.
##   wave   sin(cx) + 0.35 sin(2cx). Four lobes; the deck returns to its start height, so
##          the accumulated rate cancels to nothing over the full span.
##   hump   one arch over the whole span — THE SHIPPED DECK, a parabola, both ends level.
##   ramp   a straight climb from −A to +A. The plainest non-degenerate case: a constant
##          rate underneath, a constant difference across.
##   spike  a narrow bell. Nearly all the accumulation arrives in a tenth of the span and
##          the two ends are level again.
##   step   a smoothed step (atan). Down at a, up at b: the largest honest difference here.
##
## ── the evidence axis ─────────────────────────────────────────────────────────────────
## HOW MUCH OF THE THEOREM'S WORKING STANDS ON THE BRIDGE. Family word, taken character for
## character. The three-value list is the one zeno_staircase already declares in this same
## registry file, and it is three rather than four ON PURPOSE: the family's fourth rung,
## `axiom`, is "the rule stated instead of drawn", and the rule is ALREADY painted on this
## artifact's beam at the shipped default. Declaring `axiom` here would have shipped a
## second photograph of `result` under a different word — the two-values-identical fault,
## bought in advance. That refusal is bouncing_ball's, made of a different ladder.
##   result    the claim asserted and nothing computed — THE SHIPPED BUILD.
##   trace     the left-hand side drawn: f' plotted under the deck with its SIGNED area
##             shaded, strips hanging below the axis where the rate is negative.
##   longhand  both sides, equated: that area, plus the two endpoint heights read off a
##             common datum, the difference bracketed between them, and the numbers.

@export_category("Bridge Settings")
## Stage-2 DNA axis — which antiderivative the deck traces. Shared, word for word, with integral_area and derivative_pair.
@export_enum("wave", "hump", "ramp", "spike", "step") var curve: String = "hump"
## Stage-2 DNA axis — how much of the theorem's working stands on the bridge.
@export_enum("result", "trace", "longhand") var evidence: String = "result"
@export var pillar_color: Color = Color(0.5, 0.55, 0.7, 1.0)
@export var arch_color: Color = Color(0.95, 0.8, 0.45, 1.0)
@export var pulse_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var bridge_span: float = 3.0
@export var pillar_height: float = 1.6
@export var arch_segments: int = 24
@export var pulse_speed: float = 0.4

const CURVES: PackedStringArray = ["wave", "hump", "ramp", "spike", "step"]
const EVIDENCE: PackedStringArray = ["result", "trace", "longhand"]

## The shipped arch's peak height above the pillar tops. Every member of the curve family is
## scaled to this same amplitude, so the deck's vertical extent stays in the neighbourhood
## the 26 shipped placements were laid out around.
const ARCH_H: float = 0.7
## Where the rate plot's zero line sits, and how tall its tallest lobe is drawn. Both are
## under the deck and above the floor for every member of the family, and neither exists at
## the shipped default.
const RATE_BASE_Y: float = 0.62
const RATE_AMP: float = 0.34
const RATE_STRIPS: int = 40
## Sample count for the numeric integral under `longhand`. Trapezoid, which is exact enough
## that the printed total and the printed difference agree to the two decimals shown.
const QUAD_SAMPLES: int = 512

var _pulse_marker: MeshInstance3D
var _arch_segments_nodes: Array = []
var _t: float = 0.0


func _ready() -> void:
	curve = _pick(curve, CURVES, "hump")
	evidence = _pick(evidence, EVIDENCE, "result")
	_build_all()


func _build_all() -> void:
	_build_pillars()
	_build_arch()
	_build_pulse()
	_build_label()
	_build_evidence()


## The two numeric knobs keep their pre-promotion behaviour exactly: assigned, and never
## rebuilt for, because nothing rebuilt for them before. The two axis words DO rebuild —
## but only when the word is in the allow-list, only when it actually differs from the word
## already held, and only once _ready has built the scene a first time. No placement passes
## any key to this token today (all 26 are bare `ftc_bridge` / `ftc_bridge:0:0`), so this
## path is unreachable from any map that exists.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("bridge_span"):
		bridge_span = float(config_data["bridge_span"])
	if config_data.has("pillar_height"):
		pillar_height = float(config_data["pillar_height"])
	var dirty: bool = false
	if config_data.has("curve"):
		var c: String = _pick(str(config_data["curve"]), CURVES, curve)
		if c != curve:
			curve = c
			dirty = true
	if config_data.has("evidence"):
		var e: String = _pick(str(config_data["evidence"]), EVIDENCE, evidence)
		if e != evidence:
			evidence = e
			dirty = true
	if dirty and is_node_ready():
		_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	if allowed.has(value):
		return value
	return fallback


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pulse_marker = null
	_arch_segments_nodes.clear()
	_build_all()


func _process(delta: float) -> void:
	_t += delta * pulse_speed
	if _pulse_marker == null:
		return
	_update_pulse()


# ── the curve family ──────────────────────────────────────────────────────────────────
# Copied from integral_area so the shared axis word means the shared shape. Everything is a
# function of u in [0,1]; members more naturally written against the swept coordinate map u
# to cx in [-TAU, TAU] first. `hump` is the shipped parabola ARCH_H * (1 − (2u−1)^2), NOT
# the siblings' sin(u*PI) — the word names one arch over the whole span, and each artifact's
# hump is its own shipped curve, which is how integral_area's own hump was defined too.

func _cx(u: float) -> float:
	return lerp(-TAU, TAU, u)


## Deck height ABOVE the pillar-top datum, in metres. Zero at both ends for hump / wave /
## spike, signed for ramp / step.
func _curve_h(u: float) -> float:
	var cx: float = _cx(u)
	match curve:
		"wave":
			return sin(cx) * ARCH_H + sin(cx * 2.0) * ARCH_H * 0.35
		"ramp":
			return ARCH_H * cx / TAU
		"spike":
			return ARCH_H * exp(-cx * cx * 0.5)
		"step":
			return ARCH_H * atan(cx * 2.5) * 0.6366198
		_:
			return ARCH_H * (1.0 - pow(2.0 * u - 1.0, 2.0))


## d(deck)/dx, in metres of rise per metre of span. Central difference — the family members
## are all smooth, and asking the geometry beats hand-transcribing five derivatives.
func _curve_slope(u: float) -> float:
	var e: float = 0.0005
	var u0: float = clampf(u - e, 0.0, 1.0)
	var u1: float = clampf(u + e, 0.0, 1.0)
	var du: float = u1 - u0
	if du <= 0.0:
		return 0.0
	return (_curve_h(u1) - _curve_h(u0)) / (du * bridge_span)


func _arch_point(t_norm: float) -> Vector3:
	var x: float = lerp(-bridge_span * 0.5, bridge_span * 0.5, t_norm)
	var y: float = pillar_height + _curve_h(t_norm)
	return Vector3(x, y, 0.0)


func _build_pillars() -> void:
	# The pillars carry the deck, so their tops are f(a) and f(b). At `hump` both ends of the
	# curve are zero and each pillar is exactly the shipped BoxMesh(0.25, pillar_height, 0.25)
	# at y = pillar_height * 0.5 — the same two numbers, from the same expression.
	for i in 2:
		var u: float = float(i)
		var h: float = pillar_height + _curve_h(u)
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, h, 0.25)
		pillar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = pillar_color
		mat.roughness = 0.6
		pillar.material_override = mat
		pillar.position = Vector3(lerp(-bridge_span * 0.5, bridge_span * 0.5, u), h * 0.5, 0.0)
		add_child(pillar)


func _build_arch() -> void:
	# A series of small box segments approximating the deck.
	for i in arch_segments:
		var t0: float = float(i) / float(arch_segments)
		var t1: float = float(i + 1) / float(arch_segments)
		var p0 := _arch_point(t0)
		var p1 := _arch_point(t1)
		var center := (p0 + p1) * 0.5
		var length := (p1 - p0).length()
		var dir := (p1 - p0).normalized()
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.18, 0.18, length)
		seg.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = arch_color
		mat.emission_enabled = true
		mat.emission = arch_color
		mat.emission_energy_multiplier = 0.6
		seg.material_override = mat
		seg.position = center
		# `wave` reaches a slope of about 5 near the middle of the span, which is 11 degrees
		# off vertical — close enough to Vector3.UP that the up-hint is worth guarding. The
		# shipped hump never reaches 1.4, so this branch is dead at the default.
		var up_hint: Vector3 = Vector3.UP
		if absf(dir.y) > 0.995:
			up_hint = Vector3.BACK
		seg.transform.basis = Basis.looking_at(dir, up_hint)
		add_child(seg)
		_arch_segments_nodes.append(seg)


func _build_pulse() -> void:
	_pulse_marker = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	_pulse_marker.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pulse_color
	mat.emission_enabled = true
	mat.emission = pulse_color
	mat.emission_energy_multiplier = 2.5
	_pulse_marker.material_override = mat
	add_child(_pulse_marker)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "∫ f'(x) dx  =  f(b) − f(a)"
	label.font_size = 36
	label.outline_size = 8
	label.modulate = arch_color
	# Kept as the shipped literal rather than re-derived from the deck's peak: at `hump` the
	# two are the same number, and short-circuiting is what stops a future change to ARCH_H
	# from quietly moving the beam in 26 rooms.
	label.position = Vector3(0, pillar_height + 1.05, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	# Endpoint labels, riding their own pillar tops.
	for i in 2:
		var u: float = float(i)
		var l := Label3D.new()
		l.text = "b" if i == 1 else "a"
		l.font_size = 28
		l.modulate = pillar_color
		l.position = Vector3(
			lerp(-bridge_span * 0.5, bridge_span * 0.5, u),
			pillar_height + _curve_h(u) + 0.15,
			0.3
		)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(l)


func _update_pulse() -> void:
	# Pulse runs left → right repeatedly. fmod handles wrap.
	var t_norm: float = fmod(_t, 1.0)
	_pulse_marker.position = _arch_point(t_norm)
	# As the pulse passes each segment, light it up briefly.
	for i in _arch_segments_nodes.size():
		var node: MeshInstance3D = _arch_segments_nodes[i]
		var mat := node.material_override as StandardMaterial3D
		if not mat:
			continue
		var seg_t: float = (float(i) + 0.5) / float(arch_segments)
		var d: float = abs(t_norm - seg_t)
		var energy: float = 0.6 + max(0.0, 1.5 - d * 12.0)
		mat.emission_energy_multiplier = energy


# ── evidence ──────────────────────────────────────────────────────────────────────────
# Nothing below this line runs at the shipped default: `result` returns before a single node
# is constructed, so the scene tree and the measured AABB are what they were.

func _build_evidence() -> void:
	if evidence == "result":
		return
	_build_rate_plot()
	if evidence == "longhand":
		_build_difference_reading()


## The LEFT-HAND SIDE. f' plotted on a zero line under the deck, with the region between the
## line and the curve filled — strips standing above where the rate is positive, hanging
## below where it is negative. At `hump` the two halves are mirror images and the shaded
## total is nothing, which is the same nothing the pillar tops report.
func _build_rate_plot() -> void:
	var peak: float = 0.0
	for i in RATE_STRIPS + 1:
		peak = maxf(peak, absf(_curve_slope(float(i) / float(RATE_STRIPS))))
	if peak <= 0.0001:
		peak = 1.0
	# Normalised per curve so the rate always fills its band. What the still is asked to read
	# here is the SIGN pattern and whether the areas cancel, not the magnitude — and the
	# magnitude is printed under `longhand` anyway.
	var scale_y: float = RATE_AMP / peak
	# The zero line the strips are measured from.
	var axis_bar := MeshInstance3D.new()
	var abox := BoxMesh.new()
	abox.size = Vector3(bridge_span + 0.2, 0.018, 0.018)
	axis_bar.mesh = abox
	axis_bar.material_override = _flat_mat(Color(0.45, 0.46, 0.52, 1.0), 0.0)
	axis_bar.position = Vector3(0.0, RATE_BASE_Y, 0.0)
	add_child(axis_bar)
	var strip_w: float = bridge_span / float(RATE_STRIPS)
	var pos_col := Color(0.35, 0.7, 0.95, 1.0)
	var neg_col := Color(0.95, 0.45, 0.35, 1.0)
	for i in RATE_STRIPS:
		var u: float = (float(i) + 0.5) / float(RATE_STRIPS)
		var v: float = _curve_slope(u) * scale_y
		if absf(v) < 0.0005:
			continue
		var strip := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(strip_w * 0.9, absf(v), 0.02)
		strip.mesh = sbox
		strip.material_override = _flat_mat(pos_col if v > 0.0 else neg_col, 0.9)
		strip.position = Vector3(
			lerp(-bridge_span * 0.5, bridge_span * 0.5, u),
			RATE_BASE_Y + v * 0.5,
			0.0
		)
		add_child(strip)
	# The rate itself as a line over its own shading.
	var line := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in RATE_STRIPS + 1:
		var u: float = float(i) / float(RATE_STRIPS)
		imm.surface_add_vertex(Vector3(
			lerp(-bridge_span * 0.5, bridge_span * 0.5, u),
			RATE_BASE_Y + _curve_slope(u) * scale_y,
			0.03
		))
	imm.surface_end()
	line.mesh = imm
	line.material_override = _flat_mat(Color(1.0, 0.9, 0.3, 1.0), 1.4)
	add_child(line)
	var tag := _plot_label(Color(1.0, 0.9, 0.3, 1.0))
	tag.text = "f'(x)"
	tag.font_size = 26
	tag.position = Vector3(-bridge_span * 0.5 - 0.22, RATE_BASE_Y, 0.1)
	add_child(tag)


## The RIGHT-HAND SIDE, and the two of them equated. Both pillar tops are dropped onto one
## datum so the difference between them is a length you can look at, and the same quantity
## is printed twice — once as the accumulated area, once as f(b) − f(a).
func _build_difference_reading() -> void:
	var fa: float = _curve_h(0.0)
	var fb: float = _curve_h(1.0)
	var datum: float = pillar_height + minf(fa, fb)
	var x_read: float = bridge_span * 0.5 + 0.30
	# Two ticks at the endpoint heights, carried out past the right pillar.
	for pair in [[fa, "f(a)"], [fb, "f(b)"]]:
		var h: float = float(pair[0])
		var tick := MeshInstance3D.new()
		var tbox := BoxMesh.new()
		tbox.size = Vector3(0.30, 0.015, 0.015)
		tick.mesh = tbox
		tick.material_override = _flat_mat(pillar_color, 0.6)
		tick.position = Vector3(x_read, pillar_height + h, 0.0)
		add_child(tick)
		var tl := _plot_label(pillar_color)
		tl.text = str(pair[1])
		tl.font_size = 22
		tl.position = Vector3(x_read + 0.24, pillar_height + h, 0.0)
		add_child(tl)
	# The difference itself, as a bar spanning the two ticks.
	var diff: float = fb - fa
	var bar := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(0.035, maxf(absf(diff), 0.02), 0.035)
	bar.mesh = bbox
	bar.material_override = _flat_mat(Color(0.55, 1.0, 0.7, 1.0), 1.1)
	bar.position = Vector3(x_read, datum + absf(diff) * 0.5, 0.0)
	add_child(bar)
	# Both sides as numbers. The integral is quadrature over the same slope function the
	# strips were drawn from, so agreement here is a statement about the geometry rather
	# than a constant typed in beside it.
	var total: float = _integrate_slope()
	var readout := _plot_label(Color(0.55, 1.0, 0.7, 1.0))
	readout.text = "∫ f' dx = %+.2f     f(b) − f(a) = %+.2f" % [total, diff]
	readout.font_size = 26
	readout.position = Vector3(0.0, datum - 0.30, 0.4)
	add_child(readout)


## Trapezoid rule over dx, which is exactly the area the strips above are shading.
func _integrate_slope() -> float:
	var total: float = 0.0
	var dx: float = bridge_span / float(QUAD_SAMPLES)
	for i in QUAD_SAMPLES:
		var u0: float = float(i) / float(QUAD_SAMPLES)
		var u1: float = float(i + 1) / float(QUAD_SAMPLES)
		total += (_curve_slope(u0) + _curve_slope(u1)) * 0.5 * dx
	return total


func _flat_mat(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = energy
	return mat


func _plot_label(c: Color) -> Label3D:
	var l := Label3D.new()
	l.font_size = 24
	l.outline_size = 6
	l.modulate = c
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l
