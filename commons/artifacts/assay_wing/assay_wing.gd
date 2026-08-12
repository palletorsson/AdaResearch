extends Node3D
class_name AssayWing

## Assay Wing — a SYNTHESIS artifact. One phenomenon, five regimes of testing,
## standing at once in a row.
##
## @identity
## name: "The assay wing"
## tier: large
## essence: A five-celled laboratory wing, 3.46 m of it. Every cell holds the SAME
##   specimen under the same treatment; what differs between them is the apparatus
##   the laboratory has put around it — none, gauge, control, chart, vitrine, the
##   word nineteen artifacts each stand inside ONE value of, laid out as the row it
##   always was.
## desire: To be walked from the bare cell to the glass one, and to be checked. The
##   gauge's pointer, the control's vectors and the chart's last ink are three
##   drawings of one number. They are supposed to agree. Two of them are supposed
##   to be useless.
## critical_parameter: `treatment` — what is being done to the specimen. The five
##   regimes never move and never change their order; only what they are regimes OF.
## triggers: none. Nothing animates, nothing is picked up, nothing is random.
## emerges: a scalar assay and its history are the same information. `pull` and
##   `load` read 0.2624 and 0.2669 — four tenths of a pixel apart on a 76 px column
##   — for a corner drawn out into a spike and a body pressed flat, and the chart,
##   which plots that same number through time, separates them by 0.084 % of frame.
##   The control cell tells them apart instantly, because it is the one regime that
##   keeps a SHAPE.
## needs: one evaluation, read four ways [has, _run]; a fixed full scale that does
##   not follow the frame [has, DEP_FULL]; apparatus wired to the specimen [has];
##   no random number anywhere [has]
## relationships: Synthesised from the nineteen artifacts that declare `assay` —
##   see the registry block. It replaces none of them.
## truth: In all nineteen members the apparatus is FURNITURE. The record board plots
##   exp(-3.4t)cos(13t) on a bench about a leaking body, a permeable membrane, an
##   octopus arm and a settling swarm alike; the reference cage is 0.10 m of empty
##   wire whatever stands beside it; the indicator arm hangs at a fixed height and
##   touches nothing. This wing wires the instruments to the specimen and
##   photographs what they then say.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `treatment`
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED. This artifact did not exist before the promotion batches that
# produced its sources. It is the argument those batches left in nineteen
# registry notes, built as a body.
#
# ── WHAT IT IS ─────────────────────────────────────────────────────────────
#
# A wing 3.40 m long with five open cells cut into it, 0.56 x 0.60 x 0.40 each.
# Every cell holds the same specimen — one lattice of 75 masses, deformed by one
# treatment, evaluated ONCE at build time — and one regime of `assay`, in the
# order all nineteen members declare them:
#
#   none      the specimen, and nothing else. The thing loose in the world
#   gauge     a graduated column with a FIXED full scale, an arm that rests on
#             the specimen's crown where the crown actually is, and a pointer at
#             the measured departure
#   control   the untreated copy at the specimen's own rest extent, and one
#             vector per mass from where it was to where it is
#   chart     a ruled board carrying the departure series, on the same fixed
#             scale, ending at the number the pointer stands at
#   vitrine   glass on four posts, capped and captioned. Finished
#
# ── `assay` IS REFUSED AS THIS ARTIFACT'S AXIS, on the record ───────────────
#
# All nineteen members use the word to stand in ONE regime and forgo the other
# four. On this wing all five stand at once and that simultaneity IS the object,
# so an axis whose every value demolishes four fifths of the exhibit is not a
# variation of it. That is evidence_ladder's ruling on `evidence` and
# retention_corridor's on `retention`, and it lands here for the same reason.
#
# THE VALUES ARE SIDE BY SIDE, NOT NESTED, and this was checked in the code
# rather than assumed. Every member's dressing is a `match` with exactly one arm
# taken: `_assay_vitrine` builds glass and no gauge, `_assay_chart` a board and
# no cage. Nothing accumulates, and `vitrine` in particular SUBTRACTS — it is
# not a chart with glass round it, it is glass instead of a chart.
# disclosure_cabinet's five nest, so showing all five there is just the top rung
# and the family word can be the axis; these five are parallel readings, so
# showing all five is a NEW OBJECT and the word has to be exhibited instead of
# turned.
#
# The word is EXHIBITED — it names the artifact, it names the cells, it is
# engraved on the plinth under each one — and what turns is the treatment
# underneath it. The five value strings are never retyped here: they are read out
# of mass_spring_bench.ASSAYS by preload, the slot_machine link, so this wing and
# its nineteen members cannot drift into two vocabularies.
#
# ── WHAT THE WING FOUND, AND NO MEMBER COULD ───────────────────────────────
#
# MEASURED, by hashing the four dressing builders across the nine bench members:
# `_assay_gauge`, `_assay_control`, `_assay_chart` and `_assay_vitrine` are
# BYTE-IDENTICAL in seven of them and differ in the other two only by a variable
# name — two md5s per builder, 7 + 2, comments and blanks stripped. And the
# record board plots `exp(-3.4 * f) * cos(f * 13.0)` in ALL NINE and in
# jelly_cube; softmill plots exp(-3.0f)cos(11f); revolving_joy_ride and the
# softbody gallery plot exp(-3.2f)cos(14f). Fourteen artifacts, one damped
# oscillation, typed. Two members substituted a different FIXED curve
# (petri_dish_worms a logistic, bubbles_random a flat-topped histogram) and said
# so in their notes. In NONE of the nineteen does any instrument read the
# specimen: the chart's ink is a literal, the control's cage is 0.10 m of wire
# whether the body beside it is a 0.16 m dish or a 0.6 m lattice, and the gauge's
# arm hangs at ASSAY_TOP + 0.30 with its stylus stopping at ASSAY_TOP + 0.10,
# which is a height and not a reading.
#
# That is not a bug in nineteen artifacts. It is what a still of ONE bench can
# afford: the apparatus is there to say WHAT KIND OF CLAIM IS BEING MADE, and it
# says that perfectly well without measuring anything. This wing exists because
# once five regimes stand over one specimen the furniture stops being adequate —
# a control that does not know the body beside it cannot be a comparison, and a
# board that plots one curve for every specimen is not a record.
#
# So here the instruments are wired, and the wing photographs what they say:
#
#   * ONE EVALUATION. _run() fills _now (the specimen), _series (the departure
#     through time), _reading (its last value) and _top (its crown). The gauge's
#     pointer, the gauge's arm, the control's vectors, the chart's trace and the
#     chart's endpoint are five reads of those four. Nothing here computes a
#     quantity twice.
#
#   * A FIXED FULL SCALE. DEP_FULL = 0.80 half-widths, the same on the column and
#     on the ordinate at every value of the axis. The peak departure anywhere on
#     this axis is 0.5443 — gravity's overshoot — which is 68 % of scale, so
#     nothing clips and nothing is normalised to its own frame. A gauge whose
#     ceiling moved with its specimen would draw full scale for all five and say
#     nothing at all: sorting_hall's fault, avoided at the layout level.
#
#   * AND THEN THE INSTRUMENTS DISAGREE. The five readings are gravity 0.3648,
#     drive 0.3169, load 0.2669, pull 0.2624, breach 0.1991. `pull` and `load`
#     land 0.4 px apart on a 76 px column — a corner drawn out into a spike and a
#     body pressed flat under a platen, reported as the same event. `drive` and
#     `load` are 4.7 px apart; `breach` and `pull` 6.0. The chart cannot help,
#     because it plots THE SAME SCALAR: pull against load moves 0.084 % of frame
#     there, and drive against load 0.055 %. The control separates every pair on
#     sight, because 75 vectors are a shape and a mean is not.
#
#   * AND THE MEAN IS HONEST ABOUT BEING A MEAN. `breach` moves 24 of 75 masses
#     by 0.311 unit each and leaves 51 exactly where they were; it reads LOWEST
#     of the five. `gravity` moves 60 masses a smaller distance each and reads
#     highest. The gauge ranks a leak below a settle. Whether that is wrong
#     depends entirely on what you wanted to know, and the control cell is the
#     only place on the wing where you can find out.
#
# THAT IS THE ARGUMENT. Read as a list, none -> gauge -> control -> chart ->
# vitrine is an arc from a thing loose in the world to a museum piece, and
# nineteen registry entries describe it that way. Put the five over one specimen
# and the arc turns twice. `gauge` adds an instrument and LOSES the shape.
# `chart` adds a history of the thing the gauge already lost. `control` — third
# of five, the least ceremonious apparatus on the row — is the only regime that
# keeps what happened. And `vitrine` is the one cell whose apparatus could be
# built without ever looking at the specimen, and is: every dimension of that
# case is a constant, identical at every value of this axis by construction,
# which is what "an object of display rather than of study" means once you have
# to draw it.
#
# ── DETERMINISM ────────────────────────────────────────────────────────────
#
# There is not one call to randf, randi or randomize in this file, so no seed and
# no fixture. There is no _process and no _physics_process: the treatment is
# evaluated once at build time and drawn, so a capture's settle time cannot
# photograph this artifact half way through anything.
#
# Usage in map_data.json:
#   "assay_wing"                       — the gravity case
#   "assay_wing#treatment:breach"
#   "assay_wing#treatment:drive"

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY BINDING — read, never retyped
# ═══════════════════════════════════════════════════════════════════════════

