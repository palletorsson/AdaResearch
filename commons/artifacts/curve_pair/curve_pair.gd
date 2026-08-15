extends Node3D
class_name CurvePair

## curve_pair — the family's five words are a chain, and the one word they disagree about
## is the word the chain hangs on.
##
## THE FAMILY. Three artifacts in commons/artifacts/registry/change.json declare an axis
## called `curve`, and all three carry the same five words: derivative_pair (gd:44, 63),
## integral_area (gd:43, 68), ftc_bridge (gd:66, 77). THE BRIEF SAID two orders — that
## derivative_pair and ftc_bridge declare wave·hump·ramp·spike·step while integral_area
## declares hump·wave·ramp·spike·step. In the CODE there is one order. All three
## `@export_enum` lines and all three `const CURVES` are ("wave","hump","ramp","spike",
## "step") character for character.
##
## THE SECOND ORDER IS THE TOOL'S. tools/apply_dna_block.py:130-134 moves the export
## DEFAULT to the front of every list it generates — "Default first, then the rest in
## source order — a sweep reads left to right and the legacy lineage should be the leftmost
## tile" — and artifact_dna_critic.py:73 depends on that. derivative_pair defaults to
## `wave`, already first, so its block matches the code; integral_area defaults to `hump`,
## so its block starts with hump; ftc_bridge's block is hand-written and keeps the source
## order though it defaults to `hump` too. One rule, three different-looking blocks. THIS
## ARTIFACT REPRODUCED IT while being built — apply_dna_block wrote `curve` here hump-first
## for the same reason, and it is left that way. So the registry's axis order is a fact
## about the DEFAULT and not about the vocabulary, and reading it as vocabulary drift is a
## category error a synthesis could have shipped.
##
## Three separate scenes, three separate scripts, three class_names — DerivativePair,
## IntegralArea, FTCBridge. No two are one scene under two names.
##
## Defaults, read off the enums: derivative_pair `wave`, integral_area `hump`, ftc_bridge
## `hump`. Two of three ship `hump`. The brief had that backwards too.
##
## WHAT THE FIVE WORDS ARE, as functions of cx = lerp(-TAU, TAU, u) — identical
## expressions in all three members except the fifth line:
##   wave   sin(cx) + 0.35 sin(2cx)            all three, character for character
##   ramp   cx / TAU                           all three
##   spike  exp(-cx² / 2)                      all three — a GAUSSIAN, not a triangle
##   step   (2/pi) atan(2.5 cx)                all three — an ARCTANGENT, not a Heaviside
##   hump   sin(u pi)          derivative_pair gd:160, integral_area gd:186
##          1 - (2u - 1)²      ftc_bridge gd:186 — a PARABOLA, and its own comment
##                             (gd:164-166) says so: "NOT the siblings' sin(u*PI)".
##
## THE ARGUMENT, and it is not the one the brief proposed. The brief said the five values
## are closed under d/dx — hump' is wave-ish, ramp' is a step, step' is a spike. Two of
## those three are false in the code:
##   · ramp' = 1/TAU. A CONSTANT. A flat line, and a flat line is not one of the five
##     words. This is the link the list does not have.
##   · hump' under the SIBLINGS' half-sine is (1/4)cos(u pi) — a falling half-cosine, also
##     not one of the five words.
##   · step' = (2/pi)·2.5/(1 + 6.25 cx²), a Lorentzian bump. `spike` is a Gaussian. Same
##     shape class (one hump, centred, even, decaying), different profile: the Lorentzian
##     is half-height at |cx| = 0.40 and the Gaussian at |cx| = 1.18, so the derivative of
##     a step is a NARROWER spike than the spike. This link holds as a shape and not as an
##     equation, which is exactly what a still can show and an equation cannot.
## And one link that the brief did not ask for is EXACT, on one condition:
##   · under ftc_bridge's parabola, hump' = -2cx/TAU² = -(2/TAU)·ramp, at every point, to
##     the last bit. The derivative of the hump IS the ramp, upside down, scaled by
##     2/TAU = 0.3183. Equivalently the integral of the ramp is the hump, upside down.
## So: THE ONE WORD THE FAMILY DISAGREES ABOUT IS THE ONE WORD THAT DECIDES WHETHER THE
## FAMILY IS A CHAIN. Under ftc_bridge's dialect hump—ramp is a link; under the siblings'
## it is not. This artifact takes the parabola, on the record, because it is the reading
## under which the vocabulary means something and the disagreement is worth having.
## The whole list is therefore: two links (hump→ramp exact, step→spike by shape), one
## eigen-ish member (wave' is again a wave, cos cx + 0.7 cos 2cx — a wave with its
## harmonic doubled, so not the same wave), and one word whose derivative has no name.
## The list is a CHAIN WITH GAPS, and the gaps are where the vocabulary ran out.
##
## HOW IT IS BUILT. One curve at a time as real geometry: hexagonal tubes along x on
## horizontal rails, one rail per reading. GOING DOWN A RAIL IS DIFFERENTIATING AND GOING
## UP IS INTEGRATING — that is the object's whole grammar, and every operation is a
## contiguous window on the same three-rail stack (integral · function · rate).
## Nothing animates, nothing is printed, nothing is random.

