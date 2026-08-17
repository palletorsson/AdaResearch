class_name BasinField
extends Node3D

# ═══════════════════════════════════════════════════════════════════════════
#  BASIN FIELD — a two-plate comparator for the `basin` axis
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THIS IS. Wave 21 synthesis of a TWO-MEMBER family. `basin` is declared,
# character for character and value for value, by exactly two artifacts:
#
#   gradient_descent_visualization  algorithms/numericalmethods/gradientdescent/
#   simulated_annealing_visualization  algorithms/optimization/simulatedannealing/
#
# With two members there is one comparison and no triangulation, so the family
# is a HYPOTHESIS — that these two are about the same thing — and this bench is
# the test. It is built as a comparator and nothing else: LEFT plate carries the
# descent table's own formula for the named basin, RIGHT plate carries the
# annealing table's, and the four `reading` values are four ways of putting the
# two side by side. One photograph, one verdict.
#
# WHAT THE SOURCES ACTUALLY SAY, cited, because every claim below has to be
# traceable to a line rather than to a registry description:
#
#  1. NEITHER SOLVER BRANCHES ON `basin`. gradient_descent_visualization.gd:1122
#     `_step_optimizers()` runs SGD / Momentum / Nesterov / Adam and contains no
#     reference to `function_preset` or `basin`; it reaches the landscape only
#     through `_gradient()` (:926), which reaches it through `_eval()` (:891).
#     simulated_annealing_visualization.gd:1413 `_perform_annealing_step()` is
#     the same: `_generate_neighbor()` (:1475) scales with temperature and
#     `search_space_size`, `_perform_basin_hop()` (:1535) with `hop_strength`,
#     and neither reads `basin` or `problem_type`. Both members REDRAW THE
#     TERRAIN UNDER AN UNCHANGED SOLVER. The axis is a property of the objective
#     function, not of the algorithm — which is why a still can hold it at all,
#     and why this bench draws landscapes and runs nothing.
#
#  2. BUT THE TWO ARE NOT SYMMETRIC ABOUT WHAT ELSE `basin` TOUCHES. The descent
#     table hand-picks a start point per value (:967 `_start_pos()`, five cases)
#     and a vertical exaggeration per value (:981 `_y_scale_for_fn()`, five
#     cases). The annealing table picks neither: the start is drawn at random
#     inside +-0.8 * search_space_size regardless of basin (:1325) and the height
#     is normalised over the relief's own measured min/max (:400, :482). One
#     member COMPOSES each basin as a picture; the other MEASURES it and lets it
#     fall where it falls. This bench takes the annealing side of that — every
#     plate is normalised over its own range — because that is the only treatment
#     under which two different formulas can be compared as SHAPES.
#
#  3. `basin` IS A FALSE FRIEND INSIDE THE ANNEALING FILE ITSELF. Line 47 opens
#     an export category literally named "Basin Hopping"; :1535 is
#     `_perform_basin_hop()`. There a basin is one well you climb OUT of. The
#     DNA axis calls the whole relief a basin. So `basin = "plural"` has to be
#     read as "a basin containing many basins", and the descent table — which has
#     no local-basin concept anywhere in its 1900 lines — cannot see the
#     collision.
#
# WHAT THE COMPARISON FINDS, and it is the reason for the `residue` reading:
#
#   bowl     THE SAME FUNCTION TWICE. descent :896 `x * x + y * y`;
#            annealing :365 `p.x * p.x + p.y * p.y`. Identical.
#   valley   THE SAME FUNCTION TWICE. descent :898 and annealing :368-371 are
#            the same Rosenbrock, term for term.
#   plural   Himmelblau (descent :900) against Rastrigin (annealing :350). Both
#            are honestly many-minima'd, but on this bench's lattice one has
#            FOUR minima and the other FORTY-NINE.
#   plateau  THE ONE OUTRIGHT DISAGREEMENT. The descent table's plateau (:901)
#            is a flat disc with a rim outside it: flat in the MIDDLE, high at
#            the EDGE, and it has exactly ONE minimum. The annealing table's
#            plateau (:355) is Ackley: high and corrugated over the whole outer
#            field with one needle at the CENTRE, and forty-nine minima. Same
#            word, inverted topology. Ackley is more `plural` than Himmelblau is.
#   scarp    The same construction, and calibrated to agree exactly. descent :922
#            uses a fixed rise of 3.0 against a bowl spanning 2 * 4^2 = 32;
#            annealing :389-393 uses SCARP_RATIO = 3/32 times 2 * s^2, which AT
#            s = 4 IS 3.0 TO THE BIT. The port was written to reproduce the
#            sibling's number at the sibling's own domain, and this bench runs at
#            domain 4 so that the agreement is testable as an exact zero.
#
# So three of the five values are one function wearing two names, one is the same
# class differently populated, and one is two opposite landscapes under one word.
#
# THE OTHER SHARED AXIS IS DECLINED, and the reason is a second disagreement.
# Both members also declare `evidence` = result | trace | longhand | axiom. In
# the annealing table the rungs strictly accumulate — `axiom` is longhand plus
# the rejected offers (:642, :688-696, :722) — so its top value is the UNION of
# its own axis, the "all-rungs value" this programme has learned to refuse. In
# the descent table `axiom` REMOVES the trails (:1308 returns early for both
# `result` and `axiom`). One member's top rung is inclusive, the other's is
# exclusive. Carrying that word here would have meant inventing a third meaning,
# and every rung of it is about a running search that a still cannot hold.
#
# NO RANDOMNESS ANYWHERE IN THIS FILE, and no clock: there is no `_process`, no
# timer, no `randf`, no `randi`, no `seed`. Everything is a closed-form sample of
# a closed-form function on a fixed lattice. That is why there is no seed export
# and no dna.fixture — not an omission, an absence.