## The `assay` family's own file. Preloaded rather than reached through
## class_name: class_name lookups are not reliable headless, and every frame of
## the evidence loop is rendered headless. mass_spring_bench is the member whose
## ASSAY section is the family's longest statement of the word, and its four
## dressing builders are the ones the other eight benches are byte-identical
## copies of (measured: two md5s per builder across nine files, 7 + 2).
const AssayFamily = preload("res://commons/artifacts/mass_spring_bench/mass_spring_bench.gd")

## THE FIVE CELLS. Not a literal — the family's list, character for character,
## because it IS the family's list. If a member ever reorders or renames a value
## this wing rebuilds in the new order and _check_family() reports the drift.
var _regimes: PackedStringArray = AssayFamily.ASSAYS

## The family's instrument accents, taken the same way.
var _c_read: Color = AssayFamily.ASSAY_READ    ## readings and ink
var _c_wire: Color = AssayFamily.ASSAY_WIRE    ## the reference standard's wire

## The family's bench working surface, so the wing's specimens stand at the
## height every member's specimen stands at.
var _sill: float = AssayFamily.ASSAY_TOP

## The five values this file has builders for, in the order it draws them. Kept
## separate from _regimes ON PURPOSE: _check_family() compares the two and raises
## when they part, which is the only way a preloaded vocabulary can be verified
## against a `match` that GDScript forces to be written in literals.
const BUILT: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## The bench height above, restated so the geometry can be constant-folded and
## checked against the preload at _ready.
const SILL_EXPECTED: float = 0.86


# ═══════════════════════════════════════════════════════════════════════════
# THE AXIS
# ═══════════════════════════════════════════════════════════════════════════

## What is being done to the specimen. The value list is a census of the nineteen
## members — see the registry's dna.kin, which names which member is which value.
## The five regimes are invariant.
##
## DECLARED ORDER: the default first, then DESCENDING separation from it
## (gravity/breach 3.78 %, gravity/pull 3.51 %, gravity/drive 3.32 %,
## gravity/load 2.32 %), because build_dna_gallery trims a value list from the
## TAIL — so a truncated sweep keeps the frames furthest apart and drops the
## weakest pair first rather than last.
@export_enum("gravity", "breach", "pull", "drive", "load") var treatment: String = "gravity"

## Allow-list. An unknown word in a map token falls back to the shipped gravity
## rather than stranding a placement with five identical cells.
const TREATMENTS: PackedStringArray = ["gravity", "breach", "pull", "drive", "load"]


# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY — every number below was gauged against this artifact's own framing
# ═══════════════════════════════════════════════════════════════════════════
#
# AABB 3.460 x 1.590 x 0.540, diagonal 3.8459, radius 1.9230. capture_config_sweep
# fits by diagonal — dist = radius / tan(FOV/2) * PAD * framing, FOV 34, PAD 1.9 —
# so at dna.framing 0.55 the camera stands 6.573 m out, the visible frame is
# 4.019 m across, and a 760 px still is 189.1 px per metre. Every mark here is
# checked against that number and not against how it looked on a bench: the
# family's gauge carries 13 graduations at 0.045 m, which land 8.5 px apart here
# and would photograph as a grey smear, so this column carries 5 at 0.100 m.

const CELL_W: float = 0.56            ## cell interior — 106 px
const CELL_H: float = 0.60            ## 113 px
const CELL_D: float = 0.40
const PITCH: float = 0.66             ## cell to cell
const FIN_W: float = 0.10             ## the pier between two cells
const WALL_T: float = 0.05
const FIN_FRONT: float = 0.26         ## how far the piers stand proud
const LINTEL_H: float = 0.09
const CORNICE_H: float = 0.04
const CORNICE_OVER: float = 0.03

## The specimen's box inside a cell — 61 x 53 px at rest. Small relative to the
## cell ON PURPOSE: `pull` reaches 0.239 m above the box's own top and `breach`
## 0.230 m out from its centre, and the cell has to hold those without a clamp
## doing the work. Measured margins at the worst value on each axis: x 0.033 m,
## y 0.044 m, z 0.025 m of clear air between the outermost bead's surface and
## the masonry.
const SPEC: Vector3 = Vector3(0.32, 0.28, 0.22)
const SPEC_OFF: Vector3 = Vector3(0.0, -0.01, 0.0)

## The lattice. 5 x 5 x 3 = 75 masses, mass_spring_bench's own picture (spheres
## at the masses) at the density this frame can hold: bead diameter 0.034 m is
## 6.4 px and the column pitch 0.080 m is 15.1 px, so the beads read as a lattice
## with daylight rather than fusing into a blob.
const NX: int = 5
const NY: int = 5
const NZ: int = 3
const DOT_R: float = 0.017

## Series resolution. 25 samples over t in [0, 1] — 24 chart segments at 3.3 px
## pitch, and enough to resolve `drive` at 2 cycles without aliasing.
const STEPS: int = 25

## THE FIXED FULL SCALE, in half-widths of mean displacement. Fixed across the
## whole axis, on the column and on the ordinate alike. The largest departure any
## treatment reaches at any t is gravity's overshoot at 0.5443, which is 68 % of
## this scale, so nothing clips. NOT frame-relative and not per-value.
const DEP_FULL: float = 0.80

# ── mark widths, all gauged at 189.1 px/m ────────────────────────────────
const CTRL_W: float = 0.022           ## departure vector — 4.2 px
const CAGE_W: float = 0.018           ## the untreated copy's edge — 3.4 px
const TRACE_W: float = 0.030          ## the chart's ink — 5.7 px
const TICK_L: float = 0.026           ## a lit graduation — 4.9 px
const TICK_S: float = 0.018           ## a plain graduation — 3.4 px
const POST_W: float = 0.028           ## a vitrine post — 5.3 px

# ── the gauge's column ───────────────────────────────────────────────────
const GA_X: float = -0.20             ## the column, at the cell's left
const GA_BASE: float = 0.03           ## zero on the scale, above the cell floor
const GA_H: float = 0.40              ## full scale — 76 px of travel
## The column's head, cell-local. It stands well above the top graduation at
## +0.13 because the ARM rides the specimen's crown and the crown reaches +0.239
## at `pull`; a column sized to the scale alone would leave that collar floating
## in air at one value of five.
const GA_TOP: float = 0.28

# ── the chart's board ────────────────────────────────────────────────────
const CH_W: float = 0.44
const CH_H: float = 0.36
const CH_PLOT_W: float = 0.42
const CH_PLOT_H: float = 0.30

# ── the vitrine's case — CONSTANT, and that is the point ─────────────────
const VIT_S: Vector3 = Vector3(0.50, 0.52, 0.36)
const VIT_C: Vector3 = Vector3(0.0, 0.014, 0.0)

# ── palette ──────────────────────────────────────────────────────────────
const C_STONE := Color(0.27, 0.26, 0.27)
const C_BACK := Color(0.13, 0.13, 0.15)
const C_PIER := Color(0.20, 0.21, 0.25)
const C_CHALK := Color(0.88, 0.90, 0.95)
const C_BODY := Color(0.92, 0.45, 0.58)      ## mass_spring_bench.body_col
const C_PAPER := Color(0.87, 0.86, 0.81)     ## the family's chart paper
const C_RULE := Color(0.58, 0.58, 0.54)      ## the family's chart ruling
const C_STEEL := Color(0.42, 0.45, 0.50)     ## the family's gauge steel
const C_GLASS := Color(0.72, 0.84, 0.95)


# ═══════════════════════════════════════════════════════════════════════════
# THE TREATMENT — one rule, and the only place it is written
# ═══════════════════════════════════════════════════════════════════════════
#
# Every field below is a closed-form displacement u(p, t) on the unit box. No
# randf, no time, no solver, no node lookup: two builds of one value are two
# photographs of one object.

const G_DECAY: float = 3.4            ## the nine benches' own chart constants,
const G_RING: float = 13.0            ## used here as the SETTLING LAW rather
const G_DROP: float = 0.34            ## than as ink typed onto a board
const G_SPREAD: float = 0.30

const LOAD_RATE: float = 4.2
const LOAD_DEPTH: float = 0.30
const LOAD_BULGE: float = 0.30

const PULL_RATE: float = 3.8
const PULL_FALL: float = 1.4
const PULL_LAG: float = 0.55
const PULL_VEC: Vector3 = Vector3(0.22, 0.40, 0.10)