## WHICH FUNCTION IS ON THE TABLE. The family's five words, the family's one order.
##   wave   sin(cx) + 0.35 sin(2cx) — two periods and a harmonic. Four turning points.
##   hump   1 - (2u-1)², ftc_bridge's parabola. One turning point, ends level.
##   ramp   cx/TAU. No turning point at all, and its rate is the one flat rail here.
##   spike  exp(-cx²/2) — a Gaussian. Nearly all of it inside a fifth of the span.
##   step   (2/pi) atan(2.5 cx) — smooth, so it has a derivative; it is not a jump.
@export_enum("wave", "hump", "ramp", "spike", "step") var curve: String = "hump":
	set(v):
		curve = v
		if is_inside_tree():
			_rebuild()

## WHOSE READING OF IT. One value per member of the family, named for what is built.
##   pair    two rails — f above, f' below (derivative_pair's `stacked`, gd:223-235, its
##           own words: "Top: y = f(x). Bottom: y = f'(x)"). White beads mark every place
##           f turns and, on the rail beneath, the place f' crosses its datum — the same
##           x, joined by a dowel you could hang a plumb line from. derivative_pair's
##           claim, gd:15: "where the top peaks the bottom crosses zero", as a body.
##   area    one rail — f alone, filling the whole envelope, with the signed area under
##           it built as a SOLID slab 50 mm thick, standing on the datum where f is
##           positive and hanging beneath it where f is negative. integral_area's subject.
##           Continuous, not strips: strips are that artifact's second axis, not this one's.
##   bridge  all three rails — the integral on top, f in the middle, f' at the bottom —
##           with f's slab under it and BOTH joins beaded. ftc_bridge's subject, the
##           theorem: the top rail turns exactly where the middle rail crosses (d of the
##           integral is the function) and the slab under the middle rail is the rise of
##           the top one (the integral of the function is the integral).
@export_enum("pair", "area", "bridge") var operation: String = "pair":
	set(v):
		operation = v
		if is_inside_tree():
			_rebuild()

## One curve, or all five in a row at the same operation. NOT PART OF EITHER AXIS — an
## all-rungs value inside an axis makes capture_config_sweep union a six-metre row's AABB
## with every single and photograph the singles as specks. The registry fixture pins
## `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