# ── axis 1: the family word ────────────────────────────────────────────────
## WHICH LANDSCAPE both plates are asked for. The five values and their spelling
## are the family's, taken from gradient_descent_visualization.gd:66 and
## simulated_annealing_visualization.gd:87 (which are the same line twice).
##
## Ships as `bowl`, and the reason is not that it is the descent table's default
## (the annealing table ships `plural`, so either choice would have picked a
## side). It is that bowl is the one value at which the two members are provably
## the same function, so the shipped frame is the pair AGREEING and every other
## value is a measured departure from it.
@export_enum("bowl", "valley", "plural", "plateau", "scarp") var basin: String = "bowl"

# ── axis 2: how the same two plates are read ───────────────────────────────
## The crossing axis. Not an accumulation — each value REPLACES the last, so
## there is no all-rungs rung here.
##
##   relief   the object. Both landscapes as raked reliefs, painted on one
##            normalised colour scale, with eight contours cut into each.
##   section  the arithmetic. The plates go blank and nine profile curtains
##            stand off each of them — f sampled along nine lines, which is what
##            a surface IS before it is a picture.
##   residue  the disagreement, and the only reading that answers the family
##            question directly. LEFT shows max(0, n_descent - n_annealing) and
##            RIGHT shows max(0, n_annealing - n_descent): each plate carries the
##            ground it claims and the other does not. At bowl, valley and scarp
##            both plates are IDENTICALLY ZERO and photograph as two dead boards.
##   census   the count. Plates flat and painted, and a stem standing at every
##            strict local minimum of the lattice, height scaled by depth. This
##            is where `plural` is shown to mean 4 on one plate and 49 on the
##            other, and `plateau` to mean 1 against 49.
@export_enum("relief", "section", "residue", "census") var reading: String = "relief"

const BASINS: PackedStringArray = ["bowl", "valley", "plural", "plateau", "scarp"]
const READINGS: PackedStringArray = ["relief", "section", "residue", "census"]

# ── fixed geometry ─────────────────────────────────────────────────────────
## Half-width of the sampled square, in the objective functions' own units.
##
## 4.0 IS A LOAD-BEARING CHOICE AND NOT A CONVENIENCE. The descent table's field
## is +-4 (gradient_descent_visualization.gd:196) and the annealing table's is
## +-5 (search_space_size, simulated_annealing_visualization.gd:55). At 4.0 the
## annealing table's ported scarp rise, SCARP_RATIO * 2 * s^2 = (3/32) * 32, is
## exactly the descent table's literal 3.0, so `scarp` becomes an exact zero in
## the residue reading. At 5.0 it is 4.6875 and the agreement becomes
## approximate. Exposed so that fact can be checked rather than believed, but it
## is NOT an axis: moving it invalidates two of this artifact's designed nulls.
@export var domain: float = 4.0

## Lattice resolution. 48 quads per side, so 49 x 49 samples at spacing
## 2 * 4 / 48 = 0.16667 — which resolves Rastrigin's and Ackley's unit-spaced
## minima six samples to a period, and lands EXACTLY on every integer point, so
## the census is counting the wells and not the sampling.
const LAT: int = 48