const DRIVE_RATE: float = 5.0
const DRIVE_A: float = 0.22
const DRIVE_WAVES: float = 1.4        ## wavelengths along the body
const DRIVE_CYCLES: float = 2.0       ## cycles over the run

const BREACH_OUT: float = 0.22
const BREACH_DOWN: float = 0.22
const BREACH_Y: float = -0.24         ## only the bottom layers
const BREACH_R: float = 0.35          ## only outside this radius


var _rest: PackedVector3Array = PackedVector3Array()    ## the untreated copy
var _now: PackedVector3Array = PackedVector3Array()     ## the specimen at t = 1
var _series: PackedFloat32Array = PackedFloat32Array()  ## departure through time
var _reading: float = 0.0                               ## _series[STEPS - 1]
var _top: float = 0.0                                   ## the specimen's crown, unit y

var _root: Node3D = null
var _built: bool = false


func _ready() -> void:
	_check_family()
	_read_grid_config_meta()
	_rebuild()
	_built = true


## The vocabulary guard. GDScript will not let an @export_enum hint or a `match`
## arm be computed, so the five regime strings exist twice in this file: once as
## the preloaded family list, once as BUILT. If they ever part — a renamed value,
## a reordered list, a sixth rung — this raises instead of quietly drawing four
## cells and a gap. disclosure_cabinet's _check_vocabulary, extended to the bench
## height the wing borrows.
func _check_family() -> void:
	if _regimes.size() != BUILT.size():
		push_error("assay_wing: the `assay` family declares %d values, this wing builds %d — %s vs %s"
			% [_regimes.size(), BUILT.size(), str(_regimes), str(BUILT)])
		_regimes = BUILT
	else:
		for i in range(BUILT.size()):
			if _regimes[i] != BUILT[i]:
				push_error("assay_wing: `assay` value %d is '%s' in the family and '%s' here — the vocabularies have parted"
					% [i, _regimes[i], BUILT[i]])
				_regimes = BUILT
				break
	if not is_equal_approx(_sill, SILL_EXPECTED):
		push_error("assay_wing: the family's ASSAY_TOP has moved to %f; this wing's geometry is built for %f"
			% [_sill, SILL_EXPECTED])
		_sill = SILL_EXPECTED


# ── the fields ───────────────────────────────────────────────────────────

## GRAVITY — released and left to a body force. The body sags and spreads, rings
## once and settles. Nine of the nineteen members are this case, mass_spring_bench
## and energy_landscape_bench most explicitly ("the shape nobody specified").
##
## The envelope is the family's own chart literal, exp(-3.4 t) cos(13 t), moved
## from the record board into the law. So at this ONE value of the axis the curve
## the nineteen members type onto their boards is the curve this wing's board
## actually plots — and at the other four it is not. The family's ink is right
## once and wrong four times, and the sweep shows which.
func _u_gravity(p: Vector3, t: float) -> Vector3:
	var h: float = p.y + 0.5
	var s: float = 1.0 - exp(-G_DECAY * t) * cos(G_RING * t)
	return Vector3(p.x * G_SPREAD * h * s, -G_DROP * h * s, p.z * G_SPREAD * h * s)


## LOAD — a platen comes down and STAYS down. The top face is flattened onto a
## plane, the waist barrels out, the pinned floor does not move. Four members:
## softmill's forever-turning pusher arm, revolving_joy_ride's centrifuge,
## jelly_cube and jelly_variants under a poke that holds.
func _u_load(p: Vector3, t: float) -> Vector3:
	var g: float = 1.0 - exp(-LOAD_RATE * t)
	var platen: float = 0.5 - LOAD_DEPTH * g
	var dy: float = minf(0.0, platen - p.y)
	var h: float = p.y + 0.5
	var barrel: float = sin(PI * clampf(h, 0.0, 1.0))
	return Vector3(p.x * LOAD_BULGE * barrel * g, dy, p.z * LOAD_BULGE * barrel * g)


## PULL — held at one corner and drawn out; the rest follows, and TRAILS.
## grab_jelly_bench and tentacle_grab_bench, the latter verbatim: "grab the tip
## and the whole arm follows and trails". The trailing is why recruitment travels
## outward from the grab instead of everything starting together, and it is the
## only reason this treatment's series is an S rather than one more exponential
## approach that would photograph as `load`'s. Even so the two END at 0.2624 and
## 0.2669, which is the wing's sharpest finding rather than a fault — see the
## header.
func _u_pull(p: Vector3, t: float) -> Vector3:
	var grab: Vector3 = Vector3(0.5, 0.5, 0.5)
	var d: float = p.distance_to(grab)
	var w: float = exp(-PULL_FALL * d * d)
	var lag: float = PULL_LAG * d / sqrt(3.0)
	var tt: float = maxf(0.0, (t - lag) / maxf(0.001, 1.0 - lag))
	var q: float = 1.0 - exp(-PULL_RATE * tt)
	return PULL_VEC * (w * q)


## DRIVE — actuated from inside; a wave travels through the body and keeps
## travelling. octopus_bench's curl and petri_dish_worms' own essence line,
## offset = amplitude * sin(speed * t + i * phase). The amplitude ramps in from
## rest and then never decays, which is why this series climbs to a plateau and
## ripples on it instead of settling. A driven body has no settling curve at all,
## so the family's damped sine is furthest from the truth here.
func _u_drive(p: Vector3, t: float) -> Vector3:
	var ramp: float = 1.0 - exp(-DRIVE_RATE * t)
	var ph: float = TAU * DRIVE_WAVES * p.x - TAU * DRIVE_CYCLES * t
	return Vector3(0.0, DRIVE_A * ramp * sin(ph), 0.10 * DRIVE_A * ramp * cos(ph))