const CURVES: PackedStringArray = ["wave", "hump", "ramp", "spike", "step"]
const OPERATIONS: PackedStringArray = ["pair", "area", "bridge"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## Roles, top of the stack downward. Each is the derivative of the one above it.
const ROLE_INTEGRAL: int = 2
const ROLE_FUNCTION: int = 0
const ROLE_RATE: int = 1

# ── the panel, metres ──────────────────────────────────────────────────────────────────
const SPAN: float = 1.00          ## x, left rim to right rim: u = 0 to 1, cx = -TAU to TAU
const Y_CENTRE: float = 0.72      ## the panel's middle, and `area`'s datum
const ENVELOPE: float = 0.41      ## every operation fills y in [0.31, 1.13], the same box
const SAMPLES: int = 96           ## derivative_pair's `samples` default
## THE THREE OPERATIONS FILL ONE ENVELOPE. Three rails need a small band each, one rail
## can have the lot. Without this `area` would be a 0.23 m body next to `bridge`'s 0.82 m
## one, the sweep would frame the union, and every `area` tile would be a third the size
## of its neighbours on the sheet.
const PITCH_3: float = 0.28       ## bridge: rails at 0.44 / 0.72 / 1.00
const AMP_3: float = 0.13
const PITCH_2: float = 0.41       ## pair: rails at 0.515 / 0.925
const AMP_2: float = 0.195
const AMP_1: float = 0.41         ## area: one rail at 0.72

# ── marks, metres ─────────────────────────────────────────────────────────────────────
const TUBE_R: float = 0.016       ## the curves. 32 mm on a 1.00 m span (postulate_bench's 0.018 on 1.0 m)
const TUBE_SIDES: int = 6
const DATUM_R: float = 0.005      ## the rail's own zero
const BEAD_R: float = 0.024
const DOWEL_R: float = 0.006
const SLAB_T: float = 0.050       ## the slab's real thickness, out of the panel
const LADDER_PITCH: float = 1.20

## The panel stands vertical and FACES capture_config_sweep's standpoint: its yaw is 0.62
## and its Basis.x works out to (cos 0.62, 0, -sin 0.62) exactly, so local +x is screen
## right and the still reads the curve left to right the way the code writes it. Every
## artifact has a front; this one's front is where the reader stands.
const PANEL_YAW: float = 0.62

# ── colours, every one lifted from a member ───────────────────────────────────────────
const FN_COLOR: Color = Color(0.55, 0.85, 1.00)      ## derivative_pair fn_color
const RATE_COLOR: Color = Color(1.00, 0.55, 0.25)    ## derivative_pair deriv_color
const INT_COLOR: Color = Color(0.55, 1.00, 0.70)     ## integral_area total_color
const DATUM_COLOR: Color = Color(0.40, 0.40, 0.45)   ## derivative_pair _axis_bar
const BEAD_COLOR: Color = Color(1.00, 1.00, 1.00)    ## derivative_pair sweep_color
const AREA_POS: Color = Color(0.35, 0.70, 0.95)      ## ftc_bridge pos_col / integral_area area_color
const AREA_NEG: Color = Color(0.95, 0.45, 0.35)      ## ftc_bridge neg_col

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("curve"):
		curve = _pick(str(config_data["curve"]), CURVES, curve)
	if config_data.has("operation"):
		operation = _pick(str(config_data["operation"]), OPERATIONS, operation)
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: Array = []
	if layout == "ladder":
		for c in CURVES:
			names.append(c)
	else:
		names.append(_pick(curve, CURVES, "hump"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = str(names[i])
		var offset: float = (float(i) - float(count - 1) * 0.5) * LADDER_PITCH
		holder.position = _world(Vector3(offset, 0.0, 0.0))
		add_child(holder)
		_built.append(holder)
		_build_panel(holder, str(names[i]))


# ── the five functions ────────────────────────────────────────────────────────────────
# Everything is a function of u in [0,1], mapped to cx in [-TAU, TAU] first — the members'
# own mapping (derivative_pair gd:152, integral_area gd:170, ftc_bridge gd:168). Amplitude
# is 1 here because every rail is normalised to its own peak on the way out; see _rail.

func _cx(u: float) -> float:
	return lerpf(-TAU, TAU, u)


func _f(name_of: String, u: float) -> float:
	var cx: float = _cx(u)
	match name_of:
		"hump":
			## ftc_bridge's parabola, gd:186. NOT the siblings' sin(u*PI). This is the
			## dialect under which hump' is exactly -(2/TAU) ramp, i.e. the one under
			## which this family is a chain. See the header.
			return 1.0 - (cx * cx) / (TAU * TAU)
		"ramp":
			return cx / TAU
		"spike":
			return exp(-cx * cx * 0.5)
		"step":
			return atan(cx * 2.5) * 0.6366198
		_:
			return sin(cx) + sin(cx * 2.0) * 0.35


## d/dcx by central difference rather than five transcribed formulas — ftc_bridge's own
## choice (gd:191-198, "asking the geometry beats hand-transcribing five derivatives"), and
## it makes the rate rail a MEASUREMENT off the function rail instead of a second assertion
## beside it. Exact for the parabola, which is the link the argument turns on.
func _df(name_of: String, u: float) -> float:
	var e: float = 0.0008
	var u0: float = clampf(u - e, 0.0, 1.0)
	var u1: float = clampf(u + e, 0.0, 1.0)
	var du: float = u1 - u0
	if du <= 0.0:
		return 0.0
	return (_f(name_of, u1) - _f(name_of, u0)) / (du * 2.0 * TAU)


## Cumulative trapezoid from the left rim, so F(a) = 0 — integral_area's _cum (gd:220-230)
## with the endpoints kept instead of the midpoints, because the theorem the bridge carries
## is about the ENDS.
func _integral(name_of: String, n: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n + 1)
	out[0] = 0.0
	var dcx: float = 2.0 * TAU / float(n)
	var run: float = 0.0
	for i in range(n):
		var ua: float = float(i) / float(n)
		var ub: float = float(i + 1) / float(n)
		run += (_f(name_of, ua) + _f(name_of, ub)) * 0.5 * dcx
		out[i + 1] = run
	return out


func _role_samples(name_of: String, role: int, n: int) -> PackedFloat32Array:
	if role == ROLE_INTEGRAL:
		return _integral(name_of, n)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n + 1)
	for i in range(n + 1):
		var u: float = float(i) / float(n)
		out[i] = _df(name_of, u) if role == ROLE_RATE else _f(name_of, u)
	return out


## THE CLAMP, AND IT IS A STATEMENT. Each rail is scaled by its OWN peak, so each fills its
## own band and nothing runs off the frame. That is not cosmetic: measured over the five
## curves the rate's peak spans 1.70 (wave) down to 0.159 (ramp) in units of amplitude per
## unit cx — 10.7x — and the integral's spans 8.38 (hump) down to 2.00 (wave), 4.2x. On one
## shared scale `wave` and `step` would set the frame and `ramp`'s rate would be a 1 mm
## nudge off its datum, indistinguishable from a dead axis. So MAGNITUDES ARE NOT
## COMPARABLE BETWEEN RAILS OR BETWEEN CURVES HERE; SHAPE AND SIGN ARE, and shape is what
## the chain claim is about. ftc_bridge does exactly this to its own rate plot (gd:342,
## "Normalised per curve so the rate always fills its band"). A constant rail — ramp's
## rate, the only one — normalises to +1 and draws as a flat line at the top of its band,
## which is what a constant positive rate looks like when only shape survives.
func _rail(name_of: String, role: int, rail_y: float, amp: float) -> PackedVector2Array:
	var raw: PackedFloat32Array = _role_samples(name_of, role, SAMPLES)
	var peak: float = 0.00001
	for i in range(raw.size()):
		peak = maxf(peak, absf(raw[i]))
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(raw.size()):
		var x: float = lerpf(-SPAN * 0.5, SPAN * 0.5, float(i) / float(SAMPLES))
		out.append(Vector2(x, rail_y + amp * raw[i] / peak))
	return out


# ── the panel ─────────────────────────────────────────────────────────────────────────

func _build_panel(holder: Node3D, name_of: String) -> void:
	match _pick(operation, OPERATIONS, "pair"):
		"area":
			_build_area(holder, name_of)
		"bridge":
			_build_bridge(holder, name_of)
		_:
			_build_pair(holder, name_of)


## f above, f' below. The beads and their dowels are the join: f turns exactly where f'
## crosses, and the dowel is a plumb line between the two.
func _build_pair(holder: Node3D, name_of: String) -> void:
	var y_top: float = Y_CENTRE + PITCH_2 * 0.5
	var y_bot: float = Y_CENTRE - PITCH_2 * 0.5
	var fn: PackedVector2Array = _rail(name_of, ROLE_FUNCTION, y_top, AMP_2)
	var rate: PackedVector2Array = _rail(name_of, ROLE_RATE, y_bot, AMP_2)
	_add_datum(holder, y_top)
	_add_datum(holder, y_bot)
	holder.add_child(_tube(fn, TUBE_R, FN_COLOR, 0.9, "Function"))
	holder.add_child(_tube(rate, TUBE_R, RATE_COLOR, 0.9, "Rate"))
	_add_join(holder, name_of, ROLE_RATE, fn, y_bot)


## f alone, and the signed area under it as a solid.
func _build_area(holder: Node3D, name_of: String) -> void:
	var fn: PackedVector2Array = _rail(name_of, ROLE_FUNCTION, Y_CENTRE, AMP_1)
	_add_datum(holder, Y_CENTRE)
	_add_slab(holder, fn, Y_CENTRE)
	holder.add_child(_tube(fn, TUBE_R, FN_COLOR, 0.9, "Function"))


## The whole stack. Both joins beaded, and the middle rail's area built as the solid whose
## accumulation the top rail is.
func _build_bridge(holder: Node3D, name_of: String) -> void:
	var y_int: float = Y_CENTRE + PITCH_3
	var y_fn: float = Y_CENTRE
	var y_rate: float = Y_CENTRE - PITCH_3
	var integ: PackedVector2Array = _rail(name_of, ROLE_INTEGRAL, y_int, AMP_3)
	var fn: PackedVector2Array = _rail(name_of, ROLE_FUNCTION, y_fn, AMP_3)
	var rate: PackedVector2Array = _rail(name_of, ROLE_RATE, y_rate, AMP_3)
	_add_datum(holder, y_int)
	_add_datum(holder, y_fn)
	_add_datum(holder, y_rate)
	_add_slab(holder, fn, y_fn)
	holder.add_child(_tube(integ, TUBE_R, INT_COLOR, 0.9, "Integral"))
	holder.add_child(_tube(fn, TUBE_R, FN_COLOR, 0.9, "Function"))
	holder.add_child(_tube(rate, TUBE_R, RATE_COLOR, 0.9, "Rate"))
	_add_join(holder, name_of, ROLE_FUNCTION, integ, y_fn)
	_add_join(holder, name_of, ROLE_RATE, fn, y_rate)


## One join of the chain, as beads and a plumb line. `lower_role` is the rail underneath;
## wherever its raw value changes sign, the rail ABOVE has a turning point at the same x.
##
## THE TEST IS A BRACKET WALK AND NOT `a * b < 0`, AND THAT COST A DESIGN. SAMPLES is even
## and the domain is symmetric, so u = 0.5 (cx = 0) is ALWAYS a sample — and every centred
## zero in this family sits exactly on it: the hump's apex, the spike's apex, the ramp's
## crossing, the step's crossing. A product test reads 0 * anything as "no crossing" and
## drops all four. Caught by rasterising the artifact before capturing it: the DEFAULT
## variant (hump, pair) came back with zero beads, which is the one mark it exists to make.
## Walking between the last DEFINITELY-signed sample and the next finds the zero whether it
## lands on a sample or between two. The same walk skips the rims for free: `wave` starts
## and ends at 0 to within 4e-16, which is under eps, so it never acquires a definite sign
## there and no bead is placed on a rim.
func _add_join(holder: Node3D, name_of: String, lower_role: int,
		upper: PackedVector2Array, lower_y: float) -> void:
	var raw: PackedFloat32Array = _role_samples(name_of, lower_role, SAMPLES)
	var peak: float = 0.0
	for k in range(raw.size()):
		peak = maxf(peak, absf(raw[k]))
	var eps: float = maxf(peak * 1e-6, 1e-12)
	var last_i: int = -1
	var last_s: int = 0
	for i in range(raw.size()):
		var s: int = 0
		if raw[i] > eps:
			s = 1
		elif raw[i] < -eps:
			s = -1
		if s == 0:
			continue
		if last_s != 0 and s != last_s:
			var a: float = absf(raw[last_i])
			var b: float = absf(raw[i])
			var t: float = a / maxf(a + b, 1e-12)
			var frac: float = (float(last_i) + t * float(i - last_i)) / float(SAMPLES)
			var x: float = lerpf(-SPAN * 0.5, SPAN * 0.5, frac)
			var y_up: float = _sample_y(upper, frac)
			holder.add_child(_ball(Vector2(x, lower_y), BEAD_R, BEAD_COLOR, "Crossing"))
			holder.add_child(_ball(Vector2(x, y_up), BEAD_R, BEAD_COLOR, "Turning"))
			holder.add_child(_tube(PackedVector2Array([Vector2(x, lower_y), Vector2(x, y_up)]),
					DOWEL_R, BEAD_COLOR, 0.5, "Plumb"))
		last_i = i
		last_s = s


func _sample_y(pts: PackedVector2Array, frac: float) -> float:
	var f: float = clampf(frac, 0.0, 1.0) * float(pts.size() - 1)
	var i0: int = clampi(int(f), 0, pts.size() - 1)
	var i1: int = mini(i0 + 1, pts.size() - 1)
	return lerpf(pts[i0].y, pts[i1].y, f - float(i0))


## The rail's own zero. The one piece of chart furniture kept, because an integral without
## a datum is not a quantity and a rate without one has no sign. No ticks, no numbers, no
## second axis: all three members build exactly this bar and nothing more
## (derivative_pair _axis_bar gd:257, integral_area _build_axes gd:233, ftc_bridge gd:344).
func _add_datum(holder: Node3D, y: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-SPAN * 0.5 - 0.02, y), Vector2(SPAN * 0.5 + 0.02, y)])
	holder.add_child(_tube(pts, DATUM_R, DATUM_COLOR, 0.0, "Datum"))