const RAKE_DEG: float = 55.0
const PLATE_W: float = 1.20
const PLATE_L: float = 1.20
const PLATE_GAP: float = 0.15
const HINGE_Y: float = 0.145
const HINGE_Z: float = 0.30
## Relief amplitude along the plate normal, for every reading that has one.
const RELIEF: float = 0.13
const CONTOURS: int = 8
const SECTION_LINES: int = 9
const STEM_MAX: float = 0.12
const STEM_R: float = 0.008
## The gauge rail. It sits above the plate at every basin and every reading and
## stands 0.17 m proud — further than any relief, curtain or stem can reach — so
## THE UNION AABB IS THE SAME AT ALL TWENTY VARIANTS and the sweep camera cannot
## move between frames. Without it, `residue` at bowl (a dead-flat plate) would
## be framed 0.13 m closer than `residue` at plateau, and part of the axis would
## be a fact about the camera.
const RAIL_V: float = 1.24
const RAIL_T: float = 0.012
const RAIL_PROUD: float = 0.17

const PLINTH_W: float = 2.70
const PLINTH_H: float = 0.14
const PLINTH_D: float = 0.78

# ── palette ────────────────────────────────────────────────────────────────
## The height ramp, four stops at 0 / 0.33 / 0.66 / 1. Rec.709 luminances 18,
## 69, 112, 230 of 255 — no two stops closer than 43 levels, so a shape change
## is never lost to the critic's luminance reading.
const RAMP_A: Color = Color(0.059, 0.071, 0.110)
const RAMP_B: Color = Color(0.129, 0.302, 0.420)
const RAMP_C: Color = Color(0.549, 0.420, 0.302)
const RAMP_D: Color = Color(0.929, 0.902, 0.820)

## The residue ramp. Its zero is DELIBERATELY the darkest colour in the artifact:
## three of the five basins put both plates at exactly zero and they must read as
## dead rather than as merely dim.
const RES_A: Color = Color(0.043, 0.043, 0.051)
const RES_B: Color = Color(0.350, 0.100, 0.140)
const RES_C: Color = Color(0.860, 0.420, 0.120)
const RES_D: Color = Color(1.000, 0.940, 0.720)

const COL_DESCENT: Color = Color(0.36, 0.62, 0.92)
const COL_ANNEAL: Color = Color(0.95, 0.45, 0.16)
const COL_BODY: Color = Color(0.17, 0.175, 0.195)
const COL_BOARD: Color = Color(0.105, 0.110, 0.130)
const COL_CONTOUR: Color = Color(0.035, 0.037, 0.045)
const COL_STEM_CAP: Color = Color(0.96, 0.94, 0.88)

const SIDE_DESCENT: int = 0
const SIDE_ANNEAL: int = 1

# ── internal ───────────────────────────────────────────────────────────────
var _sin_r: float = 0.0
var _cos_r: float = 0.0
var _created: Array[Node] = []
var _built: bool = false

## Normalised height fields, [side][i * (LAT+1) + j], 0..1. Rebuilt per basin.
var _nf: Array = []


# ═══════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_dna_meta()
	_normalise_words()
	_build_all()
	_built = true


## GridInteractablesComponent writes `config_*` metadata onto the ROOT before
## add_child and only calls apply_grid_config a frame later; the DNA sweep sets
## the @exports directly, also before add_child. Reading both here makes the
## FIRST build the asked-for one instead of building `bowl` and tearing it down.
## An unknown word keeps whatever is standing, so the axis can only ever be set
## to a value the code can actually build.
func _read_dna_meta() -> void:
	if has_meta("config_basin"):
		var b: String = str(get_meta("config_basin")).strip_edges().to_lower()
		if BASINS.has(b):
			basin = b
	if has_meta("config_reading"):
		var r: String = str(get_meta("config_reading")).strip_edges().to_lower()
		if READINGS.has(r):
			reading = r


func _normalise_words() -> void:
	basin = basin.strip_edges().to_lower()
	if not BASINS.has(basin):
		basin = "bowl"
	reading = reading.strip_edges().to_lower()
	if not READINGS.has(reading):
		reading = "relief"
	if domain < 0.5:
		domain = 4.0


