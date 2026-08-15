extends Node3D
class_name LawBench

## law_bench — the corpus uses ONE word, `law`, for three things that differ in what
## would refute them. This bench builds all three on one stage so the difference is a
## difference between bodies rather than between glosses.
##
## THREE MEMBERS, THREE VOCABULARIES, and not one value in common:
##
##   newtons_laws     law = all | inertia | acceleration | reaction
##                    (algorithms/physicssimulation/newtonslaws/NewtonsLaws.gd:58)
##                    RigidBody3D under a named force regime. Its own truth line: "A law
##                    is not a rule about one body — it is a constraint on what relations
##                    between bodies are allowed." A PHYSICAL LAW: one counter-example
##                    kills it, and two did.
##   random_space     law = uniform | gaussian | poisson | exponential
##                    (commons/context/walkgrids/RandomSpace.gd:75)
##                    A walkable floor drawn from a distribution. Its own header says why
##                    the word is not a metaphor: "in probability the LAW of a random
##                    variable is literally its distribution". A MODEL: no single draw
##                    can contradict it. You need a statistic and a threshold first.
##   riemann_pi       law = none | x_over_log | logint | both
##                    (algorithms/spacetopology/riemann_pi/pi_infinity_surface.gd:58)
##                    Which smooth estimate stands against the pi(x) staircase. An
##                    APPROXIMATION: x/ln x and li(x) are neither laws nor models but
##                    estimates with error terms, and the Riemann hypothesis is a
##                    conjecture about how big one of those error terms is.
##
## SO `law` SPANS: refutable-by-instance, refutable-only-statistically, and
## not-refutable-but-bounded. Three epistemologies under one export name.
##
## HOW THE BENCH ARGUES IT — and this is the design that makes it one object rather than
## three: every value is built as A PREDICTION AND ITS RESIDUAL, both as solids. The
## `reading` axis walks the three parts: the claim alone, the claim with the world behind
## it, and the gap alone. THE RESIDUAL IS WHERE THE THREE KINDS COME APART:
##
##   a physical law      the residual is EXACTLY ZERO inside its own model. The only way
##                       to get a number out of it is to introduce a METHOD, and then the
##                       number is a fact about the method, not the law. `inertia`'s
##                       residual is zero to the last bit; `reaction`'s is zero in the
##                       centre of mass while being non-zero for each body separately.
##   a distribution      the residual is NEVER zero for a finite sample, has no fixed
##                       sign, and does not shrink for THIS sample at all. It shrinks
##                       like 1/sqrt(N) across samples that were never taken.
##   an approximation    the residual is SYSTEMATIC, SIGNED, GROWING, and bounded by a
##                       theorem. x/ln x sits below pi(x) at 497 of 500 sampled x; li
##                       sits above at 499 of 500.
##
## THE PROPOSITION SOMEONE CAN DISAGREE WITH, and it is the reason three cells of this
## sheet are deliberately empty: a residual reading cannot distinguish A PERFECT THEORY
## from NO THEORY. `none` at `claim`, `none` at `residual` and `inertia` at `residual`
## render the same picture to the byte — an empty board with a rail across it. One of
## them is "nothing has been claimed", one is "nothing was claimed so there is no gap",
## and one is "a claim was made and the gap is zero". If you think refutability is
## legible from the evidence, those three tiles are a problem for you.
##
## Deterministic. No randf, no noise, no _process, no Timer. The one sample on the bench
## is drawn from an index hash with a pinned seed (12345, random_space's own seed_value),
## so two builds of one value are the same mesh down to the vertex.