# ── the slab ──────────────────────────────────────────────────────────────────────────

## The signed area, as a solid of real thickness standing on (or hanging from) the datum.
## Segments that straddle the datum are split at the crossing so the colour boundary is the
## curve's own zero and not a sample edge.
func _add_slab(holder: Node3D, pts: PackedVector2Array, datum: float) -> void:
	var pos := SurfaceTool.new()
	var neg := SurfaceTool.new()
	pos.begin(Mesh.PRIMITIVE_TRIANGLES)
	neg.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any_pos: bool = false
	var any_neg: bool = false
	for i in range(pts.size() - 1):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var h0: float = p0.y - datum
		var h1: float = p1.y - datum
		if h0 * h1 < 0.0:
			var t: float = absf(h0) / maxf(absf(h0) + absf(h1), 1e-12)
			var xm: float = lerpf(p0.x, p1.x, t)
			var mid: Vector2 = Vector2(xm, datum)
			if _emit_cell(pos if h0 > 0.0 else neg, p0, mid, datum):
				if h0 > 0.0:
					any_pos = true
				else:
					any_neg = true
			if _emit_cell(pos if h1 > 0.0 else neg, mid, p1, datum):
				if h1 > 0.0:
					any_pos = true
				else:
					any_neg = true
			continue
		var up: bool = (h0 + h1) >= 0.0
		if _emit_cell(pos if up else neg, p0, p1, datum):
			if up:
				any_pos = true
			else:
				any_neg = true
	if any_pos:
		var mp := MeshInstance3D.new()
		mp.name = "SlabPositive"
		mp.mesh = pos.commit()
		mp.material_override = _mat(AREA_POS, 0.22, false)
		holder.add_child(mp)
	if any_neg:
		var mn := MeshInstance3D.new()
		mn.name = "SlabNegative"
		mn.mesh = neg.commit()
		mn.material_override = _mat(AREA_NEG, 0.22, false)
		holder.add_child(mn)