## BREACH — the body crosses its own edge. abject_bench "drips down a glass plate,
## seeps past its drawn edge"; membrane_bench lets the small through and turns the
## large away. So the core does not move at all and the bottom of the outer ring
## spreads past the footprint and hangs: 24 of the 75 masses, and 51 exactly
## where they started.
##
## THIS IS THE TREATMENT THE MEAN UNDER-REPORTS, and that is content rather than
## defect. Each of its 24 moving masses travels 0.311 unit — more than any mass
## moves under gravity, load or drive — and its mean departure is 0.1991, the
## LOWEST on the axis, because a mean over 75 divides a dramatic edge by a
## stationary middle. The gauge ranks the leak below the settle. The control cell
## does not.
func _u_breach(p: Vector3, t: float) -> Vector3:
	if p.y >= BREACH_Y:
		return Vector3.ZERO
	var r: float = sqrt(p.x * p.x + p.z * p.z)
	if r <= BREACH_R:
		return Vector3.ZERO
	var creep: float = pow(t, 0.6)
	return Vector3(p.x / r * BREACH_OUT * creep, -BREACH_DOWN * creep, p.z / r * BREACH_OUT * creep)


func _u(p: Vector3, t: float) -> Vector3:
	if treatment == "load":
		return _u_load(p, t)
	if treatment == "pull":
		return _u_pull(p, t)
	if treatment == "drive":
		return _u_drive(p, t)
	if treatment == "breach":
		return _u_breach(p, t)
	return _u_gravity(p, t)


## The untreated lattice — IDENTICAL AT EVERY VALUE OF THE AXIS, which is what
## makes the row a comparison and the control cell a control.
func _make_rest() -> void:
	_rest.clear()
	for ix in range(NX):
		for iy in range(NY):
			for iz in range(NZ):
				_rest.append(Vector3(
					float(ix) / float(NX - 1) - 0.5,
					float(iy) / float(NY - 1) - 0.5,
					float(iz) / float(NZ - 1) - 0.5))


## THE ONE EVALUATION. Everything the four instruments draw is read out of what
## this leaves behind: _now (the specimen), _series (its history), _reading (the
## last value of that history) and _top (its crown). Nothing on this wing computes
## a quantity a second time, so there is nothing here that can disagree with
## anything else here.
##
## `departure` is the mean displacement magnitude in half-widths of the untreated
## body. It is a MEAN, it is labelled as one, it is not a proxy for anything else,
## and it never reports zero for a specimen that moved.
func _run() -> void:
	_make_rest()
	var n: int = _rest.size()
	_now.resize(n)
	_series.resize(STEPS)
	_top = -1.0
	for k in range(STEPS):
		var t: float = float(k) / float(STEPS - 1)
		var acc: float = 0.0
		for i in range(n):
			var d: Vector3 = _u(_rest[i], t)
			acc += d.length()
			if k == STEPS - 1:
				var q: Vector3 = _rest[i] + d
				_now[i] = q
				_top = maxf(_top, q.y)
		_series[k] = (acc / float(n)) / 0.5
	_reading = _series[STEPS - 1]


# ── unit box → cell-local metres ─────────────────────────────────────────

func _place(p: Vector3) -> Vector3:
	return Vector3(
		SPEC_OFF.x + p.x * SPEC.x,
		SPEC_OFF.y + p.y * SPEC.y,
		SPEC_OFF.z + p.z * SPEC.z)


## Where a departure of `d` half-widths stands, on the gauge's column and on the
## chart's ordinate alike. ONE function, so the pointer and the ink cannot part,
## and the ceiling is DEP_FULL at every value of the axis.
func _scale_frac(d: float) -> float:
	return clampf(d / DEP_FULL, 0.0, 1.0)


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_root = Node3D.new()
	_root.name = "Wing_%s" % treatment
	add_child(_root)

	_run()
	_shell(_root)

	for i in range(_regimes.size()):
		var cell := Node3D.new()
		cell.name = "Cell_%s" % _regimes[i]
		cell.position = Vector3(_cell_x(i), _cell_cy(), 0.0)
		_root.add_child(cell)
		_specimen(cell, _now, "Specimen", C_BODY, 1.15, DOT_R)
		_fit(cell, _regimes[i])

	_collider(_root)


func _cell_x(i: int) -> float:
	return (float(i) - 0.5 * float(_regimes.size() - 1)) * PITCH


func _cell_cy() -> float:
	return _sill + CELL_H * 0.5


func _back_z() -> float:
	return -CELL_D * 0.5


## Plinth, back wall, six piers, lintel, cornice, one lit sill per cell and one
## engraved name. IDENTICAL at every value of the axis and identical between
## cells, so the specimen and its instruments are the only things that vary, both
## across the row and across a sweep.
##
## Every mesh in this artifact is inside this shell, MultiMesh included, so the
## capture AABB is the real body and no layers = 0 anchor is needed.
func _shell(root: Node3D) -> void:
	var n: int = _regimes.size()
	var width: float = float(n) * PITCH + FIN_W
	var bz: float = _back_z()
	var depth: float = FIN_FRONT - (bz - WALL_T)
	var mid_z: float = (FIN_FRONT + bz - WALL_T) * 0.5
	var stone: StandardMaterial3D = _matte(C_STONE)
	var back: StandardMaterial3D = _matte(C_BACK)
	var pier: StandardMaterial3D = _matte(C_PIER)

	root.add_child(_box(Vector3(0.0, _sill * 0.5, mid_z * 0.6),
		Vector3(width, _sill, depth * 0.86), stone))
	root.add_child(_box(Vector3(0.0, _cell_cy(), bz - WALL_T * 0.5),
		Vector3(width, CELL_H, WALL_T), back))

	for i in range(n + 1):
		var x: float = (float(i) - 0.5 * float(n)) * PITCH
		root.add_child(_box(Vector3(x, _cell_cy(), mid_z),
			Vector3(FIN_W, CELL_H, depth), pier))

	root.add_child(_box(Vector3(0.0, _sill + CELL_H + LINTEL_H * 0.5, mid_z),
		Vector3(width, LINTEL_H, depth), pier))
	root.add_child(_box(Vector3(0.0, _sill + CELL_H + LINTEL_H + CORNICE_H * 0.5, mid_z),
		Vector3(width + CORNICE_OVER * 2.0, CORNICE_H, depth + CORNICE_OVER), stone))

	# one lit sill and one engraved name per cell — the family's word, exhibited
	for i in range(n):
		root.add_child(_box(Vector3(_cell_x(i), _sill + 0.012, FIN_FRONT - 0.05),
			Vector3(CELL_W, 0.024, 0.028), _mat(_c_read, 0.30)))
		root.add_child(_text(_regimes[i].to_upper(),
			Vector3(_cell_x(i), _sill - 0.10, FIN_FRONT - 0.036), 50, 0.0018, C_CHALK))

	# THE HEADER DOES NOT NAME THE TREATMENT, deliberately. A caption carrying the
	# axis value would let a measurement of the specimen be padded by a
	# measurement of the label. Every pixel that moves across this axis is either
	# the specimen or an instrument reading it.
	root.add_child(_text("one specimen  ·  five assays",
		Vector3(0.0, _sill + CELL_H + LINTEL_H + CORNICE_H + 0.065, FIN_FRONT - 0.04),
		44, 0.0018, C_CHALK))