# ── the law axis ───────────────────────────────────────────────────────────────────────
## NINE VALUES, THREE FROM EACH MEMBER, IN THEIR MEMBERS' OWN SPELLING. The blocks are the
## point: no value crosses a block, because no two members share a word.
##
##   inertia       (newtons_laws) sum F = 0, so velocity is preserved. Three bodies with
##                 three starting speeds and three masses; mass does not enter, which is
##                 the content. REFUTED BY: one body under no net force whose velocity
##                 changes. One instance is enough.
##   acceleration  (newtons_laws) F = m a. The source's own 5 N on the source's own
##                 masses 1.0 / 1.5 / 2.0, so the three end in three places and the only
##                 thing that separates them is mass. REFUTED BY: one measured pair
##                 (F, a) whose ratio is not the body's mass.
##   reaction      (newtons_laws) two bodies, masses 1.0 and 2.0, driven at each other by
##                 forces of equal size and opposite sign. They meet off-centre — equal
##                 and opposite is a statement about FORCE, and the masses were never
##                 equal — and their centre of mass never moves. REFUTED BY: one pair
##                 whose centre of mass accelerates under internal forces alone.
##   uniform       (random_space) every height equally likely. The member's shipped
##                 default and its short-circuit expression. REFUTED BY: nothing one
##                 sample can do. Only a statistic over a threshold.
##   gaussian      (random_space) the normal quantile over 3 sigma, clipped — a bell of
##                 sigma 1/3 in normalised units with two point masses at the clip.
##   exponential   (random_space) rate 3, one-sided: a plain at the floor with about one
##                 vertex in twenty saturating at the ceiling. The only asymmetric law
##                 the member declares, and the member says so.
##   none          (riemann_pi) THE ONLY TRUE NULL ON THE AXIS. The member's _setup_law()
##                 returns before building anything: the staircase alone, a fact with
##                 nothing to be measured against. Here it claims nothing, so `claim` and
##                 `residual` are empty and `world` is the bare prime count.
##   x_over_log    (riemann_pi) x / ln x, the crude estimate. Below the true count almost
##                 everywhere and the gap widens. REFUTED BY: nothing — it is not a claim
##                 that can be false, only an estimate that can be poor, and its error is
##                 the subject of a theorem.
##   logint        (riemann_pi) the integral of dt/ln t from 2, the good estimate. Above
##                 the true count almost everywhere, by a third as much. What is at stake
##                 here is not truth but SIZE: RH says this residual stays under
##                 sqrt(x) ln x / (8 pi).
@export_enum("inertia", "acceleration", "reaction", "uniform", "gaussian", "exponential", "none", "x_over_log", "logint") var law: String = "none":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAWS.has(picked):
			return                      ## an unreachable value keeps the current figure
		law = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH PART OF THE ARGUMENT IS STANDING. Strictly additive between the first two:
## `world` draws everything `claim` draws and then puts the data behind it.
##   claim     the law's prediction, alone. For a distribution that means the EXPECTED
##             COUNTS PER BIN, not a smooth curve — because a distribution cannot be
##             compared to anything until bins have been chosen, and choosing them is the
##             price of the test. The bin edges are visible in the claim on purpose.
##   world     the prediction with what is actually there behind it: the stepped
##             trajectory an integrator produces, the seeded sample's histogram, the true
##             pi(x) staircase.
##   residual  the gap alone, as built form, standing on the rail. This is the reading
##             that carries the thesis and the only one that could refute anything.
@export_enum("claim", "world", "residual") var reading: String = "world":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One cell, or the three readings in a row. NOT PART OF EITHER AXIS. capture_config_sweep
## unions the AABB across a spec's variants, so an all-readings value declared inside
## `reading` would frame every single cell against three and a half metres. The registry
## fixture pins `single`; the stage does the rest.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const LAWS: PackedStringArray = ["inertia", "acceleration", "reaction", "uniform",
	"gaussian", "exponential", "none", "x_over_log", "logint"]