## One prism cell of the slab: datum edge to curve edge, extruded SLAB_T out of the panel.
## Six faces, each normal computed from the face and then turned OUTWARD against the cell's
## own centroid. Not decoration: a hand-written Vector3.UP for the top face and DOWN for the
## datum face are both correct for a cell standing above the datum and both backwards for
## one hanging below it, so the negative half of every slab would have shaded as if lit from
## behind — a colour difference between the two halves that says nothing and would have
## looked like the sign it is meant to carry.
func _emit_cell(st: SurfaceTool, p0: Vector2, p1: Vector2, datum: float) -> bool:
	if absf(p1.x - p0.x) < 1e-7:
		return false
	if absf(p0.y - datum) < 1e-5 and absf(p1.y - datum) < 1e-5:
		return false
	var h: float = SLAB_T * 0.5
	var a0: Vector3 = _world(Vector3(p0.x, datum, h))
	var b0: Vector3 = _world(Vector3(p1.x, datum, h))
	var c0: Vector3 = _world(Vector3(p1.x, p1.y, h))
	var d0: Vector3 = _world(Vector3(p0.x, p0.y, h))
	var a1: Vector3 = _world(Vector3(p0.x, datum, -h))
	var b1: Vector3 = _world(Vector3(p1.x, datum, -h))
	var c1: Vector3 = _world(Vector3(p1.x, p1.y, -h))
	var d1: Vector3 = _world(Vector3(p0.x, p0.y, -h))
	var mid: Vector3 = (a0 + b0 + c0 + d0 + a1 + b1 + c1 + d1) * 0.125
	_quad(st, a0, b0, c0, d0, mid)
	_quad(st, b1, a1, d1, c1, mid)
	_quad(st, d0, c0, c1, d1, mid)
	_quad(st, a1, b1, b0, a0, mid)
	_quad(st, a0, d0, d1, a1, mid)
	_quad(st, c0, b0, b1, c1, mid)
	return true