func _fit(cell: Node3D, regime: String) -> void:
	match regime:
		"none":
			# THE SPECIMEN AND NOTHING ELSE. Not an empty cell: a cell with a back
			# wall, a sill and a plate like the other four, holding the thing loose
			# in the world. It is also the only cell that cannot be wrong.
			pass
		"gauge":
			_fit_gauge(cell)
		"control":
			_fit_control(cell)
		"chart":
			_fit_chart(cell)
		"vitrine":
			_fit_vitrine(cell)


## The specimen — a dot cloud, mass_spring_bench's own picture. Drawn identically
## in all five cells from one array; nothing about the body changes between
## regimes, because a variant that changed the specimen would be changing the
## answer rather than the showing.
##
## THE CLAMP NEVER FIRES at any of the five values, and that was checked value by
## value rather than assumed: the outermost bead's surface clears the masonry by
## 0.033 m in x (breach), 0.044 m in y (pull) and 0.025 m in z (breach). It is
## here so that a sixth treatment cannot silently push a mass into a pier.
func _specimen(cell: Node3D, pts: PackedVector3Array, nm: String, c: Color,
		energy: float, radius: float) -> void:
	var mmi: MultiMeshInstance3D = _mm_dot(nm, _mat(c, energy), radius)
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = pts.size()
	for i in range(pts.size()):
		var p: Vector3 = _place(pts[i])
		p = Vector3(
			clampf(p.x, -CELL_W * 0.5 + radius, CELL_W * 0.5 - radius),
			clampf(p.y, -CELL_H * 0.5 + radius, CELL_H * 0.5 - radius),
			clampf(p.z, _back_z() + radius, CELL_D * 0.5 - radius))
		mm.set_instance_transform(i, Transform3D(Basis(), p))
	cell.add_child(mmi)


## GAUGE — a graduated column with a FIXED full scale, an arm that rests where the
## specimen's crown actually is, and a pointer at the measured departure.
##
## The family's gauge hangs its arm at ASSAY_TOP + 0.30 and drops a stylus to
## ASSAY_TOP + 0.10 whatever is on the bench; both are heights, neither is a
## reading. Here the arm rides at _top and the pointer stands at _reading, two
## different derived quantities, so the instrument is visibly touching the thing
## it reports on. The arm travels from +0.062 m at gravity to +0.263 m at pull —
## 38 px of visible contact — while the pointer travels 15.7 px over the same
## axis, which is the picture of an instrument that sees a lot and says little.
##
## THE SCALE IS THE SAME AT EVERY VALUE. Five graduations at 0.0, 0.2, 0.4, 0.6
## and 0.8 half-widths, 0.100 m apart, which is 18.9 px.
func _fit_gauge(cell: Node3D) -> void:
	var steel: StandardMaterial3D = _steel(C_STEEL)
	var tick: StandardMaterial3D = _matte(Color(0.88, 0.88, 0.84))
	var read: StandardMaterial3D = _mat(_c_read, 1.0)
	var floor_y: float = -CELL_H * 0.5
	var zero: float = floor_y + GA_BASE
	var head: float = GA_TOP

	cell.add_child(_box(Vector3(GA_X, floor_y + 0.012, 0.0), Vector3(0.12, 0.024, 0.12), steel))
	cell.add_child(_box(Vector3(GA_X, (floor_y + head) * 0.5, 0.0),
		Vector3(0.045, head - floor_y, 0.045), steel))

	# graduations up the inward face, 0.0 .. DEP_FULL, lit at the two ends
	for i in range(5):
		var f: float = float(i) / 4.0
		var lit: bool = i == 0 or i == 4
		var tl: float = TICK_L if lit else TICK_S
		cell.add_child(_box(Vector3(GA_X + 0.023 + tl * 0.5, zero + GA_H * f, 0.0),
			Vector3(tl, 0.010, 0.014), read if lit else tick))

	# THE FIXED CEILING, printed on the plinth beside the cell's name, where a
	# legend belongs and where it cannot crowd the column. It does not move with
	# the axis, so it cannot pad a measurement, and it is the visible proof that
	# no frame here is normalised to its own contents.
	cell.add_child(_text("SCALE 0 – 0.80",
		Vector3(0.0, -CELL_H * 0.5 - 0.20, FIN_FRONT - 0.036), 26, 0.0018, _c_read))

	# the pointer — the reading, on the scale
	var py: float = zero + GA_H * _scale_frac(_reading)
	cell.add_child(_box(Vector3(GA_X, py, 0.028), Vector3(0.060, 0.020, 0.030), read))

	# the arm — riding on the specimen's crown, where the crown actually is
	var crown: float = _place(Vector3(0.0, _top, 0.0)).y
	var arm_y: float = crown + 0.024
	var reach: float = SPEC_OFF.x - GA_X
	cell.add_child(_box(Vector3(GA_X, arm_y, 0.0), Vector3(0.068, 0.046, 0.068), _matte(C_PIER)))
	cell.add_child(_box(Vector3(GA_X + reach * 0.5, arm_y, SPEC_OFF.z),
		Vector3(reach, 0.022, 0.022), read))
	cell.add_child(_box(Vector3(GA_X + reach, (arm_y + crown) * 0.5, SPEC_OFF.z),
		Vector3(0.014, maxf(arm_y - crown, 0.01), 0.014), read))
	cell.add_child(_sphere(Vector3(GA_X + reach, crown, SPEC_OFF.z), 0.020, read))