func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("basin"):
		var b: String = str(config_data["basin"]).strip_edges().to_lower()
		if BASINS.has(b) and b != basin:
			basin = b
			changed = true
	if config_data.has("reading"):
		var r: String = str(config_data["reading"]).strip_edges().to_lower()
		if READINGS.has(r) and r != reading:
			reading = r
			changed = true
	if config_data.has("domain"):
		var d: float = float(config_data["domain"])
		if d > 0.5 and not is_equal_approx(d, domain):
			domain = d
			changed = true
	# Nothing standing yet means nothing to rebuild — _ready has already read the
	# metadata and will build the asked-for thing once.
	if changed and _built:
		_rebuild()


func _rebuild() -> void:
	for n in _created:
		if is_instance_valid(n):
			n.queue_free()
	_created.clear()
	_build_all()


func _own(n: Node) -> void:
	add_child(n)
	_created.append(n)


func _build_all() -> void:
	_sin_r = sin(deg_to_rad(RAKE_DEG))
	_cos_r = cos(deg_to_rad(RAKE_DEG))
	_sample_fields()
	_build_body()
	_build_plates()
	_build_rails()


# ═══════════════════════════════════════════════════════════════════════════
#  THE OBJECTIVE FUNCTIONS — both members', copied term for term
# ═══════════════════════════════════════════════════════════════════════════

## gradient_descent_visualization.gd:891 `_eval()`, the five branches of its
## `function_preset` match, with its own constants PLATEAU_R2 = 6.25,
## PLATEAU_TILT = 0.02 (:123-124) and SCARP_RISE = 3.0 (:127).
func _eval_descent(x: float, y: float) -> float:
	match basin:
		"bowl":
			return x * x + y * y
		"valley":
			return (1.0 - x) * (1.0 - x) + 100.0 * (y - x * x) * (y - x * x)
		"plural":
			return (x * x + y - 11.0) * (x * x + y - 11.0) + (x + y * y - 7.0) * (x + y * y - 7.0)
		"plateau":
			var r2p: float = x * x + y * y
			return 4.0 * tanh(0.35 * maxf(0.0, r2p - 6.25)) + 0.02 * r2p
		"scarp":
			var r2s: float = x * x + y * y
			return r2s + 3.0 * (1.0 if x > 0.0 else 0.0)
	return x * x + y * y


## simulated_annealing_visualization.gd:334 `_evaluate()` dispatching over
## BASIN_PROBLEM (:91): bowl -> _sphere (:364), valley -> _rosenbrock (:368),
## plural -> _rastrigin (:350), plateau -> _ackley (:355), scarp -> _scarp
## (:391) with SCARP_RATIO = 3.0 / 32.0 (:389).
func _eval_anneal(x: float, y: float) -> float:
	match basin:
		"bowl":
			return x * x + y * y
		"valley":
			var t1: float = y - x * x
			var t2: float = 1.0 - x
			return 100.0 * t1 * t1 + t2 * t2
		"plural":
			var a_r: float = 10.0
			return 2.0 * a_r + (x * x - a_r * cos(TAU * x)) + (y * y - a_r * cos(TAU * y))
		"plateau":
			var s1: float = x * x + y * y
			var s2: float = cos(TAU * x) + cos(TAU * y)
			return -20.0 * exp(-0.2 * sqrt(s1 / 2.0)) - exp(s2 / 2.0) + 20.0 + exp(1.0)
		"scarp":
			var rise: float = (3.0 / 32.0) * 2.0 * domain * domain
			return x * x + y * y + (rise if x > 0.0 else 0.0)
	return x * x + y * y


func _eval_side(side: int, x: float, y: float) -> float:
	if side == SIDE_DESCENT:
		return _eval_descent(x, y)
	return _eval_anneal(x, y)


## Samples both landscapes on the shared lattice and normalises each over its
## OWN measured min and max — the annealing table's treatment
## (simulated_annealing_visualization.gd:400 `_compute_height_range`), not the
## descent table's hand-chosen per-function y_scale (:981). It is the only
## treatment under which two functions with ranges of 32 and 40025 can be
## compared as shapes rather than as magnitudes.
func _sample_fields() -> void:
	_nf = []
	var n: int = LAT + 1
	for side in range(2):
		var raw: PackedFloat32Array = PackedFloat32Array()
		raw.resize(n * n)
		var lo: float = INF
		var hi: float = -INF
		for i in range(n):
			var fx: float = -domain + 2.0 * domain * float(i) / float(LAT)
			for j in range(n):
				var fy: float = -domain + 2.0 * domain * float(j) / float(LAT)
				var v: float = _eval_side(side, fx, fy)
				raw[i * n + j] = v
				lo = minf(lo, v)
				hi = maxf(hi, v)
		var span: float = hi - lo
		if span <= 0.0:
			span = 1.0
		for k in range(raw.size()):
			raw[k] = (raw[k] - lo) / span
		_nf.append(raw)