## One face, wound as given and normalled outward from `centre`.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, centre: Vector3) -> void:
	var n: Vector3 = (p1 - p0).cross(p3 - p0)
	if n.length_squared() < 1e-14:
		return
	n = n.normalized()
	var face: Vector3 = (p0 + p1 + p2 + p3) * 0.25
	if n.dot(face - centre) < 0.0:
		n = -n
	var order: Array = [p0, p1, p2, p0, p2, p3]
	for i in range(order.size()):
		var q: Vector3 = order[i]
		st.set_normal(n)
		st.add_vertex(q)


# ── frame and mesh helpers ────────────────────────────────────────────────────────────

## Panel space to world: +x runs along the panel, +y is up, +z is out of its face toward
## the reader. See PANEL_YAW.
func _world(p: Vector3) -> Vector3:
	var e1: Vector3 = Vector3(cos(PANEL_YAW), 0.0, -sin(PANEL_YAW))
	var nrm: Vector3 = Vector3(sin(PANEL_YAW), 0.0, cos(PANEL_YAW))
	return e1 * p.x + Vector3.UP * p.y + nrm * p.z


## A round tube along a polyline given in PANEL SPACE. The panel's normal is perpendicular
## to every tangent by construction, so it serves as the frame directly — no rotation-
## minimising walk, no seam, and the same ring count everywhere.
func _tube(pts: PackedVector2Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var count: int = pts.size()
	if count < 2:
		return mi
	var nrm: Vector3 = _world(Vector3(0.0, 0.0, 1.0)) - _world(Vector3.ZERO)
	var centres: PackedVector3Array = PackedVector3Array()
	var rings: Array = []
	for i in range(count):
		var prev: Vector2 = pts[maxi(i - 1, 0)]
		var next: Vector2 = pts[mini(i + 1, count - 1)]
		var d: Vector2 = next - prev
		if d.length_squared() < 1e-14:
			d = Vector2(1.0, 0.0)
		d = d.normalized()
		var tangent: Vector3 = _world(Vector3(d.x, d.y, 0.0)) - _world(Vector3.ZERO)
		var n2: Vector3 = tangent.cross(nrm).normalized()
		var centre: Vector3 = _world(Vector3(pts[i].x, pts[i].y, 0.0))
		centres.append(centre)
		var ring: Array = []
		for k in range(TUBE_SIDES):
			var a: float = TAU * float(k) / float(TUBE_SIDES)
			var normal: Vector3 = nrm * cos(a) + n2 * sin(a)
			ring.append([centre + normal * r, normal])
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			var order: Array = [ra[k], rb[k], ra[k2], ra[k2], rb[k], rb[k2]]
			for j in range(order.size()):
				var v: Array = order[j]
				var vpos: Vector3 = v[0]
				var vnrm: Vector3 = v[1]
				st.set_normal(vnrm)
				st.add_vertex(vpos)
	for e in range(2):
		var ci: int = 0 if e == 0 else count - 1
		var ring2: Array = rings[ci]
		var cap_n: Vector3 = (centres[0] - centres[1]) if e == 0 else (centres[count - 1] - centres[count - 2])
		if cap_n.length_squared() < 1e-12:
			continue
		cap_n = cap_n.normalized()
		for k in range(TUBE_SIDES):
			var k2b: int = (k + 1) % TUBE_SIDES
			var p0: Array = ring2[k]
			var p1: Array = ring2[k2b]
			var q0: Vector3 = p0[0]
			var q1: Vector3 = p1[0]
			var qc: Vector3 = centres[ci]
			st.set_normal(cap_n)
			st.add_vertex(qc)
			st.set_normal(cap_n)
			st.add_vertex(q0)
			st.set_normal(cap_n)
			st.add_vertex(q1)
	mi.mesh = st.commit()
	mi.material_override = _mat(c, emit, false)
	return mi


func _ball(at: Vector2, r: float, c: Color, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = _world(Vector3(at.x, at.y, 0.0))
	mi.material_override = _mat(c, 0.55, false)
	return mi


func _mat(c: Color, emit: float, translucent: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if translucent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