## CONTROL — the untreated copy, and the difference from it.
##
## The family draws this as a wire cage 0.10 m on a side standing on a witness
## plinth beside the bench, "the size the body had before anything happened to
## it" — a literal 0.10, the same beside a 0.16 m dish and a 0.60 m lattice. Here
## the cage is the specimen's OWN rest extent, standing where the specimen
## actually was, with the untreated lattice pale inside it and one vector from
## each rest position to where that mass is now.
##
## A DEPARTURE FROM THE FAMILY'S STAGING, ON THE RECORD. The members put the
## reference BESIDE the specimen; this cell puts it OVER. Two reasons, both
## measurable: in a 106 px cell two half-size copies are two illegible clouds,
## and a beside-standing reference cannot carry the vectors, which are the whole
## content of a comparison. The WORD is unchanged — a second, untreated copy —
## and the registration is what lets it do its job.
##
## THIS IS THE CELL THAT WINS. It is the only regime here that keeps a SHAPE, so
## it is the only one that separates pull from load, which the gauge reports 0.4
## px apart and the chart 0.084 % of frame apart.
func _fit_control(cell: Node3D) -> void:
	var wire: StandardMaterial3D = _mat(_c_wire, 0.85)
	var ghost: StandardMaterial3D = _mat(_c_wire.darkened(0.25), 0.40)

	# the twelve edges of the untreated body, at its own extent
	var hx: float = SPEC.x * 0.5
	var hy: float = SPEC.y * 0.5
	var hz: float = SPEC.z * 0.5
	var o: Vector3 = SPEC_OFF
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			cell.add_child(_box(o + Vector3(sx, 0.0, sz), Vector3(CAGE_W, SPEC.y, CAGE_W), ghost))
	for sy in [-hy, hy]:
		for sz2 in [-hz, hz]:
			cell.add_child(_box(o + Vector3(0.0, sy, sz2), Vector3(SPEC.x, CAGE_W, CAGE_W), ghost))
		for sx2 in [-hx, hx]:
			cell.add_child(_box(o + Vector3(sx2, sy, 0.0), Vector3(CAGE_W, CAGE_W, SPEC.z), ghost))

	# the untreated copy itself, pale and small, so the vectors have a foot
	_specimen(cell, _rest, "Untreated", _c_wire.darkened(0.15), 0.35, DOT_R * 0.62)

	# and the difference. One segment per mass; a mass that did not move draws
	# nothing at all, which is why `breach` reads as a skirt over 51 masses of
	# silence and why this is the cell where a mean stops being enough.
	var mmi: MultiMeshInstance3D = _mm_box("Departure", wire)
	var mm: MultiMesh = mmi.multimesh
	var xf: Array[Transform3D] = []
	for i in range(_rest.size()):
		var a: Vector3 = _place(_rest[i])
		var b: Vector3 = _place(_now[i])
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.006:
			continue
		xf.append(Transform3D(
			_basis_y_to(d).scaled(Vector3(CTRL_W, l, CTRL_W)),
			(a + b) * 0.5))
	mm.instance_count = xf.size()
	for i in range(xf.size()):
		mm.set_instance_transform(i, xf[i])
	cell.add_child(mmi)


## CHART — the departure series on a ruled board, at the same fixed full scale the
## gauge's column carries, ending at the same number the pointer stands at.
##
## The family's board plots exp(-3.4 f) cos(13 f), a literal, identical on
## fourteen artifacts including one about worms and one about a membrane. This
## board plots _series, which is what the specimen in this cell actually did. At
## treatment=gravity the two are the same curve, because gravity's envelope IS
## that literal; at the other four they are not, and that is the family's ink
## being checked rather than quoted.
func _fit_chart(cell: Node3D) -> void:
	var frame: StandardMaterial3D = _matte(Color(0.26, 0.27, 0.31))
	var paper: StandardMaterial3D = _matte(C_PAPER)
	var rule: StandardMaterial3D = _matte(C_RULE)
	var ink: StandardMaterial3D = _mat(_c_read, 1.0)
	var bz: float = _back_z() + 0.022

	cell.add_child(_box(Vector3(0.0, 0.0, bz - 0.010), Vector3(CH_W + 0.03, CH_H + 0.03, 0.014), frame))
	cell.add_child(_box(Vector3(0.0, 0.0, bz), Vector3(CH_W, CH_H, 0.010), paper))

	var x0: float = -CH_PLOT_W * 0.5
	var y0: float = -CH_PLOT_H * 0.5
	var y1: float = CH_PLOT_H * 0.5
	cell.add_child(_box(Vector3(0.0, y0, bz + 0.008), Vector3(CH_PLOT_W, 0.009, 0.006), rule))
	cell.add_child(_box(Vector3(x0, 0.0, bz + 0.008), Vector3(0.009, CH_PLOT_H, 0.006), rule))
	# the ordinate's ruling, at the same 0.2 half-width spacing as the column's
	# graduations, so the two instruments are drawn against ONE ladder
	for i in range(4):
		cell.add_child(_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 4.0), bz + 0.007),
			Vector3(CH_PLOT_W, 0.004, 0.005), rule))

	var mmi: MultiMeshInstance3D = _mm_box("Trace", ink)
	var mm: MultiMesh = mmi.multimesh
	var xf: Array[Transform3D] = []
	var prev: Vector3 = Vector3.ZERO
	for k in range(STEPS):
		var f: float = float(k) / float(STEPS - 1)
		var p: Vector3 = Vector3(
			x0 + CH_PLOT_W * f,
			y0 + CH_PLOT_H * _scale_frac(_series[k]),
			bz + 0.014)
		if k > 0:
			var d: Vector3 = p - prev
			xf.append(Transform3D(
				_basis_y_to(d).scaled(Vector3(TRACE_W, maxf(d.length(), 0.001), TRACE_W * 0.5)),
				(prev + p) * 0.5))
		prev = p
	mm.instance_count = xf.size()
	for i in range(xf.size()):
		mm.set_instance_transform(i, xf[i])
	cell.add_child(mmi)

	# the last ink — the same number the gauge's pointer stands at
	cell.add_child(_sphere(prev, 0.019, ink))