func _nval(side: int, i: int, j: int) -> float:
	var n: int = LAT + 1
	var arr: PackedFloat32Array = _nf[side]
	return arr[clampi(i, 0, LAT) * n + clampi(j, 0, LAT)]


## The value each plate actually draws, which is what the `reading` axis changes
## about the SAME two fields.
func _draw_val(side: int, i: int, j: int) -> float:
	if reading == "residue":
		var a: float = _nval(SIDE_DESCENT, i, j)
		var b: float = _nval(SIDE_ANNEAL, i, j)
		if side == SIDE_DESCENT:
			return maxf(0.0, a - b)
		return maxf(0.0, b - a)
	return _nval(side, i, j)


# ═══════════════════════════════════════════════════════════════════════════
#  PLATE FRAME
# ═══════════════════════════════════════════════════════════════════════════

## A point on plate `side`. u runs across the plate (-PLATE_W/2 .. +PLATE_W/2),
## v runs UP the rake (0 .. PLATE_L), h stands off along the plate normal.
##
## The rake exists for one measured reason. The sweep camera sits at yaw 0.62,
## pitch -0.26, giving a view direction of (0.5615, 0.2571, 0.7866). A FLAT
## relief has normal (0,1,0) and projects at 0.257 of its area; raked 55 degrees
## the normal is (0, 0.5736, 0.8192) and projects at 0.792 — 3.08x more plate in
## the frame, and 96 percent of the theoretical best (0.8275 at 71.9 degrees).
## A drafting easel is also simply what a relief model is normally shown on.
func _pp(side: int, u: float, v: float, h: float) -> Vector3:
	var cx: float = (PLATE_W + PLATE_GAP) * 0.5
	if side == SIDE_DESCENT:
		cx = -cx
	return Vector3(
		cx + u,
		HINGE_Y + v * _sin_r + h * _cos_r,
		HINGE_Z - v * _cos_r + h * _sin_r)


## Plate-space (du, dv, dh) into world. Used for surface normals.
func _pv(du: float, dv: float, dh: float) -> Vector3:
	return Vector3(du, dv * _sin_r + dh * _cos_r, -dv * _cos_r + dh * _sin_r)


func _u_of(i: int) -> float:
	return -PLATE_W * 0.5 + PLATE_W * float(i) / float(LAT)


func _v_of(j: int) -> float:
	return PLATE_L * float(j) / float(LAT)


func _ramp(t: float) -> Color:
	var n: float = clampf(t, 0.0, 1.0)
	if n < 0.33:
		return RAMP_A.lerp(RAMP_B, n / 0.33)
	if n < 0.66:
		return RAMP_B.lerp(RAMP_C, (n - 0.33) / 0.33)
	return RAMP_C.lerp(RAMP_D, (n - 0.66) / 0.34)


func _res_ramp(t: float) -> Color:
	var n: float = clampf(t, 0.0, 1.0)
	if n < 0.33:
		return RES_A.lerp(RES_B, n / 0.33)
	if n < 0.66:
		return RES_B.lerp(RES_C, (n - 0.33) / 0.33)
	return RES_C.lerp(RES_D, (n - 0.66) / 0.34)


func _paint(t: float) -> Color:
	if reading == "residue":
		return _res_ramp(t)
	return _ramp(t)


# ═══════════════════════════════════════════════════════════════════════════
#  MESH HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _tri(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, col: Color, nrm: Vector3) -> void:
	im.surface_set_color(col)
	im.surface_set_normal(nrm)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_set_normal(nrm)
	im.surface_add_vertex(b)
	im.surface_set_color(col)
	im.surface_set_normal(nrm)
	im.surface_add_vertex(c)