const READINGS: PackedStringArray = ["claim", "world", "residual"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the stage, and it is the whole answer to the extent trap ───────────────────────────
## The nine laws draw wildly different amounts: `none`/`claim` draws nothing at all and
## `logint`/`world` draws two 500-sample curves. An AABB fitted to the FIGURE would move
## between every cell and three tiles would have no AABB whatever. The plate, the four
## pins and the four top rails are drawn IDENTICALLY in all 27 variants and are the
## largest thing in the scene, so the world box is 0.96 x 1.00 x 0.96 in every cell by
## construction and the camera never moves. The stage is also why an empty cell is
## legible: it reads as a framed empty board, not as a failed render.
const STAGE_HALF: float = 0.48
const STAGE_H: float = 1.00
const PLATE_T: float = 0.024
const PIN: float = 0.032

# ── the board, drawn identically in all 27 cells ───────────────────────────────────────
const PX0: float = -0.40
const PX1: float = 0.40
const PY0: float = 0.14
const PY1: float = 0.90
## Where the residual's zero lives. Also, for the Newton family, position zero.
const RAIL_V: float = 0.5
const BOARD_Z: float = -0.145
const BOARD_T: float = 0.008
const FRAME_Z: float = -0.130
const FRAME_T: float = 0.014
const RAIL_T: float = 0.011

# ── Newton: the source's own numbers ───────────────────────────────────────────────────
## applied_force_strength, masses and the reaction pair's start positions are read off
## NewtonsLaws.gd (5.0 N; 1.0 / 1.5 / 2.0 kg; +-1.6 m). Nothing here is invented except
## the three starting speeds at `inertia`, which the source does not have because its
## `free` bodies only fall.
const NEWTON_F: float = 5.0
const NEWTON_T: float = 1.0
const NEWTON_STEPS: int = 8
const NEWTON_H: float = 0.125
## The position window, in metres, mapped onto the board's height. Every track of all
## three Newton values lies inside it: inertia ends at -0.8 / 0.2 / 1.2, acceleration at
## 0.7 / -0.133 / -0.55, reaction at 0.9 / 0.35.
const NEWTON_WIN: float = 2.0
## The residual is drawn at 5.053x the position scale, so the largest of the family
## (0.3125 m) reaches 0.300 m of board. Without the gain the largest wedge is 59 mm deep
## and the smallest is 30 mm, and the three would not be separable in a still.
const NEWTON_GAIN: float = 5.053
const LANE: float = 0.080
## Wedge thickness per kilogram. Height is the displacement error and thickness is the
## mass, so VOLUME is the momentum error — which is why acceleration's three wedges have
## equal volume (m a = F is the same for all three) and reaction's two have equal volume
## and opposite sign (that IS the third law).
const MASS_T: float = 0.035

# ── the sample: 160 draws, 16 bins, one seeded stream ──────────────────────────────────
## random_space's own finding, reproduced: the four laws are MONOTONE TRANSFORMS OF THE
## SAME DRAW. Draw i receives the same u under every value, so the three histograms on
## this bench are three views of ONE sample, not three samples. Four fields from four
## streams would also have differed, and the difference would have been the streams.
const SAMPLE_N: int = 160
const BINS: int = 16
## random_space's own seed_value.
const SAMPLE_SEED: int = 12345
## Tallest expected density is exponential's 1.368 and tallest observed is 1.70, so 1.8
## clears both with room and is the same ceiling for all three values.
const DENS_MAX: float = 1.8
const SAMPLE_GAIN: float = 1.255
const BAR_GAP: float = 0.008

# ── the count: riemann_pi's own range and stride ───────────────────────────────────────
const RI_MAXX: int = 2000
const RI_STEP: int = 4
## Tallest drawn quantity is li_trap(1998) = 314.4, so 340 clears it in every value.
const COUNT_MAX: float = 340.0
## 3.379x, so the family's largest residual (x/ln x, 39.72 counts low) reaches 0.300 m.
## logint's largest is then 0.105 m and its mean 0.064 m: the ratio 2.68 is preserved and
## it is the ratio, not the depth, that is the finding.
const RI_GAIN: float = 3.379

# ── how thick a mark is ────────────────────────────────────────────────────────────────
const CLAIM_R: float = 0.013         ## a Newton prediction
const WORLD_R: float = 0.008         ## the stepped path lying on it
const NODE_R: float = 0.019          ## a step boundary
const CURVE_R: float = 0.009         ## an estimate curve
const STAIR_R: float = 0.012         ## the true prime count
const SOLID_T: float = 0.055         ## a histogram bar, a residual block, a band
const Z_MARK: float = 0.0
const Z_BEHIND: float = -0.075

# ── colour ─────────────────────────────────────────────────────────────────────────────
## THE TWO RESIDUAL COLOURS ARE INHERITED, NOT CHOSEN. riemann_pi already ships
## law_color = Color(1.0, 0.45, 0.35) for x / ln x, which runs BELOW the staircase, and
## logint_color = Color(0.45, 1.0, 0.60) for li, which runs ABOVE it. The member had
## already colour-coded the sign of a residual; this bench takes those two colours
## character for character and generalises them to every residual on the board.
const C_PLATE: Color = Color(0.20, 0.21, 0.24)
const C_STAGE: Color = Color(0.42, 0.43, 0.47)
const C_BOARD: Color = Color(0.13, 0.14, 0.17)
const C_FRAME: Color = Color(0.34, 0.35, 0.40)
const C_RAIL: Color = Color(0.74, 0.75, 0.78)
const C_CLAIM: Color = Color(0.98, 0.84, 0.38)
const C_WORLD: Color = Color(0.42, 0.86, 1.00)
const C_POS: Color = Color(0.45, 1.00, 0.60)
const C_NEG: Color = Color(1.00, 0.45, 0.35)
const E_CLAIM: Color = Color(0.52, 0.42, 0.14)
const E_WORLD: Color = Color(0.16, 0.42, 0.58)
const E_POS: Color = Color(0.14, 0.40, 0.20)
const E_NEG: Color = Color(0.42, 0.16, 0.12)
const E_RAIL: Color = Color(0.26, 0.27, 0.29)

const LADDER_PITCH: float = 1.15
## Iterated rather than written as a literal array, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false
## Lazily created surface tools for the cell being built, keyed by material role. A
## SurfaceTool that was begun and never given a vertex is an error in the log on commit,
## and on this bench three cells legitimately have nothing to draw, so no tool is begun
## until something asks for it.
var _tools: Dictionary = {}


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("law"):
		law = str(config_data["law"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


## Which member's vocabulary a value came from, and therefore which apparatus builds it.
func _family(v: String) -> String:
	if v == "inertia" or v == "acceleration" or v == "reaction":
		return "newton"
	if v == "uniform" or v == "gaussian" or v == "exponential":
		return "sample"
	return "count"


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var cells: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		cells = READINGS.duplicate()
	else:
		cells.append(_pick(reading, READINGS, "world"))
	var chosen: String = _pick(law, LAWS, "none")
	var count: int = cells.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + cells[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_tools = {}
		_build_stage()
		_build_board()
		var fam: String = _family(chosen)
		if fam == "newton":
			_build_newton(chosen, cells[i])
		elif fam == "sample":
			_build_sample(chosen, cells[i])
		else:
			_build_count(chosen, cells[i])
		_commit_all(holder)


# ── the board mapping ──────────────────────────────────────────────────────────────────

func _bx(u: float) -> float:
	return PX0 + (PX1 - PX0) * u


func _by(v: float) -> float:
	return PY0 + (PY1 - PY0) * v


func _rail_y() -> float:
	return _by(RAIL_V)


# ── the invariant furniture ────────────────────────────────────────────────────────────

func _build_stage() -> void:
	var plate: SurfaceTool = _tool("plate")
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(STAGE_HALF * 2.0, PLATE_T, STAGE_HALF * 2.0))

	var cage: SurfaceTool = _tool("stage")
	var off: float = STAGE_HALF - PIN * 0.5
	for sx in SIGNS:
		for sz in SIGNS:
			_add_box(cage, Vector3(sx * off, STAGE_H * 0.5, sz * off),
				Vector3(PIN, STAGE_H, PIN))
	for sz in SIGNS:
		_add_box(cage, Vector3(0.0, STAGE_H - PIN * 0.5, sz * off),
			Vector3(STAGE_HALF * 2.0 - PIN * 2.0, PIN, PIN))
	for sx in SIGNS:
		_add_box(cage, Vector3(sx * off, STAGE_H - PIN * 0.5, 0.0),
			Vector3(PIN, PIN, STAGE_HALF * 2.0 - PIN * 2.0))


## Board, frame and rail. Identical in all 27 cells and drawn before either axis is read,
## which is what makes an empty cell a picture of an empty board rather than a blank.
func _build_board() -> void:
	var w: float = PX1 - PX0
	var h: float = PY1 - PY0
	var cx: float = (PX0 + PX1) * 0.5
	var cy: float = (PY0 + PY1) * 0.5

	var board: SurfaceTool = _tool("board")
	_add_box(board, Vector3(cx, cy, BOARD_Z), Vector3(w, h, BOARD_T))

	var frame: SurfaceTool = _tool("frame")
	_add_box(frame, Vector3(cx, PY0, FRAME_Z), Vector3(w + FRAME_T, FRAME_T, FRAME_T))
	_add_box(frame, Vector3(cx, PY1, FRAME_Z), Vector3(w + FRAME_T, FRAME_T, FRAME_T))
	_add_box(frame, Vector3(PX0, cy, FRAME_Z), Vector3(FRAME_T, h, FRAME_T))
	_add_box(frame, Vector3(PX1, cy, FRAME_Z), Vector3(FRAME_T, h, FRAME_T))

	## The rail is the residual's zero. It is drawn in every reading, not only in
	## `residual`, because a datum that appears only when something is measured against
	## it is a datum you cannot trust.
	var rail: SurfaceTool = _tool("rail")
	_add_box(rail, Vector3(cx, _rail_y(), FRAME_Z + 0.010),
		Vector3(w, RAIL_T, FRAME_T + 0.008))


# ── Newton: a prediction, an integrator, and the difference ────────────────────────────

## [x0, v0, a, mass] per body. `all` is NOT here — see the registry `declines`: it is a
## MIXTURE of three force histories (free, constant, oscillate), which the member's own
## comment calls "one law, F = ma, demonstrated three times over".
func _newton_tracks(v: String) -> Array:
	var out: Array = []
	if v == "inertia":
		out.append(PackedFloat32Array([-1.8, 1.0, 0.0, 1.0]))
		out.append(PackedFloat32Array([-1.8, 2.0, 0.0, 1.5]))
		out.append(PackedFloat32Array([-1.8, 3.0, 0.0, 2.0]))
	elif v == "acceleration":
		out.append(PackedFloat32Array([-1.8, 0.0, NEWTON_F / 1.0, 1.0]))
		out.append(PackedFloat32Array([-1.8, 0.0, NEWTON_F / 1.5, 1.5]))
		out.append(PackedFloat32Array([-1.8, 0.0, NEWTON_F / 2.0, 2.0]))
	else:
		out.append(PackedFloat32Array([-1.6, 0.0, NEWTON_F / 1.0, 1.0]))
		out.append(PackedFloat32Array([1.6, 0.0, -NEWTON_F / 2.0, 2.0]))
	return out


## Lanes are indexed from a FIXED origin, not centred on the track count, so body 0 of
## `acceleration` and body 0 of `reaction` — which are the same body under the same force
## — stand at the same depth and are the same wedge. Centring would have moved them and
## made the two values look less alike than they are.
func _lane(i: int) -> float:
	return (float(i) - 1.0) * LANE


func _pos_v(x: float) -> float:
	return (x + NEWTON_WIN) / (NEWTON_WIN * 2.0)


func _build_newton(v: String, which: String) -> void:
	var tracks: Array = _newton_tracks(v)
	if which == "residual":
		for i in range(tracks.size()):
			var tr: PackedFloat32Array = tracks[i]
			var acc: float = tr[2]
			if absf(acc) < 0.000001:
				continue        ## inertia: Euler is EXACT on a straight line. Nothing.
			## e(t) = 0.5 * a * h * t, exact at every one of the nine nodes and linear
			## between them, which is what it is.
			var xs: PackedFloat32Array = PackedFloat32Array()
			var ys: PackedFloat32Array = PackedFloat32Array()
			for s in range(13):
				var t: float = float(s) / 12.0
				var e: float = 0.5 * acc * NEWTON_H * (t * NEWTON_T)
				xs.append(_bx(t))
				ys.append(_rail_y() + (PY1 - PY0) * NEWTON_GAIN * e / (NEWTON_WIN * 2.0))
			var key: String = "pos"
			if acc < 0.0:
				key = "neg"
			_add_band(_tool(key), xs, ys, _rail_y(), _lane(i), tr[3] * MASS_T)
		return

	for i in range(tracks.size()):
		var tr2: PackedFloat32Array = tracks[i]
		var claim: PackedVector3Array = PackedVector3Array()
		for s in range(41):
			var t2: float = float(s) / 40.0
			var tt: float = t2 * NEWTON_T
			var x2: float = tr2[0] + tr2[1] * tt + 0.5 * tr2[2] * tt * tt
			claim.append(Vector3(_bx(t2), _by(_pos_v(x2)), _lane(i)))
		_add_tube(_tool("claim"), claim, CLAIM_R, 8)
		_add_sphere(_tool("claim"), claim[0], CLAIM_R * 1.25, 8, 12)

		if which != "world":
			continue
		## Semi-implicit Euler, the scheme Godot's rigid bodies actually use, at a step
		## coarse enough to see: v += h a, then x += h v. Its displacement error against
		## the closed form is exactly 0.5 * a * h * t — which is the residual reading.
		var xr: float = tr2[0]
		var vr: float = tr2[1]
		var walk: PackedVector3Array = PackedVector3Array()
		walk.append(Vector3(_bx(0.0), _by(_pos_v(xr)), _lane(i) + 0.022))
		for n in range(NEWTON_STEPS):
			vr += NEWTON_H * tr2[2]
			xr += NEWTON_H * vr
			var u: float = float(n + 1) / float(NEWTON_STEPS)
			walk.append(Vector3(_bx(u), _by(_pos_v(xr)), _lane(i) + 0.022))
		_add_tube(_tool("world"), walk, WORLD_R, 8)
		for p in walk:
			_add_sphere(_tool("world"), p, NODE_R, 8, 12)


# ── the sample: a density, a histogram, and their difference ───────────────────────────

## The bin's expected probability under a value, with the end bins absorbing everything
## outside [-1, 1] — exactly as the sampler does, because gaussian CLIPS at three sigma
## and exponential SATURATES at the ceiling. Folding the clip mass into the end bins is
## not a tidy-up; it is what makes claim and world comparable bin for bin.
func _bin_p(v: String, j: int) -> float:
	var a: float = -1.0 + 2.0 * float(j) / float(BINS)
	var b: float = -1.0 + 2.0 * float(j + 1) / float(BINS)
	var lo: float = 0.0
	var hi: float = 1.0
	if j > 0:
		lo = _cdf(v, a)
	if j < BINS - 1:
		hi = _cdf(v, b)
	return maxf(hi - lo, 0.0)


func _cdf(v: String, h: float) -> float:
	if v == "uniform":
		return clampf((h + 1.0) * 0.5, 0.0, 1.0)
	if v == "gaussian":
		return _normal_cdf(3.0 * h)
	return 1.0 - exp(-3.0 * (h + 1.0) * 0.5)


## One draw, under one law, in [-1, 1]. This is RandomSpace._draw with chaos_level = 1:
## uniform is randf_range(-1, 1) written as 2u - 1, gaussian is the clipped normal
## quantile over three sigma, exponential is rate 3 saturated at the ceiling. All three
## are non-decreasing in u, which is the property the shared-stream claim rests on.
func _draw_h(v: String, u: float) -> float:
	if v == "uniform":
		return 2.0 * u - 1.0
	if v == "gaussian":
		return clampf(_inverse_normal(u) / 3.0, -1.0, 1.0)
	var e: float = -log(maxf(1.0 - u, 0.000000001)) / 3.0
	return 2.0 * minf(e, 1.0) - 1.0


func _observed(v: String) -> PackedInt32Array:
	var c: PackedInt32Array = PackedInt32Array()
	c.resize(BINS)
	for j in range(BINS):
		c[j] = 0
	for i in range(SAMPLE_N):
		var h: float = _draw_h(v, _u_at(i))
		var idx: int = mini(maxi(int((h + 1.0) * 0.5 * float(BINS)), 0), BINS - 1)
		c[idx] = c[idx] + 1
	return c


func _build_sample(v: String, which: String) -> void:
	var bw: float = 2.0 / float(BINS)
	var bar_w: float = (PX1 - PX0) / float(BINS) - BAR_GAP
	if which == "residual":
		var obs: PackedInt32Array = _observed(v)
		for j in range(BINS):
			var od: float = float(obs[j]) / (float(SAMPLE_N) * bw)
			var ed: float = _bin_p(v, j) / bw
			var d: float = od - ed
			var dy: float = (PY1 - PY0) * SAMPLE_GAIN * d / DENS_MAX
			if absf(dy) < 0.0006:
				continue
			var cxb: float = _bx((float(j) + 0.5) / float(BINS))
			var key: String = "pos"
			if d < 0.0:
				key = "neg"
			_add_box(_tool(key), Vector3(cxb, _rail_y() + dy * 0.5, Z_MARK),
				Vector3(bar_w, absf(dy), SOLID_T))
		return

	for j in range(BINS):
		var ed2: float = _bin_p(v, j) / bw
		var hy: float = (PY1 - PY0) * ed2 / DENS_MAX
		var cxb2: float = _bx((float(j) + 0.5) / float(BINS))
		if hy > 0.0006:
			_add_box(_tool("claim"), Vector3(cxb2, PY0 + hy * 0.5, Z_MARK),
				Vector3(bar_w, hy, SOLID_T))
	if which != "world":
		return
	var obs2: PackedInt32Array = _observed(v)
	for j in range(BINS):
		var od2: float = float(obs2[j]) / (float(SAMPLE_N) * bw)
		var hy2: float = (PY1 - PY0) * od2 / DENS_MAX
		if hy2 <= 0.0006:
			continue
		var cxb3: float = _bx((float(j) + 0.5) / float(BINS))
		_add_box(_tool("world"), Vector3(cxb3, PY0 + hy2 * 0.5, Z_BEHIND),
			Vector3(bar_w, hy2, SOLID_T))


# ── the count: an estimate, a staircase, and the band between them ─────────────────────

## pi(x) for every x up to the limit, as a running total. The sieve is the member's own.
func _pi_table(limit: int) -> PackedInt32Array:
	var flags: PackedByteArray = PackedByteArray()
	flags.resize(limit + 1)
	for i in range(limit + 1):
		flags[i] = 1
	flags[0] = 0
	flags[1] = 0
	var top: int = int(sqrt(float(limit))) + 1
	for p in range(2, top):
		if flags[p] == 1:
			for m in range(p * p, limit + 1, p):
				flags[m] = 0
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(limit + 1)
	var c: int = 0
	for i in range(limit + 1):
		if flags[i] == 1:
			c += 1
		out[i] = c
	return out


func _build_count(v: String, which: String) -> void:
	if v == "none" and which != "world":
		return                          ## nothing is claimed, so nothing is drawn
	var table: PackedInt32Array = _pi_table(RI_MAXX)
	var us: PackedFloat32Array = PackedFloat32Array()
	var truth: PackedFloat32Array = PackedFloat32Array()
	var est: PackedFloat32Array = PackedFloat32Array()
	## li is accumulated by trapezoid from x = 2 on the SAME sample grid the member uses,
	## so this is li(x) - li(2), 1.045 below li(x). At 1998 it reads 314.39 against the
	## member's own reported 313.85 at 2000 — the same integral, one stride short.
	var li: float = 0.0
	var prev: float = 2.0
	var x: int = 2
	while x <= RI_MAXX:
		var xf: float = float(x)
		if xf > prev:
			li += (xf - prev) * 0.5 * (1.0 / log(prev) + 1.0 / log(xf))
		prev = xf
		us.append(float(x - 2) / float(RI_MAXX - 2))
		truth.append(float(table[x]))
		if v == "logint":
			est.append(li)
		else:
			est.append(xf / log(xf))
		x += RI_STEP

	if which == "residual":
		var xs: PackedFloat32Array = PackedFloat32Array()
		var ys: PackedFloat32Array = PackedFloat32Array()
		var total: float = 0.0
		for i in range(us.size()):
			var d: float = est[i] - truth[i]
			total += d
			xs.append(_bx(us[i]))
			ys.append(_rail_y() + (PY1 - PY0) * RI_GAIN * d / COUNT_MAX)
		## One tool for the whole band, chosen by the SIGN OF ITS MEAN. x / ln x is above
		## the staircase at 3 of 500 samples and li is below at 1 of 500; splitting the
		## strip there would cost two extra meshes to recolour four quads.
		var key: String = "pos"
		if total < 0.0:
			key = "neg"
		_add_band(_tool(key), xs, ys, _rail_y(), Z_MARK, SOLID_T)
		return

	if v != "none":
		var curve: PackedVector3Array = PackedVector3Array()
		for i in range(us.size()):
			curve.append(Vector3(_bx(us[i]), _by(est[i] / COUNT_MAX), Z_MARK))
		_add_tube(_tool("claim"), curve, CURVE_R, 6)
	if which != "world":
		return
	## The staircase, sampled at the member's own stride of 4. A riser is one count, which
	## is 2.2 mm at this scale and below the tube radius, so it photographs as a curve —
	## which, at 2000 wide, is what it is.
	var stair: PackedVector3Array = PackedVector3Array()
	for i in range(us.size()):
		stair.append(Vector3(_bx(us[i]), _by(truth[i] / COUNT_MAX), Z_BEHIND))
	_add_tube(_tool("world"), stair, STAIR_R, 6)


# ── arithmetic ─────────────────────────────────────────────────────────────────────────

## The sample stream. An index hash, not a running state: draw i depends only on i, so
## the order the builder happens to walk the bins can never change the sample. Seed is
## random_space's own 12345. Murmur3's 32-bit finalizer over a golden-ratio stride.
func _u_at(i: int) -> float:
	var x: int = (SAMPLE_SEED + i * 0x9E3779B9) & 0xFFFFFFFF
	x = (x ^ (x >> 16)) & 0xFFFFFFFF
	x = (x * 0x85EBCA6B) & 0xFFFFFFFF
	x = (x ^ (x >> 13)) & 0xFFFFFFFF
	x = (x * 0xC2B2AE35) & 0xFFFFFFFF
	x = (x ^ (x >> 16)) & 0xFFFFFFFF
	return float(x) / 4294967296.0


## Abramowitz & Stegun 26.2.23, copied from RandomSpace so the bench's gaussian is the
## member's gaussian and not a second opinion about it.
func _inverse_normal(u: float) -> float:
	var p: float = clampf(u, 0.000001, 0.999999)
	var q: float = minf(p, 1.0 - p)
	var t: float = sqrt(-2.0 * log(q))
	var num: float = 2.515517 + t * (0.802853 + t * 0.010328)
	var den: float = 1.0 + t * (1.432788 + t * (0.189269 + t * 0.001308))
	var z: float = t - num / den
	if p < 0.5:
		return -z
	return z


## Abramowitz & Stegun 26.2.17, absolute error below 7.5e-8 — five orders of magnitude
## finer than a bin of 160 draws can show.
func _normal_cdf(z: float) -> float:
	var az: float = absf(z)
	var t: float = 1.0 / (1.0 + 0.2316419 * az)
	var d: float = 0.3989422804014327 * exp(-0.5 * az * az)
	var p: float = d * t * (0.319381530 + t * (-0.356563782 + t * (1.781477937
		+ t * (-1.821255978 + t * 1.330274429))))
	if z >= 0.0:
		return 1.0 - p
	return p


# ── mesh primitives ────────────────────────────────────────────────────────────────────

func _tool(key: String) -> SurfaceTool:
	if _tools.has(key):
		return _tools[key] as SurfaceTool
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tools[key] = st
	return st


func _tool_colour(key: String) -> Color:
	match key:
		"plate":
			return C_PLATE
		"stage":
			return C_STAGE
		"board":
			return C_BOARD
		"frame":
			return C_FRAME
		"rail":
			return C_RAIL
		"claim":
			return C_CLAIM
		"world":
			return C_WORLD
		"pos":
			return C_POS
	return C_NEG


func _tool_emission(key: String) -> Color:
	match key:
		"rail":
			return E_RAIL
		"claim":
			return E_CLAIM
		"world":
			return E_WORLD
		"pos":
			return E_POS
		"neg":
			return E_NEG
	return Color.BLACK


func _commit_all(holder: Node3D) -> void:
	for key in _tools:
		var name_str: String = str(key)
		var st: SurfaceTool = _tools[key] as SurfaceTool
		var mesh: ArrayMesh = st.commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.name = name_str.capitalize()
		mi.mesh = mesh
		mi.material_override = _mat(_tool_colour(name_str), _tool_emission(name_str))
		holder.add_child(mi)
	_tools = {}


## A solid between a polyline and the rail, extruded in z. This is the residual as a
## BODY: four faces and two caps, with real thickness that carries the mass on the Newton
## wedges and a fixed 55 mm everywhere else.
func _add_band(st: SurfaceTool, xs: PackedFloat32Array, ys: PackedFloat32Array,
		y0: float, zc: float, depth: float) -> void:
	var n: int = xs.size()
	if n < 2:
		return
	var mean: float = 0.0
	for i in range(n):
		mean += ys[i]
	mean = mean / float(n)
	var flip: bool = mean < y0
	var zf: float = zc + depth * 0.5
	var zb: float = zc - depth * 0.5
	for i in range(n - 1):
		var xa: float = xs[i]
		var xb2: float = xs[i + 1]
		var ya: float = ys[i]
		var yb: float = ys[i + 1]
		_quad4(st, Vector3(xa, y0, zf), Vector3(xb2, y0, zf), Vector3(xb2, yb, zf),
			Vector3(xa, ya, zf), flip)
		_quad4(st, Vector3(xb2, y0, zb), Vector3(xa, y0, zb), Vector3(xa, ya, zb),
			Vector3(xb2, yb, zb), flip)
		_quad4(st, Vector3(xa, ya, zb), Vector3(xa, ya, zf), Vector3(xb2, yb, zf),
			Vector3(xb2, yb, zb), flip)
		_quad4(st, Vector3(xb2, y0, zb), Vector3(xb2, y0, zf), Vector3(xa, y0, zf),
			Vector3(xa, y0, zb), flip)
	var last: int = n - 1
	_quad4(st, Vector3(xs[0], y0, zb), Vector3(xs[0], y0, zf), Vector3(xs[0], ys[0], zf),
		Vector3(xs[0], ys[0], zb), flip)
	_quad4(st, Vector3(xs[last], ys[last], zb), Vector3(xs[last], ys[last], zf),
		Vector3(xs[last], y0, zf), Vector3(xs[last], y0, zb), flip)


func _add_tube(st: SurfaceTool, path: PackedVector3Array, r: float, sides: int) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var rings: Array = []
	for i in range(n):
		var d: Vector3 = Vector3(1.0, 0.0, 0.0)
		if i == 0:
			d = path[1] - path[0]
		elif i == n - 1:
			d = path[n - 1] - path[n - 2]
		else:
			d = path[i + 1] - path[i - 1]
		if d.length() < 0.000001:
			d = Vector3(1.0, 0.0, 0.0)
		d = d.normalized()
		var up: Vector3 = Vector3(0.0, 1.0, 0.0)
		if absf(d.dot(up)) > 0.9:
			up = Vector3(1.0, 0.0, 0.0)
		var right: Vector3 = d.cross(up).normalized()
		var fwd: Vector3 = right.cross(d).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for s in range(sides):
			var a: float = TAU * float(s) / float(sides)
			ring.append(path[i] + (right * cos(a) + fwd * sin(a)) * r)
		rings.append(ring)
	for i in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s in range(sides):
			var t: int = (s + 1) % sides
			_quad(st, r0[s], r1[s], r1[t], r0[t])


func _add_sphere(st: SurfaceTool, centre: Vector3, r: float, rings: int,
		segs: int) -> void:
	var pts: Array = []
	for i in range(rings + 1):
		var th: float = PI * float(i) / float(rings)
		var ring: PackedVector3Array = PackedVector3Array()
		for j in range(segs):
			var ph: float = TAU * float(j) / float(segs)
			ring.append(centre + Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * r)
		pts.append(ring)
	for i in range(rings):
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j in range(segs):
			var k: int = (j + 1) % segs
			_quad(st, r0[j], r1[j], r1[k], r0[k])


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3])
	_quad(st, p[5], p[4], p[7], p[6])
	_quad(st, p[3], p[2], p[6], p[7])
	_quad(st, p[4], p[5], p[1], p[0])
	_quad(st, p[1], p[5], p[6], p[2])
	_quad(st, p[4], p[0], p[3], p[7])


func _quad4(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		flip: bool) -> void:
	if flip:
		_quad(st, d, c, b, a)
	else:
		_quad(st, a, b, c, d)


## Two triangles wound a -> b -> c -> d with the normal taken from the winding, and every
## material is CULL_DISABLED besides: wave 13's lesson is that a sheet photographed from
## behind is indistinguishable from a sheet that was never built, and three cells of this
## sheet are legitimately empty, so a face that vanished would be unfalsifiable here.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _mat(c: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.55
	return m