## VITRINE — glass on four posts, capped, captioned. Finished.
##
## THIS CELL IS IDENTICAL AT EVERY VALUE OF THE AXIS, and that is the wing's point
## rather than an omission. Every dimension below is a constant; not one of them
## reads _now, _series, _reading or _top. It is the only regime on the row whose
## apparatus could be built without ever having seen the specimen — which is
## exactly what "an object of display rather than of study" means once you have to
## draw it. The family builds it the same way, and the family is right about this
## one.
##
## The case is sized to hold the specimen at EVERY value, not at the default:
## 0.50 x 0.52 x 0.36 against a worst reach of 0.230 / 0.239 / 0.158 plus a bead.
## A case fitted to `gravity` alone would have been pierced by `pull`.
func _fit_vitrine(cell: Node3D) -> void:
	var post: StandardMaterial3D = _steel(Color(0.30, 0.32, 0.36))
	var cap: StandardMaterial3D = _matte(C_PIER)
	var hx: float = VIT_S.x * 0.5
	var hz: float = VIT_S.z * 0.5
	var y0: float = VIT_C.y - VIT_S.y * 0.5
	var y1: float = VIT_C.y + VIT_S.y * 0.5

	cell.add_child(_box(VIT_C, VIT_S, _glass(C_GLASS, 0.10)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			cell.add_child(_box(Vector3(VIT_C.x + sx, VIT_C.y, VIT_C.z + sz),
				Vector3(POST_W, VIT_S.y, POST_W), post))
	# rails, not floors: a solid pan at the base would hide the specimen's foot,
	# and `breach` is a treatment that happens at the foot
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			cell.add_child(_box(Vector3(VIT_C.x, yy, VIT_C.z + sz2),
				Vector3(VIT_S.x, 0.024, 0.024), post))
		for sx2 in [-hx, hx]:
			cell.add_child(_box(Vector3(VIT_C.x + sx2, yy, VIT_C.z),
				Vector3(0.024, 0.024, VIT_S.z), post))
	# the cap sits AT the top rail rather than above it — a plate standing proud
	# would reach 0.287 m in a cell whose lintel starts at 0.300
	cell.add_child(_box(Vector3(VIT_C.x, y1, VIT_C.z),
		Vector3(VIT_S.x + 0.04, 0.026, VIT_S.z + 0.04), cap))
	cell.add_child(_box(Vector3(VIT_C.x, y0 + 0.055, VIT_C.z + hz + 0.010),
		Vector3(0.24, 0.062, 0.012), _matte(Color(0.13, 0.14, 0.17))))


## ONE body for the whole wing, not one per cell — the 8000-static-bodies lesson
## taken at the design stage. A CollisionShape3D is not a MeshInstance3D, so this
## does not touch the capture AABB.
func _collider(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "WingBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var bz: float = _back_z()
	var depth: float = FIN_FRONT - (bz - WALL_T)
	var h: float = _sill + CELL_H + LINTEL_H + CORNICE_H
	box.size = Vector3(float(_regimes.size()) * PITCH + FIN_W, h, depth)
	shape.shape = box
	shape.position = Vector3(0.0, h * 0.5, (FIN_FRONT + bz - WALL_T) * 0.5)
	body.add_child(shape)
	root.add_child(body)


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls
## apply_grid_config, and the capture harness calls apply_grid_config before the
## scene enters the tree. Reading the metadata on the way in means the wing is
## built once, correctly, instead of built as `gravity` and then torn down.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_treatment"):
			var want: String = _clean(str(node.get_meta("config_treatment")))
			if TREATMENTS.has(want):
				treatment = want
		node = node.get_parent()


## Tokens: #treatment:breach · #treatment:pull · #treatment:drive · #treatment:load
##
## GUARDED FOUR WAYS — the key must be present, the value must be one the code can
## build, it must differ from the one already standing, and _ready must have built
## once. A placement carrying any other token reaches here with no `treatment` key
## at all, and the grid reaches this twice for one placement; an unguarded rebuild
## would tear down and re-raise five cells on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("treatment"):
		return
	var want: String = _clean(str(config["treatment"]))
	if not TREATMENTS.has(want):
		return
	if want == treatment:
		return
	treatment = want
	if not _built:
		return              # _ready has not built yet and will build this value itself
	_rebuild()


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	m.metallic = 0.0
	return m


func _steel(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.4
	return m


func _glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.25
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _box(p: Vector3, s: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


func _sphere(p: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.material_override = m
	mi.position = p
	return mi


func _basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## A dot cloud. All of these sit inside a cell and every cell sits inside the
## shell, so the MeshInstance3D extent already bounds them.
func _mm_dot(nm: String, mat: Material, radius: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = radius
	dot.height = radius * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	mm.mesh = dot
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


## A bundle of oriented segments — unit boxes carrying their length and width in
## the instance basis, so the departure field and the chart's trace are one
## drawcall each rather than 99 nodes.
func _mm_box(nm: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


## Non-billboard on purpose. LabelFramer frames HANGING labels and leaves text
## that already lies on a body alone — these lie on the plinth, on the cornice and
## against the gauge's column, so they keep their place and add no plate to the
## capture. Seven labels in the whole artifact, and not one of them names the
## treatment.
func _text(content: String, p: Vector3, size: int, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