func _quad(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var nrm: Vector3 = (b - a).cross(c - a)
	if nrm.length() < 1e-9:
		nrm = Vector3.UP
	else:
		nrm = nrm.normalized()
	_tri(im, a, b, c, col, nrm)
	_tri(im, a, c, d, col, nrm)


## A box given in PLATE coordinates: centre (u, v, h) and half-extents. Every
## corner goes through _pp, so the box is raked with its plate.
func _plate_box(im: ImmediateMesh, side: int, u: float, v: float, h0: float,
		hu: float, hv: float, h1: float, col: Color) -> void:
	var p: Array = []
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			for sh in [0.0, 1.0]:
				p.append(_pp(side, u + su * hu, v + sv * hv, h0 + sh * (h1 - h0)))
	# index = su*4 + sv*2 + sh
	var c000: Vector3 = p[0]
	var c001: Vector3 = p[1]
	var c010: Vector3 = p[2]
	var c011: Vector3 = p[3]
	var c100: Vector3 = p[4]
	var c101: Vector3 = p[5]
	var c110: Vector3 = p[6]
	var c111: Vector3 = p[7]
	_quad(im, c001, c101, c111, c011, col)   # cap (h = h1)
	_quad(im, c000, c010, c110, c100, col)   # base
	_quad(im, c000, c100, c101, c001, col)   # sv = -1
	_quad(im, c010, c011, c111, c110, col)   # sv = +1
	_quad(im, c000, c001, c011, c010, col)   # su = -1
	_quad(im, c100, c110, c111, c101, col)   # su = +1


func _mesh_node(nm: String, im: ImmediateMesh, unshaded: bool) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	mi.mesh = im
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.metallic = 0.0
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	_own(mi)


# ═══════════════════════════════════════════════════════════════════════════
#  BODY — plinth and easel struts. Identical at every variant.
# ═══════════════════════════════════════════════════════════════════════════

func _build_body() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_world_box(im, Vector3(0.0, PLINTH_H * 0.5, 0.02),
		Vector3(PLINTH_W * 0.5, PLINTH_H * 0.5, PLINTH_D * 0.5), COL_BODY)
	# A darker inset band round the plinth, so the body is not one flat slab and
	# the eye has a horizon to read the rake against.
	_world_box(im, Vector3(0.0, PLINTH_H - 0.022, 0.02),
		Vector3(PLINTH_W * 0.5 + 0.012, 0.010, PLINTH_D * 0.5 + 0.012), COL_BOARD)
	# Back struts holding each plate up: two per plate, at u = +-0.45.
	for side in range(2):
		for su in [-0.45, 0.45]:
			var top: Vector3 = _pp(side, su, PLATE_L * 0.62, -0.02)
			var foot: Vector3 = Vector3(top.x, PLINTH_H, -PLINTH_D * 0.5 + 0.10)
			var mid: Vector3 = (top + foot) * 0.5
			var half_y: float = absf(top.y - foot.y) * 0.5
			var half_z: float = absf(top.z - foot.z) * 0.5 + 0.018
			_world_box(im, mid, Vector3(0.022, half_y, half_z), COL_BODY)
	im.surface_end()
	_mesh_node("Body", im, false)


func _world_box(im: ImmediateMesh, c: Vector3, h: Vector3, col: Color) -> void:
	var x0: float = c.x - h.x
	var x1: float = c.x + h.x
	var y0: float = c.y - h.y
	var y1: float = c.y + h.y
	var z0: float = c.z - h.z
	var z1: float = c.z + h.z
	_quad(im, Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), col)
	_quad(im, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x0, y0, z0), col)
	_quad(im, Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y0, z1), col)
	_quad(im, Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3(x0, y0, z0), col)
	_quad(im, Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x0, y0, z1), col)
	_quad(im, Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x1, y0, z0), col)


# ═══════════════════════════════════════════════════════════════════════════
#  RAILS — the AABB pin, and the only thing that tells the plates apart
# ═══════════════════════════════════════════════════════════════════════════

## Both rails occupy exactly the same envelope, so neither the AABB nor the
## framing depends on which plate is which. They differ only in how that
## envelope is cut: the descent rail is one continuous blade — a derivative is
## defined everywhere or it is not defined at all — and the annealing rail is
## TEN teeth, which is `_prob_bin_count` from
## simulated_annealing_visualization.gd:188, the ten bins of its acceptance
## histogram. Fixed geometry, never varies with either axis, and it identifies
## the two members without putting a word in the frame that a null would have to
## survive.
func _build_rails() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_plate_box(im, SIDE_DESCENT, 0.0, RAIL_V, 0.0,
		PLATE_W * 0.5, RAIL_T * 0.5, RAIL_PROUD, COL_DESCENT.darkened(0.42))
	var unit: float = PLATE_W / 19.0
	for k in range(10):
		var uc: float = -PLATE_W * 0.5 + unit * 0.5 + unit * 2.0 * float(k)
		_plate_box(im, SIDE_ANNEAL, uc, RAIL_V, 0.0,
			unit * 0.5, RAIL_T * 0.5, RAIL_PROUD, COL_ANNEAL.darkened(0.42))
	im.surface_end()
	_mesh_node("Rails", im, false)


# ═══════════════════════════════════════════════════════════════════════════
#  PLATES
# ═══════════════════════════════════════════════════════════════════════════

func _build_plates() -> void:
	if reading == "section":
		_build_blank_boards()
		_build_sections()
		return
	_build_fields()
	if reading == "relief":
		_build_contours()
	elif reading == "census":
		_build_stems()


## The painted surface. `relief` and `residue` displace it along the normal;
## `census` lays it flat so the stems are the only thing standing.
func _build_fields() -> void:
	var lift: float = RELIEF
	if reading == "census":
		lift = 0.0
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		for i in range(LAT):
			for j in range(LAT):
				var t00: float = _draw_val(side, i, j)
				var t10: float = _draw_val(side, i + 1, j)
				var t11: float = _draw_val(side, i + 1, j + 1)
				var t01: float = _draw_val(side, i, j + 1)
				var p00: Vector3 = _pp(side, _u_of(i), _v_of(j), t00 * lift)
				var p10: Vector3 = _pp(side, _u_of(i + 1), _v_of(j), t10 * lift)
				var p11: Vector3 = _pp(side, _u_of(i + 1), _v_of(j + 1), t11 * lift)
				var p01: Vector3 = _pp(side, _u_of(i), _v_of(j + 1), t01 * lift)
				var na: Vector3 = (p10 - p00).cross(p01 - p00)
				if na.length() < 1e-9:
					na = _pv(0.0, 0.0, 1.0)
				else:
					na = na.normalized()
				if na.dot(_pv(0.0, 0.0, 1.0)) < 0.0:
					na = -na
				_tri(im, p00, p10, p11, _paint((t00 + t10 + t11) / 3.0), na)
				_tri(im, p00, p11, p01, _paint((t00 + t11 + t01) / 3.0), na)
		# A 12 mm skirt round each plate so it reads as a board and not as a
		# floating membrane, and so the residue's zero state still has an edge.
		_plate_box(im, side, 0.0, PLATE_L * 0.5, -0.030,
			PLATE_W * 0.5 + 0.014, PLATE_L * 0.5 + 0.014, -0.002, COL_BOARD)
	im.surface_end()
	_mesh_node("Fields", im, false)


## Marching squares at eight equal levels. Contours are what makes a relief
## legible in a still at a shallow camera pitch — a shaded surface photographs
## as a gradient, a contoured one photographs as a MAP, and the whole question
## here is whether two maps are the same map.
func _build_contours() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		for c in range(1, CONTOURS):
			var lev: float = float(c) / float(CONTOURS)
			for i in range(LAT):
				for j in range(LAT):
					var pts: Array = _cell_crossings(side, i, j, lev)
					var k: int = 0
					while k + 1 < pts.size():
						_ribbon(im, side, pts[k], pts[k + 1], lev)
						k += 2
	im.surface_end()
	_mesh_node("Contours", im, true)


## The (u, v) crossings of `lev` on the four edges of lattice cell (i, j).
func _cell_crossings(side: int, i: int, j: int, lev: float) -> Array:
	var out: Array = []
	var a: float = _draw_val(side, i, j)
	var b: float = _draw_val(side, i + 1, j)
	var c: float = _draw_val(side, i + 1, j + 1)
	var d: float = _draw_val(side, i, j + 1)
	var u0: float = _u_of(i)
	var u1: float = _u_of(i + 1)
	var v0: float = _v_of(j)
	var v1: float = _v_of(j + 1)
	if (a < lev) != (b < lev):
		out.append(Vector2(lerpf(u0, u1, _frac(a, b, lev)), v0))
	if (b < lev) != (c < lev):
		out.append(Vector2(u1, lerpf(v0, v1, _frac(b, c, lev))))
	if (d < lev) != (c < lev):
		out.append(Vector2(lerpf(u0, u1, _frac(d, c, lev)), v1))
	if (a < lev) != (d < lev):
		out.append(Vector2(u0, lerpf(v0, v1, _frac(a, d, lev))))
	return out


func _frac(a: float, b: float, lev: float) -> float:
	var den: float = b - a
	if absf(den) < 1e-9:
		return 0.5
	return clampf((lev - a) / den, 0.0, 1.0)


## One contour segment as a flat ribbon riding 4 mm above the surface at its own
## level, so it is never buried by the relief it is drawn on.
func _ribbon(im: ImmediateMesh, side: int, p: Vector2, q: Vector2, lev: float) -> void:
	var dir: Vector2 = q - p
	if dir.length() < 1e-7:
		return
	var nrm: Vector2 = Vector2(-dir.y, dir.x).normalized() * 0.0035
	var h: float = lev * RELIEF + 0.004
	var a: Vector3 = _pp(side, p.x + nrm.x, p.y + nrm.y, h)
	var b: Vector3 = _pp(side, q.x + nrm.x, q.y + nrm.y, h)
	var c: Vector3 = _pp(side, q.x - nrm.x, q.y - nrm.y, h)
	var d: Vector3 = _pp(side, p.x - nrm.x, p.y - nrm.y, h)
	_quad(im, a, b, c, d, COL_CONTOUR)


# ── section ────────────────────────────────────────────────────────────────

func _build_blank_boards() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		_plate_box(im, side, 0.0, PLATE_L * 0.5, -0.030,
			PLATE_W * 0.5 + 0.014, PLATE_L * 0.5 + 0.014, 0.0, COL_BOARD)
	im.surface_end()
	_mesh_node("Boards", im, false)


## Nine curtains per plate: f sampled along nine lines of constant v, each drawn
## as a filled section standing off the board. A surface is a stack of sections
## before it is a picture, and a section is the one drawing in which a
## discontinuity is unmistakable — which is what `scarp` claims to be.
func _build_sections() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		var base: Color = COL_DESCENT
		if side == SIDE_ANNEAL:
			base = COL_ANNEAL
		for s in range(SECTION_LINES):
			var jj: int = int(round(float(LAT) * float(s) / float(SECTION_LINES - 1)))
			var v: float = _v_of(jj)
			var shade: float = 0.55 - 0.30 * float(s) / float(SECTION_LINES - 1)
			var body: Color = base.darkened(shade)
			for i in range(LAT):
				var h0: float = _draw_val(side, i, jj) * RELIEF
				var h1: float = _draw_val(side, i + 1, jj) * RELIEF
				var ua: float = _u_of(i)
				var ub: float = _u_of(i + 1)
				# the curtain
				_quad(im,
					_pp(side, ua, v, 0.0), _pp(side, ub, v, 0.0),
					_pp(side, ub, v, h1), _pp(side, ua, v, h0), body)
				# the profile itself, a bright 5 mm cap on top of the curtain
				_quad(im,
					_pp(side, ua, v - 0.0025, h0), _pp(side, ub, v - 0.0025, h1),
					_pp(side, ub, v + 0.0025, h1), _pp(side, ua, v + 0.0025, h0), base)
	im.surface_end()
	_mesh_node("Sections", im, true)


# ── census ─────────────────────────────────────────────────────────────────

## A stem at every STRICT local minimum of the lattice, 8-neighbour test, border
## excluded. Height carries depth: the deepest well gets the tallest stem.
##
## SAY WHAT THIS COUNTS, because it is not quite what it looks like. It counts
## the minima OF THE 49 x 49 LATTICE, not of the function, and the two differ
## in one honest and instructive place: Rosenbrock's trench floor is so nearly
## level along its length that the discrete test finds TWELVE minima strung
## along y = x^2 instead of the single true one at (1,1). That is not noise to
## be tuned away — it is precisely the property the descent table names when it
## writes that on `valley` "the gradient is true but useless"
## (gradient_descent_visualization.gd:56). A search with finite steps cannot tell
## those twelve apart either. The other counts are exact: bowl 1|1, plural 4|49,
## plateau 1|49, scarp 1|1.
func _build_stems() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(2):
		var base: Color = COL_DESCENT
		if side == SIDE_ANNEAL:
			base = COL_ANNEAL
		for i in range(1, LAT):
			for j in range(1, LAT):
				if not _is_min(side, i, j):
					continue
				var depth: float = _nval(side, i, j)
				var hgt: float = 0.018 + STEM_MAX * (1.0 - clampf(depth, 0.0, 1.0))
				_plate_box(im, side, _u_of(i), _v_of(j), 0.0,
					STEM_R, STEM_R, hgt, base)
				_plate_box(im, side, _u_of(i), _v_of(j), hgt,
					STEM_R * 1.9, STEM_R * 1.9, hgt + 0.007, COL_STEM_CAP)
	im.surface_end()
	_mesh_node("Stems", im, false)


func _is_min(side: int, i: int, j: int) -> bool:
	var v: float = _nval(side, i, j)
	for di in range(-1, 2):
		for dj in range(-1, 2):
			if di == 0 and dj == 0:
				continue
			if _nval(side, i + di, j + dj) <= v:
				return false
	return true
